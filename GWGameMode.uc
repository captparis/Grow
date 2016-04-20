interface GWGameMode
	dependson(GWConstants);

function bool AllowGrow(PlayerReplicationInfo Player, EForm NewForm);
function DelayedPlayerStart(Controller NewPlayer);
//function bool AllowFoodSpawn();