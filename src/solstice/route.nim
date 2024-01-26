import strformat
import options

type RouteVariableKind = enum
  String, Int

type RouteVariable* = ref object
  name: string
  case kind: RouteVariableKind:
  of String: strVal*: string
  of Int: intVal*: int

type RequestArgs* = varargs[RouteVariable]

func newRouteVariable*(name, value: string): RouteVariable =
  return RouteVariable(name: name, kind: String, strVal: value)

func newRouteVariable*(name: string; value: int): RouteVariable =
  return RouteVariable(name: name, kind: Int, intVal: value)

func get*(args: RequestArgs; name: string): Option[RouteVariable] =
  for arg in args:
    if arg.name == name:
      return some(arg)

  return none(RouteVariable)

func `[]`*(args: RequestArgs; name: string): Option[RouteVariable] =
  for arg in args:
    if arg.name == name:
      return some(arg)

  return none(RouteVariable)

func `$`*(routeVar: RouteVariable): string =
  return case routeVar.kind:
    of String: fmt"RouteVariable(name: {routeVar.name}, value: {routeVar.strVal})"
    of Int: fmt"RouteVariable(name: {routeVar.name}, value: {routeVar.intVal})"