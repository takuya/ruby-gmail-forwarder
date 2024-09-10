#!/usr/bin/env ruby
# coding: utf-8

require 'rubygems'
require 'pry'

require_relative '../lib/takuya/gmail-forwarder'

Thread.abort_on_exception = true
$DEBUG = true

require 'dotenv/load'
Dotenv.load('.env', '.env.sample')
user_id = YAML.load_file(ENV["token_path"]).keys[0]
host = '127.0.25.25'
port = '2525' # rand(49151...65535)
GMailForwarderServer = Takuya::GMailForwarderServer

server = GMailForwarderServer.new(
  user_id: user_id,
  token_path: ENV['token_path'],
  client_secret_path: ENV['client_secret_path'],
  hosts: host,
  ports: port
)
puts :debug_smtp_server
puts " write binding.pry in gmail_forwarder"
server.start
server.join
