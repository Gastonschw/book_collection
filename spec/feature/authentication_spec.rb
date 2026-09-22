# AI-assisted — prompt: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer".
# Generated OAuth account creation/reuse, protected URL, provider failure, logout, and stored-location scenarios.
require "rails_helper"

RSpec.describe "Google authentication", type: :feature do
  scenario "valid Google authentication persists an admin and opens the book collection" do
    Book.create!(title: "The Hobbit")
    auth = mock_google_auth

    visit admin_google_oauth2_omniauth_callback_path

    expect(page).to have_current_path(root_path)
    expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", kind: "Google"))
    expect(page).to have_content("The Hobbit")
    expect(Admin.find_by(email: auth.info.email)).to be_present
  end

  scenario "Google authentication reuses an existing admin account" do
    auth = mock_google_auth
    admin = Admin.create!(
      email: auth.info.email,
      full_name: auth.info.name,
      uid: auth.uid,
      avatar_url: auth.info.image
    )

    expect {
      visit admin_google_oauth2_omniauth_callback_path
    }.not_to change(Admin, :count)

    expect(page).to have_current_path(root_path)
    expect(Admin.find_by!(email: auth.info.email)).to eq(admin)
  end

  scenario "signed-out visitors cannot open the collection or new book form" do
    [ books_path, new_book_path ].each do |path|
      visit path

      expect(page).to have_current_path(new_admin_session_path)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  scenario "invalid Google credentials leave the visitor signed out" do
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

    visit admin_google_oauth2_omniauth_callback_path

    expect(page).to have_current_path(new_admin_session_path)

    visit root_path

    expect(page).to have_current_path(new_admin_session_path)
    expect(page).to have_content("You need to sign in or sign up before continuing.")
  end

  scenario "signing out revokes access to protected pages" do
    sign_in_with_google

    click_on "Sign Out"

    expect(page).to have_current_path(new_admin_session_path)

    visit root_path

    expect(page).to have_current_path(new_admin_session_path)
    expect(page).to have_content("You need to sign in or sign up before continuing.")
  end

  scenario "Google sign-in returns to the originally requested book form" do
    visit new_book_path
    expect(page).to have_current_path(new_admin_session_path)
    mock_google_auth

    visit admin_google_oauth2_omniauth_callback_path

    expect(page).to have_current_path(new_book_path)
    expect(page).to have_field("Title")
  end
end
