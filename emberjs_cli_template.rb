gem "ember-cli-rails"
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
### setup Emberjs ###
after_bundle do
  generate 'ember:init'
  run 'ember new frontend --skip-git'
  rake 'ember:install'
  inject_into_file 'config/routes.rb', after: "Rails.application.routes.draw do\n" do <<-CODE
    mount_ember_app :frontend, to: '/'
  CODE
  end
  inside('frontend') do
    puts '###########################################'
    run 'npm cache clean'
    run 'rm -r node_modules'
    run 'npm install --save-dev'
    run 'bower install'
    run 'ember install ember-cli-rails-addon'
    puts '###########################################'
  end
end
