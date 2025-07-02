class zmd_Door : zmd_Interactable {
    meta int cost;

    property cost: cost;

    Default {
        radius 20;
        height 150;
        zmd_Door.cost 1000;

        +solid;
        +wallSprite;
    }

    override void doTouch(PlayerPawn player) {
		zmd_InventoryManager.fetchFrom(player).hintOverlay.set(self.costOf(cost));
    }

    override bool doUse(PlayerPawn player) {
        if (zmd_Points.takeFrom(player, self.cost)) {
            player.a_startSound("game/purchase");
            foreach (tid : self.args)
                zmd_Spawning.addSpawners(tid);
            self.destroy();
            return true;
        }
        return false;
    }
}

class zmd_HelpDoorBack : Actor {
    Default {
        +wallSprite
    }

    States {
    Spawn:
        door b 1;
        loop;
    }
}

class zmd_HelpDoor : zmd_Door {
    Actor back;

    Default {
        radius 16;
    }

    override void postBeginPlay() {
        let offset = -Actor.angleToVector(6);
        self.back = Actor.spawn('zmd_HelpDoorBack', self.pos + (offset.x, offset.y, 0));
    }

    override bool doUse(PlayerPawn player) {
        if (super.doUse(player)) {
            self.back.destroy();
            return true;
        }
        return false;
    }

    States {
    Spawn:
        door a 1;
        loop;
    }
}

class zmd_Boxes : zmd_Door {
    States {
    Spawn:
        boxs a 1;
        loop;
    }
}