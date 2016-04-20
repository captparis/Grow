class GWPlant extends Actor
	abstract
	ClassGroup(Grow)
	dependson(GWConstants);

var SkeletalMeshComponent bulbMesh;
//var StaticMeshComponent effectMesh;
//var CylinderComponent activeRangeComp;
var AnimNodeBlendList AnimList;
var AnimNodeSequence BumpAnim;
var AnimNodeSequence BounceAnim;
var AnimNodeSequence SpawnAnim;

//var float scaleRate;

struct SFoodSpawn {
	var() EFood Type;
	var() int SpawnWeight;
	var() int MaxSpawnCount;
	structdefaultproperties {
		SpawnWeight=1
		MaxSpawnCount=-1
	}
};

var() const array<SFoodSpawn> FoodSpawnList;
var int TotalFoodWeight;

//var const int growthThreshold; // How much it takes the tree to progress
//var const int growthSpeed; // How fast the tree grows
//var repnotify int growthCount; // Current growth amount, once it hits threshold the tree expands
//var repnotify int activePawns; // Number of players nearby
//var repnotify name NewStateName;
var repnotify byte RepForceByte;
//var float CachedGrowthTime;

//var MaterialInstanceConstant effectMat;

var() int FoodNumToSpawn;

//var float RunningTime;
//var float ClockTime;

replication
{
	// Variables the server should send ALL clients.
	if (bNetDirty && Role == ROLE_Authority)
		//activePawns, NewStateName, growthCount;
		RepForceByte;
}

simulated event ReplicatedEvent(name VarName) {
	/*if(VarName == 'NewStateName') {
		ClientGoToState(NewStateName);
	}/ else if(VarName == 'growthCount') {
		GrowthAnim.SetPosition(FClamp(growthCount / float(growthThreshold), 0, 1) * CachedGrowthTime, true);
	}/ else if(VarName == 'activePawns') {
		//GrowthAnim.Rate = activePawns;
		effectMat.SetScalarParameterValue('opacityMultiplier', activePawns * 0.25);
		effectMat.SetScalarParameterValue('timeMultiplier', activePawns);
		//effectMesh.SetHidden(!bool(activePawns));
	}*/
	if(VarName == 'RepForceByte') {
		PlaySpawnFoodAnim();
	}
	super.ReplicatedEvent(VarName);
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
  BumpAnim = AnimNodeSequence(SkelComp.FindAnimNode('BumpAnim'));
  BounceAnim = AnimNodeSequence(SkelComp.FindAnimNode('BounceAnim'));
  SpawnAnim = AnimNodeSequence(SkelComp.FindAnimNode('SpawnAnim'));

  AnimList = AnimNodeBlendList(SkelComp.FindAnimNode('BlendList'));

  super.PostInitAnimTree(SkelComp);
}
simulated event Destroyed() {
	super.Destroyed();

	BumpAnim = none;
	BounceAnim = none;
	SpawnAnim = none;
	AnimList = none;
}

/* ClientGotoState()
server uses this to force client into NewState
*/
simulated function ClientGotoState(name NewState, optional name NewLabel)
{
	if ((NewLabel == 'Begin' || NewLabel == '') && !IsInState(NewState))
	{
		GotoState(NewState);
	}
	else
	{
		GotoState(NewState,NewLabel);
	}
}

simulated event PostBeginPlay() {
	local PlayerController PC;
	local SFoodSpawn FS;
	// add to local HUD's post-rendered list
	ForEach LocalPlayerControllers(class'PlayerController', PC)
	{
		if ( PC.MyHUD != None )
		{
			//PC.MyHUD.AddPostRenderedActor(self);
		}
	}
	TotalFoodWeight = 0;
	foreach FoodSpawnList(FS) {
		TotalFoodWeight += Max(FS.SpawnWeight, 0);
	}
	//effectMat = effectMesh.CreateAndSetMaterialInstanceConstant(0);
	PlaySpawnFoodAnim();
}
simulated function PlaySpawnFoodAnim() {
	AnimList.SetActiveChild(2, 0);
	SpawnAnim.PlayAnim(false,1,0);
}
function SpawnFoodNotify() {
	if(Role == ROLE_Authority) {
		SpawnFood();
	}
}
simulated event OnAnimEnd(AnimNodeSequence SeqNode, float PlayedTime, float ExcessTime) {
	if(SeqNode.NodeName == 'SpawnAnim' && Role == ROLE_Authority) {
		RepForceByte++;
		bForceNetUpdate = true;
		PlaySpawnFoodAnim();
	} else {
		AnimList.SetActiveChild(2, 0);
	}
}
simulated event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal ) {
	if(Pawn(Other) != none) {
		if(HitNormal == vect3d(0,0,1)) {
			AnimList.SetActiveChild(1, 0);
			Pawn(Other).AddVelocity(vect3d(0,0,-2 * Other.Velocity.Z) , Location, class'DamageType');
		} else {
			AnimList.SetActiveChild(0, 0);
		}
	}
	super.Bump(Other, OtherComp, HitNormal);
}
function SpawnFood() {
	
	local Vector dir;
	local int i;
	local SFoodSpawn FS;
	local GWFoodActor foodActor;
	local Vector SocketLocation;
	local Rotator SocketRotator;
	local EFood FoodType;
	local int RandNum;

	//`Log("called SpawnFood");
	bulbMesh.GetSocketWorldLocationAndRotation('FoodPoint', SocketLocation, SocketRotator);
	//`Log(SocketLocation@vector(SocketRotator));
	for( i = 0; i < FoodNumToSpawn; i++) {
		FoodType = FOOD_NONE;
		do {
			RandNum = Rand(TotalFoodWeight);
			foreach FoodSpawnList(FS) {
				RandNum -= Max(FS.SpawnWeight, 0);
				if(RandNum < 0) {
					FoodType = FS.Type;
					break;
				}
			}
		} until(FoodType != FOOD_NONE);
		dir = VRand();
		
		foodActor = Spawn(class'GWFoodActor', self, , SocketLocation, RotRand(true), , );
		foodActor.Velocity = dir * 1000 + vect3d(0, 0, 1000);
		
		foodActor.Init(FoodType);
	}
}

defaultproperties
{
	bCollideActors=true
	bBlockActors=true
	bAlwaysRelevant=true
	FoodNumToSpawn=1

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		InvisibleUpdateTime=1
		MinTimeBetweenFullUpdates=.2
	End Object
	Components.Add(MyLightEnvironment)

	Begin Object Class=SkeletalMeshComponent Name=BulbMeshComp
		CollideActors=false
		BlockActors=false
		PhysicsWeight=0
		BlockRigidBody=false
		RBChannel=RBCC_Nothing
		RBCollideWithChannels=(Default=FALSE,GameplayPhysics=FALSE,EffectPhysics=FALSE,Cloth=TRUE)
		bUpdateSkelWhenNotRendered=true
		bAcceptsDynamicDecals=FALSE
		Translation=(X=0.0,Y=0.0,Z=-20.0)  // this is needed to make the flag line up with the flag base
		AnimTreeTemplate=AnimTree'G_P_FoodBulb.AnimTrees.AT_FoodBulb'
		AnimSets(0)=AnimSet'G_P_FoodBulb.AnimSets.AS_FoodBulb'
		SkeletalMesh=SkeletalMesh'G_P_FoodBulb.Mesh.SK_FoodBulb'
		LightEnvironment=MyLightEnvironment
		Scale=7.5
	End Object
	bulbMesh = BulbMeshComp
	Components.Add(BulbMeshComp)

	/*begin object class=StaticMeshComponent Name=EffectMeshComp
		CollideActors=false
		BlockActors=false
		BlockRigidBody=false
		CanBlockCamera=false
		RBChannel=RBCC_Nothing
		bAcceptsLights=false
		HiddenEditor=false
		HiddenGame=false
		CastShadow=false
		bCastDynamicShadow=false
		bCastStaticShadow=false
		bAcceptsDynamicLights=false
		RBCollideWithChannels=(Default=false,GameplayPhysics=false,EffectPhysics=false,Cloth=false)
		StaticMesh=StaticMesh'Grow_Volcano_test.Meshes.TreeEffect_mesh'
		Materials(0)=MaterialInstanceConstant'Grow_Volcano_test.Materials.TreeEffect_colour_Mat_INST'
	end object
	effectMesh = EffectMeshComp
	Components.Add(EffectMeshComp)

	begin object class=CylinderComponent name=TriggerField
		CollisionRadius=512
		CollisionHeight=256
		CollideActors=true
		BlockActors=false
		BlockRigidBody=false
		RBChannel=RBCC_Nothing
		RBCollideWithChannels=(Default=FALSE,GameplayPhysics=FALSE,EffectPhysics=FALSE,Cloth=TRUE)
		Translation=(X=0,Y=0,Z=150)
	end object

	activeRangeComp = TriggerField
	Components.Add(TriggerField)*/
	
	begin object class=CylinderComponent name=TreeCollision
		CollisionRadius=82.5
		CollisionHeight=60
		CollideActors=true
		BlockActors=true
		//BlockRigidBody=false
		//RBChannel=RBCC_Nothing
		//RBCollideWithChannels=(Default=FALSE,GameplayPhysics=FALSE,EffectPhysics=FALSE,Cloth=TRUE)
		//Translation=(X=0,Y=0,Z=50)
	end object

	Components.Add(TreeCollision)
	CollisionComponent=TreeCollision

	//growthSpeed = 1000
	//growthThreshold = 13333
	bPostRenderIfNotVisible = true
	bOnlyRelevantToOwner = false
	bGameRelevant = true
	bStatic=false
	bTickIsDisabled=false
	bHidden=false
	//NewStateName = Sprout
	NetUpdateFrequency=0.1
	RemoteRole=ROLE_SimulatedProxy
	//growthCount=99999
}