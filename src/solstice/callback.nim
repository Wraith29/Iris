import asyncdispatch
import asynchttpserver
import sugar

type CallbackFn* = (Request {.async, closure, gcsafe.} -> Future[void])
