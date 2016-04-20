class GWSoccerBall extends KActorSpawnable
    notplaceable;

var Controller LastToucher;

simulated function TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser) {
	LastToucher = EventInstigator;
	super.TakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}
simulated function TakeRadiusDamage(Controller InstigatedBy, float BaseDamage, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HurtOrigin, bool bFullDamage, Actor DamageCauser, optional float DamageFalloffExponent=1.f) {
	LastToucher = InstigatedBy;
	super.TakeRadiusDamage(InstigatedBy, BaseDamage, DamageRadius, DamageType, Momentum, HurtOrigin, bFullDamage, DamageCauser, DamageFalloffExponent);
}

defaultproperties
{
	bIgnoreEncroachers=false
	bWakeOnLevelStart=true
	bCollideActors=TRUE
	bProjTarget=TRUE
	bPathColliding=FALSE
	bDamageAppliesImpulse=true
	bCanBeDamaged=true
    Begin Object Name=MyLightEnvironment
		bEnabled=TRUE
		bDynamic=FALSE
	End Object

	Begin Object Name=StaticMeshComponent0
        StaticMesh=StaticMesh'G_P_Fruit.Mesh.SM_Fruit_Large'
		bNotifyRigidBodyCollision=true
	End Object

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent1
		StaticMesh=StaticMesh'G_P_Fruit.Mesh.SM_Fruit_Large'
		HiddenGame=TRUE
		CollideActors=TRUE
		BlockActors=FALSE
		AlwaysCheckCollision=TRUE
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE,FracturedMeshPart=FALSE)
	End Object
	Components.Add(StaticMeshComponent1)
}