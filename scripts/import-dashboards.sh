#!/bin/bash
#===============================================================================
# Import All Dashboards to Splunk Enterprise
#===============================================================================
# This script imports all dashboard XML files to Splunk via REST API
# Usage: ./import-dashboards.sh
#===============================================================================

set -e

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_DIR="${SCRIPT_DIR}/../dashboards"

# Configuration
SPLUNK_HOST="${SPLUNK_INDEXER_IP:-10.10.10.114}"
SPLUNK_PORT="8089"
SPLUNK_USER="admin"
SPLUNK_PASSWORD="${SPLUNK_PASSWORD:-your_password_here}"
SPLUNK_APP="search"  # Default app for dashboards

echo "=============================================="
echo "  Splunk Dashboard Importer"
echo "=============================================="
echo ""
echo "Splunk Host: ${SPLUNK_HOST}:${SPLUNK_PORT}"
echo "Dashboard Dir: ${DASHBOARD_DIR}"
echo ""

# Check if dashboards directory exists
if [ ! -d "$DASHBOARD_DIR" ]; then
    echo "❌ Dashboard directory not found: $DASHBOARD_DIR"
    exit 1
fi

# Function to import a dashboard
import_dashboard() {
    local xml_file="$1"
    local filename=$(basename "$xml_file" .xml)
    
    # Read dashboard XML content
    local dashboard_xml=$(cat "$xml_file")
    
    # Extract label from XML
    local label=$(echo "$dashboard_xml" | grep -oP '(?<=<label>)[^<]+' | head -1)
    if [ -z "$label" ]; then
        label="$filename"
    fi
    
    echo -n "  Importing: $filename ($label)... "
    
    # Check if dashboard exists
    local exists=$(curl -s -k -u "${SPLUNK_USER}:${SPLUNK_PASSWORD}" \
        "https://${SPLUNK_HOST}:${SPLUNK_PORT}/servicesNS/admin/${SPLUNK_APP}/data/ui/views/${filename}" \
        -o /dev/null -w "%{http_code}")
    
    if [ "$exists" = "200" ]; then
        # Update existing dashboard
        response=$(curl -s -k -u "${SPLUNK_USER}:${SPLUNK_PASSWORD}" \
            "https://${SPLUNK_HOST}:${SPLUNK_PORT}/servicesNS/admin/${SPLUNK_APP}/data/ui/views/${filename}" \
            -X POST \
            -d "eai:data=$(cat "$xml_file" | python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")" \
            2>&1)
        
        if echo "$response" | grep -q "error"; then
            echo "❌ Failed"
            echo "$response"
        else
            echo "✅ Updated"
        fi
    else
        # Create new dashboard
        response=$(curl -s -k -u "${SPLUNK_USER}:${SPLUNK_PASSWORD}" \
            "https://${SPLUNK_HOST}:${SPLUNK_PORT}/servicesNS/admin/${SPLUNK_APP}/data/ui/views" \
            -X POST \
            -d "name=${filename}" \
            -d "eai:data=$(cat "$xml_file" | python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")" \
            2>&1)
        
        if echo "$response" | grep -q "error"; then
            echo "❌ Failed"
            echo "$response"
        else
            echo "✅ Created"
        fi
    fi
}

# Test connection
echo "Testing connection to Splunk..."
test_response=$(curl -s -k -u "${SPLUNK_USER}:${SPLUNK_PASSWORD}" \
    "https://${SPLUNK_HOST}:${SPLUNK_PORT}/services/server/info" \
    -o /dev/null -w "%{http_code}" 2>&1)

if [ "$test_response" != "200" ]; then
    echo "❌ Cannot connect to Splunk at ${SPLUNK_HOST}:${SPLUNK_PORT}"
    echo "   Please check credentials and connectivity."
    echo ""
    echo "To set credentials, export these variables:"
    echo "  export SPLUNK_INDEXER_IP=10.10.10.114"
    echo "  export SPLUNK_PASSWORD=your_password"
    exit 1
fi

echo "✅ Connected to Splunk"
echo ""

# Import all dashboards
echo "Importing dashboards..."
echo ""

for xml_file in "$DASHBOARD_DIR"/*.xml; do
    if [ -f "$xml_file" ]; then
        import_dashboard "$xml_file"
    fi
done

echo ""
echo "=============================================="
echo "  Dashboard Import Complete!"
echo "=============================================="
echo ""
echo "Access your dashboards at:"
echo "  https://${SPLUNK_HOST}:8000/en-US/app/search/dashboards"
echo ""
echo "Available Dashboards:"
for xml_file in "$DASHBOARD_DIR"/*.xml; do
    filename=$(basename "$xml_file" .xml)
    label=$(grep -oP '(?<=<label>)[^<]+' "$xml_file" | head -1)
    echo "  • $label"
done
echo ""

