class zmd_Interactable : Actor abstract {
    Default {
        +special
    }

    override void touch(Actor toucher) {
        let player = PlayerPawn(toucher);
        if (player != null && player.findInventory('zmd_LastStand') == null)
            doTouch(player);
    }

    override bool used(Actor user) {
        let player = PlayerPawn(user);
        if (player != null && player.findInventory('zmd_LastStand') == null && self.bspecial && doUse(player)) {
            zmd_InventoryManager.fetchFrom(player).hintOverlay.reset();
		}
        return false;
    }

    static String costOf(int cost) {
        return '[Cost: '..cost..']';
    }

    abstract void doTouch(PlayerPawn player);
    abstract bool doUse(PlayerPawn player);
}