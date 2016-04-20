class GWDeathmatch extends UTDeathmatch implements(GWGameMode)
	dependson(GWConstants);

function AddDefaultInventory( pawn PlayerPawn )
{
	PlayerPawn.AddDefaultInventory();
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

function bool AllowGrow(PlayerReplicationInfo Player, EForm NewForm) {
	return true;
}
function DelayedPlayerStart(Controller NewPlayer) { }
DefaultProperties
{
	bGivePhysicsGun = false

	bUseClassicHUD = true
	//BotClass = class'Grow.GWBotController'
	PlayerControllerClass = class'Grow.GWPlayerController'
	DefaultPawnClass = class'Grow.GWPawn_Baby'
	PlayerReplicationInfoClass=class'GWPlayerReplicationInfo'

	//HUDType = class'GWHud'
	HUDType = class'GWGFxHudWrapper'
}
