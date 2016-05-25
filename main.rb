require 'bundler'
require 'net/http'

Bundler.require

configure {set :server, :puma}
Faye::WebSocket.load_adapter('puma')

# get '/get' do
#   ws = Faye::WebSocket.new request.env
#   ws.on :open do |event|
#     sockets << ws
#   end
#   ws.on :close do |event|
#     sockets.delete ws
#   end
#   ws.rack_response
# end
#
# get '/send' do
#   ws = Faye::WebSocket.new request.env
#   ws.on :message do |event|
#     sockets.each do |s|
#       s.send(event.data)
#     end
#   end
#   ws.rack_response
# end
#
# get '/tx/:tx' do |tx|
#   erb :tx, :locals => {:param1 => tx}
# end
#
# get '/' do
#   erb :index
# end
#
# get '/broadcast' do
#   erb :broadcast
# end

###########

# Pages

get '/' do
  erb :index
end

get '/wallet/:id' do |id|
  erb :wallet, locals: {:id => id}
end

get '/trade/:id' do |id|
  erb :trade, locals: {:id => id}
end

get '/user/:id' do |id|
  erb :user, locals: {:id => id}
end

# APIs

transition_sockets = Array.new
get '/transition' do
  ws = Faye::WebSocket.new request.env
  ws.on :open do |event|
    transition_sockets << ws
  end
  ws.on :close do |event|
    transition_sockets.delete ws
  end
  ws.on :error do |event|
    transition_sockets.delete ws
  end
  ws.rack_response
end

# Listen
Thread.new {
  EM.run {
    ws = Faye::WebSocket::Client.new('wss://ws.blockchain.info/inv')
    ws.on :open do |event|
      ws.send('{"op":"unconfirmed_sub"}')
    end
    ws.on :message do |event|
      data = JSON.parse(event.data)
      if data['op'] == 'utx'
        puts event.data
      end
    end
  }
}