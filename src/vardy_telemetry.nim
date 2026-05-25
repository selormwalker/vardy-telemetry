import mummy, mummy/routers, json, os, locks

var
  sockets: seq[WebSocket]
  socketsLock: Lock

initLock(socketsLock)

proc healthHandler(request: Request) {.gcsafe.} =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  request.respond(200, headers, """{"status": "ok"}""")

proc metricsHandler(request: Request) {.gcsafe.} =
  # Echo the metrics to all connected sockets
  {.cast(gcsafe).}:
    acquire(socketsLock)
    try:
      for socket in sockets:
        socket.send(request.body)
    finally:
      release(socketsLock)
  
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  request.respond(200, headers, """{"status": "received"}""")

proc websocketHandler(websocket: WebSocket, event: WebSocketEvent, message: Message) {.gcsafe.} =
  case event:
  of OpenEvent:
    {.cast(gcsafe).}:
      acquire(socketsLock)
      sockets.add(websocket)
      release(socketsLock)
    echo "New WebSocket connection"
  of MessageEvent:
    echo "Received WebSocket message: ", message.data
  of CloseEvent:
    echo "WebSocket disconnected"
    # Remove socket from list
    {.cast(gcsafe).}:
      acquire(socketsLock)
      try:
        for i in 0 ..< sockets.len:
          if sockets[i] == websocket:
            sockets.delete(i)
            break
      finally:
        release(socketsLock)
  of ErrorEvent:
    echo "WebSocket error"

var router: Router
router.get("/health", healthHandler)
router.post("/api/v1/metrics", metricsHandler)

let server = newServer(router, websocketHandler)
echo "Vardy-Telemetry server starting on http://localhost:8080"
server.serve(Port(8080))
