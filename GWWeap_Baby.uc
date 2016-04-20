class GWWeap_Baby extends GWWeap_Melee;

simulated function AbilityFire() {
	local GWPawn P;

	P = GWPawn(Owner);
	SetTimer(5, false, 'AbilityEnd');
	P.TriggerAnim(ANIM_ABILITY_START);
	P.IncrementStatusEffect(EFFECT_NOM_FRENZY, Instigator.Controller);
	P.GotoState('PlayerAbility');
	P.Controller.GotoState('PlayerAbility');
	// Block player movement
}

simulated function AbilityEnd() {
	local GWPawn P;

	P = GWPawn(Owner);
	P.TriggerAnim(ANIM_ABILITY_END);
	P.Controller.GotoNormalState();
	P.ClearStatusEffect(EFFECT_NOM_FRENZY);
	P.GotoState('');
}

DefaultProperties
{
	PrimaryExtent=(X=75,Y=25,Z=25)
	EatExtent=(X=75,Y=25,Z=25)
	AmmoCount=0

	InstantHitDamage(0)= 20
	FireInterval(0)= 1.2
	InstantHitMomentum(0)=50000

	ShotCost(1)=100

	//WeaponFireSnd[0]=SoundCue'Grow_Character_Audio.nomsoundcues.NomAttackSoundCue'
	//WeaponFireSnd[1]=SoundCue'Grow_Character_Audio.nomsoundcues.NomAttackSoundCue'
}
