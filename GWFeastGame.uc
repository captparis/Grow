class GWFeastGame extends UTTeamGame implements(GWGameMode)
	config(Game);

var bool ShowColliders;
var WebServer WebApp;

function RestartPlayer(Controller NewPlayer)
{
	local UTPlayerController PC;
	local NavigationPoint startSpot;
	local int TeamNum;
	local LocalPlayer LP;
	local GWSpawnEgg SE;
	local Rotator StartRotation;

	PC = UTPlayerController(NewPlayer);
	if (PC != None)
	{
		// can't respawn if you have to join before the game starts and this player didn't
		if (bMustJoinBeforeStart && PC != None && PC.bLatecomer)
		{
			return;
		}
	} else {
		super.RestartPlayer(NewPlayer);
		return;
	}

	// can't respawn if out of lives
	if ( NewPlayer.PlayerReplicationInfo.bOutOfLives )
	{
		return;
	}

	if ( UTBot(NewPlayer) != None )
	{
		if ( TooManyBots(NewPlayer) )
		{
			NewPlayer.Destroy();
			return;
		}
		else if ( UTGameReplicationInfo(GameReplicationInfo).bStoryMode )
		{
			CampaignSkillAdjust(UTBot(NewPlayer));
		}
	}
	/**-------------------------------------*/
	if( bRestartLevel && WorldInfo.NetMode!=NM_DedicatedServer && WorldInfo.NetMode!=NM_ListenServer )
	{
		`warn("bRestartLevel && !server, abort from RestartPlayer"@WorldInfo.NetMode);
		return;
	}
	// figure out the team number and find the start spot
	TeamNum = ((NewPlayer.PlayerReplicationInfo == None) || (NewPlayer.PlayerReplicationInfo.Team == None)) ? 255 : NewPlayer.PlayerReplicationInfo.Team.TeamIndex;
	StartSpot = FindPlayerStart(NewPlayer, TeamNum);

	// if a start spot wasn't found,
	if (startSpot == None)
	{
		// check for a previously assigned spot
		if (NewPlayer.StartSpot != None)
		{
			StartSpot = NewPlayer.StartSpot;
			`warn("Player start not found, using last start spot");
		}
		else
		{
			// otherwise abort
			`warn("Player start not found, failed to restart player");
			return;
		}
	}
	NewPlayer.StartSpot = StartSpot;
	/***-----Spawn Egg */
	// don't allow pawn to be spawned with any pitch or roll
	StartRotation.Yaw = startSpot.Rotation.Yaw;
	SE = Spawn(class'GWSpawnEgg',,, startSpot.Location, StartRotation,,true);
	PC.GotoState('WaitingToHatch');
	PC.ClientGotoState('WaitingToHatch');
	PC.SetViewTarget(SE);

	// To fix custom post processing chain when not running in editor or PIE.
	if (PC != none)
	{
		LP = LocalPlayer(PC.Player); 
		if(LP != None) 
		{ 
			LP.RemoveAllPostProcessingChains(); 
			LP.InsertPostProcessingChain(LP.Outer.GetWorldPostProcessChain(),INDEX_NONE,true); 
			if(PC.myHUD != None)
			{
				PC.myHUD.NotifyBindPostProcessEffects();
			}
		} 
	}


	// Make sure VOIP state for this player is updated.  They may have just entered the game after spectating
	// for awhile post-connection.
	if( PC != None )
	{
		SetupPlayerMuteList( PC, false );		// Force spectator channel?
	}
}
function DelayedPlayerStart(Controller NewPlayer) {
	local UTVehicle V, Best;
	local vector ViewDir;
	local float BestDist, Dist;
	local UTPlayerController PC;
	local NavigationPoint startSpot;
	local int Idx;
	local array<SequenceObject> Events;
	local SeqEvent_PlayerSpawned SpawnedEvent;
	local LocalPlayer LP;


	PC = UTPlayerController(NewPlayer);
	startSpot = NewPlayer.StartSpot;
	// try to create a pawn to use of the default class for this player
	if (NewPlayer.Pawn == None)
	{
		NewPlayer.Pawn = SpawnDefaultPawnFor(NewPlayer, StartSpot);
	}
	if (NewPlayer.Pawn == None)
	{
		`log("failed to spawn player at "$StartSpot);
		NewPlayer.GotoState('Dead');
		if ( PlayerController(NewPlayer) != None )
		{
			PlayerController(NewPlayer).ClientGotoState('Dead','Begin');
		}
	}
	else
	{
		// initialize and start it up
		NewPlayer.Pawn.SetAnchor(startSpot);
		if ( PlayerController(NewPlayer) != None )
		{
			PlayerController(NewPlayer).TimeMargin = -0.1;
			startSpot.AnchoredPawn = None; // SetAnchor() will set this since IsHumanControlled() won't return true for the Pawn yet
		}
		NewPlayer.Pawn.LastStartSpot = PlayerStart(startSpot);
		NewPlayer.Pawn.LastStartTime = WorldInfo.TimeSeconds;
		NewPlayer.Possess(NewPlayer.Pawn, false);
		NewPlayer.Pawn.PlayTeleportEffect(true, true);
		Spawn(class'GWEmit_Cloud',,,NewPlayer.Pawn.Location,MakeRotator(0,0,0));
		NewPlayer.ClientSetRotation(NewPlayer.Pawn.Rotation, TRUE);

		if (!WorldInfo.bNoDefaultInventoryForPlayer)
		{
			AddDefaultInventory(NewPlayer.Pawn);
		}
		SetPlayerDefaults(NewPlayer.Pawn);

		// activate spawned events
		if (WorldInfo.GetGameSequence() != None)
		{
			WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_PlayerSpawned',TRUE,Events);
			for (Idx = 0; Idx < Events.Length; Idx++)
			{
				SpawnedEvent = SeqEvent_PlayerSpawned(Events[Idx]);
				if (SpawnedEvent != None &&
					SpawnedEvent.CheckActivate(NewPlayer,NewPlayer))
				{
					SpawnedEvent.SpawnPoint = startSpot;
					SpawnedEvent.PopulateLinkedVariableValues();
				}
			}
		}
	}

	// To fix custom post processing chain when not running in editor or PIE.
	if (PC != none)
	{
		LP = LocalPlayer(PC.Player); 
		if(LP != None) 
		{ 
			LP.RemoveAllPostProcessingChains(); 
			LP.InsertPostProcessingChain(LP.Outer.GetWorldPostProcessChain(),INDEX_NONE,true); 
			if(PC.myHUD != None)
			{
				PC.myHUD.NotifyBindPostProcessEffects();
			}
		} 
	}

	if ( NewPlayer.Pawn == None )
	{
		// pawn spawn failed
		return;
	}

	AssignHoverboard(UTPawn(NewPlayer.Pawn));

	if ( (WorldInfo.NetMode == NM_Standalone) && (PlayerController(NewPlayer) != None) )
	{
		// tell bots not to get into nearby vehicles for a little while
		BestDist = 2000;
		ViewDir = vector(NewPlayer.Pawn.Rotation);
		for ( V=VehicleList; V!=None; V=V.NextVehicle )
		{
			if ( !bTeamGame && V.bTeamLocked )
			{
				V.bTeamLocked = false;
			}
			if ( V.bTeamLocked && WorldInfo.GRI.OnSameTeam(NewPlayer,V) )
			{
				Dist = VSize(V.Location - NewPlayer.Pawn.Location);
				if ( (ViewDir Dot (V.Location - NewPlayer.Pawn.Location)) < 0 )
					Dist *= 2;
				if ( Dist < BestDist )
				{
					Best = V;
					BestDist = Dist;
				}
			}
		}
		if ( Best != None )
			Best.PlayerStartTime = WorldInfo.TimeSeconds + 8;
	}
}


/** RatePlayerStart()
* Return a score representing how desireable a playerstart is.
* @param P is the playerstart being rated
* @param Team is the team of the player choosing the playerstart
* @param Player is the controller choosing the playerstart
* @returns playerstart score
*/
function float RatePlayerStart(PlayerStart P, byte Team, Controller Player)
{
	local float Rating;
	local GWSpawnEgg A;
	
	Rating = super.RatePlayerStart(P, Team, Player);

	foreach VisibleActors(class'GWSpawnEgg', A, 50.f, P.Location)
	{
		Rating = FMin(0.f, Rating);
	}
	return Rating;
}
function PostBeginPlay() {
	Super.PostBeginPlay();
	if(WebApp == none) {
		WebApp = Spawn(class'WebServer');
	}
}
event Destroyed() {
	WebApp = none;
}
function AddDefaultInventory( pawn PlayerPawn )
{
	PlayerPawn.AddDefaultInventory();
}

static event class<GameInfo> SetGameType(string MapName, string Options, string Portal)
{
	local string ThisMapPrefix;
	local int i,pos;
	local class<GameInfo> NewGameType;
	local string GameOption;

	if (Left(MapName, 8) ~= "GrowMenu")
	{
		return class'MobileMenuGame';
		//return class'UTEntryGame';
	}
	if (Left(MapName, 9) ~= "GrowEntry" || Left(MapName, 14) ~= "UDKFrontEndMap")
	{
		return class'UTEntryGame';
	}
	// allow commandline to override game type setting
	GameOption = ParseOption( Options, "Game");
	if ( GameOption != "" )
	{
		return Default.class;
	}

	// strip the UEDPIE_ from the filename, if it exists (meaning this is a Play in Editor game)
	MapName = StripPlayOnPrefix( MapName );

	// replace self with appropriate gametype if no game specified
	pos = InStr(MapName,"-");
	ThisMapPrefix = left(MapName,pos);
	for (i = 0; i < default.MapPrefixes.length; i++)
	{
		if (default.MapPrefixes[i] ~= ThisMapPrefix)
		{
			return Default.class;
		}
	}

	// change game type
	for ( i=0; i<Default.DefaultMapPrefixes.Length; i++ )
	{
		if ( Default.DefaultMapPrefixes[i].Prefix ~= ThisMapPrefix )
		{
			NewGameType = class<GameInfo>(DynamicLoadObject(Default.DefaultMapPrefixes[i].GameType,class'Class'));
			if ( NewGameType != None )
			{
				return NewGameType;
			}
		}
	}
	for ( i=0; i<Default.CustomMapPrefixes.Length; i++ )
	{
		if ( Default.CustomMapPrefixes[i].Prefix ~= ThisMapPrefix )
		{
			NewGameType = class<GameInfo>(DynamicLoadObject(Default.CustomMapPrefixes[i].GameType,class'Class'));
			if ( NewGameType != None )
			{
				return NewGameType;
			}
		}
	}

    return class'UTGame';
}

/** handles all player initialization that is shared between the travel methods
 * (i.e. called from both PostLogin() and HandleSeamlessTravelPlayer())
 */
function GenericPlayerInitialization(Controller C)
{
	if ( !bUseClassicHUD )
	{
		HUDType = bTeamGame ? class'GWGFxTeamHUDWrapper' : class'GWGFxHudWrapper';
	}
	super.GenericPlayerInitialization(C);
}

event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage) {
	local PlayerController NewPlayer;
	local byte i;

	NewPlayer = Super.Login(Portal, Options, UniqueId, ErrorMessage);

	if ( GWPlayerController(NewPlayer) != None ) {
		//`Log("Login - Hat Index:"@GetIntOption( Options, "HatIndex", 255 ));
		for(i = 1; i <= 10; i++) {
			GWPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo).HatIndex[i] = GetIntOption( Options, "HatIndex"$i, 255 );
		}
	}

	return newPlayer;
}

function bool AllowGrow(PlayerReplicationInfo Player, EForm NewForm) {
	return true;
}

state MatchInProgress
{
	function Timer()
	{
		local PlayerController P;

		Global.Timer();
		if ( !bFinalStartup )
		{
			bFinalStartup = true;
			PlayStartupMessage();
		}
		// force respawn failsafe
		if ( ForceRespawn() )
		{
			foreach WorldInfo.AllControllers(class'PlayerController', P)
			{
				if (P.Pawn == None && !P.PlayerReplicationInfo.bOnlySpectator && !P.IsTimerActive('DoForcedRespawn') && !P.IsInState('WaitingToHatch'))
				{
					P.ServerReStartPlayer();
				}
			}
		}
		if ( NeedPlayers() )
		{
			AddBot();
		}

		if ( bOverTime )
		{
			EndGame(None,"TimeLimit");
		}
		else if ( TimeLimit > 0 )
		{
			GameReplicationInfo.bStopCountDown = false;
			if ( GameReplicationInfo.RemainingTime <= 0 )
			{
				EndGame(None,"TimeLimit");
			}
		}
		else if ( (MaxLives > 0) && (NumPlayers + NumBots != 1) )
		{
			CheckMaxLives(none);
		}
	}
}
function AddObjectiveScore(PlayerReplicationInfo Scorer, Int Score)
{
	if ( Scorer != None )
	{
		Scorer.Score += Score;
		Scorer.Team.Score += Score;
	}
	if (BaseMutator != None)
	{
		BaseMutator.ScoreObjective(Scorer, Score);
	}
}
DefaultProperties
{
	bSpawnInTeamArea = true
	MapPrefixes[0] = "GW"
	Acronym = "GW"
	
	bScoreDeaths = false
	bScoreTeamKills = False
	bScoreVictimsTarget = false
	
	bGivePhysicsGun = false

	bUseClassicHUD = true
	//BotClass = class'Grow.GWBotController'
	PlayerControllerClass = class'Grow.GWPlayerController'
	DefaultPawnClass = class'Grow.GWPawn_Baby'
	PlayerReplicationInfoClass=class'GWPlayerReplicationInfo'

	//HUDType = class'GWHud'
	HUDType = class'GWGFxTeamHUDWrapper'

	GameMessageClass=none
	MessageClass=none
	bDelayedStart=false

//	AnnouncerMessageClass=class'GWCTFMessage'
 	LocalMessageClass=class'GWTeamGameMessage'
	KillsRemainingMessageClass=class'GWKillsRemainingMessage'
	TeamScoreMessageClass=class'GWTeamScoreMessage'
	GameReplicationInfoClass=class'GWCTFGameReplicationInfo'
	VictoryMessageClass=class'GWVictoryMessage'
	FirstBloodMessageClass=class'GWFirstBloodMessage'
	KillingSpreeMessageClass=class'GWKillingSpreeMessage'
	DeathMessageClass=class'GWDeathMessage'
}
