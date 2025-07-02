class zmd_Drop : CustomInventory {
    Default {
        Inventory.pickupMessage '';
        Inventory.pickupSound 'game/powerup_grab';
        floatBobStrength 0.5;

        +Inventory.alwaysPickup
        +floatBob
        +noGravity
    }

    action void downScale() {
        self.scale /= 1.5;
    }

    action void giveAll(name item, int amount = 1) {
        scriptUtil.giveInventory(null, item, amount);
    }
}

class zmd_Powerup : Powerup {
    Default {
        Powerup.duration 30 * 35;
		+Inventory.unclearable;
    }

    override TextureId getPowerupIcon() {
        return self.altHudIcon;
    }

    override void attachToOwner(Actor owner) {
        super.attachToOwner(owner);
		zmd_InventoryManager.fetchFrom(owner).powerupOverlay.add(self);
    }
}

class zmd_DropPool : EventHandler {
    const dropsPerRound = 4;
    const dropChance = 7;

    Array<class<zmd_Drop> > fullPool;
    Array<class<zmd_Drop> > pool;
    int dropsLeft;

    static zmd_DropPool fetch() {
        return zmd_DropPool(EventHandler.find('zmd_DropPool'));
    }

    override void worldLoaded(WorldEvent e) {
        self.add('zmd_Instakill');
        self.add('zmd_DoublePoints');
        self.add('zmd_MaxAmmo');
        self.add('zmd_Kaboom');
        self.fill();
    }

    override void worldThingDied(WorldEvent e) {
        if (e.thing.bisMonster && e.thing.curSector.damageAmount == 0) {
            let drop = self.choose();
            if (drop != null)
                Actor.spawn(drop, e.thing.pos, allow_replace);
        }
    }

    void add(class<zmd_Drop> drop) {
        self.fullPool.push(drop);
    }

    void fill() {
        self.pool.copy(self.fullPool);
    }

    void handleRoundChange() {
        self.dropsLeft = 4;
    }

    class<zmd_Drop> choose() {
        if (self.dropsLeft != 0 && random[randomSpawning](1, self.dropChance) == 1) {
            --self.dropsLeft;
            let index = random[randomSpawning](0, self.pool.size() - 1);
            let drop = self.pool[index];
            self.pool.delete(index);
            if (self.pool.size() == 0)
                self.fill();
            return drop;
        }
        return null;
    }
}

class zmd_PowerupOverlay : zmd_OverlayItem {
    const offsetDelta = 13;

    Array<zmd_PowerupIcon> icons;

	static zmd_PowerupOverlay create() {
		return new('zmd_PowerupOverlay');
	}

    override void update(zmd_InventoryManager manager) {
        for (let i = 0; i != icons.size(); ++i) {
            let icon = icons[i];
            icon.update(manager);
            if (icon.power == null) {
                icons.delete(i);
                for (let j = 0; j != i; ++j)
                    icons[j].offset += self.offsetDelta;
                for (let j = i; j != icons.size(); ++j)
                    icons[j].offset -= self.offsetDelta;
                --i;
            }
        }
    }

    override void render(RenderEvent e) {
        foreach (icon : self.icons)
            icon.render(e);
    }

    void add(Powerup power) {
        for (int i = 0; i != self.icons.size(); ++i) {
            let icon = self.icons[i];
            if (power.getClass() == icon.power.getClass()) {
                for (int j = 0; j != i; ++j)
                    self.icons[j].offset += self.offsetDelta;
                return;
            }
            icon.offset -= self.offsetDelta;
        }
        if (self.icons.size() == 0) {
            self.icons.push(zmd_PowerupIcon.create(power, 0));
        } else {
            self.icons.push(zmd_PowerupIcon.create(power, self.icons[self.icons.size() - 1].offset + 2 * self.offsetDelta));
		}
	}
}

class zmd_PowerupIcon : zmd_OverlayItem {
	const scale = 0.5;
	const centerOffset = 11;

    Powerup power;
    int offset;
	TextureId texture;

    static zmd_PowerupIcon create(Powerup power, int offset) {
        let icon = new('zmd_PowerupIcon');
        icon.power = power;
        icon.offset = offset;
		icon.texture = power.icon;
        return icon;
    }

    override void update(zmd_InventoryManager manager) {
        if (self.power.effectTics == 1) {
			self.power = null;
		}
    }

    override void render(RenderEvent e) {
        if (self.power && !self.power.isBlinking()) {
            Screen.drawTexture(self.texture, false, zmd_Overlay.centerX - zmd_PowerupIcon.centerOffset + offset, zmd_Overlay.margin, dta_scaleX, zmd_PowerupIcon.scale, dta_scaleY, zmd_PowerupIcon.scale, dta_320x200, true);
		}
    }
}