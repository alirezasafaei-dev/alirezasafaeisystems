#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# IRAN_PROD Production Server Inventory Script (Phase A)
# ============================================================================
# This script collects read-only information about the production server
# All output is redacted to prevent exposure of secrets or raw IPs
# NEVER RUN THIS SCRIPT WITHOUT EXPLICIT APPROVAL
#
# Usage: ./iran-prod-inventory.sh [--output-file <path>] APPROVE_IRAN_PROD_SITE_INVENTORY
# ============================================================================

# ============================================================================
# CONFIGURATION
# ============================================================================

APPROVAL_PHRASE="APPROVE_IRAN_PROD_SITE_INVENTORY"
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
OUTPUT_FILE="/tmp/iran-prod-inventory-${TIMESTAMP}.json"

# ============================================================================
# DRY-RUN MODE & OUTPUT OPTIONS
# ============================================================================

DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-file)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# ============================================================================
# HELPERS
# ============================================================================

log() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $1" >&2
}

log_error() {
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] ERROR: $1" >&2
}

# Function to redact IP addresses
redact_ip() {
    echo "$1" | sed -E 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[REDACTED_IP]/g'
}

# Function to redact secrets (API keys, passwords, tokens)
redact_secrets() {
    echo "$1" | sed -E 's/(api[_-]?key|password|secret|token|auth)[[:space:]]*[:=][[:space:]]*["\x27]?[^ "\x27,;]+["\x27]?/\1=[REDACTED]/gi'
}

# Function to redact both IPs and secrets
redact_all() {
    redact_ip "$(redact_secrets "$1")"
}

# ============================================================================
# APPROVAL GATE
# ============================================================================

if [[ $# -lt 1 ]] || [[ "$1" != "$APPROVAL_PHRASE" ]]; then
    log_error "Approval required to run inventory script"
    echo "Usage: $0 [--output-file <path>] [--dry-run] $APPROVAL_PHRASE" >&2
    echo "This script collects sensitive server information and must be explicitly approved" >&2
    exit 1
fi

log "Starting IRAN_PROD inventory collection..."

# ============================================================================
# SERVER INFO
# ============================================================================

log "Collecting server information..."

SERVER_INFO=$(cat <<EOF
{
    "hostname": "$(redact_all "$(hostname)")",
    "kernel": "$(uname -r)",
    "uptime": "$(uptime -p)",
    "cpu_count": $(nproc),
    "memory_total_mb": $(free -m | awk '/^Mem:/{print $2}'),
    "memory_used_mb": $(free -m | awk '/^Mem:/{print $3}'),
    "swap_total_mb": $(free -m | awk '/^Swap:/{print $2}'),
    "swap_used_mb": $(free -m | awk '/^Swap:/{print $3}')
}
EOF
)

# ============================================================================
# DISK USAGE
# ============================================================================

log "Collecting disk usage..."

DISK_USAGE="["
first=true
while IFS= read -r line; do
    if [[ "$first" == "true" ]]; then
        first=false
    else
        DISK_USAGE+=","
    fi
    DISK_USAGE+=$(echo "$line" | awk '{printf "{\"filesystem\":\"%s\",\"size\":\"%s\",\"used\":\"%s\",\"avail\":\"%s\",\"use_percent\":\"%s\",\"mount\":\"%s\"}", $1, $2, $3, $4, $5, $6}')
done < <(df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs -x squashfs 2>/dev/null | tail -n +2)
DISK_USAGE+="]"

# ============================================================================
# NGINX CONFIGS
# ============================================================================

log "Collecting nginx configurations..."

NGINX_CONFIGS="["
if command -v nginx >/dev/null 2>&1; then
    nginx_conf_dir=$(nginx -t 2>&1 | grep "configuration file" | sed -n 's/.*configuration file \([^ ]*\).*/\1/p' | xargs dirname 2>/dev/null || echo "/etc/nginx")
    
    if [[ -d "$nginx_conf_dir" ]]; then
        first=true
        while IFS= read -r conf_file; do
            if [[ "$first" == "true" ]]; then
                first=false
            else
                NGINX_CONFIGS+=","
            fi
            # Extract server names and redact
            server_names=$(grep -r "server_name" "$conf_file" 2>/dev/null | awk '{print $2}' | tr -d ';' | tr '\n' ',' | sed 's/,$//' | redact_all)
            listen_ports=$(grep -r "listen" "$conf_file" 2>/dev/null | awk '{print $2}' | tr -d ';' | tr '\n' ',' | sed 's/,$//' | redact_all)
            ssl_certs=$(grep -r "ssl_certificate" "$conf_file" 2>/dev/null | grep -v "ssl_certificate_key" | awk '{print $2}' | tr -d ';' | tr '\n' ',' | sed 's/,$//' | redact_all)
            
            NGINX_CONFIGS+="{\"file\":\"$(redact_all "$conf_file")\",\"server_names\":\"$server_names\",\"listen_ports\":\"$listen_ports\",\"ssl_certs\":\"$ssl_certs\"}"
        done < <(find "$nginx_conf_dir" -name "*.conf" -type f 2>/dev/null)
    fi
fi
NGINX_CONFIGS+="]"

# ============================================================================
# PM2 PROCESSES
# ============================================================================

log "Collecting PM2 processes..."

PM2_PROCESSES="["
if command -v pm2 >/dev/null 2>&1; then
    pm2_json=$(pm2 jlist 2>/dev/null || echo "[]")
    # Redact sensitive information from PM2 output
    PM2_PROCESSES=$(echo "$pm2_json" | jq -c '.[] | {
        name: .name,
        status: .pm2_env.status,
        pid: .pid,
        restarts: .pm2_env.restart_time,
        memory: .monit.memory,
        cpu: .monit.cpu,
        pm_exec_path: (.pm2_env.pm_exec_path // "N/A" | gsub("/home/[^/]+";"/home/[USER]")),
        pm_cwd: (.pm2_env.pm_cwd // "N/A" | gsub("/home/[^/]+";"/home/[USER]")),
        created: .pm2_env.created_at,
        node_version: .pm2_env.node_version
    }' 2>/dev/null | jq -s '.' || echo "[]")
fi

# ============================================================================
# APPLICATION DIRECTORIES
# ============================================================================

log "Collecting application directories..."

APP_DIRECTORIES="["
first=true
for dir in /home/*/ /var/www/ /opt/*/; do
    if [[ -d "$dir" ]]; then
        if [[ "$first" == "true" ]]; then
            first=false
        else
            APP_DIRECTORIES+=","
        fi
        dir_size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
        APP_DIRECTORIES+="{\"path\":\"$(redact_all "$dir")\",\"size\":\"$dir_size\"}"
    fi
done
APP_DIRECTORIES+="]"

# ============================================================================
# SSL CERTIFICATES
# ============================================================================

log "Collecting SSL certificates..."

SSL_CERTIFICATES="["
first=true
for cert_dir in /etc/letsencrypt/live/ /etc/ssl/certs/ /etc/nginx/ssl/; do
    if [[ -d "$cert_dir" ]]; then
        while IFS= read -r cert_file; do
            if [[ -f "$cert_file" ]]; then
                if [[ "$first" == "true" ]]; then
                    first=false
                else
                    SSL_CERTIFICATES+=","
                fi
                cert_info=$(openssl x509 -in "$cert_file" -noout -subject -dates -issuer 2>/dev/null | redact_all || echo "Unable to read certificate")
                SSL_CERTIFICATES+="{\"file\":\"$(redact_all "$cert_file")\",\"info\":\"$cert_info\"}"
            fi
        done < <(find "$cert_dir" -name "*.pem" -o -name "*.crt" 2>/dev/null)
    fi
done
SSL_CERTIFICATES+="]"

# ============================================================================
# PORT USAGE
# ============================================================================

log "Collecting port usage..."

PORT_USAGE="["
first=true
while IFS= read -r line; do
    if [[ "$first" == "true" ]]; then
        first=false
    else
        PORT_USAGE+=","
    fi
    port=$(echo "$line" | awk '{print $4}' | sed 's/.*://')
    protocol=$(echo "$line" | awk '{print $1}')
    process=$(echo "$line" | awk '{print $7}' | redact_all)
    PORT_USAGE+="{\"port\":$port,\"protocol\":\"$protocol\",\"process\":\"$process\"}"
done < <(ss -tulnp 2>/dev/null | tail -n +2)
PORT_USAGE+="]"

# ============================================================================
# CRONTABS
# ============================================================================

log "Collecting crontabs..."

CRONTABS="["
first=true
for user in $(cut -f1 -d: /etc/passwd); do
    crontab_content=$(crontab -l -u "$user" 2>/dev/null | grep -v '^#' | grep -v '^$' | redact_all || true)
    if [[ -n "$crontab_content" ]]; then
        if [[ "$first" == "true" ]]; then
            first=false
        else
            CRONTABS+=","
        fi
        # Escape newlines for JSON
        escaped_content=$(echo "$crontab_content" | sed ':a;N;$!ba;s/\n/\\n/g')
        CRONTABS+="{\"user\":\"$user\",\"entries\":\"$escaped_content\"}"
    fi
done
CRONTABS+="]"

# ============================================================================
# SYSTEM SERVICES
# ============================================================================

log "Collecting system services..."

SYSTEM_SERVICES="["
first=true
while IFS= read -r service; do
    if [[ "$first" == "true" ]]; then
        first=false
    else
        SYSTEM_SERVICES+=","
    fi
    service_name=$(echo "$service" | awk '{print $1}' | sed 's/\.service$//')
    service_status=$(systemctl is-active "$service_name" 2>/dev/null || echo "unknown")
    SYSTEM_SERVICES+="{\"name\":\"$service_name\",\"status\":\"$service_status\"}"
done < <(systemctl list-units --type=service --state=running 2>/dev/null | grep "running" | awk '{print $1}' | head -20)
SYSTEM_SERVICES+="]"

# ============================================================================
# NETWORK INTERFACES
# ============================================================================

log "Collecting network interfaces..."

NETWORK_INTERFACES="["
first=true
while IFS= read -r iface; do
    if [[ "$first" == "true" ]]; then
        first=false
    else
        NETWORK_INTERFACES+=","
    fi
    iface_name=$(echo "$iface" | awk '{print $2}' | tr -d ':')
    iface_status=$(echo "$iface" | awk '{print $1}')
    NETWORK_INTERFACES+="{\"name\":\"$iface_name\",\"status\":\"$iface_status\"}"
done < <(ip -br addr 2>/dev/null)
NETWORK_INTERFACES+="]"

# ============================================================================
# DISK PARTITIONS
# ============================================================================

log "Collecting disk partitions..."

DISK_PARTITIONS="["
first=true
while IFS= read -r line; do
    if [[ "$first" == "true" ]]; then
        first=false
    else
        DISK_PARTITIONS+=","
    fi
    device=$(echo "$line" | awk '{print $1}')
    mount=$(echo "$line" | awk '{print $6}')
    fstype=$(echo "$line" | awk '{print $5}')
    size=$(echo "$line" | awk '{print $2}')
    used=$(echo "$line" | awk '{print $3}')
    avail=$(echo "$line" | awk '{print $4}')
    DISK_PARTITIONS+="{\"device\":\"$(redact_all "$device")\",\"mount\":\"$mount\",\"type\":\"$fstype\",\"size\":\"$size\",\"used\":\"$used\",\"available\":\"$avail\"}"
done < <(df -hT 2>/dev/null | tail -n +2 | grep -v tmpfs | grep -v devtmpfs)
DISK_PARTITIONS+="]"

# ============================================================================
# BUILD JSON OUTPUT
# ============================================================================

log "Building JSON output..."

INVENTORY_JSON=$(cat <<EOF
{
  "inventory_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "inventory_version": "1.0",
  "server_info": $SERVER_INFO,
  "disk_usage": $DISK_USAGE,
  "nginx_configs": $NGINX_CONFIGS,
  "pm2_processes": $PM2_PROCESSES,
  "app_directories": $APP_DIRECTORIES,
  "ssl_certificates": $SSL_CERTIFICATES,
  "port_usage": $PORT_USAGE,
  "crontabs": $CRONTABS,
  "system_services": $SYSTEM_SERVICES,
  "network_interfaces": $NETWORK_INTERFACES,
  "disk_partitions": $DISK_PARTITIONS
}
EOF
)

# ============================================================================
# OUTPUT
# ============================================================================

if [[ "$DRY_RUN" == "true" ]]; then
    log "DRY-RUN: Would write inventory to $OUTPUT_FILE"
    echo "$INVENTORY_JSON" | jq . 2>/dev/null || echo "$INVENTORY_JSON"
else
    echo "$INVENTORY_JSON" | jq . > "$OUTPUT_FILE" 2>/dev/null || echo "$INVENTORY_JSON" > "$OUTPUT_FILE"
    log "Inventory written to: $OUTPUT_FILE"
fi

log "Inventory collection completed at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
log "Output has been redacted to remove sensitive information"