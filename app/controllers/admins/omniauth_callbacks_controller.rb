# AI-assisted — prompt: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer"; generated Google account sign-in and success/failure redirects.
class Admins::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    admin = Admin.from_google(**from_google_params)
    return_to = stored_location_for(admin)
    sign_out_all_scopes
    store_location_for(admin, return_to) if return_to
    flash[:success] = t "devise.omniauth_callbacks.success", kind: "Google"
    sign_in_and_redirect admin, event: :authentication
  end

  protected

  def after_omniauth_failure_path_for(_scope)
    new_admin_session_path
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || root_path
  end

  private

  def from_google_params
    auth = request.env["omniauth.auth"]
    {
      uid: auth.uid, email: auth.info.email,
      full_name: auth.info.name, avatar_url: auth.info.image
    }
  end
end
