class GWHUD extends UTHUD;

var Texture HungerColorSkill;
var Texture HungerColorSpeed;
var Texture HungerColorPower;

var int HUDCoords[56];

function DrawLivingHud() {
	local float healthWidth;
	local float energyWidth;
	local GWPawn P;
	//local Color Red;
	//local Color Blue;
	//local Color Green;

	if(PawnOwner == none) {
		return;
	}
	P = GWPawn(PawnOwner);

	Canvas.SetPos(HUDCoords[0],HUDCoords[1]);

	Canvas.SetDrawColor(255,255,255);

	Canvas.DrawTile(Texture'Grow_HUD.BackgroundTex', HUDCoords[2], HUDCoords[3], HUDCoords[4], HUDCoords[5], HUDCoords[6], HUDCoords[7]);
	
	if(P.GetCurrentStage() == 2) {
	} else if(P.Speed >= P.Skill && P.Speed >= P.Power) {
		DrawHunger(HungerColorSpeed, P.Speed);
	} else if(P.Skill >= P.Power) {
		DrawHunger(HungerColorSkill, P.Skill);
	} else {
		DrawHunger(HungerColorPower, P.Power);
	}
	
	Canvas.SetPos(HUDCoords[0] + HUDCoords[16],HUDCoords[1] + HUDCoords[17]);
	Canvas.DrawTile(Texture'Grow_HUD.HungerOutlineTex', HUDCoords[18], HUDCoords[19], HUDCoords[20], HUDCoords[21], HUDCoords[22], HUDCoords[23]);
	
	healthWidth = HUDCoords[26] * FClamp(P.Health / float(P.HealthMax), 0, 1);
	Canvas.SetPos(HUDCoords[0] + HUDCoords[24],HUDCoords[1] + HUDCoords[25]);
	Canvas.DrawTile(Texture'Grow_HUD.HealthTex', healthWidth, HUDCoords[27], HUDCoords[28], HUDCoords[29], HUDCoords[30], HUDCoords[31]);
	
	energyWidth = HUDCoords[34] * UTWeapon(P.Weapon).GetPowerPerc();
	Canvas.SetPos(HUDCoords[0] + HUDCoords[32],HUDCoords[1] + HUDCoords[33]);
	Canvas.DrawTile(Texture'Grow_HUD.EnergyTex', energyWidth, HUDCoords[35], HUDCoords[36], HUDCoords[37], HUDCoords[38], HUDCoords[39]);
	DrawHUDText(string(UTWeapon(P.Weapon).GetPowerPerc() * 100), 20, 220,0,0,0);
	Canvas.SetPos(HUDCoords[0] + HUDCoords[40],HUDCoords[1] + HUDCoords[41]);
	Canvas.DrawTile(Texture'Grow_HUD.OutlineGlowTex', HUDCoords[42], HUDCoords[43], HUDCoords[44], HUDCoords[45], HUDCoords[46], HUDCoords[47]);
	
	Canvas.SetPos(HUDCoords[0] + HUDCoords[48],HUDCoords[1] + HUDCoords[49]);
	Canvas.DrawTile(Texture'Grow_HUD.OutlineTex', HUDCoords[50], HUDCoords[51], HUDCoords[52], HUDCoords[53], HUDCoords[54], HUDCoords[55]);

	//P.CooldownInst.SetScalarParameterValue('CooldownParam', GWWeap(P.Weapon).GetCooldownPerc());
	//Canvas.SetPos((Canvas.ClipX * 0.5) - 128, (Canvas.ClipY * 0.5) - 128);
	//Canvas.DrawMaterialTile(P.CooldownInst, 256, 256);
	/*DrawHUDText(H,"Cute Team Lives: "$int(UTGRI.Teams[1].Score),20,220,0,0,0);
	DrawHUDText(H,"Creepy Team Lives: "$int(UTGRI.Teams[0].Score),20,240,0,0,0);
	DrawHUDText(H, "Cooldown: "$GWWeap(Weapon).GetCooldownPerc(), 20, 260, 0, 0, 0);*/

	//GWWeap(P.Weapon).DrawTargets(self);
	GWWeap(P.Weapon).DrawAbilityTargets(self);
	/*Red = MakeColor(255, 0, 0);
	Blue = MakeColor(0,0,255);
	Green = MakeColor(0,255,0);
	Draw3DLine(P.Location - 100 * P.Floor, P.Location, Red);
	Draw3DLine(P.Location + 100 * P.Floor, P.Location, Blue);
	Draw3DLine(P.Location + 100 * Vector(P.Rotation), P.Location, Green);*/

}

function DrawHunger(Texture tex, int food) {
	local int maxFood;
	local float offset;
	local GWPawn P;

	P = GWPawn(PawnOwner);
	if(P.GetCurrentStage() == 0) {
		maxFood = GWPlayerController(P.Controller).ReqStage1;
		offset = FClamp(food / float(maxFood), 0, 1);
	} else if(P.GetCurrentStage() == 1) {
		maxFood = GWPlayerController(P.Controller).ReqStage2;
		offset = FClamp(food / float(maxFood), 0, 1);
	} else {
		maxFood = 0;
		offset = 1; // 0-1
	}
	// 1-0 * hud = hud-0
	offset = (1 - offset) * HUDCoords[11];
	Canvas.SetPos(HUDCoords[0] + HUDCoords[8],HUDCoords[1] + HUDCoords[9] + offset);
	Canvas.DrawTile(tex, HUDCoords[10], HUDCoords[11] - offset, HUDCoords[12], HUDCoords[13], HUDCoords[14], HUDCoords[15]);
}

function SetHUD(int element, int index = 0, int value = 0) {
	local int aindex;
	local GWPawn P;

	P = GWPawn(PawnOwner);
	aindex = element * 8;
	if(value != 0) {
		HUDCoords[aindex + index] = value;
	} else {
		P.ClientMessage("HUD Coords:"@HUDCoords[aindex]@HUDCoords[aindex + 1]);
		P.ClientMessage("HUD Coords:"@HUDCoords[aindex + 2]@HUDCoords[aindex + 3]);
		P.ClientMessage("HUD Coords:"@HUDCoords[aindex + 4]@HUDCoords[aindex + 5]);
		P.ClientMessage("HUD Coords:"@HUDCoords[aindex + 6]@HUDCoords[aindex + 7]);
	}
}

function DrawHUDText(string Text, int X, int Y, int R, int G, int B) {
	Canvas.SetPos(X,Y);
	Canvas.SetDrawColor(R,G,B,200);
	Canvas.Font = class'Engine'.static.GetSmallFont();
	Canvas.DrawText(Text);
}
function DrawHUD() {
	local float x,y,w,h;
	local vector ViewPoint;
	local rotator ViewRotation;


	// post render actors before creating safe region
	if (UTGRI != None && !UTGRI.bMatchIsOver && bShowHud && PawnOwner != none )
	{
		Canvas.Font = GetFontSizeIndex(0);
		PlayerOwner.GetPlayerViewPoint(ViewPoint, ViewRotation);
		DrawActorOverlays(Viewpoint, ViewRotation);
	}

	CheckViewPortAspectRatio();

//	Canvas.Font = PlayerFont;


	// Create the safe region
	w = FullWidth * SafeRegionPct;
	X = Canvas.OrgX + (Canvas.ClipX - w) * 0.5;

	// We have some extra logic for figuring out how things should be displayed
	// in split screen.

	h = FullHeight * SafeRegionPct;

		Y = Canvas.OrgY + (Canvas.ClipY - h) * 0.5;

	Canvas.OrgX = X;
	Canvas.OrgY = Y;
	Canvas.ClipX = w;
	Canvas.ClipY = h;
	Canvas.Reset(true);

	// Set up delta time
	RenderDelta = WorldInfo.TimeSeconds - LastHUDRenderTime;
	LastHUDRenderTime = WorldInfo.TimeSeconds;

	// If we are not over, draw the hud
	if (UTGRI != None && !UTGRI.bMatchIsOver)
	{
			PlayerOwner.DrawHud( Self );
			DrawGameHud();
	}
	else	// Match is over
	{
		//DrawPostGameHud();
	}

	LastHUDUpdateTime = WorldInfo.TimeSeconds;
}
function DrawGameHud() {
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

	DisplayLocalMessages();
	DisplayConsoleMessages();

	Canvas.Font = GetFontSizeIndex(1);

	if ( bShowClock && !bIsSplitScreen )
	{
		DisplayClock();
	}

	// If the player isn't dead, draw the living hud
	if ( !UTPlayerOwner.IsDead() )
	{
		DrawLivingHud();
	}

	//DisplayDamage();
}

simulated function PostBeginPlay() {

	super.PostBeginPlay();
	
	// add actors to the PostRenderedActors array
}

simulated event PostRender()
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

	PawnOwner = Pawn(PlayerOwner.ViewTarget);
	if ( PawnOwner == None )
	{
		PawnOwner = PlayerOwner.Pawn;
	}

	PreCalcValues();
	
	/**
	 * Aim Adjustment
	 */

	//Set PC as CustomPlayerController version of the PlayerOwner
	PC = GWPlayerController(PlayerOwner);
	PC.GetPlayerViewPoint(CameraLoc,CameraRot);

	Resolution.X = (Canvas.ClipX);
	Resolution.Y = (Canvas.ClipY);

	FullWidth = Canvas.ClipX;
	FullHeight = Canvas.ClipY;

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

// Unordered Functions Called Elsewhere
function CheckViewPortAspectRatio() {
	local vector2D ViewportSize;
	local bool bIsWideScreen;
	local PlayerController PC;

	foreach LocalPlayerControllers(class'PlayerController', PC) {
		LocalPlayer(PC.Player).ViewportClient.GetViewportSize(ViewportSize);
		break;
	}

	bIsWideScreen = (ViewportSize.Y > 0.f) && (ViewportSize.X/ViewportSize.Y > 1.7);

	if ( bIsWideScreen ) {
		RatioX = SizeX / 1280.f;
		RatioY = SizeY / 720.f;
	}
}

defaultproperties
{
	HudFonts(0)=Font'Grow_HUD.Fonts.Huggable_Small'
	HudFonts(1)=Font'Grow_HUD.Fonts.Huggable_Medium'
	HudFonts(2)=Font'Grow_HUD.Fonts.Huggable_Large'
	HudFonts(3)=Font'Grow_HUD.Fonts.Huggable_Huge'

	HungerColorSkill=Texture'Grow_HUD.HungerBlueTex'
	HungerColorPower=Texture'Grow_HUD.HungerRedTex'
	HungerColorSpeed=Texture'Grow_HUD.HungerYellowTex'
	
	HUDCoords[0] = 0;
	HUDCoords[1] = 0;
	HUDCoords[2] = 502;
	HUDCoords[3] = 185;
	HUDCoords[4] = 7;
	HUDCoords[5] = 6;
	HUDCoords[6] = 669;
	HUDCoords[7] = 247;
	
	HUDCoords[8] = 45;
	HUDCoords[9] = 50;
	HUDCoords[10] = 98;
	HUDCoords[11] = 92;
	HUDCoords[12] = 1;
	HUDCoords[13] = 4;
	HUDCoords[14] = 130;
	HUDCoords[15] = 122;
	
	HUDCoords[16] = 15;
	HUDCoords[17] = 16;
	HUDCoords[18] = 166;
	HUDCoords[19] = 152;
	HUDCoords[20] = 5;
	HUDCoords[21] = 6;
	HUDCoords[22] = 221;
	HUDCoords[23] = 202;
	
	HUDCoords[24] = 165;
	HUDCoords[25] = 31;
	HUDCoords[26] = 318;
	HUDCoords[27] = 31;
	HUDCoords[28] = 7;
	HUDCoords[29] = 13;
	HUDCoords[30] = 424;
	HUDCoords[31] = 41;
	
	HUDCoords[32] = 200;
	HUDCoords[33] = 75;
	HUDCoords[34] = 235;
	HUDCoords[35] = 26;
	HUDCoords[36] = 9;
	HUDCoords[37] = 16;
	HUDCoords[38] = 313;
	HUDCoords[39] = 34;
	
	HUDCoords[40] = 164;
	HUDCoords[41] = 31;
	HUDCoords[42] = 319;
	HUDCoords[43] = 71;
	HUDCoords[44] = 3;
	HUDCoords[45] = 3;
	HUDCoords[46] = 425;
	HUDCoords[47] = 95;
	
	HUDCoords[48] = 160;
	HUDCoords[49] = 27;
	HUDCoords[50] = 326;
	HUDCoords[51] = 75;
	HUDCoords[52] = 6;
	HUDCoords[53] = 8;
	HUDCoords[54] = 434;
	HUDCoords[55] = 100;
}