class GWCTFFlag extends UTCTFFlag;

/**
 * This function will set the flag properties back to what they should be when the flag is stationary.  (i.e. dropped or at a flag base
 **/
function SetFlagPropertiesToStationaryFlagState()
{
	SkelMesh.SetTranslation( vect(0.0,0.0,-25.0) );
	LightEnvironment.bDynamic = TRUE;
	SkelMesh.SetShadowParent( None );
	SetTimer( 5.0f, FALSE, 'SetFlagDynamicLightToNotBeDynamic' );
}
function SetHolder(Controller C)
{
	local Weapon Inv;

	if(C.Pawn.IsInState('PlayerAbility'))
		return;

	super.SetHolder(C);
	if(Role == ROLE_Authority) {
		if(C.Pawn.IsInState('PlayerAbility'))
			return;

		Inv = Weapon(C.Pawn.CreateInventory(class'GWEggCarrier', false));
		if(Inv != none) {
			C.Pawn.SetActiveWeapon(Inv);
		}
	}
}
auto state Home
{
	ignores SendHome, Score, Drop;

	function BeginState(Name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);

		SetCollisionSize(CylinderComponent(CollisionComponent).CollisionRadius * 3, CylinderComponent(CollisionComponent).CollisionHeight);
	}

	function EndState(Name NextStateName)
	{
		SetCollisionSize(CylinderComponent(CollisionComponent).default.CollisionRadius, CylinderComponent(CollisionComponent).CollisionHeight);
		Super.EndState(NextStateName);
	}
	function SameTeamTouch(Controller C)
	{

		local UTCTFFlag flag;
		local UTBot Bot;

		if ( UTPlayerReplicationInfo(C.PlayerReplicationInfo).bHasFlag )
		{
			// Score!
			flag = UTCTFFlag(UTPlayerReplicationInfo(C.PlayerReplicationInfo).GetFlag());
			UTCTFGame(WorldInfo.Game).ScoreFlag(C, flag);
			SuccessfulCaptureSystem.SetActive(true);
			flag.Score();

			Bot = UTBot(C);
			if (C.Pawn != None && Bot != None && UTSquadAI(Bot.Squad).GetOrders() == 'Attack')
			{
				Bot.Pawn.SetAnchor(HomeBase);
				UTSquadAI(Bot.Squad).SetAlternatePathTo(UTCTFSquadAI(Bot.Squad).EnemyFlag.HomeBase, Bot);
			}
			if(GWEggCarrier(C.Pawn.Weapon) != none) {
				C.Pawn.Weapon.WeaponEmpty();
				`Log("Egg Captured. Removing Weapon");
			}
		}
	}
	singular event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal ) {
		local UTCTFFlag flag;

		flag = UTCTFFlag(Other);
		if(flag != none && flag.Team != Team) {
			UTCTFGame(WorldInfo.Game).ScoreFlag(flag.OldHolder.Controller, flag);
			SuccessfulCaptureSystem.SetActive(true);
			flag.Score();
			return;
		}
		if (!ValidHolder(Other))
		return;

		SetHolder(Pawn(Other).Controller);
	}
}
event Landed(vector HitNormal, actor FloorActor)
{
	local UTBot B;
	local rotator NewRot;

	NewRot = Rot(16384,0,0);
	NewRot.Yaw = Rotation.Yaw;
	SetRotation(NewRot);
	SetTimer(0.1f, false, 'ResetHolder');

	//`log(self$" landed",, 'GameObject');

	// tell nearby bots about this
	foreach WorldInfo.AllControllers(class'UTBot', B)
	{
		if ( B.Pawn != None && B.RouteGoal != self && B.MoveTarget != self
			&& VSize(B.Pawn.Location - Location) < 1600.f && B.LineOfSightTo(self) )
		{
			UTSquadAI(B.Squad).Retask(B);
		}
	}
}
function ResetHolder() {
	OldHolder = none;
}
function CheckTouching()
{
	local int i;
	local Controller BestToucher;
	local Pawn PastHolder;

	PastHolder = OldHolder;
	//OldHolder = None;
	for ( i=0; i<Touching.Length; i++ )
	{
		if ( ValidHolder(Touching[i]) )
		{
			if ( PlayerController(Pawn(Touching[i]).Controller) != None )
			{
				if ( PastHolder != Touching[i] && !Touching[i].IsInState('PlayerAbility'))
				{
			SetHolder(Pawn(Touching[i]).Controller);
				}
			return;
		}
			else if ( BestToucher == None )
			{
				// players get priority over bots
				BestToucher = Pawn(Touching[i]).Controller;
			}
		}
	}

	if ( BestToucher != None )
	{
		SetHolder(BestToucher);
	}
}
DefaultProperties
{
	Begin Object Name=TheFlagSkelMesh
		SkeletalMesh=SkeletalMesh'G_CTF_Egg.Mesh.SK_Egg'
		PhysicsAsset=PhysicsAsset'G_CTF_Egg.Mesh.PA_Egg'
		Materials(0)=MaterialInstanceConstant'G_CTF_Egg.Materials.MI_Egg_Neutral'
		Translation=(X=0.0,Y=0.0,Z=-25.0)
	End Object

	PickupSound=SoundCue'Grow_Objective_Sounds.SoundCue.Enemy_Pickup_SoundCue'
	ReturnedSound=SoundCue'Grow_Objective_Sounds.SoundCue.FriendlyCaptured_SoundCue'
	DroppedSound=SoundCue'Grow_Sounds.bouncegrowth2_Cue'
	MessageClass=class'GWCTFMessage'
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0030.000000
		CollisionHeight=+0050.000000
	End Object
	GameObjBone3P=FlagPoint
	GameObjOffset3P=(X=0,Y=0,Z=0)
	GameObjRot3P=(Roll=0,Yaw=0)
	GameObjRot1P=(Yaw=0,Roll=0)
	GameObjOffset1P=(X=0,Y=0,Z=0)
	Components.Remove(FlagLightComponent)

	LastSecondMessageClass=class'GWLastSecondMessage'
}
