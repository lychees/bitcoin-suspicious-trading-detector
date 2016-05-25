require 'bundler'
require 'sinatra'
require 'net/http'

Bundler.require

configure {set :server, :puma}
Faye::WebSocket.load_adapter('puma')

sockets = Array.new

get '/get' do
  ws = Faye::WebSocket.new request.env

  ws.on :open do |event|
    sockets << ws
  end

  ws.on :close do |event|
    sockets.delete ws
  end

  ws.rack_response
end

get '/send' do
  ws = Faye::WebSocket.new request.env

  ws.on :message do |event|
    sockets.each do |s|
      s.send(event.data)
    end
  end

  ws.rack_response
end

get '/hello/tfh' do
  "Hello World"
end

get '/tx/:id' do |id|
  erb :tx, :locals => {:param1 => id}
end


get '/' do
  erb :index
end

get '/broadcast' do
  erb :broadcast
end