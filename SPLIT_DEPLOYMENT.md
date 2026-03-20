# Split Deployment

Alert worker target:

- public droplet IP: `46.101.219.78`
- frontend: `3000`
- alert API/WebSocket: `3100`
- PostgreSQL: local only on `5432`

Listener should forward alerts to:

```env
ALERT_WORKER_URL=http://46.101.219.78:3100
```

Alert worker should call back to the listener for screenshots/video commands:

```env
LISTENER_SERVER_URL=http://209.38.206.44:3000
```

The alert worker does not own device ingest and should run with:

```env
INGRESS_ENABLED=false
ALERT_PROCESSING_ENABLED=true
VIDEO_PROCESSING_ENABLED=false
DB_ENABLED=true
MESSAGE_TRACE_ENABLED=false
DATA_WS_ENABLED=false
PROTOCOL_WS_ENABLED=false
BACKGROUND_STREAMS_ENABLED=false
AUTO_SCREENSHOT_FANOUT_ENABLED=false
```
