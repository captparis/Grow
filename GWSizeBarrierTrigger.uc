class GWSizeBarrierTrigger extends TriggerVolume
	ClassGroup(Grow);

var GWSizeBarrier connectedBarrier;
simulated function PostBeginPlay() {
//Find contained Barrier
	local GWSizeBarrier ArrayItem;

	ForEach AllActors(class'GWSizeBarrier', ArrayItem) {
		//`log(Name$": Barrier at "$ArrayItem.Location);
		if(Encompasses(ArrayItem)) {
			connectedBarrier = ArrayItem;
			//`log(Name$": Found Barrier at "$ArrayItem.Location);
		
			break;
		}
	}
	super.PostBeginPlay();
	
}

simulated event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	//`log(Name$" Touched by "$Other.Name);
	if(connectedBarrier == none) {
		//`Log("Can't touch this");
	}
	if(connectedBarrier != none && (Other.Role == ROLE_AutonomousProxy || Other.Role == ROLE_Authority)) {
		//`log(Name$" Touched by "$Other.Name);
		if(GWPawn_Baby(Other) != none || GWPawn_Speed(Other) != none || GWPawn_Skill(Other) != none || GWPawn_Power(Other) != none) {
			connectedBarrier.bBlockActors = false;
			//`log(Name$" Touched by "$Other.Name);
			//connectedBarrier.BrushComponent.BlockNonZeroExtent = false;
		} else {
			connectedBarrier.bBlockActors = true;
			//connectedBarrier.BrushComponent.BlockNonZeroExtent = true;
		}
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

simulated event untouch( Actor Other )
{
	//`log(Name$" Untouched by "$Other.Name);
	if(connectedBarrier != none && (Other.Role == ROLE_AutonomousProxy || Other.Role == ROLE_Authority)) {
		connectedBarrier.bBlockActors = true;
	}
	super.untouch(Other);
}

DefaultProperties
{
	connectedBarrier = none
}
