import strformat
import options

type RouteVariableKind = enum
  String
  Int

type RouteVariable* = ref object
  name: string
  case kind: RouteVariableKind:
  of String: strVal*: string
  of Int: intVal*: int

type RequestArgs* = varargs[RouteVariable]

proc newRouteVariable*(name, value: string): RouteVariable =
  RouteVariable(name: name, kind: String, strVal: value)

proc newRouteVariable*(name: string, value: int): RouteVariable =
  RouteVariable(name: name, kind: Int, intVal: value)

proc get*(args: RequestArgs, name: string): Option[RouteVariable] =
  for arg in args:
    if arg.name == name:
      return some(arg)
  none(RouteVariable)

proc `[]`*(args: RequestArgs, name: string): Option[RouteVariable] =
  for arg in args:
    if arg.name == name:
      return some(arg)
  none(RouteVariable)

proc `$`*(routeVar: RouteVariable): string =
  case routeVar.kind:
  of String: fmt"RouteVariable(name: {routeVar.name}, value: {routeVar.strVal})"
  of Int: fmt"RouteVariable(name: {routeVar.name}, value: {routeVar.intVal})"