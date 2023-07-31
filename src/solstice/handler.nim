import asynchttpserver
import sugar
import response
import route

type RequestHandler* = ((Request, RequestArgs) {.closure, gcsafe.} -> Response)


type Handler* = ref object
  route*: string
  reqMethod*: HttpMethod
  handler*: RequestHandler


proc newHandler*(route: string; reqMethod: HttpMethod; handler: RequestHandler): Handler =
  return Handler(
    route: route,
    reqMethod: reqMethod,
    handler: handler
  )
