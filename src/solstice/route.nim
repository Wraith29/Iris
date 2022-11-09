import
  strformat

type
  RouteVariableKind = enum
    String, Int

  RouteVariableObj = object
    name*: string
    case kind: RouteVariableKind:
    of String: strVal*: string
    of Int: intVal*: int
  
  RouteVariable* = ref RouteVariableObj
  
func newRouteVariable*(name: string, value: string): RouteVariable =
  new result
  result.name = name
  result.kind = RouteVariableKind.String
  result.strVal = value

func newRouteVariable*(name: string, value: int): RouteVariable =
  new result
  result.name = name
  result.kind = RouteVariableKind.Int
  result.intVal = value

func `$`*(value: RouteVariable): string =
  case value.kind:
  of String: &"RouteVariable(kind: String, value: {value.strVal})"
  of Int: &"RouteVariable(kind: Int, value: {value.intVal})"
