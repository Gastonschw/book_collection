# AI-assisted — prompt: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer"; generated the OAuth-only Admin and email-based account lookup.
class Admin < ApplicationRecord
  devise :omniauthable, omniauth_providers: [ :google_oauth2 ]

  def self.from_google(email:, full_name:, uid:, avatar_url:)
    create_with(uid: uid, full_name: full_name, avatar_url: avatar_url).find_or_create_by!(email: email)
  end
end
