# SpotPrice - KDE Plasma 6 Widget

A KDE Plasma 6 widget for displaying Finnish electricity spot prices from spot-hinta.fi API.

## Features

- **Compact view (Taskbar)**: Shows current price with color indicator
- **Full view (Desktop)**: Bar chart of today's/tomorrow's hourly prices
- **Color indicators**:
  - 🟢 Green: < 10 c/kWh (cheap)
  - 🟡 Yellow: 10-20 c/kWh (moderate)
  - 🔴 Red: > 20 c/kWh (expensive)
- **Smart caching**: Prices cached locally to avoid API abuse
- **Day switching**: Toggle between today and tomorrow's prices
- **Tomorrow notification**: Shows when tomorrow's prices will be available (14:15 EET)

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/villepekkaa/spotprices.git
cd spotprices
```

2. Copy to Plasma widgets directory (excluding .git):
```bash
mkdir -p ~/.local/share/plasma/plasmoids/com.villepekkaa.spotprice
cp -r contents metadata.json LICENSE README.md AGENTS.md ~/.local/share/plasma/plasmoids/com.villepekkaa.spotprice/
```

3. Restart Plasma or run:
```bash
kpackagetool6 --upgrade ~/.local/share/plasma/plasmoids/com.villepekkaa.spotprice
```

Alternative restart methods:
```bash
kquitapp6 plasmashell && kstart plasmashell
# or
plasmashell --replace
```

4. Add widget to your desktop or panel:
   - Right-click on desktop/panel → Add Widgets
   - Search for "SpotPrice"
   - Drag to desired location

## Usage

- **Compact view**: Shows current hour's price with color indicator
- **Click to expand**: Opens full view with bar chart
- **Day toggle**: Switch between today and tomorrow (if available)
- **Auto-refresh**: Prices update automatically every hour

## Configuration

The widget automatically detects your location and shows Finnish (FI) prices. Future versions may support other regions.

## API

This widget uses the [spot-hinta.fi](https://spot-hinta.fi) API for price data. Prices are cached locally to minimize API requests.

## Requirements

- KDE Plasma 6.5.5 or later
- Qt 6.x

## License

MIT License - See LICENSE file

## Author

Ville-Pekka Alavuotunki

## Contributing

Contributions welcome! Please read AGENTS.md for development guidelines.
