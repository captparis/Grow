class GWWeap_SpeedMax extends GWWeap_Melee;
var bool bExitingCloak;

simulated function AbilityFire() {
	local GWPawn P;

	if(Owner == none) {
		return;
	}

	P = GWPawn(Owner);

	P.IncrementStatusEffect(EFFECT_DART_CLOAK, P.Controller);
	SetTimer(AbilityDuration, false, 'AbilityEnd');
}

simulated function AbilityEnd() {
	local GWPawn P;

	if(Owner == none) {
		return;
	}

	P = GWPawn(Owner);
	P.ClearStatusEffect(EFFECT_DART_CLOAK);

}
simulated function AttackFire()
{
	if(IsTimerActive('AbilityEnd')) {
		bExitingCloak = true;
		ClearTimer('AbilityEnd');
		AbilityEnd();
		InstantHitDamage[0]=95;
	}
	super.AttackFire();
	if(bExitingCloak) {
		InstantHitDamage[0] = default.InstantHitDamage[0];
		bExitingCloak=false;
	}
}
simulated function IncrementFlashCount()
{
	if( Instigator != None && bExitingCloak && CurrentFireMode == 0)
	{
		Instigator.IncrementFlashCount( Self, 6 );
	} else {
		super.IncrementFlashCount();
	}
}
DefaultProperties
{
	PrimaryExtent=(X=100,Y=50,Z=50)
	EatExtent=(X=100,Y=50,Z=50)

	AmmoRegenAmount = 2
	ShotCost(1)=100
	WeaponFireTypes(1)=EWFT_InstantHit
	InstantHitDamage(0)=30
	FireInterval(0)=0.5
	FireInterval(1)=2//30
	AbilityDuration=10

	//WeaponFireSnd[0]=SoundCue'Grow_Sounds.attackhigh_Cue'
	//WeaponFireSnd[1]=SoundCue'Grow_Sounds.attackhigh_Cue'
}