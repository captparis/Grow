class GWWeap_Skill extends GWWeap_Ranged;

var int HealPoints;

var float ProjectilesPerSecond;

/** Saved partial ammo consumption */
var float	PartialProjectiles;

simulated function AbilityFire() {
	local vector AimOrigin, AimDirection;
	local GWPawn tempTarget;
	local Vector targetLocation;
	local Rotator targetRotation;
	local float HealModifier;

	HealModifier = AmmoCount / float(MaxAmmoCount);
	if(HealModifier == 0) {
		return;
	}
	// define range to use for CalcWeaponFire()
	AimOrigin = InstantFireStartTrace();
	IncrementFlashCount();
	AddAmmo(-AmmoCount);
	foreach VisibleCollidingActors(class'GWPawn', tempTarget, 1000, AimOrigin) {
		//Boost Damage (Call a function in Pawn)
		if(Instigator == tempTarget) {
			continue;
		}
		tempTarget.GetActorEyesViewPoint(targetLocation, targetRotation); //Get Pawn's Location
		if(HealRadiusCollision(AimOrigin, AbilityExtent * HealModifier, AimDirection, tempTarget.HitBoxInfo, targetLocation, Vector(targetRotation))) {
			if(GWPawn(Instigator).IsSameTeamOrSelf(tempTarget)) {
				tempTarget.HealDamage(HealPoints * HealModifier,Instigator.Controller,none);
				tempTarget.IncrementStatusEffect(EFFECT_NEWT_HEAL, Instigator.Controller);
			} else {
				tempTarget.TakeRadiusDamage(Instigator.Controller, 0, 1000, class'DmgType_Fell', 500000 * HealModifier, AimOrigin, true, Instigator);
			}
		}
	}

}

simulated function bool HealRadiusCollision(Vector pos0, Vector rad0, Vector dir0, SPawnHitBoxes box1, Vector pos1, Vector dir1) {
	local Shape Shape0;
	local Shape Shape1;

	Shape0.m_pos = pos0;
	Shape0.m_rot = QuatToCQuat(QuatFromRotator(Rotator(dir0)));
	Shape0.m_radius = vect3d(0,0,0);
	Shape0.m_type = SHAPE_POINT;

	Shape1.m_pos = pos1 + dir1 * box1.Offset;
	Shape1.m_rot = QuatToCQuat(QuatFromRotator(Rotator(dir1)));
	Shape1.m_radius = box1.Radius + vect3d(rad0.X,rad0.X,rad0.X);
	Shape1.m_type = SHAPE_CUBE;

	return CollisionManager.HasCollision(Shape0, Shape1);
}

simulated state SprayFiring {

	/**
	 * Update the beam and handle the effects
	 */
	simulated function Tick(float DeltaTime)
	{
		// Retrace everything and see if there is a new LinkedTo or if something has changed.
		FireProjectiles(ProjectilesPerSecond * DeltaTime);
	}

	function FireProjectiles(float Amount)
	{
		PartialProjectiles += Amount;
		while (PartialProjectiles >= 1.0)
		{
			CustomFire();
			PartialProjectiles -= 1;
		}
	}

	/**
	 * Fires a projectile.
	 * Spawns the projectile, but also increment the flash count for remote client effects.
	 * Network: Local Player and Server
	 */

	simulated function CustomFire()
	{
		local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
		local ImpactInfo	TestImpact;
		local Projectile	SpawnedProjectile;

		// tell remote clients that we fired, to trigger effects
		//IncrementFlashCount();

		if( Role == ROLE_Authority )
		{
			// This is where we would start an instant trace. (what CalcWeaponFire uses)
			StartTrace = Instigator.GetWeaponStartTraceLocation();
			AimDir = Normal(Vector(GetAdjustedAim( StartTrace )) + vect3d(0,0,0.1));

			// this is the location where the projectile is spawned.
			RealStartLoc = GetPhysicalFireStartLoc(AimDir);

			if( StartTrace != RealStartLoc )
			{
				// if projectile is spawned at different location of crosshair,
				// then simulate an instant trace where crosshair is aiming at, Get hit info.
				EndTrace = StartTrace + AimDir * GetTraceRange();
				TestImpact = CalcWeaponFire( StartTrace, EndTrace );

				// Then we realign projectile aim direction to match where the crosshair did hit.
				AimDir = Normal(TestImpact.HitLocation - RealStartLoc);
			}

			// Spawn projectile
			SpawnedProjectile = Spawn(GetProjectileClass(), Self,, StartTrace);
			if( SpawnedProjectile != None && !SpawnedProjectile.bDeleteMe )
			{
				SpawnedProjectile.Init( AimDir );
			}

			// Return it up the line
			return;
		}

		return;
	}
	simulated function BeginState(Name PreviousStateName) {
		local UTPawn POwner;

		RefireCheckTimer();
		TimeWeaponFiring( CurrentFireMode );
		CustomFire();
		IncrementFlashCount();
		if(Role == ROLE_Authority) {
			GWPawn(Instigator).TriggerAnim(ANIM_ATTACK);
		}
		POwner = UTPawn(Instigator);
		if (POwner != None)
		{
			if(SoundGroupClass == none) {
				//`Log(name@Owner);
				SoundGroupClass = class<GWSoundGroup>(GWPawn(Owner).SoundGroupClass);
			}
			POwner.SetWeaponAmbientSound(SoundGroupClass.default.AttackSound);
		}
	}

	simulated function EndState(Name NextStateName)
	{
		local UTPawn POwner;
		POwner = UTPawn(Instigator);
		if (POwner != None)
		{
			POwner.SetWeaponAmbientSound(None);
		}
		ClearTimer('RefireCheckTimer');
		ClearFlashLocation();
		ClearFlashCount();
		PartialProjectiles = 0;
		if(Role == ROLE_Authority)
			GWPawn(Instigator).TriggerAnim(ANIM_NONE);
	}

	simulated function bool IsFiring()
	{
		return true;
	}

	/**
	 * In this weapon, RefireCheckTimer consumes ammo and deals out health/damage.  It's not
	 * concerned with the effects.  They are handled in the tick()
	 */
	simulated function RefireCheckTimer()
	{
		// If weapon should keep on firing, then do not leave state and fire again.
		if( ShouldRefire() )
		{
			return;
		}
		// Otherwise we're done firing, so go back to active state.
		GotoState('Active');
	}
}

defaultproperties
{
	EatExtent=(X=75,Y=25,Z=25)
	AbilityExtent=(X=400)
	WeaponProjectiles(0)=class'Grow.GWProj_Skill'
	AmmoRegenAmount=0
	HealPoints = 50

	FireInterval(1)=2//25
	
	ShotCost(1)=0
	WeaponFireTypes(1)=EWFT_InstantHit

	ShotCost(0)=0
	AmmoCount=0
	WeaponFireTypes(0)=EWFT_Custom
	FiringStatesArray(0)=SprayFiring
	//AbilityAmmoUsePerSecond=8.5

	FireInterval(0)=0.2
	//WeaponFireSnd[0]=SoundCue'Placeholder.NullCue'
	//WeaponFireSnd[1]=SoundCue'Grow_Sounds.attacksoft_Cue'
	ProjectilesPerSecond=20
}
