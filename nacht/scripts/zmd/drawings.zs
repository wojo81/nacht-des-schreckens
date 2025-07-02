class zmd_Drawing : zmd_Interactable {
    const upgradedAmmoCost = 4500;

    class<Weapon> weapon, upgradedWeapon;

    int weaponCost;
    int ammoCost;

    String weaponMessage;
    String ammoMessage;
    String upgradedAmmoMessage;

    property weapon: weapon;
    property cost: weaponCost;

    Default {
        +wallSprite;
        +noGravity;
    }

    override void beginPlay() {
        super.beginPlay();

        self.upgradedWeapon = 'Upgraded'..getDefaultByType(self.weapon).getClassName();
        self.ammoCost = self.weaponCost / 2;

        self.weaponMessage = self.costOf(weaponCost);
        self.ammoMessage = self.costOf(ammoCost);
        self.upgradedAmmoMessage = self.costOf(upgradedAmmoCost);
    }

    override void doTouch(PlayerPawn player) {
		let manager = zmd_InventoryManager.fetchFrom(player);
        if (player.findInventory(self.weapon)) {
			manager.hintOverlay.set(self.ammoMessage);
		} else if (player.findInventory(self.upgradedWeapon)) {
            manager.hintOverlay.set(self.upgradedAmmoMessage);
		} else if ((player.player.readyWeapon == null || player.player.readyWeapon.getClass() != manager.fist) || manager.weapons.size() < manager.maxWeaponCount) {
            manager.hintOverlay.set(self.weaponMessage);
		}
    }

    override bool doUse(PlayerPawn player) {
		let manager = zmd_InventoryManager.fetchFrom(player);
        if (player.countInv(self.weapon) != 0) {
            if (zmd_Points.takeFrom(player, ammoCost) && player.giveInventory(getDefaultByType(self.weapon).ammoType1, 999))
                player.a_startSound("game/purchase");
        } else if (player.countInv(self.upgradedWeapon) != 0) {
            if (zmd_Points.takeFrom(player, self.upgradedAmmoCost) && player.giveInventory(getDefaultByType(self.upgradedWeapon).ammoType1, 999))
                player.a_startSound("game/purchase");
        } else if (((player.player.readyWeapon == null || player.player.readyWeapon.getClass() != manager.fist) || manager.weapons.size() < manager.maxWeaponCount) && zmd_Points.takeFrom(player, self.weaponCost) && player.giveInventory(self.weapon, 1)) {
            player.a_selectWeapon(self.weapon);
            player.a_startSound("game/purchase");
        } else
            return false;
        return true;
    }
}

class MinigunDrawing : zmd_Drawing {
    Default {
        zmd_Drawing.weapon 'zmd_M1Garand';
        zmd_Drawing.cost 1200;
    }

    States {
    Spawn:
        mink a -1 bright;
        loop;
    }
}

class Kar98Drawing : zmd_Drawing {
    Default {
        zmd_Drawing.weapon 'zmd_Kar98';
        zmd_Drawing.cost 500;
    }

    States {
    Spawn:
        k98d a -1 bright;
        loop;
    }
}

class CarbineDrawing : zmd_Drawing {
    Default {
        zmd_Drawing.weapon 'zmd_Carbine';
        zmd_Drawing.cost 500;
    }

    States {
    Spawn:
        m1cd a -1 bright;
        loop;
    }
}

class ThompsonDrawing : zmd_Drawing {
    Default {
        zmd_Drawing.weapon 'zmd_Thompson';
        zmd_Drawing.cost 1000;
    }

    States {
    Spawn:
        tmpd a -1 bright;
        loop;
    }
}