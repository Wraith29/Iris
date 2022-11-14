import
  asyncdispatch,
  asynchttpserver,
  sugar

type
  Middleware* = (Request {.async.} -> Future[void])

proc debugMiddleware*(request: Request) =
  echo request
