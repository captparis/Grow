class GWPawn_Speed extends GWPawn;

var bool bLunging;
var bool bAttacking;
var MorphNodeWeight NodeSpikes;

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp) {
	super.PostInitAnimTree(SkelComp);

	NodeSpikes = MorphNodeWeight(SkelComp.FindMorphNode('MorphSpikes'));
}

function bool DoJump( bool bUpdating )
{
	local bool JumpSuccess;

	JumpSuccess = super.DoJump(bUpdating);

	if(Role > ROLE_SimulatedProxy && JumpSuccess && GWWeap_Speed(Weapon) != none) {
		SetTimer(0.3, true, 'JumpAttack');
		bAttacking = true;
	}
	return JumpSuccess;
}
function JumpAttack() {
	if(bAttacking) {
		if(Role == ROLE_Authority) {
			HurtRadius(5, 250, class'GWDmgType_TailWhip', 0, Location, self, Controller, true);
		}
		class<GWSoundGroup_Speed>(SoundGroupClass).static.PlayTailWhipSound(self);
		IncrementFlashCount(none, 6);
	}
}
simulated function WeaponFired(Weapon InWeapon, bool bViaReplication, optional vector HitLocation) {
	`Log(GetFuncName()@FiringMode);
	if(FiringMode == 6) {
		NodeSpikes.SetNodeWeight(1.0f);
	}
	super.WeaponFired(InWeapon, bViaReplication, HitLocation);
}

simulated function WeaponStoppedFiring(Weapon InWeapon, bool bViaReplication)
{
	`Log(GetFuncName()@FiringMode);
	if(FiringMode == 6) {
		NodeSpikes.SetNodeWeight(0);
	}
	super.WeaponStoppedFiring(InWeapon, bViaReplication);
}
exec function SetSpikes(bool newValue) {
	if(newValue) {
		NodeSpikes.SetNodeWeight(1.0f);
	} else {
		NodeSpikes.SetNodeWeight(0);
	}
}
simulated function SetMuzzleFlashParams(ParticleSystemComponent PSC) {
	local Vector TeamColor;
	if(FiringMode == 6) {
		if(GetTeamNum() == 1) {
			TeamColor = vect3d(1,1,0);
		} else {
			TeamColor = vect3d(1,0,1);
		}
		PSC.SetVectorParameter('scamperwhip_col', TeamColor);
	}
	super.SetMuzzleFlashParams(PSC);
}
event Bump(Actor Other, PrimitiveComponent OtherComp, vector HitNormal) {
	//Called by actors and pawns *NOTE* Collision Actors also call HitWall
	//HitNormal is the Normal of the Surface hit
	
	local GWPawn P;

	if(!bLunging) {
		return;
	}
	if ( WorldInfo.NetMode != NM_DedicatedServer )
	{
		//PlaySound(ImpactSound, true);
	}
	
	if(GWPawn(Other) != none) {
		P = GWPawn(Other);

		if(IsEnemyTeam(P)) {
			P.TakeDamage(20, Controller, Location, vect3d(0,0,0), class'GWDmgType_Lunge');
			P.IncrementStatusEffect(EFFECT_SCAMPER_STINK, Controller);
			class<GWSoundGroup_Speed>(SoundGroupClass).static.PlayStinkSound(self);
		}
	}
	bLunging = false;
}
simulated function PhysicsVolumeChange( PhysicsVolume NewVolume )
{
	if ( WaterVolume(NewVolume) != none )
	{
		bLunging = false;
		if(bAttacking) {
			bAttacking = false;
			ClearTimer('JumpAttack');
			ClearFlashCount(none);
		}
	}

	Super.PhysicsVolumeChange(NewVolume);
}
event Landed(vector HitNormal, actor FloorActor)
{
	bLunging = false;
	if(bAttacking) {
		bAttacking = false;
		ClearTimer('JumpAttack');
		ClearFlashCount(none);
	}
	Super.Landed(HitNormal, FloorActor);
}
DefaultProperties
{
	Form = FORM_SPEED
	CamOffset = (X=50,Y=0,Z=70)
	// Movement Speed
	GroundSpeed = 1000
	AirSpeed = 760
	WaterSpeed = 690
	LadderSpeed = 600
	AccelRate = 1000
	MaxJumpHeight = 100.0
	MaxDoubleJumpHeight = 180.0
	Mass=+0100.000000

	// Damage Scaling
	DamageScaling = 1

	// Firing Rate
	
	// Max Health
	Health = 125
	HealthMax = 125
	
	// Swim?
	bCanSwim = false
	//Buoyancy = 1.5
	WaterMovementState=PlayerFloating
	// Climb?
	bCanClimbLadders = true

	Begin Object Name=CollisionCylinder
		CollisionRadius=+060.00000
		CollisionHeight=+031.000000
	End Object

	begin object Name=HitBoxComp
		BoxExtent=(Y=31.5, Z=31, X=60)
		Translation=(Z=0, X=-8)
	end object
	HitBoxInfo=(Offset=(Z=0, X=-8),Radius=(Y=31.5, Z=31, X=60))
	begin object Name=BiteBoxComp
		BoxExtent=(X=75, Y=25, Z=25)
		Translation=(X=75, Z=12.5)
	end object

	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'G_CH_Scamper.AnimTrees.AT_Scamper'
		AnimSets[0]=AnimSet'G_CH_Scamper.AnimSets.AS_Scamper'
		SkeletalMesh=SkeletalMesh'G_CH_Scamper.Mesh.SK_Scamper'
		MorphSets[0]=MorphTargetSet'G_CH_Scamper.Mesh.MT_Scamper'
	End Object

	BaseEyeHeight=3

	TeamMaterials[0]=MaterialInstanceConstant'G_CH_Scamper.Materials.MI_Scamper_Creepy'
	TeamMaterials[1]=MaterialInstanceConstant'G_CH_Scamper.Materials.MI_Scamper_Cute'
	TeamMaterials[2]=MaterialInstanceConstant'G_CH_Scamper.Materials.MI_Scamper_Neutral'
	CharacterName = "Scamper"
	CharacterColour = (R=186,G=255,B=0,A=0)
	MuzzleFlashPSCTemplate[0]=ParticleSystem'G_FX_CH_Scampers.Effects.PS_Stink_Ribbon_Effect'
	MuzzleFlashPSCTemplate[6]=ParticleSystem'Grow_John_Assets.Effects.ScamperWhip_Effect'
	SoundGroupClass=class'GWSoundGroup_Speed'
}
