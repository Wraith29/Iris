import strformat

const AnsiCyan = "\u001b[36m"
const AnsiReset = "\u001b[0m"

proc log*(msg: string) =
  echo fmt"{AnsiCyan}[DBG]: {msg}{AnsiReset}"