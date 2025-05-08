# frozen_string_literal: true

class Profile < ApplicationRecord
  validates :pd_id, presence: true, uniqueness: true
  has_many :user_sessions, primary_key: :pd_id, foreign_key: :pd_id, dependent: :destroy, inverse_of: :profile

  # Sync with external API data
  def self.sync_from_api(user_data)
    profile = find_by(pd_id: user_data["pd_id"])

    attributes = {
      email: user_data["email"],
      first_name: user_data["first_name"],
      last_name: user_data["last_name"]
    }

    if profile
      profile.update(attributes)
    else
      profile = create(attributes.merge(pd_id: user_data["pd_id"]))
    end

    profile
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  # Application-specific profile data methods (see bio as example)
  # def update_bio(text)
  #   update(bio: text)
  # end


end
