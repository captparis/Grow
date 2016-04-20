class GWTargetSpawner extends Actor
	placeable
	ClassGroup(Grow);

var GWTarget CurrentTarget;
var float LastDestroy;
var() float Score; 

simulated event Tick(float DeltaTime) {
	super.Tick(DeltaTime);
	if(CurrentTarget == none) {
		LastDestroy += DeltaTime;
		if(LastDestroy > 1) {
			CurrentTarget = Spawn(class'GWTarget', self, , Location, Rotation);
			CurrentTarget.Score = Score;
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
	Score = 1

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
        StaticMesh=StaticMesh'G_SM_Target.StaticMeshs.SM_ArcheryTarget_Complete'
		Rotation=(Yaw=32768)
		HiddenGame=true
	End Object
	Components.Add(StaticMeshComponent0)
}
