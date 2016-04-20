class GWWeap_Ranged extends GWWeap;

simulated function AttackFire() {
	ProjectileFire();
}

DefaultProperties
{
	WeaponFireTypes(0)=EWFT_Projectile
	WeaponProjectiles(0)=class'Grow.GWProj'
	InstantHitDamageTypes(0)=class'Grow.GWDmgType_Bite'
	CrosshairImage=Texture2D'Grow_HUD.CrosshairTex'
	CrossHairCoordinates=(U=0,V=0,UL=64,VL=64)
}
