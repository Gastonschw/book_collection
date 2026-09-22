# AI-assisted — prompt: "Get Heroku up"; migrate before each release and run Puma on the assigned port.
release: bundle exec rails db:migrate
web: bundle exec puma -C config/puma.rb
