# Install required gems
gem 'react-rails', '~> 1.6.0'
gem 'lodash-rails' '~4.3.0'
gem_group :test, :development do
  gem 'thin'
  gem 'quiet_assets'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'spork', '~> 1.0rc'
  gem 'guard', require: false
  gem 'guard-spork'
  gem 'guard-rspec', require: false
  gem 'guard-livereload', '~> 2.5.2', require: false
end
### Install gems ###
run 'bundle install'
### Install rspec ###
generate 'rspec:install'
### Install guard ###
run 'bundle exec guard init'
### Install Spork ###
run 'spork --bootstrap'
remove_file 'spec/spec_helper.rb'
file 'spec/spec_helper.rb', <<-CODE
require 'rubygems'
require 'spork'
require 'database_cleaner'

Spork.prefork do
  ENV['RAILS_ENV'] ||= 'test'
  require File.expand_path('../../config/environment', __FILE__)
  require 'rspec/rails'
  require 'capybara/rspec'

  Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

  DatabaseCleaner.strategy = :truncation

  RSpec.configure do |config|
    config.mock_with :rspec
    config.include FactoryGirl::Syntax::Methods
    config.use_transactional_fixtures = true
    config.infer_base_class_for_anonymous_controllers = false
    config.order = "random"
  end
end

Spork.each_run do
  FactoryGirl.reload
  DatabaseCleaner.clean
end
CODE
### configure rubocop ###
file '.rubocop.yml', <<-CODE
AllCops:
  Exclude:
    - '**/Guardfile'
Metrics/LineLength:
  Max: 127
CODE
### Setup Reactjs ###
generate 'react:install'
remove_file 'app/assets/application.js'
file 'app/assets/application.coffee', <<-CODE
#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require react
#= require react_ujs
#= require lodash
#= require components
#= require_tree .
CODE

inject_into_file 'config/environments/development.rb', after: "# Settings specified here will take precedence over those in config/application.rb.\n" do <<-CODE
  config.react.variant = :development
CODE
end

inject_into_file 'config/environments/production.rb', after: "# Settings specified here will take precedence over those in config/application.rb.\n" do <<-CODE
  config.react.variant = :production
CODE
end

# Post setup must do manually
after_bundle do
  puts '###### TODO ######'
  puts 'Move spork tasks block before rspec tasks block in Guardfile.'
  puts 'You should install Alt.js for flux integration.'
  puts '##################'
end
