/**
 * GFxGrowFrontEnd
 * Scaleform Interface for Main Menu
 */
class OldGFxGrowFrontEnd extends GFxMoviePlayer
	dependson(GWConstants)
	config(UI);

var GFxClikWidget HostButton, JoinButton, SoloButton, SettingsButton, ExitButton;
var GFxClikWidget HostStartButton, HostMapOption, HostModeOPtion;
var GFxClikWidget JoinBrowserButton, JoinIpButton, JoinIpField, JoinOfficialButton;
var GFxClikWidget SettingsResolutionOption, SettingsWindowOption, SettingsQualityOption, SettingsApplyButton;
var GFxObject     Root, Options;
var byte HatIndex[EForm];

function bool Start(optional bool StartPaused = false)
{
	super.Start();
	Advance(0);
	
	Root = GetVariableObject("_root");
	Options = GetVariableObject("_root.options");
	//JoinButton = GetVariableObject("_root.Join_btn");
	//IpField = GetVariableObject("_root.IpField_mc.IpField_txt");
	//SettingsButton = GetVariableObject("_root.Settings_btn");
	//SoloButton = GetVariableObject("_root.Solo_btn");
	
	return true;
}

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget)
{
	switch(WidgetName)
	{
		//Main
		case ('Host_btn'):
			HostButton = GFxClikWidget(Widget);
			HostButton.AddEventListener('CLIK_press', OnHostButtonPress);
			break;
		case ('Join_btn'):
			JoinButton = GFxClikWidget(Widget);
			JoinButton.AddEventListener('CLIK_press', OnJoinButtonPress);
			break;
		case ('Solo_btn'):
			SoloButton = GFxClikWidget(Widget);
			SoloButton.AddEventListener('CLIK_press', OnSoloButtonPress);
			break;
		case ('Settings_btn'):
			SettingsButton = GFxClikWidget(Widget);
			SettingsButton.AddEventListener('CLIK_press', OnSettingsButtonPress);
			break;
		case ('Exit_btn'):
			ExitButton = GFxClikWidget(Widget);
			ExitButton.AddEventListener('CLIK_press', OnExitButtonPress);
			break;
		//Host
		case ('HostStart_btn'):
			HostStartButton = GFxClikWidget(Widget);
			HostStartButton.AddEventListener('CLIK_press', OnHostStartButtonPress);
			break;
		case ('HostMode_opt'):
			HostModeOption = GFxClikWidget(Widget);
			break;
		case ('HostMap_opt'):
			HostMapOption = GFxClikWidget(Widget);
			break;
		//Join
		case ('JoinBrowser_btn'):
			JoinBrowserButton = GFxClikWidget(Widget);
			break;
		case ('JoinIp_btn'):
			JoinIpButton = GFxClikWidget(Widget);
			JoinIpButton.AddEventListener('CLIK_press', OnJoinIpButtonPress);
			break;
		case ('JoinIp_fld'):
			JoinIpField = GFxClikWidget(Widget);
			break;
		case ('JoinOfficial_btn'):
			JoinOfficialButton = GFxClikWidget(Widget);
			JoinOfficialButton.AddEventListener('CLIK_press', OnJoinOfficialButtonPress);
			break;
		//Settings
		case ('SettingsResolution_opt'):
			SettingsResolutionOption = GFxClikWidget(Widget);
			break;
		case ('SettingsWindow_opt'):
			SettingsWindowOption = GFxClikWidget(Widget);
			break;
		case ('SettingsQuality_opt'):
			SettingsQualityOption = GFxClikWidget(Widget);
			break;
		case ('SettingsApply_btn'):
			SettingsApplyButton = GFxClikWidget(Widget);
			SettingsApplyButton.AddEventListener('CLIK_press', OnSettingsApplyButtonPress);
			break;
		default:
			break;
	}
	return true;
}

//Called from Scaleform
/*function JoinFunction(string ip) 
{
	ConsoleCommand("open "$ip);
}

function OnHostButtonPress(GFxClikWidget.EventData ev)
{
	ConsoleCommand("open GW-Precipice?Listen?MaxPlayers=16?MinNetPlayers=0?bShouldAdvertise=True?bIsLanMatch=True?bUsesStats=True?bAllowJoinInProgress=True?bAllowInvites=True?bUsesPresence=True?bAllowJoinViaPresence=True?bAllowJoinViaPresenceFriendsOnly=False?bUsesArbitration=False?bAntiCheatProtected=False?bIsDedicated=True?PingInMs=0?MatchQuality=0.000000?GameState=OGS_NoSession?GameMode=4?Difficulty=2?PureServer=1?LockedServer=0?Campaign=0?ForceRespawn=1?CustomMapName=GW-Volcano?CustomGameMode=Grow.GWCTFGame?GoalScore=100?TimeLimit=60?ServerDescription=?NumPlay=1?game=Grow.GWCTFGame");
}

function OnMapButtonPress(GFxClikWidget.EventData ev)
{
	`log("Log 4");
	ConsoleCommand("open DM-Deck");
}*/

function ToggleDisabled (GFxClikWidget Btn)
{
	ActionScriptVoid("ToggleDisabled");
}

//Main
function OnHostButtonPress(GFxClikWidget.EventData ev)
{
	ToggleDisabled(HostButton);
	Root.GotoAndPlay("Host_start");
}

function OnJoinButtonPress(GFxClikWidget.EventData ev)
{
	ToggleDisabled(JoinButton);
	Root.GotoAndPlay("Join_start");
}

function OnSoloButtonPress(GFxClikWidget.EventData ev)
{
	ToggleDisabled(SoloButton);
	Root.GotoAndPlay("Solo_start");
}

function OnSettingsButtonPress(GFxClikWidget.EventData ev)
{
	ToggleDisabled(SettingsButton);
	Root.GotoAndPlay("Settings_start");
}

function OnExitButtonPress(GFxClikWidget.EventData ev)
{
	ConsoleCommand("EXIT");
}

//Host
function OnHostStartButtonPress(GFxClikWidget.EventData ev)
{
    //local int selectedMode;
	local int selectedMap;
	//local string hostingMode;
	local string hostingMap;
	
	//Options.SetFloat("selectedMode", HostModeOption.GetFloat("selectedIndex"));
	Options.SetFloat("selectedMap", HostMapOption.GetFloat("selectedIndex"));
	
	selectedMap = Options.GetFloat("selectedMap");
//	selectedMode = Options.GetFloat("selectedMode");
	
	/*switch (selectedMode)
	{
		case(0):
			hostingMode = "None";
			break;
		case(1): 
			hostingMode = "Grow.GWCTFGame";
			break;
		case(2): 
			hostingMode = "Grow.GWDeathmatch";
			break;
		default:
			break;
	}*/
	
	switch (selectedMap)
	{
		case(0):
			hostingMap = "None";
			break;
		case(1): 
			//hostingMap = "GWDM-SkyArena";
			hostingMap = "GW-TestLevel";
			break;
		case(2): 
			hostingMap = "GW-Precipice";
			break;
		default:
			break;
	}
	
	ConsoleCommand("open "$hostingMap$"?Listen?MaxPlayers=32?MinNetPlayers=0?bShouldAdvertise=True?bIsLanMatch=True?bUsesStats=True?bAllowJoinInProgress=True?bAllowInvites=True?bUsesPresence=True?bAllowJoinViaPresence=True?bAllowJoinViaPresenceFriendsOnly=False?bUsesArbitration=False?bAntiCheatProtected=False?bIsDedicated=True?PingInMs=0?MatchQuality=0.000000?GameState=OGS_NoSession?GameMode=4?Difficulty=2?PureServer=1?LockedServer=0?Campaign=0?ForceRespawn=1?GoalScore=10000?TimeLimit=600?ServerDescription=?NumPlay=1?HatIndex1="$HatIndex[1]$"?HatIndex2="$HatIndex[2]$"?HatIndex3="$HatIndex[3]$"?HatIndex4="$HatIndex[4]$"?HatIndex5="$HatIndex[5]$"?HatIndex6="$HatIndex[6]$"?HatIndex7="$HatIndex[7]$"?HatIndex8="$HatIndex[8]$"?HatIndex9="$HatIndex[9]$"?HatIndex10="$HatIndex[10]);
	//ConsoleCommand("open GW-Precipice?Listen?MaxPlayers=16?MinNetPlayers=0?bShouldAdvertise=True?bIsLanMatch=True?bUsesStats=True?bAllowJoinInProgress=True?bAllowInvites=True?bUsesPresence=True?bAllowJoinViaPresence=True?bAllowJoinViaPresenceFriendsOnly=False?bUsesArbitration=False?bAntiCheatProtected=False?bIsDedicated=True?PingInMs=0?MatchQuality=0.000000?GameState=OGS_NoSession?GameMode=4?Difficulty=2?PureServer=1?LockedServer=0?Campaign=0?ForceRespawn=1?CustomMapName=GW-Volcano?CustomGameMode=Grow.GWCTFGame?GoalScore=100?TimeLimit=60?ServerDescription=?NumPlay=1?game=Grow.GWCTFGame");
	//ConsoleCommand("open DM-Deck");
}

//Join
function OnJoinIpButtonPress(GFxClikWidget.EventData ev)
{
    local string ip;

    ip = JoinIpField.GetString("text");
	
	JoinServer(ip);
}
function JoinServer(string ip) {
	ConsoleCommand("open "$ip$"?HatIndex1="$HatIndex[1]$"?HatIndex2="$HatIndex[2]$
		"?HatIndex3="$HatIndex[3]$"?HatIndex4="$HatIndex[4]$"?HatIndex5="$HatIndex[5]$
		"?HatIndex6="$HatIndex[6]$"?HatIndex7="$HatIndex[7]$"?HatIndex8="$HatIndex[8]$
		"?HatIndex9="$HatIndex[9]$"?HatIndex10="$HatIndex[10]);
}

function OnJoinOfficialButtonPress(GFxClikWidget.EventData ev)
{
    JoinServer("server.studiogrow.org");
}
//Solo

//Settings
function OnSettingsApplyButtonPress(GFxClikWidget.EventData ev)
{
    local int selectedRes;
	local int selectedWindow;
	local int selectedQuality;
	local string settingsWindow;
    // This is where you set the current resolution stored in _root.options.selectedResolution
    Options.SetFloat("selectedResolution", SettingsResolutionOption.GetFloat("selectedIndex"));
	Options.SetFloat("selectedWindow", SettingsWindowOption.GetFloat("selectedIndex"));
	Options.SetFloat("selectedQuality", SettingsQualityOption.GetFloat("selectedIndex"));

    selectedRes = Options.GetFloat("selectedResolution");
	selectedWindow = Options.GetFloat("selectedWindow");
	selectedQuality = Options.GetFloat("selectedQuality");
	
	switch (selectedWindow)	{
		case 0:
			settingsWindow = "w";
			//ConsoleCommand("scale set fullscreen false");
			break;
		case 1: 
			settingsWindow = "f";
			//ConsoleCommand("scale set fullscreen true");
			break;
	}

    switch (selectedRes) {
		case 0:
			ConsoleCommand("setres 800x600"$settingsWindow);
			break;
		case 1: 
			ConsoleCommand("setres 1024x768"$settingsWindow);
			break;
		case 2: 
			ConsoleCommand("setres 1280x720"$settingsWindow);
			break;
		case 3: 
			ConsoleCommand("setres 1920x1080"$settingsWindow);
			break;
	}
	
	switch (selectedQuality) {
		case 0:
			ConsoleCommand("scale lowend");
			break;
		case 1: 
			ConsoleCommand("scale bucket bucket3");
			break;
		case 2: 
			ConsoleCommand("scale highend");
			break;
	}
}

/*function OnJoinButtonPress(GFxClikWidget.EventData ev)
{
	local string ip;
	
	ip = IpField.GetText();
	if (ip == "Official Server")
	{
		ConsoleCommand("open server.studiogrow.org");
	}
	else
	{
		ConsoleCommand("open "$ip);
	}
}*/

defaultproperties 
{
	//Main
	WidgetBindings.Add((WidgetName="Host_btn",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="Join_btn",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="Solo_btn",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="Settings_btn",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="Exit_btn",WidgetClass=class'GFxClikWidget'))
	//Host
	WidgetBindings.Add((WidgetName="HostStart_btn",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="HostMode_opt",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="HostMap_opt",WidgetClass=class'GFxClikWidget'))
	//Join
	WidgetBindings.Add((WidgetName="JoinBrowser_btn",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="JoinIp_btn",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="JoinIp_fld",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="JoinOfficial_btn",WidgetClass=class'GFxClikWidget'))
	//Settings
	WidgetBindings.Add((WidgetName="SettingsResolution_opt",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="SettingsWindow_opt",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="SettingsQuality_opt",WidgetClass=class'GFxClikWidget'))
	WidgetBindings.Add((WidgetName="SettingsApply_btn",WidgetClass=class'GFxClikWidget'))

	HatIndex[0]=255
	HatIndex[1]=255
	HatIndex[2]=255
	HatIndex[3]=255
	HatIndex[4]=255
	HatIndex[5]=255
	HatIndex[6]=255
	HatIndex[7]=255
	HatIndex[8]=255
	HatIndex[9]=255
	HatIndex[10]=255
}