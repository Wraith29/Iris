import asyncdispatch, options, strformat
import src/solstice


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


proc index(req: Request, args: RequestArgs): Response =
  newResponse(Http200, "<a href=\"/user/1\">User</a><a href=\"/post/1\">Post</a>")
  

proc main {.async.} =
  var sol = newSolstice()
  
  sol.get("/", index)
  sol.register(getPostContainer())
  sol.register(getUserContainer())
  
  for route in sol.routes:
    echo route
  
  waitFor sol.run()


when isMainModule:
  waitFor main()