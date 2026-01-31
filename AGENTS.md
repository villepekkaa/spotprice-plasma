# AGENTS.md - Development Guidelines

## Project Overview

This is a KDE Plasma 6 widget for displaying Finnish electricity spot prices. It uses QML (Qt Meta Language) and JavaScript for the UI and logic.

## Technology Stack

- **QML**: Declarative UI language for Qt
- **JavaScript**: Logic and API handling
- **KDE Plasma Framework**: Widget APIs
- **Qt 6**: Base framework

## Project Structure

```
.
├── metadata.json              # Widget metadata (name, version, etc.)
├── contents/
│   ├── config/
│   │   └── main.xml           # Configuration options
│   ├── ui/
│   │   ├── main.qml           # Main widget entry point
│   │   ├── CompactView.qml    # Taskbar/compact view
│   │   └── FullView.qml       # Desktop/full view
│   └── code/
│       └── priceFetcher.js    # API and caching logic
├── README.md
├── LICENSE
└── AGENTS.md (this file)
```

## Key Concepts

### QML Basics
- QML is declarative - you describe UI structure, not how to build it
- Uses JavaScript for logic
- Components are reusable building blocks
- Properties are reactive (changes auto-update UI)

### KDE Plasma Widget Structure
- `metadata.json`: Widget identity and metadata
- `contents/ui/main.qml`: Entry point, handles compact/full view switching
- `Plasmoid.compactRepresentation`: Taskbar view
- `Plasmoid.fullRepresentation`: Desktop view

### API Handling
- Use `XMLHttpRequest` for HTTP calls
- Cache to `~/.local/share/plasma/plasmoids/com.villepekkaa.spotprice/cache/`
- Limit API calls (max once per hour)
- Handle offline gracefully

## Development Commands

```bash
# Install locally for testing
cp -r . ~/.local/share/plasma/plasmoids/com.villepekkaa.spotprice

# Restart Plasma (testing changes)
kquitapp6 plasmashell && kstart plasmashell
# or
plasmashell --replace

# Check QML syntax
qml6 -typeinfo contents/ui/main.qml
```

## Coding Standards

- Use 4 spaces for indentation
- Comment complex QML bindings
- Use descriptive property names
- Follow Qt naming conventions (camelCase)

## Color Scheme

- Green: `#4CAF50` (price < 10 c/kWh)
- Yellow: `#FFC107` (price 10-20 c/kWh)
- Red: `#F44336` (price > 20 c/kWh)

## Testing Checklist

- [ ] Widget installs without errors
- [ ] Compact view shows current price
- [ ] Colors update correctly based on price
- [ ] Full view shows bar chart
- [ ] Day switching works
- [ ] Tomorrow prices show after 14:15
- [ ] Caching works (no excessive API calls)
- [ ] Offline mode handles gracefully

## Common Issues

1. **Widget not appearing**: Check metadata.json syntax
2. **API errors**: Verify spot-hinta.fi is accessible
3. **Layout issues**: Check QML anchors and layouts
4. **Colors not updating**: Check price threshold logic

## Resources

- [KDE Plasma Widget Tutorial](https://develop.kde.org/docs/plasma/widget/)
- [QML Documentation](https://doc.qt.io/qt-6/qml-reference.html)
- [spot-hinta.fi API](https://spot-hinta.fi)
- [Plasma Framework API](https://api.kde.org/plasma-framework/html/)

## Git Workflow

1. Create feature branch
2. Make changes
3. Test locally
4. Commit with descriptive message
5. Push to GitHub
6. Create PR if needed

## Questions?

Contact: villepekkaa (GitHub)
