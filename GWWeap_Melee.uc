class GWWeap_Melee extends GWWeap
	abstract;

//Handles Single Shot Conefire Weapons
simulated function AttackFire()
{
	local vector AimOrigin, AimDirection;
	local GWPawn tempTarget;
	local Vector targetLocation;
	local Rotator targetRotation;

	IncrementFlashCount();
	
	AimOrigin = InstantFireStartTrace();
	AimDirection = InstantFireEndTrace(AimOrigin);

	AimDirection = Normal(AimDirection - AimOrigin); // Magnitude of RealEndTrace
	foreach VisibleActors(class'GWPawn', tempTarget, PrimaryExtent.X + 2 * LargestHitBox, AimOrigin) {
		if(GWPawn(Owner).IsSameTeamOrSelf(tempTarget)) {
			continue;
		}
		tempTarget.GetActorEyesViewPoint(targetLocation, targetRotation); //Get Pawn's Location
		if(PrimaryAttackCollision(AimOrigin, PrimaryExtent, AimDirection, tempTarget.HitBoxInfo, targetLocation, Vector(targetRotation))) {
			tempTarget.TakeDamage( InstantHitDamage[CurrentFireMode], Instigator.Controller,
			Instigator.Location, InstantHitMomentum[CurrentFireMode] * -Normal(Instigator.Location - tempTarget.Location),
			InstantHitDamageTypes[CurrentFireMode],, self );
		}
	}
}
defaultproperties
{
	bMeleeWeapon=true
	WeaponFireTypes(0)=EWFT_InstantHit
	InstantHitDamage(0)= 20
	FireInterval(0)= 1.7
	InstantHitMomentum(0)=50000
	InstantHitDamageTypes(0)=class'GWDmgType_Bite'
	//WeaponFireSnd[0]=SoundCue'Grow_Sounds.attackhigh_Cue'
	//WeaponFireSnd[1]=SoundCue'Grow_Sounds.attackhigh_Cue'
}
