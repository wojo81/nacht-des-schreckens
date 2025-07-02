class zmd_HintOverlay : zmd_OverlayItem {
	const removalDelay = 35;
	const offset = 24;

	String hint;
	int ticksLeft;

	static zmd_HintOverlay create() {
		return zmd_HintOverlay(new('zmd_HintOverlay'));
	}

	override void update(zmd_InventoryManager manager) {
		if (self.ticksLeft == 0) {
			self.hint = '';
		}
		--self.ticksLeft;
	}

	override void render(RenderEvent e) {
		if (self.hint != "") {
			zmd_Overlay.centerText(conFont, Font.cr_blue, zmd_Overlay.margin + offset, self.hint);
		}
	}

	void set(String hint) {
		self.hint = hint;
		self.ticksLeft = zmd_HintOverlay.removalDelay;
	}

	void reset() {
		self.ticksLeft = 0;
	}
}