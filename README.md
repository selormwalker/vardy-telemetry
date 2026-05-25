# 🛰️ Vardy-Telemetry

**High-Performance Telemetry Ingestion & Streaming Microservice**

Built with the **Nim** programming language and the **Mummy** web framework, `Vardy-Telemetry` is designed for ultra-low latency data collection and real-time broadcasting.

---

## 🚀 Key Features

- ⚡ **Native Performance:** Compiled to C for machine-level efficiency.
- 🤖 **Multi-threaded:** Leverages Mummy's high-concurrency architecture.
- 📡 **Real-time Streaming:** Ingests data via HTTP and broadcasts instantly via WebSockets.
- 🛡️ **Thread-Safe:** Implements robust locking mechanisms for global state management.
- 📊 **Introspection:** Built-in health checks and live statistics.

---

## 🛠️ Technical Stack

- **Language:** [Nim](https://nim-lang.org/)
- **Web Framework:** [Mummy](https://github.com/guzba/mummy)
- **Serialization:** Native JSON handling.
- **Concurrency:** Nim's multi-threading with `Locks`.

---

## 🚦 API Reference

### HTTP Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/health` | Service health status. |
| `GET` | `/api/v1/stats` | Live connection and throughput metrics. |
| `POST` | `/api/v1/metrics` | Ingest telemetry data (JSON). |

### WebSocket Endpoint

| Endpoint | Protocol | Description |
| :--- | :--- | :--- |
| `/ws/stream` | `WS/WSS` | Subscribe to live telemetry stream. |

---

## 🏗️ Getting Started

### Prerequisites
- Nim 2.2.0 or higher
- Nimble (Nim package manager)

### Installation
```bash
git clone https://github.com/selormwalker/vardy-telemetry.git
cd vardy-telemetry
nimble install -y
```

### Running the Server
```bash
nim c -r -d:release src/vardy_telemetry.nim
```

---

## 🧪 Testing

### Ingesting Data (CURL)
```bash
curl -X POST http://localhost:8080/api/v1/metrics \
     -H "Content-Type: application/json" \
     -d '{"sensor": "GT-01", "load": 85.2, "temp": 42.5}'
```

---

<div align="center">
  <i>"Building the future of code, autonomously."</i>
</div>
