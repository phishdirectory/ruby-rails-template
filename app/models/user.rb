# frozen_string_literal: true

class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password_hash, presence: true

  has_many :user_sessions, dependent: :destroy

end
