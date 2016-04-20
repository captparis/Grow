class GWWeap_Power extends GWWeap_Melee;

var ParticleSystemComponent AbilityParticle;
var int ComboNumber;
var float LastComboTime;

simulated function AbilityFire() {
	if(ComboNumber > 0 && ComboNumber < 4) 
	{
		if(LastComboTime + 0.3 < WorldInfo.TimeSeconds && WorldInfo.TimeSeconds < LastComboTime + 1.5) 
		{
			switch (ComboNumber) 
			{
				case 1:
				case 2:
					ProjectileFire();
					ComboNumber++;
					GWPawn_Power(Instigator).ComboNumber = ComboNumber;
					LastComboTime = WorldInfo.TimeSeconds;
					return;
					break;
				case 3:
					PulseFire();
					ComboNumber = 0;
					GWPawn_Power(Instigator).ComboNumber = ComboNumber;
					return;
					break;
			}
		}
	}
	ComboNumber = 0;
	GWPawn_Power(Instigator).ComboNumber = ComboNumber;
	ProjectileFire();
	ComboNumber++;
	LastComboTime = WorldInfo.TimeSeconds;
}

simulated function PulseFire() {
	local Vector StartFire;

	// define range to use for CalcWeaponFire()
	StartFire = InstantFireStartTrace();
	IncrementFlashCount();

	HurtRadius(60, AbilityExtent.X, class'GWDmgType_Bark', 85000, StartFire,,GWPawn(Owner).Controller,true);
}
function class<Projectile> GetProjectileClass()
{
	if(CurrentFireMode != FIREMODE_ABILITY) {
		return super.GetProjectileClass();
	}
	switch (ComboNumber) {
	case 1:
		return class'GWProj_Power_2nd';
		break;
	case 2:
		return class'GWProj_Power_3rd';
		break;
	default:
		return class'GWProj_Power_1st';
	}
}
simulated function DrawAbilityTargets(HUD H) {
	local vector StartTrace;
	local GWPawn targetPawn;
	local Vector targetEyeLoc;
	local Rotator targetEyeRot;

	// define range to use for CalcWeaponFire()
	StartTrace = InstantFireStartTrace();

	foreach VisibleCollidingActors(class'GWPawn', targetPawn, AbilityExtent.X, StartTrace) {
		if(GWPawn(Owner).IsSameTeamOrSelf(targetPawn)) 
		{
			continue;
		}
		targetPawn.GetActorEyesViewPoint(targetEyeLoc, targetEyeRot); //Get Pawn's Location
		H.Draw3DLine(StartTrace, targetEyeLoc, MakeColor(0, 255, 0));
	}
}
simulated function AttackFire() {
	local GWPawn_Power P;
	
	super.AttackFire();
	P = GWPawn_Power(Owner);
	if (P.Physics == PHYS_Walking) {
		P.SetPhysics(PHYS_Falling);
        P.Velocity.Z = 250;
        P.Velocity += vector(P.Rotation) * 400;
    }
}

simulated function bool HurtRadius
(
	float				BaseDamage,
	float				DamageRadius,
	class<DamageType>	DamageType,
	float				Momentum,
	vector				HurtOrigin,
	optional Actor		IgnoredActor,
	optional Controller InstigatedByController = Instigator != None ? Instigator.Controller : None,
	optional bool       bDoFullDamage
)
{
	local Actor	Victim;
	local bool bCausedDamage;
	local TraceHitInfo HitInfo;
	local StaticMeshComponent HitComponent;
	local KActorFromStatic NewKActor;

	// Prevent HurtRadius() from being reentrant.
	if ( bHurtEntry )
		return false;

	bHurtEntry = true;
	bCausedDamage = false;
	foreach VisibleCollidingActors( class'Actor', Victim, DamageRadius, HurtOrigin,,,,, HitInfo )
	{
		if(Victim == Owner) {
			continue;
		}
		if ( Victim.bWorldGeometry )
		{
			// check if it can become dynamic
			// @TODO note that if using StaticMeshCollectionActor (e.g. on Consoles), only one component is returned.  Would need to do additional octree radius check to find more components, if desired
			HitComponent = StaticMeshComponent(HitInfo.HitComponent);
			if ( (HitComponent != None) && HitComponent.CanBecomeDynamic() )
			{
				NewKActor = class'KActorFromStatic'.Static.MakeDynamic(HitComponent);
				if ( NewKActor != None )
				{
					Victim = NewKActor;
				}
			}
		}
		if ( !Victim.bWorldGeometry && (Victim != self) && (Victim != IgnoredActor) && (Victim.bCanBeDamaged || Victim.bProjTarget) )
		{
			Victim.TakeRadiusDamage(InstigatedByController, BaseDamage, DamageRadius, DamageType, Momentum, HurtOrigin, bDoFullDamage, self);
			bCausedDamage = bCausedDamage || Victim.bProjTarget;
		}
	}
	bHurtEntry = false;
	return bCausedDamage;
}
DefaultProperties
{
	ComboNumber=0
	PrimaryExtent=(X=100,Y=37.5,Z=37.5)
	EatExtent=(X=100,Y=37.5,Z=37.5)
	AbilityExtent=(X=200)
	AbilityTickRate=0.5
	AbilityDuration=2.0
	ShouldFireOnRelease(1)=0
	
	ShotCost(1)=20
	InstantHitDamage(1)=5
	InstantHitDamage(0)=30
	FireInterval(0)=.5
	FireInterval(1)=1//20
	WeaponKeepFiring(1)=0
	InstantHitDamageTypes(1)=class'GWDmgType_Bark'
	WeaponFireTypes(1)=EWFT_InstantHit
	//WeaponFireSnd[0]=SoundCue'Grow_Character_Audio.growlsoundcues.GrowlAttackSoundCue'
	//WeaponFireSnd[1]=SoundCue'Grow_Character_Audio.growlsoundcues.GrowlSpecialSoundCue'
	//SoundGroupClass=class'GWSoundGroup_Power'
}