import std/[asynchttpserver, strutils, sugar]
import ./[response, route]

type RequestHandler* = ((Request, RequestArgs) {.closure, gcsafe.} -> Response)

type Handler* = ref object
  route*: string
  reqMethod*: HttpMethod
  handler*: RequestHandler

func normaliseRoute(route: string): string =
  route.replace("//", "/")

func newHandler*(route: string; reqMethod: HttpMethod; handler: RequestHandler): Handler =
  return Handler(
    route: normaliseRoute route,
    reqMethod: reqMethod,
    handler: handler
  )
