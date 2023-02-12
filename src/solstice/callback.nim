import asyncdispatch
import asynchttpserver
import sugar

type Callback* = (Request {.closure, gcsafe.} -> Future[void])
