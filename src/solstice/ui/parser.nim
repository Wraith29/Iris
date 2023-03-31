import strutils
import sugar
import tables
import vars

type Parser = ref object
  src: string
  index: int
  vars: Table[string, VarType]

proc newParser(src: string, vars: Table[string, VarType]): Parser =
  return Parser(src: src, index: 0, vars: vars)

proc current(parser: Parser): char =
  return parser.src[parser.index]

proc peek(parser: Parser; n: int = 1): char =
  return parser.src[parser.index+n]

proc skip(parser: var Parser; n: int = 1) =
  parser.index += 1

proc next(parser: Parser): bool =
  return parser.index < len(parser.src)

proc hasVar(parser: Parser; key: string): bool =
  return parser.vars.hasKey(key)

proc collectUntil(parser: Parser; delim: char): string =
  var n = 0
  while parser.peek(n) != delim:
    result.add(parser.peek(n))
    inc n

proc collectUntil(parser: Parser; slice: string): string =
  var n = 0
  while parser.src[parser.index+n .. parser.index+n+len(slice)-1] != slice:
    result.add(parser.peek(n))
    inc n

proc parseVar(parser: var Parser) =
  let varName = parser.collectUntil('|')
  if not parser.hasVar(varName.strip):
    echo "Var not found: ", varName
    return
  
  let index = parser.src.find(varName.strip, parser.index, len(parser.src)) - 2
  parser.src.delete(index..index+len(varName)+3)
  parser.src.insert($parser.vars[varName], index)

proc parseForLoopVar(parser: Parser; pref: string; obj: VarType; orig: string): string =
  if obj.kind != Map: return
  var content = deepCopy(orig)

  var idx = 0
  var endIdx = 0
  var name: string

  while idx < len(content)-1:
    if content[idx .. idx+1] == "{|":
      endIdx = content.find("|}", endIdx + 1, len(content) - 1)
      name = content[idx + 2 .. endIdx - 1]

      if name.startsWith(pref):
        name.delete(0 .. len(pref))
        if obj.mapValue.hasKey(name):
          content.delete(idx .. endIdx + 1)
          content.insert($obj.mapValue[name], idx)
    inc idx
  
  return content

proc parseLoop(parser: var Parser) =
  let startIdx = parser.index - 2
  let inner = parser.collectUntil('!').strip
  let varPref = inner.split(" ")[1]
  let varName = inner.split(" ")[3]

  if not parser.hasVar(varName.strip):
    return

  if parser.vars[varName].kind != Array:
    return

  let forDeclLen = len(parser.collectUntil("!}"))
  parser.skip(forDeclLen + 2)
  let forBlock = parser.collectUntil("{!}")

  var parsed: string
  for obj in parser.vars[varName].arrValue:
    parsed &= parser.parseForLoopVar(varPref, obj, forBlock)

  let blockLen = len(parser.collectUntil("{!}"))

  parser.src.delete(startIdx .. startIdx + forDeclLen + blockLen + 6)
  parser.src.insert(parsed, startIdx)

proc parse(parser: var Parser) =
  parser.src = collect(
    for line in parser.src.split("\n"):
      if line == "": continue
      line.strip()
  ).join()

  while parser.next():
    if parser.current == '{':
      if parser.peek() == '|':
        parser.skip(2)
        parser.parseVar()
      elif parser.peek() == '!' and parser.peek(2) != '}':
        parser.skip(2)
        parser.parseLoop()
    parser.skip(1)

proc parseTemplate*(templ: string, vars: Table[string, VarType]): string =
  var parser = newParser(templ, vars)
  parser.parse()
  return parser.src

proc parseTemplate*(templ: string): string =
  return parseTemplate(templ, initTable[string, VarType]())


proc loadTemplate*(filename: string, vars: Table[string, VarType]): string =
  let contents = readFile(filename)
  var parser = newParser(contents, vars)
  parser.parse()
  return parser.src


proc loadTemplate*(filename: string): string =
  return loadTemplate(filename, initTable[string, VarType]())
