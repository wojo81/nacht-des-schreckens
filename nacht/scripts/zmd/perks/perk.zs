class zmd_PerkMachine : zmd_Interactable {
    class<zmd_Drink> drink;
    int cost;

    property cost: cost;
    property drink: drink;

    Default {
        radius 20;
        height 80;

        +solid
        +special
        +wallSprite
    }

    override void doTouch(PlayerPawn player) {
        if (player.countInv(self.drink) == 0 && player.findInventory(getDefaultByType(self.drink).perk) == null) {
            zmd_InventoryManager.fetchFrom(player).hintOverlay.set(self.costOf(self.cost));
		}
    }

    override bool doUse(PlayerPawn player) {
        if (player.findInventory(self.drink) == null && player.findInventory(getDefaultByType(self.drink).perk) == null && zmd_Points.takeFrom(player, self.cost)) {
            player.giveInventory(self.drink, 1);
            self.a_startSound("game/purchase");
            player.a_selectWeapon(self.drink);
            return true;
        }
        return false;
    }
}

class zmd_Perk : Inventory {
    Default {
        Inventory.maxAmount 1;
    }
}

class zmd_DrinkAmmo : Ammo {
    Default {
        Inventory.maxAmount 1;
    }
}

class zmd_Drink : zmd_Weapon {
    readonly class<zmd_Perk> perk;
    int sprites[3];
    bool consumed;

    property perk: perk;

    Default {
        Weapon.ammoType 'zmd_DrinkAmmo';
        Weapon.ammoGive 1;
        zmd_Weapon.reloadFrameRate 2;
    }

    override void beginPlay() {
        let state = self.findState('Sprites');
        self.sprites[0] = state.sprite;
        self.sprites[1] = state.nextState.sprite;
        self.sprites[2] = state.nextState.nextState.sprite;
    }

    override void attachToOwner(Actor owner) {
        super.attachToOwner(owner);
        zmd_InventoryManager.fetchFrom(owner).switchWeapon = false;
    }

    override void detachFromOwner() {
        let inventoryManager = zmd_InventoryManager.fetchFrom(self.owner);
        if (inventoryManager != null) {
            inventoryManager.switchWeapon = true;
        }
        super.detachFromOwner();
    }

    action void loadSprites(int index) {
        self.player.findPSprite(psp_weapon).sprite = invoker.sprites[index];
    }

    action void rfr() {
        a_weaponReady();
        fr();
    }

    action void consume() {
        if (!invoker.consumed) {
            self.a_startSound("game/swallow2");
            self.giveInventory(invoker.perk, 1);
            invoker.consumed = true;
        }
    }

    action void discard() {
        self.takeInventory(invoker.ammoType1, 1);
        self.takeInventory(invoker.getClass(), 1);
    }

    action void throw() {
        Actor bottle, _;
        [bottle, _] = shootProjectile('zmd_Bottle');
        if (bottle != null) {
            bottle.sprite = invoker.Default.spawnState.sprite;
        }
    }

    States {
    Ready:
        tnt1 a 0 loadSprites(0);
        #### abcdefghijklmnopqrstuvwxyz 2 rfr;
        #### a 0 loadSprites(1);
        #### abcdefghi 2 rfr;
        #### a 0 consume;
        #### jklmnopqrstuvwxyz 2 rfr;
        #### a 0 loadSprites(2);
        #### ab 2 rfr;
        tnt1 a 0 a_startSound("game/bottle_break");
        goto Deselect;
    Select:
        tnt1 a 0 a_raise;
        wait;
    Deselect:
        tnt1 a 0 discard;
        stop;
    Fire:
        tnt1 a 0 throw;
        goto Deselect;
    }
}

class zmd_Bottle : Rocket {
    Default {
        scale 0.5;
        health 1;
        radius 5;
        height 5;
        speed 25;
        damage 300;
        damageType 'Bottle';
        seeSound '';
        deathSound 'game/bottle_break';
        gravity 0.5;

        +flatSprite
        -rocketTrail
        -nogravity
    }

    action void spin() {
        invoker.pitch += 25;
    }

    States {
    Spawn:
        #### a 1 spin;
        loop;
    Death:
        stop;
    }
}

class zmd_PerkOverlay : zmd_OverlayItem {
    const offsetDelta = 13;

    Array<zmd_PerkIcon> icons;
    int offset;

	static zmd_PerkOverlay create() {
		let self = new('zmd_PerkOverlay');
		return self;
	}

	override void update(zmd_InventoryManager manager) {}

    override void render(RenderEvent e) {
        foreach (icon : self.icons)
            icon.render(e);
    }

    void add(Inventory perk) {
        let perkIcon = new('zmd_PerkIcon');
        perkIcon.perk = perk;
        perkIcon.offsetX = self.offset;
		perkIcon.texture = perk.icon;
        self.icons.push(perkIcon);
        self.offset += self.offsetDelta;
    }

    void clear() {
        self.icons.resize(0);
        self.offset = 0;
    }
}

class zmd_PerkIcon : zmd_OverlayItem {
	const offsetY = zmd_Overlay.margin + 17;
	const scale = 0.25;

    Inventory perk;
    int offsetX;
	TextureId texture;

	override void update(zmd_InventoryManager manager) {}

    override void render(RenderEvent e) {
        Screen.drawTexture(self.texture, false, self.offsetX + zmd_Overlay.margin, zmd_PerkIcon.offsetY, dta_scaleX, zmd_PerkIcon.scale, dta_scaleY, zmd_PerkIcon.scale, dta_320x200, true);
    }
}