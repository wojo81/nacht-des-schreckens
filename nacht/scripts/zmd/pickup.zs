class zmd_Pickup : zmd_Interactable {
    class<Inventory> item;

    static int, int, Vector2 getInfo(readonly<Inventory> item) {
        let state = item.spawnState;
        if (state.getSpriteTexture(0).exists() && state.sprite != 0) {
            return state.sprite, state.frame, item.scale;
        }
        int sprite, frame; Vector2 scale;
        [sprite, frame, scale] = zmd_NullPickup.getInfo();
        return sprite, frame, scale;
    }

    static zmd_Pickup take(Weapon given, Vector3 pos) {
        let self = zmd_Pickup(Actor.spawn('zmd_Pickup', pos, allow_replace));
        self.item = given.getClass();
        self.addInventory(given);
        [self.sprite, self.frame, self.scale] = zmd_Pickup.getInfo(given);
        return self;
    }

    static zmd_Pickup takeFrom(Actor giver, Weapon given) {
        let self = zmd_Pickup.take(given, giver.pos);
        let ammo = given.Default.ammoType1;
        if (ammo != null) {
            self.addInventory(giver.findInventory(ammo));
        }
        return self;
    }

    override void doTouch(PlayerPawn player) {
        let weapon = player.player.readyWeapon;
        let manager = zmd_InventoryManager.fetchFrom(player);
        if (player.findInventory(self.item) == null && (weapon == null || weapon.getClass() != manager.fist) || manager.weapons.size() < manager.maxWeaponCount) {
            manager.hintOverlay.set('[Pickup '..getDefaultByType(self.item).getTag()..']');
        }
    }

    override bool doUse(PlayerPawn player) {
        let weapon = player.player.readyWeapon;
        let manager = zmd_InventoryManager.fetchFrom(player);
        if (player.findInventory(self.item) == null && (weapon == null || weapon.getClass() != manager.fist) || manager.weapons.size() < manager.maxWeaponCount) {
            self.giveTo(player);
            return true;
        }
        return false;
    }

    virtual void giveTo(Actor taker) {
        let taken = Weapon(self.findInventory(self.item));
        let ammo = getDefaultByType((class<Weapon>)(self.item)).ammoType1;
        if (taken != null) {
            zmd_InventoryManager(taker.findInventory('zmd_InventoryManager')).handlePickup(taken);
            taker.addInventory(taken);
            if (ammo != null) {
                taker.addInventory(self.findInventory(ammo));
            }
        } else {
            taker.giveInventory(self.item, 1);
            if (!(self.item is 'zmd_Weapon') && ammo != null) {
                taker.giveInventory(ammo, getDefaultByType(ammo).maxAmount / 3);
            }
        }
        taker.a_selectWeapon((class<Weapon>)(self.item));
        self.destroy();
    }

    States {
    Spawn:
        #### # 2100;
        stop;
    }
}

class zmd_NullPickup : Inventory {
    static int, int, Vector2 getInfo() {
        let self = getDefaultbyType('zmd_NullPickup');
        let state = self.spawnState;
        return state.sprite, state.frame, self.scale;
    }

    States {
    Spawn:
        nill a -1;
        loop;
    }
}

class zmd_PickupDropper : Inventory {
    const cost = 750;

    int ticksSincePress;

    Default {
        Inventory.maxAmount 1;
        +Inventory.undroppable
        +Inventory.untossable
        +Inventory.persistentPower
    }

    override void doEffect() {
        ++self.ticksSincePress;
    }

    void handlePress() {
        if (self.ticksSincePress > 0 && self.ticksSincePress <= 35) {
            self.dropPickup();
        }
        self.ticksSincePress = 0;
    }

    void dropPickup() {
        let player = PlayerPawn(self.owner);
        let weapon = self.owner.player.readyWeapon;

        if (weapon == null)
            return;

        let manager = zmd_InventoryManager.fetchFrom(player);

        if (manager.owns(weapon)) {
            if (zmd_Points.takeFrom(player, self.cost)) {
                manager.abandon(weapon);
                zmd_Pickup.takeFrom(player, weapon);
            }
        } else if (weapon is 'zmd_Drink' && !zmd_Drink(weapon).consumed) {
            if (zmd_Points.takeFrom(player, self.cost)) {
                zmd_Pickup.takeFrom(player, weapon);
            }
        } else if (!(weapon is manager.fist)) {
            zmd_Pickup.takeFrom(player, weapon);
        }
    }
}

class zmd_PickupDropHandler : EventHandler {
    static ui bool isKeyForCommand(int key, String command) {
        Array<int> keys;
        bindings.getAllKeysForCommand(keys, command);
        return keys.find(key) != keys.size();
    }

    override bool inputProcess(InputEvent event) {
        if (event.type != InputEvent.Type_KeyDown) {
            return false;
        }

        if (isKeyForCommand(event.keyScan, 'weapDrop')) {
            EventHandler.sendNetworkEvent('zmd_dropWeapon');
            return true;
        }
        return false;
    }

    override void networkProcess(ConsoleEvent e) {
        if (e.name == 'zmd_dropWeapon') {
            zmd_PickupDropper(players[e.player].mo.findInventory('zmd_PickupDropper')).handlePress();
        }
    }
}