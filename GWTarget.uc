class GWTarget extends KActorSpawnable
    notplaceable;

var float Score;
var int Health;

/** Called when shot. */
simulated function TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser) {
	//local ParticleSystemComponent ProjExplosion;
	Health -= DamageAmount;
	if(Health > 0)
		return;

	if (WorldInfo.NetMode != NM_DedicatedServer) {
		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Grow_Effects.Effects.Glob_Splat_Effect', Location);
	}
	`Log("Ouch");
	
	WorldInfo.Game.ScoreObjective(EventInstigator.PlayerReplicationInfo, Score);
	GWTargetSpawner(Owner).CurrentTarget = none;
	Destroy();
}
simulated function TakeRadiusDamage(Controller InstigatedBy, float BaseDamage, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HurtOrigin, bool bFullDamage, Actor DamageCauser, optional float DamageFalloffExponent=1.f) {
	TakeDamage(BaseDamage, InstigatedBy, HurtOrigin, Momentum * Normal(HurtOrigin), DamageType,,DamageCauser);
}
defaultproperties
{
	bCollideActors=TRUE
	bProjTarget=TRUE
	bPathColliding=FALSE
	bDamageAppliesImpulse=false
	bCanBeDamaged=true
	Health=1
    Begin Object Name=MyLightEnvironment
		bEnabled=TRUE
		bDynamic=FALSE
	End Object

	Begin Object Name=StaticMeshComponent0
        StaticMesh=StaticMesh'G_SM_Target.StaticMeshs.SM_ArcheryTarget_Complete'
		Rotation=(Yaw=32768)
	End Object
}