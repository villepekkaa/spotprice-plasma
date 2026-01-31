# SpotPrice - KDE Plasma 6 Widget

A KDE Plasma 6 widget for displaying Finnish electricity spot prices from spot-hinta.fi API.

## Features

- **Compact view (Taskbar)**: Shows current price with color indicator
- **Full view (Desktop)**: Bar chart of today's/tomorrow's hourly prices
- **Color indicators**:
  - 🟢 Green: < 10 c/kWh (cheap)
  - 🟡 Yellow: 10-20 c/kWh (moderate)
  - 🔴 Red: > 20 c/kWh (expensive)
- **Price customization**: Add margin and transfer fee to all displayed prices
- **Centralized configuration**: All widget instances share the same settings
- **Smart caching**: Prices cached locally to avoid API abuse
- **Day switching**: Toggle between today and tomorrow's prices
- **Tomorrow notification**: Shows when tomorrow's prices will be available (14:15 EET)

## Installation

### Standard Method (Recommended)

Using KDE's official package tool:

```bash
# Clone the repository
git clone https://github.com/villepekkaa/spotprices.git
cd spotprices

# Install the widget
kpackagetool6 --install .

# Or if updating an existing installation:
kpackagetool6 --upgrade .
```

### Alternative Methods

**Method 1: Manual Copy**
```bash
mkdir -p ~/.local/share/plasma/plasmoids/com.villepekkaa.spotprice
cp -r contents metadata.json LICENSE README.md AGENTS.md ~/.local/share/plasma/plasmoids/com.villepekkaa.spotprice/
```

**Method 2: Using Makefile (if available)**
```bash
make install
```

### After Installation

Restart Plasma to load the widget:
```bash
kpackagetool6 --global --upgrade ~/.local/share/plasma/plasmoids/com.villepekkaa.spotprice
# or
kquitapp6 plasmashell && kstart plasmashell
```

Then add the widget to your desktop or panel:
   - Right-click on desktop/panel → Add Widgets
   - Search for "SpotPrice"
   - Drag to desired location

### Future: KDE Store (Discover/GHNS)

Once published to [KDE Store](https://store.kde.org), you can install directly through:
- **Discover** (Software Center) → Plasma Addons
- **Plasma Widget Explorer** → Get New Widgets → Download New Plasma Widgets

## Usage

- **Compact view**: Shows current hour's price with color indicator
- **Click to expand**: Opens full view with bar chart
- **Day toggle**: Switch between today and tomorrow (if available)
- **Auto-refresh**: Prices update automatically every hour

## Configuration

Each widget instance has its own independent settings. Right-click any widget and select "Configure..." to open settings.

### Available Settings

- **Price Thresholds**: Customize the price ranges for color indicators (green/yellow/red)
- **Price Margin**: Add a fixed margin to all displayed prices (e.g., electricity company margin)
- **Transfer Fee**: Add a transfer fee to all displayed prices (e.g., network transmission cost)

**Note:** Settings are per-widget instance. If you have multiple widgets (e.g., one on desktop and one on panel), each has its own separate configuration.

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
