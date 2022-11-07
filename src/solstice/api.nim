import 
  asynchttpserver,
  asyncdispatch,
  uri,
  sequtils,
  sugar,
  strformat,
  strutils,
  options

type
  Response* = ref object
    code: HttpCode
    msg: string
    headers: HttpHeaders

  Callback = (Request {.closure, gcsafe.} -> Future[void])

  RouteVariableKind = enum
    String, Int

  RouteVariable* = ref object
    name: string
    case kind: RouteVariableKind:
    of String: strVal*: string
    of Int: intVal*: int

  RequestArgs* = varargs[RouteVariable]

  RequestHandler = ((Request, RequestArgs) {.closure, gcsafe.} -> Response)

  Handler = tuple[route: string, httpMethod: HttpMethod, handler: RequestHandler]

  Solstice* = ref object
    routes: seq[Handler]

func `[]`*(args: RequestArgs, name: string): RouteVariable =
  for arg in args:
    if arg.name == name:
      return arg

func `$`*(routeVar: RouteVariable): string =
  case routeVar.kind:
  of String: &"RouteVariable(kind: String, value: {routeVar.strVal})"
  of Int: &"RouteVariable(kind: Int, value: {routeVar.intVal})"

func newResponse*(code: HttpCode, msg: string, headers: HttpHeaders): Response =
  Response(code: code, msg: msg, headers: headers)

func newResponse*(code: HttpCode, msg: string): Response =
  Response(code: code, msg: msg, headers: newHttpHeaders())

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
  app.routes.add((route, httpMethod, handler))

func delete*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpPut, handler)

func put*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpPut, handler)

func post*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpPost, handler)

func get*(app: var Solstice, route: string, handler: RequestHandler) =
  app.add(route, HttpGet, handler)

func newSolstice*(): Solstice =
  Solstice(routes: @[])

func getRoute(app: Solstice, request: Request): Option[Handler] =
  for (route, httpMethod, handler) in app.routes:
    if pathMatch(route, request.url):
      if httpMethod == request.reqMethod:
        return some((route, httpMethod, handler))
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
        result.add(RouteVariable(name: name, kind: Int, intVal: uSec.parseInt))
      else:
        result.add(RouteVariable(name: name, kind: String, strVal: uSec))

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