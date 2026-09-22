# AI-assisted — prompt: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer".
# Authenticated existing browser CRUD scenarios through the shared Google callback mock.
# AI-assisted (OpenAI/agent), 9/14/26 — prompt: "update scaffold flows for home redirects and dedicated delete confirmation".
require "application_system_test_case"

class BooksTest < ApplicationSystemTestCase
  setup do
    @book = books(:one)
    sign_in_with_google
  end

  test "visiting the index" do
    visit books_url
    assert_selector "h1", text: "Books"
  end

  test "should create book" do
    visit books_url
    click_on "New book"

    fill_in "Title", with: @book.title
    click_on "Create Book"

    assert_text "Book was successfully created"
    assert_current_path books_path
  end

  test "should update Book" do
    visit book_url(@book)
    click_on "Edit this book", match: :first

    fill_in "Title", with: @book.title
    click_on "Update Book"

    assert_text "Book was successfully updated"
    assert_current_path books_path
  end

  test "should destroy Book" do
    visit book_url(@book)
    click_on "Delete"
    assert_current_path delete_book_path(@book)
    click_on "Yes, delete"

    assert_current_path books_path
    assert_text "Book was successfully deleted."
  end
end
