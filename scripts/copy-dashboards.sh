#!/bin/bash
#===============================================================================
# Copy Dashboards to Splunk Container
#===============================================================================
# This script copies all dashboard XML files directly to the Splunk container
# Usage: ./copy-dashboards.sh
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_DIR="${SCRIPT_DIR}/../dashboards"
SPLUNK_HOST="${SPLUNK_INDEXER_IP:-10.10.10.114}"
SSH_KEY="${SSH_KEY:-~/.ssh/key_10.10.10.114}"

echo "=============================================="
echo "  Copy Dashboards to Splunk"
echo "=============================================="
echo ""
echo "Source: ${DASHBOARD_DIR}"
echo "Target: ${SPLUNK_HOST}"
echo ""

# First, copy files to remote host
echo "Copying dashboard files to ${SPLUNK_HOST}..."
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "${DASHBOARD_DIR}"/*.xml root@${SPLUNK_HOST}:/tmp/

# Then copy into container
echo "Installing dashboards in Splunk container..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no root@${SPLUNK_HOST} << 'REMOTE'
# Copy dashboards to Splunk app directory
SPLUNK_APP_DIR="/opt/splunk/etc/apps/search/local/data/ui/views"

# Create directory if needed
docker exec splunk-enterprise mkdir -p "$SPLUNK_APP_DIR"

# Copy each dashboard
for xml in /tmp/*.xml; do
    if [ -f "$xml" ]; then
        filename=$(basename "$xml")
        echo "  Installing: $filename"
        docker cp "$xml" splunk-enterprise:"$SPLUNK_APP_DIR/$filename"
        rm "$xml"
    fi
done

# Fix permissions
docker exec splunk-enterprise chown -R splunk:splunk /opt/splunk/etc/apps/search/local/

# Reload dashboards (no restart needed)
docker exec splunk-enterprise /opt/splunk/bin/splunk _internal call /data/ui/views/_reload -auth admin:$(docker exec splunk-enterprise cat /opt/splunk/etc/splunk-launch.conf 2>/dev/null | grep -oP 'SPLUNK_PASSWORD=\K.*' || echo "your_password") 2>/dev/null || true

echo ""
echo "✅ Dashboards installed!"
REMOTE

echo ""
echo "=============================================="
echo "  Dashboard Installation Complete!"
echo "=============================================="
echo ""
echo "Access dashboards at:"
echo "  https://${SPLUNK_HOST}:8000/en-US/app/search/dashboards"
echo ""
echo "If dashboards don't appear, refresh the browser or restart Splunk:"
echo "  ssh root@${SPLUNK_HOST} 'docker restart splunk-enterprise'"
echo ""

