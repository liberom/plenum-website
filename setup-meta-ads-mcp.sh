#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Meta Ads MCP — Setup Script for Plenum AI Systems
# ═══════════════════════════════════════════════════════════
#
# This script configures the Meta Ads MCP server for use with Hermes.
#
# PREREQUISITES:
#   1. A Meta Business account with an ad account
#   2. A Meta Developer app with Marketing API access
#   3. A long-lived access token with ads_read permission
#
# If you don't have #2 and #3 yet, follow the steps in the README first.
# ═══════════════════════════════════════════════════════════

set -e

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Meta Ads MCP — Setup for Plenum AI Systems"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if meta-ads-mcp is installed
if ! command -v meta-ads-mcp &> /dev/null; then
    echo "Installing meta-ads-mcp..."
    pip install --break-system-packages meta-ads-mcp
fi

echo ""
echo "This script will:"
echo "  1. Start the Meta Ads MCP server locally"
echo "  2. Configure Hermes to connect to it"
echo ""
echo "You need a Meta long-lived access token with these permissions:"
echo "  - ads_read"
echo"  - ads_management (optional, for write access)"
echo ""
echo "To get a token:"
echo "  1. Go to https://developers.facebook.com/tools/explorer/"
echo "  2. Select your app"
echo "  3. Select 'User Token'"
echo "  4. Check 'ads_read' permission"
echo "  5. Click 'Generate Access Token'"
echo "  6. Copy the token"
echo ""
echo "  To make it long-lived (60 days):"
echo "  Go to https://developers.facebook.com/tools/debug/accesstoken/"
echo "  Paste your token and click 'Debug', then 'Extend Token'"
echo ""

read -p "Paste your long-lived access token: " ACCESS_TOKEN

if [ -z "$ACCESS_TOKEN" ]; then
    echo "ERROR: No token provided. Exiting."
    exit 1
fi

echo ""
echo "Starting Meta Ads MCP server on port 8080..."

# Start the MCP server in the background
META_ACCESS_TOKEN="$ACCESS_TOKEN" meta-ads-mcp --transport streamable-http --port 8080 &
MCP_PID=$!

sleep 3

# Test the connection
if curl -s http://localhost:8080/mcp > /dev/null 2>&1; then
    echo "✓ Meta Ads MCP server is running on http://localhost:8080"
else
    echo "✗ Failed to start MCP server"
    kill $MCP_PID 2>/dev/null
    exit 1
fi

echo ""
echo "Adding to Hermes configuration..."

# Add to Hermes MCP config
hermes mcp add meta-ads --url "http://localhost:8080/mcp" 2>&1

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✓ Meta Ads MCP configured!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "The MCP server is running in the background (PID: $MCP_PID)."
echo "To stop it: kill $MCP_PID"
echo ""
echo "To make it permanent, add this to your Hermes config:"
echo ""
echo "  mcp_servers:"
echo "    meta-ads:"
echo "      command: meta-ads-mcp"
echo "      args: [--transport, streamable-http, --port, '8080']"
echo "      env:"
echo "        META_ACCESS_TOKEN: $ACCESS_TOKEN"
echo "      enabled: true"
echo ""
