class GWPawn_Power extends GWPawn;

var int DamageStacks;
var float DamageStackTimes[8];
var const int StackBonus, MaxBonus;
var byte ComboNumber;
var ParticleSystem AbilityPulsePSCTemplate;

var ParticleSystemComponent RagePart;

replication {
	if(true)
		ComboNumber;
}

event TakeDamage(int Damage, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	Super.TakeDamage(Damage, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	if(Damage == 0 || EventInstigator == Controller || DamageCauser == self || DamageType.default.bCausedByWorld ) {
		return;
	}
	AddStack();
}

function RemoveStack() {
	local byte i;
	for(i = 0; i < 7; i++) {
		DamageStackTimes[i] = DamageStackTimes[i+1];
	}
	DamageStackTimes[7] = 0;
	DamageStacks--;
	if(DamageStacks > 0) {
		SetTimer(DamageStackTimes[0] - WorldInfo.TimeSeconds, false, 'RemoveStack');
	}
	UpdateStacks();
}
function AddStack() {
	local byte i;
	if(DamageStacks >= 8) {
		for(i = 0; i < 7; i++) {
			DamageStackTimes[i] = DamageStackTimes[i+1];
		}
		DamageStackTimes[7] = WorldInfo.TimeSeconds + 5;
	} else {
		DamageStackTimes[DamageStacks] = WorldInfo.TimeSeconds + 5;
		DamageStacks++;
	}
	SetTimer(DamageStackTimes[0] - WorldInfo.TimeSeconds, false, 'RemoveStack');
	UpdateStacks();
}

function UpdateStacks() 
{
	if(DamageStacks > 0) {
		IncrementStatusEffect(EFFECT_GROWL_RAGE, Controller);
	} else {
		ClearStatusEffect(EFFECT_GROWL_RAGE);
	}
}
simulated function IncrementStatusEffect(EStatusEffects Stat, Controller CausedBy)
{
	if(Stat == EFFECT_GROWL_RAGE) {
		bForceNetUpdate = TRUE;	// Force replication
		StatusEffects[Stat] = DamageStacks;
		StatusEffectsCausedBy[Stat] = CausedBy;

		// Make sure it's not 0, because it means the weapon stopped firing!
		if( StatusEffects[Stat] == 0 )
		{
			StatusEffects[Stat] += 2;
		}
		
		// This weapon has fired.
		StatusEffectUpdated(FALSE);
	} else {
		super.IncrementStatusEffect(Stat, CausedBy);
	}
}

simulated function WeaponFired(Weapon InWeapon, bool bViaReplication, optional vector HitLocation) {
	`Log("Combo Number:"@ComboNumber);
	if(ComboNumber == 3 && FiringMode == 1) {
		
		//`Log(Instigator@"fired Muzzle Flash");

		if (MuzzleFlashPSC != none) {
			if ( !bMuzzleFlashPSCLoops || !MuzzleFlashPSC.bIsActive) {
				if (AbilityPulsePSCTemplate != MuzzleFlashPSC.Template){
					MuzzleFlashPSC.SetTemplate(AbilityPulsePSCTemplate);
				}
				SetMuzzleFlashParams(MuzzleFlashPSC);
				MuzzleFlashPSC.ActivateSystem();
			}
		}
	} else {
		super.WeaponFired(InWeapon, bViaReplication, HitLocation);
	}
}
simulated function StatusEffectStart(EStatusEffects Stat, bool bViaReplication) {
	//local PlayerController PC;

	switch(Stat) {
	case EFFECT_GROWL_RAGE:
		ModifySpeed();
		RagePart.ActivateSystem();
		break;
	default:
		super.StatusEffectStart(Stat, bViaReplication);
	}
}
function float ModifySpeed(optional float Multiplier) {
	local int RageBuff;
	if(Multiplier == 0) {
		Multiplier = 1;
	}
	Multiplier = super.ModifySpeed(Multiplier);

	RageBuff = StatusEffects[EFFECT_GROWL_RAGE] * StackBonus;
	
	GroundSpeed = Multiplier * (default.GroundSpeed + RageBuff);
	AirSpeed = Multiplier * (default.AirSpeed + RageBuff);
	WaterSpeed = Multiplier * (default.WaterSpeed + RageBuff);
	LadderSpeed = Multiplier * (default.LadderSpeed + RageBuff);
	AccelRate = Multiplier * (default.AccelRate + RageBuff);

	return Multiplier;
}
simulated function StatusEffectStop(EStatusEffects Stat, bool bViaReplication) {
	switch(Stat) {
	case EFFECT_GROWL_RAGE:
		ModifySpeed();
		RagePart.DeactivateSystem();
		break;
	default:
		super.StatusEffectStop(Stat, bViaReplication);
	}
}
DefaultProperties
{
	Form = FORM_POWER
	CamOffset = (X=50,Y=0,Z=70)
	// Movement Speed
	GroundSpeed = 900
	AirSpeed = 700
	WaterSpeed = 450
	LadderSpeed = 300
	AccelRate = 500
	JumpZ = 1000
	CustomGravityScaling=1.5

	Mass=+0300.000000

	// Damage Scaling
	DamageScaling = 1

	// Firing Rate
	
	// Max Health
	Health = 200
	HealthMax = 200
	
	
	Buoyancy = 0
	bCanSwim=false
	WaterMovementState=PlayerWalking
	UnderWaterTime = 10

	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'G_CH_Growl.AnimTrees.AT_Growl'
		AnimSets[0]=AnimSet'G_CH_Growl.AnimSets.AS_Growl'
		SkeletalMesh=SkeletalMesh'G_CH_Growl.Mesh.SK_Growl'
		Scale3D=(X=3,Y=3,Z=3)
	End Object

	Begin Object Class=ParticleSystemComponent Name=RagePartComp
		bAutoActivate=false
		Template=ParticleSystem'Grow_John_Assets.Effects.Rage_Buff_Alternate_Effect'
		Scale=3.0
	End Object
	RagePart=RagePartComp
	Components.Add(RagePartComp)

	Begin Object Name=CollisionCylinder
		CollisionRadius=+070.000000
		CollisionHeight=+047.000000
	End Object

	TeamMaterials[0]=MaterialInstanceConstant'G_CH_Growl.Materials.MI_Growl_Creepy'
	TeamMaterials[1]=MaterialInstanceConstant'G_CH_Growl.Materials.MI_Growl_Cute'
	TeamMaterials[2]=MaterialInstanceConstant'G_CH_Growl.Materials.MI_Growl_Neutral'

	StackBonus = 40
	MaxBonus = 300

	begin object Name=HitBoxComp
		BoxExtent=(Y=57, Z=57, X=88)
		Translation=(Z=20, X=0)
	end object
	HitBoxInfo=(Offset=(Z=20, X=0),Radius=(Y=57, Z=57, X=88))
	begin object Name=BiteBoxComp
		BoxExtent=(X=100, Y=37.5, Z=37.5)
		Translation=(X=100, Z=18.75)
	end object

	CharacterName = "Growl"
	CharacterColour = (R=255,G=186,B=0,A=0)
	SoundGroupClass=class'GWSoundGroup_Power'
	MuzzleFlashPSCTemplate[0]=ParticleSystem'Grow_Effects.Effects.Bite'
	MuzzleFlashPSCTemplate[1]=ParticleSystem'Grow_Effects.Effects.Growl_Bark_Noise'
	AbilityPulsePSCTemplate=ParticleSystem'Grow_Effects.Effects.SonicBarkS4_Effect'

}
