# AI-assisted — prompt: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer".
# Generated shared Google OAuth mocks, callback login, and mock-state isolation for both suites.
require "omniauth"

module OmniauthHelper
  def mock_google_auth
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "123456",
      info: {
        email: "admin@example.com",
        name: "Test Admin",
        image: "https://example.com/avatar.png"
      },
      credentials: { token: "fake-google-token", expires_at: 4_102_444_800 }
    )
  end

  def sign_in_with_google
    mock_google_auth
    visit admin_google_oauth2_omniauth_callback_path
    page.assert_current_path(root_path)
  end

  def preserve_omniauth_mock_state
    @original_omniauth_mock_auth = OmniAuth.config.mock_auth.dup
  end

  def restore_omniauth_mock_state
    OmniAuth.config.mock_auth = @original_omniauth_mock_auth
  end
end
