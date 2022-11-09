import 
  asynchttpserver,
  asyncdispatch,
  uri,
  sequtils,
  sugar,
  strformat,
  strutils,
  options

import
  response,
  route

type
  Callback = (Request {.closure, gcsafe.} -> Future[void])

  RequestArgs* = varargs[RouteVariable]

  RequestHandler = ((Request, RequestArgs) {.closure, gcsafe.} -> Response)

  Handler = ref object
    route: string
    reqMethod: HttpMethod
    handler: RequestHandler

  Solstice* = ref object
    routes: seq[Handler]

func newSolstice*(): Solstice =
  Solstice(routes: @[])

func `[]`*(args: RequestArgs, name: string): RouteVariable =
  for arg in args:
    if arg.name == name:
      return arg

func newHandler*(route: string, reqMethod: HttpMethod, handler: RequestHandler): Handler =
  Handler(route: route, reqMethod: reqMethod, handler: handler)

proc pathMatch*(route: string, url: Uri): bool =
  let
    rSplit = route.split("/")
    uSplit = ($url).split("/")

  if rSplit.len != uSplit.len:
    return false

  for (rSec, uSec) in zip(rSplit, uSplit):
    if not rSec.startsWith("{") and not rSec.endsWith("}"):
      if rSec == uSec: continue
      else: return false
  true

func add*(app: var Solstice, route: string, httpMethod: HttpMethod, handler: RequestHandler) =
  app.routes.add(newHandler(route, httpMethod, handler))

func delete*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpPut, handler)

func put*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpPut, handler)

func post*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpPost, handler)

func get*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpGet, handler)

func getRoute(app: Solstice, request: Request): Option[Handler] =
  for handler in app.routes:
    if pathMatch(handler.route, request.url):
      if handler.reqMethod == request.reqMethod:
        return some(handler)
  none(Handler)

proc getHandler(app: Solstice, request: Request): RequestHandler =
  let res = app.getRoute(request)
  if res.isSome:
    res.get.handler
  else:
    ((r: Request, _: varargs[RouteVariable]) => newResponse(Http404, "Page Not Found"))

proc getVariables(app: Solstice, request: Request): seq[RouteVariable] =
  let res = app.getRoute(request)
  if res.isNone:
    return @[]
  let route = res.get().route
  for (rSec, uSec) in zip(route.split("/"), ($request.url).split("/")):
    if rSec.startsWith("{") and rSec.endsWith("}"):
      let
        rSplit = rSec.split(":")
        name = rSplit[0].substr(1, rSplit[0].len-1)
      if uSec[0].isDigit:
        result.add(newRouteVariable(name, uSec.parseInt))
      else:
        result.add(newRouteVariable(name, uSec))

proc createCallback(app: Solstice): Future[Callback] {.async.} =
  proc callback(request: Request): Future[void] {.async.} =
    echo &"Received Request To: {request.url}"
    let
      handler = app.getHandler(request)
      vars = app.getVariables(request)
      response = handler(request, vars)
    
    await request.respond(response.code, response.msg, response.headers)

  return callback

proc run*(app: Solstice) {.async.} =
  let 
    server = newAsyncHttpServer()
    callback = await app.createCallback()

  waitFor server.serve(Port(5000), callback)