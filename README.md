# docker-state

Docker container state and health check.

## Requirements

Tested on: Node v12; Express v4; and [apocas/dockerode] v3.

[apocas/dockerode]: https://github.com/apocas/dockerode

## Example use

Returns status code 200 if and only if container is healthy.

Example use:

    $ curl -I http://localhost:3000/node
    HTTP/1.1 200 OK
    X-Powered-By: Express
    Content-Type: application/json; charset=utf-8
    Content-Length: 5770
    ETag: W/"168a-5eUBcpHavWjKjs0OWb8kmeXZdVs"
    Date: Thu, 04 Jun 2020 13:48:10 GMT
    Connection: keep-alive

## TODO

Use a smaller framework than express, or no framework at all?
