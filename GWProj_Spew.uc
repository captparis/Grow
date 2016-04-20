class GWProj_Spew extends GWProj;

var int Gravity;

function Init(vector Direction)
{
	SetRotation(Rotator(Direction));

	Velocity = Speed * Direction/* + vect3d(0,0,400)*/;
	//Acceleration = vect3d(0, 0, Gravity);
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
			//Acceleration = vect3d(0, 0, Gravity);
			GotoState((InitialState != 'None') ? InitialState : 'Auto');
		}
	}
}

DefaultProperties
{
	Speed=3000
	MinimumBounceSpeed=50
	//CheckRadius=1
	Physics=PHYS_Projectile
	ProjFlightTemplate=ParticleSystem'Grow_Effects.Effects.Temp_Projectile'
	ProjExplosionTemplate=ParticleSystem'Grow_John_Assets.Effects.Spew_impact'
	Damage=0
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