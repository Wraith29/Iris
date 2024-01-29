import std/[asynchttpserver, strformat]
import src/solstice/[handler]

type Module* = ref object
  name*: string
  routes*: seq[Handler]

func newModule*(name: string): Module =
  Module(name: name, routes: @[])
  
func add*(module: var Module, route: string, httpMethod: HttpMethod, handler: RequestHandler) =
  let path = &"/{module.name}{route}"
  module.routes.add(newHandler(path, httpMethod, handler))

template delete*(module: var Module, route: string, handler: RequestHandler) =
  module.add(route, HttpDelete, handler)

template put*(module: var Module, route: string, handler: RequestHandler) =
  module.add(route, HttpPut, handler)

template post*(module: var Module, route: string, handler: RequestHandler) =
  module.add(route, HttpPost, handler)

template get*(module: var Module, route: string, handler: RequestHandler) =
  module.add(route, HttpGet, handler)
