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
  Callback = (Request {.closure, gcsafe.} -> Future[void])
  
  Response* = ref object
    code: HttpCode
    msg: string
    headers: HttpHeaders
  
  RouteVariableKind = enum
    String
    Int
  
  RouteVariable = ref object
    name: string
    case kind: RouteVariableKind:
    of String: strVal*: string
    of Int: intVal*: int

  RequestArgs* = varargs[RouteVariable]
  
  RequestHandler = ((Request, RequestArgs) {.closure, gcsafe.} -> Response)
  
  Handler = ref object
    route: string
    reqMethod: HttpMethod
    handler: RequestHandler

  Container* = ref object
    name: string
    routes: seq[Handler]

  Solstice* = ref object
    routes*: seq[Handler]
    port: int

func newResponse*(code: HttpCode, msg: string, headers: HttpHeaders): Response =
  new result
  result.code = code
  result.msg = msg
  result.headers = headers

func newResponse*(code: HttpCode, msg: string): Response =
  newResponse(code, msg, newHttpHeaders())

func newRouteVariable(name, value: string): RouteVariable =
  new result
  result.name = name
  result.kind = RouteVariableKind.String
  result.strVal = value

func newRouteVariable(name: string, value: int): RouteVariable =
  new result
  result.name = name
  result.kind = RouteVariableKind.Int
  result.intval = value

func `[]`*(args: RequestArgs, name: string): Option[RouteVariable] =
  for arg in args:
    if arg.name == name:
      return some(arg)
  none(RouteVariable)

func newHandler(route: string, reqMethod: HttpMethod, handler: RequestHandler): Handler =
  new result
  result.route = route
  result.reqMethod = reqMethod
  result.handler = handler

proc `$`*(handler: RequestHandler): string =
  &"RequestHandler"

proc `$`*(handler: Handler): string =
  &"Handler(route: {handler.route}, method: {handler.reqMethod}, handler: {handler.handler})"

func newContainer*(name: string): Container =
  new result
  result.name = name
  result.routes = @[]

func newSolstice*(port: int): Solstice =
  new result
  result.routes = @[]
  result.port = port

func newSolstice*(): Solstice =
  newSolstice(5000)

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
  true

func add*(container: var Container, route: string, httpMethod: HttpMethod, handler: RequestHandler) =
  let path = &"/{container.name}{route}"
  container.routes.add(newHandler(path, httpMethod, handler))

func delete*(container: var Container, route: string, handler: RequestHandler) =
  container.add(route, HttpPut, handler)

func put*(container: var Container, route: string, handler: RequestHandler) =
  container.add(route, HttpPut, handler)

func post*(container: var Container, route: string, handler: RequestHandler) =
  container.add(route, HttpPost, handler)

func get*(container: var Container, route: string, handler: RequestHandler) =
  container.add(route, HttpGet, handler)

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

proc register*(app: var Solstice, container: Container) =
  for handler in container.routes:
    app.add(handler.route, handler.reqMethod, handler.handler)

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
        kind = rSplit[1].substr(0, rSplit[1].len-2)

      if uSec[0].isDigit and kind == "int":
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

  waitFor server.serve(Port(app.port), callback)