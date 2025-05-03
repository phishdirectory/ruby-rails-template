# frozen_string_literal: true

# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def new
    # Login form
    redirect_to root_path if current_user
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      fingerprint_info = {
        fingerprint: params[:fingerprint],
        device_info: params[:device_info],
        os_info: params[:os_info],
        timezone: params[:timezone],
        ip: request.remote_ip
      }

      session = sign_in(user: user, fingerprint_info: fingerprint_info)
      session.touch_last_seen_at

      redirect_back_or_to root_path, notice: "Successfully logged in!"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy_all
    sign_out_of_all_sessions
    redirect_to profile_path, notice: "All other sessions have been signed out."
  end

  def destroy
    session_id = params[:id]

    if session_id == "current"
      sign_out
      redirect_to root_path, notice: "You have been successfully signed out."
    else
      session = current_user.user_sessions.find(session_id)
      session.update(signed_out_at: Time.current, expiration_at: Time.current)
      redirect_to profile_path, notice: "Session has been revoked."
    end
  end

  private

  def redirect_back_or_to(default, options = {})
    redirect_to(session[:return_to] || default, options)
    session.delete(:return_to)
  end

end
