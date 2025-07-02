class zmd_Player : DoomPlayer {
    const liveTid = 15;
    const regularHealthMin = 150;
    const juggHealthMin = 0;

    bool fastReload;
    bool doubleFire;

    Default {
        Player.displayName 'Marine (ZMD)';
        Player.startItem 'zmd_Colt';
        Player.startItem 'zmd_ColtAmmo', 32;
        Player.startItem 'NTM_QuickMelee';

        Player.weaponSlot 1, 'zmd_Colt', 'zmd_Magnum';
		Player.weaponSlot 2, 'zmd_Kar98', 'zmd_Carbine';
		Player.weaponSlot 3, 'zmd_M1Garand';
		Player.weaponSlot 4, 'zmd_DoubleBarrelShotgun';
		Player.weaponSlot 5, 'zmd_Type100', 'zmd_Thompson';
		Player.weaponSlot 6, 'zmd_Ppsh';
		Player.weaponSlot 7, 'zmd_Raygun';
    }
}

// class zmd_HintHud : zmd_HudItem {
//     const fadeDelay = 40;
//     const fadeTicks = 5;

//     String message;
//     int ticksLeft;
//     int alpha;

//     override void update() {
//         if (self.ticksLeft != 0) {
//             --self.ticksLeft;
//             self.alpha = self.ticksLeft / double(self.fadeTicks);
//         }
//     }

//     override void draw(zmd_Hud hud, int state, double tickFrac) {
//         if (self.ticksLeft != 0)
//             hud.drawString(hud.hintFont, self.message, (0, -42), hud.di_screen_center_bottom | hud.di_text_align_center, Font.cr_blue, alpha, scale: (1.5, 1.5));
//     }

//     action void setMessage(String message) {
//         invoker.message = message;
//         invoker.ticksLeft = invoker.fadeDelay;
//         invoker.alpha = 1.0;
//     }

//     void clearMessage() {
//         self.ticksLeft = self.fadeTicks;
//     }
// }

// class zmd_AmmoHud : zmd_HudItem {
//     override void draw(zmd_Hud hud, int state, double tickFrac) {
//         let ammo = hud.getCurrentAmmo();
//         let weapon = hud.cplayer.readyWeapon;
//         let zweapon = zmd_Weapon(weapon);
//         if (ammo != null) {
//             if (zweapon && zweapon.Default.activeAmmo > 0)
//                 hud.drawString(hud.defaultFont, zweapon.activeAmmo..'/'..ammo.amount, (hud.right_margin, hud.bottom_margin), hud.di_screen_right_bottom | hud.di_text_align_right, Font.cr_green);
//             else
//                 hud.drawString(hud.defaultFont, ''..ammo.amount, (hud.right_margin, hud.bottom_margin), hud.di_screen_right_bottom | hud.di_text_align_right, Font.cr_green);
//         }
//     }
// }