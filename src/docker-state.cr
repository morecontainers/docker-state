require "router"
require "json"
require "docker"
require "socket"

LISTEN_PORT = 3000

struct State
  include JSON::Serializable
  @[JSON::Field(key: "Dead")]
  getter dead        : Bool
  @[JSON::Field(key: "Error")]
  getter error       : String
  @[JSON::Field(key: "ExitCode")]
  getter exit_code   : Int32
  @[JSON::Field(key: "FinishedAt")]
  getter finished_at : String
  @[JSON::Field(key: "OOMKilled")]
  getter oom_killed  : Bool
  @[JSON::Field(key: "Paused")]
  getter paused      : Bool
  @[JSON::Field(key: "Pid")]
  getter pid         : Int32
  @[JSON::Field(key: "Restarting")]
  getter restarting  : Bool
  @[JSON::Field(key: "Running")]
  getter running     : Bool
  @[JSON::Field(key: "StartedAt")]
  getter started_at  : String
  @[JSON::Field(key: "Status")]
  getter status      : String
  def running?
    @exit_code == 0 && @running
  end
end

class WebServer
  include Router

  def draw_routes
    get "/:id" do |context, params|
      id = params["id"]
      res = Docker.client.get "/v1.30/containers/#{id}/json"
      if !res.status.success?
        context.response.status_code = res.status_code
        context.response.print res.body
        context
      else
        state = State.from_json res.body, root: "State"
        unless state.running?
          context.response.status_code = 500
        end
        state.to_json context.response
        context.response.print "\n"
        context
      end
    end
  end

  def run
    server = HTTP::Server.new(route_handler)
    address = server.bind_tcp "0.0.0.0", LISTEN_PORT
    puts "Listening on http://#{address}"
    server.listen
  end
end

web_server = WebServer.new
web_server.draw_routes
web_server.run
