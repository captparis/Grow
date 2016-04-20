class GWPawn_PowerMax extends GWPawn;

var ParticleSystemComponent	LArmFlashPSC;
var array<ParticleSystem>			LArmFlashPSCTemplate;
var ParticleSystemComponent	RArmFlashPSC;
var array<ParticleSystem>			RArmFlashPSCTemplate;


/*var Name SkelControlLookAtName;
var SkelControlLookAt SkelControlLookAt;

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
  Super.PostInitAnimTree(SkelComp);

  if (SkelComp == Mesh)
  {
    SkelControlLookAt = SkelControlLookAt(Mesh.FindSkelControl('HeadLook'));
  }
}

simulated event Destroyed()
{
  Super.Destroyed();

  SkelControlLookAt = None;
}

simulated event Tick(float DeltaTime)
{
  local PlayerController PlayerController;

  Super.Tick(DeltaTime);

  if (SkelControlLookAt != None)
  {
    PlayerController = GetALocalPlayerController();

    if (PlayerController != None && PlayerController.Pawn != None && PlayerController != Controller)
    {
      SkelControlLookAt.TargetLocation = PlayerController.Pawn.Location + vect3d(0,0,1) * 50;
    } else {
		SkelControlLookAt.SetSkelControlActive(false);
    }
  }
}*/

simulated function AttachWeaponEffects() {
	super.AttachWeaponEffects();

	LArmFlashPSC = new(self) class'UTParticleSystemComponent';
	LArmFlashPSC.bAutoActivate = false;
	Mesh.AttachComponent(LArmFlashPSC, 'HAND_Left');
	RArmFlashPSC = new(self) class'UTParticleSystemComponent';
	RArmFlashPSC.bAutoActivate = false;
	Mesh.AttachComponent(RArmFlashPSC, 'HAND_Right');
}
simulated event DelayWeaponFired() {
	local int ArmToPlay;
	
	ArmToPlay = GWAnimNodeRandom(BodyAnimList.Children[BodyAnimList.ActiveChildIndex].Anim).ActiveChildIndex;
	if (LArmFlashPSC != none && ArmToPlay == 0) {
		if (!LArmFlashPSC.bIsActive) {
			if (LArmFlashPSCTemplate[0] != LArmFlashPSC.Template){
				LArmFlashPSC.SetTemplate(LArmFlashPSCTemplate[0]);
			}
			SetMuzzleFlashParams(LArmFlashPSC);
			LArmFlashPSC.ActivateSystem();
		}
	}
	if (RArmFlashPSC != none && ArmToPlay == 1) {
		if (!RArmFlashPSC.bIsActive) {
			if (RArmFlashPSCTemplate[0] != RArmFlashPSC.Template){
				RArmFlashPSC.SetTemplate(RArmFlashPSCTemplate[0]);
			}
			SetMuzzleFlashParams(RArmFlashPSC);
			RArmFlashPSC.ActivateSystem();
		}
	}
}
simulated function WeaponFired(Weapon InWeapon, bool bViaReplication, optional vector HitLocation) {

	if(FiringMode == 1) {
		
		//`Log(Instigator@"fired Muzzle Flash");

		if (MuzzleFlashPSC != none) {
			if ( !bMuzzleFlashPSCLoops || !MuzzleFlashPSC.bIsActive) {
				if (MuzzleFlashPSCTemplate[1] != MuzzleFlashPSC.Template){
					MuzzleFlashPSC.SetTemplate(MuzzleFlashPSCTemplate[1]);
				}
				SetMuzzleFlashParams(MuzzleFlashPSC);
				MuzzleFlashPSC.ActivateSystem();
			}
		}
		SetTimer(5,false,'MuzzleFlashTimer');
	} else {
		if(FiringMode == 0) {
			SetTimer(0.3, false, 'DelayWeaponFired');
		}
		super.WeaponFired(InWeapon, bViaReplication, HitLocation);
	}
}
simulated function WeaponStoppedFiring(Weapon InWeapon, bool bViaReplication)
{
	if(FiringMode == 1) {
		return;
	} else {
		if(FiringMode == 0) {
			ClearTimer('DelayWeaponFired');
			if (LArmFlashPSC != none) {
				LArmFlashPSC.DeactivateSystem();
			}
			if (RArmFlashPSC != none) {
				RArmFlashPSC.DeactivateSystem();
			}
		}
		super.WeaponStoppedFiring(InWeapon, bViaReplication);
	}
}
function PlayerAbilityMove(float DeltaTime, PlayerInput PInput) {
	PInput.aForward = 0;
	PInput.aStrafe = 0;
	PInput.aUp = 0;
	PlayerController(Controller).bPressedJump = false;
}
function ProcessAbilityViewRotation( float DeltaTime, out rotator out_ViewRotation, out Rotator out_DeltaRot ) {
	out_DeltaRot.Yaw = FClamp(out_DeltaRot.Yaw, -15 * DeltaTime * DegToUnrRot, 15 * DeltaTime * DegToUnrRot);
}
DefaultProperties
{
	Form = FORM_POWER_MAX
	CamOffset = (X=70,Y=0,Z=30)
	// Movement Speed
	GroundSpeed = 360
	AirSpeed = 300
	WaterSpeed = 320
	LadderSpeed = 300
	AccelRate = 2048

	// Damage Scaling
	DamageScaling = 1

	// Firing Rate
	
	// Max Health
	Health = 300
	HealthMax = 300
		
	// Swim?
	bCanSwim = false
	Buoyancy = 0.0
	WaterMovementState=PlayerWalking
	// Climb?
	bCanClimbLadders = false
	UnderWaterTime = 5f

	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'G_CH_Grumble.AnimTrees.AT_Grumble'
		AnimSets[0]=AnimSet'G_CH_Grumble.AnimSets.AS_Grumble'
		SkeletalMesh=SkeletalMesh'G_CH_Grumble.Mesh.SK_Grumble'
	End Object

	Begin Object Name=CollisionCylinder
		CollisionRadius=+85.000000
		CollisionHeight=+100.000000
	End Object
	DeathPartScale = 2
	Mass=+05000.000000

	begin object Name=HitBoxComp
		BoxExtent=(Y=101, Z=131, X=119)
		Translation=(Z=50, X=-31)
	end object
	HitBoxInfo=(Offset=(Z=50, X=-31),Radius=(Y=101, Z=131, X=119))

	begin object Name=BiteBoxComp
		BoxExtent=(X=200, Y=100, Z=150)
		Translation=(X=200, Z=50)
	end object

	TeamMaterials[0]=MaterialInstanceConstant'G_CH_Grumble.Materials.MI_Grumble_Creepy'
	TeamMaterials[1]=MaterialInstanceConstant'G_CH_Grumble.Materials.MI_Grumble_Cute'
	TeamMaterials[2]=MaterialInstanceConstant'G_CH_Grumble.Materials.MI_Grumble_Neutral'
	CharacterName = "Grumble"
	CharacterColour = (R=255,G=0,B=0,A=0)

	LArmFlashPSCTemplate[0]=ParticleSystem'G_FX_CH_Grumble.Effects.PS_Grumble_Swipe_Effect'
	RArmFlashPSCTemplate[0]=ParticleSystem'G_FX_CH_Grumble.Effects.PS_Grumble_Swipe_Effect'
	MuzzleFlashPSCTemplate[1]=ParticleSystem'Grow_Effects.Effects.Grumble_Vacuum_Attack'
	SoundGroupClass=class'GWSoundGroup_PowerMax'
}
