class GFxGrowMenu extends GFxMoviePlayer;

/** Reference to _root of the movie's (udk_manager.swf) stage. */
var GFxObject RootMC;

/** Reference to the manager MovieClip (_root.manager) where views will be attached. */
var GFxObject ManagerMC;

var bool bInitialized;

/** View declarations. */
var GFxGrowMenu_Community CommunityView;
var GFxGrowMenu_CreateGame CreateGameView;
var GFxGrowMenu_Customise CustomiseView;
var GFxGrowMenu_GameMode GameModeView;
var GFxGrowMenu_JoinGame JoinGameView;
var GFxGrowMenu_MainMenu MainMenuView;
var GFxGrowMenu_MapSelect MapSelectView;
var GFxGrowMenu_Mutators MutatorsView;
var GFxGrowMenu_Options OptionsView;
var GFxGrowMenu_Play PlayView;
var GFxGrowMenu_ServerSettings ServerSettingsView;
var GFxGrowMenu_Settings SettingsView;
var GFxGrowMenu_Stats StatsView;

var GFxGrowMenu_Dialog InfoDialog;

//var GFxUDKFrontEnd_FilterDialog FilterDialog;

var GFxGrowMenu_JoinDialog JoinDialog;

var GFxGrowMenu_ErrorDialog ErrorDialog;

var GFxGrowMenu_PasswordDialog PasswordDialog;

/** Structure which defines a unique menu view to be loaded. */
struct ViewInfo
{
	/** Unique string. */
	var name ViewName;

	/** SWF content to be loaded. */
	var string SWFName;
};

/** Array of all menu views to be loaded, defined in DefaultUI.ini. */
var array<ViewInfo>			ViewData;

/** 
 *  Shadow of the AS view stack. Necessary to update ( View.OnTopMostView(false) ) views that
 *  alreday exist on the stack. 
 */
var array<GFxGrowMenu_View>		ViewStack;

/**
 * An array of names of views which have been attachMovie()'d and loadMovie()'d. Views
 * are loaded based on their DependantViews array, defined in Default.ini.
 */
var array<name>						LoadedViews;

function bool Start(optional bool StartPaused = false)
{
	super.Start();
	Advance(0);

	if (!bInitialized)
	{
		ConfigFrontEnd();
	}

	// @todo sf: Stops the game running the background from ending. We should set the Kismet level up
	// properly rather than use pause instead.
	//ConsoleCommand("pause");
	//ASShowCursor(false);
	LoadViews();
	return TRUE;
}

/** 
 *  Configuration method which stores references to _root and
 *  _root.manager for use in attaching views.
 */
final function ConfigFrontEnd()
{ 
	RootMC = GetVariableObject("root");
	ManagerMC = RootMC.GetObject("manager");

	bInitialized = TRUE;
}

/** 
 *  Creates MovieClips in ManagerMC into which the views are loaded. These MovieClips
 *  are then stored in MenuViews for later manipulation.
 */
final function LoadViews()
{
	local byte i;
	for (i = 0; i < ViewData.Length; i++) 
	{
		LoadView( ViewData[i] );
	}
}

/** 
 *  Create a view using existing ViewInfo. 
 *
 *  @param InViewInfo, the data for the view which includes the SWFName and the name for the view.
 */
final function LoadView(ViewInfo InViewInfo)
{
	local ASValue asval1, asval2;
	local array<ASValue> args;

	//ViewContainer = ManagerMC.CreateEmptyMovieClip( String(InViewInfo.ViewName) $ "Container" );
	//ViewLoader = ViewContainer.CreateEmptyMovieClip( String(InViewInfo.ViewName) );

	asval1.Type = AS_String;
	asval1.s = String(InViewInfo.ViewName);
	asval2.Type = AS_String;
	asval2.s = InViewInfo.SWFName;
	args[0] = asval1;
	args[1] = asval2;
	RootMC.Invoke( "loadView", args );
	LoadedViews.AddItem( InViewInfo.ViewName );
}

/** 
 *  Loads a view using the view name. Used for loading views based on the current screen.
 *  Views that should be loaded for each screen are defined in DefaultUI.ini.
 *
 *  @param InViewName		The name of the view to be loaded.
 */
final function LoadViewByName( name InViewName )
{
	local byte i;
	for( i = 0; i < ViewData.Length; i++ )
	{
		// Find the view data by the view name and check that it is not already loaded.
		if ( ViewData[i].ViewName == InViewName && !IsViewLoaded(InViewName) )
		{
			// Load the view.
			LoadView( ViewData[i] );             
		}
	}
}

/**  
 *  Checks whether a view has already been loaded using the view name. 
 *
 *  @param InViewName		The name of the view to check.
 */
final function bool IsViewLoaded( name InViewName )
{
	local byte i;
	for( i = 0; i < ViewData.Length; i++ )
	{
		// Check if the view has already been loaded using the view name.
		if ( LoadedViews[i] == InViewName )
		{
			return TRUE;
		}
	}
	return FALSE;
}

/** 
 * Used by views to set the function triggered by "escape" input. 
 *
 * @param InDelegate	The EscapeDelegate that should be called on Escape/Cancel key press.
 */
/*final function SetEscapeDelegate( delegate<EscapeDelegate> InDelegate )
{
	local GFxObject _global;
	_global = GetVariableObject("_global");        
	ActionScriptSetFunction(_global, "OnEscapeKeyPress");
}*/

/** 
 *  Pushes a view onto MenuManager.as's view stack by name.
 *  This is the primarily method by which views on the stack notify the
 *  GFxUDKFrontEnd that the state of the stack needs to be updated.
 */ 
final function PushViewByName(name TargetViewName, optional GFxGrowMenu_Screen ParentView)
{
	`log( "GFxGrowMenu::PushViewByName(" @ string(TargetViewName) @ ")",,'DevUI');    
	switch (TargetViewName)
	{
		case ( 'Community' ): 
			ConfigureTargetView( CommunityView ); 
			break;
		case ( 'CreateGame' ):
			ConfigureTargetView( CreateGameView );
			break;
		case ( 'Customise' ):      
			ConfigureTargetView( CustomiseView ); 
			break;  
		case ( 'GameMode' ):     
			ConfigureTargetView( GameModeView ); 
			break;  
		case ( 'JoinGame' ):
			ConfigureTargetView( JoinGameView );
			break;
		case ( 'MainMenu' ):
			ConfigureTargetView( MainMenuView );
			break;
		case ( 'MapSelect' ): 
			ConfigureTargetView( MapSelectView ); 
			break;
		case ( 'Mutators' ):
			ConfigureTargetView( MutatorsView );
			break;
		case ( 'Options' ):      
			ConfigureTargetView( OptionsView ); 
			break;  
		case ( 'Play' ):     
			ConfigureTargetView( PlayView ); 
			break;  
		case ( 'ServerSettings' ):
			ConfigureTargetView( ServerSettingsView );
			break;
		case ( 'Settings' ):
			ConfigureTargetView( SettingsView );
			break;
		case ( 'Stats' ):
			ConfigureTargetView( StatsView );
			break;
		default:
			`log( "View ["$TargetViewName$"] not found." ,,'DevUI');  
			break;
	}
}

/** 
 *  Configures a dialog and pushes it on to the view stack. 
 *  Returns a reference to the dialog which can be manipulated to the view which spawned it.
 */
function GFxGrowMenu_Dialog SpawnDialog(name TargetDialogName, optional GFxGrowMenu_Screen ParentView)
{
	`log( "GFxGrowMenu::SpawnDialog(" @ string(TargetDialogName) @ ")" ,,'DevUI');    
	switch ( TargetDialogName )
	{
		case ( 'InfoDialog' ):
			ConfigureTargetDialog( InfoDialog ); 
			return InfoDialog;
		case ( 'JoinDialog' ):
			ConfigureTargetDialog( JoinDialog );
			return JoinDialog;
		case ( 'ErrorDialog' ):
			ConfigureTargetDialog( ErrorDialog );
			return ErrorDialog;
		case ( 'PasswordDialog' ):
			ConfigureTargetDialog( PasswordDialog );
			return PasswordDialog;
		default:
			`log( "Dialog ["$TargetDialogName$"] not found." ,,'DevUI');  
			return none;
	}
}

/**
 * Activates, updates, and pushes a dialog on the stack.
 * This method is called when a dialog is created by name using SpawnDialog().
 */
function ConfigureTargetDialog(coerce GFxGrowMenu_View TargetDialog)
{
	if (TargetDialog != none)
	{
		if (ViewStack.Length > 0)
		{
			ViewStack[ViewStack.Length - 1].DisableSubComponents(true);
		}

		TargetDialog.OnViewActivated();
		TargetDialog.OnTopMostView( true ); 

		ViewStack.AddItem( TargetDialog );
		PushDialogView( TargetDialog );
	}
	else 
	{
		`log( "GFxGrowMenu::ConfigureTargetDialog: TargetDialog is none. Unable to push view." ,,'DevUI');
	}
}

/** 
 * Activates, updates, and pushes a view on the stack if it is allowed.
 * This method is called when a view is created by name using PushViewByName().
 */
function ConfigureTargetView(GFxGrowMenu_View TargetView)
{
	`log( "GFxGrowMenu::"$GetFuncName()$"(" @ string(TargetView) @ ")" ,,'DevUI'); 
	if( IsViewAllowed( TargetView ) )
	{
		// LoadDependantViews( TargetView.ViewName );
		// Disable the current top most view's controls to prevent focus from escaping during the transition.
		if (ViewStack.Length > 0)
		{
			ViewStack[ViewStack.Length - 1].DisableSubComponents(true);
		}
		
		TargetView.OnViewActivated();
		TargetView.OnTopMostView( true );

		ViewStack.AddItem( TargetView );
		PushView( TargetView );      
	}    
}

/** Check whether target view is appropriate to add to the view stack. */
function bool IsViewAllowed(GFxGrowMenu_View TargetView)
{
	local byte i;	
	local name TargetViewName;

	// Check to see that we weren't passed a null view.
	if ( TargetView == none )
	{
		`log( "GFxGrowMenu:: TargetView is null. Unable to push view onto stack." ,,'DevUI');         
		return false;
	}

	// Check to see if the view is already loaded on the view stack using the view name. 
	TargetViewName = TargetView.ViewName;
	for ( i = 0; i < ViewStack.Length; i++ )
	{
		if (ViewStack[i].ViewName == TargetViewName)
		{
			`log( "GFxGrowMenu:: TargetView is already on the stack." ,,'DevUI');             
			return false;
		}
	}

	return true;
}

/** Pushes a view onto MenuManager.as view stack. */
function PushView(coerce GFxGrowMenu_View targetView) 
{     
	RootMC.ActionScriptVoid("pushStandardView"); 
}

/** AS stub for pushing a view onto the stack. */
function PushDialogView(coerce GFxGrowMenu_View dialogView) 
{
	RootMC.ActionScriptVoid("pushDialogView");
}

/** Gives focus to a particular GFxObject. */
function SetSelectionFocus(coerce GFxObject MovieClip)
{    
	if (MovieClip != none)
	{
		ASSetSelectionFocus(MovieClip);       
	}
}

/** AS stub for access to Selection.setFocus() via SetSelectionFocus(). */
function ASSetSelectionFocus(GFxObject MovieClip)
{
	RootMC.ActionScriptVoid("setSelectionFocus");    
}

/** Pops a view from the view stack and handles update/close of existing views. */
function GFxObject PopView() 
{       
	if ( ViewStack.Length <= 1 ) 
	{
		return none;
	}

	// Call OnViewClosed() for the popped view. 
	// Generally, this will disable the view's list to prevent accidental mouse rollOvers that cause
	// focus to change undesirably as the view is tweened out.
	ViewStack[ViewStack.Length-1].OnViewClosed();

	// DestroyDependantViews( ViewStack[ViewStack.Length - 1].ViewName );

	// Remove the view from the stack in US so we know what's still on top.   
	ViewStack.Remove(ViewStack.Length-1, 1);     

	// Update the new top most view.    
	ViewStack[ViewStack.Length-1].OnTopMostView( false ); 

	return PopViewStub();
}

/** Pops a view from the MenuManager.as view stack. */
final function GFxObject PopViewStub() { return ActionScriptObject("popView"); }

final function ConfigureView(GFxGrowMenu_View InView, name WidgetName, name WidgetPath)
{	
	SetWidgetPathBinding(InView, WidgetPath);
	InView.MenuManager = self;
	InView.ViewName = WidgetName;
	InView.OnViewLoaded();
}

final function ASShowCursor(bool bShowCursor)
{
	RootMC.ActionScriptVoid("showCursor");
}

/** Callback when at least one CLIK widget with enableInitCallback set to TRUE has been initialized in a frame */
function PostWidgetInit()
{
	//
}

/** @return Checks to see if the platform is currently connected to a network. */
function bool CheckLinkConnectionAndError( optional string AlternateTitle, optional string AlternateMessage )
{
   // local GFxGrowMenu_ErrorDialog Dialog;
	local bool bResult;

	if( class'GFxGrowView'.static.HasLinkConnection() )
	{
		bResult = true;
	}
	else
	{
		if ( AlternateTitle == "" )
		{
			AlternateTitle = "<Strings:UTGameUI.Errors.Error_Title>";
		}
		if ( AlternateMessage == "" )
		{
			AlternateMessage = "<Strings:UTGameUI.Errors.LinkDisconnected_Message>";
		}

	  //  Dialog = GFxGrowMenu_ErrorDialog(SpawnDialog('ErrorDialog'));
//	    Dialog.SetTitle(AlternateTitle);
//	    Dialog.SetInfo(AlternateMessage);
		bResult = false;
	}

	return bResult;
}

/** 
 *  Callback when a CLIK widget with enableInitCallback set to TRUE is initialized.  
 *  Returns TRUE if the widget was handled, FALSE if not. 
 */
event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget)
{    
	local bool bResult;
	bResult = false;

	`log( "GFxGrowMenu::WidgetInit: " @ WidgetName @ " : " @ WidgetPath @ " : " @ Widget);   
	switch(WidgetName) {
		case ( 'Community' ): 
			if (CommunityView == none)
			{
				CommunityView = GFxGrowMenu_Community(Widget);
				ConfigureView(CommunityView, WidgetName, WidgetPath);

				bResult = true;
			} 
			break;
		case ( 'CreateGame' ):
			if (CreateGameView == none)
			{
				CreateGameView = GFxGrowMenu_CreateGame(Widget);
				ConfigureView(CreateGameView, WidgetName, WidgetPath);

				bResult = true;
			}
			break;
		case ( 'Customise' ):      
			if (CustomiseView == none)
			{
				CustomiseView = GFxGrowMenu_Customise(Widget);
				ConfigureView(CustomiseView, WidgetName, WidgetPath);

				bResult = true;
			} 
			break;  
		case ( 'GameMode' ):     
			if (GameModeView == none)
			{
				GameModeView = GFxGrowMenu_GameMode(Widget);
				ConfigureView(GameModeView, WidgetName, WidgetPath);

				bResult = true;
			}
			break;  
		case ( 'JoinGame' ):
			if (JoinGameView == none)
			{
				JoinGameView = GFxGrowMenu_JoinGame(Widget);
				ConfigureView(JoinGameView, WidgetName, WidgetPath);

				bResult = true;
			}
			break;
		case ( 'MainMenu' ):
			if (MainMenuView == none)
			{
				MainMenuView = GFxGrowMenu_MainMenu(Widget);
				ConfigureView(MainMenuView, WidgetName, WidgetPath);

				// Currently here because need to ensure MainMenuView has loaded.
				ConfigureTargetView(MainMenuView);                 
				bResult = true;
			} 
			break;
		case ( 'MapSelect' ): 
			if (MapSelectView == none)
			{
				MapSelectView = GFxGrowMenu_MapSelect(Widget);
				ConfigureView(MapSelectView, WidgetName, WidgetPath);

				bResult = true;
			}
			break;
		case ( 'Mutators' ):
			if (MutatorsView == none)
			{
				MutatorsView = GFxGrowMenu_Mutators(Widget);
				ConfigureView(MutatorsView, WidgetName, WidgetPath);

				bResult = true;
			}
			break;
		case ( 'Options' ):      
			if (OptionsView == none)
			{
				OptionsView = GFxGrowMenu_Options(Widget);
				ConfigureView(OptionsView, WidgetName, WidgetPath);

				bResult = true;
			}
			break;  
		case ( 'Play' ):     
			if (PlayView == none)
			{
				PlayView = GFxGrowMenu_Play(Widget);
				ConfigureView(PlayView, WidgetName, WidgetPath);

				bResult = true;
			} 
			break;  
		case ( 'ServerSettings' ):
			if (ServerSettingsView == none)
			{
				ServerSettingsView = GFxGrowMenu_ServerSettings(Widget);
				ConfigureView(ServerSettingsView, WidgetName, WidgetPath);

				bResult = true;
			}
			break;
		case ( 'Settings' ):
			if (SettingsView == none)
			{
				SettingsView = GFxGrowMenu_Settings(Widget);
				ConfigureView(SettingsView, WidgetName, WidgetPath);

				bResult = true;
			}
			break;
		case ( 'Stats' ):
			if (StatsView == none)
			{
				StatsView = GFxGrowMenu_Stats(Widget);
				ConfigureView(StatsView, WidgetName, WidgetPath);

				bResult = true;
			}
			break;
		case ('InfoDialog'):
			if (InfoDialog == none)
			{
				InfoDialog = GFxGrowMenu_InfoDialog(Widget);
				ConfigureView(InfoDialog, WidgetName, WidgetPath); 
				bResult = true;
			}
			break;
		case ('JoinDialog'):
			if (JoinDialog == none)
			{
				JoinDialog = GFxGrowMenu_JoinDialog(Widget);
				ConfigureView(JoinDialog, WidgetName, WidgetPath); 
				bResult = true;
			}
			break;
		case ('PasswordDialog'):
			if (PasswordDialog == none)
			{                				
				PasswordDialog = GFxGrowMenu_PasswordDialog(Widget);
				ConfigureView(PasswordDialog, WidgetName, WidgetPath); 
				bResult = true;
			}
			break;
		case ('ErrorDialog'):
			if (ErrorDialog == none)
			{
				ErrorDialog = GFxGrowMenu_ErrorDialog(Widget);
				ConfigureView(ErrorDialog, WidgetName, WidgetPath); 

				// Hack to ensure that focus is set to the main menu even after all the other views have been loaded above.
				//SetSelectionFocus(MainMenuView.ListMC);
				bResult = true;
			}
			break;
		default:
			break;
	}

	return bResult;
}

/**
 * Pass on input to the currently focused view (JoinGame only atm)
 */
function bool FilterButtonInput(int ControllerId, name ButtonName, EInputEvent InputEvent)
{
//	if (GFxGrowMenu_JoinGame(ViewStack[ViewStack.Length-1]) != none)
//		return GFxGrowMenu_JoinGame(ViewStack[ViewStack.Length-1]).OnFilterButtonInput(ControllerId, ButtonName, InputEvent);

	return False;
}


defaultproperties
{    
	// Views & Dialogs
	WidgetBindings.Add((WidgetName="Community",WidgetClass=class'GFxGrowMenu_Community'))
	WidgetBindings.Add((WidgetName="CreateGame",WidgetClass=class'GFxGrowMenu_CreateGame'))       
	WidgetBindings.Add((WidgetName="Customise",WidgetClass=class'GFxGrowMenu_Customise'))
	WidgetBindings.Add((WidgetName="GameMode",WidgetClass=class'GFxGrowMenu_GameMode'))
	WidgetBindings.Add((WidgetName="JoinGame",WidgetClass=class'GFxGrowMenu_JoinGame'))
	WidgetBindings.Add((WidgetName="MainMenu",WidgetClass=class'GFxGrowMenu_MainMenu'))
	WidgetBindings.Add((WidgetName="MapSelect",WidgetClass=class'GFxGrowMenu_MapSelect'))
	WidgetBindings.Add((WidgetName="Mutators",WidgetClass=class'GFxGrowMenu_Mutators'))       
	WidgetBindings.Add((WidgetName="Options",WidgetClass=class'GFxGrowMenu_Options'))
	WidgetBindings.Add((WidgetName="Play",WidgetClass=class'GFxGrowMenu_Play'))
	WidgetBindings.Add((WidgetName="ServerSettings",WidgetClass=class'GFxGrowMenu_ServerSettings'))
	WidgetBindings.Add((WidgetName="Settings",WidgetClass=class'GFxGrowMenu_Settings'))
	WidgetBindings.Add((WidgetName="Stats",WidgetClass=class'GFxGrowMenu_Stats'))
	
	WidgetBindings.Add((WidgetName="InfoDialog",WidgetClass=class'GFxGrowMenu_InfoDialog'))
	WidgetBindings.Add((WidgetName="ErrorDialog",WidgetClass=class'GFxGrowMenu_ErrorDialog'))
	WidgetBindings.Add((WidgetName="JoinDialog",WidgetClass=class'GFxGrowMenu_JoinDialog'))
	WidgetBindings.Add((WidgetName="PasswordDialog",WidgetClass=class'GFxGrowMenu_PasswordDialog'))

	// Sound Mapping
	//SoundThemes(0)=(ThemeName=default,Theme=UISoundTheme'UDKFrontEnd.Sound.SoundTheme')

	ViewData.Add((ViewName="MainMenu",SWFName="gw_main_menu.swf"))
	ViewData.Add((ViewName="Play",SWFName="gw_play.swf"))
	ViewData.Add((ViewName="Options",SWFName="gw_options.swf"))

	bDisplayWithHudOff=TRUE    
	TimingMode=TM_Real
	bInitialized=FALSE
	MovieInfo=SwfMovie'GrowFrontEnd.gw_manager'
	bPauseGameWhileActive=TRUE
	bCaptureInput=true
}