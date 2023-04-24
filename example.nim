import asyncdispatch
import strformat
import src/iris
import tables
import sugar


proc getPostById(req: Request, args: RequestArgs): Response =
  let id = args["id"]
  if isNone id:
    newResponse(Http400, "Bad Request")
  else:
    newResponse(Http200, &"Post Id: {id.get().intVal}")

proc getPostByName(req: Request, args: RequestArgs): Response =
  let name = args["name"]
  if isNone name:
    newResponse(Http400, "Bad Request")
  else:
    newResponse(Http200, &"Post Name: {name.get().strVal}")

proc getPostContainer: Container =
  result = newContainer("post")
  result.get("/{id:int}", getPostById)
  result.get("/{name:string}", getPostByName)

proc getUserById(req: Request, args: RequestArgs): Response =
  let id = args["id"]
  if isNone id:
    newResponse(Http400, "Bad Request")
  else:
    newResponse(Http200, &"User Id: {id.get().intVal}")

proc getUserContainer: Container =
  result = newContainer("user")
  result.get("/{id:int}", getUserById)

proc getAuthContainer: Container =
  result = newContainer("auth")
  result.post("/register", proc (r: Request, args: RequestArgs): Response =
    echo r.body
    return newResponse(Http200, "Hello, World!")
  )

  result.post("/login", proc (r: Request, a: RequestArgs): Response =
    echo r.body
    return newResponse(Http200, "Hello, World!")
  )

proc main() {.async.} =
  var api = newApi(5000)

  api.get("/", (req: Request, args: RequestArgs) => newResponse(Http200, "Hello, World!"))
  api.register(getPostContainer())
  api.register(getUserContainer())
  api.register(getAuthContainer())

  api.post("/test", proc (r:Request, a:RequestArgs): Response =
    echo r.body.toJson()
  
    return newResponse(Http200, "Hello, World!")
  )
  
  api.addCorsOrigins("http://localhost:3000")

  waitFor api.run()

when isMainModule:
  waitFor main()