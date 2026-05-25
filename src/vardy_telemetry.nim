import mummy, mummy/routers, json, os, locks, times

type
  Stats = object
    connections: int
    totalMessages: int
    startTime: float

var
  sockets: seq[WebSocket]
  serverStats: Stats
  stateLock: Lock

initLock(stateLock)
serverStats.startTime = epochTime()

proc log(level, message: string) =
  let now = now().format("yyyy-MM-dd HH:mm:ss")
  echo "[" & now & "] [" & level & "] " & message

proc healthHandler(request: Request) {.gcsafe.} =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  request.respond(200, headers, """{"status": "ok"}""")

proc statsHandler(request: Request) {.gcsafe.} =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  
  var response: JsonNode
  {.cast(gcsafe).}:
    acquire(stateLock)
    let uptime = epochTime() - serverStats.startTime
    response = %*{
      "connections": serverStats.connections,
      "total_messages": serverStats.totalMessages,
      "uptime_seconds": uptime
    }
    release(stateLock)
  
  request.respond(200, headers, $response)

proc metricsHandler(request: Request) {.gcsafe.} =
  # Data Validation
  try:
    let data = parseJson(request.body)
    if data.kind != JObject:
      request.respond(400, emptyHttpHeaders(), "Invalid JSON: Expected object")
      return
  except JsonParsingError:
    request.respond(400, emptyHttpHeaders(), "Invalid JSON format")
    return

  # Broadcast and Update Stats
  {.cast(gcsafe).}:
    acquire(stateLock)
    serverStats.totalMessages.inc()
    for socket in sockets:
      socket.send(request.body)
    release(stateLock)
  
  log("INFO", "Processed metrics: " & request.body)
  
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  request.respond(200, headers, """{"status": "received"}""")

proc websocketHandler(websocket: WebSocket, event: WebSocketEvent, message: Message) {.gcsafe.} =
  case event:
  of OpenEvent:
    {.cast(gcsafe).}:
      acquire(stateLock)
      sockets.add(websocket)
      serverStats.connections.inc()
      release(stateLock)
    log("INFO", "New WebSocket connection established")
  of MessageEvent:
    log("DEBUG", "Received WebSocket message: " & message.data)
  of CloseEvent:
    log("INFO", "WebSocket disconnected")
    {.cast(gcsafe).}:
      acquire(stateLock)
      serverStats.connections.dec()
      try:
        for i in 0 ..< sockets.len:
          if sockets[i] == websocket:
            sockets.delete(i)
            break
      finally:
        release(stateLock)
  of ErrorEvent:
    log("ERROR", "WebSocket error occurred")

var router: Router
router.get("/health", healthHandler)
router.get("/api/v1/stats", statsHandler)
router.post("/api/v1/metrics", metricsHandler)

let server = newServer(router, websocketHandler)
log("INFO", "Vardy-Telemetry server starting on http://localhost:8080")
server.serve(Port(8080))
