import asyncdispatch
import asynchttpserver
import sugar

type CallbackFn* = (Request {.closure, gcsafe.} -> Future[void])
