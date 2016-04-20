class GWSpawnEgg extends Actor;
var StaticMeshComponent Mesh;
var ParticleSystemComponent Part;

simulated function bool CalcCamera( float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV )
{
	local vector HitNormal;
	local float Radius, Height;

	GetBoundingCylinder(Radius, Height);

	if (Trace(out_CamLoc, HitNormal, Location - vector(out_CamRot) * Radius * 2, Location, false) == None)
	{
		out_CamLoc = Location - vector(out_CamRot) * Radius * 3;
	}
	else
	{
		out_CamLoc = Location + Height * vector(Rotation);
	}

	return false;
}

DefaultProperties
{
	Begin Object class=StaticMeshComponent name=StaticMesh0
		StaticMesh=StaticMesh'G_FX_CH_All.Mesh.SM_Egg_Spawn'
		Translation=(Z=-24.5)
	end object
	Mesh = StaticMesh0
	Components.Add(StaticMesh0)

	Begin Object Class=ParticleSystemComponent Name=EggPart
		bAutoActivate=true
		Template=ParticleSystem'G_FX_CH_All.Effects.PS_Egg_Spawn'
	End Object
	Part=EggPart
	Components.Add(EggPart)

	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=+0018.000000
		CollisionHeight=+0024.5
		CollideActors=true
		BlockActors=true
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
	Physics=PHYS_Falling
	//LifeSpan=5.f
	bCollideActors=true
	bBlockActors=true
	bCollideWorld=true
	RemoteRole=ROLE_SimulatedProxy
}
