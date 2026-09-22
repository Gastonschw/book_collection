# AI-assisted — prompt: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer".
# Shared callback mocks with automatic cleanup and opt-in sandbox disabling for root-run test Chrome.
require "test_helper"
require_relative "../spec/support/omniauth_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include OmniauthHelper

  setup :preserve_omniauth_mock_state
  teardown :restore_omniauth_mock_state

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_argument("--no-sandbox") if ENV["CHROME_NO_SANDBOX"] == "1"
  end
end
