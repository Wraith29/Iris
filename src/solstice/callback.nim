import 
  asyncdispatch,
  asynchttpserver,
  sugar

type Callback* = (Request {.closure, gcsafe.} -> Future[void])
