#!/bin/bash

# Compile .po files to .mo files for installation

DOMAIN="spotprice"
LOCALE_DIR="contents/locale"

echo "Compiling translations..."

# Create locale directories and compile .mo files
for po_file in translations/*.po; do
    if [ -f "$po_file" ]; then
        # Get language code from filename (e.g., fi.po -> fi)
        lang=$(basename "$po_file" .po)
        
        # Create directory structure
        mo_dir="$LOCALE_DIR/$lang/LC_MESSAGES"
        mkdir -p "$mo_dir"
        
        # Compile .po to .mo
        mo_file="$mo_dir/${DOMAIN}.mo"
        msgfmt -o "$mo_file" "$po_file"
        
        echo "  $lang: $po_file -> $mo_file"
    fi
done

echo ""
echo "Translations compiled successfully!"
echo "Install the widget to see the translations in action."
