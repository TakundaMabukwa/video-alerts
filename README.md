# video-alerts

# Alert Worker

This service receives parsed alerts from the listener and runs:

- alert creation and deduplication
- alert persistence in PostgreSQL
- alert websocket/API for the frontend
- screenshot and camera-video command callbacks back through the listener

Recommended deployment on your frontend droplet:

- frontend: port `3000`
- alert worker API: port `3100`
- PostgreSQL: local on `127.0.0.1:5432`

Quick start:

```bash
cp .env.example .env
npm install
npm run build
pm2 start ecosystem.config.js --update-env
```

One-shot droplet bootstrap:

```bash
curl -fsSL https://raw.githubusercontent.com/TakundaMabukwa/video-alerts/main/bootstrap-droplet.sh -o bootstrap-droplet.sh
chmod +x bootstrap-droplet.sh
sudo ./bootstrap-droplet.sh
```

After bootstrap:

- edit `/opt/video-alerts/.env` if needed
- confirm the DB password in `.env` matches what the bootstrap created
- restart PM2

Health check:

```bash
curl http://127.0.0.1:3100/health
```
