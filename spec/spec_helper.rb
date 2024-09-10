# frozen_string_literal: true

##
require 'pry'
require 'digest/md5'
require 'dotenv/load'
require 'securerandom'
##
require 'takuya/xoauth2'
##
require_relative '../lib/takuya/gmail-forwarder'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.raise_errors_for_deprecations!
  Dotenv.load('.env', '.env.sample')
  ENV['client_secret_path'] = File.realpath ENV['client_secret_path']
  ENV['token_path'] = File.realpath ENV['token_path']
  ENV['user_id'] = ENV['user_id'].strip
  ##
  raise "Empty file (#{ENV['token_path']})." unless YAML.load_file(ENV['token_path'])
  ENV['user_id'] = YAML.load_file(ENV['token_path']).keys[0] if ENV['user_id'].empty?


end