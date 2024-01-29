import std/[asyncdispatch, asynchttpserver, sugar]

type CallbackFn* = (Request {.closure, gcsafe.} -> Future[void])
