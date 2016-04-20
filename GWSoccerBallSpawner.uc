class GWSoccerBallSpawner extends Actor
	placeable
	ClassGroup(Grow);

var GWSoccerBall CurrentBall;
var float LastDestroy;

simulated event Tick(float DeltaTime) {
	super.Tick(DeltaTime);
	if(CurrentBall == none) {
		LastDestroy += DeltaTime;
		if(LastDestroy > 3) {
			CurrentBall = Spawn(class'GWSoccerBall', self, , Location, Rotation);
			LastDestroy = 0;
		}
	}
}

DefaultProperties
{
	bAlwaysRelevant=true
	bGameRelevant = true
	bStatic=false
	bTickIsDisabled=false
	bHidden=false

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
        StaticMesh=StaticMesh'G_P_Fruit.Mesh.SM_Fruit_Large'
		HiddenGame=true
	End Object
	Components.Add(StaticMeshComponent0)
}