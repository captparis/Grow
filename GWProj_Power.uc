class GWProj_Power extends GWProj
	abstract;

var float StunTime;

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	if (Pawn(Other) != none && Instigator != Other) //Pass through Fluid Surface Actors
	{
		GWPlayerController(Pawn(Other).Controller).ServerStun(StunTime);
		Other.TakeDamage(Damage,InstigatorController,HitLocation,MomentumTransfer * Normal(Velocity), MyDamageType,, self);
	} else {
		super.ProcessTouch(Other, HitLocation, HitNormal);
	}
}
simulated event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp) {
	if (Pawn(Wall) != none && Instigator != Wall) {
		GWPlayerController(Pawn(Wall).Controller).ServerStun(StunTime);
		Wall.TakeDamage(Damage,InstigatorController,HitNormal,MomentumTransfer * Normal(Velocity), MyDamageType,, self);
	} else {
		super.HitWall(HitNormal, Wall, WallComp);
	}
}

DefaultProperties
{
	ProjExplosionTemplate=ParticleSystem'Grow_Effects.Effects.sonicbarkimpact_Effect'
	Damage=0//12
	LifeSpan = 5
	MomentumTransfer=30000
	bBlockedByInstigator=false
	MyDamageType=class'GWDmgType_Bark'
}
