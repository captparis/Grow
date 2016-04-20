class GWProj_Food_Grenade extends GWProj_Food;

var float StartTime;
/**
 * Set the initial velocity and cook time
 */
simulated function PostBeginPlay()
{
	local MaterialInstanceTimeVarying MITV;

	Super.PostBeginPlay();
	StartTime = WorldInfo.TimeSeconds;
	SetTimer(10,false);                  //Grenade begins unarmed
	RandSpin(100000);
	MITV = new(self) class'MaterialInstanceTimeVarying';
	MITV.SetParent(MaterialInstanceTimeVarying'Grow_John_Assets.Materials.pomegranite_Mat_INST');
	MITV.SetDuration( 5 );
	MeshParam.SetMaterial(0, MITV);
}

function Init(vector Direction)
{
	SetRotation(Rotator(Direction));

	Velocity = Speed * Direction;
	TossZ = TossZ + (FRand() * TossZ / 2.0) - (TossZ / 4.0);
	Velocity.Z += TossZ;
	Acceleration = AccelRate * Normal(Velocity);
}

/**
 * Explode
 */
simulated function Timer()
{
	Explode(Location, vect(0,0,1));
}

/**
 * Give a little bounce
 */
simulated event HitWall(vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{
	if(GetRemainingTimeForTimer() > 2) {
		SetTimer(2);
	}
	bBlockedByInstigator = true;

	if ( WorldInfo.NetMode != NM_DedicatedServer )
	{
		//PlaySound(ImpactSound, true);
	}

	// check to make sure we didn't hit a pawn

	if ( Pawn(Wall) == none )
	{
		Velocity = 0.5*(( Velocity dot HitNormal ) * HitNormal * -2.0 + Velocity);   // Reflect off Wall w/damping
		Speed = VSize(Velocity);

		if (Velocity.Z > 400)
		{
			Velocity.Z = 0.5 * (400 + Velocity.Z);
		}
		// If we hit a pawn or we are moving too slowly, explode

		if ( Speed < 20 || Pawn(Wall) != none )
		{
			ImpactedActor = Wall;
			SetPhysics(PHYS_None);
		}
	}
	else if ( Wall != Instigator ) 	// Hit a different pawn, just explode
	{
		Explode(Location, HitNormal);
	}
}

/**
 * When a grenade enters the water, kill effects/velocity and let it sink
 */
simulated function PhysicsVolumeChange( PhysicsVolume NewVolume )
{
	if ( WaterVolume(NewVolume) != none )
	{
		if(GetRemainingTimeForTimer() > 1) {
		SetTimer(1);
	}
		Velocity *= 0.25;
	}

	Super.PhysicsVolumeChange(NewVolume);
}

DefaultProperties
{
	//ProjFlightTemplate=ParticleSystem'Grow_John_Assets.Effects.pomegranite_explosion_effect
	ProjExplosionTemplate=ParticleSystem'Grow_John_Assets.Effects.pomegranite_explosion_effect'
	
	ProjFlightTemplate=ParticleSystem'WP_RocketLauncher.Effects.P_WP_RocketLauncher_Smoke_Trail'

	//ProjExplosionTemplate=ParticleSystem'WP_RocketLauncher.Effects.P_WP_RocketLauncher_RocketExplosion'
	ExplosionLightClass=class'UTGame.UTRocketExplosionLight'

	speed=1500
	//MaxSpeed=1000.0
	Damage=100.0
	DamageRadius=700
	MomentumTransfer=50000
	MyDamageType=class'GWDmgType_Grenade'
	LifeSpan=0.0
	//ExplosionSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Impact_Cue'
	//ExplosionDecal=MaterialInstanceTimeVarying'WP_RocketLauncher.Decals.MITV_WP_RocketLauncher_Impact_Decal01'
	//DecalWidth=128.0
	//DecalHeight=128.0
	bCollideWorld=true
	bBounce=true
	//TossZ=+400.0
	Physics=PHYS_Falling
	CheckRadius=36.0

	//ImpactSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_GrenadeFloor_Cue'

	bNetTemporary=False
	bWaitForEffects=false

	CustomGravityScaling=0.7

	Begin Object Name=CollisionCylinder
		CollisionRadius=15
		CollisionHeight=15
	End Object
}
