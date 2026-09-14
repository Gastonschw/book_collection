# location: spec/feature/integration_spec.rb
require 'rails_helper'

RSpec.describe 'Creating a book', type: :feature do
  scenario 'valid inputs' do
    visit new_book_path
    fill_in 'book[title]', with: 'harry potter'
    click_on 'Create Book'
    visit books_path
    expect(page).to have_content('harry potter')
  end

  scenario 'invalid inputs' do
    visit new_book_path
    fill_in 'book[title]', with: ''
    click_on 'Create Book'
    expect(page).to have_content("Title can't be blank")
  end
end
