class nacht_Barrel : ExplosiveBarrel {
    States {
    Death:
        BEXP A 5 Bright;
        BEXP B 5 Bright A_Scream;
        BEXP C 5 Bright;
        BEXP D 5 Bright A_Explode(200);
        BEXP E 10 Bright;
        TNT1 A 1050 Bright A_BarrelDestroy;
        stop;
    }
}