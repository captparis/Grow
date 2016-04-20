class GWPawn_SpeedMax extends GWPawn;

var GWDecoy DecoyMesh;
var bool IsCloaked;

simulated function StatusEffectStart(EStatusEffects Stat, bool bViaReplication) {
	switch(Stat) {
	case EFFECT_DART_CLOAK:
		SetOpacity(0);
		IsCloaked = true;
		if(DecoyMesh != none) {
			DecoyMesh.Destroy();
		}
		if(Role == ROLE_Authority) {
			DecoyMesh = Spawn(class'GWDecoy', self, , Location, Rotation, ,true);
			if(DecoyMesh != none) {
				if(PlayerReplicationInfo != none && PlayerReplicationInfo.Team != none) {
					DecoyMesh.Init(TeamMaterials[PlayerReplicationInfo.Team.TeamIndex]);
				} else {
					DecoyMesh.Init(TeamMaterials[2]);
				}
			}
		}
		break;
	default:
		super.StatusEffectStart(Stat, bViaReplication);
	}
}
simulated function StatusEffectStop(EStatusEffects Stat, bool bViaReplication) {
	switch(Stat) {
	case EFFECT_DART_CLOAK:
		SetOpacity(1.0f);
		IsCloaked = false;
		if(DecoyMesh != none) {
			DecoyMesh.Destroy();
		}
		break;
	default:
		super.StatusEffectStop(Stat, bViaReplication);
	}
}
simulated event Destroyed() {
	Super.Destroyed();

	if(DecoyMesh != none) {
		DecoyMesh.Destroy();
	}
}
DefaultProperties
{
	Form = FORM_SPEED_MAX

	CamOffset = (X=50,Y=0,Z=80)
	// Movement Speed
	GroundSpeed = 1000
	AirSpeed = 900
	WaterSpeed = 700
	LadderSpeed = 1300
	AccelRate = 800
	MaxJumpHeight = 100.0
	MaxDoubleJumpHeight = 180.0
	Mass=+0250.000000
	JumpZ = 900
	// Damage Scaling
	DamageScaling = 1

	// Firing Rate
	
	// Max Health
	Health = 150
	HealthMax = 150
	
	// Swim?
	bCanSwim = false
	//Buoyancy = 1.5
	WaterMovementState=PlayerFloating
	// Climb?
	bCanClimbLadders = true

	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'G_CH_Dart.AnimTrees.AT_Dart'
		AnimSets[0]=AnimSet'G_CH_Dart.AnimSets.AS_Dart'
		SkeletalMesh=SkeletalMesh'G_CH_Dart.Mesh.SK_Dart'
		//Scale3D=(X=0.8,Y=0.8,Z=0.8)
		Translation=(Z=-61,X=-30)
	End Object

	Begin Object Name=CollisionCylinder
		CollisionRadius=+092.000000
		CollisionHeight=+060.000000
	End Object

	begin object Name=HitBoxComp
		BoxExtent=(Y=52, Z=70, X=117)
		Translation=(Z=15, X=0)
	end object
	HitBoxInfo=(Offset=(Z=15, X=0),Radius=(Y=52, Z=70, X=117))
	
	begin object Name=BiteBoxComp
		BoxExtent=(X=160, Y=50, Z=50)
		Translation=(X=160, Z=25)
	end object

	TeamMaterials[0]=MaterialInstanceConstant'G_CH_Dart.Materials.MI_Dart_Creepy'
	TeamMaterials[1]=MaterialInstanceConstant'G_CH_Dart.Materials.MI_Dart_Cute'
	TeamMaterials[2]=MaterialInstanceConstant'G_CH_Dart.Materials.MI_Dart_Neutral'
	TeamExtraMaterials[0]=MaterialInstanceConstant'G_CH_Dart.Materials.MI_Dart_Cloak_Creepy'
	TeamExtraMaterials[1]=MaterialInstanceConstant'G_CH_Dart.Materials.MI_Dart_Cloak_Cute'
	TeamExtraMaterials[2]=MaterialInstanceConstant'G_CH_Dart.Materials.MI_Dart_Cloak_Neutral'
	CharacterName = "Dart"
	CharacterColour = (R=255,G=255,B=0,A=0)

	MuzzleFlashPSCTemplate[0]=ParticleSystem'Grow_Effects.Effects.Headbutt'
	MuzzleFlashPSCTemplate[6]=ParticleSystem'Grow_John_Assets.Effects.Dart_Crit_Strike'
	SoundGroupClass=class'GWSoundGroup_SpeedMax'
}
