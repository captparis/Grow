class GFxGrowMenu_Play extends GFxGrowMenu_Screen;
/** Structure which defines a unique game mode. */
struct Option
{
	var string OptionName;
	var string OptionLabel;
	var string OptionDesc;
};

/** Aray of all list options, defined in DefaultUI.ini */
var array<Option> ListOptions;

/** Reference to the list. */
var GFxClikWidget ListMC;

/** Reference to the list's dataProvider array in AS. */
var GFxObject ListDataProvider;

/** Reference to the "USER" label at the bottom right. Label for username textField. */
//var GFxObject UserLabelTxt;

/** Reference to the User Name textField. This only appears if the user is properly logged in. */
//var GFxObject UserNameTxt;

var byte LastSelectedIndex;

/** Configures the view when it is first loaded. */
function OnViewLoaded()
{
	Super.OnViewLoaded();
}

/**
* Update the view.
* This method is called whenever the view is pushed or popped from the view stakc.
*/
function OnTopMostView(optional bool bPlayOpenAnimation = false)
{
	Super.OnTopMostView(bPlayOpenAnimation);

	MenuManager.SetSelectionFocus(ListMC);
	UpdateDescription();
}

/** Enable/disable sub-components of the view. */
function DisableSubComponents(bool bDisableComponents)
{
	if (ListMC != none)
	{
		ListMC.SetBool("disabled", bDisableComponents);
	}
}

/**
* Pushes the Instant Action view on to the stack. This method is fired
* by the list's OnListItemPress() listener.
*/
function Select_Play()
{
	MenuManager.PushViewByName('Play');
}

/**
* Pushes the Multiplayer view on to the stack. This method is fired
* by the list's OnListItemPress() listener.
*/
function Select_Options()
{
	MenuManager.PushViewByName('Options');
}

/** Before exiting the game, spawn a dialog asking the user to confirm his selection. */
function Select_ExitGame()
{
	// local GFxGrowMenu_InfoDialog ExitDialogMC;
	/*ExitDialogMC = GFxGrowMenu_InfoDialog(MenuManager.SpawnDialog('InfoDialog'));
ExitDialogMC.SetTitle("EXIT GAME");
ExitDialogMC.SetInfo("Are you sure you wish to exit?");
ExitDialogMC.SetBackButtonLabel("CANCEL");
ExitDialogMC.SetAcceptButtonLabel("EXIT GAME");
ExitDialogMC.SetAcceptButton_OnPress(ExitDialog_SelectOK);
ExitDialogMC.SetBackButton_OnPress(ExitDialog_SelectBack);*/
}

/** Listener for ExitDialog's "OK" button press. Quits the game. */
function ExitDialog_SelectOK( GFxClikWidget.EventData ev )
{
	ConsoleCommand("quit");
}

/** Listener for ExitDialog's "Cancel" button press. Pops a dialog from the view stack. */
function ExitDialog_SelectBack( GFxClikWidget.EventData ev )
{
	MenuManager.PopView();
}

/**
* Listener for the menu's list "CLIK_itemPress" event.
* When an item is pressed, retrieve the data associated with the item
* and use it to trigger the appropriate function call.
*/
private final function OnListItemPress(GFxClikWidget.EventData ev)
{
	local int SelectedIndex;
	local name Selection;

	SelectedIndex = ev._this.GetInt("index");
	`Log("SelectedIndex: "$SelectedIndex);
	Selection = Name(ListOptions[SelectedIndex].OptionName);

	switch(Selection)
	{
		case('Play'):
		Select_Play();
		break;
		case('Options'):
		Select_Options();
		break;
		case('Exit'):
		Select_ExitGame();
		break;
	default:
		break;
	}
}

/**
* Listener for the menu's list "CLIK_onChange" event.
* When the selectedIndex of the list changes, update the title, description,
* and image information using the data from the list.
*/
private final function OnListChange(GFxClikWidget.EventData ev)
{
	UpdateDescription();
}

/**
* Update the info text field with a description of the
* currently selected index.
*/
function UpdateDescription()
{
	local int SelectedIndex;
	//local String Description;

	if (ListMC != none)
	{
		SelectedIndex = ListMC.GetFloat("selectedIndex");
		if (SelectedIndex < 0)
		{
			SelectedIndex = 0;
		}

		// Description = ListOptions[SelectedIndex].OptionDesc;
		// InfoTxt.SetText(Description);
	}
}

/**
* Sets up the list's dataProvider using the data pulled from
* DefaultUI.ini.
*/
function UpdateListDataProvider()
{
	local byte i;
	local GFxObject DataProvider, dataProviderArray;
	local GFxObject TempObj;

	dataProviderArray = Outer.CreateArray();
	for (i = 0; i < ListOptions.Length; i++)
	{
		TempObj = CreateObject("Object");
		TempObj.SetString("name", ListOptions[i].OptionName);
		TempObj.SetString("label", ListOptions[i].OptionLabel);
		TempObj.SetString("desc", ListOptions[i].OptionDesc);

		dataProviderArray.SetElementObject(i, TempObj);
	}
	dataProvider = CreateDataProviderFromArray( dataProviderArray );
	ListMC.SetObject("dataProvider", DataProvider);
	//PushListUpdate();
	ListDataProvider = ListMC.GetObject("dataProvider");

	ListMC.AddEventListener('CLIK_itemClick', OnListItemPress);
	ListMC.AddEventListener('CLIK_change', OnListChange);
}

/** Pushes Unreal Script changes to Action Script (updates the UI) */
function PushListUpdate()
{
	ListMC.ActionScriptVoid("validateNow");
}

/**
* Passes a reference to the list back to the AS View implementation.
*/
function SetList(GFxObject InList)
{
	ActionScriptVoid("setList");
}

function OnEscapeKeyPress()
{
	Select_ExitGame();
}

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget)
{
	local bool bWasHandled;
	bWasHandled = false;

	`log("GFxUDKFrontEnd_MainMenu: WidgetInitialized():: WidgetName: " @ WidgetName @ " : " @ WidgetPath @ " : " @ Widget);
	switch(WidgetName)
	{
	case ('list'):
		if (ListMC == none)
		{
			ListMC = GFxClikWidget(Widget);
			SetList(ListMC);

			UpdateListDataProvider();
			MenuManager.SetSelectionFocus(ListMC);
			ListMC.SetFloat("selectedIndex", 0);

			UpdateDescription();
			bWasHandled = true;
		}
		break;

	default:
		bWasHandled = false;
	}

	if (!bWasHandled)
	{
		bWasHandled = Super.WidgetInitialized(WidgetName, WidgetPath, Widget);
	}
	return bWasHandled;
}

defaultproperties
{
	// AcceptButtonHelpText="SELECT"
	// CancelButtonHelpText="EXIT GAME"
	//ViewTitle=
	ListOptions.Add((OptionName="Play",OptionLabel="PLAY",OptionDesc="Jump right into the action with some bots."))
	ListOptions.Add((OptionName="Options",OptionLabel="OPTIONS",OptionDesc="Host or join a multiplayer game."))
	ListOptions.Add((OptionName="Exit",OptionLabel="EXIT",OptionDesc="Exit to the desktop."))
}