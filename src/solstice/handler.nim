import
  asyncdispatch,
  asynchttpserver,
  sugar

import
  middleware,
  response,
  route

type
  RequestHandler* = ((Request, RequestArgs) {.closure, gcsafe.} -> Response)

  Handler* = ref object
    route*: string
    reqMethod*: HttpMethod
    handler*: RequestHandler
    middleware*: seq[Middleware]

proc newHandler*(route: string, reqMethod: HttpMethod, handler: RequestHandler): Handler =
  new result
  result.route = route
  result.reqMethod = reqMethod
  result.handler = handler
  result.middleware = @[]

proc invoke*(handler: Handler, request: Request, args: RequestArgs): Future[Response] {.async.} =
  # for middleware in handler.middleware:
  #   await middleware(request)

  result = handler.handler(request, args)
