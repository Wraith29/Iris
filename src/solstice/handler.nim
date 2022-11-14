import
  asynchttpserver,
  sugar

import
  response,
  route

type
  RequestHandler* = ((Request, RequestArgs) {.closure, gcsafe.} -> Response)

  Handler* = ref object
    route*: string
    reqMethod*: HttpMethod
    handler*: RequestHandler

proc newHandler*(route: string, reqMethod: HttpMethod, handler: RequestHandler): Handler =
  new result
  result.route = route
  result.reqMethod = reqMethod
  result.handler = handler
