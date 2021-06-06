# docker-state

Docker container state and health check.

TODO: Implement tests.

## Building

    shards build

## Example use

Returns status code 200 if and only if container is healthy.

Example use:

    ❯ docker run -d --rm --name=docker-state \
                 -v /var/run/docker.sock:/var/run/docker.sock \
                 -p 3000:3000 \
		 morecontainers/docker-state
    1e9e61d7d59ecb085360dde1241e4003ad157b0cf51e69ae60cb104ffaa5565a
    ❯ docker run -d --rm --name=hello alpine tail -f /dev/null
    ❯ curl -I localhost:3000/hello
    HTTP/1.1 200 OK
    Connection: keep-alive
    Content-Length: 0
    ❯ docker kill hello
    hello
    ❯ docker run -d --name=hello-world hello-world
    9a95d317e186bee47308dd50b59b186e8546eaef6a2f349d595a557b816c76de
    ❯ curl -v localhost:3000/hello-world                                                                                                        ⏎
    *   Trying 127.0.0.1:3000...
    * TCP_NODELAY set
    * Connected to localhost (127.0.0.1) port 3000 (#0)
    > GET /hello-world HTTP/1.1
    > Host: localhost:3000
    > User-Agent: curl/7.68.0
    > Accept: */*
    >
    * Mark bundle as not supporting multiuse
    < HTTP/1.1 404 Not Found
    < Connection: keep-alive
    < Transfer-Encoding: chunked
    <
    {"Dead":false,"Error":"","ExitCode":0,"FinishedAt":"2021-06-05T12:49:06.985669184Z","OOMKilled":false,"Paused":false,"Pid":0,"Restarting":false,"Running":false,"StartedAt":"2021-06-05T12:49:06.96204151Z","Status":"exited"}
    * Connection #0 to host localhost left intact
    ❯ docker rm hello-world
    ❯ docker kill docker-state

