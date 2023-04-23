import asyncdispatch
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
import log

type Solstice* = ref object
  routes*: seq[Handler]
  port: int
  cors: seq[string]


proc newSolstice*(port: int): Solstice =
  new result
  result.routes = @[]
  result.port = port


proc newSolstice*(): Solstice =
  newSolstice(5000)


proc add(app: var Solstice; route: string; httpMethod: HttpMethod; handler: RequestHandler) =
  app.routes.add(newHandler(route, httpMethod, handler))


proc delete*(app: var Solstice; route: string; handler: RequestHandler) =
  app.add(route, HttpDelete, handler)


proc put*(app: var Solstice; route: string; handler: RequestHandler) =
  app.add(route, HttpPut, handler)


proc post*(app: var Solstice; route: string; handler: RequestHandler) =
  app.add(route, HttpPost, handler)


proc get*(app: var Solstice; route: string; handler: RequestHandler) =
  app.add(route, HttpGet, handler)


proc register*(app: var Solstice; container: Container) =
  for handler in container.routes:
    app.add(handler.route, handler.reqMethod, handler.handler)


proc pathMatch(route: string; url: Uri): bool =
  let routeSplit = route.split("/")
  let urlSplit = ($url).split("/")

  if routeSplit.len != urlSplit.len:
    return false

  for (routeSection, urlSection) in zip(routeSplit, urlSplit):
    if not routeSection.startsWith("{") and not routeSection.endsWith("}"):
      if routeSection == urlSection: continue
      else: return false

    let rSpl = routeSection.split(":")
    let uSecKind = if urlSection[0].isDigit(): "int" else: "string"
    let rSecKind = rSpl[1].substr(0, rSpl[1].len-2)

    if rSecKind != uSecKind:
      return false
  return true


proc getRoute(app: Solstice; request: Request): Option[Handler] =
  for handler in app.routes:
    if pathMatch(handler.route, request.url):
      if handler.reqMethod == request.reqMethod:
        return some(handler)
  none(Handler)


proc getHandler(app: Solstice; request: Request): Handler =
  let res = app.getRoute(request)
  if res.isSome:
    return res.get()
  else:
    let handler = (req: Request, args: RequestArgs) => newResponse(Http404, "Page Not Found")
    let notFoundHandler = newHandler("", HttpGet, handler)
    
    return notFoundHandler


proc getVariables(app: Solstice; request: Request): seq[RouteVariable] =
  let res = app.getRoute(request)
  if isNone res:
    return @[]

  let route = res.get().route
  for (routeSection, urlSection) in zip(route.split("/"), ($request.url).split("/")):
    if routeSection.startsWith("{") and routeSection.endsWith("}"):
      let rSplit = routeSection.split(":")
      let name = rSplit[0].substr(1, rSplit[0].len-1)
      let kind = rSplit[1].substr(0, rSplit[1].len-2)

      if urlSection[0].isDigit and kind == "int":
        result.add(newRouteVariable(name, urlSection.parseInt))
      else:
        result.add(newRouteVariable(name, urlSection))


proc addCorsOrigins*(app: var Solstice; origins: varargs[string]) =
  for origin in origins:
    app.cors.add(origin)


proc createCallback(app: Solstice): Future[CallbackFn] {.async.} =
  proc callback(request: Request) {.async.} =
    log fmt"Received {$request.reqMethod} Request To: {$request.url}"
    let handler = app.getHandler(request)
    let args = app.getVariables(request)
    var response = handler.handler(request, args)

    for origin in app.cors:
      response.addHeader("Access-Control-Allow-Origin", origin)

    await request.respond(response.code, response.msg, response.headers)

  return callback


proc run*(app: Solstice; debug: bool = false) {.async.} =
  let server = newAsyncHttpServer()
  let callback = await app.createCallback()

  if debug:
    for handler in app.routes:
      log fmt"[{handler.reqMethod}] http://localhost:{app.port}{handler.route}"

  log fmt"Starting Server on Port: {app.port}"
  waitFor server.serve(Port(app.port), callback)
