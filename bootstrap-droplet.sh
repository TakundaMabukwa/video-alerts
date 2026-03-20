#!/usr/bin/env bash
set -euo pipefail

APP_NAME="video-alert-worker"
APP_DIR="/opt/video-alerts"
REPO_URL="https://github.com/TakundaMabukwa/video-alerts.git"
BRANCH="main"
API_PORT_DEFAULT="3100"
LISTENER_URL_DEFAULT="http://209.38.206.44:3000"
SERVER_IP_DEFAULT="46.101.219.78"
DB_NAME="video_system"
DB_USER="video_user"
DB_PASSWORD="${VIDEO_DB_PASSWORD:-$(python3 - <<'PY'
import secrets,string
alphabet = string.ascii_letters + string.digits
print(''.join(secrets.choice(alphabet) for _ in range(24)))
PY
)}"

export DEBIAN_FRONTEND=noninteractive

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root or with sudo."
  exit 1
fi

echo "[1/11] Installing base packages..."
apt-get update -y
apt-get install -y curl git build-essential ca-certificates nginx python3 postgresql postgresql-contrib

echo "[2/11] Installing Node.js 20..."
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi

echo "[3/11] Installing PM2..."
npm install -g pm2

mkdir -p /opt
if [[ ! -d "${APP_DIR}/.git" ]]; then
  echo "[4/11] Cloning video-alerts..."
  git clone --branch "${BRANCH}" "${REPO_URL}" "${APP_DIR}"
else
  echo "[4/11] Updating existing video-alerts checkout..."
  git -C "${APP_DIR}" fetch origin
  git -C "${APP_DIR}" checkout "${BRANCH}"
  git -C "${APP_DIR}" pull --ff-only origin "${BRANCH}"
fi

cd "${APP_DIR}"

if [[ ! -f .env ]]; then
  echo "[5/11] Creating .env from template..."
  cp .env.example .env
fi

echo "[6/11] Writing environment defaults..."
python3 - <<PY
from pathlib import Path
p = Path('.env')
text = p.read_text()
replacements = {
    'SERVER_IP=46.101.219.78': 'SERVER_IP=${SERVER_IP_DEFAULT}',
    'LISTENER_SERVER_URL=http://209.38.206.44:3000': 'LISTENER_SERVER_URL=${LISTENER_URL_DEFAULT}',
    'DB_HOST=127.0.0.1': 'DB_HOST=127.0.0.1',
    'DB_PORT=5432': 'DB_PORT=5432',
    'DB_NAME=video_system': 'DB_NAME=${DB_NAME}',
    'DB_USER=video_user': 'DB_USER=${DB_USER}',
    'DB_PASSWORD=CHANGE_ME_VIDEO_DB_PASSWORD': 'DB_PASSWORD=${DB_PASSWORD}',
}
for old, new in replacements.items():
    text = text.replace(old, new)
p.write_text(text)
PY

echo "[7/11] Bootstrapping PostgreSQL user/database/schema..."
python3 - <<PY
from pathlib import Path
cluster = Path('postgres/bootstrap_cluster.sql')
cluster.write_text(cluster.read_text().replace('CHANGE_ME_VIDEO_DB_PASSWORD', '${DB_PASSWORD}'))
PY
sudo -u postgres psql -f postgres/bootstrap_cluster.sql
sudo -u postgres psql -d "${DB_NAME}" -f postgres/bootstrap_schema.sql

echo "[8/11] Installing app dependencies..."
npm install

echo "[9/11] Building app..."
npm run build

mkdir -p logs media hls recordings

echo "[10/11] Starting PM2 process..."
pm2 delete "${APP_NAME}" >/dev/null 2>&1 || true
pm2 start ecosystem.config.js --update-env
pm2 save
pm2 startup systemd -u root --hp /root >/tmp/pm2-startup-alerts.txt || true
bash /tmp/pm2-startup-alerts.txt 2>/dev/null || true

echo "[11/11] Completed"
echo "Alert worker API: http://127.0.0.1:${API_PORT_DEFAULT}"
echo "Frontend stays on port 3000"
echo ""
echo "Database credentials created:"
echo "  DB_NAME=${DB_NAME}"
echo "  DB_USER=${DB_USER}"
echo "  DB_PASSWORD=${DB_PASSWORD}"
echo ""
echo "Checks:"
echo "  pm2 status"
echo "  pm2 logs ${APP_NAME} --lines 100"
echo "  curl http://127.0.0.1:${API_PORT_DEFAULT}/health"
