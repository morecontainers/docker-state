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

  def container_handler(method, context, params) : HTTP::Server::Context
    id = params["id"]
    response = Docker.client.get "/v1.30/containers/#{id}/json"
    context.response.content_type = "application/json"
    if !response.status.success?
      context.response.status_code = response.status_code
      if method == "get"
        context.response.print response.body
      end
      context
    else
      state = State.from_json response.body, root: "State"
      unless state.running?
        context.response.status_code = 404
      end
      if method == "get"
        state.to_json context.response
        context.response.print "\n"
      end
      context
    end
  end

  def compose_handler(method, context, params) : HTTP::Server::Context
    project = params["project"]
    response = Docker.client.get "/v1.30/containers/json?all=true&filters={\"label\":[\"com.docker.compose.project=#{project}\"]}"
    context.response.content_type = "application/json"   # NOTE: This does not seem to work
    if !response.status.success?
      context.response.status_code = response.status_code
      if method == "get"
        context.response.print response.body
      end
    else
      stackIds = Array(String).new
      Array(JSON::Any).from_json response.body do |el|
        stackIds.push el["Id"].as_s
      end
      if stackIds.empty?
        context.response.status_code = 404
      else
        states = Hash(String, State).new
        stackIds.each do |id|
          response = Docker.client.get "/v1.30/containers/#{id}/json"
          name = (String.from_json response.body, root: "Name").delete("/")
          # name = name.delete("/")
          state = State.from_json response.body, root: "State"
          states[name] = state
        end
        if method == "get"
          states.to_json context.response
          context.response.print "\n"
        end
        all_ok = states.all? {|_, state| state.running? }
        context.response.status_code = all_ok ? 200 : 404
      end
    end
    context
  end

  def draw_routes
    get "/compose/:project" { |context, params| compose_handler("get", context, params) }
    head "/compose/:project" { |context, params| compose_handler("head", context, params) }
    # TODO: Move container endpoint to /container/:id
    # get "/container/:id" { |context, params| container_handler("get", context, params) }
    # head "/container/:id" { |context, params| container_handler("head", context, params) }
    get "/:id" { |context, params| container_handler("get", context, params) }
    head "/:id" { |context, params| container_handler("head", context, params) }
  end

  def run
    server = HTTP::Server.new([HTTP::LogHandler.new, route_handler])
    address = server.bind_tcp "0.0.0.0", LISTEN_PORT
    puts "Listening on http://#{address}"
    server.listen
  end
end

web_server = WebServer.new
web_server.draw_routes
web_server.run
