import asynchttpserver
import strformat

import handler

type
  Container* = ref object
    name*: string
    routes*: seq[Handler]

proc newContainer*(name: string): Container =
  new result
  result.name = name
  result.routes = @[]

proc add*(container: var Container, route: string, httpMethod: HttpMethod, handler: RequestHandler) =
  let path = &"/{container.name}{route}"
  container.routes.add(newHandler(path, httpMethod, handler))

proc delete*(container: var Container, route: string, handler: RequestHandler) =
  container.add(route, HttpDelete, handler)

proc put*(container: var Container, route: string, handler: RequestHandler) =
  container.add(route, HttpPut, handler)

proc post*(container: var Container, route: string, handler: RequestHandler) =
  container.add(route, HttpPost, handler)

proc get*(container: var Container, route: string, handler: RequestHandler) =
  container.add(route, HttpGet, handler)
