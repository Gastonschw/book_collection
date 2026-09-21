# AI-assisted — prompt: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer"; added authentication and local ENV loading dependencies.
source "https://rubygems.org"

gem "rails", "~> 8.0.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "rexml"
gem "json", "< 3"
gem "devise", "~> 4.9"
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "omniauth-google-oauth2", "~> 1.1"

# gem "bcrypt", "~> 3.1.7"

gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

# gem "image_processing", "~> 1.2"

group :development, :test do
  gem "dotenv-rails"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
