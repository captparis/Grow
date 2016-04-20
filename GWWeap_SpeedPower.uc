class GWWeap_SpeedPower extends GWWeap_Melee;

struct Speed {
	var int GroundSpeed;
	var int AirSpeed;
	var int WaterSpeed;
	var int LadderSpeed;
	var int AccelRate;
};

var Speed OldSpeed;

simulated function AbilityFire() {
	local GWPawn P;

	P = GWPawn(Owner);

	if(IsTimerActive('AbilityEnd')) {
		return;
	}
	P.IncrementStatusEffect(EFFECT_POKEY_CHARGE, P.Controller);
	P.Controller.GotoState('PlayerAbility');
	P.GotoState('PlayerAbility');
	SetTimer(AbilityDuration, false, 'AbilityEnd');
}

simulated function AbilityEnd() {
	local GWPawn P;

	P = GWPawn(Owner);

	ClearTimer('AbilityEnd');

	P.ClearStatusEffect(EFFECT_POKEY_CHARGE);
	P.TriggerAnim(ANIM_NONE);
	P.Controller.GotoNormalState();
	P.GotoState('');
}

DefaultProperties
{
	PrimaryExtent=(X=200,Y=100,Z=100)
	EatExtent=(X=200,Y=100,Z=100)
	InstantHitDamage(0)=50
	FireInterval(0)=1
	FireInterval(1)=2//25
	ShotCost(1)=100
	WeaponFireTypes(1)=EWFT_InstantHit
	AmmoRegenAmount=8
	AbilityDuration=4
	AbilityMultiplier=2

	//WeaponFireSnd[0]=SoundCue'Grow_Sounds.attacklow_Cue'
	//WeaponFireSnd[1]=SoundCue'Grow_Sounds.attacklow_Cue'
}