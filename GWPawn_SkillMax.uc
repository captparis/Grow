class GWPawn_SkillMax extends GWPawn;

function TakeDrowningDamage()
{
	BreathTime = 0;
	return;
}

DefaultProperties
{
	Form = FORM_SKILL_MAX
	CamOffset = (X=50,Y=0,Z=70)
	// Movement Speed
	GroundSpeed = 800
	AirSpeed = 600
	WaterSpeed = 1600
	LadderSpeed = 300
	AccelRate = 1600
	CustomGravityScaling=0.6
	Mass=+0100.000000
	JumpZ=800

	// Damage Scaling
	DamageScaling = 1

	// Firing Rate
	
	// Max Health
	Health = 150
	HealthMax = 150
		
	// Swim?
	bCanSwim = true
	Buoyancy = 1
	//WaterMovementState=PlayerSwimming
	// Climb?
	bCanClimbLadders = false

	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'G_CH_Bubbles.AnimTrees.AT_Bubbles'
		AnimSets[0]=AnimSet'G_CH_Bubbles.AnimSets.AS_Bubbles'
		SkeletalMesh=SkeletalMesh'G_CH_Bubbles.Mesh.SK_Bubbles'
	End Object

	Begin Object Name=CollisionCylinder
		CollisionRadius=+055.000000
		CollisionHeight=+051.000000
	End Object

	begin object Name=HitBoxComp
		BoxExtent=(Y=65, Z=64, X=70)
		Translation=(Z=25.5, X=3)
	end object
	HitBoxInfo=(Offset=(Z=25.5, X=3),Radius=(Y=65, Z=64, X=70))

	begin object Name=BiteBoxComp
		HiddenGame=true
	end object

	TeamMaterials[0]=MaterialInstanceConstant'G_CH_Bubbles.Materials.MI_Bubbles_Creepy'
	TeamMaterials[1]=MaterialInstanceConstant'G_CH_Bubbles.Materials.MI_Bubbles_Cute'
	TeamMaterials[2]=MaterialInstanceConstant'G_CH_Bubbles.Materials.MI_Bubbles_Neutral'
	CharacterName = "Bubbles"
	CharacterColour = (R=0,G=0,B=255,A=0)
	SoundGroupClass=class'GWSoundGroup_SkillMax'
}
