class zmd_Hud : BaseStatusBar {
	zmd_Overlay overlay;

	override void draw(int state, double ticFrac) {
		super.draw(state, ticFrac);
		if (self.overlay && self.overlay.active[consolePlayer] && !self.overlay.managers[consolePlayer].gameOver) {
			let weapon = players[consolePlayer].readyWeapon;
			if (weapon is 'zmd_Weapon') {
				zmd_Overlay.rightText(overlay.regularFont, overlay.ammoColor, zmd_Overlay.height - overlay.regularFont.getHeight(), zmd_Weapon(weapon).activeAmmo..'/'..players[consolePlayer].mo.countInv(weapon.ammoType1));
			} else if (weapon != null) {
				zmd_Overlay.rightText(overlay.regularFont, overlay.ammoColor, zmd_Overlay.height - overlay.regularFont.getHeight(), ''..players[consolePlayer].mo.countInv(weapon.ammoType1));
			}
		}
	}
}

class zmd_Overlay : EventHandler {
	Font regularFont;
	Font messageFont;
	const roundColor = Font.cr_red;
	const ammoColor = Font.cr_green;
	const messageColor = Font.cr_blue;
	const width = 320;
	const height = 200;
	const centerX = 160;
	const centerY = 100;
	const margin = 9;
	const flashDelay = 35 * 2;

    int ticksSinceGameOver;
    double alpha;
	bool active[4];
	zmd_InventoryManager managers[4];
	zmd_Rounds rounds;

	clearscope static zmd_Overlay fetch() {
		return zmd_Overlay(EventHandler.find('zmd_Overlay'));
	}

	override void worldLoaded(WorldEvent e) {
		self.regularFont = bigFont;
		self.messageFont = conFont;
		self.rounds = zmd_Rounds.fetch();
	}

	override void playerSpawned(PlayerEvent e) {
		self.active[e.playerNumber] = true;
	}

	ui static void centerText(Font font, int color, double y, String text, double alpha = 1.0) {
		Screen.drawText(font, color, centerX - font.stringWidth(text) / 2, y, text, dta_alpha, alpha, dta_320x200, true);
	}

	ui static void rightText(Font font, int color, double y, String text, double alpha = 1.0) {
		Screen.drawText(font, color, width - font.stringWidth(text) - margin, y, text, dta_alpha, alpha, dta_320x200, true);
	}

	ui static void leftText(Font font, int color, double y, String text, double alpha = 1.0) {
		Screen.drawText(font, color, margin, y, text, dta_alpha, alpha, dta_320x200, true);
	}

	override void worldTick() {
		if (self.managers[consolePlayer].gameOver) {
            self.alpha = abs((self.ticksSinceGameOver++ % (self.flashDelay * 2) - self.flashDelay) / double(self.flashDelay));
        }
	}

	override void renderOverlay(RenderEvent e) {
		if (self.active[consolePlayer]) {
			let manager = self.managers[consolePlayer];
			if (manager.gameOver) {
				zmd_Overlay.centerText(bigFont, Font.cr_red, zmd_Overlay.centerY - bigFont.getHeight(), "Game Over", self.alpha);
			} else if (manager.lastStand) {
				manager.powerupOverlay.render(e);
                Screen.dim("red", 0.4, 0, 0, screen.getWidth(), screen.getHeight());
			} else if (!manager.spectating) {
				foreach (overlay : manager.overlays) {
					overlay.render(e);
				}
			}
		}
	}
}

class zmd_OverlayItem abstract {
	abstract void update(zmd_InventoryManager manager);
	ui abstract void render(RenderEvent e);
}