import tables
import json

proc toJson*(reqBody: string): TableRef[string, string] =
  var items = newTable[string, string]()

  for key in parseJson(reqBody).keys:
    items[key] = parseJson(reqBody).getOrDefault(key).str

  return items