class GWWeap_Speed extends GWWeap_Melee;

simulated function AbilityFire() {
	local GWPawn P;

	P = GWPawn(Owner);

	P.IncrementStatusEffect(EFFECT_SCAMPER_BOOST, P.Controller);

	SetTimer(AbilityDuration, false, 'AbilityEnd');
}

simulated function AbilityEnd() {
	local GWPawn P;

	P = GWPawn(Owner);
	if(Role == ROLE_Authority)
		GWPawn(Instigator).TriggerAnim(ANIM_NONE);
	P.ClearStatusEffect(EFFECT_SCAMPER_BOOST);
}
simulated function AttackFire() {
	local GWPawn_Speed P;
	
	P = GWPawn_Speed(Owner);
	if (P.Base != none && !P.bLunging) {
		P.SetPhysics(PHYS_Falling);
        P.Velocity.Z = 500;
        P.Velocity += vector(P.Rotation) * 700;
		P.bLunging = true;
		IncrementFlashCount();
    }

}
DefaultProperties
{
	PrimaryExtent=(X=75,Y=25,Z=25)
	EatExtent=(X=75,Y=25,Z=25)

	ShotCost(1)=75
	WeaponFireTypes(1)=EWFT_InstantHit

	AbilityDuration=5
	AbilityMultiplier=2
	InstantHitDamage(0)=30
	FireInterval(0)=0.5
	FireInterval(1)=2//20

	//WeaponFireSnd[0]=SoundCue'Grow_Sounds.attackhigh_Cue'
	//WeaponFireSnd[1]=SoundCue'Grow_Sounds.attackhigh_Cue'
}
