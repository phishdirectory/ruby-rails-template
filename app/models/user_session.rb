# frozen_string_literal: true

# app/models/user_session.rb
class UserSession < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :last_seen_at, presence: true

  scope :active, ->(duration = 30.days) { where(last_seen_at: duration.ago..) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }

  before_create :set_defaults

  private

  def set_defaults
    self.last_seen_at ||= Time.current
  end

end
