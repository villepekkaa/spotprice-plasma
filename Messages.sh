#!/bin/bash

# Extract translatable strings from QML files
# This script creates a .pot template file from the source code

# Find the domain name from metadata.json
DOMAIN="spotprice"

# Create template directory if needed
mkdir -p translations

# Create a temporary pot file
POT_FILE="translations/${DOMAIN}.pot"

echo "Creating translation template..."

# Write the header
cat > "$POT_FILE" << EOF
# Translations template for SpotPrice widget
# Copyright (C) 2026 Ville-Pekka Alavuotunki
# This file is distributed under the same license as the SpotPrice package.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: spotprice-widget 1.0.0\\n"
"Report-Msgid-Bugs-To: https://github.com/villepekkaa/spotprice-plasma/issues\\n"
"POT-Creation-Date: $(date +%Y-%m-%d\ %H:%M%z)\\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"Language: \\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"

EOF

# Extract strings from QML files using grep and sed
# Look for i18n("...") patterns

# Function to escape special characters in strings
escape_string() {
    echo "$1" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g'
}

# Extract i18n calls from QML files
find contents -name "*.qml" -exec grep -Hn 'i18n("' {} \; | while read line; do
    file=$(echo "$line" | cut -d: -f1)
    lineno=$(echo "$line" | cut -d: -f2)
    # Extract the string inside i18n("...")
    str=$(echo "$line" | sed 's/.*i18n("\([^"]*\)").*/\1/')
    if [ -n "$str" ] && [ "$str" != "$line" ]; then
        echo "" >> "$POT_FILE"
        echo "#: $file:$lineno" >> "$POT_FILE"
        echo "msgid \"$(escape_string "$str")\"" >> "$POT_FILE"
        echo "msgstr \"\"" >> "$POT_FILE"
    fi
done

echo "Template created: $POT_FILE"
echo ""
echo "To update translation files:"
echo "  msgmerge -U translations/fi.po $POT_FILE"
echo "  msgmerge -U translations/en.po $POT_FILE"
echo ""
echo "To compile translations to .mo files:"
echo "  ./compile_translations.sh"
