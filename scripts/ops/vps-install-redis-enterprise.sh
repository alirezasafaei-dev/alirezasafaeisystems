#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
REMOTE_SCRIPT="/tmp/asdev-install-redis.sh"

cat <<'REMOTE' | ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "cat > '$REMOTE_SCRIPT' && chmod +x '$REMOTE_SCRIPT' && sudo bash '$REMOTE_SCRIPT' && sudo rm -f '$REMOTE_SCRIPT'"
#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
for list_file in /etc/apt/sources.list.d/*; do
  [ -f "$list_file" ] || continue
  if grep -qiE 'nodesource|dl\\.google\\.com' "$list_file"; then
    sudo mv "$list_file" "${list_file}.disabled"
  fi
done

if grep -q 'de.archive.ubuntu.com' /etc/apt/sources.list; then
  sudo sed -i 's#de.archive.ubuntu.com#archive.ubuntu.com#g' /etc/apt/sources.list
fi

sudo dpkg --configure -a || true
sudo apt-get -o Dpkg::Options::=--force-confold -o Acquire::Retries=5 -o Acquire::ForceIPv4=true update
sudo apt-get -o Dpkg::Options::=--force-confold -o Acquire::Retries=5 -o Acquire::ForceIPv4=true install -y redis-server redis-tools

SECRET_DIR="/etc/asdev-redis"
SECRET_FILE="$SECRET_DIR/credentials.env"
sudo mkdir -p "$SECRET_DIR"
sudo chmod 700 "$SECRET_DIR"

REDIS_PASSWORD="$(openssl rand -base64 36 | tr -d '\n' | sed 's#[/=+]#A#g')"

MEM_KB="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
MEM_MB="$((MEM_KB / 1024))"
MAXMEM_MB="$((MEM_MB / 4))"
if (( MAXMEM_MB < 128 )); then MAXMEM_MB=128; fi
if (( MAXMEM_MB > 1024 )); then MAXMEM_MB=1024; fi

CONF="/etc/redis/redis.conf"
sudo cp "$CONF" "${CONF}.bak.$(date -u +%Y%m%dT%H%M%SZ)"

sudo sed -i -E 's/^bind .*/bind 127.0.0.1 ::1/' "$CONF"
sudo sed -i -E 's/^protected-mode .*/protected-mode yes/' "$CONF"
sudo sed -i -E 's/^#?\\s*port .*/port 6379/' "$CONF"
sudo sed -i -E 's/^#?\\s*tcp-backlog .*/tcp-backlog 511/' "$CONF"
sudo sed -i -E 's/^#?\\s*timeout .*/timeout 0/' "$CONF"
sudo sed -i -E 's/^#?\\s*tcp-keepalive .*/tcp-keepalive 300/' "$CONF"
sudo sed -i -E 's/^#?\\s*appendonly .*/appendonly yes/' "$CONF"
sudo sed -i -E 's/^#?\\s*appendfsync .*/appendfsync everysec/' "$CONF"
sudo sed -i -E "s/^#?\\s*maxmemory .*/maxmemory ${MAXMEM_MB}mb/" "$CONF"
sudo sed -i -E 's/^#?\\s*maxmemory-policy .*/maxmemory-policy allkeys-lru/' "$CONF"
sudo sed -i -E 's/^#?\\s*stop-writes-on-bgsave-error .*/stop-writes-on-bgsave-error yes/' "$CONF"

if sudo grep -qE '^requirepass ' "$CONF"; then
  sudo sed -i -E "s#^requirepass .*#requirepass ${REDIS_PASSWORD}#" "$CONF"
else
  echo "requirepass ${REDIS_PASSWORD}" | sudo tee -a "$CONF" >/dev/null
fi

{
  echo "# generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "REDIS_HOST=127.0.0.1"
  echo "REDIS_PORT=6379"
  echo "REDIS_PASSWORD=${REDIS_PASSWORD}"
  echo "REDIS_URL=redis://:${REDIS_PASSWORD}@127.0.0.1:6379/0"
  echo "REDIS_MAXMEMORY_MB=${MAXMEM_MB}"
} | sudo tee "$SECRET_FILE" >/dev/null
sudo chmod 600 "$SECRET_FILE"

sudo systemctl enable redis-server
sudo systemctl restart redis-server
sudo systemctl --no-pager --full status redis-server | sed -n '1,12p'

REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h 127.0.0.1 -p 6379 ping

echo "secret_file=$SECRET_FILE"
echo "config_file=$CONF"
echo "maxmemory_mb=$MAXMEM_MB"
REMOTE

echo "Redis enterprise setup completed on VPS."
