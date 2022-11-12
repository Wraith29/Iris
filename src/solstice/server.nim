import
  asynchttpserver,
  httpcore,
  asyncnet,
  nativesockets,
  strutils,
  uri

import
  asyncdispatch except Callback

import
  callback

func toHttpMethod(reqMethod: string): HttpMethod =
  case reqMethod:
  of "GET": result = HttpGet
  of "POST": result = HttpPost
  of "HEAD": result = HttpHead
  of "PUT": result = HttpPut
  of "DELETE": result = HttpDelete
  of "PATCH": result = HttpPatch
  of "OPTIONS": result = HttpOptions
  of "CONNECT": result = HttpConnect
  of "TRACE": result = HttpTrace
  else: discard

type
  Server* = ref object
    socket: AsyncSocket
    port: Port
    callback: Callback

proc newServer*(port: Port, callback: Callback): Server =
  new result
  result.socket = newAsyncSocket(AF_INET)
  result.port = port
  result.callback = callback

proc newServer*(port: int, callback: Callback): Server =
  newServer(Port(port), callback)

proc serve*(server: Server) {.async.} =
  server.socket.setSockOpt(OptReuseAddr, true)
  server.socket.setSockOpt(OptReusePort, true)
  server.socket.bindAddr(server.port, "")
  server.socket.listen()

  while true:
    var (address, client) = await server.socket.acceptAddr()
    # let req = newFutureVar[Request]("Solstice.server.serve")
    # template request: Request =
    #   req.mget()
    
    let
      data = (await client.recvLine()).split(' ')
      reqMethod = data[0].toUpper().toHttpMethod()
      route = data[1].parseUri()
      protocol = data[2]
    
    echo "ReqMethod: ", reqMethod
    echo "Route:     ", route
    echo "Protocol:  ", protocol