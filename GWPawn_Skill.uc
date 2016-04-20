class GWPawn_Skill extends GWPawn;
//var AnimNodeSequence Node;

function TakeDrowningDamage()
{
	BreathTime = 0;
	return;
}
simulated event Tick(float DeltaTime) {
	local Rotator POVRot;
	local Vector POVVec;

	if(FiringMode == 0 && FlashCount != 0) {
		POVRot = GetBaseAimRotation();
		POVRot.Roll = 0;
		POVRot.Yaw = 0;
		POVVec = Vector(POVRot);

		MuzzleFlashPSC.SetVectorParameter('PawnViewPitch', POVVec);
	}
	super.Tick(DeltaTime);
}
simulated function IncrementFlashCount(Weapon InWeapon, byte InFiringMode)
{
	bForceNetUpdate = TRUE;	// Force replication
	if(InFiringMode == 1)
		FlashCount = GWWeap(InWeapon).AmmoCount / float(GWWeap(InWeapon).MaxAmmoCount);
	else
		FlashCount++;

	// Make sure it's not 0, because it means the weapon stopped firing!
	if( FlashCount == 0 )
	{
		FlashCount += 2;
	}
	// Make sure firing mode is updated
	SetFiringMode(InWeapon, InFiringMode);

	// This weapon has fired.
	FlashCountUpdated(InWeapon, FlashCount, FALSE);
}
simulated function SetMuzzleFlashParams(ParticleSystemComponent PSC)
{
	if(FiringMode == 1)
	PSC.SetFloatParameter('SplashScale', FlashCount);
}

/*simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp) {
	Node = AnimNodeSequence(SkelComp.FindAnimNode('Slide1'));
}
exec function PlaySlide()
{
   // Play Jump animation
   Node.SetAnim('Newt');
   Node.PlayAnim(true, 1.f);

   // Turn on Root Motion on Animation node
   Node.SetRootBoneAxisOption(RBA_Translate,RBA_Translate,RBA_Translate);

   // Tell animation node to notify actor when animation is done playing
  // Node.bCauseActorAnimEnd = TRUE;

   // Tell mesh to use Root Motion to translate the actor
   Mesh.RootMotionMode = RMM_Accel;

   // Tell mesh to notify us when root motion will be applied,
   // so we can seamlessly transition from physics movement to animation movement
   Mesh.bRootMotionModeChangeNotify = TRUE;
}

simulated event RootMotionModeChanged(SkeletalMeshComponent SkelComp)
{
   /**
    * Root motion will kick-in on next frame.
    * So we can kill Pawn movement, and let root motion take over.
    */
   if( SkelComp.RootMotionMode == RMM_Translate )
   {
      Velocity = Vect(0.f, 0.f, 0.f);
      Acceleration = Vect(0.f, 0.f, 0.f);
   }

   // Disable notification
   Mesh.bRootMotionModeChangeNotify = false;
}

simulated event OnAnimEnd(AnimNodeSequence SeqNode, float PlayedTime, float ExcessTime)
{
   // Finished Jumping
   
   // Discard root motion. So mesh stays locked in place.
   // We need this to properly blend out to another animation
	Node.SetRootBoneAxisOption(RBA_Discard,RBA_Discard,RBA_Discard);

   // Tell mesh to stop using root motion
   Mesh.RootMotionMode = RMM_Ignore;
}*/
DefaultProperties
{
	Form = FORM_SKILL
	CamOffset = (X=50,Y=0,Z=100)

	// Movement Speed
	GroundSpeed = 800
	AirSpeed = 750
	WaterSpeed = 1400
	LadderSpeed = 300
	AccelRate = 1400
	MaxJumpHeight = 65.0
	MaxDoubleJumpHeight = 117.0
	Mass=+0200.000000
	JumpZ = 900
	//CustomGravityScaling=0.3
	

	// Damage Scaling
	DamageScaling = 1

	// Firing Rate
	
	// Max Health
	Health = 150
	HealthMax = 150
		
	// Swim?
	bCanSwim = true
	Buoyancy = 1f

	//WaterMovementState=PlayerSwimming
	// Climb?
	bCanClimbLadders = false

	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'G_CH_Newt.AnimTrees.AT_Newt'
		AnimSets[0]=AnimSet'G_CH_Newt.AnimSets.AS_Newt'
		SkeletalMesh=SkeletalMesh'G_CH_Newt.Mesh.SK_Newt'
		Scale=0.7
	End Object

	Begin Object Name=CollisionCylinder
		CollisionRadius=+055.00000
		CollisionHeight=+035.000000
	End Object

	begin object Name=HitBoxComp
		BoxExtent=(Y=50, Z=56, X=70)
		Translation=(Z=14, X=-3)
	end object
	HitBoxInfo=(Offset=(Z=14, X=-3),Radius=(Y=50, Z=56, X=70))

	begin object Name=BiteBoxComp
		HiddenGame=true
	end object

	TeamMaterials[0]=MaterialInstanceConstant'G_CH_Newt.Materials.MI_Newt_Creepy'
	TeamMaterials[1]=MaterialInstanceConstant'G_CH_Newt.Materials.MI_Newt_Cute'
	TeamMaterials[2]=MaterialInstanceConstant'G_CH_Newt.Materials.MI_Newt_Neutral'
	CharacterName = "Newt"
	CharacterColour = (R=0,G=186,B=255,A=0)

	MuzzleFlashPSCTemplate[1]=ParticleSystem'Grow_John_Assets.Effects.Conv_New_Current'
	//MuzzleFlashPSCTemplate[0]=ParticleSystem'Grow_John_Assets.Effects.Water_effect_Thin'
	SoundGroupClass=class'GWSoundGroup_Skill'
}
