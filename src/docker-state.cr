require "http/server"
require "json"
require "docker"

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

server = HTTP::Server.new do |context|
  method = context.request.method.upcase
  if method != "GET" && method != "HEAD"
    raise Exception.new "Invalid method #{method}"
  end
  if /\/[a-z0-9]*/ =~ context.request.resource
    id = context.request.resource.delete_at(0)
  else
    raise Exception.new("invalid path: #{context.request.resource}")
  end
  response = Docker.client.get "/v1.30/containers/#{id}/json"
  if response.status.success?
    case method
    when "GET"
      state = State.from_json response.body, root: "State"
      context.response.status_code = state.running? ? 200 : 404
      context.response.content_type = "application/json"
      state.to_json context.response
      context.response.print "\n"
    when "HEAD"
      state = State.from_json response.body, root: "State"
      context.response.status_code = state.running? ? 200 : 404
    end
  else
    context.response.status_code = response.status_code
    if method == "GET"
      context.response.content_type = response.content_type.not_nil!
      context.response.print response.body
    end
  end
  puts "#{method} /#{id} #{context.response.status_code}"
end

address = server.bind_tcp "0.0.0.0", 3000
puts "Listening on http://#{address}"
server.listen
