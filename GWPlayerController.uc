class GWPlayerController extends UTPlayerController
	dependson(GWConstants)
	config(Grow)
	;

/* enum from GWPawn:
 * EForm {
 *  FORM_NONE,
 *	FORM_BABY,
 *	FORM_POWER, FORM_SKILL, FORM_SPEED,
 *	FORM_POWER_MAX, FORM_SKILL_MAX, FORM_SPEED_MAX,
 *	FORM_SKILL_POWER, FORM_SPEED_POWER, FORM_SPEED_SKILL
 */

/** If the 'join game' submenu is open, a reference to it is stored here, to pass on requests to cleanup online delegates if required */
//var GFxGrowFrontEnd_JoinGame JoinGameMenu;

struct FormStruct {
	var class<GWFamilyInfo> Family;
	var class<GWPawn> Pawn;
	var class<GWWeap> Weapon;
	structdefaultproperties {
		Family = class'GWFamilyInfo'
		Weapon = class'GWWeap'
	}
};
var FormStruct CharInfo[EForm];
var Vector CrosshairHitWorldLocation;
//var EForm newForm;
var EForm lastForm;
var EForm NewGrowthForm;
var repnotify bool bDevolve;
var repnotify bool bStun;
var bool bFlinch;
var float StunTime;
var float StartStunTime;
var float GrowCharge;

var int ReqStage1;
var int ReqStage2;

var Name lastState;
var Vector slideAmount;
var Vector AccelAmount;
var float HatchCount;

var config bool UseAnimatedProfile;

replication {
	if(RemoteRole == ROLE_Authority)
		CrosshairHitWorldLocation;
	if(bNetDirty)
		bDevolve;
	if(bNetDirty && Role == ROLE_Authority)
		bStun;
}

exec function StartEat( optional Byte FireModeNum )
{
	StartFire( 2 );
}

exec function StopEat( optional byte FireModeNum )
{
	StopFire( 2 );
}
exec function StartSpew( optional Byte FireModeNum )
{
	StartFire( 5 );
}

exec function StopSpew( optional byte FireModeNum )
{
	StopFire( 5 );
}
exec function Achieve() {
	local int i;
	local int MutatorBit;
	if (AchievementHandler == none)
		InitAchievementHandler();
	for (i=0; i<31; i++) {
		MutatorBit = 1 << i;
		AchievementHandler.UpdateAchievement(EUTA_EXPLORE_EveryMutator, MutatorBit);
	}
	AchievementHandler.UpdateAchievement(EUTA_POWERUP_DeliveringTheHurt, 120);
	AchievementHandler.UpdateAchievement(EUTA_WEAPON_DontTaseMeBro, 15);
	AchievementHandler.UpdateAchievement(EUTA_WEAPON_StrongestLink, 15);
	AchievementHandler.UpdateAchievement(EUTA_WEAPON_HaveANiceDay, 15);
	AchievementHandler.UpdateAchievement(EUTA_VEHICLE_Armadillo, 15);
	AchievementHandler.UpdateAchievement(EUTA_HUMILIATION_SerialKiller, 15);
	AchievementHandler.UpdateAchievement(EUTA_HUMILIATION_OffToAGoodStart, 15);
}
/** Clears previously set online delegates. */
event ClearOnlineDelegates()
{
	local LocalPlayer LP;

	Super.ClearOnlineDelegates();

	LP = LocalPlayer(Player);
	if ( OnlineSub != None
	&&	(Role < ROLE_Authority || LP != None))
	{
		//if (JoinGameMenu != none)
		//{
			//JoinGameMenu.Cleanup();
		//}
	}
}
simulated event ReplicatedEvent(name VarName)
{
	if ( VarName == 'bDevolve') {
		ClientDevolve();
	}
	if(VarName == 'bStun') {
		ClientStun();
	}
	super.ReplicatedEvent(VarName);
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	//SetCameraMode('ThirdPerson');
	bNoTextToSpeechVoiceMessages=true;
	bTextToSpeechTeamMessagesOnly=True;
}
exec function Save() {
	SaveConfig();
}
simulated function PlayBeepSound() {}

reliable server function ServerGrow(EForm newForm, int GrowType)
{
	local GWPawn P;
	//local GWReplicatedEmitter GWRE;
	local bool allowGrow;
	
	NewGrowthForm = 0;
	P = GWPawn(Pawn);
	if (GrowType == 0)
	{
		switch (newForm)
		{
			case FORM_BABY:
			allowGrow = true;
		}
	}
	if (GrowType == 1)
	{
		if(P.Power >= ReqStage1)
		{
			switch (newForm)
			{
				case FORM_POWER:
				allowGrow = true;
			}
		}
		if(P.Power >= ReqStage2)
		{
			switch (newForm)
			{
				case FORM_POWER_MAX:
				case FORM_SKILL_POWER:
				case FORM_SPEED_POWER:
				allowGrow = true;
			}
		}
	}
	if (GrowType == 2)
	{
		if(P.Speed >= ReqStage1)
		{
			switch (newForm)
			{
				case FORM_SPEED:
				allowGrow = true;
			}
		}
		if(P.Speed >= ReqStage2)
		{
			switch (newForm)
			{
				case FORM_SPEED_MAX:
				case FORM_SKILL_SPEED:
				case FORM_SPEED_POWER:
				allowGrow = true;
			}
		}
	}
	if (GrowType == 3)
	{
		if(P.Skill >= ReqStage1)
		{
			switch (newForm)
			{
				case FORM_SKILL:
				allowGrow = true;
			}
		}
		if(P.Skill >= ReqStage2)
		{
			switch (newForm)
			{
				case FORM_SKILL_MAX:
				case FORM_SKILL_POWER:
				case FORM_SKILL_SPEED:
				allowGrow = true;
			}
		}
	}
	allowGrow = true;
	if (allowGrow && (GWGameMode(WorldInfo.Game) == none || GWGameMode(WorldInfo.Game).AllowGrow(PlayerReplicationInfo, newForm))) {
		NewGrowthForm = newForm;
		Spawn(class'GWEmit_Spark', , , Pawn.Location);
		SetTimer(0.2, false, 'ServerGrowChar');
		HurtRadius(0, 300, class'GWDmgType_Vacuum', 100000, P.Location, P, self, true);
		ClientIgnoreMoveInput(true);
	} else {
		//P.ClientGrowFailed("Not enough food for new form. Form:"@newForm@"Food Counts: Power("$P.Power$") Skill("$P.Skill$") Speed("$P.Speed$")");
		P.ClientGrowFailed("");
	}
}
function ServerGrowChar() {
	local EForm oldForm;
	local GWPawn P;

	P = GWPawn(Pawn);
	oldForm = P.Form;

	ClientIgnoreMoveInput(false);
	`Log(GetFuncName);
	if(!ChangeChar(NewGrowthForm)) {
		P.ClientGrowFailed(P.CharacterName@"says: \"Need more room\"");
	} else {
		lastForm = oldForm;
	}
}

function IgnoreMoveInput( bool bNewMoveInput )
{
	if(!bNewMoveInput) {
		bIgnoreMoveInput = 0;
	} else {
		bIgnoreMoveInput = Max( bIgnoreMoveInput + (bNewMoveInput ? +1 : -1), 0 );
	}
	//`Log("IgnoreMove: " $ bIgnoreMoveInput);
}
exec function BeginSlide() {
	//slideAmount = Vector(Pawn.Rotation) * 2048;
	//GotoState('PlayerSliding');
}
exec function StopSlide() {
	//GotoState('PlayerWalking');
}
state PlayerSliding extends PlayerWalking {
	function PlayerMove( float DeltaTime )
	{
		local eDoubleClickDir	DoubleClickMove;
		local rotator			OldRotation;
		local bool				bSaveJump;

		if( Pawn == None )
		{
			GotoState('Dead');
		}
		else
		{
			DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );

			// Update rotation.
			OldRotation = Rotation;
			UpdateRotation( DeltaTime );
			bDoubleJump = false;

			if( bPressedJump && Pawn.CannotJumpNow() )
			{
				bSaveJump = true;
				bPressedJump = false;
			}
			else
			{
				bSaveJump = false;
			}

			if( Role < ROLE_Authority ) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, vect3d(0,0,0), DoubleClickMove, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, vect3d(0,0,0), DoubleClickMove, OldRotation - Rotation);
			}
			bPressedJump = bSaveJump;
		}
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local vector floorNormal;

		local float gDotN;
		local Vector normalAcc;
		local float gravity;

		// gives a negative, downward acceleration due to gravity
		gravity = GetGravityZ();
		floorNormal = Pawn.Floor;

		// (-G dot N)*N = normal acceleration
		// (-G dot N)*N + G = net acceleration
		gDotN = -gravity*floorNormal.Z;
		normalAcc = floorNormal*gDotN;
		slideAmount = slideAmount * 0.9 + normalAcc;

		// player has limited control going forward/backwards down slope, but a bit more control going left-right across slope
		
		Pawn.Acceleration = AccelAmount;

		CheckJumpOrDuck();
	}
	exec function SetAccel(Vector Accel) {
		AccelAmount = Accel;
	}
}

exec function SwitchHud()
{
	local class<HUD> NewHUDClass;

	`log("SWITCHEROO THE HUD "$WorldInfo.GRI.GameClass);
	NewHUDClass = WorldInfo.GRI.GameClass.Default.HUDType;
	if ( UTGFxHUDWrapper(myHUD) == None )
	{
		NewHUDClass = WorldInfo.GRI.GameClass.Default.bTeamGame ? class'GWGFxTeamHudWrapper' : class'GWGFxHudWrapper';
	}
	ClientSetHud(NewHUDClass);
}

state PlayerWalking {

	function PlayerMove( float DeltaTime ) {
		
		local vector			X,Y,Z, NewAccel;
		local eDoubleClickDir	DoubleClickMove;
		local rotator			OldRotation;
		local bool				bSaveJump;

		if( Pawn == None )
		{
			GotoState('Dead');
		}
		else
		{
			/*if(Pawn.Floor != vect3d(0,0,1) && Pawn.Base != none) {
				GotoState('PlayerSliding');
			}*/
			GetAxes(Pawn.Rotation, X, Y, Z); // #TASK GetAxes(Pawn.Rotation - MakeRotator(Pawn.Rotation.Pitch, 0,0),X,Y,Z);
			// Update acceleration.
			NewAccel = PlayerInput.aForward*X + PlayerInput.aStrafe*Y;
			NewAccel.Z	= 0;
			NewAccel = Pawn.AccelRate * Normal(NewAccel);

			if (IsLocalPlayerController())
			{
				AdjustPlayerWalkingMoveAccel(NewAccel);
			}
			//NewAccel.Z	= Pawn.Velocity.Z;

			DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );

			// Update rotation.
			OldRotation = Rotation;
			UpdateRotation( DeltaTime );
			bDoubleJump = false;

			if( bPressedJump && Pawn.CannotJumpNow() )
			{
				bSaveJump = true;
				bPressedJump = false;
			}
			else
			{
				bSaveJump = false;
			}

			if( Role < ROLE_Authority ) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			bPressedJump = bSaveJump;
		}
	}
	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		if( Pawn == None )
		{
			return;
		}

		if (Role == ROLE_Authority)
		{
			// Update ViewPitch for remote clients
			Pawn.SetRemoteViewPitch( Rotation.Pitch );
		}

		//Pawn.Velocity = NewAccel;
		Pawn.Acceleration = NewAccel;

		CheckJumpOrDuck();
	}
// #TASK
/*	function UpdateRotation( float DeltaTime )
	{
		local Rotator	DeltaRot, newRotation, ViewRotation;
		local vector ViewDir, X, Y, Z;
//		local rotator NewRotation;

		ViewRotation = Rotation;
		if (Pawn!=none)
		{
			Pawn.SetDesiredRotation(ViewRotation);
		}

		// Calculate Delta to be applied on ViewRotation
		DeltaRot.Yaw	= PlayerInput.aTurn;
		DeltaRot.Pitch	= PlayerInput.aLookUp;

		ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
		SetRotation(ViewRotation);

		ViewShake( deltaTime );

		NewRotation = ViewRotation;
		NewRotation.Roll = Rotation.Roll;

		if ( Pawn != None && Pawn.Base != none) {
			//Pawn.FaceRotation(NewRotation, deltatime);
			//Pawn.SetRotation(Rotator(Pawn.Floor));
		}
		GetPlayerViewPoint(ViewDir, newRotation);
		`Log(newRotation);
		ViewDir = Normal(Pawn.Location - ViewDir);
		Y = Pawn.Floor cross ViewDir;
		X = Y cross Z;

		NewRotation = OrthoRotation( X, Y, Pawn.Floor );
		
		Pawn.SetRotation( NewRotation );
	}
*/
}
state PlayerCrazy extends PlayerWalking {

	/*function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;
		local Rotator DeltaRot, ViewRotation;

		bPressedJump = false;
		GetAxes(Rotation,X,Y,Z);
		// Update view rotation.
		ViewRotation = Rotation;
		// Calculate Delta to be applied on ViewRotation
		DeltaRot.Yaw	= PlayerInput.aTurn;
		DeltaRot.Pitch	= PlayerInput.aLookUp;
		ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
		SetRotation(ViewRotation);

		ViewShake(DeltaTime);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, vect(0,0,0), DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, vect(0,0,0), DCLICK_None, rot(0,0,0));
		bPressedJump = false;
	}*/
	function PlayerMove( float DeltaTime ) {
		
		local vector			X,Y,Z, NewAccel;
		local eDoubleClickDir	DoubleClickMove;
		local rotator			DeltaRot, ViewRotation;
		local bool				bSaveJump;

		if( Pawn == None )
		{
			GotoState('Dead');
		}
		else
		{
			GetAxes(Pawn.Rotation,X,Y,Z);

			// Update acceleration.
			NewAccel = PlayerInput.aForward*X + PlayerInput.aStrafe*Y;
			NewAccel.Z	= 0;
			NewAccel = Pawn.AccelRate * Normal(NewAccel);

			if (IsLocalPlayerController())
			{
				AdjustPlayerWalkingMoveAccel(NewAccel);
			}

			DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );

			// Update rotation.
			//OldRotation = Rotation;
			//UpdateRotation( DeltaTime );
			bDoubleJump = false;
			
			//GetAxes(Rotation,X,Y,Z);
			// Update view rotation.
			ViewRotation = Rotation;
			// Calculate Delta to be applied on ViewRotation
			DeltaRot.Yaw	= PlayerInput.aTurn;
			DeltaRot.Pitch	= PlayerInput.aLookUp;
			ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
			//ViewRotation.Roll = RandRange(-15 * DegToUnrRot,15 * DegToUnrRot);
			SetRotation(ViewRotation);
			//ViewRotation.Yaw = RandRange(-180 * DegToUnrRot,180 * DegToUnrRot);
			ViewRotation.Roll = 180 * DegToUnrRot;
			//ViewRotation.Pitch = RandRange(-180 * DegToUnrRot,180 * DegToUnrRot);
			Pawn.SetRotation(ViewRotation);

			ViewShake(DeltaTime);

			if( bPressedJump && Pawn.CannotJumpNow() )
			{
				bSaveJump = true;
				bPressedJump = false;
			}
			else
			{
				bSaveJump = false;
			}

			if( Role < ROLE_Authority ) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, rot(0,0,0));
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DoubleClickMove, rot(0,0,0));
			}
			bPressedJump = bSaveJump;
		}
	}
}

reliable server function ServerForceChar(int newChar)
{
		ChangeChar(EForm(newChar));
}
exec function ForceCharacter(int newChar) {
	ServerForceChar(newChar);
}
exec function SpectateMode(bool mode) {
	ServerSpectateMode(mode);
}
exec function GetVolume() {
	local SoundClass SC;
	SC = SoundClass'SoundClassesAndModes.Character';
	`Log(GetFuncName()@SC.Properties.Volume);
}
exec function SetVolumeAG(float newVol) {
	SetAudioGroupVolume('Character', newVol);
	GetVolume();
}
exec function SetVolume(float newVol) {
	local SoundClass SC;
	SC = SoundClass'SoundClassesAndModes.Character';
	SC.Properties.Volume = newVol;
	GetVolume();
}
reliable server function ServerSpectateMode(bool mode) {
	if(mode) {
		GotoState('PlayerSpec');
		PlayerReplicationInfo.bOnlySpectator = true;
		PlayerReplicationInfo.bIsSpectator = true;
		PlayerReplicationInfo.bOutOfLives = true;
		ClientGotoState('PlayerSpec');
	} else {
		GotoNormalState();
		PlayerReplicationInfo.bOnlySpectator = false;
		PlayerReplicationInfo.bIsSpectator = false;
		PlayerReplicationInfo.bOutOfLives = false;
		ClientGotoNormalState();
		Suicide();
	}
}
exec function CheatGhost() {
	if ( (Pawn != None) && Pawn.CheatGhost() )
	{
		bCheatFlying = true;
		GotoState('PlayerFlying');
		ServerCheatGhost();
		Pawn.SetHidden(true);
	}
}
reliable server function ServerCheatGhost()
{
	if ( (Pawn != None) && Pawn.CheatGhost() )
	{
		bCheatFlying = true;
		GotoState('PlayerFlying');
		Pawn.SetHidden(true);
	}
}
exec function Devolve() {
		ServerDevolve();
}
reliable server function ServerDevolve()
{
		bDevolve = true;
		ClientDevolve();
}

function ClientDevolve() {
	local GWPawn P;
	local EForm newForm;
	`Log(name$"::"$GetFuncName(),,'DevEvolve');
	P = GWPawn(Pawn);

	if(P.Form == FORM_BABY) {
		return;
	}
	if(lastForm == FORM_NONE) {
		`Log("Lastform = none",,'DevEvolve');
		newForm = FORM_BABY;
		lastForm = FORM_BABY;
	} else {
		newForm = lastForm;
		lastForm = FORM_BABY;
	}

	if(P.Form != newForm) {
		ChangeChar(newForm);
	}
}

function ServerStun(float TimeToStun) {
	`Log(name@"ServerStun"@TimeToStun);
	if(IsInState('PlayerStun')) {
		if(TimeToStun > 0) {
			SetTimer(TimeToStun, false, 'EndStun');
		} else {
			ClearTimer('EndStun');
			EndStun();
		}
	} else {
		if(TimeToStun > 0) {
			if(Role == ROLE_Authority)
				GWPawn(Pawn).TriggerAnim(ANIM_STUN);
			SetTimer(TimeToStun, false, 'EndStun');
			bStun = true;
			bNetDirty = true;
			GWPawn(Pawn).IncrementStatusEffect(EFFECT_STUN, self);
			StartStun();
		}
	}
}

simulated function ClientStun() {
	`Log(name@"ClientStun"@bStun);
	if(bStun) {
		StartStun();
	} else {
		EndStun();
	}
}
function ServerFlinch() {
	if(Role == ROLE_Authority) {
		GWPawn(Pawn).TriggerAnim(ANIM_FLINCH);
		SetTimer(0.2, false, 'ServerStopFlinch');
		GWPawn(Pawn).IncrementStatusEffect(EFFECT_FLINCH, self);
		ServerStartFlinch();
	}
}

reliable client function ClientStartFlinch() {
	`Log(Pawn @ "started flinching");
	IgnoreMoveInput(true);
}
reliable client function ClientStopFlinch() {
	`Log(Pawn @ "stopped flinching");
	bIgnoreMoveInput = 0;
}
function ServerStartFlinch() {
	ClientStartFlinch();
	IgnoreMoveInput(true);
}
function ServerStopFlinch() {
	bIgnoreMoveInput = 0;
	ClientStopFlinch();
	GWPawn(Pawn).ClearStatusEffect(EFFECT_FLINCH);
}
exec function DebugFlinch() {
	`Log(Pawn @ "is" $ (IsMoveInputIgnored() ? "" : " not") @ "flinching"@bIgnoreMoveInput);
}
simulated function StartStun() {
	IgnoreMoveInput(true);
	//IgnoreLookInput(true);
}
simulated function EndStun() {
	StunTime = 0;
	bStun = false;
	bNetDirty = true;
	//IgnoreLookInput(false);
	bIgnoreMoveInput = 0;
	if(Role == ROLE_Authority)
		GWPawn(Pawn).TriggerAnim(ANIM_NONE);
	GWPawn(Pawn).ClearStatusEffect(EFFECT_STUN);
}

/**
 * Changes this Controller's Pawn to a new character.
 * Also the flag is dropped and picked up again to avoid the flag reset
 */
function bool ChangeChar(EForm Form)
{
	local GWPawn P, newP;
	local Vector L;
	//local ParticleSystem ExplosionTemplate;
	local UTPlayerReplicationInfo PRI;
	local UTCarriedObject Flag;
	local GWEmit_Cloud GWRE;

	if(Role != ROLE_Authority) {
		`Log(GetFuncName()@"Not Authority",,'DevEvolve');
		return false;
	}

	P = GWPawn(Pawn);
	L = Pawn.Location;
	`Log("Changed"@P.Form@"to"@Form,,'DevEvolve');
	PRI = UTPlayerReplicationInfo(P.PlayerReplicationInfo);

	if(PRI.bHasFlag) {
		Flag = PRI.GetFlag();
		Flag.Drop();
	}
	P.SetCollision(false, false, false);

	//Spawn new character
	newP = Spawn(CharInfo[Form].Pawn, , ,L);
	if(newP == none) {
		P.SetCollision(true, true, false);
		`Log(GetFuncName()@"Can't Spawn Creature",,'DevEvolve');
		return false;
	}

	UnPossess();
	Possess(newP, true);
	newP.AddDefaultInventory();

	if(Flag != none) {
		Flag.SetHolder(self);
	}

	// Spawn Smoke & Mirrors
	//ExplosionTemplate=ParticleSystem'GrowEffects.Effects.Grow_Effect';
	class<GWSoundGroup>(P.SoundGroupClass).static.PlayEvolveSound(P);
	//WorldInfo.MyEmitterPool.SpawnEmitter(ExplosionTemplate,L);
	GWRE = Spawn(class'GWEmit_Cloud',,,L,MakeRotator(0,Rotation.Yaw, 0));
	switch(Form) {
	case FORM_BABY:
		GWRE.SetColor(1);
		break;
	case FORM_POWER:
		GWRE.SetColor(1);
		break;
	case FORM_SKILL:
		GWRE.SetColor(2);
		break;
	case FORM_SPEED:
		GWRE.SetColor(3);
		break;
	case FORM_POWER_MAX:
		GWRE.SetDrawScale3D(vect(3,3,3));
		GWRE.SetColor(1);
		break;
	case FORM_SKILL_MAX:
		GWRE.SetColor(2);
		break;
	case FORM_SKILL_POWER:
		if(P.Form == FORM_POWER)
			GWRE.SetColor(2);
		if(P.Form == FORM_SKILL)
			GWRE.SetColor(1);
		break;
	case FORM_SKILL_SPEED:
		if(P.Form == FORM_SPEED)
			GWRE.SetColor(2);
		if(P.Form == FORM_SKILL)
			GWRE.SetColor(3);
		break;
	case FORM_SPEED_MAX:
		GWRE.SetColor(3);
		break;
	case FORM_SPEED_POWER:
		if(P.Form == FORM_POWER)
			GWRE.SetColor(3);
		if(P.Form == FORM_SPEED)
			GWRE.SetColor(1);
		break;
	}
	P.Destroy();
	`Log(GetFuncName()@"Spawn Success");
	return true;
}

/*state PlayerSwimming
{
	function PlayerMove(float DeltaTime)
	{
		local rotator oldRotation;
		local vector X,Y,Z, NewAccel;
		local GWPawn P;

		if (Pawn == None){
			GotoState('Dead');
		} else {
			P = GWPawn(Pawn);
			GetAxes(Rotation,X,Y,Z);

			NewAccel = PlayerInput.aForward*X + PlayerInput.aStrafe*Y + PlayerInput.aUp*vect(0,0,1);
			if(!P.bCanSwim) {
				if(P.Form == FORM_SPEED || P.Form == FORM_SPEED_MAX || P.Form == FORM_BABY || P.Form == FORM_SKILL_SPEED) {
					if(NewAccel.Z < 300.0f) {
						NewAccel.Z = 300.0f;
					}
				} else {
					NewAccel.Z = -500.0f;
				}
			}
			NewAccel = Pawn.AccelRate * Normal(NewAccel);

			// Update rotation.
			oldRotation = Rotation;
			UpdateRotation( DeltaTime );

			if ( Role < ROLE_Authority ) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, NewAccel, DCLICK_None, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DCLICK_None, OldRotation - Rotation);
			}
			bPressedJump = false;
		}
	}
}*/
reliable server function WaterJump() {
	Pawn.SetPhysics(PHYS_Falling);
	Pawn.velocity.Z = Pawn.OutOfWaterZ; //set here so physics uses this for remainder of tick
	GotoState(Pawn.LandMovementState);
}
state PlayerFloating extends PlayerSwimming {
	function PlayerMove(float DeltaTime)
	{
		local Vector      vSurfaceLoc;
		local rotator oldRotation;
		local Vector vNewAccel;
		//local vector HitNormal;
		local GWPawn P;

		P = GWPawn(Pawn);
		if (P == none)
		{
			GotoState('Dead');
		}
		else
		{
			if (bPressedJump/* && Pawn.CheckWaterJump(HitNormal)*/) {
				Pawn.SetPhysics(PHYS_Falling);
				Pawn.velocity.Z = Pawn.OutOfWaterZ; //set here so physics uses this for remainder of tick
				GotoState(Pawn.LandMovementState);
				WaterJump();
			}
			//Cannot jump while swimming
			bPressedJump = false;

			//make pawn float on surface
			vSurfaceLoc = Pawn.Location;
			vSurfaceLoc.Z = Lerp(Pawn.Location.Z,P.fWaterSurfaceZ,FMin(5*DeltaTime,1));
			Pawn.SetLocation(vSurfaceLoc);

			vNewAccel = GetDirectionalizedInputMovement(DeltaTime);
			vNewAccel.Z = 0;
			//Pawn.Acceleration = 
			vNewAccel *= Pawn.AccelRate;
			//`Log("");
			//`Log("VSurfaceLoc:"@vSurfaceLoc@"NewAccel"@Pawn.Acceleration);

			oldRotation = Rotation;
			UpdateRotation( DeltaTime );
			if ( Role < ROLE_Authority ) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, vNewAccel, DCLICK_None, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, vNewAccel, DCLICK_None, OldRotation - Rotation);
			}
		}
	}
	
	event Timer()
	{
		`Log("Swimming Timer");
		super.Timer();
	}

	event NotifyPhysicsVolumeChange( PhysicsVolume NewVolume )
	{
		local actor HitActor;
		local vector HitLocation, HitNormal, Checkpoint;
		local vector X,Y,Z;

		`Log(GetFuncName()@GetStateName()@NewVolume);
		if ( !Pawn.bCollideActors )
		{
			GotoState(Pawn.LandMovementState);
		}
		if (Pawn.Physics != PHYS_RigidBody)
		{
			if ( !NewVolume.bWaterVolume )
			{
				Pawn.SetPhysics(PHYS_Falling);
				
				GetAxes(Rotation,X,Y,Z);
			    if ( (Pawn.Velocity.Z > 160) || !Pawn.TouchingWaterVolume() )
				    GotoState(Pawn.LandMovementState);
			    else //check if in deep water
			    {
				    Checkpoint = Pawn.Location;
				    Checkpoint.Z -= (Pawn.CylinderComponent.CollisionHeight + 6.0);
				    HitActor = Trace(HitLocation, HitNormal, Checkpoint, Pawn.Location, false);
				    if (HitActor != None)
					    GotoState(Pawn.LandMovementState);
				    else
				    {
					    SetTimer(0.2, false);
				    }
			    }
			}
			else
			{
				ClearTimer();
				Pawn.SetPhysics(PHYS_Swimming);
			}
		}
		else if (!NewVolume.bWaterVolume)
		{
			// if in rigid body, go to appropriate state, but don't modify pawn physics
			GotoState(Pawn.LandMovementState);
		}
	}
}
simulated event PlayerTick(float DeltaTime) {
	if(lastState != GetStateName()) {
		lastState = GetStateName();
		`Log("Entering "$GetStateName());
	}
	if(Pawn != none && Pawn.Weapon == none) {
		NextWeapon();
	}
	//`Log(Pawn.Acceleration@slideAmount);
	super.PlayerTick(DeltaTime);
}

reliable server function setCrosshairAim( vector newAim) {
	CrosshairHitWorldLocation = newAim;
}
/**
 * Adjusts weapon aiming direction.
 * Gives controller a chance to modify the aiming of the pawn. For example aim error, auto aiming, adhesion, AI help...
 * Requested by weapon prior to firing.
 * UTPlayerController implementation doesn't adjust aim, but sets the shottarget (for warning enemies)
 *
 * @param	W, weapon about to fire
 * @param	StartFireLoc, world location of weapon fire start trace, or projectile spawn loc.
 * @param	BaseAimRot, original aiming rotation without any modifications.
 */
function Rotator GetAdjustedAimFor( Weapon W, vector StartFireLoc )
{
	local rotator	BaseAimRot;

	BaseAimRot = (Pawn != None) ? Pawn.GetBaseAimRotation() : Rotation;
	
	BaseAimRot.Pitch += 15 * DegToUnrRot;

   	return BaseAimRot;
}
/*state PlayerStun extends PlayerWalking {
	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;
		local Rotator DeltaRot, ViewRotation;

		bPressedJump = false;
		GetAxes(Rotation,X,Y,Z);
		// Update view rotation.
		ViewRotation = Rotation;
		// Calculate Delta to be applied on ViewRotation
		DeltaRot.Yaw	= PlayerInput.aTurn;
		DeltaRot.Pitch	= PlayerInput.aLookUp;
		ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
		SetRotation(ViewRotation);

		ViewShake(DeltaTime);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, vect(0,0,0), DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, vect(0,0,0), DCLICK_None, rot(0,0,0));
		bPressedJump = false;
	}
	exec function StartFire( optional byte FireModeNum )
	{
		return;
	}
	function EndStun() {
		`Log(name@"EndStunTimer");
		StunTime = 0;
		bStun = false;
		bNetDirty = true;
		if(Pawn.TouchingWaterVolume()) {
			GotoState(Pawn.WaterMovementState);
		} else {
			GotoState(Pawn.LandMovementState);
		}
		GWPawn(Pawn).ClearStatusEffect(EFFECT_STUN);
	}
	simulated event BeginState(Name PreviousStateName) {
		`Log(name@"StartStun");
		StopFire();
		
	}
	simulated event EndState(Name NextStateName) {
		`Log(name@"EndStun");
	}
}
state PlayerFlinch extends PlayerWalking {
	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;
		local Rotator DeltaRot, ViewRotation;

		bPressedJump = false;
		GetAxes(Rotation,X,Y,Z);
		// Update view rotation.
		ViewRotation = Rotation;
		// Calculate Delta to be applied on ViewRotation
		DeltaRot.Yaw	= PlayerInput.aTurn;
		DeltaRot.Pitch	= PlayerInput.aLookUp;
		ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
		SetRotation(ViewRotation);

		ViewShake(DeltaTime);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, vect(0,0,0), DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, vect(0,0,0), DCLICK_None, rot(0,0,0));
		bPressedJump = false;
	}
	exec function StartFire( optional byte FireModeNum )
	{
		return;
	}
	function EndFlinch() {
		bFlinch = false;
		bNetDirty = true;
		if(Pawn.TouchingWaterVolume()) {
			GotoState(Pawn.WaterMovementState);
		} else {
			GotoState(Pawn.LandMovementState);
		}
		GWPawn(Pawn).ClearStatusEffect(EFFECT_FLINCH);
	}
	simulated event BeginState(Name PreviousStateName) {
		`Log(name@"StartFlinch");
	}
	simulated event EndState(Name NextStateName) {
		`Log(name@"EndFlinch");
	}
}*/
state PlayerSpec extends Spectating {
	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;
		local Rotator DeltaRot, ViewRotation;

		GetAxes(Rotation,X,Y,Z);
		Acceleration = PlayerInput.aForward*X + PlayerInput.aStrafe*Y + PlayerInput.aUp*vect(0,0,1);
		
		// Update view rotation.
		ViewRotation = Rotation;
		// Calculate Delta to be applied on ViewRotation
		DeltaRot.Yaw	= PlayerInput.aTurn;
		DeltaRot.Pitch	= PlayerInput.aLookUp;
		ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
		SetRotation(ViewRotation);

		ViewShake(DeltaTime);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));
		bPressedJump = false;
	}
}
function DrawHUD( HUD H )
{
	if ( Pawn != None )
	{
		Pawn.DrawHUD( H );
	}

	if ( PlayerInput != None )
	{
		PlayerInput.DrawHUD( H );
	}
}

state PlayerAbility extends PlayerWalking
{
	function PlayerMove(float DeltaTime) {
		GWPawn(Pawn).PlayerAbilityMove(DeltaTime, PlayerInput);

		super.PlayerMove(DeltaTime);
		//ShakeOffset = vect3d(RandRange(-30,30),RandRange(-30,30),RandRange(-30,30));
		//ShakeRot = RotRand(true);
	}
	event EndState(Name NextStateName) {
		if(NextStateName != 'PlayerWalking') {
			GWWeap(Pawn.Weapon).AbilityEnd();
		}
	}
	function ProcessViewRotation( float DeltaTime, out Rotator out_ViewRotation, Rotator DeltaRot )
	{
		GWPawn(Pawn).ProcessAbilityViewRotation(DeltaTime, out_ViewRotation, DeltaRot);
		
		if( PlayerCamera != None )
		{
			PlayerCamera.ProcessViewRotation( DeltaTime, out_ViewRotation, DeltaRot );
		}

		if ( Pawn != None )
		{	// Give the Pawn a chance to modify DeltaRot (limit view for ex.)
			Pawn.ProcessViewRotation( DeltaTime, out_ViewRotation, DeltaRot );
		}
		else
		{
			// If Pawn doesn't exist, limit view

			// Add Delta Rotation
			out_ViewRotation	+= DeltaRot;
			out_ViewRotation	 = LimitViewRotation(out_ViewRotation, -16384, 16383 );
		}
	}
}
exec function ShowAttacks(bool newValue) {
	GWCTFGame(WorldInfo.Game).ShowColliders = newValue;
}
exec function RotatorToVector(int Pitch, int Yaw, int Roll) {
	ClientMessage(Vector(MakeRotator(Pitch, Yaw, Roll)));
}
exec function VectorToRotator(int X, int Y, int Z) {
	ClientMessage(Rotator(vect3d(X, Y, Z)));
}
server reliable function ServerTriggerHatch() {
	local GWSpawnEgg SE;

	SE = GWSpawnEgg(ViewTarget);
	if(SE != none) {
		SE.SetCollision(false, false, true);
		SE.Destroy();
	}
	GWGameMode(WorldInfo.Game).DelayedPlayerStart(self);
	if(SE != none) {
		SE.Destroy();
	}
	
}
state WaitingToHatch extends PlayerWaiting
{
	
	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local vector OldLocation;

		OldLocation = Location;
		super.ProcessMove(DeltaTime, NewAccel, DoubleClickMove, DeltaRot);

		if ( bCameraOutOfWorld )
		{
			bCameraOutOfWorld = false;
			SetLocation(OldLocation);
		}
	}
	exec function StartFire( optional byte FireModeNum ) {
		HatchCount += 1;
		if(HatchCount >= 3) {
			HatchCount = 0;
			ServerTriggerHatch();
		} else {
			GWGFxHudWrapper(myHUD).HudMovie.SetCenterText("Mash E To Hatch");
		}
	}
	simulated function BeginState(name PreviousStateName) {
		local Rotator NewRotation;
		super.BeginState(PreviousStateName);
		NewRotation = Rotation;
		NewRotation.Roll = 0;
		SetRotation(NewRotation);
		HatchCount = 0;
		GWGFxHudWrapper(myHUD).HudMovie.SetCenterText("Mash E To Hatch");
	}
}

/**This calculates a relative movement input vector with the axes being within -1 and 1
 * (Movement input is keys or left analog stick)
 * 
 * @param   _fDeltaTime the current delta time to use for scaling
 * @return              the relative vector
 */
final function Vector GetRelativeInputMovement(float _fDeltaTime)
{
	local Vector vInputVector;

	vInputVector.X = PlayerInput.aForward/PlayerInput.MoveForwardSpeed;
	vInputVector.Y = PlayerInput.aStrafe/PlayerInput.MoveStrafeSpeed;
	vInputVector.Z = PlayerInput.aUp/PlayerInput.MoveStrafeSpeed;

	if(_fDeltaTime!=0)
	{
		vInputVector /= 100.f*_fDeltaTime;
	}

	//NOTE: For some reason the Z Axis scaling differs from XY, so it needs to be clamped
	vInputVector.Z = FClamp(vInputVector.Z,-1,1);

	return vInputVector;
}

/**Transforms relative movement input into camera aligned axes
 * For walking this means the XY-Plane
 * 
 * @param   _fDeltaTime	the current delta time to use for scaling
 * @return              the transformed vector
 */
function Vector GetDirectionalizedInputMovement(float _fDeltaTime)
{
	local Vector	X,Y,Z, vInputVector;

	vInputVector = GetRelativeInputMovement(_fDeltaTime);
	vInputVector.Z = 0;

	//Prevent speed hack (e.g. Forward is slower than Foward + Right movement)
	if(VSize(vInputVector)>1)
		vInputVector = Normal(vInputVector);

	//Align acceleration to view angle
	//GetAxes(PlayerCamera.Rotation,X,Y,Z);
	GetAxes(Pawn.Rotation, X, Y, Z);

	X.Z = 0;
	Y.Z = 0;

	vInputVector = Normal(vInputVector.X*X + vInputVector.Y*Y);

	return vInputVector;
}

DefaultProperties
{
	ReqStage1 = 50
	ReqStage2 = 150
	InputClass=class'GWPlayerInput'


	CharInfo(1)=(Pawn=class'GWPawn_Baby')
	CharInfo(2)=(Pawn=class'GWPawn_Power')
	CharInfo(3)=(Pawn=class'GWPawn_Skill')
	CharInfo(4)=(Pawn=class'GWPawn_Speed')
	CharInfo(5)=(Pawn=class'GWPawn_PowerMax')
	CharInfo(6)=(Pawn=class'GWPawn_SkillMax')
	CharInfo(7)=(Pawn=class'GWPawn_SpeedMax')
	CharInfo(8)=(Pawn=class'GWPawn_SkillPower')
	CharInfo(9)=(Pawn=class'GWPawn_SpeedPower')
	CharInfo(10)=(Pawn=class'GWPawn_SkillSpeed')

	WeaponHand=HAND_Hidden
	LocalMessageClass=class'GWTeamGameMessage'
	TimerMessageClass=class'GWTimerMessage'
	StartupMessageClass=class'GWStartupMessage'
}
