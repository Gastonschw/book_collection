# AI-assisted — prompt: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer"; configured OAuth-only authentication with ENV credentials and Turbo-compatible responses.
Devise.setup do |config|
  require "devise/orm/active_record"

  config.omniauth :google_oauth2, ENV["GOOGLE_OAUTH_CLIENT_ID"], ENV["GOOGLE_OAUTH_CLIENT_SECRET"]
  config.responder.error_status = :unprocessable_content
  config.responder.redirect_status = :see_other
end
