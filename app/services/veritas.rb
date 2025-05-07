# frozen_string_literal: true

# lib/services/veritas.rb
require "base64"
require "json"
require "securerandom"
require "active_support/time"

module Services
  class AuthService
    attr_reader :hash_key

    def initialize(hash_key)
      @hash_key = hash_key
    end

    # Register a new user
    def register(user_data)
      # Validate required fields
      validate_user_data(user_data)

      # Create the user with has_secure_password
      user = User.new(
        first_name: user_data[:first_name],
        last_name: user_data[:last_name],
        email: user_data[:email],
        password: user_data[:password],
        password_confirmation: user_data[:password_confirmation] || user_data[:password],
        access_level: user_data[:admin] ? :admin : :user
      )

      if user.save
        # Create initial session
        session = create_session_for_user(user)

        # Return user info without sensitive data
        {
          success: true,
          token: session[:token],
          user: {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            full_name: user.full_name,
            access_level: user.access_level,
            admin: user.admin?
          }
        }
      else
        { success: false, error: user.errors.full_messages.join(", ") }
      end
    rescue => e
      { success: false, error: e.message }
    end

    # Authenticate a user and generate a token
    def authenticate(email, password)
      # Find user by email
      user = User.find_by(email: email)

      if user&.authenticate(password)
        # Create a session for the user
        session = create_session_for_user(user)

        {
          success: true,
          token: session[:token],
          user: {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            full_name: user.full_name,
            access_level: user.access_level,
            admin: user.admin?
          }
        }
      else
        { success: false, error: "Invalid email or password" }
      end
    rescue => e
      { success: false, error: e.message }
    end

    # Get user info by ID
    def get_user(user_id)
      user = User.find_by(id: user_id)

      if user
        {
          success: true,
          user: {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            full_name: user.full_name,
            access_level: user.access_level,
            admin: user.admin?,
            last_seen_at: user.last_seen_at,
            last_login_at: user.last_login_at,
            active: user.active?
          }
        }
      else
        { success: false, error: "User not found" }
      end
    rescue => e
      { success: false, error: e.message }
    end

    # Verify a token
    def verify_token(token)
      begin
        decoded = decode_token(token)
        user_id = decoded[:user_id]
        session_id = decoded[:session_id]

        # Find the user session
        user_session = UserSession.find_by(id: session_id, user_id: user_id)
        return { success: false, error: "Invalid session" } unless user_session

        # Check if session has expired based on user's session duration
        user = user_session.user
        session_duration = user.session_duration_seconds.seconds

        if user_session.last_seen_at < Time.now.utc - session_duration
          return { success: false, error: "Session expired" }
        end

        # Update last seen timestamp
        user_session.update(last_seen_at: Time.now.utc)

        {
          success: true,
          user: {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            full_name: user.full_name,
            access_level: user.access_level,
            admin: user.admin?
          }
        }
      rescue => e
        { success: false, error: "Invalid token" }
      end
    end

    # Logout - invalidate a session
    def logout(token)
      begin
        decoded = decode_token(token)
        session_id = decoded[:session_id]

        # Find and destroy the session
        session = UserSession.find_by(id: session_id)

        if session
          session.destroy
          { success: true }
        else
          { success: false, error: "Session not found" }
        end
      rescue => e
        { success: false, error: e.message }
      end
    end

    # Logout all sessions for a user
    def logout_all(user_id)
      user = User.find_by(id: user_id)

      if user
        user.user_sessions.destroy_all
        { success: true }
      else
        { success: false, error: "User not found" }
      end
    rescue => e
      { success: false, error: e.message }
    end

    private

    def validate_user_data(user_data)
      raise "First name is required" unless user_data[:first_name]
      raise "Last name is required" unless user_data[:last_name]
      raise "Email is required" unless user_data[:email]
      raise "Password is required" unless user_data[:password]
      raise "Password must be at least 8 characters" if user_data[:password].length < 8
    end

    # Create a session for a user and generate a token
    def create_session_for_user(user)
      # Create user session
      session = UserSession.create!(
        user: user,
        user_agent: Thread.current[:user_agent],
        ip_address: Thread.current[:remote_ip],
        last_seen_at: Time.now
      )

      # Generate a token for this session
      token = generate_token(user.id, session.id)

      {
        id: session.id,
        token: token
      }
    end

    # Generate a JWT-like token
    def generate_token(user_id, session_id)
      payload = {
        user_id: user_id,
        session_id: session_id,
        created_at: Time.now.to_i
      }

      encoded_payload = Base64.strict_encode64(payload.to_json)
      signature = generate_signature(encoded_payload)

      "#{encoded_payload}.#{signature}"
    end

    # Generate signature for token
    def generate_signature(payload)
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        hash_key,
        payload
      )
    end

    # Decode and verify a token
    def decode_token(token)
      encoded_payload, signature = token.split(".")

      # Verify signature
      valid_signature = generate_signature(encoded_payload)
      raise "Invalid signature" unless signature == valid_signature

      # Decode payload
      JSON.parse(Base64.strict_decode64(encoded_payload), symbolize_names: true)


    end

  end
end
