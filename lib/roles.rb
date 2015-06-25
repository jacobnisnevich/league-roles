require 'json'
require 'yaml'
require 'lol'

[
  "chat_parser.rb"
].each do |file_name|
  require File.expand_path("../league-roles/#{file_name}", __FILE__)
end