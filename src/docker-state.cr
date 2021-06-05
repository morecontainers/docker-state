require "router"
require "json"
require "docker"
require "socket"

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

class WebServer
  include Router
  @client = Docker.client
  @server : HTTP::Server | Nil

  def draw_routes
    get "/:id" do |context, params|
      id = params["id"]
      res = Docker.client.get "/v1.30/containers/#{id}/json"
      context.response.status_code = res.status_code
      if res.status_code != 200
        context.response.status_code = 500
        context.response.print res.body
        context
      else
        my_json = JSON.parse(res.body)
        state = State.from_json my_json["State"].as_s
        if state.@ExitCode != 0 || !state.@Running
          context.response.status_code = 500
        end
        context.response.print my_json["State"].to_json, "\n"
        context
      end
    end
  end

  def run
    @client = Docker::Client.new
    server = HTTP::Server.new(route_handler)
    address = server.bind_tcp "0.0.0.0", 8080
    puts "Listening on http://#{address}"
    server.listen
  end
end

web_server = WebServer.new
web_server.draw_routes
web_server.run
