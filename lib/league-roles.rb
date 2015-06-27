require 'json'
require 'yaml'
require 'lol'

[
  "role_synonyms.rb",
  "graphmatch.rb",
  "chat_parser.rb"
].each do |file_name|
  require File.expand_path("../league-roles/#{file_name}", __FILE__)
end
