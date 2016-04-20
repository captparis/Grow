class GWProj_SkillMax extends GWProj;

//var repnotify Actor ReplicatedTarget;

/*replication {
	if(bNetDirty && Role == ROLE_Authority)
		ReplicatedTarget;
}

simulated event ReplicatedEvent(name VarName) {
	if(VarName == 'ReplicatedTarget') {
		SeekTarget = ReplicatedTarget;
	}
	super.ReplicatedEvent(VarName);
}*/

simulated function PhysicsVolumeChange( PhysicsVolume NewVolume )
{
	if ( WaterVolume(NewVolume) != none ) {
		Velocity *= 0.50;
		SetPhysics(PHYS_Projectile);
	} else {
		SetPhysics(PHYS_Falling);
	}

	Super.PhysicsVolumeChange(NewVolume);
}

/*event Tick( float DeltaTime ) {
	local GWPawn tempTarget;
	if(SeekTarget == none) {
		foreach VisibleCollidingActors(class'GWPawn', tempTarget, 200, Location) {
			//Boost Damage (Call a function in Pawn)
			if(tempTarget.IsSameTeamOrSelf(Instigator)) {
				continue;
			}
			bNetDirty=true;
			bForceNetUpdate=true;
			ReplicatedTarget = tempTarget;
			SeekTarget = tempTarget;
			break;
		}
	}
	super.Tick(DeltaTime);
}*/

DefaultProperties
{
	CheckRadius=40
	Physics=PHYS_Falling
	ProjFlightTemplate=ParticleSystem'Grow_John_Assets.Effects.Bubble_Attack_Effect'
	ProjExplosionTemplate=ParticleSystem'Grow_Effects.Effects.Bubble_Splat_Effect'
	Damage=30
	bBounce=true
	Begin Object Name=CollisionCylinder
		CollisionRadius=5
		CollisionHeight=5
	End Object
	CustomGravityScaling=0.4

	//BaseTrackingStrength=5
}
