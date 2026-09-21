# AI-assisted — prompt: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer"; required an authenticated Admin for application actions.
class ApplicationController < ActionController::Base
  before_action :authenticate_admin!

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
