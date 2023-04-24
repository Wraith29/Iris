import strformat

proc log*(msg: string) =
  echo fmt"[DBG]: {msg}"