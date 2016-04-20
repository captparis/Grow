class GWProj_Power_2nd extends GWProj_Power;

DefaultProperties
{
	ProjFlightTemplate=ParticleSystem'Grow_Effects.Effects.SonicBark_SecondBlast'
	CheckRadius=150
	Begin Object Name=CollisionCylinder
		CollisionRadius=150
		CollisionHeight=0
	End Object
	LifeSpan = 0.52
	StunTime = 1.2
	Damage = 20
}