class GWMiniGame extends GameInfo implements(GWGameMode)
	config(game)
	dependson(GWConstants);

var bool bScoreKills;
var bool bPreventDamage;

function Killed( Controller Killer, Controller KilledPlayer, Pawn KilledPawn, class<DamageType> damageType )
{
    if( KilledPlayer != None && KilledPlayer.bIsPlayer )
	{
		KilledPlayer.PlayerReplicationInfo.IncrementDeaths();
		KilledPlayer.PlayerReplicationInfo.SetNetUpdateTime(FMin(KilledPlayer.PlayerReplicationInfo.NetUpdateTime, WorldInfo.TimeSeconds + 0.3 * FRand()));
		BroadcastDeathMessage(Killer, KilledPlayer, damageType);
	}

    if( KilledPlayer != None && bScoreKills)
	{
		ScoreKill(Killer, KilledPlayer);
	}

	DiscardInventory(KilledPawn, Killer);
    NotifyKilled(Killer, KilledPlayer, KilledPawn, damageType);
}

function bool PreventDeath(Pawn KilledPawn, Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	if(bPreventDamage) {
		if(DamageType == class'DmgType_Fell' || DamageType == class'DmgType_Suicided' || DamageType == class'KillZDamageType')
			return false;

		return true;
	} else {
		super.PreventDeath(KilledPawn, Killer, DamageType, HitLocation);
	}
}
/* ReduceDamage:
	Use reduce damage for teamplay modifications, etc. */
function ReduceDamage(out int Damage, pawn injured, Controller instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	if(bPreventDamage) {
		if(DamageType == class'DmgType_Fell' || DamageType == class'DmgType_Suicided' || DamageType == class'KillZDamageType') {
			return;
		}
		Damage = 0;
		Momentum = vect3d(0,0,0);
		return;
	}
	super.ReduceDamage(Damage, injured, instigatedBy,HitLocation, Momentum, DamageType, DamageCauser);
}

/* CheckScore()
see if this score means the game ends
*/
function bool CheckScore(PlayerReplicationInfo Scorer)
{
	if(Scorer.Score >= GoalScore) {
		EndGame(Scorer, "scorelimit");
		return true;
	} else {
		return false;
	}
}

// Parse options for this game...
event InitGame( string Options, out string ErrorMessage )
{

	Super.InitGame(Options, ErrorMessage);

	// Set goal score to end match... If automated testing, no score limit (end by timelimit only)
	GoalScore = Max(0,GetIntOption( Options, "GoalScore", GoalScore ));
}

function bool AllowGrow(PlayerReplicationInfo Player, EForm NewForm) {
	return true;
}
function DelayedPlayerStart(Controller NewPlayer) { }
DefaultProperties
{
	bTeamGame = false
	bRestartLevel = false
	bScoreKills = false
	bPreventDamage = true

	DefaultPawnClass = class'GWPawn_Baby'
	HUDType = class'GWGFxHudWrapper'
	PlayerControllerClass=class'GWPlayerController'
	PlayerReplicationInfoClass=class'GWPlayerReplicationInfo'
}