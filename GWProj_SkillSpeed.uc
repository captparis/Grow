class GWProj_SkillSpeed extends GWProj;

DefaultProperties
{
	ProjFlightTemplate=ParticleSystem'Grow_John_Assets.Effects.Toot_Shot'
	ProjExplosionTemplate=ParticleSystem'Grow_Effects.Effects.Bubble_Splat_Effect'
	Damage=50
	Speed=9000
	CheckRadius=24
	Begin Object Name=CollisionCylinder
		CollisionRadius=18
		CollisionHeight=18
	End Object
}
