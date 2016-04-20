class GWProj extends UTProjectile;

var float MinimumBounceSpeed;
var int MaxBounces;
var int BouncesCount;

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	if (FluidSurfaceActor(Other) == none) //Pass through Fluid Surface Actors
	{
		if (DamageRadius > 0.0) {
			Explode( HitLocation, HitNormal );
		} else {
			Other.TakeDamage(Damage,InstigatorController,HitLocation,MomentumTransfer * Normal(Velocity), MyDamageType,, self);
			Shutdown();
		}
	}
}

//==============
// Touching
simulated singular event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if ( (Other == None) || Other.bDeleteMe ) // Other just got destroyed in its touch?
		return;

	if (bIgnoreFoliageTouch && InteractiveFoliageActor(Other) != None ) // Ignore foliage if desired
		return;
	// don't allow projectiles to explode while spawning on clients
	// because if that were accurate, the projectile would've been destroyed immediately on the server
	// and therefore it wouldn't have been replicated to the client
	if ( Other.StopsProjectile(self) && (Role == ROLE_Authority || bBegunPlay) && (bBlockedByInstigator || (Other != Instigator)) )
	{
		ImpactedActor = Other;
		ProcessTouch(Other, HitLocation, HitNormal);
		ImpactedActor = None;
	}
}
	
simulated event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp) {

	if(!bBounce || ((BouncesCount >= MaxBounces) && MaxBounces != 0)) {

		super.HitWall(HitNormal,Wall,WallComp);
	} else {

		if ( WorldInfo.NetMode != NM_DedicatedServer )
		{
			//PlaySound(ImpactSound, true);
		}

		// check to make sure we didn't hit a pawn
		BouncesCount++;
		if ( Pawn(Wall) == none )
		{
			Velocity = 0.75*(( Velocity dot HitNormal ) * HitNormal * -2.0 + Velocity);   // Reflect off Wall w/damping
			Speed = VSize(Velocity);

			/*if (Velocity.Z > 400)
			{
				Velocity.Z = 0.5 * (400 + Velocity.Z);
			}*/
			// If we hit a pawn or we are moving too slowly, explod
			if(Speed < MinimumBounceSpeed) {
				Explode(Location, HitNormal);
				if(Projectile(Wall) != none) {
					Projectile(Wall).Explode(Wall.Location, -1 * HitNormal);
				}
				return;
			}
			if ( Speed < 20 || Pawn(Wall) != none )
			{
				ImpactedActor = Wall;
				SetPhysics(PHYS_None);
			}
		}
		else if ( Wall != Instigator) 	// if a pawn, but not shooter
		{
			Explode(Location, HitNormal);
			if(Projectile(Wall) != none) {
				Projectile(Wall).Explode(Wall.Location, -1 * HitNormal);
			}
		}
	}
}

simulated event CreateProjectileLight()
{
	if ( WorldInfo.bDropDetail || ProjectileLightClass == none)
		return;

	ProjectileLight = new(self) ProjectileLightClass;
	AttachComponent(ProjectileLight);
}

defaultproperties
{
	Speed=3000
	MaxSpeed=3000
	MaxEffectDistance=7000.0
	bCheckProjectileLight=true
	bSwitchToZeroCollision = false
	
	Damage=2
	DamageRadius=120
	MomentumTransfer=30000

	MyDamageType=class'Grow.GWDmgType_Bite'
	LifeSpan=8.0

	bCollideWorld=true
	bProjTarget=True
	bBounce=false

	bCollideComplex=false

	Begin Object Name=CollisionCylinder
		AlwaysLoadOnClient=True
		AlwaysLoadOnServer=True
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object

	bNetTemporary=false
	bAllowFluidSurfaceInteraction=true
	bBlockedByInstigator=false
	//bAlwaysRelevant=true
	ProjectileLightClass=none
}
