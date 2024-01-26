import tables
import jsony

proc toJson*(reqBody: string): TableRef[string, string] =
  return reqBody.fromJson(TableRef[string, string])