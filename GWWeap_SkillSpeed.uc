class GWWeap_SkillSpeed extends GWWeap_Ranged;

simulated function AbilityFire() {
	ProjectileFire();
}

DefaultProperties
{
	EatExtent=(X=75,Y=25,Z=25)
	WeaponProjectiles(0)=class'Grow.GWProj_SkillSpeed'
	WeaponProjectiles(1)=class'Grow.GWProj_SkillSpeedSpecial'

	FireInterval(0)=1.6
	FireInterval(1)=3
	ShotCost(1)=50
	WeaponFireTypes(1)=EWFT_Projectile
	//WeaponFireSnd[0]=SoundCue'Grow_Sounds.attackhigh_Cue'
	//WeaponFireSnd[1]=SoundCue'Grow_Sounds.attackhigh_Cue'
}