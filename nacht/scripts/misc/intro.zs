class nacht_Intro : Inventory {
    const skipKey = bt_user1;

    override void attachToOwner(Actor owner) {
        super.attachToOwner(owner);
        owner.setCamera(Level.createActorIterator(13).next());
    }

    override void doEffect() {
		super.doEffect();
        if (self.owner.getPlayerInput(modInput_oldButtons) & self.skipKey) {
            nacht_IntroOverlay.fetch().startMap();
		}
    }

    override void detachFromOwner() {
        self.owner.setCamera(self.owner);
		zmd_Overlay.fetch().active[self.owner.playerNumber()] = true;
        super.detachFromOwner();
    }
}

class nacht_SwayTarget : Actor {
    const maxWidth = 10;
    const maxHeight = 10;
    const ticksTillChange = 120;

    Vector3 originalPosition;
    Vector3 lastPosition;
    Vector3 targetPosition;
    int ticsSinceChange;

    static Vector3 lerp(Vector3 start, Vector3 end, double percent) {
        return start + percent * (end - start);
    }

    static Vector3 smoothStep(Vector3 start, Vector3 end, double ticks) {
        let percent = ticks / nacht_SwayTarget.ticksTillChange;
        return nacht_SwayTarget.lerp(start, end, percent * percent * percent * (percent * (6 * percent - 15) + 10));
    }

    override void beginPlay() {
        super.beginPlay();
        self.originalPosition = self.pos;
        self.changeTargetPosition();
    }

    override void tick() {
        if (self.ticsSinceChange == self.ticksTillChange) {
            self.ticsSinceChange = 0;
            self.changeTargetPosition();
        } else {
            ++self.ticsSinceChange;
            self.setXYZ(self.smoothStep(self.lastPosition, self.targetPosition, self.ticsSinceChange));
        }
    }

    void changeTargetPosition() {
        self.lastPosition = self.pos;
        self.targetPosition = self.originalPosition + (random[offset](-self.maxWidth, self.maxWidth), 0, random[offset](0, self.maxHeight));
    }
}

class nacht_IntroOverlay : EventHandler {
	bool active;
	int ticsSinceStart;
	double alpha;
	Vector2 textOffset;
	Vector2 textScale;
	Font font;
	int color;

	const introCameraTid = 13;
	const flashDelay = 35 * 3;
    const blackScreenDelay = 35 * 18;
    const textDelay = 35 * 5;
	const startDelay = 1015;

	clearscope static nacht_IntroOverlay fetch() {
		return nacht_IntroOverlay(EventHandler.find('nacht_IntroOverlay'));
	}

	override void worldLoaded(WorldEvent e) {
		self.active = true;
		self.textScale = (3, 5);
		self.font = bigFont;
		self.color = Font.cr_red;
		Level.createActorIterator(nacht_IntroOverlay.introCameraTid).next().a_startSound("game/intro_cinematic", chan_5, attenuation: attn_none);
	}

	override void playerEntered(PlayerEvent e) {
		zmd_Overlay.fetch().active[e.playerNumber] = false;
		players[e.playerNumber].mo.giveInventory('nacht_Intro', 1);
	}

    void changeTextOffset() {
        let limit = 1;
        self.textOffset = (random[offset](-limit, limit), (random[offset](-limit, limit)));
    }

	void startMap() {
        Actor.spawn('Weather');
        Weather.setPrecipitationType('BloodRain');

        let zombie_tid = 115;
        let sway_target_tid = 25;

        Level.createActorIterator(zombie_tid).next().destroy();
        Level.createActorIterator(nacht_IntroOverlay.introCameraTid).next().a_stopSound(chan_5);
        thing_destroy(sway_target_tid);
        foreach (player : players) {
			let player = player.mo;
			if (player) {
				zmd_Spectate.setOriginToSpawn(player);
				player.takeInventory('nacht_Intro', 1);
			}
        }
        zmd_Rounds.fetch().nextRound();
		nacht_IntroOverlay.fetch().active = false;
    }

	override void worldTick() {
		if (self.active) {
			++self.ticsSinceStart;
			if (self.ticsSinceStart == 4) {
				thing_activate(20);
			}

			if (self.ticsSinceStart < self.blackScreenDelay) {
				self.alpha = abs((self.ticsSinceStart % (self.flashDelay * 2) - self.flashDelay) / double(self.flashDelay));
			} else if (self.ticsSinceStart == self.blackScreenDelay) {
				self.changeTextOffset();
				self.alpha = 0.0;
			} else if (self.ticsSinceStart == self.startDelay) {
				self.startMap();
			} else {
				if (self.ticsSinceStart % 3 == 0) {
					self.changeTextOffset();
				}
				self.alpha = (self.ticsSinceStart - self.blackScreenDelay) / double(self.textDelay);
			}
		}
	}

	override void renderOverlay(RenderEvent e) {
		if (self.active) {
			if (self.ticsSinceStart < self.blackScreenDelay)
				Screen.dim("black", self.alpha, 0, 0, screen.getWidth(), Screen.getHeight());
			else {
				Screen.dim("black", 1.0, 0, 0, Screen.getWidth(), Screen.getHeight());
				let doomed = "Doomed";
				let zombies = "Zombies";
				Screen.drawText(self.font, self.color, zmd_Overlay.centerX - (self.font.stringWidth(doomed) + 5) * self.textScale.x / 2 + self.textOffset.x, 20 + self.textOffset.y, doomed, dta_scaleX, self.textScale.x, dta_scaleY, self.textScale.y, dta_alpha, self.alpha, dta_spacing, 1, dta_320x200, true);
				Screen.drawText(self.font, self.color, zmd_Overlay.centerX - (self.font.stringWidth(zombies) + 6) * self.textScale.x / 2 + self.textOffset.x, 110 + self.textOffset.y, zombies, dta_scaleX, self.textScale.x, dta_scaleY, self.textScale.y, dta_alpha, self.alpha, dta_spacing, 1, dta_320x200, true);
			}
		}
    }
}