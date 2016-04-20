class GWProj_Power_1st extends GWProj_Power;

DefaultProperties
{
	ProjFlightTemplate=ParticleSystem'Grow_Effects.Effects.SonicBark_FirstBlast'
	CheckRadius=125
	Begin Object Name=CollisionCylinder
		CollisionRadius=125
		CollisionHeight=0	//125
	End Object
	LifeSpan = 0.5
	StunTime = 0.8//0.8
	Damage = 5
}