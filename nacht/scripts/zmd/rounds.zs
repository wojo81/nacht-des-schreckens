class zmd_Rounds : EventHandler {
    const maxHordeCount = 32;
    const introSound = "game/intro";
    const beginRoundSound = "game/round";
    const endRoundSound = "game/siren";

    int currentRound;
    int zombieHealth;
    int unspawnedZombies;
    int liveZombies;
    int zombiesLeft;
    int tickCount;
    bool isTransitioning;

    zmd_Spawning spawning;
    zmd_DropPool dropPool;
    zmd_RepulsionHandler repulsionHandler;

    clearscope static zmd_Rounds fetch() {
        return zmd_Rounds(EventHandler.find('zmd_Rounds'));
    }

    override void worldLoaded(WorldEvent e) {
        self.dropPool = zmd_DropPool.fetch();
        self.spawning = zmd_Spawning.init(self);
        zmd_RepulsionHandler.bindWith(self);
    }

    override void worldThingDied(WorldEvent e) {
        if (!self.isTransitioning && e.thing && e.thing.bIsMonster) {
            self.zombieKilled();
            if (self.roundOver()) {
                s_startSound(self.endRoundSound, chan_auto, pitch: 0.5);
                self.isTransitioning = true;
                zmd_RoundDelay.create(self);
            }
        }
    }

    // override void worldTick() {
    //     super.worldTick();
    //     console.printf("");
    //     console.printf("unspawned %d", self.unspawnedZombies);
    //     console.printf("live zombies %d", self.liveZombies);
    //     console.printf("zombies left %d", self.zombiesLeft);
    // }

    int calcZombiesHealth() {
        return 25 + 20 * (self.currentRound - 1);
    }

    int calcZombiesCount() {
        return 4 + 3 * (self.currentRound - 1);
    }

    void nextRound() {
        ++self.currentRound;
        self.zombieHealth = self.calcZombiesHealth();
        self.unspawnedZombies = self.calcZombiesCount();
        self.zombiesLeft = self.unspawnedZombies;
        self.isTransitioning = false;
        self.dropPool.handleRoundChange();

        if (self.currentRound == 1)
            s_startSound(self.introSound, chan_auto);
        else
            s_startSound(self.beginRoundSound, chan_auto);

        foreach (player : players) {
			let player = player.mo;
            if (player != null && player.countInv('zmd_Spectate') != 0) {
                player.takeInventory('zmd_Spectate', 1);
                zmd_InventoryManager.fetchFrom(player).reset();
            }
        }
    }

    void zombieKilled() {
        --self.liveZombies;
        --self.zombiesLeft;
    }

    bool roundOver() {
        return self.zombiesLeft == 0;
    }

    bool readyToSpawn() {
        return !self.isTransitioning && self.liveZombies != self.maxHordeCount && self.unspawnedZombies != 0;
    }

    void tryRepulse() {
        self.repulsionHandler.activate();
    }
}

class zmd_RoundDelay : Thinker {
    const delay = 35 * 10;

    zmd_Rounds rounds;
    int tickCount;

    static zmd_RoundDelay create(zmd_Rounds rounds) {
        let self = new('zmd_RoundDelay');
        self.rounds = rounds;
        self.tickCount = delay;
        return self;
    }

    override void tick() {
        if (self.tickCount-- == 0) {
            self.rounds.tryRepulse();
            self.destroy();
        }
    }
}

class zmd_RoundsOverlay : zmd_OverlayItem {
	const fadeInDelay = 35 * 2;
	const fadeOutDelay = 35 * 5;
	const flashDelay = 35;

	zmd_Rounds rounds;
	int ticksSinceTransition;
	int color;
	double alpha;

	static zmd_RoundsOverlay create() {
		zmd_RoundsOverlay overlay = new('zmd_RoundsOverlay');
		overlay.rounds = zmd_Rounds.fetch();
		overlay.color = Font.cr_red;
		overlay.alpha = 1.0;
		return overlay;
	}

	override void update(zmd_InventoryManager manager) {
		if (self.rounds.isTransitioning) {
            if (self.ticksSinceTransition == self.fadeOutDelay) {
                self.alpha = 0.0;
                self.color = Font.cr_red;
            } else if (self.ticksSinceTransition < self.fadeOutDelay) {
                ++self.ticksSinceTransition;
                self.alpha = abs((self.ticksSinceTransition % (self.flashDelay * 2) - self.flashDelay) / double(self.flashDelay));
                self.color = Font.cr_untranslated;
            }
        } else if (self.ticksSinceTransition != 0) {
            if (self.ticksSinceTransition == self.fadeOutDelay)
                self.ticksSinceTransition = self.fadeInDelay;
            --self.ticksSinceTransition;
            self.alpha = double(self.fadeInDelay - self.ticksSinceTransition) / self.fadeInDelay;
        }
	}

	override void render(RenderEvent e) {
		zmd_Overlay.rightText(bigFont, self.color, zmd_Overlay.margin, ''..self.rounds.currentRound, self.alpha);
	}
}