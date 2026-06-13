#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="$SCRIPT_DIR/aivox-ui.service"

if [ ! -f "$SERVICE_FILE" ]; then
  echo "Error: aivox-ui.service not found in $SCRIPT_DIR"
  exit 1
fi

echo "Installing AiVox UI service..."
echo "Make sure you've edited aivox-ui.service with your username and paths first!"
echo ""

sudo cp "$SERVICE_FILE" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable aivox-ui
sudo systemctl start aivox-ui
sudo systemctl status aivox-ui
