class GWPawn_SkillPower extends GWPawn;

var bool bTransitioning;

simulated function StartAbilityStartAnimation() {
	super.StartAbilityStartAnimation();
	Controller.GotoState('PlayerAbility');
	GotoState('PlayerAbility');
	bTransitioning = true;
}
simulated function StartAttackAnimation() {}
simulated function StopAbilityStartAnimation() {
	super.StopAbilityStartAnimation();
	if(!Controller.IsInState('PlayerAbility')) {
		StopAbilityEndAnimation();
		bTransitioning = false;
		return;
	}
	bTransitioning = false;
}

simulated function StopAbilityEndAnimation() {
	super.StopAbilityEndAnimation();
	Controller.GotoNormalState();
	GotoState('');
}
simulated event Tick(float DeltaTime) {
	if(Controller != none && Controller.IsInState('PlayerAbility') && !bTransitioning) {
		Controller.GotoNormalState();
	}
	super.Tick(DeltaTime);
}
function TakeDrowningDamage()
{
	BreathTime = 0;
	return;
}

simulated state PlayerAbility {
	ignores StartAbilityStartAnimation;

	event TakeDamage(int Damage, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser) {
		Momentum=vect3d(0,0,0);
		super.TakeDamage(Damage, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	}
	simulated function AdjustDamage(out int InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser)
	{
		if(!DamageType.default.bArmorStops) {
			return;
		}
		super.AdjustDamage(InDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);

		InDamage *= 0.25;
	}
	simulated function StartAttackAnimation() {
		if(bool(AnimExists[4])) {
			StopAbilityLoopAnimation();
		}
		PlayAnimList(2, true);
	}
	simulated function StopAttackAnimation() {
		PlayAnimList(2, false);
		if(bool(AnimExists[4])) {
			StartAbilityLoopAnimation();
		}
	}
	simulated event Tick(float DeltaTime) {
		if(Controller != none && !Controller.IsInState('PlayerAbility')) {
			Controller.GotoState('PlayerAbility');
		}
		super(GWPawn).Tick(DeltaTime);
	}
	function BeginState(Name PreviousStateName) {
		bCanFlinch = false;
	}
	function EndState( Name NextStatename) {
		bCanFlinch = true;
	}
	function AddVelocity( vector NewVelocity, vector HitLocation, class<DamageType> DamageType, optional TraceHitInfo HitInfo ) {}
}
function PlayerAbilityMove(float DeltaTime, PlayerInput PInput) {
	PInput.aForward = 0;
	PInput.aStrafe = 0;
	PInput.aUp = 0;
	PlayerController(Controller).bPressedJump = false;
}
function ProcessAbilityViewRotation( float DeltaTime, out rotator out_ViewRotation, out Rotator out_DeltaRot ) {
	out_DeltaRot.Yaw = FClamp(out_DeltaRot.Yaw, -90 * DeltaTime * DegToUnrRot, 90 * DeltaTime * DegToUnrRot);
}
DefaultProperties
{
	Form = FORM_SKILL_POWER

	CamOffset = (X=60,Y=0,Z=85)

	// Movement Speed
	GroundSpeed = 650
	AirSpeed = 600
	WaterSpeed = 750
	LadderSpeed = 300
	AccelRate = 600
	Mass=+0300.000000

	// Damage Scaling
	DamageScaling = 1

	// Firing Rate
	
	// Max Health
	Health = 200
	HealthMax = 200
		
	// Swim?
	bCanSwim = true
	Buoyancy = 1
	//WaterMovementState=PlayerSwimming
	// Climb?
	bCanClimbLadders = false
	Begin Object Name=CollisionCylinder
		CollisionRadius=+055.000000
		CollisionHeight=+047.000000
	End Object

	begin object Name=HitBoxComp
		BoxExtent=(Y=62, Z=57, X=60)
		Translation=(Z=23.5, X=-3)
	end object
	HitBoxInfo=(Offset=(Z=23.5, X=-3),Radius=(Y=62, Z=57, X=60))

	begin object Name=BiteBoxComp
		HiddenGame=true
	end object

	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'G_CH_Spiral.AnimTrees.AT_Spiral'
		AnimSets[0]=AnimSet'G_CH_Spiral.AnimSets.AS_Spiral'
		SkeletalMesh=SkeletalMesh'G_CH_Spiral.Mesh.SK_Spiral'
	End Object

	TeamMaterials[0]=MaterialInstanceConstant'G_CH_Spiral.Materials.MI_Spiral_Creepy'
	TeamMaterials[1]=MaterialInstanceConstant'G_CH_Spiral.Materials.MI_Spiral_Cute'
	TeamMaterials[2]=MaterialInstanceConstant'G_CH_Spiral.Materials.MI_Spiral_Neutral'
	CharacterName = "Spiral"
	CharacterColour = (R=122,G=65,B=186,A=0)
	SoundGroupClass=class'GWSoundGroup_SkillPower'
}
