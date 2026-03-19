# OpenClaw Mission Control Dashboard

Realtime mission control UI for OpenClaw operations:

- Agents (status, latency, CPU)
- Cluster nodes (role, zone, utilization)
- GPU fleet metrics
- Network path telemetry (RTT / throughput / loss)
- Alert stream

## Run locally

From the repo root:

- `make dashboard`

Then open: `http://localhost:8088/dashboard/`

## Realtime integration

By default, the UI runs with a mock 1-second telemetry stream.

To connect a backend websocket stream, set:

- `window.OPENCLAW_WS_URL = "ws://<your-host>/stream"`

before `app.js` loads (or inject via a small inline script tag).

Expected websocket payload shape (partial updates are okay):

```json
{
  "cluster": {},
  "agents": [],
  "nodes": [],
  "gpus": [],
  "network": [],
  "alerts": []
}
```
