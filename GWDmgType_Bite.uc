class GWDmgType_Bite extends GWDamageType;

static function string DeathMessage(PlayerReplicationInfo Killer, PlayerReplicationInfo Victim)
{
	return Killer.PlayerName$" killed "$Victim.PlayerName;
}

DefaultProperties
{
	DamageBodyMatColor=(R=50,G=0,B=0)
	DamageOverlayTime=1.0
	DeathOverlayTime=1.0
	bCausesBlood=true
	bSpecialDeathCamera=true
	bComplainFriendlyFire=false
	bDontHurtInstigator=true
}
