class GWProj_Food extends GWProj
	abstract;

var int DamageHP;
var StaticMeshComponent MeshParam;
var repnotify EFood FT;
var byte FoodStrength; //Number of bites left

replication {
	if(bNetInitial)
		FT, FoodStrength;
}
simulated event ReplicatedEvent(name VarName)
{
	if ( VarName == 'FT') {
		InitStats(FT, FoodStrength);
	}
	super.ReplicatedEvent(VarName);
}
simulated function InitStats(EFood FoodType, int Power) {
	local SFoodInfo FI;

	//`Log(name@"set food"@FoodType);

	FI = class'GWConstants'.default.FoodStats[FoodType];
	MeshParam.SetStaticMesh(FI.Mesh);
	MeshParam.SetScale(Power / float(FI.Size));
	if(Role == ROLE_Authority) {
		Damage = default.Damage * Power;
		FT = FoodType;
		FoodStrength = Power;
	}
}

DefaultProperties
{
	ProjFlightTemplate=ParticleSystem'Grow_John_Assets.Effects.Food_Trail_Effect'
	ProjExplosionTemplate=ParticleSystem'Grow_John_Assets.Effects.Food_Splat_Effect'
	Damage=10
	Physics=PHYS_Falling

	/*Begin Object Name=CollisionCylinder
		CollisionRadius=18
		CollisionHeight=18
	End Object*/
	Begin Object Class=StaticMeshComponent Name=FoodComponent
		BlockActors=false
		CollideActors=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		HiddenGame=false
		HiddenEditor=true
		LightingChannels=(Dynamic=true)
		Scale3D=(X=1.0,Y=1.0,Z=1.0)
	End Object
	MeshParam = FoodComponent
	Components.Add(FoodComponent)
	/*DecalWidth=256
	DecalHeight=256
	bAdvanceExplosionEffect = true*/
}
