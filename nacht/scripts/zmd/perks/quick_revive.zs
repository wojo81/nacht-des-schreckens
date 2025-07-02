class zmd_QuickReviveMachine : zmd_PerkMachine {
    int buyCount;

    Default {
        zmd_PerkMachine.cost 1500;
        zmd_PerkMachine.drink 'zmd_QuickReviveDrink';
    }

    override void postBeginPlay() {
        super.postBeginPlay();

        if (!multiplayer) {
            self.cost = 500;
            self.drink = 'zmd_ReviveDrink';
        }
    }

    override bool doUse(PlayerPawn player) {
        let used = super.doUse(player);
        if (used && !multiplayer && ++self.buyCount == 3) {
            self.setStateLabel('Vanish');
        }
        return used;
    }

    States {
    Spawn:
        qkrv a 1;
        loop;
    Vanish:
        stop;
    }
}

class zmd_QuickReviveDrink : zmd_Drink {
    Default {
        zmd_Drink.perk 'zmd_QuickRevive';
        tag 'Quick Revive';
    }

    States {
    Sprites:
        dq0r a 0;
        dq1r a 0;
        dq2r a 0;
    Spawn:
        qra0 a -1;
        loop;
    }
}

class zmd_ReviveDrink : zmd_QuickReviveDrink {
    Default {
        zmd_Drink.perk 'zmd_Revive';
    }
}

class zmd_QuickRevive : zmd_Perk {
    Default {
        Inventory.Icon 'qric';
    }
}

class zmd_Revive : zmd_QuickRevive {
	override void detachFromOwner() {
		super.detachFromOwner();
		console.printf("\cf"..self.owner.player.getUserName().."\cj was revived!");
	}
}