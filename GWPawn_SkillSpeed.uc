class GWPawn_SkillSpeed extends GWPawn;
var MaterialInterface FogMaterial[3];

function TakeDrowningDamage()
{
	BreathTime = 0;
	return;
}

DefaultProperties
{
	Form = FORM_SKILL_SPEED

	CamOffset = (X=35,Y=0,Z=45)

	// Movement Speed
	GroundSpeed = 800
	AirSpeed = 750
	WaterSpeed = 750
	LadderSpeed = 900
	AccelRate = 700
	Mass=+0200.000000

	// Damage Scaling
	DamageScaling = 1

	// Firing Rate
	
	// Max Health
	Health = 125
	HealthMax = 125
		
	// Swim?
	bCanSwim = true
	Buoyancy = 1.0
	//WaterMovementState=PlayerSwimming
	// Climb?
	bCanClimbLadders = true
	Begin Object Name=CollisionCylinder
		CollisionRadius=+026.65000
		CollisionHeight=+040.95000
	End Object

	begin object Name=HitBoxComp
		BoxExtent=(Y=26, Z=43, X=55)
		Translation=(Z=20, X=-3)
	end object
	HitBoxInfo=(Offset=(Z=20, X=-3),Radius=(Y=26, Z=43, X=55))

	begin object Name=BiteBoxComp
		HiddenGame=true
	end object

	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'G_CH_Toot.AnimTrees.AT_Toot'
		AnimSets[0]=AnimSet'G_CH_Toot.AnimSets.AS_Toot'
		SkeletalMesh=SkeletalMesh'G_CH_Toot.Mesh.SK_Toot'
		Scale3D=(X=0.65,Y=0.65,Z=0.65)
	End Object

	TeamMaterials[0]=MaterialInstanceConstant'G_CH_Toot.Materials.MI_Toot_Creepy'
	TeamMaterials[1]=MaterialInstanceConstant'G_CH_Toot.Materials.MI_Toot_Cute'
	TeamMaterials[2]=MaterialInstanceConstant'G_CH_Toot.Materials.MI_Toot_Neutral'

	FogMaterial[0]=MaterialInstanceTimeVarying'G_FX_CH_Toot.Materials.MITV_SmokeBomb_Creepy'
	FogMaterial[1]=MaterialInstanceTimeVarying'G_FX_CH_Toot.Materials.MITV_SmokeBomb_Cute'
	FogMaterial[2]=MaterialInstanceTimeVarying'G_FX_CH_Toot.Materials.MITV_SmokeBomb_Neutral'

	CharacterName = "Toot"
	CharacterColour = (R=0,G=255,B=186,A=0)
	SoundGroupClass=class'GWSoundGroup_SkillSpeed'
}
