class GWFoodActor extends KActorSpawnable;

var EFood FoodType;
var SFoodInfo FoodInfo;

replication {
	if(bNetInitial)
		FoodType, FoodInfo;
}

function Init(EFood food) {
	FoodType = food;
	FoodInfo = class'GWConstants'.default.FoodStats[FoodType];
	SetStaticMesh(FoodInfo.Mesh);
}

DefaultProperties
{
	//Physics=PHYS_Game //Sets physics
    //AttackDistance=96.0     //Enemies attacking distance
    //bBlockActors=true
    //bCollideActors=true
    bWakeOnLevelStart=true
	bAllowFluidSurfaceInteraction=true
	LifeSpan=30
	bCollideActors=true
	bBlockActors=false
	//CollisionType = COLLIDE_BlockWeaponsKickable
	Begin Object Name=StaticMeshComponent0
		BlockActors=false
		CollideActors=true
		BlockNonZeroExtent=true
		BlockRigidBody=true
		HiddenGame=False
		LightingChannels=(Dynamic=true)
		Scale3D=(X=1.0,Y=1.0,Z=1.0)
	End Object
	bPawnCanBaseOn=false
}
