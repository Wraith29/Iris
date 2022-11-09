import
  asynchttpserver

type
  ResponseObj = object
    code*: HttpCode
    msg*: string
    headers*: HttpHeaders
  
  Response* = ref Responseobj

func newResponse*(code: HttpCode, msg: string, headers: HttpHeaders): Response =
  new result
  result.code = code
  result.msg = msg
  result.headers = headers

func newResponse*(code: HttpCode, msg: string): Response =
  newResponse(code, msg, newHttpHeaders())
