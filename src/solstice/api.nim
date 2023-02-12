import asyncdispatch except Callback
import asynchttpserver
import strformat
import strutils
import sequtils
import options
import sugar
import uri
import handler
import callback
import container
import route
import response

type
  Solstice* = ref object
    routes*: seq[Handler]
    port: int

proc newSolstice*(port: int): Solstice =
  new result
  result.routes = @[]
  result.port = port

proc newSolstice*(): Solstice =
  newSolstice(5000)

proc add(app: var Solstice, route: string, httpMethod: HttpMethod, handler: RequestHandler) =
  app.routes.add(newHandler(route, httpMethod, handler))

proc delete*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpDelete, handler)

proc put*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpPut, handler)

proc post*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpPost, handler)

proc get*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpGet, handler)

proc register*(app: var Solstice, container: Container) =
  for handler in container.routes:
    app.add(handler.route, handler.reqMethod, handler.handler)

proc pathMatch(route: string, url: Uri): bool =
  let
    rSplit = route.split("/")
    uSplit = ($url).split("/")

  if rSplit.len != uSplit.len:
    return false

  for (rSec, uSec) in zip(rSplit, uSplit):
    if not rSec.startsWith("{") and not rSec.endsWith("}"):
      if rSec == uSec: continue
      else: return false

    let
      rSpl = rSec.split(":")
      uSecKind = if uSec[0].isDigit(): "int" else: "string"
      rSecKind = rSpl[1].substr(0, rSpl[1].len-2)

    if rSecKind != uSecKind:
      return false
  true

proc getRoute(app: Solstice, request: Request): Option[Handler] =
  for handler in app.routes:
    if pathMatch(handler.route, request.url):
      if handler.reqMethod == request.reqMethod:
        return some(handler)
  none(Handler)

proc getHandler(app: Solstice, request: Request): Handler =
  let res = app.getRoute(request)
  if res.isSome:
    res.get()
  else:
    newHandler(
      "",
      HttpGet,
      ((req: Request, args: RequestArgs) => newResponse(Http404, "Page Not Found"))
    )

proc getVariables(app: Solstice, request: Request): seq[RouteVariable] =
  let res = app.getRoute(request)
  if isNone res:
    return @[]

  let route = res.get().route
  for (rSec, uSec) in zip(route.split("/"), ($request.url).split("/")):
    if rSec.startsWith("{") and rSec.endsWith("}"):
      let
        rSplit = rSec.split(":")
        name = rSplit[0].substr(1, rSplit[0].len-1)
        kind = rSplit[1].substr(0, rSplit[1].len-2)

      if uSec[0].isDigit and kind == "int":
        result.add(newRouteVariable(name, uSec.parseInt))
      else:
        result.add(newRouteVariable(name, uSec))

proc createCallback(app: Solstice): Future[Callback] {.async.} =
  proc callback(request: Request) {.async.} =
    echo &"Received Request To: {request.url}"
    let
      handler = app.getHandler(request)
      args = app.getVariables(request)
      response = handler.handler(request, args)

    await request.respond(response.code, response.msg, response.headers)

  return callback

proc run*(app: Solstice) {.async.} =
  let
    server = newAsyncHttpServer()
    callback = await app.createCallback()

  echo fmt"Starting Server on Port: {app.port}"
  waitFor server.serve(Port(app.port), callback)
