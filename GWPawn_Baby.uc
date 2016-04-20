class GWPawn_Baby extends GWPawn;

var ParticleSystemComponent EyeParticleL;
var ParticleSystemComponent EyeParticleR;
var ParticleSystemComponent FrenzyStartPart;

/*var Name SkelControlLookAtName;
var SkelControlLookAt SkelControlLookAt;

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
  Super.PostInitAnimTree(SkelComp);

  if (SkelComp == Mesh)
  {
    SkelControlLookAt = SkelControlLookAt(Mesh.FindSkelControl('NomHead'));
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
      SkelControlLookAt.TargetLocation = PlayerController.Pawn.Location;
    } else {
		SkelControlLookAt.SetSkelControlActive(false);
    }
  }
}*/

state PlayerAbility {
	event Bump(Actor Other, PrimitiveComponent OtherComp, vector HitNormal) {
		//Called by actors and pawns *NOTE* Collision Actors also call HitWall
		//HitNormal is the Normal of the Surface hit
		
		local GWPawn P;
		local GWFoodActor FA;
		local SFoodInfo FI;
		
		if ( WorldInfo.NetMode != NM_DedicatedServer )
		{
			//PlaySound(ImpactSound, true);
		}

		if(GWPawn(Other) != none) {
			P = GWPawn(Other);

			if(IsEnemyTeam(P)) {
				P.TakeDamage(0, Controller, Location, (Normal(Velocity) + vect3d(0,0, 0.3)) * 10000, class'GWDmgType_Bite');
			}
		} else if(GWFoodActor(Other) != none) {
			FA = GWFoodActor(Other);
			`Log("Bump Food");

			FI = class'GWConstants'.default.FoodStats[FA.FoodType];

			switch (FA.FoodType) {
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
				EatPart.SetMaterialParameter('PartMat', MaterialInstanceConstant'Grow_John_Assets.Materials.Gib_Power_Material_INST');
				EatPart.SetMaterialParameter('PartMatGibs',MaterialInstanceConstant'Grow_John_Assets.Materials.Eating_Chunks_Power_Mat_INST');
				break;
			}

			EatPart.ActivateSystem(false);
			
			Health = Clamp(Health + FI.HealAmount * 2 * FI.Size, Health, HealthMax);
			IncrementAbility(FI.StatName, FI.FoodAmount * FI.Size * 2);
			
			FA.Destroy();
		}
	}
	event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal ) {
		local GWFoodActor FA;
		local SFoodInfo FI;
		
		if ( WorldInfo.NetMode != NM_DedicatedServer )
		{
			//PlaySound(ImpactSound, true);
		}

		if(GWFoodActor(Other) != none) {
			FA = GWFoodActor(Other);
			`Log("Touch Food");
	
			FI = class'GWConstants'.default.FoodStats[FA.FoodType];

			switch (FA.FoodType) {
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
				EatPart.SetMaterialParameter('PartMat', MaterialInstanceConstant'Grow_John_Assets.Materials.Gib_Power_Material_INST');
				EatPart.SetMaterialParameter('PartMatGibs',MaterialInstanceConstant'Grow_John_Assets.Materials.Eating_Chunks_Power_Mat_INST');
				break;
			}

			EatPart.ActivateSystem(false);
			
			Health = Clamp(Health + FI.HealAmount * 2 * FI.Size, Health, HealthMax);
			IncrementAbility(FI.StatName, FI.FoodAmount * FI.Size * 2);
			
			FA.Destroy();
		}
	}
}
simulated function AttachWeaponEffects() {
	super.AttachWeaponEffects();
	if(Mesh.GetSocketByName('LEyePoint') != none) {
		Mesh.AttachComponentToSocket(EyeParticleL, 'LEyePoint');
	}
	if(Mesh.GetSocketByName('REyePoint') != none) {
		Mesh.AttachComponentToSocket(EyeParticleR, 'REyePoint');
	}
}

function PlayerAbilityMove(float DeltaTime, PlayerInput PInput) {
	PInput.aStrafe = 0;
	PInput.aForward = 1.f;
	//PlayerController(Controller).bPressedJump = false;
}
/*function ProcessAbilityViewRotation( float DeltaTime, out rotator out_ViewRotation, out Rotator out_DeltaRot ) {
	out_DeltaRot.Yaw = FClamp(out_DeltaRot.Yaw, -180 * DeltaTime * DegToUnrRot, 120 * DeltaTime * DegToUnrRot);
}*/
simulated function StatusEffectStart(EStatusEffects Stat, bool bViaReplication) {
	//local PlayerController PC;

	switch(Stat) {
	case EFFECT_NOM_FRENZY:
		ModifySpeed();
		BodyMaterialInstances[0].SetScalarParameterValue('Frenzy', 1);
		EyeParticleL.ActivateSystem();
		EyeParticleR.ActivateSystem();
		FrenzyStartPart.ActivateSystem();
		break;
	default:
		super.StatusEffectStart(Stat, bViaReplication);
	}
}

simulated function StatusEffectStop(EStatusEffects Stat, bool bViaReplication) {
	switch(Stat) {
	case EFFECT_NOM_FRENZY:
		ModifySpeed();
		BodyMaterialInstances[0].SetScalarParameterValue('Frenzy', 0);
		EyeParticleL.DeactivateSystem();
		EyeParticleR.DeactivateSystem();
		break;
	default:
		super.StatusEffectStop(Stat, bViaReplication);
	}
}
DefaultProperties
{
	PowerCharge = 0;
	Form = FORM_BABY
	CamOffset = (X=25,Y=0,Z=70)
	// Movement Speed
	GroundSpeed = 800
	AirSpeed = 660
	WaterSpeed = 600
	LadderSpeed = 360
	AccelRate = 2048

	// Damage Scaling
	DamageScaling = 1

	// Firing Rate
	
	// Max Health
	Health = 100
	HealthMax = 100
	
	BaseEyeHeight=7
	bCanSwim = false
	Buoyancy = 1
	WaterMovementState=PlayerFloating
	// Climb?
	bCanClimbLadders = true
	Mass=+0100.000000

	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'G_CH_Nom.AnimTrees.AT_Nom'
		AnimSets[0]=AnimSet'G_CH_Nom.AnimSets.AS_Nom'
		SkeletalMesh=SkeletalMesh'G_CH_Nom.Mesh.SK_Nom'
		//Translation=(Z=-20)
	End Object

	Begin Object Class=ParticleSystemComponent Name=EyePartCompL
		bAutoActivate=false
		Template=ParticleSystem'Grow_John_Assets.Effects.FeedingFrenzy_Eye_Effect'
		//Scale=1.0
	End Object
	EyeParticleL=EyePartCompL
	Components.Add(EyePartCompL)
	Begin Object Class=ParticleSystemComponent Name=EyePartCompR
		bAutoActivate=false
		Template=ParticleSystem'Grow_John_Assets.Effects.FeedingFrenzy_Eye_Effect'
		//Scale=1.0
	End Object
	EyeParticleR=EyePartCompR
	Components.Add(EyePartCompR)
	Begin Object Class=ParticleSystemComponent Name=FrenzyPartComp
		bAutoActivate=false
		Template=ParticleSystem'Grow_John_Assets.Effects.FeedingFrenzy_Launch_Effect'
		//Scale=1.0
	End Object
	FrenzyStartPart=FrenzyPartComp
	Components.Add(FrenzyPartComp)

	Begin Object Name=CollisionCylinder
		CollisionRadius=+029.000000
		CollisionHeight=+014.000000
	End Object

	begin object Name=HitBoxComp
		BoxExtent=(Y=26, Z=22, X=36)
		Translation=(Z=7, X=-6)
	end object
	HitBoxInfo=(Offset=(Z=7, X=-6),Radius=(Y=26, Z=22, X=36))

	begin object Name=BiteBoxComp
		BoxExtent=(X=75, Y=25, Z=25)
		Translation=(X=75, Z=12.5)
	end object

	TeamMaterials[0]=MaterialInstanceConstant'G_CH_Nom.Materials.MI_Nom_Creepy'
	TeamMaterials[1]=MaterialInstanceConstant'G_CH_Nom.Materials.MI_Nom_Cute'
	TeamMaterials[2]=MaterialInstanceConstant'G_CH_Nom.Materials.MI_Nom_Neutral'
	CharacterName = "Nom"
	CharacterColour = (R=0,G=255,B=0,A=0)
	SoundGroupClass=class'GWSoundGroup_Baby'

}
