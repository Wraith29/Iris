import httpcore

type Response* = ref object
  code*: HttpCode
  msg*: string
  headers*: HttpHeaders

func newResponse*(code: HttpCode; msg: string; headers: HttpHeaders): Response =
  return Response(
    code: code,
    msg: msg,
    headers: headers
  )

func newResponse*(code: HttpCode; msg: string): Response =
  return newResponse(code, msg, newHttpHeaders())

proc addHeader*(response: var Response; key, value: string) =
  response.headers.add(key, value)