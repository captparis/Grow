class GWWeap_SkillMax extends GWWeap_Ranged;

simulated function AbilityFire() {
	local vector AimOrigin, AimDirection;
	local GWPawn tempTarget;
	local Vector targetLocation;
	local Rotator targetRotation;
	
	// define range to use for CalcWeaponFire()
	AimOrigin = InstantFireStartTrace();
	IncrementFlashCount();
	foreach VisibleCollidingActors(class'GWPawn', tempTarget, 1000, AimOrigin) {
		//Boost Damage (Call a function in Pawn)
		tempTarget.GetActorEyesViewPoint(targetLocation, targetRotation); //Get Pawn's Location
		if(HealRadiusCollision(AimOrigin, AbilityExtent, AimDirection, tempTarget.HitBoxInfo, targetLocation, Vector(targetRotation))) {
			if(GWPawn(Instigator).IsSameTeamOrSelf(tempTarget)) {
				tempTarget.IncrementStatusEffect(EFFECT_BUBBLES_AEGIS, Instigator.Controller);
			}
		}
	}
}

/*simulated function DrawAbilityTargets(HUD H) {
	local GWPawn targetPawn;
	local Vector StartTrace;

	// define range to use for CalcWeaponFire()
	StartTrace = Instigator.Location;

	foreach VisibleCollidingActors(class'GWPawn', targetPawn, AbilityRange, StartTrace) {
		//Boost Damage (Call a function in Pawn)
		if(GWPawn(Owner).IsSameTeam(targetPawn)) {
			H.Draw3DLine(StartTrace, targetPawn.Location, MakeColor(0, 255, 0));
		}
	}
}*/

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


DefaultProperties
{
	EatExtent=(X=75,Y=25,Z=25)
	AbilityExtent=(X=500)
	WeaponProjectiles(0)=class'Grow.GWProj_SkillMax'
	
	//AbilityDuration=7
	//AbilityMultiplier=1.5
	FireInterval(1)=2//25
	
	ShotCost(1)=75
	WeaponFireTypes(1)=EWFT_InstantHit
	FireInterval(0)=1.5
	//WeaponFireSnd[0]=SoundCue'Grow_Sounds.attacksoft_Cue'
	//WeaponFireSnd[1]=SoundCue'Grow_Sounds.attacksoft_Cue'
}
