class zmd_Points : Inventory {
    Default {
        Inventory.maxAmount 999999;
        +Inventory.undroppable;
    }

    static bool takeFrom(PlayerPawn player, int cost) {
        if (player.countInv('zmd_Points') >= cost) {
            player.takeInventory('zmd_Points', cost);
			zmd_InventoryManager.fetchFrom(player).pointsOverlay.deltas.push(zmd_PointsDecrease.create(cost));
            return true;
        }
        return false;
    }

    override void setGiveAmount(Actor receiver, int amount, bool giveCheat) {
		if (receiver.findInventory('zmd_lastStand') || receiver.findInventory('zmd_Spectate')) {
			amount = 0;
		} else {
			if (!giveCheat)
				amount <<= receiver.countInv('zmd_DoublePointsPower');
			else if (amount == 1)
				amount = 50000;
			zmd_InventoryManager.fetchFrom(receiver).pointsOverlay.deltas.push(zmd_PointsIncrease.create(amount));
        }
		super.setGiveAmount(receiver, amount, giveCheat);
    }
}

class zmd_PointsHandler : EventHandler {
    override void worldThingDamaged(WorldEvent e) {
        if (e.damageSource is 'PlayerPawn' && e.thing.bisMonster && e.damageType != 'None') {
            e.damageSource.giveInventory('zmd_Points', 10);

            if (e.thing.health <= 0 || e.damageSource.countInv('zmd_InstakillPower') != 0) {
                if (e.damageType == 'bottle')
                    e.damageSource.giveInventory('zmd_Points', 150);
                else if (e.damageType == 'kick')
                    e.damageSource.giveInventory('zmd_Points', 120);
                else if (e.damageType == 'zmd_headshot')
                    e.damageSource.giveInventory('zmd_points', 90);
                else
                    e.damageSource.giveInventory('zmd_points', 50);
            }
        }
    }
}

class zmd_PointsOverlay : zmd_OverlayItem {
	const color = Font.cr_sapphire;

	Font font;
	Array<zmd_PointsDelta> deltas;

	static zmd_PointsOverlay create() {
		let overlay = new('zmd_PointsOverlay');
		overlay.font = bigFont;
		return overlay;
	}

	override void update(zmd_InventoryManager manager) {
		while (self.deltas.size() && self.deltas[0].ticksLeft == 0) {
			self.deltas.delete(0);
		}
		foreach (delta : self.deltas) {
			delta.update(manager);
		}
	}

	override void render(RenderEvent e) {
		zmd_Overlay.leftText(self.font, zmd_PointsOverlay.color, zmd_Overlay.margin, ''..players[consolePlayer].mo.countInv('zmd_Points'));
		foreach (delta : self.deltas) {
			delta.render(e);
		}
	}
}

class zmd_PointsDelta : zmd_OverlayItem abstract {
	const margin = zmd_Overlay.margin + 3;
	const scale = 0.75;
	const fadeDelay = 55;

	Font font;
	int value, color, ticksLeft;
	Vector2 position, velocity;
	double alpha;

	void init(int value) {
		self.font = smallFont;
		self.value = value;
		self.position = (45, zmd_PointsDelta.margin);
		self.ticksLeft = zmd_PointsDelta.fadeDelay;
		self.alpha = 1.0;
	}

	override void update(zmd_InventoryManager manager) {
		self.position += self.velocity;
		--self.ticksLeft;
		self.alpha = self.ticksLeft / double(zmd_PointsDelta.fadeDelay);
	}
}

class zmd_PointsIncrease : zmd_PointsDelta {
	const leastColor = Font.cr_gold;
	const lowColor = Font.cr_orange;
	const midColor = Font.cr_red;
	const highColor = Font.cr_purple;

	static zmd_PointsIncrease create(int value) {
		let increase = new('zmd_PointsIncrease');
		increase.init(value);
		if (value < 50)
            increase.color = zmd_PointsIncrease.leastColor;
        else if (value < 90)
            increase.color = zmd_PointsIncrease.lowColor;
        else if (value < 120)
            increase.color = zmd_PointsIncrease.midColor;
        else
            increase.color = zmd_PointsIncrease.highColor;
        increase.velocity = (frandom[pointIncrease](0.4, 1.4), frandom[pointIncrease](-0.2, 0.4));
		return increase;
	}

	override void render(RenderEvent e) {
		Screen.drawText(self.font, self.color, self.position.x, self.position.y, '+'..self.value, dta_scaleX, self.scale, dta_scaleY, self.scale, dta_alpha, self.alpha, dta_320x200, true);
	}
}

class zmd_PointsDecrease : zmd_PointsDelta {
	const regularColor = Font.cr_darkRed;

	static zmd_PointsDecrease create(int value) {
		let decrease = zmd_PointsDecrease(new('zmd_PointsDecrease'));
		decrease.init(value);
		decrease.color = zmd_PointsDecrease.regularColor;
		decrease.velocity = (0, 0.1);
		return decrease;
	}

	override void render(RenderEvent e) {
		Screen.drawText(self.font, self.color, self.position.x, self.position.y, '-'..self.value, dta_scaleX, self.scale, dta_scaleY, self.scale, dta_alpha, self.alpha, dta_320x200, true);
	}
}