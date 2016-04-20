class GWDecoy extends Pawn;

var repnotify MaterialInterface RepMat;

replication {
	if(bNetInitial)
		RepMat;
}
simulated event ReplicatedEvent(name VarName)
{
	if ( VarName == 'RepMat') {
		Init(RepMat);
	}
	super.ReplicatedEvent(VarName);
}

simulated function Init(MaterialInterface Mat) {
	if(Role == ROLE_Authority)
		RepMat = Mat;
	Mesh.SetMaterial(0, Mat);
}
DefaultProperties
{
	//RemoteRole=ROLE_None
	LifeSpan=10

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		InvisibleUpdateTime=1
		MinTimeBetweenFullUpdates=.2
	End Object
	Components.Add(MyLightEnvironment)

	Begin Object Class=SkeletalMeshComponent Name=DecoySkeletalMeshComponent
		bCacheAnimSequenceNodes=FALSE
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		CastShadow=true
		BlockRigidBody=false
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		RBChannel=RBCC_Untitled3
		RBCollideWithChannels=(Untitled3=true)
		LightEnvironment=MyLightEnvironment
		bAcceptsDynamicDecals=FALSE
		TickGroup=TG_PreAsyncWork
		MinDistFactorForKinematicUpdate=0.2
		bChartDistanceFactor=true
		//bSkipAllUpdateWhenPhysicsAsleep=TRUE
		RBDominanceGroup=20
		// Nice lighting for hair
		bUseOnePassLightingOnTranslucency=TRUE
		bPerBoneMotionBlur=true

		Translation=(X=0,Y=0,Z=0)
		Scale=0.8
		bOnlyOwnerSee=false
		bOwnerNoSee=false
		bHasPhysicsAssetInstance=false
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bOverrideAttachmentOwnerVisibility=true
		SkeletalMesh=SkeletalMesh'G_CH_Dart.Mesh.SK_Dart'
		AnimSets[0]=AnimSet'G_CH_Dart.AnimSets.AS_Dart'
		AnimTreeTemplate=AnimTree'G_CH_Dart.AnimTrees.AT_Dart_Decoy'
	End Object
	Mesh=DecoySkeletalMeshComponent
	Components.Add(DecoySkeletalMeshComponent)
	Physics=PHYS_Falling
	Begin Object Name=CollisionCylinder
		CollisionRadius=+050.000000
		CollisionHeight=+030.000000
	End Object
}
