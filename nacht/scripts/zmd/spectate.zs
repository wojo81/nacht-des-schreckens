class zmd_Spectate : Inventory {
	const key = bt_use;
	int playerIndex;

    static void setOriginToSpawn(Actor player) {
        player.setOrigin(Level.createActorIterator(100 + player.playerNumber()).next().pos, false);
    }

	override void doEffect() {
		if (self.justTapped()) {
			console.printf('test');
			self.owner.setCamera(self.choosePlayer());
		}
	}

    override void attachToOwner(Actor owner) {
        super.attachToOwner(owner);
        zmd_InventoryManager.fetchFrom(owner).spectating = true;
		self.playerIndex = owner.playerNumber();
        owner.setOrigin((-2150, 2500, 0), false);
        owner.setCamera(self.choosePlayer());
    }

    override void detachFromOwner() {
        let manager = zmd_InventoryManager.fetchFrom(self.owner);
        if (!manager.gameOver) {
            manager.spectating = false;
            self.setOriginToSpawn(self.owner);
            self.owner.setCamera(self.owner);
        }
        super.detachFromOwner();
    }

    Actor choosePlayer() {
        for (let i = playerIndex; i != players.size(); ++i) {
			let player = players[i].mo;
			if (player == null) {
				i = 0;
			} else {
				let playerNumber = player.playerNumber();
				if (playerNumber != self.owner.playerNumber() && playerNumber != self.playerIndex) {
					self.playerIndex = player.playerNumber();
					return player;
				}
			}
        }
        return null;
    }

	bool justTapped() {
        return self.owner.getPlayerInput(modInput_oldButtons) & self.key && !(self.owner.getPlayerInput(modInput_buttons) & self.key);
    }
}

class zmd_GameOverSpectate : Inventory {
    override void attachToOwner(Actor owner) {
        super.attachToOwner(owner);
		let gameOverTid = 11;
        zmd_InventoryManager.fetchFrom(owner).gameOver = true;
        owner.setOrigin((-2150, 2500, 0), false);
        thing_activate(gameOverTid);
        owner.setCamera(Level.createActorIterator(gameOverTid).next());
    }
}