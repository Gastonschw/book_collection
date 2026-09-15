# location: spec/feature/integration_spec.rb
# AI-assisted (OpenAI/agent), 9/14/26 — prompt: "test creation notices on home and the dedicated delete confirmation flow".
require 'rails_helper'

RSpec.describe 'Creating a book', type: :feature do
  scenario 'valid inputs' do
    visit new_book_path
    fill_in 'book[title]', with: 'harry potter'
    click_on 'Create Book'
    expect(page).to have_current_path(books_path)
    expect(page).to have_content('Book was successfully created.')
    expect(page).to have_content('harry potter')
  end

  scenario 'invalid inputs' do
    visit new_book_path
    fill_in 'book[title]', with: ''
    click_on 'Create Book'
    expect(page).to have_content("Title can't be blank")
  end
end

RSpec.describe 'Deleting a book', type: :feature do
  scenario 'confirming deletion returns home with a notice and removes the book' do
    book = Book.create!(title: 'The Hobbit')

    visit delete_book_path(book)
    expect(page).to have_content("Are you sure you want to delete 'The Hobbit'?")
    expect(Book.exists?(book.id)).to be true

    click_on 'Yes, delete'

    expect(page).to have_current_path(books_path)
    expect(page).not_to have_content('The Hobbit')
    expect(page).to have_content('Book was successfully deleted.')
    expect(Book.exists?(book.id)).to be false
  end
end
