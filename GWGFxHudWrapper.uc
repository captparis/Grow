/**********************************************************************

Copyright   :   Copyright 2006-2007 Scaleform Corp. All Rights Reserved.

Portions of the integration code is from Epic Games as identified by Perforce annotations.
Copyright 2010 Epic Games, Inc. All rights reserved.

Licensees may use this file in accordance with the valid Scaleform
Commercial License Agreement provided with the software.

This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING
THE WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR ANY PURPOSE.

**********************************************************************/
/**
 * HUDWrapper to workaround lack of multiple inheritance.
 * Related Flash content:   ut3_hud.fla
 *                          ut3_minimap.fla
 *                          ut3_scoreboard.fla
 *
 */
class GWGFxHudWrapper extends UTHUDBase;

/** Main Heads Up Display Flash movie */
var GWGFxMinimapHud   HudMovie;

/** Movie for non-functional sample inventory management UI */
var GFxProjectedUI   InventoryMovie;

/** Class of HUD Movie object */
var class<GWGFxMinimapHUD> MinimapHUDClass;

exec function MinimapZoomIn()
{
	HudMovie.MinimapZoomIn();
}

exec function MinimapZoomOut()
{
	HudMovie.MinimapZoomOut();
}

singular event Destroyed()
{
	RemoveMovies();

	Super.Destroyed();
}

/**
  * Destroy existing Movies
  */
function RemoveMovies()
{
	if ( HUDMovie != None )
	{
		HUDMovie.Close(true);
		HUDMovie = None;
	}
	if (InventoryMovie != None)
	{
		InventoryMovie.Close(true);
		InventoryMovie = None;
	}
	Super.RemoveMovies();
}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	CreateHUDMovie();
}

/**
  * Create and initialize the HUDMovie.
  */
function CreateHUDMovie()
{
	HudMovie = new MinimapHUDClass;
	HudMovie.SetTimingMode(TM_Real);
	HudMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HudMovie.LocalPlayerOwnerIndex]);
	HudMovie.ToggleCrosshair(true);
}

/**
  * Returns the index of the local player that owns this HUD
  */
function int GetLocalPlayerOwnerIndex()
{
	return HudMovie.LocalPlayerOwnerIndex;
}

/**
 *  Toggles visibility of normal in-game HUD
 */
function SetVisible(bool bNewVisible)
{
	HudMovie.ToggleCrosshair(bNewVisible);
	//HudMovie.Minimap.SetVisible(false);
	Super.SetVisible(bNewVisible);
	HudMovie.SetPause(!bNewVisible);
}

function DisplayHit(vector HitDir, int Damage, class<DamageType> damageType)
{
	HudMovie.DisplayHit(HitDir, Damage, DamageType);
}

/**
  * Called when pause menu is opened
  */
function CloseOtherMenus()
{
	if ( InventoryMovie != none && InventoryMovie.bMovieIsOpen )
	{
		InventoryMovie.StartCloseAnimation();
		return;
	}
}


/**
  * Recreate movies since resolution changed (also creates them initially)
  */
function ResolutionChanged()
{
	//local bool bNeedInventoryMovie;

	//bNeedInventoryMovie = InventoryMovie != none && InventoryMovie.bMovieIsOpen;
	super.ResolutionChanged();

	CreateHUDMovie();
	/*
	if ( bNeedInventoryMovie )
	{
		ToggleInventory();
	}
	*/
}

/**
 * PostRender is the main draw loop.
 */
event PostRender()
{
	local GWPlayerController PC;//This will hold the player controller

	local Vector CrosshairHitWorldNormal;//Hold the normalized vector of world location to get direction to CrosshairHitWorldLocation
	local Vector CrosshairPosWorldLocation;//Hold deprojected mouse location in 3d world coordinates.
	local Vector CrosshairPosWorldNormal;//Hold deprojected mouse location normal.

	local vector StartTrace;//Hold calculated start of ray from camera
	local Vector EndTrace;//Hold calculated end of ray from camera to ground
	local vector RayDir;//Hold the direction for the ray query.
	local Actor TraceActor;//If an actor is found under mouse cursor when mouse moves, its going to end up here.

	local Vector CameraLoc;
	local Rotator CameraRot;
	local Vector2D CrosshairPosition;
	local Vector Resolution;
	
	if (HudMovie != none)
		HudMovie.TickHud(0);

	if ( InventoryMovie != none && InventoryMovie.bMovieIsOpen )
	{
		InventoryMovie.Tick(RenderDelta);
		InventoryMovie.UpdatePos();
	}

	if ( bShowHud && bEnableActorOverlays )
	{
		DrawHud();
	}

	if (bShowMobileHud)
	{
		DrawInputZoneOverlays();
	}
//------------------------------------------------------------Tim Post Render------------------------------------------------------------
	PreCalcValues();

	//Set PC as CustomPlayerController version of the PlayerOwner
	PC = GWPlayerController(PlayerOwner);
	PC.GetPlayerViewPoint(CameraLoc,CameraRot);

	Resolution.X = (Canvas.ClipX);
	Resolution.Y = (Canvas.ClipY);

	//FullWidth = Canvas.ClipX;
	//FullHeight = Canvas.ClipY;

	//Get center of screen
	CrosshairPosition.X = Resolution.X/2;
	CrosshairPosition.Y = Resolution.Y/2;

	//find the cursor 3d location and direction
	Canvas.DeProject(CrosshairPosition, CrosshairPosWorldLocation, CrosshairPosWorldNormal);
	RayDir = CrosshairPosWorldNormal;

	StartTrace = CameraLoc + RayDir;  //where to start the trace from
	EndTrace = StartTrace + RayDir * 5000;    //where to end the trace

	//trace the line, see if it hits anything. store in CrosshairHitWorldLocation
	TraceActor = Trace(PC.CrosshairHitWorldLocation, CrosshairHitWorldNormal, EndTrace, StartTrace, true);

	if (TraceActor == PC.pawn)//if the line hit your pawn
	//search again, ignoring actors. Don't want to be shooting at yourself
	TraceActor = Trace(PC.CrosshairHitWorldLocation, CrosshairHitWorldNormal, EndTrace, StartTrace, false);

	if (PC.CrosshairHitWorldLocation == vect(0,0,0))//if the trace doesn't hit anything
	PC.CrosshairHitWorldLocation = EndTrace;// use the end trace location so you'll have somewhere to aim
	//`Log("Post Render:"$PC.CrosshairHitWorldLocation);
	PC.setCrosshairAim(PC.CrosshairHitWorldLocation);
	super.PostRender();
}

/**
  * Call PostRenderFor() on actors that want it.
  */
event DrawHUD()
{
	local vector ViewPoint;
	local rotator ViewRotation;
	local float XL, YL, YPos;

	if (UTGRI != None && !UTGRI.bMatchIsOver  )
	{
		Canvas.Font = GetFontSizeIndex(0);
		PlayerOwner.GetPlayerViewPoint(ViewPoint, ViewRotation);
		DrawActorOverlays(Viewpoint, ViewRotation);
	}

	if ( bCrosshairOnFriendly )
	{
		// verify that crosshair trace might hit friendly
		bGreenCrosshair = CheckCrosshairOnFriendly();
		bCrosshairOnFriendly = false;
	}
	else
	{
		bGreenCrosshair = false;
	}

	if ( HudMovie.bDrawWeaponCrosshairs )
	{
		PlayerOwner.DrawHud(self);
	}

	if ( bShowDebugInfo )
	{
		Canvas.Font = GetFontSizeIndex(0);
		Canvas.DrawColor = ConsoleColor;
		Canvas.StrLen("X", XL, YL);
		YPos = 0;
		PlayerOwner.ViewTarget.DisplayDebug(self, YL, YPos);

		if (ShouldDisplayDebug('AI') && (Pawn(PlayerOwner.ViewTarget) != None))
		{
			DrawRoute(Pawn(PlayerOwner.ViewTarget));
		}
		return;
	}
}

function LocalizedMessage
(
	class<LocalMessage>		InMessageClass,
	PlayerReplicationInfo	RelatedPRI_1,
	PlayerReplicationInfo	RelatedPRI_2,
	string					CriticalString,
	int						Switch,
	float					Position,
	float					LifeTime,
	int						FontSize,
	color					DrawColor,
	optional object			OptionalObject
)
{
	local class<UTLocalMessage> UTMessageClass;

	UTMessageClass = class<UTLocalMessage>(InMessageClass);

	if (InMessageClass == class'GWMultiKillMessage')
		HudMovie.ShowMultiKill(Switch, "Kill Streak!");
	else if (ClassIsChildOf (InMessageClass, class'UTDeathMessage'))
		HudMovie.AddDeathMessage (RelatedPRI_1, RelatedPRI_2, class<UTDamageType>(OptionalObject));
	else  if ( (UTMessageClass == None) || UTMessageClass.default.MessageArea > 6 )
	{
		HudMovie.AddMessage("text", InMessageClass.static.GetString(Switch, false, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	}
	else if ( (UTMessageClass.default.MessageArea < 4) || (UTMessageClass.default.MessageArea == 6) )
	{
		HudMovie.SetCenterText(InMessageClass.static.GetString(Switch, false, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	}

	// Skip message area 4,5 for now (pickup and weapon switch messages)
}

/**
 * Add a new console message to display.
 */
function AddConsoleMessage(string M, class<LocalMessage> InMessageClass, PlayerReplicationInfo PRI, optional float LifeTime)
{
	// check for beep on message receipt
	if( bMessageBeep && InMessageClass.default.bBeep )
	{
		PlayerOwner.PlayBeepSound();
	}

	HudMovie.AddMessage("text", M);
}

/*
 * Toggle for  3D Inventory menu.
 
exec function ToggleInventory()
{
	if ( InventoryMovie != None && InventoryMovie.bMovieIsOpen )
	{
		InventoryMovie.StartCloseAnimation();
	}
	else if ( PlayerOwner.Pawn != None )
	{
		if (InventoryMovie == None)
		{
			InventoryMovie = new class'GFxProjectedUI';
		}

		InventoryMovie.LocalPlayerOwnerIndex = class'Engine'.static.GetEngine().GamePlayers.Find(LocalPlayer(PlayerOwner.Player));
		InventoryMovie.SetTimingMode(TM_Real);
		InventoryMovie.Start();

		if (!WorldInfo.bPlayersOnly)
		{
		   PlayerOwner.ConsoleCommand("playersonly");
		}

		// Hide the HUD.
		SetVisible(false);
	}
}
*/

function CompleteCloseInventory()
{
	if (WorldInfo.bPlayersOnly)
	{
		PlayerOwner.ConsoleCommand("playersonly");
	}

	SetTimer(0.1, false, 'CompleteCloseTimer');
}
exec function SetShowScores(bool bEnableShowScores)
{
	// Don't allow displaying of leaderboard/scoreboard at same time
	if (LeaderboardMovie != none && LeaderboardMovie.bMovieIsOpen)
		return;

    if(bEnableShowScores)
    {
        if ( ScoreboardMovie == None )
        {
            ScoreboardMovie = new class'GWGFxUIScoreboard';
			ScoreboardMovie.LocalPlayerOwnerIndex = GetLocalPlayerOwnerIndex();
			ScoreboardMovie.SetTimingMode(TM_Real);
			ScoreboardMovie.ExternalInterface = self;
		}

        if ( !ScoreboardMovie.bMovieIsOpen )
        {
            ScoreboardMovie.Start();
            GWGFxUIScoreboard(ScoreboardMovie).PlayOpenAnimation();
        }
		SetVisible(false);
    }
    else if ( (ScoreboardMovie != None) && ScoreboardMovie.bMovieIsOpen )
	{
		GWGFxUIScoreboard(ScoreboardMovie).PlayCloseAnimation();
		SetVisible(true);
	}
}

/**
 * Displays/closes the leaderboard
 */
exec function SetShowLeaderboard(bool bEnableLeaderboard)
{
	// Don't allow displaying of leaderboard/scoreboard at same time
	if (ScoreboardMovie != none && ScoreboardMovie.bMovieIsOpen)
		return;

	if (bEnableLeaderboard)
	{
		if (LeaderboardMovie == none)
		{
			LeaderboardMovie = new Class'GWGFxUILeaderboard';

			LeaderboardMovie.LocalPlayerOwnerIndex = GetLocalPlayerOwnerIndex();
			LeaderboardMovie.SetTimingMode(TM_Real);
			// NOTE: Leaderboard does not need its external interface set
		}

		if (!LeaderboardMovie.bMovieIsOpen)
		{
			LeaderboardMovie.Start();
			GWGFxUILeaderboard(LeaderboardMovie).PlayOpenAnimation();
		}

		SetVisible(False);
	}
	else if (LeaderboardMovie != none && LeaderboardMovie.bMovieIsOpen)
	{
		GWGFxUILeaderboard(LeaderboardMovie).PlayCloseAnimation();
		SetVisible(True);
	}
}

/*
 * Used to manage the timing of events on Inventory close.
 *
 */
function CompleteCloseTimer()
{
	//If InventoryMovie exists, destroy it.
	if ( InventoryMovie != none && InventoryMovie.bMovieIsOpen )
	{
		InventoryMovie.Close(FALSE); // Keep the Pause Menu loaded in memory for reuse.
	}

	SetVisible(true);
}

defaultproperties
{
	bCrosshairShow=true
	bEnableActorOverlays=true
	MinimapHUDClass=class'GWGFxMinimapHUD'
}
