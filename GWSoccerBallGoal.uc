class GWSoccerBallGoal extends TriggerVolume
	ClassGroup(Grow);

var() byte Team;

simulated event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal ) {
	local GWSoccerBall Ball;
	if(Role == ROLE_Authority) {
		Ball = GWSoccerBall(Other);
		if(Ball != none) {
			WorldInfo.Game.ScoreObjective(Ball.LastToucher.PlayerReplicationInfo, 1);
			GWSoccerBallSpawner(Ball.Owner).CurrentBall = none;
			Ball.Destroy();
		}
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

DefaultProperties
{
	bPawnsOnly=false
	
}
