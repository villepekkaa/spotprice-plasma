#!/bin/bash
# Create centralized config directory for spotprices widget

CONFIG_DIR="$HOME/.config/spotprices"

mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_DIR/settings.json" ]; then
    cat > "$CONFIG_DIR/settings.json" << 'EOF'
{
  "greenThreshold": 10,
  "yellowThreshold": 20,
  "redThreshold": 30,
  "priceMargin": 0,
  "transferFee": 0
}
EOF
    echo "Created default settings.json"
fi

echo "Config directory ready: $CONFIG_DIR"
