class GWProj_SkillPower extends GWProj;

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

DefaultProperties
{
	Speed = 7000
	MaxSpeed = 12000
	Physics=PHYS_Falling
	ProjFlightTemplate=ParticleSystem'Grow_Effects.Effects.Spike_Shell_Attack'
	ProjExplosionTemplate=ParticleSystem'Grow_John_Assets.Effects.Spiral_Shot_Collision_Effect'
	LifeSpan=8.0
	Damage=40
	bCollideWorld=true
	CheckRadius=35
	bNetTemporary=False
	bWaitForEffects=false
	Begin Object Name=CollisionCylinder
		CollisionRadius=25
		CollisionHeight=25
	End Object
	CustomGravityScaling=0.5
}
