import tables

type
  VarKind* = enum
    Str, Int, Array, Map
  
  VarType* = ref object
    case kind*: VarKind:
    of Str: strValue*: string
    of Int: intValue*: int
    of Array: arrValue*: seq[VarType]
    of Map: mapValue*: Table[string, VarType]
  
func newVar*(strValue: string): VarType {.inline.} =
  VarType(kind: Str, strValue: strValue)

func newVar*(intValue: int): VarType {.inline.} =
  VarType(kind: Int, intValue: intValue)

func newVar*(arrValue: seq[VarType]): VarType {.inline.} =
  VarType(kind: Array, arrValue: arrValue)

func newVar*(mapValue: Table[string, VarType]): VarType {.inline.} =
  VarType(kind: Map, mapValue: mapValue)

func `$`*(vt: VarType): string =
  case vt.kind:
  of Str: vt.strValue
  of Int: $vt.intValue
  of Array: $vt.arrValue
  of Map: $vt.mapValue