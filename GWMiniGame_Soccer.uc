class GWMiniGame_Soccer extends GWMiniGame;

function bool AllowGrow(PlayerReplicationInfo Player, EForm NewForm) {
	return false;
}

event AddDefaultInventory(Pawn P)
{
    
    P.CreateInventory(class'GWWeap_Skill_Soccer', false);
}

DefaultProperties
{
	DefaultPawnClass=class'GWPawn_Skill'
}
