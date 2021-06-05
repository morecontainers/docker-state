#require "http/server"
require "router"
require "json"
require "docker"
require "socket"

class WebServer
  include Router
  @client = Docker.client
  @server : HTTP::Server | Nil

  def draw_routes
    get "/:id" do |context, params|
      id = params["id"]
      #context.response.print Docker.client.containers
      #res = Docker.client.post("/containers/#{id}")
      res = Docker.client.get "/v1.30/containers/#{id}/json"
      context.response.status_code = res.status_code
      if res.status_code != 200
        context.response.print res.body
        context
      else
        #res = @client.post("/containers/#{id}")
        #case res.status_code
        #when 404
        #  raise Docker::Client::Exception.new("no such container")
        #when 500
        #  raise Docker::Client::Exception.new("server error")
        #end
        state_json = Hash(String, JSON::Any).from_json(res.body)
        context.response.print state_json["State"].to_json, "\n"
        context
      end
    end
  end

  def run
    @client = Docker::Client.new
    server = HTTP::Server.new(route_handler)
    address = server.bind_tcp 8080
    puts "Listening on http://#{address}"
    server.listen
  end
end

#{'Dead': False,
# 'Error': '',
# 'ExitCode': 0,
# 'FinishedAt': '2021-01-09T19:45:21.120602084Z',
# 'OOMKilled': False,
# 'Paused': False,
# 'Pid': 171432,
# 'Restarting': False,
# 'Running': True,
# 'StartedAt': '2021-06-05T11:24:27.11380333Z',
# 'Status': 'running'}
#

struct State
  include JSON::Serializable
  @Dead       : Bool
  @Error      : String
  @ExitCode   : Int32
  @FinishedAt : String
  @OOMKilled  : Bool
  @Paused     : Bool
  @Pid        : Int32
  @Restarting : Bool
  @Running    : Bool
  @StartedAt  : String
  @Status     : String
end

# Docker.client.info
# #containers = Docker.client.containers
# #info = Docker.client.info
# res = Docker.client.get "/v1.30/containers/hello/json"
# case res.status_code
# when 404
#   pp "no such container"
# when 500
#   pp "server error"
# end
# #puts res.body
# #puts "--------------------"
# state_json = Hash(String, JSON::Any).from_json(res.body)
# p state_json["State"]
# #puts State.from_json(state_json["State"])
# puts "------------------------------"
# #puts State.from_json(state_json)

#p containers.first
#p info

web_server = WebServer.new
web_server.draw_routes
web_server.run
