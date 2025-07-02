class zmd_InventoryManager : Inventory {
	const speed = 0.5;

    bool lastStand, spectating, gameOver, skipHandlePickup, switchWeapon;
    int ticsSinceSwitch;

    Array<class<zmd_Perk> > perks;
    Array<Weapon> weapons;
    class<Weapon> fist, startingWeapon;
    Array<class<Inventory> > startingItems;
    int maxWeaponCount;

	Array<zmd_OverlayItem> overlays;
	zmd_RoundsOverlay roundsOverlay;
	zmd_HintOverlay hintOverlay;
	zmd_PointsOverlay pointsOverlay;
	zmd_PowerupOverlay powerupOverlay;
	zmd_PerkOverlay perkOverlay;
	zmd_ReviveOverlay reviveOverlay;

    bool fastReload;
    bool doubleFire;

    property switchDelay: ticsSinceSwitch;

    Default {
        zmd_InventoryManager.switchDelay 5;
        Inventory.maxAmount 1;
        +Inventory.undroppable
        +Inventory.untossable
        +Inventory.persistentPower
    }

    static zmd_InventoryManager fetchFrom(Actor player) {
        return zmd_InventoryManager(player.findInventory('zmd_InventoryManager'));
    }

	static bool couldPickup(PlayerPawn player, class<Weapon> weaponClass) {
		if (player.findInventory(weaponClass)) {
			return true;
		} else {
			player.giveInventory(weaponClass, 1);
			let weapon = player.findInventory(weaponClass);
			if (weapon != null) {
				weapon.destroy();
				return true;
			}
			return false;
		}
	}

    override void postBeginPlay() {
        super.postBeginPlay();

		self.owner.speed = self.speed;

        let iterator = ThinkerIterator.create('Inventory');
        Thinker thinker;
        while (thinker = iterator.next()) {
            let item = Inventory(thinker);
            if (item != null && item.owner == self.owner && !(item is 'Ammo') && !(item is 'nacht_Intro') && !(item is 'zmd_Points')) {
                self.startingItems.push(item.getClass());
				let weapon = Weapon(thinker);
                if (weapon != null && weapon.owner == self.owner && weapon.ammoType1 == null) {
                    self.fist = weapon.getClass();
                }
            }
        }

		self.roundsOverlay = zmd_RoundsOverlay.create();
		self.hintOverlay = zmd_HintOverlay.create();
		self.pointsOverlay = zmd_PointsOverlay.create();
		self.powerupOverlay = zmd_PowerupOverlay.create();
		self.perkOverlay = zmd_PerkOverlay.create();
		self.reviveOverlay = zmd_ReviveOverlay.create();

		self.overlays.push(self.roundsOverlay);
		self.overlays.push(self.hintOverlay);
		self.overlays.push(self.pointsOverlay);
		self.overlays.push(self.powerupOverlay);
		self.overlays.push(self.perkOverlay);
		self.overlays.push(self.reviveOverlay);

        self.startingWeapon = self.owner.player.readyWeapon.getClass();
        self.weapons.push(self.owner.player.readyWeapon);
        self.maxWeaponCount = 2;
        self.switchWeapon = true;
        self.ticsSinceSwitch = 0;

        let mysteryBoxPool = zmd_MysteryBoxPool.fetch();
        let playerNumber = self.owner.playerNumber();

		self.skipHandlePickup = true;
		let slots = self.owner.player.weapons;
		for (int x = 0; x <= 7; ++x) {
			for (int y = 0; y != slots.slotSize(x); ++y) {
				let weapon = slots.getWeapon(x, y);
				if (weapon != self.fist && zmd_InventoryManager.couldPickup(PlayerPawn(self.owner), weapon)) {
					mysteryBoxPool.add(playerNumber, weapon);
				}
			}
		}
		self.skipHandlePickup = false;
    }

    override bool handlePickup(Inventory item) {
        if (self.skipHandlePickup) {
            return super.handlePickup(item);
        }
        if (item is self.fist) {
            self.owner.addInventory(item);
        } else if (item is 'zmd_Drink') {
            let drink = zmd_Drink(item);
            if (self.fastReload)
                drink.activateFastReload();
        } else if (item is 'zmd_Perk') {
            self.perks.push(item.getClassName());
            self.perkOverlay.add(item);
        } else if (item is 'Weapon' && self.owner.findInventory('zmd_LastStand') == null) {
            let weapon = Weapon(item);
            if (self.atCapacity()) {
                let cweapon = self.owner.player.readyWeapon;
                if (cweapon == null)
                    cweapon = self.owner.player.pendingWeapon;
                self.abandon(cweapon);
                if (cweapon is 'zmd_Weapon')
                    owner.setInventory(cweapon.Default.ammoType1, 0);
                owner.removeInventory(cweapon);
            }
            let zweapon = zmd_Weapon(weapon);
            if (zweapon != null) {
                if (self.fastReload)
                    zweapon.activateFastReload();
                if (self.doubleFire)
                    zweapon.activateDoubleFire();
            }
            self.weapons.push(weapon);
        }
        return super.handlePickup(item);
    }

    override void modifyDamage(int damage, Name damageType, out int newDamage, bool receivedDamage, Actor inflictor, Actor source, int flags) {
        if (receivedDamage && damage >= self.owner.health) {
            newDamage = 0;
            self.handleDown();
        }
    }

    override void tick() {
        super.tick();
        ++self.ticsSinceSwitch;
		foreach (overlay : self.overlays) {
			overlay.update(self);
		}
    }

    void handleDown() {
        self.giveTemp(zmd_LastStandWeaponPool.chooseFor(self.owner));
        let repulsion = zmd_Repulsion(self.owner.findInventory('zmd_Repulsion'));
        if (repulsion != null) {
            repulsion.handler.deactivate();
        }
        if (self.owner.findInventory('zmd_Revive')) {
            self.owner.giveInventory('zmd_LastStand', 1);
            return;
        }
        foreach (player : players) {
            let player = player.mo;
            if (player != null && player != self.owner && player.findInventory('zmd_Revive') == null && player.findInventory('zmd_LastStand') == null && player.findInventory('zmd_Spectate') == null) {
                self.owner.giveInventory('zmd_LastStand', 1);
                return;
            }
        }
        foreach (player : players) {
			let player = player.mo;
            if (player != null) {
                player.takeInventory('zmd_Spectate', 1);
                player.giveInventory('zmd_GameOverSpectate', 1);
            }
        }
        s_startSound("game/gameover", chan_auto);
    }

    void reset() {
        self.owner.clearInventory();
		self.weapons.clear();
        foreach (item : self.startingItems) {
            self.owner.giveInventory(item, 1);
        }
		if (self.owner.countInv('zmd_Points') < 1500) {
			self.owner.setInventory('zmd_Points', 1500);
		}
		self.switchWeapon = true;
		self.owner.a_selectWeapon(self.startingWeapon);
    }

    void giveTemp(class<Weapon> weapon) {
        if (self.owner.findInventory(weapon) == null) {
            self.skipHandlePickup = true;
            self.owner.giveInventory(weapon, 1);
            self.skipHandlePickup = false;
        }
        self.owner.a_selectWeapon(weapon);
    }

    void removeTemp() {
        if (!self.owns(self.owner.player.readyWeapon)) {
            self.owner.player.readyWeapon.destroy();
        }
    }

    void nextWeapon() {
        if (self.weapons.size() > 0 && self.owner.findInventory('zmd_LastStand') == null) {
            let index = self.weapons.find(self.owner.player.readyWeapon);
            if (index == self.weapons.size()) {
                self.owner.a_selectWeapon(self.weapons[0].getClass());
            } else if (index == self.weapons.size() - 1) {
                if (self.fist == null || self.owner.findInventory(self.fist) == null) {
                    self.owner.a_selectWeapon(self.weapons[0].getClass());
                } else {
                    self.owner.a_selectWeapon(self.fist);
                }
            } else {
                self.owner.a_selectWeapon(self.weapons[index + 1].getClass());
            }
        }
    }

    void previousWeapon() {
        if (self.weapons.size() > 0 && self.owner.findInventory('zmd_LastStand') == null) {
            let index = self.weapons.find(self.owner.player.readyWeapon);
            if (index == -1) {
                self.owner.a_selectWeapon(self.weapons[self.maxWeaponCount - 1].getClass());
            } else if (index == 0) {
                if (self.fist == null) {
                    self.owner.a_selectWeapon(self.weapons[self.weapons.size() - 1].getClass());
                } else {
                    self.owner.a_selectWeapon(self.fist);
                }
            } else {
                self.owner.a_selectWeapon(self.weapons[index - 1].getClass());
            }
        }
    }

    void selectWeapon(int index) {
        if (self.owner.findInventory('zmd_LastStand') == null) {
			if (self.fist != null) {
				if (index == 0) {
					self.owner.a_selectWeapon(self.fist);
				} else if (index <= self.weapons.size()) {
					self.owner.a_selectWeapon(self.weapons[index - 1].getClass());
				}
			} else if (index < self.weapons.size()) {
				self.owner.a_selectWeapon(self.weapons[index].getClass());
			}
        }
    }

    bool owns(Weapon weapon) {
        return self.weapons.find(weapon) != self.weapons.size();
    }

    void abandon(Weapon weapon) {
        self.weapons.delete(self.weapons.find(weapon));
    }

    bool atCapacity() {
        return self.weapons.size() == self.maxWeaponCount;
    }

    void fillWeapons() {
        foreach (weapon : self.weapons) {
            let ammoType = getDefaultByType(weapon.getClass()).ammoType1;
            if (ammoType != null) {
                let ammoCount = Inventory(getDefaultByType(ammoType)).maxAmount;
                self.owner.setInventory(ammoType, ammoCount);
            }
        }
    }

    void activateFastReload() {
        self.fastReload = true;
        foreach (weapon : self.weapons) {
            let weapon = zmd_Weapon(weapon);
            if (weapon != null)
                zmd_Weapon(weapon).activateFastReload();
        }
    }

    void deactivateFastReload() {
        self.fastReload = false;
        foreach (weapon : self.weapons) {
            let weapon = zmd_Weapon(weapon);
            if (weapon != null)
                zmd_Weapon(weapon).deactivateFastReload();
        }
    }

    void activateDoubleFire() {
        self.doubleFire = true;
        foreach (weapon : self.weapons) {
            let weapon = zmd_Weapon(weapon);
            if (weapon != null)
                weapon.activateDoubleFire();
        }
    }

    void deactivateDoubleFire() {
        self.doubleFire = false;
        foreach (weapon : self.weapons) {
            let weapon = zmd_Weapon(weapon);
            if (weapon != null)
                weapon.deactivateDoubleFire();
        }
    }

    void clearPerks() {
		self.perkOverlay.clear();
        foreach (perk : self.perks)
            self.owner.takeInventory(perk, 1);
		self.owner.a_setHealth(zmd_Regen(self.owner.findInventory('zmd_Regen')).maxHealth);
        self.perks.clear();
    }
}

class zmd_InventoryGiver : EventHandler {
    static void giveTo(PlayerPawn player) {
        player.changeTid(zmd_Player.liveTid);
        player.giveInventory('zmd_InventoryManager', 1);
        player.setInventory('zmd_Points', 500);
        player.giveInventory('zmd_Regen', 1);
        player.giveInventory('zmd_PickupDropper', 1);
    }

    override void playerEntered(PlayerEvent e) {
		let player = players[e.playerNumber].mo;
		zmd_InventoryGiver.giveTo(player);
		zmd_Overlay.fetch().managers[e.playerNumber] = zmd_InventoryManager.fetchFrom(player);
		EventHandler.sendInterfaceEvent(e.playerNumber, 'addOverlay');

    }

	override void interfaceProcess(ConsoleEvent e) {
        if (e.name == 'addOverlay' && statusbar != null && statusbar.cplayer != null && statusbar.cplayer.mo != null && statusbar is 'zmd_Hud') {
            zmd_Hud(statusbar).overlay = zmd_Overlay.fetch();
		}
    }
}