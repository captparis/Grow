class GWWeap_PowerMax extends GWWeap_Melee;

var float AbilityKillRange;
var bool AbilityFiring;
var float MaximumMassEaten;


simulated function AbilityFire() {
	if(CurrentFireMode == FIREMODE_ABILITY && Owner.Physics == PHYS_Falling) {
		AbilityFiring = true;
		AbilityEnd();

		return;
	}
	IncrementFlashCount();
	SetTimer(5, false, 'AbilityEnd');
	AbilityFiring = true;
	Pawn(Owner).Controller.GotoState('PlayerAbility');
	// Block player movement
}

simulated function FireAmmunition()
{
	if(CurrentFireMode == FIREMODE_ABILITY && Owner.Physics == PHYS_Falling) {
		return;
	}
	if(AbilityFiring) {
		return;
	}
	super.FireAmmunition();
}

simulated function Tick(float DeltaTime) {
	local vector AimOrigin, AimDirection;
	local GWPawn tempTarget;
	local GWFoodActor tempFood;
	local Vector targetLocation;
	local Rotator targetRotation;
	local float DistFromAim;
	local Vector DeltaVelocity;
	local SFoodInfo FI;

	if(!AbilityFiring) {
		super.Tick(DeltaTime);
		return;
	}
	if(Pawn(Owner).Controller != none && !Pawn(Owner).Controller.IsInState('PlayerAbility')) {
		Pawn(Owner).Controller.GotoState('PlayerAbility');
	}

	AimOrigin = InstantFireStartTrace();
	AimDirection = InstantFireEndTrace(AimOrigin);

	AimDirection = Normal(AimDirection - AimOrigin); // Magnitude of RealEndTrace
	
	foreach VisibleCollidingActors(class'GWPawn', tempTarget, 1200, AimOrigin) {
		/**
		 * Hit enemies in a short range cylinder
		 */
		if(GWPawn(Owner).IsSameTeamOrSelf(tempTarget)) {
			continue;
		}
		tempTarget.GetActorEyesViewPoint(targetLocation, targetRotation); //Get Pawn's Location

		if(PrimaryAttackCollision(AimOrigin, AbilityExtent, AimDirection, tempTarget.HitBoxInfo, targetLocation, Vector(targetRotation))) {
			DistFromAim = VSize(AimOrigin - targetLocation) - Pawn(Owner).GetCollisionRadius() - tempTarget.GetCollisionRadius();
			if(DistFromAim <= AbilityKillRange && tempTarget.Mass <= MaximumMassEaten) {
				//Someone got eaten
				//tempTarget.SetPhysics(PHYS_Interpolating);
				//tempTarget.MoveSmooth(Owner.Location + GWPawn(Owner).GetEyeHeight() * vect3d(0,0,1));
				DeltaVelocity = 100000 * DeltaTime * (-Normal(targetLocation - AimOrigin)/* + vect3d(0,0,1)*/);
				tempTarget.TakeDamage( InstantHitDamage[CurrentFireMode], Instigator.Controller,
						targetLocation, DeltaVelocity,
						InstantHitDamageTypes[CurrentFireMode],, self );
				/*if(Role == ROLE_Authority) {
					GWPawn(Owner).TriggerAnim(ANIM_ABILITY_HIT);
					AbilityEnd();
					return;
				}*/
			} else {
				//Pull towards us
				DeltaVelocity = 300000 * DeltaTime * (-Normal(targetLocation - AimOrigin)/* + vect3d(0,0,1)*/);
				//`Log("DeltaVelocity ="@DeltaVelocity);
				tempTarget.TakeDamage(0, Instigator.Controller,
						targetLocation, DeltaVelocity,
						class'GWDmgType_Vacuum',, self );
			}

		}
	}
	foreach VisibleActors(class'GWFoodActor', tempFood, 1200, AimOrigin) {
		tempFood.GetActorEyesViewPoint(targetLocation, targetRotation); //Get Pawn's Location

		if(EatFoodCollision(AimOrigin, AbilityExtent, AimDirection, targetLocation, targetRotation)) {
			DistFromAim = VSize(AimOrigin - targetLocation) - Pawn(Owner).GetCollisionRadius() - 25;
			if(DistFromAim <= AbilityKillRange) {
				//Someone got eaten
				FI = class'GWConstants'.default.FoodStats[tempFood.FoodType];
				GWPawn(Owner).Health = Clamp(GWPawn(Owner).Health + FI.HealAmount, GWPawn(Owner).Health, GWPawn(Owner).HealthMax);
				GWPawn(Owner).IncrementAbility(FI.StatName, FI.FoodAmount);

				tempFood.Destroy();
				if(Role == ROLE_Authority) {
					GWPawn(Owner).TriggerAnim(ANIM_ABILITY_HIT);
				}
			} else {
				//Pull towards us
				DeltaVelocity = 500 * DeltaTime * (Normal(AimOrigin - targetLocation)/* + vect3d(0,0,1)*/);
				`Log("DeltaVelocity ="@DeltaVelocity);
				tempFood.TakeDamage(0, Instigator.Controller,
						targetLocation, DeltaVelocity,
						class'GWDmgType_Vacuum',, self );
			}
		}
	}
	
	super.Tick(DeltaTime);
}
simulated function AbilityEnd() {
	
	if(AbilityFiring) {
		AbilityFiring = false;
		ClearTimer('AbilityEnd');
		Pawn(Owner).Controller.GotoNormalState();
		GWPawn(Owner).TriggerAnim(ANIM_NONE);
	}
	// Reenable player movement
}

/*simulated function DrawAbilityTargets(HUD H) {
	local vector AimOrigin, AimDirection;
	local GWPawn tempTarget;
	local Vector targetLocation;
	local Rotator targetRotation;
	local float DistFromAimDir;
	local float RangeSq;
	local float RadiusSq;

	AimOrigin = InstantFireStartTrace();
	AimDirection = InstantFireEndTrace(AimOrigin);

	AimDirection = Normal(AimDirection - AimOrigin) * AbilityRange; // Magnitude of RealEndTrace
	RangeSq = AbilityRange * AbilityRange;
	RadiusSq = AbilityRadius * AbilityRadius;

	foreach VisibleCollidingActors(class'GWPawn', tempTarget, AbilityRange, AimOrigin) {
		/**
		 * Hit enemies in a short range cylinder
		 */
		if(GWPawn(Owner).IsSameTeam(tempTarget)) {
			continue;
		}
		tempTarget.GetActorEyesViewPoint(targetLocation, targetRotation); //Get Pawn's Location

		DistFromAimDir = PointInCylinderTest(AimOrigin, AimDirection, RangeSq, RadiusSq, targetLocation);
		if(DistFromAimDir != -1) {
			if(DistFromAimDir <= AbilityKillRange) {
				H.Draw3DLine(AimOrigin, targetLocation, MakeColor(0, 255, 0));
			}
		}
	}
}*/

DefaultProperties
{
	MaximumMassEaten=1000
	PrimaryExtent=(X=200,Y=100,Z=150)
	EatExtent=(X=200,Y=100,Z=150)
	AbilityExtent=(X=1200,Y=300,Z=300)
	AbilityKillRange=50
	ShotCost(1)=100
	InstantHitDamage(1)=1
	InstantHitDamage(0)=80
	FireInterval(0)=1.5
	FireInterval(1)=2
	InstantHitMomentum(0)=200000
	InstantHitDamageTypes(1)=class'GWDmgType_Eaten'
	WeaponFireTypes(1)=EWFT_InstantHit
	//WeaponFireSnd[0]=SoundCue'Grow_Sounds.attacklow_Cue'
	//WeaponFireSnd[1]=SoundCue'Grow_Sounds.attacklow_Cue'
}
