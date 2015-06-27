require 'sinatra'
require 'json'

require File.expand_path('../lib/league-roles.rb', __FILE__)

get '/' do
  File.read(File.join('public', 'index.html'))
end

post '/chat' do
  parser = ChatParser.new(params[:chat], params[:region])
  puts parser.data.to_json
  parser.data.to_json
end