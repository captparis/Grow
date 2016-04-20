class GWProj_Skill extends GWProj;

var int Gravity;
/*simulated function PhysicsVolumeChange( PhysicsVolume NewVolume )
{
	if ( WaterVolume(NewVolume) != none )
	{
		Shutdown();
	}

	Super.PhysicsVolumeChange(NewVolume);
}*/
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	if (FluidSurfaceActor(Other) == none) //Pass through Fluid Surface Actors
	{
		if(GWPawn(Other) != none) {
			if(GWPawn(Other).IsSameTeam(Instigator)) {
				Other.HealDamage(Damage, InstigatorController, MyDamageType);
				if(Instigator.Weapon != none) {
					Instigator.Weapon.AddAmmo(Damage);
				}
				ProjExplosionTemplate = ParticleSystem'Grow_John_Assets.Effects.WaterBeam_friendly_impact';
			} else {
				Other.TakeDamage(Damage,InstigatorController,HitLocation,MomentumTransfer * Normal(Velocity), MyDamageType,, self);
				if(Instigator.Weapon != none) {
					Instigator.Weapon.AddAmmo(Damage);
				}
				ProjExplosionTemplate = ParticleSystem'Grow_John_Assets.Effects.WaterBeam_enemy_impact';
			}
		}
		Shutdown();
	}
}
function Init(vector Direction)
{
	SetRotation(Rotator(Direction));

	Velocity = Speed * Direction/* + vect3d(0,0,400)*/;
	Acceleration = vect3d(0, 0, Gravity);
}
function Tick(float DeltaTime) {
	Speed = default.Speed;
}

simulated event SetInitialState()
{
	bScriptInitialized = true;
	if (Role < ROLE_Authority)
	{
		GotoState('WaitingForVelocity');
	}
	else
	{
		GotoState((InitialState != 'None') ? InitialState : 'Auto');
	}
}

state WaitingForVelocity
{
	simulated function Tick(float DeltaTime)
	{
		if (!IsZero(Velocity))
		{
			Acceleration = vect3d(0, 0, Gravity);
			GotoState((InitialState != 'None') ? InitialState : 'Auto');
		}
	}
}

DefaultProperties
{
	Speed=9000
	MinimumBounceSpeed=50
	//CheckRadius=1
	Physics=PHYS_Projectile
	ProjFlightTemplate=ParticleSystem'Grow_John_Assets.Effects.waterbeam_single_shot'
	ProjExplosionTemplate=none
	Damage=5
	DamageRadius=0
	LifeSpan=0.5
	bBounce=false
	/*Begin Object Name=CollisionCylinder
		CollisionRadius=2
		CollisionHeight=2
	End Object*/
	CustomGravityScaling=1
	//Gravity=-3000
	MyDamageType=class'GWDmgType_WaterGun'
}