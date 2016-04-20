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
 * GFx HUD Demo for UTGame.
 * Related Flash content:   ut3_hud.fla
 * 
 * 
 */

class GWGFxMinimapHud extends GFxMoviePlayer
	dependson(GWConstants);
	
var WorldInfo    ThisWorld;
//var GFxMinimap   Minimap;
var float        Radius;
var float        CurZoomf, NormalZoomf, MaxZoomf, MinZoomf;

struct MessageRow
{
	var GFxObject  MC, TF;
	var float     StartFadeTime;
	var int       Y;
};

var GFxObject     LogMC;
var array<MessageRow>   Messages, FreeMessages;
var float               MessageHeight;
var int                 NumMessages;

//------------------------------------------------------------GW Vars------------------------------------------------------------
var GFxObject	VersionTF;
var string		VersionNo;
//-GW PlayerStats vars
var GFxObject	PlayerStatsMC, 
				PSControllerOverlayMC,
				HealthTF, HealthMC, HealthRedMC, HealthWhiteMC, SpitNotifierMC,
				AttackContainerMC, AttackMC, AttackBarMC, AttackRingMC, AttackPicMC, AttackFoodPicMC, AttackKeyMC, AttackKeyTF,
				SpecialContainerMC, SpecialMC, SpecialBarMC, SpecialRingMC, SpecialPicMC, SpecialKeyMC, SpecialKeyTF,
				ExtraContainerMC, ExtraMC, ExtraBarMC, ExtraRingMC, ExtraPicMC, ExtraKeyMC, ExtraKeyTF;
var int			LastHealth, HealthTrans, LastHealthPercent, LastFoodHP, MaxFoodHP;
var bool		AttackEnabled, AttackShouldEnable, 
				SpecialEnabled, SpecialShouldEnable, 
				ExtraEnabled, ExtraShouldEnable,
				AbilityActive;
var float		LastEnergy;
var float		LastWeapCD[3];
//-GW CharacterStats vars
var GFxObject	CharacterStatsMC, 
				PortraitMC, AddFoodMC, CSControllerOverlayMC,
				DownContainerMC, DownMC, DownBarMC, DownRingMC, DownPicMC, DownFoodPicMC, DownKeyMC, DownKeyTF,
				MeatContainerMC, MeatMC, MeatBarMC, MeatRingMC, MeatPicMC, MeatGlowMC, MeatKeyMC, MeatKeyTF,
				CandyContainerMC, CandyMC, CandyBarMC, CandyRingMC, CandyPicMC, CandyGlowMC, CandyKeyMC, CandyKeyTF,
				FruitContainerMC, FruitMC, FruitBarMC, FruitRingMC, FruitPicMC, FruitGlowMC, FruitKeyMC, FruitKeyTF,
				EatNotifierMC, EatNotifierEatMC, EatKeyTF;
var int			LastMeat, MeatTEMP, LastCandy, CandyTEMP, LastFruit, FruitTEMP, LastDown, DownTEMP, MaxFood;
var bool		DownEnabled, MeatEnabled, CandyEnabled, FruitEnabled,
				DownShouldEnable, MeatShouldEnable, CandyShouldEnable, FruitShouldEnable;
var float		LastGrowCharge;
var EForm		CurrentChar, FirstChar, SecondChar;
var string		CurrentCharName, FirstCharName, SecondCharName;
var EFood		LastFoodType;
//-GW Misc
var GFxObject	ReticuleMC, ReticuleInnerMC, ReticuleOuterMC;

var GFxObject     TeamStatsMC;
var GFxObject     AmmoCountTF, AmmoBarMC, MaxAmmoMC, ArmorTF, ArmorMC, VArmorMC, VArmorTF, TimeTF;
var GFxObject     WeaponMC, ArmorPercTF;

var GFxObject     CenterTextMC, CenterTextTF;
var GFxObject     ScoreBarMC[2], ScoreTF[2], FlagCarrierMC[2], FlagCarrierTF[2], EnemyNameTF;

var GFxObject     HitLocMC[8], MultiKillN_TF, MultiKillMsg_TF, MultiKillMC;
//var GFxObject     ReticuleMC, RBotMC, RRightMC, RTopMC, RLeftMC;
var bool		WasUsingController;

var UTVehicle LastVehicle;
var UTWeapon     LastWeapon;
var float        LastArmor, HealthTransFactor, LastVHealth;
var int          LastAmmoCount;
var int          LastScore[2];
var byte         LastFlagHome[2];
var UTPlayerReplicationInfo  LastEnemy, LastFlagCarrier[2];

var UTGameReplicationInfo GRI;

/** IF true, set this HUD up a a team HUD */
var bool bIsTeamHUD;

/** If true, let weapons draw their crosshairs instead of using GFx crosshair */
var bool bDrawWeaponCrosshairs;

/*
 * Callback fired from Flash when Minimap is loaded.
 *   "ExternalInterface.call("RegisterMinimapView", this)";
 *   
 * Used to pass a reference to the MovieClip which is loaded
 * from Flash back to UnrealScript.
 */
 
function registerMiniMapView(GFxMinimap mc, float r)
{
    //Minimap = mc;
	Radius = r;
	CurZoomf = 64;
	NormalZoomf = 64;
/*	if (Minimap != none)
	{
		//Minimap.Init(self);
		Minimap.SetVisible(false);
		Minimap.SetFloat("_xscale", 85);
		Minimap.SetFloat("_yscale", 85);
	}*/
}

/*
 * Creates a new LogMessage MovieClip for use in the 
 * log.
 */
function GFxObject CreateMessageRow()
{
	return LogMC.AttachMovie("LogMessage", "logMessage"$NumMessages++);
}

/*
 * Initalizes a new MessageRow and adds it to the list
 * of available log MessageRow MovieClips for reuse.
 */
function GFxObject InitMessageRow()
{
	local MessageRow mrow;

	mrow.Y = 0;
	mrow.MC = CreateMessageRow();

	mrow.TF = mrow.MC.GetObject("message").GetObject("textField");
	mrow.TF.SetBool("html", true);
	mrow.TF.SetString("htmlText", "");

	FreeMessages.AddItem(mrow);
	return mrow.MC;
}

/*
 * Initialization method for HUD.
 * 
 * Caches all the references to MovieClips that will be updated throughout
 * the HUD's lifespan.
 * 
 * For the record, GetVariableObject is not as fast as GFxObject::GetObject() but
 * nevertheless is used here for convenience.
 * 
 */
function Init(optional LocalPlayer player)
{
	local int j;
	local GFxObject TempWidget;
	
	super.Init(player);

	ThisWorld = GetPC().WorldInfo;
	GRI = UTGameReplicationInfo(GetPC().WorldInfo.GRI);

    Start();
    Advance(0);

    NumMessages = 0;
	DownTEMP = 10;
	LastFoodType = -1;
	CurrentChar = -10;
	FirstChar = -1;
	SecondChar = -1;
	CurrentCharName = "";
	FirstCharName = "";
	SecondCharName = "";
	ExtraEnabled = false;
	SpecialEnabled = false;
	AttackEnabled = false;
	DownEnabled = false;
	MeatEnabled = false;
	CandyEnabled = false;
	FruitEnabled = false;
	ExtraShouldEnable = false;
	AttackShouldEnable = false;
	SpecialShouldEnable = false;
	DownShouldEnable = false;
	MeatShouldEnable = false;
	CandyShouldEnable = false;
	FruitShouldEnable = false;
	AbilityActive = false;
	WasUsingController = true;
	MaxFood = 0;
	LastEnergy = -1;
	LastHealth = -110;
	LastHealthPercent = -110;
	HealthTrans = -10;
	LastArmor = -110;
	LastAmmoCount = -110;
	LastScore[0] = -110;
	LastScore[1] = -110;
	for(j=0; j<2; j++)
	{
		LastWeapCD[j]=-1;
	}
	
	TempWidget = GetVariableObject("_root.expBar"); 
	if ( TempWidget != None ) 
	{ 
		TempWidget.SetBool("_visible", false);
	}

    TempWidget = GetVariableObject("_root.rank"); 
	if ( TempWidget != None ) 
	{
		TempWidget.SetBool("_visible", false);
	}

    TempWidget = GetVariableObject("_root.billboard"); 
	if ( TempWidget != None ) 
	{
		TempWidget.SetBool("_visible", false);
	}

	TempWidget = GetVariableObject("_root.title"); 
	if ( TempWidget != None ) 
	{
		TempWidget.SetBool("_visible", false);
	}
    TempWidget = GetVariableObject("_root.stats"); 
	if ( TempWidget != None ) 
	{
		TempWidget.SetBool("_visible", false);
	}

    TempWidget = GetVariableObject("_root.flag"); 
	if ( TempWidget != None ) 
	{
		TempWidget.SetVisible(false);
	}

	TempWidget = GetVariableObject("_root.teamStats.redWinning");
	if ( TempWidget != None ) 
	{
		TempWidget.SetVisible(false);
	}

	TempWidget = GetVariableObject("_root.teamStats.blueWinning"); 
	if ( TempWidget != None ) 
	{
		TempWidget.SetVisible(false);
	}

    LogMC = GetVariableObject("_root.log");
    for (j = 0; j < 15; j++)
		InitMessageRow();

    TeamStatsMC = GetVariableObject("_root.teamStats");
    
//------------------------------------------------------------GW Objects------------------------------------------------------------
	VersionTF = GetVariableObject("_root.version");
	VersionTF.SetString("text", VersionNo);
//Player Stats
	PlayerStatsMC = GetVariableObject("_root.playerStats");
	SpitNotifierMC = GetVariableObject("_root.playerStats.spitnotice");
	//required for UDK vehicle hud, remove later
	PlayerStatsMC.GotoAndStopI(3);
	VArmorTF = GetVariableObject("_root.playerStats.vehicleN");
    VArmorMC = GetVariableObject("_root.playerStats.healthVehicle");
	
    PlayerStatsMC.GotoAndStopI(2);
	//required for weapon graphics, remove later
	WeaponMC = GetVariableObject("_root.playerStats.weapon");
//-Health	
    HealthTF = GetVariableObject("_root.playerStats.healthN");
    HealthMC = GetVariableObject("_root.playerStats.health");
	HealthRedMC = GetVariableObject("_root.playerStats.health.red");
	HealthWhiteMC = GetVariableObject("_root.playerStats.health.white");
//-Attack
	AttackContainerMC = GetVariableObject("_root.playerStats.attackcontainer");
	AttackMC = GetVariableObject("_root.playerStats.attackcontainer.attack");
	AttackBarMC = GetVariableObject("_root.playerStats.attackcontainer.attack.bar");
	AttackPicMC = GetVariableObject("_root.playerStats.attackcontainer.attack.picture");
	AttackMC.GotoAndStopI(2);
	AttackRingMC = GetVariableObject("_root.playerStats.attackcontainer.attack.ring");
	AttackMC.GotoAndStopI(3);
	AttackFoodPicMC = GetVariableObject("_root.playerStats.attackcontainer.attack.food");
	AttackKeyMC = GetVariableObject("_root.playerStats.attackkey");
	AttackKeyTF = GetVariableObject("_root.playerStats.attackkey.key");
	AttackKeyTF.SetString("text", "RM");
//-Special
	SpecialContainerMC = GetVariableObject("_root.playerStats.specialcontainer");
	SpecialMC = GetVariableObject("_root.playerStats.specialcontainer.special");
	SpecialBarMC = GetVariableObject("_root.playerStats.specialcontainer.special.bar");
	SpecialPicMC = GetVariableObject("_root.playerStats.specialcontainer.special.picture");
	SpecialMC.GotoAndStopI(2);
	SpecialRingMC = GetVariableObject("_root.playerStats.specialcontainer.special.ring");
	SpecialKeyMC = GetVariableObject("_root.playerStats.specialkey");
	SpecialKeyTF = GetVariableObject("_root.playerStats.specialkey.key");
	SpecialKeyTF.SetString("text", "E");
//-Extra
	ExtraContainerMC = GetVariableObject("_root.playerStats.extracontainer");
	ExtraMC = GetVariableObject("_root.playerStats.extracontainer.extra");
	ExtraBarMC = GetVariableObject("_root.playerStats.extracontainer.extra.bar");
	ExtraPicMC = GetVariableObject("_root.playerStats.extracontainer.extra.picture");
	ExtraMC.GotoAndStopI(2);
	ExtraRingMC = GetVariableObject("_root.playerStats.extracontainer.extra.ring");
	ExtraKeyMC = GetVariableObject("_root.playerStats.extrakey");
	ExtraKeyTF = GetVariableObject("_root.playerStats.extrakey.key");
	ExtraKeyTF.SetString("text", " ");
	ExtraMC.GotoAndStopI(1);
	ExtraContainerMC.SetVisible(false);
//-ControllerOverlay
	PSControllerOverlayMC = GetVariableObject("_root.playerStats.coverlay");
	
//Character Stats
	CharacterStatsMC = GetVariableObject("_root.characterStats");
	CharacterStatsMC.GotoAndStopI(2);
//-AddFood
	AddFoodMC = GetVariableObject("_root.characterStats.addfood");
//-Portrait
	EatNotifierMC = GetVariableObject("_root.characterStats.eatnotice");
	EatNotifierEatMC = GetVariableObject("_root.characterStats.eatnotice.eatbutton");
	EatKeyTF = GetVariableObject("_root.characterStats.eatnotice.eatbutton.anim.key");
	EatNotifierMC.GotoAndStop("off");
	EatKeyTF.SetString("text", "LM");
//-Up
//--Meat
	MeatContainerMC = GetVariableObject("_root.characterStats.meatcontainer");
	MeatMC = GetVariableObject("_root.characterStats.meatcontainer.meat");
	MeatBarMC = GetVariableObject("_root.characterStats.meatcontainer.meat.food");
	MeatPicMC = GetVariableObject("_root.characterStats.meatcontainer.meat.picture");
	MeatMC.GotoAndStopI(2);
	MeatRingMC = GetVariableObject("_root.characterStats.meatcontainer.meat.ring");
	MeatGlowMC = GetVariableObject("_root.characterStats.glowMeat");
	MeatKeyMC = GetVariableObject("_root.characterStats.meatkey");
	MeatKeyTF = GetVariableObject("_root.characterStats.meatkey.key");
	MeatKeyTF.SetString("text", "1");
	//MeatGlowMC.GotoAndStopI(2);
//--Candy
	CandyContainerMC = GetVariableObject("_root.characterStats.candycontainer");
	CandyMC = GetVariableObject("_root.characterStats.candycontainer.candy");
	CandyBarMC = GetVariableObject("_root.characterStats.candycontainer.candy.food");
	CandyPicMC = GetVariableObject("_root.characterStats.candycontainer.candy.picture");
	CandyMC.GotoAndStopI(2);
	CandyRingMC = GetVariableObject("_root.characterStats.candycontainer.candy.ring");
	CandyGlowMC = GetVariableObject("_root.characterStats.glowCandy");
	CandyKeyMC = GetVariableObject("_root.characterStats.candykey");
	CandyKeyTF = GetVariableObject("_root.characterStats.candykey.key");
	CandyKeyTF.SetString("text", "2");
	//CandyGlowMC.GotoAndStopI(2);
//--Fruit
	FruitContainerMC = GetVariableObject("_root.characterStats.fruitcontainer");
	FruitMC = GetVariableObject("_root.characterStats.fruitcontainer.fruit");
	FruitBarMC = GetVariableObject("_root.characterStats.fruitcontainer.fruit.food");
	FruitPicMC = GetVariableObject("_root.characterStats.fruitcontainer.fruit.picture");
	FruitMC.GotoAndStopI(2);
	FruitRingMC = GetVariableObject("_root.characterStats.fruitcontainer.fruit.ring");
	FruitGlowMC = GetVariableObject("_root.characterStats.glowFruit");
	FruitKeyMC = GetVariableObject("_root.characterStats.fruitkey");
	FruitKeyTF = GetVariableObject("_root.characterStats.fruitkey.key");
	FruitKeyTF.SetString("text", "3");
	//FruitGlowMC.GotoAndStopI(2);
//-Down
	DownContainerMC = GetVariableObject("_root.characterStats.downcontainer");
	DownMC = GetVariableObject("_root.characterStats.downcontainer.down");
	DownBarMC = GetVariableObject("_root.characterStats.downcontainer.down.bar");
	DownPicMC = GetVariableObject("_root.characterStats.downcontainer.down.picture");
	DownMC.GotoAndStopI(2);
	DownRingMC = GetVariableObject("_root.characterStats.downcontainer.down.ring");
	DownMC.GotoAndStopI(3);
	DownFoodPicMC = GetVariableObject("_root.characterStats.downcontainer.down.food");
	DownKeyMC = GetVariableObject("_root.characterStats.downkey");
	DownKeyTF = GetVariableObject("_root.characterStats.downkey.key");
	DownKeyTF.SetString("text", "Q");
//-ControllerOverlay
	CSControllerOverlayMC = GetVariableObject("_root.characterStats.coverlay");

//Misc
	ReticuleMC = GetVariableObject("_root.reticule");
	ReticuleInnerMC = GetVariableObject("_root.reticule.outer");
	ReticuleOuterMC = GetVariableObject("_root.reticule.inner");
	
    AmmoCountTF = GetVariableObject("_root.playerStats.ammoN");
    AmmoBarMC = GetVariableObject("_root.playerStats.ammo");
    MaxAmmoMC = GetVariableObject("_root.playerStats.ammo.ammoBG");
    ArmorTF = GetVariableObject("_root.playerStats.armorN");
    ArmorMC = GetVariableObject("_root.playerStats.armor");
    ArmorPercTF = GetVariableObject("_root.playerStats.armorPerc");

	EnemyNameTF = GetVariableObject("_root.teamStats.redName");
	CenterTextTF = GetVariableObject("_root.centerTextMC.centerText.textField");
	CenterTextMC = GetVariableObject("_root.centerTextMC");

    //ReticuleMC = GetVariableObject("_root.reticule");
    //RBotMC = GetVariableObject("_root.reticule.bottom");
    //RTopMC = GetVariableObject("_root.reticule.top");
    //RLeftMC = GetVariableObject("_root.reticule.left");
    //RRightMC = GetVariableObject("_root.reticule.right");

	MultiKillMC = GetVariableObject("_root.popup");

    TimeTF = GetVariableObject("_root.teamStats.roundTime");

	if ( bIsTeamHUD )
	{
		ScoreBarMC[0] = GetVariableObject("_root.teamStats.teamRed");
		ScoreTF[0] = GetVariableObject("_root.teamStats.scoreRed");
		ScoreBarMC[1] = GetVariableObject("_root.teamStats.teamBlue");
		ScoreTF[1] = GetVariableObject("_root.teamStats.scoreBlue");
		FlagCarrierMC[0] = GetVariableObject("_root.flagRed");
		FlagCarrierMC[1] = GetVariableObject("_root.flagBlue");
	}
	else
	{
		ScoreBarMC[1] = GetVariableObject("_root.teamStats.teamRed");
		ScoreTF[1] = GetVariableObject("_root.teamStats.scoreRed");
		ScoreBarMC[0] = GetVariableObject("_root.teamStats.teamBlue");
		ScoreTF[0] = GetVariableObject("_root.teamStats.scoreBlue");
		FlagCarrierMC[0] = GetVariableObject("_root.flagBlue");
		FlagCarrierMC[1] = GetVariableObject("_root.flagRed");
	}

	if ( bIsTeamHUD )
	{
		EnemyNameTF.SetVisible(false);
		FlagCarrierTF[0] = FlagCarrierMC[0].GetObject("textField");
		FlagCarrierTF[1] = FlagCarrierMC[1].GetObject("textField");
		FlagCarrierTF[0].SetText("");
		FlagCarrierTF[1].SetText("");
	}
	else
	{
		EnemyNameTF.SetText("");
		FlagCarrierMC[0].SetVisible(false);
		FlagCarrierMC[1].SetVisible(false);
		ScoreBarMC[0].SetVisible(false);
		ScoreBarMC[1].SetVisible(false);
		ScoreTF[0].SetVisible(false);
		ScoreTF[1].SetVisible(false);
		TeamStatsMC.SetVisible(false);  // FIXMESTEVE - also removes clock
	}

	HitLocMC[0] = GetVariableObject("_root.dirHit.t");
	HitLocMC[1] = GetVariableObject("_root.dirHit.tr");
	HitLocMC[2] = GetVariableObject("_root.dirHit.r");
	HitLocMC[3] = GetVariableObject("_root.dirHit.br");
	HitLocMC[4] = GetVariableObject("_root.dirHit.b");
	HitLocMC[5] = GetVariableObject("_root.dirHit.bl");
	HitLocMC[6] = GetVariableObject("_root.dirHit.l");
	HitLocMC[7] = GetVariableObject("_root.dirHit.tl");

    LogMC.SetFloat("_yrotation", -5);
    TeamStatsMC.SetFloat("_yrotation", -15);

    FlagCarrierMC[0].SetFloat("_yrotation", 15);
	FlagCarrierMC[1].SetFloat("_yrotation", 15);
    PlayerStatsMC.SetFloat("_yrotation", 10);
	CharacterStatsMC.SetFloat("_yrotation", -10);

    ClearStats(true);
}

function bool MCToggle(GFxObject mc, bool enabled, bool shouldenable)
{
	local bool resultenabled;
	if (enabled)
	{
		if (!shouldenable)
		{
			mc.GotoAndPlayI(12);
			resultenabled = false;
		}
		else
		{
			resultenabled = true;
		}
	}
	else
	{
		if (shouldenable)
		{
			mc.GotoAndPlayI(2);
			resultenabled = true;
		}
		else
		{
			resultenabled = false;
		}
	}
	//`log(VersionNo$"----------------------------MCToggle, MC:"@mc@", enabled:"@enabled@", shouldenable:"@shouldenable@", resultenabled"@resultenabled);
	return resultenabled;
}

function KeyToggle(GFxObject mc, bool enabled)
{
	if (enabled)
	{
		mc.GotoAndStopI(1);
	}
	else
	{
		mc.GotoAndStopI(2);
	}
}

static function string FormatTime(int Seconds)
{
	local int Hours, Mins;
	local string NewTimeString;

	Hours = Seconds / 3600;
	Seconds -= Hours * 3600;
	Mins = Seconds / 60;
	Seconds -= Mins * 60;
	if (Hours > 0)
		NewTimeString = ( Hours > 9 ? String(Hours) : "0"$String(Hours)) $ ":";
	NewTimeString = NewTimeString $ ( Mins > 9 ? String(Mins) : "0"$String(Mins)) $ ":";
	NewTimeString = NewTimeString $ ( Seconds > 9 ? String(Seconds) : "0"$String(Seconds));

	return NewTimeString;
}

//------------------------------------------------------------Clear Stats------------------------------------------------------------
function ClearStats(optional bool clearScores)
{
	local GFxObject.ASDisplayInfo DI;
	local int i;
	DI.hasXScale = true;
	DI.XScale = 0;

	if (LastVehicle != none)
	{
		PlayerStatsMC.GotoAndStopI(2);
		LastVehicle = none;
	}
	if (CurrentChar != -1)
	{
		CandyGlowMC.GotoAndStopI(2);
		MeatGlowMC.GotoAndStopI(2);
		FruitGlowMC.GotoAndStopI(2);
		EatNotifierMC.GotoAndStop("off");
		SpitNotifierMC.GotoAndStop("off");
		AttackShouldEnable = false;
		SpecialShouldEnable = false;
		ExtraShouldEnable = false;
		DownShouldEnable = false;
		MeatShouldEnable = false;
		CandyShouldEnable = false;
		FruitShouldEnable = false;
		DownEnabled = MCToggle(DownContainerMC, DownEnabled, DownShouldEnable);
		SpecialEnabled = MCToggle(SpecialContainerMC, SpecialEnabled, SpecialShouldEnable);
		ExtraEnabled = MCToggle(ExtraContainerMC, ExtraEnabled, ExtraShouldEnable);
		AttackEnabled = MCToggle(AttackContainerMC, AttackEnabled, AttackShouldEnable);
		MeatEnabled = MCToggle(DownContainerMC, MeatEnabled, MeatShouldEnable);
		CandyEnabled = MCToggle(SpecialContainerMC, CandyEnabled, CandyShouldEnable);
		FruitEnabled = MCToggle(AttackContainerMC, FruitEnabled, FruitShouldEnable);
		KeyToggle(DownKeyMC, DownEnabled);
		KeyToggle(SpecialKeyMC, SpecialEnabled);
		KeyToggle(ExtraKeyMC, ExtraEnabled);
		KeyToggle(AttackKeyMC, AttackEnabled);
		KeyToggle(MeatKeyMC, MeatEnabled);
		KeyToggle(CandyKeyMC, CandyEnabled);
		KeyToggle(FruitKeyMC, FruitEnabled);
		AbilityActive = false;
		LastFoodType = 0;
		CurrentChar = 0;
		FirstChar = 0;
		SecondChar = 0;
		CurrentCharName = "none";
		FirstCharName = "none";
		SecondCharName = "none";
		MaxFood = 0;
		LastGrowCharge = -1;
		LastEnergy = -1;
	}
	if (LastHealth != -10)
	{
		HealthRedMC.GotoAndStopI(500);
		HealthWhiteMC.GotoAndStopI(500);
		
		HealthMC.GotoAndStop("dead");
		HealthTF.SetString("text", "");
		LastHealth = -10;
		HealthTrans = -10;
		LastHealthPercent = -10;
	}
	for(i=0; i<2; i++)
	{
		LastWeapCD[i]=0;
	}
	if (LastArmor != -10)
	{
		if (ArmorMC != none)
		{
			ArmorMC.SetVisible(false);
		}
		//ArmorPercTF.SetVisible(false);
		ArmorTF.SetString("text", "");		
		LastArmor = -10;
	}
	if (LastAmmoCount != -10)
	{
		AmmoCountTF.SetString("text", "");
		AmmoBarMC.GotoAndStopI(51);
		LastAmmoCount = -10;
	}
	if (LastWeapon != none)
	{
		WeaponMC.SetVisible(false);
		MaxAmmoMC.GotoAndStopI(51);
		LastWeapon = none;
	}

	if (clearScores && LastScore[0] != -100000)
	{
		if ( bIsTeamHUD )
		{
			LastScore[0] = -100000;
			LastScore[1] = -100000;
			ScoreTF[0].SetString("text", "");
			ScoreTF[1].SetString("text", "");
			ScoreBarMC[0].SetDisplayInfo(DI);
			ScoreBarMC[1].SetDisplayInfo(DI);
			FlagCarrierTF[0].SetText("");
			FlagCarrierTF[1].SetText("");
		}
		TimeTF.SetString("text", "");
		LastEnemy = none;
		EnemyNameTF.SetText("");
	}
}

function RemoveMessage()
{

}

function AddMessage(string type, string msg)
{
	local MessageRow mrow;
	local GFxObject.ASDisplayInfo DI;
	local int j;

	if (Len(msg) == 0)
		return;

	if (FreeMessages.Length > 0)
	{
		mrow = FreeMessages[FreeMessages.Length-1];
		FreeMessages.Remove(FreeMessages.Length-1,1);
	}
	else
	{
		mrow = Messages[Messages.Length-1];
		Messages.Remove(Messages.Length-1,1);
	}

	mrow.TF.SetString(type, msg);
	mrow.Y = 0;
	DI.hasY = true;
	DI.Y = 0;
	mrow.MC.SetDisplayInfo(DI);
	mrow.MC.GotoAndPlay("show");
	for (j = 0; j < Messages.Length; j++)
	{
		Messages[j].Y += MessageHeight;
		DI.Y = Messages[j].Y;
		Messages[j].MC.SetDisplayInfo(DI);
	}
	Messages.InsertItem(0,mrow);
}

function UpdateGameHUD(UTPlayerReplicationInfo PRI)
{
	local UTPlayerReplicationInfo MaxPRI;
	local int i, j;

	MaxPri = none;
	i = -10000000;
	for (j = 0; j < GRI.PRIArray.length; j++)
	{
		if (GRI.PRIArray[j] != PRI && GRI.PRIArray[j].Score > i && (GRI.PRIArray[j].Score > 0 || GRI.PRIArray[j].Score > PRI.Score))
		{
			i = GRI.PRIArray[j].Score;
			MaxPRI = UTPlayerReplicationInfo(GRI.PRIArray[j]);
		}
	}
	if (MaxPri != LastEnemy)
	{
		EnemyNameTF.SetText(MaxPRI != none ? MaxPRI.PlayerName : "");
		LastEnemy = MaxPri;
	}
}

function TickHud(float DeltaTime)
{
	//local UTPawn UTP;
	//local UTVehicle UTV;
	//local UTWeaponPawn UWP;
	//local int TotalArmor;
	local GWWeap Weapon;
	local float PowerCharge, SpeedCharge, SkillCharge, GrowCharge, Energy, MinEnergy;
	local int i, percent, Skill, Speed, Power, Health, MaxHealth, FoodHP/*, Velocity*/;
	local bool UsingAbility, UsingController;
	local float WeapCD[3];
	local string NextCharName, PreviousCharName;
	local EFood FoodType;
	local EForm Form;
	local GFxObject NewObject;
	local UTPlayerReplicationInfo PRI;
	//local GFxObject.ASDisplayInfo DI;
	//local GFxObject.ASColorTransform Cxform;
	local PlayerController PC;
	
//GW vars
	local GWPawn P;

	PC = GetPC();
	P = GWPawn(PC.Pawn);

	GRI = UTGameReplicationInfo(PC.WorldInfo.GRI);
	PRI = UTPlayerReplicationInfo(PC.PlayerReplicationInfo);
	
	if (P != None)
	{
		UsingController = PC.PlayerInput.bUsingGamepad;
		//`log( "Using Controller"@UsingController);
		Weapon = GWWeap(P.Weapon);
		Skill = P.Skill;
		Speed = P.Speed;
		Power = P.Power;
		Health = P.Health;
		DownTEMP = Clamp(100-(Skill+Speed+Power),1,100);
		//Velocity = P.LastSpeed;
		MaxHealth = P.HealthMax;
		Form = P.Form;
		FoodType = P.CurrentEatenFoodType;
		if(Weapon != none) {
			for(i=0; i<2; i++)
			{
				WeapCD[i] = Weapon.GetCooldownPerc(i);
			}
			Energy = Weapon.GetPowerPerc();
			MinEnergy = 100*Weapon.ShotCost[1]/Weapon.MaxAmmoCount;
		}

		PowerCharge = P.PowerCharge;
		SpeedCharge = P.SpeedCharge;
		SkillCharge = P.SkillCharge;
		GrowCharge = P.GrowCharge;
		UsingAbility = PC.IsInState('PlayerAbility');
	}
	else
	{
		ClearStats();
		return;
	}

	if ( GRI != None )
	{
		// score & time
		if ( TimeTF != None )
		{
			TimeTF.SetString("text", FormatTime(GRI.TimeLimit != 0 ? GRI.RemainingTime : GRI.ElapsedTime));
		}

		if ( PRI != None )
		{
			UpdateGameHUD(PRI);
		}
	}

//------------------------------------------------------------GW Update------------------------------------------------------------
	if (UsingController != WasUsingController)
		{
			WasUsingController = UsingController;
			if (UsingController)
			{
				EatKeyTF.SetString("text", "LT");
				AttackKeyTF.SetString("text", "RT");
				PSControllerOverlayMC.SetVisible(true);
				CSControllerOverlayMC.SetVisible(true);
			}
			else
			{
				EatKeyTF.SetString("text", "LM");
				AttackKeyTF.SetString("text", "RM");
				PSControllerOverlayMC.SetVisible(false);
				CSControllerOverlayMC.SetVisible(false);
			}
		}
//CharacterStats
//-Character
	if(CurrentChar != Form)
	{		
		AttackShouldEnable = true;
		SpecialShouldEnable = true;
		ExtraShouldEnable = false;
		DownShouldEnable = true;
		MeatShouldEnable = true;
		CandyShouldEnable = true;
		FruitShouldEnable = true;
		if(P.GetCurrentStage() == 0)
		{
			LastHealth = 0;
			MaxFood = GWPlayerController(P.Controller).ReqStage1;
			PreviousCharName = ("none");
			CurrentChar = Form;
			CurrentCharName = P.CharacterName;
			FirstChar = CurrentChar;
			FirstCharName = CurrentCharName;
			NextCharName = CurrentCharName;
			MeatMC.GotoAndStopI(1);
			CandyMC.GotoAndStopI(1);
			FruitMC.GotoAndStopI(1);
			MeatGlowMC.GotoAndStopI(2);
			CandyGlowMC.GotoAndStopI(2);
			FruitGlowMC.GotoAndStopI(2);
			DownShouldEnable = false;
		}
		else if(P.GetCurrentStage() == 1)
		{
			LastHealth = 0;
			MaxFood = GWPlayerController(P.Controller).ReqStage2;
			PreviousCharName = FirstCharName;
			CurrentChar = Form;
			CurrentCharName = P.CharacterName;
			SecondCharName = CurrentCharName;
			NextCharName = CurrentCharName;
			MeatMC.GotoAndStopI(1);
			CandyMC.GotoAndStopI(1);
			FruitMC.GotoAndStopI(1);
			MeatGlowMC.GotoAndStopI(2);
			CandyGlowMC.GotoAndStopI(2);
			FruitGlowMC.GotoAndStopI(2);
		}
		else if(P.GetCurrentStage() == 2)
		{
			LastHealth = 0;
			MaxFood = 0;
			PreviousCharName = SecondCharName;
			CurrentChar = Form;
			CurrentCharName = P.CharacterName;
			NextCharName = ("full");
			MeatBarMC.GotoAndStopI(1);
			CandyBarMC.GotoAndStopI(1);
			FruitBarMC.GotoAndStopI(1);
			MeatMC.GotoAndStopI(1);
			CandyMC.GotoAndStopI(1);
			FruitMC.GotoAndStopI(1);
			MeatGlowMC.GotoAndStopI(2);
			CandyGlowMC.GotoAndStopI(2);
			FruitGlowMC.GotoAndStopI(2);
			MeatShouldEnable = false;
			CandyShouldEnable = false;
			FruitShouldEnable = false;
			switch (Form)
			{
				case FORM_SKILL_POWER:
					AttackShouldEnable = false;
			}
		}
		//InitCam(P,P.CharacterColour);
		MeatPicMC.GotoAndStop(NextCharName);
		CandyPicMC.GotoAndStop(NextCharName);
		FruitPicMC.GotoAndStop(NextCharName);
		DownPicMC.GotoAndStop(PreviousCharName);
		AttackPicMC.GotoAndStop(CurrentCharName);
		SpecialPicMC.GotoAndStop(CurrentCharName);
		ExtraPicMC.GotoAndStop("none");
		DownEnabled = MCToggle(DownContainerMC, DownEnabled, DownShouldEnable);
		SpecialEnabled = MCToggle(SpecialContainerMC, SpecialEnabled, SpecialShouldEnable);
		ExtraEnabled = MCToggle(ExtraContainerMC, ExtraEnabled, ExtraShouldEnable);
		AttackEnabled = MCToggle(AttackContainerMC, AttackEnabled, AttackShouldEnable);
		MeatEnabled = MCToggle(MeatContainerMC, MeatEnabled, MeatShouldEnable);
		CandyEnabled = MCToggle(CandyContainerMC, CandyEnabled, CandyShouldEnable);
		FruitEnabled = MCToggle(FruitContainerMC, FruitEnabled, FruitShouldEnable);
		KeyToggle(DownKeyMC, DownEnabled);
		KeyToggle(ExtraKeyMC, ExtraEnabled);
		KeyToggle(SpecialKeyMC, SpecialEnabled);
		KeyToggle(AttackKeyMC, AttackEnabled);
		KeyToggle(MeatKeyMC, MeatEnabled);
		KeyToggle(CandyKeyMC, CandyEnabled);
		KeyToggle(FruitKeyMC, FruitEnabled);
		LastDown = -1;
		LastEnergy = -10;
	}
//-Eat Notifier
	if (LastFoodType != FoodType)
	{
		if (FoodType != 0)
		{
			if (FoodType <= 3)
			{
				DownMC.GotoAndStopI(3);
				AttackMC.GotoAndStopI(3);		
			}
			else if (FoodType <= 6)
			{
				DownMC.GotoAndStopI(5);
				AttackMC.GotoAndStopI(5);
			}
			else if (FoodType <= 9)
			{
				DownMC.GotoAndStopI(4);
				AttackMC.GotoAndStopI(4);
			}
			EatNotifierMC.GotoAndPlay("onStart");
			SpitNotifierMC.GotoAndPlay("onStart");
			ExtraEnabled = MCToggle(ExtraContainerMC, ExtraEnabled, false);
			SpecialEnabled = MCToggle(SpecialContainerMC, SpecialEnabled, false);
			AttackEnabled = MCToggle(AttackContainerMC, AttackEnabled, true);
			DownEnabled = MCToggle(DownContainerMC, DownEnabled, true);
			if(Weapon != none) {
				MaxFoodHP = Weapon.EatenFoodHealth;
			} else {
				MaxFoodHP = 0;
			}
			DownFoodPicMC.GotoAndStopI(FoodType);
			AttackFoodPicMC.GotoAndStopI(FoodType);
		}
		else
		{
			EatNotifierMC.GotoAndPlay("offStart");
			SpitNotifierMC.GotoAndPlay("offStart");
			ExtraEnabled = MCToggle(ExtraContainerMC, ExtraEnabled, ExtraShouldEnable);
			SpecialEnabled = MCToggle(SpecialContainerMC, SpecialEnabled, SpecialShouldEnable);
			AttackEnabled = MCToggle(AttackContainerMC, AttackEnabled, AttackShouldEnable);
			DownEnabled = MCToggle(DownContainerMC, DownEnabled, DownShouldEnable);
			MaxFoodHP = 0;
		}
		KeyToggle(ExtraKeyMC, ExtraEnabled);
		KeyToggle(SpecialKeyMC, SpecialEnabled);
		KeyToggle(AttackKeyMC, AttackEnabled);
		KeyToggle(DownKeyMC, DownEnabled);
		LastWeapCD[0] = -1;
		LastDown = -1;
		LastFoodType = FoodType;
	}
	if (FoodType == 0)
	{
		LastFoodHP = 0;
		FoodHP = 0;
	}
	else
	{
		if(Weapon != none) {
			FoodHP = Weapon.EatenFoodHealth;
		} else {
			FoodHP = 0;
		}
	}
//-Up
	if (GrowCharge != LastGrowCharge)
	{
		if (PowerCharge >= 0)
		{
			percent = Clamp(FCeil(100 * PowerCharge),1,100);
			MeatRingMC.GotoAndStopI(percent);
		}
		if (SpeedCharge >= 0)
		{
			percent = Clamp(FCeil(100 * SpeedCharge),1,100);
			CandyRingMC.GotoAndStopI(percent);
		}
		if (SkillCharge >= 0)
		{
			percent = Clamp(FCeil(100 * SkillCharge),1,100);
			FruitRingMC.GotoAndStopI(percent);
		}
		LastGrowCharge = GrowCharge;
	}
//--Meat
	if (MaxFood > 0)
	{
		if (LastMeat != Power)
		{
			percent = Clamp(FCeil((100.0 * Power) / MaxFood),1,100);
			i = FCeil(Power - LastMeat);
			LastMeat = Power;
			
			if (percent >= 100)
			{
				MeatMC.GotoAndStopI(2);
				MeatGlowMC.GotoAndStopI(1);
			}
			else
			{
				MeatMC.GotoAndStopI(1);
				MeatGlowMC.GotoAndStopI(2);
			}
			if (i > 0)
			{
				NewObject = AddFoodMC.AttachMovie("GW_AddMeat_mc", "addmeat"$PC.WorldInfo.TimeSeconds);
				NewObject.GetObject("amount").GetObject("text").SetText("+"$i);
			}
			EatNotifierEatMC.GotoAndPlay("start");
			MeatBarMC.GotoAndStopI(percent);
		}
//--Candy
		if (LastCandy != Speed)
		{
			percent = Clamp(FCeil((100.0 * Speed) / MaxFood),1,100);
			i = FCeil(Speed - LastCandy);
			LastCandy = Speed;
			
			if (percent >= 100)
			{
				CandyMC.GotoAndStopI(2);
				CandyGlowMC.GotoAndStopI(1);
			}
			else
			{
				CandyMC.GotoAndStopI(1);
				CandyGlowMC.GotoAndStopI(2);
			}
			if (i > 0)
			{
				NewObject = AddFoodMC.AttachMovie("GW_AddCandy_mc", "addcandy"$PC.WorldInfo.TimeSeconds);
				NewObject.GetObject("amount").GetObject("text").SetText("+"$i);
			}
			EatNotifierEatMC.GotoAndPlay("start");
			CandyBarMC.GotoAndStopI(percent);
		}
//--Fruit
		if (LastFruit != Skill)
		{
			percent = Clamp(FCeil((100.0 * Skill) / MaxFood),1,100);
			i = FCeil(Skill - LastFruit);
			LastFruit = Skill;
			
			if (percent >= 100)
			{
				FruitMC.GotoAndStopI(2);
				FruitGlowMC.GotoAndStopI(1);
			}
			else
			{
				FruitMC.GotoAndStopI(1);
				FruitGlowMC.GotoAndStopI(2);
			}
			if (i > 0)
			{
				NewObject = AddFoodMC.AttachMovie("GW_AddFruit_mc", "addfruit"$PC.WorldInfo.TimeSeconds);
				NewObject.GetObject("amount").GetObject("text").SetText("+"$i);
			}
			EatNotifierEatMC.GotoAndPlay("start");
			FruitBarMC.GotoAndStopI(percent);
		}
	}
//-Down
	//if (DownTEMP < 100)
	//{
	//	DownTEMP ++;
	//}
	
	if (LastDown != DownTEMP)
	{
		if (FoodType == 0)
		{
			i = DownTEMP;
			
			DownBarMC.GotoAndStopI(i);
			if (i >= 100)
			{
				DownMC.GotoAndStopI(2);
			}
			else
			{
				DownMC.GotoAndStopI(1);
			}
			LastDown = DownTEMP;
		}
	}
//--Eat
	if (FoodHP != LastFoodHP)
	{
		percent = Clamp(FCeil((100.0 * FoodHP) / MaxFoodHP),1,100);
		
		DownBarMC.GotoAndStopI(percent);
		LastFoodHP = FoodHP;
	}

//PlayerStats
	if (AbilityActive != UsingAbility)
	{
		if (UsingAbility)
		{
			switch (Form) 
			{
				case FORM_POWER_MAX:
					break;
				case FORM_SKILL_POWER:
					SpecialPicMC.GotoAndStop("shell");
					AttackShouldEnable = true;
					AttackEnabled = MCToggle(AttackContainerMC, AttackEnabled, AttackShouldEnable);
					KeyToggle(AttackKeyMC, AttackEnabled);
					break;
				case FORM_SPEED_POWER:
					break;
			}
		}
		else
		{
			switch (Form) 
			{
				case FORM_POWER_MAX:
					break;
				case FORM_SKILL_POWER:
					SpecialPicMC.GotoAndStop(CurrentCharName);
					AttackShouldEnable = false;
					AttackEnabled = MCToggle(AttackContainerMC, AttackEnabled, AttackShouldEnable);
					KeyToggle(AttackKeyMC, AttackEnabled);
					break;
				case FORM_SPEED_POWER:
					break;
			}
		}
		AbilityActive = UsingAbility;
	}
//-Health
	//HealthTF.SetText(Velocity);
	if (LastHealth != Health) {
		HealthTF.SetText(Health);
		percent = Clamp(FCeil(500.0*Health/MaxHealth),1,500);
		if (percent < 1)
		{
			HealthMC.GotoAndStop("dead");
			HealthTF.SetString("text", "");
			percent = HealthTrans;
		}
		if (percent <= 100)
		{
			HealthMC.GotoAndStop("pulse");
			HealthRedMC.GotoAndStopI(percent);
		}
		else
		{
			HealthMC.GotoAndPlay("staticStart");
			HealthRedMC.GotoAndStopI(percent);
		}
		
		LastHealthPercent = percent;
		LastHealth = Health;
	}
	
	if (HealthTrans != LastHealthPercent)
	{
		if (HealthTrans > LastHealthPercent)
		{
			HealthTrans -= FCeil(HealthTransFactor);
			HealthTransFactor *= 1.4;
		}
		if (HealthTrans < LastHealthPercent)
		{
			HealthTrans = LastHealthPercent;
			HealthTransFactor = 1;
		}
		HealthWhiteMC.GotoAndStopI(HealthTrans);
	}	
//-Attack
	if (WeapCD[0] != LastWeapCD[0])
	{
		if (FoodType == 0)
		{
			percent = Clamp(FCeil(WeapCD[0]),1,100);
			
			if (percent >= 100)
			{
				AttackMC.GotoAndStopI(2);
			}
			else
			{
				AttackMC.GotoAndStopI(1);
			}
			AttackBarMC.GotoAndStopI(percent);
		}
		LastWeapCD[0] = WeapCD[0];
	}
//-Special
	if (Energy != LastEnergy)
	{
		percent = Clamp(FCeil(100*Energy),1,100);
		
		if (WeapCD[1] == 100)
		{
			if (percent == 100)
			{
				SpecialMC.GotoAndStopI(3);
			}
			else if(percent >= MinEnergy)
			{
				SpecialMC.GotoAndStopI(2);
			}
			else
			{
				SpecialMC.GotoAndStopI(1);
			}
		}
		else
		{
			SpecialMC.GotoAndStopI(1);
		}
		SpecialBarMC.GotoAndStopI(percent);
		LastEnergy = Energy;
	}
//-Extra
	/*if (WeapCD[3] != LastWeapCD[3])
	{
		if (FoodType == 0)
		{
			percent = Clamp(FCeil(WeapCD[2]),1,100);
			
			if (percent >= 100)
			{
				ExtraMC.GotoAndStopI(2);
			}
			else
			{
				ExtraMC.GotoAndStopI(1);
			}
			ExtraBarMC.GotoAndStopI(percent);
		}
		LastWeapCD[2] = WeapCD[2];
	}*/
	

//------------------------------------------------------------UDK Update------------------------------------------------------------
/*	TotalArmor = UTP.GetShieldStrength();
	if (TotalArmor != LastArmor)
	{
		if (TotalArmor > 0)
		{
			if (ArmorMC != none)
			{
				ArmorMC.SetVisible(true);
				ArmorMC.GotoAndStopI(TotalArmor >= 100 ? 100 : (1 + TotalArmor));
			}
			ArmorTF.SetText(TotalArmor);
			//ArmorPercTF.SetVisible(true);
		}
		else
		{
			if (ArmorMC != none)
			{
				ArmorMC.SetVisible(false);
			}
			ArmorTF.SetText("");
			//ArmorPercTF.SetVisible(false);
		}
		LastArmor = TotalArmor;
	}

	Weapon = UTWeapon(P.Weapon);
	if (Weapon != none && UTV == none)
	{
		if (Weapon != LastWeapon)
		{
			if (Weapon.AmmoDisplayType == EAWDS_None)
				AmmoCountTF.SetText("");
			i = (Weapon.MaxAmmoCount > 30 ? 30 : Weapon.MaxAmmoCount);
			MaxAmmoMC.GotoAndStopI(31 - i);
			WeaponMC.SetVisible(true);
			WeaponMC.GotoAndStopI(Weapon.InventoryGroup);
			LastWeapon = Weapon;
		}
		i = Weapon.GetAmmoCount();
		if (i != LastAmmoCount)
		{
			LastAmmoCount = i;
			AmmoCountTF.SetText(i);
			if (i > 30)
				i = 30;
			AmmoBarMC.GotoAndStopI(31 - i);
			AmmoBarMC.SetVisible(true);
		}
	}
	else if (Weapon != LastWeapon)
	{
		AmmoCountTF.SetText("");
		AmmoBarMC.SetVisible(false);
		WeaponMC.SetVisible(false);
	}

	if (UTV != none)
	{
		if (UTV.Health != LastVHealth)
		{
			VArmorTF.SetText(UTV.Health);
			DI.hasXScale = true;
			DI.XScale = (100.0 * float(UTV.Health)) / float(UTV.HealthMax);
			if (DI.XScale > 100)
				DI.XScale = 100;
			VArmorMC.SetDisplayInfo(DI);
			LastVHealth = UTV.Health;
		}
	}*/
}

function CrosshairFire()
{}

function CrosshairHit()
{}

function ToggleCrosshair(bool bToggle)
{
	bToggle = !bDrawWeaponCrosshairs && bToggle && !UTPlayerController(GetPC()).bNoCrosshair && UTHUDBase(GetPC().myHUD).bCrosshairShow;
	ReticuleMC.SetVisible(bToggle);
}

function MinimapZoomOut()
{
	if (CurZoomf < MaxZoomf)
		CurZoomf *= 2;
}

function MinimapZoomIn()
{
	if (CurZoomf > MinZoomf)
		CurZoomf *= 0.5;
}

function DisplayHit(vector HitDir, int Damage, class<DamageType> damageType)
{
	local Vector Loc;
	local Rotator Rot;
	local float DirOfHit;
	local vector AxisX, AxisY, AxisZ;
	local vector ShotDirection;
	local bool bIsInFront;
	local vector2D	AngularDist;

	if ( class<UTDamageType>(damagetype) != none && class<UTDamageType>(damageType).default.bLocationalHit )
	{
		// Figure out the directional based on the victims current view
		GetPC().GetPlayerViewPoint(Loc, Rot);
		GetAxes(Rot, AxisX, AxisY, AxisZ);

		ShotDirection = Normal(HitDir - Loc);
		bIsInFront = GetAngularDistance( AngularDist, ShotDirection, AxisX, AxisY, AxisZ);
		GetAngularDegreesFromRadians(AngularDist);
		DirOfHit = AngularDist.X;

		if( bIsInFront )
		{
			DirOfHit = AngularDist.X;
			if (DirOfHit < 0)
			DirOfHit += 360;
		}
		else
			DirOfHit = 180 + AngularDist.X;
	}
	else
		DirOfHit = 180;

	HitLocMC[int(DirOfHit/45.f)].GotoAndPlay("on");
}

function ShowMultiKill(int n, string msg)
{
	if (MultiKillN_TF == none)
	{
		MultiKillN_TF = GetVariableObject("_root.popup.popupNumber.textField");
		MultiKillMsg_TF = GetVariableObject("_root.popup.popupText.textField");
	}

	MultiKillN_TF.SetText(n+1);
	MultiKillMsg_TF.SetText(msg);
	MultiKillMC.GotoAndPlay("on");
}

function SetCenterText(string text)
{
	CenterTextTF.SetText(text);
	CenterTextMC.GotoAndPlay("on");
}

function string GetRank(PlayerReplicationInfo PRI)
{
	local int i;
	local int j;

	i = -10000000;
	for (j = 0; j < GRI.PRIArray.length; j++)
	{
		if (GRI.PRIArray[j].Score > i)
		{
			i = GRI.PRIArray[j].Score;
		}
	}
	if (PRI.Score >= i && PRI.Score > 0)
		return "<img src='rank15'>";
	return "";
}

function AddDeathMessage(PlayerReplicationInfo Killer, PlayerReplicationInfo Killed, class<UTDamageType> Dmg)
{
	local string msg;
//	local byte index;

	if (Killer != none) {
		msg = Killer.PlayerName @ "Killed" @ Killed.PlayerName;
	} else {
		msg = Killed.PlayerName @ "Suicided";
	}
	AddMessage("htmlText", msg);
}

defaultproperties
{
	VersionNo = "GWGFXHud v 0.29"
	
	bDisplayWithHudOff=FALSE
	MinZoomf=16
	MaxZoomf=128
	MessageHeight=20
	MovieInfo=SwfMovie'Grow_HUD.gw_hud'
	bEnableGammaCorrection=false
	bDrawWeaponCrosshairs=false
	
	bAllowInput=FALSE;
	bAllowFocus=FALSE;
	//`log(VersionNo$"----------------------------ExtraEnabled:"@ExtraEnabled);
}
