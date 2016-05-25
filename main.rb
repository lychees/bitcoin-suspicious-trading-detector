require 'bundler'
require 'net/http'

Bundler.require

configure {set :server, :puma}
Faye::WebSocket.load_adapter('puma')

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
    @geo = GeoIP.new('GeoLiteCity.dat')
    ws = Faye::WebSocket::Client.new('wss://ws.blockchain.info/inv')
    ws.on :open do |event|
      ws.send('{"op":"unconfirmed_sub"}')
    end
    ws.on :message do |event|
      data = JSON.parse(event.data)
      if data['op'] == 'utx'
        transition_sockets.each do |socket|
          unless GeoIP.new('GeoLiteCity.dat').country(data['x']['relayed_by']).nil?
            socket.send(JSON.fast_unparse({
                                              sender: data['x']['inputs'][0]['prev_out']['addr'],
                                              receiver: data['x']['out'][0]['addr'],
                                              value: (data['x']['inputs'].map{
                                                  |x| x['prev_out']['value']}.reduce(:+)).to_f * (10 ** -8),
                                              country: GeoIP.new('GeoLiteCity.dat').country(data['x']['relayed_by']).country_name
                                          }))
          end
        end
      end
    end
  }
}