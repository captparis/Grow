class GWPawn_SpeedPower extends GWPawn;

var StaticMeshComponent SpeedShellMesh;

state PlayerAbility {
	/* Hit Cases
	 * 
	 * Allied Pawn - Stop Ability - Launch Ally
	 * Enemy Pawn - Stop Ability - Launch Enemy - Deal Damage
	 * Food Actor - Launch Food
	 * Collider (Above Walking Angle) - Do Nothing
	 * Collider (Below Walking Angle) - Stop Ability - Take Damage
	 */
	ignores StartAttackAnimation, StartAbilityStartAnimation;
	event Bump(Actor Other, PrimitiveComponent OtherComp, vector HitNormal) {
		//Called by actors and pawns *NOTE* Collision Actors also call HitWall
		//HitNormal is the Normal of the Surface hit
		
		local UTCarriedObject Flag;
		local GWPawn P;
		local GWFoodActor FA;
		
		if ( WorldInfo.NetMode != NM_DedicatedServer )
		{
			//PlaySound(ImpactSound, true);
		}

		if(GWPawn(Other) != none) {
			P = GWPawn(Other);

			if(IsSameTeamOrSelf(P)) {
				P.TakeDamage(0, Controller, Location, Normal(Velocity) * 10000, class'GWDmgType_Bite');
			} else {
				P.TakeDamage(70, Controller, Location, Normal(Velocity) * 100000, class'GWDmgType_Bite');
				
				if(UTPlayerReplicationInfo(P.PlayerReplicationInfo).bHasFlag) {
					Flag = UTPlayerReplicationInfo(P.PlayerReplicationInfo).GetFlag();
					Flag.Drop(Controller);
					Flag.Velocity.Z = 0;
					Flag.Velocity = Velocity * -HitNormal * 5;
					Flag.Velocity.Z += 500;
				}
			}
			GWWeap(Weapon).AbilityEnd();
		} else if(GWFoodActor(Other) != none) {
			FA = GWFoodActor(Other);

			FA.Velocity = Velocity * -HitNormal * 5;
			FA.Velocity.Z += 500;
		} else if(HitNormal.Z < WalkableFloorZ) {
			TakeDamage(5, Controller, Location, vect(0, 0, 0), class'DmgType_Crushed');
			GWWeap(Weapon).AbilityEnd();
		}
	}
	event HitWall( vector HitNormal, actor Wall, PrimitiveComponent WallComp ) {
		// Called by geometry collision and non-pawn actor collision
		local UTCarriedObject Flag;
		local GWPawn P;
		local GWFoodActor FA;
		
		`Log("HitWall");
		if ( WorldInfo.NetMode != NM_DedicatedServer )
		{
			//PlaySound(ImpactSound, true);
		}

		if(GWPawn(Wall) != none) {
			P = GWPawn(Wall);

			if(IsSameTeamOrSelf(P)) {
				P.TakeDamage(0, Controller, Location, Normal(Velocity) * 10000, class'GWDmgType_Bite');
			} else {
				P.TakeDamage(50, Controller, Location, Normal(Velocity) * 100000, class'GWDmgType_Bite');
				
				if(UTPlayerReplicationInfo(P.PlayerReplicationInfo).bHasFlag) {
					Flag = UTPlayerReplicationInfo(P.PlayerReplicationInfo).GetFlag();
					Flag.Drop(Controller);
					Flag.Velocity.Z = 0;
					Flag.Velocity = Velocity * -HitNormal * 5;
					Flag.Velocity.Z += 500;
				}
			}
			GWWeap(Weapon).AbilityEnd();
		} else if(GWFoodActor(Wall) != none) {
			FA = GWFoodActor(Wall);

			FA.Velocity = Velocity * -HitNormal * 5;
			FA.Velocity.Z += 500;
		} else if(HitNormal.Z < WalkableFloorZ) {
			TakeDamage(30, Controller, Location, vect(0, 0, 0), class'DmgType_Crushed');
			GWWeap(Weapon).AbilityEnd();
		}
	}
}
simulated function StatusEffectStart(EStatusEffects Stat, bool bViaReplication) {
	switch(Stat) {
	case EFFECT_POKEY_CHARGE:
		ModifySpeed();
		SpeedShellMesh.SetHidden(false);
		break;
	default:
		super.StatusEffectStart(Stat, bViaReplication);
	}
}
simulated function StatusEffectStop(EStatusEffects Stat, bool bViaReplication) {
	switch(Stat) {
	case EFFECT_POKEY_CHARGE:
		ModifySpeed();
		SpeedShellMesh.SetHidden(true);
		break;
	default:
		super.StatusEffectStop(Stat, bViaReplication);
	}
}
function PlayerAbilityMove(float DeltaTime, PlayerInput PInput) {
	PInput.aStrafe = 0;
	PInput.aForward = 1.f;
	PlayerController(Controller).bPressedJump = false;
}
function ProcessAbilityViewRotation( float DeltaTime, out rotator out_ViewRotation, out Rotator out_DeltaRot ) {
	out_DeltaRot.Yaw = FClamp(out_DeltaRot.Yaw, -120 * DeltaTime * DegToUnrRot, 120 * DeltaTime * DegToUnrRot);
}
DefaultProperties
{
	Form = FORM_SPEED_POWER

	CamOffset = (X=55,Y=0,Z=70)

	// Movement Speed
	GroundSpeed = 800
	AirSpeed = 700
	WaterSpeed = 500
	LadderSpeed = 300
	AccelRate = 550
	Mass=+0400.000000

	// Damage Scaling
	DamageScaling = 1

	// Firing Rate
	
	// Max Health
	Health = 175
	HealthMax = 175
	
	// Swim?
	bCanSwim = false
	//Buoyancy = 1.5
	UnderWaterTime = 10f
	WaterMovementState=PlayerFloating
	// Climb?
	bCanClimbLadders = false
	Begin Object Name=CollisionCylinder
		CollisionRadius=+059.000000
		CollisionHeight=+035.000000
	End Object

	begin object Name=HitBoxComp
		BoxExtent=(Y=49, Z=58, X=104)
		Translation=(Z=17.5, X=-14)
	end object
	HitBoxInfo=(Offset=(Z=17.5, X=-14),Radius=(Y=49, Z=58, X=104))

	begin object Name=BiteBoxComp
		BoxExtent=(X=200, Y=100, Z=100)
		Translation=(X=200, Z=50)
	end object

	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'G_CH_Pokey.AnimTrees.AT_Pokey'
		AnimSets[0]=AnimSet'G_CH_Pokey.AnimSets.AS_Pokey'
		SkeletalMesh=SkeletalMesh'G_CH_Pokey.Mesh.SK_Pokey'
	End Object

	begin object class=StaticMeshComponent Name=SpeedStaticMeshComponent
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		HiddenGame=true
		Translation=(X=40,Y=0,Z=-40)
		StaticMesh=StaticMesh'Grow_Effects.Static_Meshes.sonic_boom'
		Scale3D=(X=20,Y=20,Z=20)
		Rotation=(Yaw=16384,Pitch=0,Roll=0)
	end object
	SpeedShellMesh=SpeedStaticMeshComponent
	Components.Add(SpeedStaticMeshComponent)
	bCollideWorld=true
	bDirectHitWall=true

	TeamMaterials[0]=MaterialInstanceConstant'G_CH_Pokey.Materials.MI_Pokey_Creepy'
	TeamMaterials[1]=MaterialInstanceConstant'G_CH_Pokey.Materials.MI_Pokey_Cute'
	TeamMaterials[2]=MaterialInstanceConstant'G_CH_Pokey.Materials.MI_Pokey_Neutral'
	CharacterName = "Pokey"
	CharacterColour = (R=255,G=122,B=0,A=0)

	MuzzleFlashPSCTemplate[0]=ParticleSystem'Grow_Effects.Effects.Headbutt'
	SoundGroupClass=class'GWSoundGroup_SpeedPower'
}
