class GWPawn extends UTPawn
	dependson(GWConstants)
	config(Grow)
	abstract;

var config Vector CameraOffset;
var int Speed;
var int Skill;
var int Power;
var bool bShielded;
var bool bLockGrow;
var ParticleSystemComponent StunPart;
var ParticleSystemComponent EatPart;
var ParticleSystemComponent StinkPart;
var ParticleSystemComponent BurnPart;
var string CharacterName;
var Color CharacterColour;
var Name lastState;
var int LastSpeed;
var float LastSpeedTick;

var float PowerCharge, SpeedCharge, SkillCharge, GrowCharge, DevolveCharge;
var repnotify byte ReplicatedGrowCharge, ReplicatedDevolveCharge;
var int GrowType;
var int Size;
var bool bCanFlinch;
var() SkeletalMeshComponent HatSkeletalMesh;
//var protected SkeletalMeshComponent OverlayTest;
//var UDKSkeletalMeshComponent FaceCam;
var DrawBoxComponent HitBox;
struct SPawnHitBoxes {
	var Vector Offset;
	var Vector Radius;
};
var SPawnHitBoxes HitBoxInfo;
var DrawBoxComponent BiteBox;

enum EAnim {
	ANIM_NONE,
	ANIM_DEATH, ANIM_ATTACK, ANIM_ABILITY_START, ANIM_ABILITY_LOOP,
	ANIM_ABILITY_HIT, ANIM_ABILITY_END, ANIM_EAT, ANIM_FOOD_HOLD,
	ANIM_CHEW, ANIM_SPEW, ANIM_SPIT, ANIM_FLINCH, ANIM_STUN
};
struct RepAnim {
	var EAnim Type;
	var byte Id;
};

/*enum EStat {
	STAT_HP, STAT_GSPEED, STAT_ASPEED, STAT_WSPEED, STAT_LSPEED, STAT_DAMAGE
};*/

/*struct RepStat {
	var EStat Type;
	var name Pawn
*/

// declare the var with repnotify so it replicates to all clients
var repnotify RepAnim AnimRep;
var byte AnimRepLastAnim;
var repnotify int TriggerOpacity;
var MaterialInterface TeamMaterials[3];
var MaterialInterface TeamExtraMaterials[3];
var repnotify EFood CurrentEatenFoodType;
var StaticMeshComponent CurrentEatenFoodMesh;
var bool HoldingFood;
var repnotify byte StatusEffects[EStatusEffects];
var byte OldStatusEffects[EStatusEffects];
var Controller StatusEffectsCausedBy[EStatusEffects];

replication
{
	if ( bNetOwner && bNetDirty )
		Speed, Skill, Power;
	if(bNetDirty)
		AnimRep, TriggerOpacity, CurrentEatenFoodType;
	if(Role > ROLE_SimulatedProxy)
		ReplicatedGrowCharge, ReplicatedDevolveCharge;
	if( ( Role == Role_Authority ) && bNetDirty )
		StatusEffects;
}

var EForm Form;

/**
 * Animation
 */

var byte AnimHeadOnly[EAnim];
var byte AnimExists[EAnim];
var GWAnimBlendByAction BodyAnimList;
var GWAnimBlendByAction HeadAnimList;
var AnimNodeBlendPerBone AnimHeadBlend;
//var array<GWAnimBlendByFall> JumpAnimNodes; 

/**
 * Particle Systems
 */

var ParticleSystemComponent	MuzzleFlashPSC;
var array<ParticleSystem>			MuzzleFlashPSCTemplate;
var bool					bMuzzleFlashPSCLoops;
var float					MuzzleFlashDuration;

var ParticleSystemComponent AttackPart;
var ParticleSystemComponent AbilityPart;
var ParticleSystemComponent GrowPart;
var float DeathPartScale;

var SceneCapture2DComponent	FaceCam;
var TextureRenderTarget2D CharacterPortraitRT;
var Texture FaceCamCharacterPicture;

var Pawn BasedPawn;

var bool bLongIdle;
var float fIdleTime;
var float fWaterSurfaceZ;

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp) {
	local GWAnimBlendByAction node;
	//local GWAnimBlendByFall Jnode;
	local int i;

	foreach SkelComp.AllAnimNodes(class'GWAnimBlendByAction', node) {
		if(BodyAnimList == none) {
			BodyAnimList = node;
		} else {
			HeadAnimList = node;
		}
	}

	for(i = 0; i < ANIM_MAX; i++) {
		if(BodyAnimList.Children[i].Anim != none) {
			AnimExists[i] = 1;
		} else if(HeadAnimList.Children[i].Anim != none) {
			AnimHeadOnly[i] = 1;
			AnimExists[i] = 1;
		}
	}
	AnimHeadBlend = AnimNodeBlendPerBone(SkelComp.FindAnimNode('HeadAnim'));
	//foreach SkelComp.AllAnimNodes(class'GWAnimBlendByFall', Jnode) {
	//	JumpAnimNodes.AddItem(Jnode);
	//}
}
function PossessedBy(Controller C, bool bVehicleTransition)
{
	Super.PossessedBy(C, bVehicleTransition);
	/*if(IsLocallyControlled()) {
		`Log("Server Possessed");
		if(GWGFxHudWrapper(GWPlayerController(C).myHUD) != none) {
			GWGFxHudWrapper(GWPlayerController(C).myHUD).HudMovie.ClearStats();
		}
	} else {
		GWPlayerController(C).SetCameraMode('ThirdPerson');
		RefreshFaceCam();
	}*/
	//`Log("Hat Index:"@GWPlayerReplicationInfo(PlayerReplicationInfo).HatIndex);
	GWPlayerReplicationInfo(PlayerReplicationInfo).ReplicatedEvent('HatIndex');
}
/*exec function RefreshFaceCam()
{
	if(GWGFxHudWrapper(GWPlayerController(Controller).myHUD) != none) {
		GWGFxHudWrapper(GWPlayerController(Controller).myHUD).HudMovie.InitCam(self, MakeColor(255,255,0));
	}
}*/
function PlayTeleportEffect(bool bOut, bool bSound)
{
	Super(Actor).PlayTeleportEffect( bOut, bSound );
}

/**The Pawn has entered a new PhsyicsVolume
 * 
 * @param   NewVolume  the entered volume
 */
event PhysicsVolumeChange( PhysicsVolume NewVolume) {
	local BrushComponent BC;
	super.PhysicsVolumeChange(NewVolume);

	//in case the volume is a WaterVolume, update the surface value
	if(NewVolume.bWaterVolume) {
		BC = NewVolume.BrushComponent;
		fWaterSurfaceZ = BC.Bounds.Origin.Z + BC.Bounds.BoxExtent.Z - (0.2 * GetCollisionHeight());
	}
}

simulated function name GetDefaultCameraMode( PlayerController RequestedBy )
{
	if ( RequestedBy != None && RequestedBy.PlayerCamera != None && RequestedBy.PlayerCamera.CameraStyle == 'Fixed' )
		return 'Fixed';

	return 'ThirdPerson';
}
function float ModifySpeed(optional float Multiplier) {
	
	if(Multiplier == 0) {
		Multiplier = 1;
	}
	if(StatusEffects[EFFECT_SCAMPER_BOOST] > 0) {
		Multiplier *= class'GWWeap_Speed'.default.AbilityMultiplier;
	}
	if(StatusEffects[EFFECT_SCAMPER_STINK] > 0) {
		Multiplier *= 0.5;
	}
	if(StatusEffects[EFFECT_NOM_FRENZY] > 0) {
		Multiplier *= 1.25;
	}
	if(StatusEffects[EFFECT_POKEY_CHARGE] > 0) {
		Multiplier *= 3;
	}
	GroundSpeed = Multiplier * default.GroundSpeed;
	AirSpeed = Multiplier * default.AirSpeed;
	WaterSpeed = Multiplier * default.WaterSpeed;
	LadderSpeed = Multiplier * default.LadderSpeed;
	AccelRate = Multiplier * default.AccelRate;

	return Multiplier;
}
simulated function NotifyTeamChanged()
{
	local UTPlayerReplicationInfo PRI;

	// set mesh to the one in the PRI, or default for this team if not found
	PRI = GetUTPlayerReplicationInfo();

	if (PRI != None)
	{
		SetCharacterClassFromInfo(GetFamilyInfo());

		if (WorldInfo.NetMode != NM_DedicatedServer)
		{
			// refresh weapon attachment
			if (CurrentWeaponAttachmentClass != None)
			{
				// recreate weapon attachment in case the socket on the new mesh is in a different place
				if (CurrentWeaponAttachment != None)
				{
					CurrentWeaponAttachment.DetachFrom(Mesh);
					CurrentWeaponAttachment.Destroy();
					CurrentWeaponAttachment = None;
				}
				WeaponAttachmentChanged();
			}
			// refresh overlay
			if (OverlayMaterialInstance != None)
			{
				SetOverlayMaterial(OverlayMaterialInstance);
			}
		}

		// Reset physics state.
		bIsHoverboardAnimPawn = FALSE;
		ResetCharPhysState();
		//`Log("Hat Index:"@GWPlayerReplicationInfo(PlayerReplicationInfo).HatIndex);
		GWPlayerReplicationInfo(PlayerReplicationInfo).ReplicatedEvent('HatIndex');
	}

	if (!bReceivedValidTeam)
	{
		SetTeamColor();
		bReceivedValidTeam = (GetTeam() != None);
	}
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	if(IsHumanControlled()) {
		CamOffset = CameraOffset;
	}
	if(WorldInfo.NetMode != NM_DedicatedServer) {
		AttachWeaponEffects();
		//if(IsLocallyControlled()) {
		//	CreateFaceCam();
		//}
	}
}

simulated function CreateFaceCam() {
	`Log("CreateFaceCam");
	if(GWPlayerController(Controller).UseAnimatedProfile) {
		//if(Mesh.GetSocketByName('FaceCam') != none) {
		FaceCam = new class'SceneCapture2DComponent';

		FaceCam.ClearColor = CharacterColour;
		GWGFxHudWrapper(GWPlayerController(Controller).myHUD).HudMovie.SetExternalTexture("characterportrait",CharacterPortraitRT);
		FaceCam.SetCaptureParameters(CharacterPortraitRT,40,1,100);
		FaceCam.SetEnabled(true);
		Mesh.AttachComponentToSocket(FaceCam,'FaceCam');
		//}
	} else {
		GWGFxHudWrapper(GWPlayerController(Controller).myHUD).HudMovie.SetExternalTexture("characterportrait",FaceCamCharacterPicture);
	}
}
simulated function AttachWeaponEffects() {
	if(Mesh.GetSocketByName('FoodPoint') != none) {
		Mesh.AttachComponentToSocket(CurrentEatenFoodMesh, 'FoodPoint');
		Mesh.AttachComponentToSocket(EatPart, 'FoodPoint');
	} else if(Mesh.GetSocketByName('WeaponPoint') != none) {
		Mesh.AttachComponentToSocket(CurrentEatenFoodMesh, 'WeaponPoint');
		Mesh.AttachComponentToSocket(EatPart, 'WeaponPoint');
	}
	if(Mesh.GetSocketByName('HatPoint') != none) {
		`Log("Attaching hat");
		Mesh.AttachComponentToSocket(HatSkeletalMesh, 'HatPoint');
	} else {
		`Log("No Hat point found");
	}
	//GWPlayerReplicationInfo(PlayerReplicationInfo).ReplicatedEvent('HatIndex');
	if (WeaponSocket != '') {
		MuzzleFlashPSC = new(self) class'UTParticleSystemComponent';
		MuzzleFlashPSC.bAutoActivate = false;
		//MuzzleFlashPSC.SetOwnerNoSee(false);
		if(Mesh.GetSocketByName(WeaponSocket) != none) {
			Mesh.AttachComponentToSocket(MuzzleFlashPSC, WeaponSocket);
		} else {
			AttachComponent(MuzzleFlashPSC);
		}
	}
}
/*simulated function CreateOverlayTest()
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		OverlayTest = new(self) Mesh.Class;
		OverlayTest.SetScale(2.00);
		OverlayTest.SetSkeletalMesh(Mesh.SkeletalMesh);
		OverlayTest.SetOwnerNoSee(false);
		OverlayTest.SetOnlyOwnerSee(false);
		OverlayTest.AnimSets = Mesh.AnimSets;
		OverlayTest.SetParentAnimComponent(Mesh);
		OverlayTest.bUpdateSkelWhenNotRendered = false;
		OverlayTest.bIgnoreControllersWhenNotRendered = true;
		OverlayTest.bOverrideAttachmentOwnerVisibility = true;

		if (UDKSkeletalMeshComponent(OverlayTest) != none)
		{
			UDKSkeletalMeshComponent(OverlayTest).SetFOV(UDKSkeletalMeshComponent(Mesh).FOV);
		}
		AttachComponent(OverlayTest);
		OverlayTest.SetRotation(MakeRotator(0, 180 * DegToUnrRot, 0));
		OverlayTest.SetTranslation(vect3d(0, 0, 50));
	}
}*/

event TakeDamage(int Damage, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser) {
	local class<GWDamageType> GWD;

	GWD = class<GWDamageType>(DamageType);

	if(GWD != none) {

		if(GWD.default.IgnoreTeamMates && (EventInstigator != none && IsTeamMate(EventInstigator.Pawn))) {
			return;
		}

		if(EventInstigator != Controller && Role == ROLE_Authority &&
			GWD.default.CausesFlinch && bCanFlinch &&
			(EventInstigator == none || IsEnemyTeam(EventInstigator.Pawn))) {
			//GWPlayerController(Controller).ServerFlinch();
		}
		if(GWD.default.IgnorePawnMass) {
			Momentum *= Mass;
		}
	}
	super.TakeDamage(Damage, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}
function TakeDrowningDamage()
{
	TakeDamage(5, None, Location + GetCollisionHeight() * vect(0,0,0.5)+ 0.7 * GetCollisionRadius() * vector(Controller.Rotation), vect(0,0,0), class'GWDmgType_Drowned');
}
/** CrushedBy()
Called for pawns that have bCanBeBaseForPawns=false when another pawn becomes based on them
*/
function CrushedBy(Pawn OtherPawn)
{
	TakeDamage( (1-OtherPawn.Velocity.Z/400)* OtherPawn.Mass/Mass, OtherPawn.Controller,Location, vect(0,0,0) , class'GWDmgType_Crushed');
}
function AddDefaultInventory()
{
	switch(Form) {
	case FORM_BABY:
		CreateInventory(class'GWWeap_Baby', false);
		break;
	case FORM_POWER:
		CreateInventory(class'GWWeap_Power', false);
		break;
	case FORM_SKILL:
		CreateInventory(class'GWWeap_Beam', false);
		//CreateInventory(class'UTWeap_LinkGun', false);
		break;
	case FORM_SPEED:
		CreateInventory(class'GWWeap_Speed', false);
		break;
	case FORM_POWER_MAX:
		CreateInventory(class'GWWeap_PowerMax', false);
		break;
	case FORM_SKILL_MAX:
		CreateInventory(class'GWWeap_SkillMax', false);
		break;
	case FORM_SKILL_POWER:
		CreateInventory(class'GWWeap_SkillPower', false);
		break;
	case FORM_SKILL_SPEED:
		CreateInventory(class'GWWeap_SkillSpeed', false);
		break;
	case FORM_SPEED_MAX:
		CreateInventory(class'GWWeap_SpeedMax', false);
		break;
	case FORM_SPEED_POWER:
		CreateInventory(class'GWWeap_SpeedPower', false);
		break;
	default:
		`Log("Error: No Character Type Selected");
	}
	Controller.ClientSwitchToBestWeapon();
}
simulated function AnimNodeSequence GetAnimNode(int AnimNum, optional AnimNodeSequence TestNode) {
	local AnimNode WorkingNode;
	
	if(bool(AnimExists[AnimNum])) {
		/* Check if wanted node is a direct child or if not, get the child */
		if(bool(AnimHeadOnly[AnimNum])) {
			if(AnimNodeSequence(HeadAnimList.Children[AnimNum].Anim) != none) {
				return AnimNodeSequence(HeadAnimList.Children[AnimNum].Anim);
			}
			WorkingNode = HeadAnimList.Children[AnimNum].Anim;
		} else {
			if(AnimNodeSequence(BodyAnimList.Children[AnimNum].Anim) != none) {
				return AnimNodeSequence(BodyAnimList.Children[AnimNum].Anim);
			}
			WorkingNode = BodyAnimList.Children[AnimNum].Anim;
		}
		/* Iterate through the animations to try and find the right node */
		while(true) {
			if(WorkingNode == none) {
				return none;
			} else if(AnimNodeBlendPerBone(WorkingNode) != none) {
				WorkingNode = AnimNodeBlendPerBone(WorkingNode).Children[1].Anim;
			} else if(AnimNodeBlendList(WorkingNode) != none) {
				WorkingNode = AnimNodeBlendList(WorkingNode).Children[AnimNodeBlendList(WorkingNode).ActiveChildIndex].Anim;
			} else if(AnimNodeBlendBase(WorkingNode) != none) {
				WorkingNode = AnimNodeBlendBase(WorkingNode).Children[0].Anim;
			} else if(AnimNodeSequence(WorkingNode) != none) {
				return AnimNodeSequence(WorkingNode);
			} else {
				return none;
			}
		}
	} else {
		return none;
	}
}
simulated event OnAnimEnd(AnimNodeSequence SeqNode, float PlayedTime, float ExcessTime) {
	`Log(self@"Called"@GetFuncName()@"with"@SeqNode.AnimSeqName,,'DevAnim');
	switch(SeqNode) {
	case GetAnimNode(1):
		StopDeathAnimation();
		break;
	case GetAnimNode(2):
		StopAttackAnimation();
		break;
	case GetAnimNode(3):
		StopAbilityStartAnimation();
		break;
	case GetAnimNode(4):
		StopAbilityLoopAnimation();
		break;
	case GetAnimNode(5):
		StopAbilityHitAnimation();
		break;
	case GetAnimNode(6):
		StopAbilityEndAnimation();
		return;
		break;
	case GetAnimNode(7):
		StopEatAnimation();
		break;
	case GetAnimNode(8):
		StopFoodHoldAnimation();
		break;
	case GetAnimNode(9):
		StopChewAnimation();
		break;
	case GetAnimNode(10):
		StopSpitAnimation();
		break;
	/*case GetAnimNode(11):
		StopSpewAnimation();
		break;*/
	case GetAnimNode(12):
		StopFlinchAnimation();
		break;
	/*case GetAnimNode(13, SeqNode):
		StopStunAnimation();
		break;*/
	}
	super.OnAnimEnd(SeqNode, PlayedTime, ExcessTime);
}

simulated event Destroyed() {
	Super.Destroyed();

	BodyAnimList = none;
 	HeadAnimList = none;
	AnimHeadBlend = none;
	BiteBox = none;
	HitBox = none;
	FaceCam = none;
}

simulated function PlayFeignDeath() {}

/*function bool Dodge(eDoubleClickDir DoubleClickMove)
{
	return false;
}*/
function bool CanDoubleJump()
{
	if(Form == FORM_SPEED) {
		return super.CanDoubleJump();
	} else {
		return false;
	}
}

function bool DoJump( bool bUpdating )
{
	//local GWAnimBlendByFall node;
	// This extra jump allows a jumping or dodging pawn to jump again mid-air
	// (via thrusters). The pawn must be within +/- DoubleJumpThreshold velocity units of the
	// apex of the jump to do this special move.
	if ( !bUpdating && CanDoubleJump()&& IsLocallyControlled() )
	{
		if ( PlayerController(Controller) != None )
			PlayerController(Controller).bDoubleJump = true;
		DoDoubleJump(bUpdating);
		MultiJumpRemaining -= 1;
		//foreach JumpAnimNodes(node) {
		//	node.FallState = BF_DBL_Up;
		//}
		return true;
	}

	if (bJumpCapable && !bIsCrouched && !bWantsToCrouch && (Physics == PHYS_Walking || Physics == PHYS_Ladder || Physics == PHYS_Spider))
	{
		if ( Physics == PHYS_Spider )
			Velocity = JumpZ * Floor;
		else if ( Physics == PHYS_Ladder )
			Velocity.Z = 0;
		else if ( bIsWalking )
			Velocity.Z = Default.JumpZ;
		else
			Velocity.Z = JumpZ;
		if (Base != None && !Base.bWorldGeometry && Base.Velocity.Z > 0.f)
		{
			if ( (WorldInfo.WorldGravityZ != WorldInfo.DefaultGravityZ) && (GetGravityZ() == WorldInfo.WorldGravityZ) )
			{
				Velocity.Z += Base.Velocity.Z * sqrt(GetGravityZ()/WorldInfo.DefaultGravityZ);
			}
			else
			{
				Velocity.Z += Base.Velocity.Z;
			}
		}
		SetPhysics(PHYS_Falling);
		bReadyToDoubleJump = true;
		bDodging = false;
		//foreach JumpAnimNodes(node) {
		//	node.FallState = BF_Up;
		//}
		if ( !bUpdating )
			PlayJumpingSound();
		return true;
	}
	return false;
}

/**
* Attach GameObject to mesh.
* @param GameObj : Game object to hold
*/
simulated event HoldGameObject(UDKCarriedObject GameObj)
{
	local UTCarriedObject UTGameObj;

	UTGameObj = UTCarriedObject(GameObj);
	UTGameObj.SetHardAttach(UTGameObj.default.bHardAttach);
	UTGameObj.bIgnoreBaseRotation = UTGameObj.default.bIgnoreBaseRotation;

	if ( class'Engine'.static.IsSplitScreen() )
	{
		if ( UTGameObj.GameObjBone3P != '' )
		{
			//`Log("Split:"@UTGameObj.GameObjBone3P);
			UTGameObj.SetBase(self,,Mesh,UTGameObj.GameObjBone3P);
		}
		else
		{
			UTGameObj.SetBase(self);
		}
		//UTGameObj.SetRelativeRotation(UTGameObj.GameObjRot3P);
		//UTGameObj.SetRelativeLocation(UTGameObj.GameObjOffset3P);
	}
	else if (IsFirstPerson())
	{
		//`Log("First Person");
		UTGameObj.SetBase(self);
		UTGameObj.SetRelativeRotation(UTGameObj.GameObjRot1P);
		UTGameObj.SetRelativeLocation(UTGameObj.GameObjOffset1P);
	}
	else
	{
		if ( UTGameObj.GameObjBone3P != '' )
		{
			//`Log("Third:"@UTGameObj.GameObjBone3P);
			UTGameObj.SetBase(self,,Mesh,UTGameObj.GameObjBone3P);
		}
		else
		{
			UTGameObj.SetBase(self);
		}
		//UTGameObj.SetRelativeRotation(UTGameObj.GameObjRot3P);
		//UTGameObj.SetRelativeLocation(UTGameObj.GameObjOffset3P);
	}
}

simulated function FaceRotation(rotator NewRotation, float DeltaTime)
{
	switch (Form) {
	case FORM_BABY:
	case FORM_POWER:
	case FORM_POWER_MAX:
	case FORM_SPEED:
	case FORM_SPEED_MAX:
	case FORM_SPEED_POWER:
		if ( Physics == PHYS_Ladder )
		{
			NewRotation = OnLadder.Walldir;
			NewRotation.Pitch = DegToUnrRot * 90;
		} else {
			NewRotation.Pitch = 0;
			NewRotation.Roll = Rotation.Roll;
		}
		break;
	case FORM_SKILL:
	case FORM_SKILL_MAX:
	case FORM_SKILL_POWER:
	case FORM_SKILL_SPEED:
		if ( (Physics == PHYS_Walking) || (Physics == PHYS_Falling)) {
			NewRotation.Pitch = 0;
		}
		NewRotation.Roll = Rotation.Roll;
		break;
	}
	SetRotation(NewRotation); // #TASK SetRotation(NewRotation);
}

function AttackBoostEnd() {
	DamageScaling = default.DamageScaling;
	if(Role == ROLE_Authority) {
		ClearStatusEffect(EFFECT_BUBBLES_AEGIS);
	}
}

function PlayerAbilityMove(float DeltaTime, PlayerInput PInput) {}

function ProcessAbilityViewRotation( float DeltaTime, out rotator out_ViewRotation, out Rotator out_DeltaRot ) {}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	if(Role == ROLE_Authority)
		TriggerAnim(ANIM_DEATH);
	super(Pawn).PlayDying(DamageType, HitLoc);
}
State Dying
{
ignores Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling, BreathTimer, FellOutOfWorld;

	simulated function PlayWeaponSwitch(Weapon OldWeapon, Weapon NewWeapon) {}
	simulated function PlayNextAnimation() {}
	simulated singular event BaseChange() {}
	simulated event Landed(vector HitNormal, Actor FloorActor) {}

	simulated function bool Died(Controller Killer, class<DamageType> damageType, vector HitLocation);

	  simulated singular event OutsideWorldBounds()
	  {
		  SetPhysics(PHYS_None);
		  SetHidden(True);
		  LifeSpan = FMin(LifeSpan, 1.0);
	  }

	simulated event Timer()
	{
		if ( !PlayerCanSeeMe() )
		{
			Destroy();
		}
		else
		{
			SetTimer(2.0, false);
		}
	}

	simulated event TakeDamage(int Damage, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		SetPhysics(PHYS_Falling);

		if ( (Physics == PHYS_None) && (Momentum.Z < 0) )
			Momentum.Z *= -1;

		Velocity += 3 * momentum/(Mass + 200);

		if ( damagetype == None )
		{
			// `warn("No damagetype for damage by "$instigatedby.pawn$" with weapon "$InstigatedBy.Pawn.Weapon);
			DamageType = class'DamageType';
		}

		Health -= Damage;
	}
	function SpawnFood() {
		
		local Vector dir;
		local int i;
		local GWFoodActor foodActor;
		local EFood FoodType;
		local int RandNum;

		
		//`Log(SocketLocation@vector(SocketRotator));
		for( i = 0; i < 5; i++) {
			FoodType = FOOD_NONE;
			RandNum = Rand(9) + 1;
			FoodType = EFood(RandNum);
			dir = VRand();
			
			foodActor = Spawn(class'GWFoodActor', self, , Location + GetCollisionHeight() * vect3d(0, 0, 0.5), RotRand(true), , );
			foodActor.Velocity = dir * 200 + vect3d(0, 0, 500);
			
			foodActor.Init(FoodType);
		}
	}
	simulated event BeginState(Name PreviousStateName)
	{
		local Actor A;
		local array<SequenceEvent> TouchEvents;
		local int i;

		if(Role == ROLE_Authority)
			SpawnFood();
		if ( bTearOff && (WorldInfo.NetMode == NM_DedicatedServer) )
		{
			LifeSpan = 2.0;
		}
		else
		{
			SetTimer(5.0, false);
			// add a failsafe termination
			LifeSpan = 5.f;
		}

		SetDyingPhysics();

		SetCollision(true, false);

		if ( Controller != None )
		{
			if ( Controller.bIsPlayer )
			{
				DetachFromController();
			}
			else
			{
				Controller.Destroy();
			}
		}

		foreach TouchingActors(class'Actor', A)
		{
			if (A.FindEventsOfClass(class'SeqEvent_Touch', TouchEvents))
			{
				for (i = 0; i < TouchEvents.length; i++)
				{
					SeqEvent_Touch(TouchEvents[i]).NotifyTouchingPawnDied(self);
				}
				// clear array for next iteration
				TouchEvents.length = 0;
			}
		}
		foreach BasedActors(class'Actor', A)
		{
			A.PawnBaseDied();
		}
	}

Begin:
	Sleep(0.2);
	PlayDyingSound();
}
simulated function PlayTakeHitEffects()
{
	local UTEmit_HitEffect HitEffect;
	//local ParticleSystem BloodTemplate;
	//BloodTemplate = class'UTEmitter'.static.GetTemplateForDistance(GetFamilyInfo().default.BloodEffects, LastTakeHitInfo.HitLocation, WorldInfo);
	HitEffect = Spawn(class'UTGame.UTEmit_HitEffect', self,, self.Location);
	HitEffect.SetTemplate(ParticleSystem'Grow_Effects.Effects.Damage_Effect', true);
	//WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Grow_LevelDesign.Effects.Damage_Effect',self.Location);
	super.PlayTakeHitEffects();
	
}

simulated function DrawHUD( HUD H ) {
	local GWHUD GH;
	local Color Green;

	GH = GWHUD(H);

	if(GH == none) {
		return;
	}
	GWWeap(Weapon).DrawTargets(GH);
	GWWeap(Weapon).DrawFoodTargets(GH);
	Green = MakeColor(0,255,0);
	//GH.Draw3DLine(Location - 100 * Floor, Location, Red);
	//GH.Draw3DLine(Location + 100 * Floor, Location, Blue);
	//GH.Draw3DLine(Location + 100 * Vector(Rotation), Location, Red);
	GH.Draw3DLine(GWWeap(Weapon).InstantFireStartTrace(), GWWeap(Weapon).InstantFireEndTrace(GWWeap(Weapon).InstantFireStartTrace()), Green);
}
/**
 * Return world location to start a weapon fire trace from.
 *
 * @return	World location where to start weapon fire traces from
 */
simulated event Vector GetWeaponStartTraceLocation(optional Weapon CurrentWeapon)
{
	local vector	POVLoc;

	if(Mesh.GetSocketByName('WeaponPoint') != none) {
		Mesh.GetSocketWorldLocationAndRotation('WeaponPoint', POVLoc);
		return POVLoc;
	} else {
		return super.GetWeaponStartTraceLocation(CurrentWeapon);
	}
}
simulated function IncrementAbility(Name stat, int GrowAmount)
{
	if(stat == 'PICKUPS_SPEED') {
		Speed += GrowAmount;
	} else if(stat == 'PICKUPS_SKILL') {
		Skill += GrowAmount;
	} else if(stat == 'PICKUPS_POWER') {
		Power += GrowAmount;
	} else if(stat == 'PICKUPS_POWER_SKILL') {
		Power += GrowAmount;
		Skill += GrowAmount;
	} else if(stat == 'PICKUPS_POWER_SPEED') {
		Power += GrowAmount;
		Speed += GrowAmount;
	} else if(stat == 'PICKUPS_SKILL_SPEED') {
		Skill += GrowAmount;
		Speed += GrowAmount;
	} else if(stat == 'PICKUPS_ALL') {
		Power += GrowAmount;
		Skill += GrowAmount;
		Speed += GrowAmount;
	}
	//class<GWSoundGroup>(SoundGroupClass).static.PlayEatSound(self);
}
simulated function bool DecrementAbility(Name stat, int GrowAmount)
{
	if(Power <= 0 && Skill <= 0 && Speed <= 0) {
		return false;
	}
	if(stat == 'PICKUPS_SPEED') {
		Speed = Max(Speed - GrowAmount, 0);
	} else if(stat == 'PICKUPS_SKILL') {
		Skill = Max(Skill - GrowAmount, 0);
	} else if(stat == 'PICKUPS_POWER') {
		Power = Max(Power - GrowAmount, 0);
	} else if(stat == 'PICKUPS_POWER_SKILL') {
		Power = Max(Power - GrowAmount, 0);
		Skill = Max(Skill - GrowAmount, 0);
	} else if(stat == 'PICKUPS_POWER_SPEED') {
		Power = Max(Power - GrowAmount, 0);
		Speed = Max(Speed - GrowAmount, 0);
	} else if(stat == 'PICKUPS_SKILL_SPEED') {
		Skill = Max(Skill - GrowAmount, 0);
		Speed = Max(Speed - GrowAmount, 0);
	} else if(stat == 'PICKUPS_ALL') {
		Power = Max(Power - GrowAmount, 0);
		Skill = Max(Skill - GrowAmount, 0);
		Speed = Max(Speed - GrowAmount, 0);
	}
	//class<GWSoundGroup>(SoundGroupClass).static.PlayEatSound(self);
	return true;
}

simulated event PlayFootStepSound(int FootDown)
{
	local PlayerController PC;

	if ( !IsFirstPerson() )
	{
		ForEach LocalPlayerControllers(class'PlayerController', PC)
		{
			if ( (PC.ViewTarget != None) && (VSizeSq(PC.ViewTarget.Location - Location) < MaxFootstepDistSq) )
			{
				//Trigger Footstep Particle
				ActuallyPlayFootstepSound(FootDown);
				return;
			}
		}
	}
}

simulated function PlayAnimList(int AnimNum, bool BlendToAnim) {
	local AnimNode Node;

	if(AnimNum == 0) { //Stop All Animations
		if(HeadAnimList.ActiveChildIndex != 0) {
			Node = HeadAnimList.Children[HeadAnimList.ActiveChildIndex].Anim;
			//while(AnimNodeSequence(Node) == none) {
			//AnimNodeScalePlayRate(Node).C
			if(Node != none) {
				Node.StopAnim();
			}
		}
		if(BodyAnimList.ActiveChildIndex != 0) {
			Node = BodyAnimList.Children[BodyAnimList.ActiveChildIndex].Anim;
			if(Node != none) {
				Node.StopAnim();
			}
		}
		AnimHeadBlend.SetBlendTarget(0, 0);
		BodyAnimList.SetActiveChild(0, BodyAnimList.GetBlendTime(0));
		return;
	}

	if(bool(AnimExists[AnimNum])) {
		if(bool(AnimHeadOnly[AnimNum])) {
			Node = HeadAnimList.Children[AnimNum].Anim;
		} else {
			Node = BodyAnimList.Children[AnimNum].Anim;
		}
		if(AnimNum != 0) {
			if(BlendToAnim) {
				Node.ReplayAnim();//Node.PlayAnim(Node., Node.Rate, 0);
			} else {
				Node.StopAnim();
			}
		}
		if(bool(AnimHeadOnly[AnimNum])) {
			AnimHeadBlend.SetBlendTarget((BlendToAnim ? 1 : 0), ((BlendToAnim && (HeadAnimList.ActiveChildIndex != 0)) ? 0.25f : 0.f));
			if(BlendToAnim) {
				HeadAnimList.SetActiveChild(AnimNum, HeadAnimList.GetBlendTime(AnimNum));
			} else {
				HeadAnimList.SetActiveChild(0, HeadAnimList.GetBlendTime(0));
			}
		} else {
			if(BlendToAnim) {
				BodyAnimList.SetActiveChild(AnimNum, BodyAnimList.GetBlendTime(AnimNum));
			} else {
				BodyAnimList.SetActiveChild(0,  BodyAnimList.GetBlendTime(0));
			}
		}
	}
	
}
simulated function StartEatAnimation() {
	`Log(self@"Called"@GetFuncName(),,'DevAnim');
	PlayAnimList(7, true);
}

simulated function StopEatAnimation() {
	`Log(self@"Called"@GetFuncName(),,'DevAnim');
	PlayAnimList(7, false);
	if(CurrentEatenFoodType != FOOD_NONE) {
		StartFoodHoldAnimation();
	}
}
simulated function StartChewAnimation() {
	`Log(self@"Called"@GetFuncName(),,'DevAnim');
	StopFoodHoldAnimation();
	if(bool(AnimExists[9])) {
		PlayAnimList(9, true);
	} else {
		StopChewAnimation();
	}
}
simulated function StopChewAnimation() {
	`Log(self@"Called"@GetFuncName(),,'DevAnim');
	if(CurrentEatenFoodType != FOOD_NONE) {
		StartFoodHoldAnimation();
	} else {
		PlayAnimList(9, false);
	}
}
simulated function StartSpitAnimation() {
	StopFoodHoldAnimation();
	if(bool(AnimExists[10])) {
		PlayAnimList(10, true);
	} else {
		StopSpitAnimation();
	}
}
simulated function StopSpitAnimation() {
	PlayAnimList(10, false);
}
simulated function StartSpewAnimation() {
	if(bool(AnimExists[11])) {
		PlayAnimList(11, true);
	} else {
		StopSpewAnimation();
	}
}
simulated function StopSpewAnimation() {
	PlayAnimList(11, false);
}
simulated function StartFoodHoldAnimation() {
	`Log(self@"Called"@GetFuncName(),,'DevAnim');
	if(bool(AnimExists[8])) {
		PlayAnimList(8, true);
	} else {
		StopFoodHoldAnimation();
	}
}
simulated function StopFoodHoldAnimation() {
	`Log(self@"Called"@GetFuncName(),,'DevAnim');
	PlayAnimList(8, false);
}
simulated function StartAttackAnimation() {
	PlayAnimList(2, true);
}
simulated function StopAttackAnimation() {
	PlayAnimList(2, false);
}
simulated function StartDeathAnimation() {
	class<GWSoundGroup>(SoundGroupClass).static.PlayDyingSound(self);
	//`Log("Death is cruel for"@GetHumanReadableName());
	if(!bool(AnimExists[1])) {
		SetTimer(0.1f, false, 'StopDeathAnimation');
	} else {
		PlayAnimList(1, true);
	}
}
simulated function StopDeathAnimation() {
	local ParticleSystemComponent Part;
	PlayAnimList(1, false);

	if(WorldInfo.NetMode != NM_DedicatedServer) {
		Part = WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'Grow_Effects.Effects.Grow_Effect',self.Location);
		Part.SetScale(DeathPartScale);
	}
	//`Log("Death is unforgiving for"@GetHumanReadableName());
	//Controller.UnPossess();
	self.Destroy();
}
simulated function StartAbilityStartAnimation() {
	if(!bool(AnimExists[3])) {
		StopAbilityStartAnimation();
	} else {
		PlayAnimList(3, true);
	}
}
simulated function StopAbilityStartAnimation() {
	PlayAnimList(3, false);
	if(bool(AnimExists[4])) {
		StartAbilityLoopAnimation();
	}
}
simulated function StartAbilityLoopAnimation() {
	PlayAnimList(4, true);
}
simulated function StopAbilityLoopAnimation() {
	PlayAnimList(4, false);
}
simulated function StartAbilityHitAnimation() {
	if(bool(AnimExists[4])) {
		StopAbilityLoopAnimation();
	}
	PlayAnimList(5, true);
}
simulated function StopAbilityHitAnimation() {
	PlayAnimList(5, false);
	if(bool(AnimExists[4])) {
		StartAbilityLoopAnimation();
	}
}
simulated function StartAbilityEndAnimation() {
	if(bool(AnimExists[4])) {
		StopAbilityLoopAnimation();
	}
	if(bool(AnimExists[5])) {
		StopAbilityHitAnimation();
	}
	if(bool(AnimExists[6])) {
		PlayAnimList(6, true);
	} else {
		StopAbilityEndAnimation();
	}
}
simulated function StopAbilityEndAnimation() {
	PlayAnimList(6, false);
}
simulated function StopAllAnimation() {
	PlayAnimList(0, false);
}
simulated function StartFlinchAnimation() {
	if(bool(AnimExists[12])) {
		PlayAnimList(12, true);
	}
}
simulated function StopFlinchAnimation() {
	if(bool(AnimExists[12])) {
		PlayAnimList(12, false);
	}
}
simulated function StartStunAnimation() {
	if(bool(AnimExists[13])) {
		PlayAnimList(13, true);
	}
}
simulated function StopStunAnimation() {
	if(bool(AnimExists[13])) {
		PlayAnimList(13, false);
	}
}
exec function BaseLock() {
	ServerBaseLock();
}
reliable server function ServerBaseLock() {
	SetCollision( false, false);
	bCollideWorld = false;
	SetBase(none);
	SetHardAttach(true);
	SetPhysics( PHYS_None );

	SetBase(BasedPawn);
	// need to set PHYS_None again, because SetBase() changes physics to PHYS_Falling
	SetPhysics( PHYS_None );
}
/**
 * Animation Replication Functions
 */

function TriggerAnim(EAnim AnimType)
{
	local RepAnim NewRepAnim;

	if(Role < ROLE_Authority) {
		return;
	}
	NewRepAnim.Type = AnimType;
	NewRepAnim.Id = Rand(255);

	// changing this var will make it get caught and replicated by ReplicatedEvent. remember repnotify on the declaration?
	while(AnimRep.Id == NewRepAnim.Id) {
		NewRepAnim.Id = Rand(255);
	}
	AnimRep = NewRepAnim;
	AnimRepLastAnim = AnimRep.Id;
	//`Log(self@"Called TriggerAnim with"@AnimType);
	PlayRepAnim(AnimType);
	/*if(Role < ROLE_Authority) // If not server
		ServerPlayRepAnim(AnimType);*/
}

/*reliable server function ServerPlayRepAnim(EAnim AnimType) {
	PlayRepAnim(AnimType);
}*/

reliable client function ClientPlayRepAnim(EAnim AnimType) {
	PlayRepAnim(AnimType);
}

simulated function PlayRepAnim(EAnim AnimType) {
	`Log(self@"Called PlayRepAnim with"@AnimType,,'DevAnim');

	switch(AnimType) {
	case(ANIM_NONE):
		StopAllAnimation();
		break;
	case(ANIM_EAT):
		StartEatAnimation();
		break;
	case(ANIM_ATTACK):
		StartAttackAnimation();
		break;
	case(ANIM_ABILITY_START):
		StartAbilityStartAnimation();
		break;
	case(ANIM_CHEW):
		StartChewAnimation();
		break;
	case(ANIM_SPIT):
		StartSpitAnimation();
		break;
	case(ANIM_FOOD_HOLD):
		StartFoodHoldAnimation();
		break;
	case(ANIM_SPEW):
		StartSpewAnimation();
		break;
	case(ANIM_ABILITY_LOOP):
		StartAbilityLoopAnimation();
		break;
	case(ANIM_ABILITY_HIT):
		StartAbilityHitAnimation();
		break;
	case(ANIM_ABILITY_END):
		StartAbilityEndAnimation();
		break;
	case(ANIM_DEATH):
		StartDeathAnimation();
		break;
	case(ANIM_FLINCH):
		StartFlinchAnimation();
		break;
	case(ANIM_STUN):
		StartStunAnimation();
		break;
	}
}

simulated event ReplicatedEvent(name VarName)
{
	if ( VarName == 'AnimRep') {
		//if(AnimRepLastAnim == AnimRep.Id)
		//	return;
		ClientPlayRepAnim(AnimRep.Type);
	}
	if ( VarName == 'TriggerOpacity') {
		SetOpacity(TriggerOpacity);
	}
	if(VarName == 'CurrentEatenFoodType') {
		ClientSetFood(CurrentEatenFoodType, true);
	}
	if(VarName == 'StatusEffects') {
		StatusEffectUpdated(true);
	}
	if(VarName == 'ReplicatedGrowCharge') {
		ClientSetGrowProgress(true);
	}
	if(VarName == 'ReplicatedDevolveCharge') {
		ClientSetDevolveProgress(true);
	}

	super.ReplicatedEvent(VarName);
}


/**
 * This function's responsibility is to signal clients that non-instant hit shot
 * has been fired. Call this on the server and local player.
 *
 * Network: Server and Local Player
 */
simulated function IncrementStatusEffect(EStatusEffects Stat, Controller CausedBy)
{
	bForceNetUpdate = TRUE;	// Force replication
	StatusEffects[Stat]++;
	StatusEffectsCausedBy[Stat] = CausedBy;

	// Make sure it's not 0, because it means the weapon stopped firing!
	if( StatusEffects[Stat] == 0 )
	{
		StatusEffects[Stat] += 2;
	}
	
	// This weapon has fired.
	StatusEffectUpdated(FALSE);
}


/**
 * Called when FlashCount has been updated.
 * Trigger appropritate events based on FlashCount's value.
 * = 0 means Weapon Stopped firing
 * > 0 means Weapon just fired
 *
 * Network: ALL
 */
simulated function StatusEffectUpdated(bool bViaReplication)
{
	local int i;
	for(i = 0; i < EFFECT_MAX; i++) {
		if(StatusEffects[i] != OldStatusEffects[i]) {
			OldStatusEffects[i] = StatusEffects[i];
			if(StatusEffects[i] > 0) {
				StatusEffectStart(EStatusEffects(i), bViaReplication);
			} else {
				StatusEffectStop(EStatusEffects(i), bViaReplication);
			}
		}
	}
}

simulated function StatusEffectStart(EStatusEffects Stat, bool bViaReplication) {
	local LinearColor LC;

	switch(Stat) {
	case EFFECT_GROWL_RAGE:
		BodyMaterialInstances[0].SetScalarParameterValue('Rage', StatusEffects[Stat]);
		break;
	case EFFECT_NEWT_HEAL:
		if(Role == ROLE_Authority) {
			SetTimer(0.3, false, 'ClearHeal');
		}
		break;
	case EFFECT_STUN:
		StunPart.ActivateSystem(false);
		break;
	case EFFECT_FLINCH:
		//StunPart.ActivateSystem(false);
		break;
	case EFFECT_BUBBLES_AEGIS:
		LC = MakeLinearColor(0, 1, 0, 1);
		BodyMaterialInstances[0].SetVectorParameterValue('CharOverlay', LC);
		DamageScaling = 1.5 * default.DamageScaling;
		if(Role == ROLE_Authority) {
			SetTimer(7, false, 'AttackBoostEnd');
		}
		break;
	case EFFECT_SCAMPER_BOOST:
		ModifySpeed();
		break;
	case EFFECT_SCAMPER_STINK:
		ModifySpeed();
		//LC = MakeLinearColor(0, 0, 1, 1);
		//BodyMaterialInstances[0].SetVectorParameterValue('CharOverlay', LC);
		if(Role == ROLE_Authority) {
			SetTimer(5, false, 'ClearStink');
		}
		StinkPart.ActivateSystem(false);
		break;
	case EFFECT_FOOD_BURN:
		if(Role == ROLE_Authority) {
			SetTimer(0.3, true, 'BurnTick');
			SetTimer(3, false, 'BurnEnd');
		}
		BurnPart.ActivateSystem(false);
		break;
	}
}
function BurnTick() {
	TakeDamage(5, StatusEffectsCausedBy[EFFECT_FOOD_BURN], Location, vect3d(0,0,0), class'GWDmgType_Burning');
}
function BurnEnd() {
	ClearStatusEffect(EFFECT_FOOD_BURN);
	ClearTimer('BurnTick');
}
simulated function StatusEffectStop(EStatusEffects Stat, bool bViaReplication) {
	local LinearColor LC;
	switch(Stat) {
	case EFFECT_GROWL_RAGE:
		BodyMaterialInstances[0].SetScalarParameterValue('Rage', StatusEffects[Stat]);
		break;
	case EFFECT_STUN:
	//case EFFECT_FLINCH:
		StunPart.DeactivateSystem();
		break;
	case EFFECT_BUBBLES_AEGIS:
		LC = MakeLinearColor(0, 0, 0, 1);
		BodyMaterialInstances[0].SetVectorParameterValue('CharOverlay', LC);
		break;
	case EFFECT_SCAMPER_BOOST:
		ModifySpeed();
		break;
	case EFFECT_SCAMPER_STINK:
		ModifySpeed();
		//LC = MakeLinearColor(0, 0, 0, 1);
		//BodyMaterialInstances[0].SetVectorParameterValue('CharOverlay', LC);
		StinkPart.DeactivateSystem();
		break;
	case EFFECT_FOOD_BURN:
		BurnPart.DeactivateSystem();
		break;
	}
}

function ClearHeal() {
	ClearStatusEffect(EFFECT_NEWT_HEAL);
}
function ClearStink() {
	ClearStatusEffect(EFFECT_SCAMPER_STINK);
}

/**
 * Clear flashCount variable. and call WeaponStoppedFiring event.
 * Call this on the server and local player.
 *
 * Network: Server or Local Player
 */
simulated function ClearStatusEffect(EStatusEffects Stat)
{
	if( StatusEffects[Stat] != 0 )
	{
		bForceNetUpdate = TRUE;	// Force replication
		StatusEffects[Stat] = 0;
		StatusEffectsCausedBy[Stat] = none;
		// This weapon stopped firing
		StatusEffectUpdated(FALSE);
	}
}
/**
 * When a pawn's team is set or replicated, SetTeamColor is called.  By default, this will setup
 * any required material parameters.
 */
simulated function SetTeamColor()
{
	local PlayerReplicationInfo PRI;

	if ( PlayerReplicationInfo != None )
	{
		PRI = PlayerReplicationInfo;
	}
	if ( PRI == None )
		return;

	if ( PRI.Team == None )
	{
		if ( VerifyBodyMaterialInstance() )
		{
			BodyMaterialInstances[0] = new(self) class'MaterialInstanceConstant';
			BodyMaterialInstances[0].SetParent(TeamMaterials[2]);

			Mesh.SetMaterial(0,BodyMaterialInstances[0]);
		}
	} else if (VerifyBodyMaterialInstance()) {
		BodyMaterialInstances[0] = new(self) class'MaterialInstanceConstant';
		BodyMaterialInstances[0].SetParent(TeamMaterials[PRI.Team.TeamIndex]);

		Mesh.SetMaterial(0,BodyMaterialInstances[0]);
	}
}

simulated event Tick( float DeltaTime ) {
	local Vector      vSurfaceLoc;
//	local PhysicsVolume V;
	//29 (Distance between centre of bounding box and slope) * Cos(ASin(Floor.Z))
	//0.77, -0.15, 0.62
	//-0.43,-0.65, 0.62
	//-0.26, -0.39,0.88
	//Dist = 29 / Cos(ATan(0.39/0.26))
	//Multiply the normal X by collision size to get Y
	
	//local Rotator POVRot;
	//local Vector POVVec;

	/*if(FiringMode == 0 && FlashCount != 0) {
		POVRot = GetBaseAimRotation();
		POVRot.Roll = 0;
		POVRot.Yaw = 0;
		POVVec = Vector(POVRot);

		MuzzleFlashPSC.SetVectorParameter('PawnViewPitch', POVVec);
	}*/
	super.Tick(DeltaTime);

	GrowProgress(DeltaTime);

	if(lastState != GetStateName()) {
		lastState = GetStateName();
		`Log("Entering Pawn"@GetStateName());
	}
	if(`TimeSince(LastSpeedTick) > 0.1) {
		LastSpeed = int(VSize(Velocity));
		LastSpeedTick = WorldInfo.TimeSeconds;
		//`Log("Speed:"@LastSpeed@"Physics:"@Physics);
	}

	UpdateMuzzleFlash();
	//`Log("Floor:"@Floor@"Base:"@Base);
	
	/*if(Floor.Z == 1) {
		BaseTranslationOffset = default.Mesh.Translation.Z;
	} else {
		temp = (GetCollisionRadius() / Cos(Atan(Floor.X/Floor.Y))) * Cos(Asin(Floor.Z));
		BaseTranslationOffset = default.Mesh.Translation.Z - temp;
		`Log("Ground Normal: "$Floor$"Offset: "$temp$" Rotation: "$Vector(Rotation));
	}*/
	//if(GWCTFGame(WorldInfo.Game).ShowColliders) {
	//	Box.SetHidden()
	if(VSizeSq(Velocity) < 20) {
		fIdleTime += DeltaTime;
		if(fIdleTime > 5) {
			bLongIdle = true;
		}
	} else if(fIdleTime > 0) {
		fIdleTime = 0;
		bLongIdle = false;
	}
	if(Role == ROLE_Authority && Controller != none && Controller.IsInState('PlayerFloating')) {
		//make pawn float on surface
		vSurfaceLoc = Location;
		vSurfaceLoc.Z = Lerp(Location.Z, fWaterSurfaceZ,FMin(5*DeltaTime,1));
		SetLocation(vSurfaceLoc);
	}
}
simulated function UpdateMuzzleFlash() {
	local Rotator POVRot;
	local Vector POVVec;

	if(FiringMode == FIREMODE_SPEW && FlashCount != 0) {
		POVRot = GetBaseAimRotation();
		POVRot.Roll = 0;
		POVRot.Yaw = 0;
		POVVec = Vector(POVRot);

		MuzzleFlashPSC.SetVectorParameter('PawnViewPitch', POVVec);
	}
}
event Landed(vector HitNormal, actor FloorActor)
{
	local vector Impulse;
	//local GWAnimBlendByFall node;

	//foreach JumpAnimNodes(node) {
	//	node.FallState = BF_Land;
	//}
	TakeFallingDamage();
	if ( Health > 0 )
		PlayLanded(Velocity.Z);
	LastHitBy = None;

	//`Log("Landed:BasedPawn ="@BasedPawn);
	BasedPawn = none;
/*	if(Floor != vect3d(0,0,1)) {
		Controller.GotoState('PlayerSliding');
	}*/

	// adds impulses to vehicles and dynamicSMActors (e.g. KActors)
	Impulse.Z = Velocity.Z * 4.0f; // 4.0f works well for landing on a Scorpion
	if (UTVehicle(FloorActor) != None)
	{
		UTVehicle(FloorActor).Mesh.AddImpulse(Impulse, Location);
	}
	else if (DynamicSMActor(FloorActor) != None)
	{
		DynamicSMActor(FloorActor).StaticMeshComponent.AddImpulse(Impulse, Location);
	}

	if ( Velocity.Z < -200 )
	{
		OldZ = Location.Z;
		bJustLanded = bUpdateEyeHeight && (Controller != None) && Controller.LandingShake();
	}

	if (UTInventoryManager(InvManager) != None)
	{
		UTInventoryManager(InvManager).OwnerEvent('Landed');
	}
	/*if ((MultiJumpRemaining < MaxMultiJump && bStopOnDoubleLanding) || bDodging || Velocity.Z < -2 * JumpZ)
	{
		// slow player down if double jump landing
		Velocity.X *= 0.1;
		Velocity.Y *= 0.1;
	}*/

	AirControl = DefaultAirControl;
	MultiJumpRemaining = MaxMultiJump;
	bDodging = false;
	bReadyToDoubleJump = false;
	if (UTBot(Controller) != None)
	{
		UTBot(Controller).ImpactVelocity = vect(0,0,0);
	}

	if(!bHidden)
	{
		PlayLandingSound();
	}
	if (Velocity.Z < -MaxFallSpeed)
	{
		SoundGroupClass.Static.PlayFallingDamageLandSound(self);
	}
	else if (Velocity.Z < MaxFallSpeed * -0.5)
	{
		SoundGroupClass.Static.PlayLandSound(self);
	}

	SetBaseEyeheight();
}
function GrowProgress(float DeltaTime) {
	local GWPlayerController GWPC;
	local int ReqStage1;
	local int ReqStage2;
	local EForm newForm;
	local bool allowCharge;
	local float oldGrowCharge;

	GWPC = GWPlayerController(Controller);
	if(GWPC == none || WorldInfo.NetMode == NM_DedicatedServer) 
	{
		return;
	}
	ReqStage1 = GWPC.ReqStage1;
	ReqStage2 = GWPC.ReqStage2;
	
	oldGrowCharge = GrowCharge;

	if (!bLockGrow)
	{
		if (GrowType != 0)
		{
			//`log("Pawn----------------------------Grow Type is:"@GrowType);
			switch (Form) 
			{
			case FORM_BABY:
				if (GrowType == 1)
				{
					if(Power >= ReqStage1)
					{
						allowCharge = true;
						newForm = FORM_POWER;
					}
				}
				else if (GrowType == 2)
				{
					if(Speed >= ReqStage1)
					{
						allowCharge = true;
						newForm = FORM_SPEED;
					}
				}
				else if (GrowType == 3)
				{
					if(Skill >= ReqStage1)
					{
						allowCharge = true;
						newForm = FORM_SKILL;
					}
				}
				break;
			case FORM_POWER:
				if (GrowType == 1)
				{
					if(Power >= ReqStage2)
					{
						allowCharge = true;
						newForm = FORM_POWER_MAX;
					}
				}
				else if (GrowType == 2)
				{
					if(Speed >= ReqStage2)
					{
						allowCharge = true;
						newForm = FORM_SPEED_POWER;
					}
				}
				else if (GrowType == 3)
				{
					if(Skill >= ReqStage2)
					{
						allowCharge = true;
						newForm = FORM_SKILL_POWER;
					}
				}
				break;
			case FORM_SKILL:
				if (GrowType == 1)
				{
					if(Power >= ReqStage2)
					{
						allowCharge = true;
						newForm = FORM_SKILL_POWER;
					}
				}
				else if (GrowType == 2)
				{
					if(Speed >= ReqStage2)
					{
						allowCharge = true;
						newForm = FORM_SKILL_SPEED;
					}
				}
				else if (GrowType == 3)
				{
					if(Skill >= ReqStage2)
					{
						allowCharge = true;
						newForm = FORM_SKILL_MAX;
					}
				}
				break;
			case FORM_SPEED:
				if (GrowType == 1)
				{
					if(Power >= ReqStage2)
					{
						allowCharge = true;
						newForm = FORM_SPEED_POWER;
					}
				}
				else if (GrowType == 2)
				{
					if(Speed >= ReqStage2)
					{
						allowCharge = true;
						newForm = FORM_SPEED_MAX;
					}
				}
				else if (GrowType == 3)
				{
					if(Skill >= ReqStage2)
					{
						allowCharge = true;
						newForm = FORM_SKILL_SPEED;
					}
				}
				break;
			}
			//`log("Pawn----------------------------Allow Charge?"@allowCharge);
			if (allowCharge)
			{
				if (GrowType == 1)
				{
					PowerCharge += DeltaTime;
					SpeedCharge -= DeltaTime;
					SkillCharge -= DeltaTime;
					//`log("Pawn----------------------------Charging Power"@PowerCharge);
				}
				else if (GrowType == 2)
				{
					PowerCharge -= DeltaTime;
					SpeedCharge += DeltaTime;
					SkillCharge -= DeltaTime;
				}
				else if (GrowType == 3)
				{
					PowerCharge -= DeltaTime;
					SpeedCharge -= DeltaTime;
					SkillCharge += DeltaTime;
				}
			}
		}
		else if (GrowCharge != 0)
		{
			//`log("Pawn----------------------------Reducing Charge");
			if (!allowCharge)
			{
				PowerCharge -= DeltaTime;
				SpeedCharge -= DeltaTime;
				SkillCharge -= DeltaTime;
			}
		}
		PowerCharge = FClamp(PowerCharge,0,1);
		SpeedCharge = FClamp(SpeedCharge,0,1);
		SkillCharge = FClamp(SkillCharge,0,1);
		GrowCharge = FMax(PowerCharge, SpeedCharge);
		GrowCharge = FMax(GrowCharge, SkillCharge);
		//`log("Pawn----------------------------Grow Charge: "$GrowCharge);
		if (GrowCharge != oldGrowCharge )
		{
			ReplicatedGrowCharge = Min(GrowCharge * 255, 255);
			//`Log("ReplicatedGrowCharge:"@ReplicatedGrowCharge);
			ClientSetGrowProgress();
			if (GrowCharge >= 1 && allowCharge)
			{
				if (Form != newForm && newForm != FORM_NONE)
				{
					bLockGrow = true;
					`Log("Growing Server Grow");
					GWPC.ServerGrow(newForm, GrowType);
				}
			}
		}
	}
}
simulated function ClientSetGrowProgress(bool ViaReplication = false) {
	if(Role == ROLE_SimulatedProxy) {
		GrowCharge = ReplicatedGrowCharge / 255.0f;
	}
	GrowCharge = FClamp(GrowCharge, 0, 1);
	//if(ViaReplication)
		//`Log(name@"GrowCharge: "$GrowCharge$" ViaReplication: "$ViaReplication);
	BodyMaterialInstances[0].SetScalarParameterValue('Glow', GrowCharge * 2);
}
function DevolveProgress(float DeltaTime) {
	local GWPlayerController GWPC;

	GWPC = GWPlayerController(Controller);
	if(GWPC == none || WorldInfo.NetMode == NM_DedicatedServer) {
		return;
	}

	if(Form == FORM_BABY) {
		return;
	}
	DevolveCharge += DeltaTime;
	ReplicatedDevolveCharge = Min(DevolveCharge * 255, 255);
	ClientSetDevolveProgress();
	if (DevolveCharge >= 1) {
			GWPC.ServerDevolve();
	}
}
simulated function ClientSetDevolveProgress(bool ViaReplication = false) {
	if(Role == ROLE_SimulatedProxy) {
		DevolveCharge = ReplicatedDevolveCharge / 255.0f;
	}
	DevolveCharge = FClamp(DevolveCharge, 0, 1);
	BodyMaterialInstances[0].SetScalarParameterValue('Glow', DevolveCharge);
}
function ResetDevolve() {
	DevolveCharge = 0;
	ReplicatedDevolveCharge = 0;
	ClientSetDevolveProgress();
}
reliable client function ClientGrowFailed(string Reason) {
	bLockGrow = false;
	ClientMessage(Reason);
	PowerCharge = 0;
	SpeedCharge = 0;
	SkillCharge = 0;
	//GrowCharge = 0;
	//ReplicatedGrowCharge = 0;
	//ClientSetGrowProgress();
}
/**
PostRenderFor()
Hook to allow pawns to render HUD overlays for themselves.
Called only if pawn was rendered this tick.
Assumes that appropriate font has already been set
@todo FIXMESTEVE - special beacon when speaking (SpeakingBeaconTexture)
*/
simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir) {}

/** Set various basic properties for this UTPawn based on the character class metadata */
simulated function SetCharacterClassFromInfo(class<GWFamilyInfo> Info)
{
	
	if (Info != CurrCharClassInfo)
	{
		// Set Family Info
		CurrCharClassInfo = Info;

		// First person arms mesh/material (if necessary)
		if (WorldInfo.NetMode != NM_DedicatedServer && IsHumanControlled() && IsLocallyControlled())
		{
			//TeamMaterialArms = Info.static.GetFirstPersonArmsMaterial(TeamNum);
			//SetFaceCam();
		}
	}
}
/*simulated function SetFaceCam() {
	
	6FaceCam.SetScale(0.5);
	FaceCam.SetSkeletalMesh(Mesh.SkeletalMesh);
	FaceCam.SetOwnerNoSee(false);
	FaceCam.SetOnlyOwnerSee(true);
	FaceCam.AnimSets = Mesh.AnimSets;
	FaceCam.SetParentAnimComponent(Mesh);
	FaceCam.bUpdateSkelWhenNotRendered = false;
	FaceCam.bIgnoreControllersWhenNotRendered = true;
	FaceCam.bOverrideAttachmentOwnerVisibility = true;

	FaceCam.SetFOV(55);
	//FaceCam.SetRotation(MakeRotator(0, 180 * DegToUnrRot, 0));
	FaceCam.SetTranslation(vect3d(0, 0, 50));
}*/
function bool IsLocationOnHead(const out ImpactInfo Impact, float AdditionalScale)
{
	return false;
}
/*exec function SetHUD(int element, int index = 0, int value = 0) {
	GWHUD(GWPlayerController(Controller).myHUD).SetHUD(element, index, value);
}*/
function int GetCurrentStage() {
	switch(Form) {
	case FORM_BABY:
		return 0;
	case FORM_POWER:
	case FORM_SKILL:
	case FORM_SPEED:
		return 1;
	case FORM_POWER_MAX:
	case FORM_SKILL_MAX:
	case FORM_SPEED_MAX:
	case FORM_SKILL_POWER:
	case FORM_SKILL_SPEED:
	case FORM_SPEED_POWER:
		return 2;
	default:
		return 0;
	}
}

simulated function SetHatFromInfo(SkeletalMesh NewMesh) {
	HatSkeletalMesh.SetSkeletalMesh(NewMesh);
}

function AdjustDamage(out int InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser)
{
	if(!DamageType.default.bArmorStops) {
		return;
	}
	if(bShielded) {
		InDamage *= 0.5;
	}
	if(StatusEffects[EFFECT_SCAMPER_STINK] > 0) {
		InDamage *= 1.25;
	}
	super.AdjustDamage(InDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);
}

/*reliable server function ServerSetOpacity( float newOpacity)
{
	TriggerOpacity = newOpacity;
	SetOpacity(TriggerOpacity);
}*/

simulated function SetOpacity(float newOpacity) {
	local PlayerReplicationInfo PRI;
	local int MatNum;
	local PlayerController PC;

	if ( PlayerReplicationInfo != None )
	{
		PRI = PlayerReplicationInfo;
	}
	if ( PRI == None )
		return;
	
	if ( PRI.Team == None ) {
		MatNum = 2;
	} else {
		MatNum = PRI.Team.TeamIndex;
	}
	if(newOpacity > 0) {
		if (WorldInfo.NetMode != NM_DedicatedServer) {
			BodyMaterialInstances[0] = new(self) class'MaterialInstanceConstant';
			BodyMaterialInstances[0].SetParent(TeamMaterials[MatNum]);

			Mesh.SetMaterial(0,BodyMaterialInstances[0]);
		}
	} else {
		if (WorldInfo.NetMode != NM_DedicatedServer) {
			BodyMaterialInstances[0] = new(self) class'MaterialInstanceConstant';
			BodyMaterialInstances[0].SetParent(TeamExtraMaterials[MatNum]);

			Mesh.SetMaterial(0,BodyMaterialInstances[0]);
		}
	}
	BodyMaterialInstances[0].SetScalarParameterValue('Char_Opacity', newOpacity);

	PC = GetALocalPlayerController();
	
	if(IsSameTeamOrSelf(PC.Pawn)) {
		BodyMaterialInstances[0].SetScalarParameterValue('Friendly', 1.0);
	} else {
		BodyMaterialInstances[0].SetScalarParameterValue('Friendly', 0);
	}
}
exec simulated function SetCameraPosition(int x, int y, int z) {
	ClientMessage("Old Camera Position: "$CamOffset.X$", "$CamOffset.Y$", "$CamOffset.Z);
	CamOffset.X = x;
	CamOffset.Y = y;
	CamOffset.Z = z;
	CameraOffset = CamOffset;
	SaveConfig();
}

exec simulated function SetStat(string stat, int value) {
	switch(stat) {
	case "GroundSpeed":
		ClientMessage("Old GroundSpeed is: "$GroundSpeed);
		GroundSpeed = value;
		break;
	case "AirSpeed":
		ClientMessage("Old AirSpeed is: "$AirSpeed);
		AirSpeed = value;
		break;
	case "WaterSpeed":
		ClientMessage("Old WaterSpeed is: "$WaterSpeed);
		WaterSpeed = value;
		break;
	case "AccelRate":
		ClientMessage("Old AccelRate is: "$AccelRate);
		AccelRate = value;
		break;
	case "Health":
		ClientMessage("Old Health is: "$HealthMax);
		HealthMax = value;
		Health = value;
		break;
	case "Damage":
		ClientMessage("Old Damage is: "$DamageScaling);
		DamageScaling = value;
		break;
	default:
		ClientMessage("Choices are:\nGroundSpeed\nAirSpeed\nWaterSpeed\nAccelRate\nHealth\nDamage");
	}
}
exec function AddNewVelocity(float x, float y, float z) {
	//local Vector axisX, axisY, axisZ;
	if ( (Physics == PHYS_Walking)
		|| (((Physics == PHYS_Ladder) || (Physics == PHYS_Spider)) && (z > Default.JumpZ)) )
		SetPhysics(PHYS_Falling);
	//GetAxes(Rotation, axisX, axisY, axisZ);
	//Velocity += (axisX + axisZ) * newVect(x,y,z);
	Velocity += vect3d(x, y, z);
}

exec function SetOffset(float z) {
	//Mesh.SetTranslation(Mesh.Translation + vect3d(0,0,z));
	BaseTranslationOffset = z;
}

simulated function bool CanBeBaseForPawn(Pawn APawn)
{
	`Log("Base:BasedPawn ="@GWPawn(APawn).BasedPawn);
	if(IsSameTeam(APawn)) {
		GWPawn(APawn).BasedPawn = self;
		return true;
	}
	return false;
}
exec function SetState(name state) {
	Controller.GotoState(state);
}
simulated function ClientSetFood(EFood HoldFood, bool bViaReplication) {
	local SFoodInfo FI;

	//`Log(name@"set food"@FoodType);

	FI = class'GWConstants'.default.FoodStats[HoldFood];
	
	`Log(name$"::"$GetFuncName()@"set food"@HoldFood,, 'DevFood');
	CurrentEatenFoodMesh.SetScale(1);
	if(HoldFood == FOOD_NONE) {
		CurrentEatenFoodMesh.SetHidden(true);
		HoldingFood = false;
	} else {
		CurrentEatenFoodMesh.SetStaticMesh(FI.Mesh);
		switch (HoldFood) {
		case FOOD_CANDY_LARGE:
		case FOOD_CANDY_MEDIUM:
		case FOOD_CANDY_SMALL:
			EatPart.SetMaterialParameter('PartMat', MaterialInstanceConstant'Grow_John_Assets.Materials.Gib_Speed_Material_INST');
			EatPart.SetMaterialParameter('PartMatGibs',MaterialInstanceConstant'Grow_John_Assets.Materials.Eating_Chunks_Speed_Mat_INST');
			break;
		case FOOD_FRUIT_LARGE:
		case FOOD_FRUIT_MEDIUM:
		case FOOD_FRUIT_SMALL:
			EatPart.SetMaterialParameter('PartMat', MaterialInstanceConstant'Grow_John_Assets.Materials.Gib_Skill_Material_INST');
			EatPart.SetMaterialParameter('PartMatGibs',MaterialInstanceConstant'Grow_John_Assets.Materials.Eating_Chunks_Skill_Mat_INST');
			break;
		case FOOD_MEAT_LARGE:
		case FOOD_MEAT_MEDIUM:
		case FOOD_MEAT_SMALL:
		default:
			EatPart.SetMaterialParameter('PartMat', MaterialInstanceConstant'Grow_John_Assets.Materials.Gib_Power_Material_INST');
			EatPart.SetMaterialParameter('PartMatGibs',MaterialInstanceConstant'Grow_John_Assets.Materials.Eating_Chunks_Power_Mat_INST');
			break;
		}
		CurrentEatenFoodMesh.SetHidden(false);
		HoldingFood = true;
	}
}
`if(`notdefined(FINAL_RELEASE))
exec function ActorDebug() {
	ServerDebug();
	ClientDebug();
}
reliable server function ServerDebug() {
	DisplayADebug();
}
reliable client function ClientDebug() {
	DisplayADebug();
}

simulated function DisplayADebug() {
	local GWPawn GWP;
	local GWPlayerController GWPC;
	local GWWeap GWW;
	local GWFoodActor GWFA;
	local Actor GWPL;
	local int Count;

	//`Log("==============Pawn Debug==============");
	Count = 0;
	foreach AllActors(class'GWPawn', GWP) {
	//	`Log(GWP.name@"Role ="@GWP.Role);
		Count++;
	}
	//`Log("Total Pawns:"@Count);

	//`Log("==============Controllers Debug==============");
	Count = 0;
	foreach AllActors(class'GWPlayerController', GWPC) {
	//	`Log(GWPC.name@"Role ="@GWPC.Role);
		Count++;
	}
	//`Log("Total Controllers:"@Count);

	//`Log("==============Weapons Debug==============");
	Count = 0;
	foreach AllActors(class'GWWeap', GWW) {
	//	`Log(GWW.name@"Role ="@GWW.Role);
		Count++;
	}
	//`Log("Total Weapons:"@Count);

	//`Log("==============Food Debug==============");
	Count = 0;
	foreach AllActors(class'GWFoodActor', GWFA) {
	//	`Log(GWFA.name@"Type:"@GWFA.FoodType@"Role ="@GWFA.Role);
		Count++;
	}
	//`Log("Total Food:"@Count);
	`Log("==============All Debug==============");
	Count = 0;
	foreach AllActors(class'Actor', GWPL) {
		`Log(GWPL.name@"Role ="@GWPL.Role);
		Count++;
	}
	`Log("Total Actors:"@Count);
}

exec function PawnDebug() {
	ServerPDebug();
	ClientPDebug();
}
reliable server function ServerPDebug() {
	PawnADebug();
}
reliable client function ClientPDebug() {
	PawnADebug();
}

simulated function PawnADebug() {
	`Log("Pawn Physics:"@Physics@"Pawn State:"@GetStateName());
	`Log("Controller Physics:"@Controller.Physics@"Controller State:"@Controller.GetStateName());
}
`endif
exec function GrowPower()
{
	GrowType = 1;
	//stop movement
}

exec function GrowSpeed()
{
	GrowType = 2;
}

exec function GrowSkill()
{
	GrowType = 3;
}

exec function StopGrow()
{
	GrowType = 0;
	//start movement
}
`if(`notdefined(FINAL_RELEASE))
exec function SocketDebug() {
	local Vector Loc;
	local Rotator Rot;
	local UTCarriedObject Flag;
	local GWPawn GWP;

	foreach AllActors(class'GWPawn', GWP) {
		GWP.Mesh.GetSocketWorldLocationAndRotation('FlagPoint', Loc, Rot);
		`Log("FlagPoint is ("$Loc$") ("$Rot$")");
		if(UTPlayerReplicationInfo(GWP.PlayerReplicationInfo).GetFlag() != none) {
			Flag = UTPlayerReplicationInfo(GWP.PlayerReplicationInfo).GetFlag();
			`Log("("$Flag.Location$") ("$Flag.RelativeLocation$") ("$Flag.Rotation$") ("$Flag.RelativeRotation$")");
		}
	}
	ServerSocketFunction();
}
reliable server function ServerSocketFunction() {
	local Vector Loc;
	local Rotator Rot;
	local UTCarriedObject Flag;
	local GWPawn GWP;

	foreach AllActors(class'GWPawn', GWP) {
		GWP.Mesh.GetSocketWorldLocationAndRotation('FlagPoint', Loc, Rot);
		`Log("FlagPoint is ("$Loc$") ("$Rot$")");
		if(UTPlayerReplicationInfo(GWP.PlayerReplicationInfo).GetFlag() != none) {
			Flag = UTPlayerReplicationInfo(GWP.PlayerReplicationInfo).GetFlag();
			`Log("("$Flag.Location$") ("$Flag.RelativeLocation$") ("$Flag.Rotation$") ("$Flag.RelativeRotation$")");
		}
	}
}
`endif
/* BecomeViewTarget
	Called by Camera when this actor becomes its ViewTarget */
simulated event BecomeViewTarget( PlayerController PC )
{
	local GWPlayerController GWPC;

	Super.BecomeViewTarget(PC);

	if (LocalPlayer(PC.Player) != None)
	{
		//AttachComponent(FaceCam);
		GWPC = GWPlayerController(PC);
		if (GWPC != None)
		{
			if(Role == ROLE_Authority) {
				GWPC.SetBehindView(true);
			} else {
				GWPC.ServerSetBehindView(true);
			}
			/*if(GWGFxHudWrapper(GWPC.myHUD) != none) {
				GWGFxHudWrapper(GWPC.myHUD).HudMovie.InitCam(self, MakeColor(255,0,255));
			}*/
			CreateFaceCam();
		}
	}
}

/* EndViewTarget
	Called by Camera when this actor becomes its ViewTarget */
simulated event EndViewTarget( PlayerController PC )
{
	super.EndViewTarget(PC);
	if (LocalPlayer(PC.Player) != None)
	{
		SetMeshVisibility(true);
		//DetachComponent(FaceCam);
	}
}
simulated function WeaponFired(Weapon InWeapon, bool bViaReplication, optional vector HitLocation) {
	local ParticleSystem MuzzleTemplate;
	//`Log(Instigator@"fired Muzzle Flash");

	if (MuzzleFlashPSC != none)
	{
		if ( !bMuzzleFlashPSCLoops || !MuzzleFlashPSC.bIsActive)
		{
			MuzzleTemplate = MuzzleFlashPSCTemplate[Instigator.FiringMode];
			
			if (MuzzleTemplate != MuzzleFlashPSC.Template)
			{
				MuzzleFlashPSC.SetTemplate(MuzzleTemplate);
			}
			SetMuzzleFlashParams(MuzzleFlashPSC);
			MuzzleFlashPSC.ActivateSystem();
		}
	}

	// Set when to turn it off.
	//SetTimer(MuzzleFlashDuration,false,'MuzzleFlashTimer');
}
simulated function MuzzleFlashTimer()
{
	if (MuzzleFlashPSC != none && (!bMuzzleFlashPSCLoops) )
	{
		MuzzleFlashPSC.DeactivateSystem();
	}
}

simulated function SetMuzzleFlashParams(ParticleSystemComponent PSC)
{
}
simulated function WeaponStoppedFiring(Weapon InWeapon, bool bViaReplication)
{
	//ClearTimer('MuzzleFlashTimer');
	MuzzleFlashTimer();

	if ( MuzzleFlashPSC != none )
	{
		MuzzleFlashPSC.DeactivateSystem();
	}
}
exec function SetHitBox(Vector extent, Vector Trans) {
	HitBox.BoxExtent = extent;
	HitBox.SetTranslation(Trans);
}
exec function SetPrimaryColour(float r, float g, float b) {
	local LinearColor LC;
	
	LC = MakeLinearColor(r,g,b,1);
	BodyMaterialInstances[0].SetVectorParameterValue('PrimaryColour', LC);
}
exec function SetSecondaryColour(float r, float g, float b) {
	local LinearColor LC;
	
	LC = MakeLinearColor(r,g,b,1);
	BodyMaterialInstances[0].SetVectorParameterValue('SecondaryColour', LC);
}
function bool Dodge(eDoubleClickDir DoubleClickMove)
{
	return false;
}
function bool PerformDodge(eDoubleClickDir DoubleClickMove, vector Dir, vector Cross)
{
	local float VelocityZ;

	if ( Physics == PHYS_Falling )
	{
		TakeFallingDamage();
	}

	bDodging = true;
	bReadyToDoubleJump = (JumpBootCharge > 0);
	VelocityZ = Velocity.Z;
	Velocity = DodgeSpeed*Dir + (Velocity Dot Cross)*Cross;

	if ( VelocityZ < -200 )
		Velocity.Z = VelocityZ + DodgeSpeedZ;
	else
		Velocity.Z = DodgeSpeedZ;

	CurrentDir = DoubleClickMove;
	SetPhysics(PHYS_Falling);
	//SoundGroupClass.Static.PlayDodgeSound(self);
	return true;
}

exec function SetDodgeSpeed(float A) {
	DodgeSpeed = A;
}
exec function SetDodgeZ(float A) {
	DodgeSpeedZ = A;
}
exec function TestStun(float Time) {
	GWPlayerController(Controller).ServerStun(Time);
}
exec function DestroyServerWeapon() {
	ServerDestroyWeapon();
}
server reliable function ServerDestroyWeapon() {
	Weapon.Destroy();
	PlayerController(Controller).NextWeapon();
}
exec function DestroyClientWeapon() {
	ClientDestroyWeapon();
}
client reliable function ClientDestroyWeapon() {
	Weapon.Destroy();
}
exec function DestroyWeapon() {
	ServerDestroyWeapon();
	ClientDestroyWeapon();
}
exec function DisplayWeapon() {
	`Log("Weapon:"@Weapon);
}

exec function DebugAnimAction() {
	`Log("Head Anim:"@HeadAnimList.ActiveChildIndex);
	`Log("Body Anim:"@BodyAnimList.ActiveChildIndex);
	`Log("Head Blend:"@AnimHeadBlend.Child2PerBoneWeight[0]);
	`Log("Head Blend:"@AnimHeadBlend.Child2PerBoneWeight[1]);
}

DefaultProperties
{
	//"when you spawn a model as a pawn's visual mesh, things like whether or not it uses cloth simulation need to be set again manually, regardless of what you ticked in the content browser" "they need to be always relevant"
	Form = FORM_NONE
	TriggerOpacity = 1.0f

	bLockGrow = false;
	PowerCharge = 1.9;
	SlopeBoostFriction=1;

	//CamOffset = (X=7,Y=0,Z=15)
	begin object Name=WPawnSkeletalMeshComponent
		Translation=(X=0,Y=0,Z=0)
		Scale=1
		bHasPhysicsAssetInstance=false
	end object
	SoundGroupClass=class'GWSoundGroup'
	DefaultMeshScale=1
	BaseTranslationOffset=0
	Size = 0

	// Movement Speed
	GroundSpeed = 600 // 200 + 100x
	AirSpeed = 600 // 200 + 100x
	WaterSpeed = 200 // 100 + 50x
	LadderSpeed = 300 // 75% Speed
	AccelRate = 2048
	DodgeSpeed=1200.0
	DodgeSpeedZ=400.0

	// Damage Scaling
	DamageScaling = 1

	// Firing Rate
	
	// Max Health
	Health = 10
	HealthMax = 10
	
	// Swim?
	bCanSwim = false
	Buoyancy = 1
	//WaterMovementState=PlayerSwimming
	// Climb?
	bCanClimbLadders = false
	SwimmingZOffset = 0

	//Size
	HeadRadius=+0.0
	HeadHeight=0.0
	HeadScale=+0.0
	HeadOffset=0.0
	BaseEyeHeight=2.7
	
	bCanCrouch = false
	MaxStepHeight = 15.0
	MaxJumpHeight = 100.0
	JumpZ = 700.0
	//MaxDoubleJumpHeight = 500.0
	DoubleJumpEyeHeight = 43.0
	OutofWaterZ=+600.0
	MaxOutOfWaterStepHeight=80.0
	Mass=+00100.000000 //Used by TakeDamage Launching and CrushedBy (goomba stomp)
	WalkableFloorZ=0.5
	MaxFallSpeed=9999999
	InventoryManagerClass=class'GWInventoryManager'

	Begin Object Class=SkeletalMeshComponent Name=HatMesh
		CastShadow=true
		bCastDynamicShadow=true
		bOwnerNoSee=false
		LightEnvironment=MyLightEnvironment
	End Object
	HatSkeletalMesh = HatMesh

	DeathPartScale = 1.0f
	Begin Object Class=ParticleSystemComponent Name=StunPartComp
		bAutoActivate=false
		Template=ParticleSystem'Grow_Effects.Effects.BirdStunEffect'
		//InstanceParameters(0)=(Name=PartMat,ParamType=PSPT_Material,Material=Material'Grow_Effects.Materials.Drop_Mat')
		//Scale=1.0
	End Object
	StunPart=StunPartComp
	Components.Add(StunPartComp)
	Begin Object Class=ParticleSystemComponent Name=StinkPartComp
		bAutoActivate=false
		Template=ParticleSystem'G_FX_CH_Scampers.Effects.PS_Stink_Ribbon_Effect'
		//InstanceParameters(0)=(Name=PartMat,ParamType=PSPT_Material,Material=Material'Grow_Effects.Materials.Drop_Mat')
		//Scale=1.0
	End Object
	StinkPart=StinkPartComp
	Components.Add(StinkPartComp)
	Begin Object Class=ParticleSystemComponent Name=BurnPartComp
		bAutoActivate=false
		Template=ParticleSystem'Grow_John_Assets.Effects.Chilli_Effect'
		//InstanceParameters(0)=(Name=PartMat,ParamType=PSPT_Material,Material=Material'Grow_Effects.Materials.Drop_Mat')
		//Scale=1.0
	End Object
	BurnPart=BurnPartComp
	Components.Add(BurnPartComp)
	Begin Object Class=ParticleSystemComponent Name=EatPartComp
		bAutoActivate=false
		Template=ParticleSystem'Grow_John_Assets.Effects.Food_eating_effect'
		InstanceParameters(0)=(Name=PartMat,ParamType=PSPT_Material,Material=Material'Grow_John_Assets.Materials.Gib_Material')
		InstanceParameters(1)=(Name=PartMatGibs,ParamType=PSPT_Material,Material=Material'Grow_John_Assets.Materials.Eating_Chunks_Mat')
		//Scale=1.0
	End Object
	EatPart=EatPartComp
	Components.Add(EatPartComp)
	ArmorHitSound=none
	FallImpactSound=none
	SpawnSound=none
	TeleportSound=none
	SpawnProtectionColor=(R=0,G=0,B=0)

	//bPushesRigidBodies=true
	bPostRenderIfNotVisible=true
	bPostRenderOtherTeam=true
	TeamBeaconMaxDist=3000.f
	//bAlwaysRelevant=true
	/*Begin Object Class=DecalComponent Name=Decal
		DecalTransform=DecalTransform_OwnerRelative
		ParentRelativeOrientation=(Yaw=0,Pitch=-16384,Roll=0)  // Yaw - left right, pitch - up down
		DecalMaterial=DecalMaterial'WP_BioRifle.Materials.Bio_Splat_Decal'
		bMovableDecal=true
	End Object
	Components.Add(Decal)*/
	//bCrawler=true
		//MaxMultiJump=2
	AirControl=0.3
	DefaultAirControl=0.3
	Begin Object Class=StaticMeshComponent Name=EatenFoodComponent
		BlockActors=false
		CollideActors=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		HiddenGame=true
		HiddenEditor=true
		LightingChannels=(Dynamic=true)
		Scale3D=(X=1.0,Y=1.0,Z=1.0)
	End Object
	CurrentEatenFoodMesh = EatenFoodComponent
	Components.Add(EatenFoodComponent)

	/*Begin Object Class=UDKSkeletalMeshComponent Name=FaceCamComp
		PhysicsAsset=None
		FOV=55
		DepthPriorityGroup=SDPG_Foreground
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bOnlyOwnerSee=true
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=FALSE
		//AbsoluteTranslation=false
		AbsoluteRotation=false
		//AbsoluteScale=true
		bSyncActorLocationToRootRigidBody=false
		CastShadow=false
		TickGroup=TG_DuringASyncWork
	End Object
	FaceCam=FaceCamComp*/
	begin object Class=DrawBoxComponent Name=HitBoxComp
		BoxExtent=(X=200.0, Y=200.0, Z=200.0)
		//HiddenGame=false
		BoxColor=(R=0,G=255,B=0)
	end object
	HitBox=HitBoxComp
	Components.Add(HitBoxComp)

	begin object Class=DrawBoxComponent Name=BiteBoxComp
		BoxExtent=(X=200.0, Y=200.0, Z=200.0)
		//HiddenGame=false
		BoxColor=(R=255,G=0,B=0)
	end object

	BiteBox=BiteBoxComp
	Components.Add(BiteBoxComp)
	//ArmsMesh[0]=FirstPersonArms
	WeaponSocket=WeaponPoint
	MuzzleFlashDuration=0.3
	MuzzleFlashPSCTemplate[5]=ParticleSystem'Grow_John_Assets.Effects.Spew_effect'
	bCanFlinch=true
	FaceCamCharacterPicture=Texture2D'Grow_John_Assets.Textures.waternormal_tex'
	CharacterPortraitRT=TextureRenderTarget2D'Grow_HUD.CharacterPortraitRT'
}