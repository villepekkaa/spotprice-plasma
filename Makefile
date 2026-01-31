# Makefile for SpotPrice Plasma Widget
# Standard Linux installation using KDE's kpackagetool6

WIDGET_ID = com.villepekkaa.spotprice
INSTALL_DIR = $(HOME)/.local/share/plasma/plasmoids/$(WIDGET_ID)

.PHONY: all install uninstall clean restart

all:
	@echo "Available targets:"
	@echo "  make install    - Install the widget using kpackagetool6"
	@echo "  make uninstall  - Remove the widget"
	@echo "  make restart    - Restart Plasma shell to apply changes"
	@echo "  make clean      - Clean build artifacts (none currently)"

install:
	@echo "Installing SpotPrice widget..."
	@mkdir -p $(INSTALL_DIR)
	@cp -r contents metadata.json LICENSE README.md AGENTS.md $(INSTALL_DIR)/
	@echo "Widget files copied to $(INSTALL_DIR)"
	@echo "Installation complete!"
	@echo "Run 'make restart' to reload Plasma, or add the widget manually."

uninstall:
	@echo "Uninstalling SpotPrice widget..."
	@rm -rf $(INSTALL_DIR)
	@echo "Uninstall complete!"

restart:
	@echo "Restarting Plasma shell..."
	kquitapp6 plasmashell 2>/dev/null || true
	sleep 2
	kstart plasmashell &
	@echo "Plasma restarted!"

clean:
	@echo "Nothing to clean"
