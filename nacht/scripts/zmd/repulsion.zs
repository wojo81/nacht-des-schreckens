class zmd_Repulsion : Inventory {
    const key = bt_user1;

    zmd_RepulsionHandler handler;
    int tickCount;

    property tickCount: tickCount;

    Default {
        Inventory.maxAmount 1;
        zmd_Repulsion.tickCount 35 * 5;
    }

    static void giveTo(PlayerPawn player, zmd_RepulsionHandler handler) {
        player.giveInventory('zmd_Repulsion', 1);
        zmd_Repulsion(player.findInventory('zmd_Repulsion')).handler = handler;
    }

    override void doEffect() {
        if (self.justTapped()) {
            self.tickCount = self.Default.tickCount;
        } else if (self.tickCount-- == 0) {
            self.handler.deactivate();
        }
    }

    bool justTapped() {
        return self.owner.getPlayerInput(modInput_oldButtons) & self.key && !(self.owner.getPlayerInput(modInput_buttons) & self.key);
    }
}

class zmd_RepulsionHandler : EventHandler {
    zmd_Rounds rounds;

    static void bindWith(zmd_Rounds rounds) {
        let self = zmd_RepulsionHandler(EventHandler.find('zmd_RepulsionHandler'));
        rounds.repulsionHandler = self;
        self.rounds = rounds;
    }

    void activate() {
        foreach (player : players) {
			let player = player.mo;
            if (player != null) {
                zmd_Repulsion.giveTo(player, self);
			}
        }
    }

    void deactivate() {
        self.rounds.nextRound();
        foreach (player : players) {
			let player = player.mo;
            if (player != null) {
                player.takeInventory('zmd_Repulsion', 1);
            }
        }
    }
}