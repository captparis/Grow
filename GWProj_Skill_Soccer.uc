class GWProj_Skill_Soccer extends GWProj;

var int Gravity;
simulated function PhysicsVolumeChange( PhysicsVolume NewVolume )
{
	if ( WaterVolume(NewVolume) != none )
	{
		Velocity *= 0.50;
		SetPhysics(PHYS_Projectile);
	} else {
		SetPhysics(PHYS_Falling);
	}

	Super.PhysicsVolumeChange(NewVolume);
}

DefaultProperties
{
	Speed=1000
	MinimumBounceSpeed=50
	CheckRadius=5
	Physics=PHYS_Falling
	ProjFlightTemplate=ParticleSystem'Grow_Effects.Effects.waterbeam_Effect'
	//ProjExplosionTemplate=ParticleSystem'Grow_Effects.Effects.Glob_Splat_Effect'
	Damage=10
	LifeSpan=0.5
	Begin Object Name=CollisionCylinder
		CollisionRadius=5
		CollisionHeight=5
	End Object
	CustomGravityScaling=0.4
	bBounce=false
}