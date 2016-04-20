class GWWeap extends UTWeapon
	abstract
	dependson(GWConstants);

var GWCollisionManager CollisionManager;

/*
 * Range & Radius of Eatting
 */
var Vector EatExtent;
/*
 * Range & Radius of Primary Attack
 */
var Vector PrimaryExtent;
/*
 * Range & Radius of Abilities
 */
var Vector AbilityExtent;

var float AbilityDuration; // How long the ability lasts for
var float AbilityTickRate;
var float AbilityMultiplier; // Multipler for abilities such as speed boost
var Array<float> LastWeaponFire;
var Array<float> DelayWeaponFire;
var Array<byte> WeaponKeepFiring;
var class<GWSoundGroup> SoundGroupClass; 
var int EatenFoodHealth;
var float LargestHitBox;
var bool SpewFireEnded;
var float AmmoRegenAmount;

/*
 * Spew Vars
 */
var float FoodConsumedPerSecond;
var float PartialFoodConsumed;
var float FoodConsumed;

/**
 * --------------
 * FireAmmunition
 * --------------
 * Triggers the chain of events that cause the weapon to fire.
 * Triggers the firing animations
 */
simulated function FireAmmunition()
{
	LastWeaponFire[CurrentFireMode] = WorldInfo.TimeSeconds;
	switch(CurrentFireMode) {
	case FIREMODE_ATTACK:
		GWPawn(Instigator).TriggerAnim(ANIM_ATTACK);
		break;
	case FIREMODE_ABILITY:
		GWPawn(Instigator).TriggerAnim(ANIM_ABILITY_START);
		break;
	case FIREMODE_EAT:
		GWPawn(Instigator).TriggerAnim(ANIM_EAT);
		break;
	case FIREMODE_CHEW:
		GWPawn(Instigator).TriggerAnim(ANIM_CHEW);
		break;
	case FIREMODE_SPIT:
		GWPawn(Instigator).TriggerAnim(ANIM_SPIT);
		break;
	case FIREMODE_SPEW:
		//GWPawn(Instigator).TriggerAnim(ANIM_SPIT);
		break;
	}
	PlayFiringSound();
	if(DelayWeaponFire[CurrentFireMode] > 0) {
		SetTimer(DelayWeaponFire[CurrentFireMode], false, 'FireWeapon');
	} else {
		FireWeapon();
	}

	UTInventoryManager(InvManager).OwnerEvent('FiredWeapon');
}

/**
 * FireAmmunition: Perform all logic associated with firing a shot
 * - Fires ammunition (instant hit or spawn projectile)
 * - Consumes ammunition
 *
 * Network: LocalPlayer and Server
 */

simulated function FireWeapon()
{
	// Use ammunition to fire
	ConsumeAmmo( CurrentFireMode );

	// Handle the different fire types
	switch(CurrentFireMode) {
	case FIREMODE_ATTACK:
		AttackFire();
		break;
	case FIREMODE_ABILITY:
		AbilityFire();
		break;
	case FIREMODE_EAT:
		EatFire();
		break;
	case FIREMODE_CHEW:
//		ChewFire();
		break;
	case FIREMODE_SPIT:
//		SpitFire();
		break;
	case FIREMODE_SPEW:
		SpewFire();
		break;
	}

	NotifyWeaponFired( CurrentFireMode );
}

simulated function AttackFire() {}
simulated function AbilityFire() {}
simulated function AbilityEnd() {}

simulated function EatFire() {
	local GWFoodActor Target;
	local GWPawn P;
	local GWFoodCarrier Inv;

	IncrementFlashCount();
	if(Role != ROLE_Authority)
		return;

	Target = GWFoodActor(GetClosestTarget(class'GWFoodActor', EatExtent));
	if(Target != none) {
		P = GWPawn(Owner);
		if(Role == ROLE_Authority) {
			Inv = GWFoodCarrier(P.CreateInventory(class'GWFoodCarrier', false));
			Inv.AmmoCount = Target.FoodInfo.Size;
			if(Inv != none) {
				P.SetActiveWeapon(Inv);
			}
		}
		P.CurrentEatenFoodMesh.SetScale(1);
		P.CurrentEatenFoodType = Target.FoodType;
		P.ForceNetRelevant();
		P.bNetDirty = true;
		P.ClientSetFood(Target.FoodType, false);
		Target.Destroy();
	}
}
simulated function SpewFire() {}
simulated function bool StillFiring(byte FireMode)
{
	if(!bool(WeaponKeepFiring[FireMode])) {
		StopFire(FireMode);
	}
	return ( PendingFire(FireMode));
}
simulated event PostBeginPlay() {
	local GWWeap tempWep;
	super.PostBeginPlay();
	if (Role == ROLE_Authority)
	{
		if(AmmoCount < MaxAmmoCount && AmmoRegenAmount > 0) {
			SetTimer(1.5, false, 'RechargeAmmo');
		}
	}
	if(SoundGroupClass == none) {
		//`Log(name@Owner);
		SoundGroupClass = class<GWSoundGroup>(GWPawn(Owner).SoundGroupClass);
	}
	if(CollisionManager == none) {
		foreach AllActors(class'GWWeap', tempWep) {
			if(tempWep.CollisionManager != none) {
				CollisionManager = tempWep.CollisionManager;
				return;
			}
		}
		CollisionManager = new class'GWCollisionManager';
	}
}


simulated function Actor GetClosestTarget(class<actor> BaseClass, Vector Extent, optional Actor IgnoredActor) {
	local vector AimOrigin, AimDirection;
	local Actor tempTarget;
	local Actor closestTarget;
	local float closestTargetDistance;
	local Vector targetLocation;
	local Rotator targetRotation;
	local float DistFromAim;

	AimOrigin = InstantFireStartTrace();
	AimDirection = InstantFireEndTrace(AimOrigin);

	AimDirection = Normal(AimDirection - AimOrigin); // Magnitude of RealEndTrace
	
	foreach VisibleActors(BaseClass, tempTarget, Extent.X + 2 * LargestHitBox + 5000, AimOrigin) {
		if((IgnoredActor != none) && (tempTarget == IgnoredActor)) {
			continue;
		}
		if(GWPawn(tempTarget) != none) {
			if(GWPawn(Owner).IsSameTeamOrSelf(GWPawn(tempTarget))) {
				continue;
			}
		}
		tempTarget.GetActorEyesViewPoint(targetLocation, targetRotation); //Get Pawn's Location

		if(EatFoodCollision(AimOrigin, Extent, AimDirection, targetLocation, targetRotation)) {
			DistFromAim = VSize(targetLocation - AimOrigin);
			if(DistFromAim < closestTargetDistance || closestTarget == none) {
				closestTarget = tempTarget;
				closestTargetDistance = DistFromAim;
			}
		}
	}
	return closestTarget;
}

simulated function PlayFiringSound()
{
	if(SoundGroupClass == none) {
		//`Log(name@Owner);
		SoundGroupClass = class<GWSoundGroup>(GWPawn(Owner).SoundGroupClass);
	}
	switch(CurrentFireMode) {
	case FIREMODE_ATTACK:
		SoundGroupClass.static.PlayAttackSound(GWPawn(Owner));
		break;
	case FIREMODE_ABILITY:
		SoundGroupClass.static.PlayAbilitySound(GWPawn(Owner));
		break;
	case FIREMODE_EAT:
		SoundGroupClass.static.PlayEatSound(GWPawn(Owner));
		break;
	case FIREMODE_CHEW:
		SoundGroupClass.static.PlayChewSound(GWPawn(Owner));
		break;
//	case FIREMODE_SPEW:
//		SoundGroupClass.static.PlayAttackSound(GWPawn(Owner));
//		break;
	case FIREMODE_SPIT:
		//SoundGroupClass.static.PlaySpitSound(GWPawn(Owner));
		break;
	}
	MakeNoise(1.0);
}

simulated event float GetPowerPerc()
{
	return FClamp(AmmoCount / float(MaxAmmoCount), 0, 1);
}

simulated function float PointInCylinderTest( Vector pt1, Vector pt2, float lengthsq, float radius_sq, Vector testpt ) {
	local float dx, dy, dz;	// vector d  from line segment point 1 to point 2
	local float pdx, pdy, pdz;	// vector pd from point 1 to test point
	local float dot, dsq;

	dx = pt2.x;
	dy = pt2.y;
	dz = pt2.z;

	pdx = testpt.x - pt1.x;		// vector from pt1 to test point.
	pdy = testpt.y - pt1.y;
	pdz = testpt.z - pt1.z;

	// Dot the d and pd vectors to see if point lies behind the 
	// cylinder cap at pt1.x, pt1.y, pt1.z

	dot = pdx * dx + pdy * dy + pdz * dz;

	// If dot is less than zero the point is behind the pt1 cap.
	// If greater than the cylinder axis line segment length squared
	// then the point is outside the other end cap at pt2.

	if( dot < 0.0f || dot > lengthsq )
	{
		return( -1.0f );
	}
	else 
	{
		// Point lies within the parallel caps, so find
		// distance squared from point to line, using the fact that sin^2 + cos^2 = 1
		// the dot = cos() * |d||pd|, and cross*cross = sin^2 * |d|^2 * |pd|^2
		// Carefull: '*' means mult for scalars and dotproduct for vectors
		// In short, where dist is pt distance to cyl axis: 
		// dist = sin( pd to d ) * |pd|
		// distsq = dsq = (1 - cos^2( pd to d)) * |pd|^2
		// dsq = ( 1 - (pd * d)^2 / (|pd|^2 * |d|^2) ) * |pd|^2
		// dsq = pd * pd - dot * dot / lengthsq
		//  where lengthsq is d*d or |d|^2 that is passed into this function 

		// distance squared to the cylinder axis:

		dsq = (pdx*pdx + pdy*pdy + pdz*pdz) - dot*dot/lengthsq;

		if( dsq > radius_sq )
		{
			return( -1.0f );
		}
		else
		{
			return( dsq );		// return distance squared to axis
		}
	}
}
/*
 * HUD Target Debug
 */

simulated function DrawTargets(HUD H) {
	local vector AimOrigin, AimDirection;
	local GWPawn tempTarget;
	local Vector targetLocation;
	local Rotator targetRotation;
	local Color Red;

	AimOrigin = InstantFireStartTrace();
	AimDirection = InstantFireEndTrace(AimOrigin);

	AimDirection = Normal(AimDirection - AimOrigin); // Magnitude of RealEndTrace
	Red = MakeColor(255, 0, 0);
	foreach VisibleActors(class'GWPawn', tempTarget, PrimaryExtent.X + 2 * LargestHitBox, AimOrigin) {
		if(GWPawn(Owner).IsSameTeamOrSelf(tempTarget)) {
			continue;
		}
		tempTarget.GetActorEyesViewPoint(targetLocation, targetRotation); //Get Pawn's Location
		if(PrimaryAttackCollision(AimOrigin, PrimaryExtent, AimDirection, tempTarget.HitBoxInfo, targetLocation, Vector(targetRotation))) {
			H.Draw3DLine(AimOrigin, targetLocation, Red);
		}
	}
}
/*
 * Parameter Order
 * Attack Origin, Attack Radius, Attack Direction, Target Form, Target Origin, Target Facing
 * */
simulated function bool PrimaryAttackCollision(Vector pos0, Vector rad0, Vector dir0, SPawnHitBoxes box1, Vector pos1, Vector dir1) {
	local Shape Shape0;
	local Shape Shape1;

	Shape0.m_pos = pos0 + rad0.X * dir0;
	Shape0.m_rot = QuatToCQuat(QuatFromRotator(Rotator(dir0)));
	Shape0.m_radius = rad0;
	Shape0.m_type = SHAPE_CUBE;

	Shape1.m_pos = pos1 + dir1 * box1.Offset;
	Shape1.m_rot = QuatToCQuat(QuatFromRotator(Rotator(dir1)));
	Shape1.m_radius = box1.Radius;
	Shape1.m_type = SHAPE_CUBE;

	return CollisionManager.HasCollision(Shape0, Shape1);
}
simulated function bool EatFoodCollision(Vector pos0, Vector rad0, Vector dir0, Vector pos1, Rotator rot1) {
	local Shape Shape0;
	local Shape Shape1;

	Shape0.m_pos = pos0 + rad0.X * dir0;
	Shape0.m_rot = QuatToCQuat(QuatFromRotator(Rotator(dir0)));
	Shape0.m_radius = rad0 + vect3d(25,25,25);
	Shape0.m_type = SHAPE_CUBE;

	Shape1.m_pos = pos1;
	Shape1.m_rot = QuatToCQuat(QuatFromRotator(rot1));;
	Shape1.m_radius = vect3d(0,0,0);
	Shape1.m_type = SHAPE_POINT;

	return CollisionManager.HasCollision(Shape0, Shape1);
}
simulated function DrawFoodTargets(HUD H) {
	local vector AimOrigin, AimDirection;
	local GWFoodActor tempTarget;
	local Vector targetLocation;
	local Rotator targetRotation;
	local Color Red;

	AimOrigin = InstantFireStartTrace();
	AimDirection = InstantFireEndTrace(AimOrigin);

	AimDirection = Normal(AimDirection - AimOrigin); // Magnitude of RealEndTrace

	Red = MakeColor(0, 0, 0);
	
	foreach VisibleActors(class'GWFoodActor', tempTarget, EatExtent.X + 2 * LargestHitBox + 5000, AimOrigin) {
		tempTarget.GetActorEyesViewPoint(targetLocation, targetRotation); //Get Pawn's Location

		if(EatFoodCollision(AimOrigin, EatExtent, AimDirection, targetLocation, targetRotation)) {
			H.Draw3DLine(AimOrigin, targetLocation, Red);
		}
	}
}
simulated function DrawAbilityTargets(HUD H) {}

function ConsumeAmmo( byte FireModeNum )
{
	super.ConsumeAmmo(FireModeNum);
	if (Role == ROLE_Authority)
	{
		if(AmmoCount < MaxAmmoCount && AmmoRegenAmount > 0) {
			SetTimer(0.5, false, 'RechargeAmmo');
		}
	}
}

function RechargeAmmo()
{
	if ( AmmoCount < MaxAmmoCount )
	{
		AmmoCount += AmmoRegenAmount;
		if ( AmmoCount < MaxAmmoCount )
		{
			SetTimer(0.5, false, 'RechargeAmmo');
		}	
	}
}

/**
* @returns position of trace start for instantfire()
*/
/*simulated function vector InstantFireStartTrace()
{
	return Instigator.GetWeaponStartTraceLocation();
}*/

/**
* @returns end trace position for instantfire()
*/
simulated function vector InstantFireEndTrace(vector StartTrace)
{
	return StartTrace + vector(Owner.Rotation) * GetTraceRange();
}

function float GetCooldownPerc(int m) 
{
	local float Time;
	//we need last fire time, animation time, fire interval
	Time = WorldInfo.TimeSeconds - LastWeaponFire[m];
	if (Time > 0)
	{
		if (Time >= FireInterval[m])
		{
			return 100.0;
		} 
		else
		{
			return (100.0 * Time) / FireInterval[m];
		}
	}
	return 0.0;
	/*if(Time <= AnimLength[0]) 
	{
		return FClamp(Time / AnimLength[m], 0, 1);
	} 
	else if(Time <= FireInterval[m])
	{
		return 1 - FClamp((Time -= AnimLength[m]) / (FireInterval[m] - AnimLength[m]), 0, 1);
	} 
	else 
	{
		return 0;
	}
	if(Time <= AnimLength[0]) 
	{
		return FClamp(Time / AnimLength[0], 0, 1);
	} 
	else if(Time <= FireInterval[0])
	{
		return 1 - FClamp((Time -= AnimLength[0]) / (FireInterval[0] - AnimLength[0]), 0, 1);
	} 
	else 
	{
		return 0;
	}*/
}

simulated state SpewFiring {

	/**
	 * Update the beam and handle the effects
	 */
	simulated function Tick(float DeltaTime)
	{
		// Retrace everything and see if there is a new LinkedTo or if something has changed.
		ConsumeFood(DeltaTime);
	}

	simulated function ConsumeFood(float DeltaTime)
	{
		local GWPawn P;

		P = GWPawn(Owner);
		PartialFoodConsumed += FoodConsumedPerSecond * DeltaTime;
		FoodConsumed += FoodConsumedPerSecond * DeltaTime;
		if(PartialFoodConsumed >= 1.0)
		{
			if(!P.DecrementAbility('PICKUPS_ALL', int(PartialFoodConsumed))) {
				//P.ClientMessage("Belly Empty");
				P.DevolveProgress(DeltaTime);
				if(!SpewFireEnded) {
					SpewFireEnded = true;
					ClearFlashCount();
				}
			}
			PartialFoodConsumed -= int(PartialFoodConsumed);
		}
		if(FoodConsumed >= 25) {
			CustomFire();
			FoodConsumed -= 25;
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
		local GWPawn P;
		local GWFoodActor foodActor;
		local EFood FoodType;
		local byte RandFood;

		P = GWPawn(Owner);
		//local Projectile	SpawnedProjectile;

		// tell remote clients that we fired, to trigger effects
		//IncrementFlashCount();

		if( Role == ROLE_Authority )
		{
			// This is where we would start an instant trace. (what CalcWeaponFire uses)
			StartTrace = Instigator.GetWeaponStartTraceLocation();
			AimDir = Vector(GetAdjustedAim( StartTrace ));

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
			if(P.Power <= 0 && P.Skill <= 0 && P.Speed <= 0) {
				return;
			}
			while(FoodType == FOOD_NONE) {
				RandFood = Rand(3);
				switch(RandFood) {
				case 0:
					if(P.Power > 0) {
						FoodType = FOOD_MEAT_SMALL;
					}
					break;
				case 1:
					if(P.Skill > 0) {
						FoodType = FOOD_FRUIT_SMALL;
					}
					break;
				case 2:
					if(P.Speed > 0) {
						FoodType = FOOD_CANDY_SMALL;
					}
					break;
				}
			}
			foodActor = Spawn(class'GWFoodActor', self, , StartTrace, RotRand(true));
			foodActor.Velocity = AimDir * 2000;
			foodActor.Init(FoodType);
			//SpawnedProjectile = Spawn(GetProjectileClass(), Self,, StartTrace);
			/*if( SpawnedProjectile != None && !SpawnedProjectile.bDeleteMe )
			{
				SpawnedProjectile.Init( AimDir );
			}*/

			// Return it up the line
			return;
		}

		return;
	}
	simulated function BeginState(Name PreviousStateName) {
		RefireCheckTimer();
		TimeWeaponFiring( CurrentFireMode );
		//CustomFire();
		IncrementFlashCount();
		SpewFireEnded = false;
		if(Role == ROLE_Authority) {
			GWPawn(Instigator).TriggerAnim(ANIM_SPEW);
		}
		SoundGroupClass.static.PlaySpewSound(GWPawn(Owner));
	}

	simulated function EndState(Name NextStateName)
	{
		ClearTimer('RefireCheckTimer');
		ClearFlashLocation();
		ClearFlashCount();
		SpewFireEnded = false;
		PartialFoodConsumed = 0;
		FoodConsumed = 0;
		GWPawn(Owner).ResetDevolve();
		if(Role == ROLE_Authority) {
			GWPawn(Instigator).TriggerAnim(ANIM_NONE);
		}

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
simulated function bool HasAmmo( byte FireModeNum, optional int Amount )
{
	if (Amount==0)
		return (AmmoCount >= ShotCost[FireModeNum]);
	else
		return ( AmmoCount >= Amount );
}
defaultproperties
{

	AmmoRegenAmount = 4
	InstantHitDamage(FIREMODE_ATTACK)=0
	InstantHitDamage(FIREMODE_ABILITY)=0
	InstantHitDamage(FIREMODE_EAT)=0
	InstantHitDamage(FIREMODE_CHEW)=0
	InstantHitDamage(FIREMODE_SPIT)=0
	InstantHitDamage(FIREMODE_SPEW)=0

	InstantHitMomentum(FIREMODE_ATTACK)=0.0
	InstantHitMomentum(FIREMODE_ABILITY)=0.0
	InstantHitMomentum(FIREMODE_EAT)=0.0
	InstantHitMomentum(FIREMODE_CHEW)=0.0
	InstantHitMomentum(FIREMODE_SPIT)=0.0
	InstantHitMomentum(FIREMODE_SPEW)=0.0

	WeaponFireTypes(FIREMODE_ATTACK)=EWFT_InstantHit
	WeaponFireTypes(FIREMODE_ABILITY)=EWFT_InstantHit
	WeaponFireTypes(FIREMODE_EAT)=EWFT_InstantHit
	WeaponFireTypes(FIREMODE_CHEW)=EWFT_InstantHit
	WeaponFireTypes(FIREMODE_SPIT)=EWFT_InstantHit
	WeaponFireTypes(FIREMODE_SPEW)=EWFT_Custom

	ShotCost(FIREMODE_ATTACK)=0
	ShotCost(FIREMODE_ABILITY)=0
	ShotCost(FIREMODE_EAT)=0
	ShotCost(FIREMODE_CHEW)=0
	ShotCost(FIREMODE_SPIT)=0
	ShotCost(FIREMODE_SPEW)=0

	FiringStatesArray(FIREMODE_ATTACK)=WeaponFiring
	FiringStatesArray(FIREMODE_ABILITY)=WeaponFiring
	FiringStatesArray(FIREMODE_EAT)=WeaponFiring
	FiringStatesArray(FIREMODE_CHEW)=WeaponFiring
	FiringStatesArray(FIREMODE_SPIT)=WeaponFiring
	FiringStatesArray(FIREMODE_SPEW)=SpewFiring

	WeaponProjectiles(FIREMODE_ATTACK)=none
	WeaponProjectiles(FIREMODE_ABILITY)=none
	WeaponProjectiles(FIREMODE_EAT)=none
	WeaponProjectiles(FIREMODE_CHEW)=none
	WeaponProjectiles(FIREMODE_SPIT)=none
	WeaponProjectiles(FIREMODE_SPEW)=class'GWProj_Spew'

	FireInterval(FIREMODE_ATTACK)=+1.0
	FireInterval(FIREMODE_ABILITY)=+1.0
	FireInterval(FIREMODE_EAT)=+1.0
	FireInterval(FIREMODE_CHEW)=+0.5
	FireInterval(FIREMODE_SPIT)=+1.0
	FireInterval(FIREMODE_SPEW)=0.2

	Spread(FIREMODE_ATTACK)=0.0
	Spread(FIREMODE_ABILITY)=0.0
	Spread(FIREMODE_EAT)=0.0
	Spread(FIREMODE_CHEW)=0.0
	Spread(FIREMODE_SPIT)=0.0
	Spread(FIREMODE_SPEW)=0.0

	LastWeaponFire(FIREMODE_ATTACK)=0.0
	LastWeaponFire(FIREMODE_ABILITY)=0.0
	LastWeaponFire(FIREMODE_EAT)=0.0
	LastWeaponFire(FIREMODE_CHEW)=0.0
	LastWeaponFire(FIREMODE_SPIT)=0.0
	LastWeaponFire(FIREMODE_SPEW)=0.0

	DelayWeaponFire(FIREMODE_ATTACK)=0.0
	DelayWeaponFire(FIREMODE_ABILITY)=0.0
	DelayWeaponFire(FIREMODE_EAT)=0.0
	DelayWeaponFire(FIREMODE_CHEW)=0.0
	DelayWeaponFire(FIREMODE_SPIT)=0.0
	DelayWeaponFire(FIREMODE_SPEW)=0.0

	InstantHitDamageTypes(FIREMODE_ATTACK)=class'DamageType'
	InstantHitDamageTypes(FIREMODE_ABILITY)=class'DamageType'
	InstantHitDamageTypes(FIREMODE_EAT)=class'DamageType'
	InstantHitDamageTypes(FIREMODE_CHEW)=class'DamageType'
	InstantHitDamageTypes(FIREMODE_SPIT)=class'DamageType'
	InstantHitDamageTypes(FIREMODE_SPEW)=class'DamageType'
	
	EffectSockets(FIREMODE_ATTACK)=MuzzleFlashSocket
	EffectSockets(FIREMODE_ABILITY)=MuzzleFlashSocket
	EffectSockets(FIREMODE_EAT)=MuzzleFlashSocket
	EffectSockets(FIREMODE_CHEW)=MuzzleFlashSocket
	EffectSockets(FIREMODE_SPIT)=MuzzleFlashSocket
	EffectSockets(FIREMODE_SPEW)=MuzzleFlashSocket
	
	/*WeaponFireSnd(FIREMODE_ATTACK)=SoundCue'Grow_Sounds.attackhigh_Cue'
	WeaponFireSnd(FIREMODE_ABILITY)=SoundCue'Grow_Sounds.attackhigh_Cue'
	WeaponFireSnd(FIREMODE_EAT)=none
	WeaponFireSnd(FIREMODE_CHEW)=none
	WeaponFireSnd(FIREMODE_SPIT)=none
	WeaponFireSnd(FIREMODE_SPEW)=none*/

	MinReloadPct(FIREMODE_ATTACK)=0.6
	MinReloadPct(FIREMODE_ABILITY)=0.6
	MinReloadPct(FIREMODE_EAT)=0.6
	MinReloadPct(FIREMODE_CHEW)=0.6
	MinReloadPct(FIREMODE_SPIT)=0.6
	MinReloadPct(FIREMODE_SPEW)=0.6

	ShouldFireOnRelease(FIREMODE_ATTACK)=0
	ShouldFireOnRelease(FIREMODE_ABILITY)=0
	ShouldFireOnRelease(FIREMODE_EAT)=0
	ShouldFireOnRelease(FIREMODE_CHEW)=0
	ShouldFireOnRelease(FIREMODE_SPIT)=0
	ShouldFireOnRelease(FIREMODE_SPEW)=0
	
	WeaponKeepFiring(FIREMODE_ATTACK)=1
	WeaponKeepFiring(FIREMODE_ABILITY)=1
	WeaponKeepFiring(FIREMODE_EAT)=1
	WeaponKeepFiring(FIREMODE_CHEW)=1
	WeaponKeepFiring(FIREMODE_SPIT)=0
	WeaponKeepFiring(FIREMODE_SPEW)=1

	FoodConsumedPerSecond=30

	AmmoCount=100
	MaxAmmoCount=100

	DefaultAnimSpeed=1
	bCanThrow = false

	PivotTranslation=(Y=0.0)

	MessageClass=class'UTPickupMessage'
	DroppedPickupClass=none
	CrosshairImage=none
	CrossHairCoordinates=(U=0,V=0,UL=128,VL=128)

	//FireOffset=(X=30,Y=0,Z=30)

	//SoundGroupClass=class'GWSoundGroup'

	LargestHitBox=200
	
}
