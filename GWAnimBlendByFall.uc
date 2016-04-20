class GWAnimBlendByFall extends UTAnimBlendBase;

/*var() array<name> UpAnimList;
var() array<name> DownAnimList;
var() array<name> DBLUpAnimList;
var() array<name> DBLDownAnimList;*/

enum EBlendFall
{
	BF_None,
	BF_Up,
	BF_Down,
	BF_PreLand,
	BF_Land,
	BF_DBL_Up,
	BF_DBL_Down,
	BF_DBL_PreLand,
	BF_DBL_Land
};

/** The current state this node believes the pawn to be in */

var EBlendFall 	FallState;


/** If TRUE, double jump versions of the inputs will be ignored. */
var() bool					bIgnoreDoubleJumps;

/** Time before predicted landing to trigger pre-land animation. */
var() float					PreLandTime;

/** True if a double jump was performed and we should use the DblJump states. */
var transient bool			bDidDoubleJump;

/** Set internally, this variable holds the size of the velocity at the last tick */

var float				LastFallingVelocity;

var float AnimStateTime;

var float TimeTicked;

event TickAnim(FLOAT DeltaSeconds) {
	Local GWPawn P;
	local vector HitLocation, HitNormal;
	local TraceHitInfo HitInfo;
	local actor HitActor;
	local float TraceDist;

	AnimStateTime += DeltaSeconds;
	//`Log(FallState);
	if(SkelComponent.Owner != none) {
		P = GWPawn(SkelComponent.Owner);
	} else {
		return;
	}
	if(P.Base != none) { // if Pawn is on the ground, play Landed/DBL Landed Animation
		if(FallState != BF_DBL_Land && FallState != BF_Land) {
			if(bDidDoubleJump && !bIgnoreDoubleJumps) {
				`Log("Anim State:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
				AnimStateTime = 0;
				FallState = BF_DBL_Land;
				`Log("Anim State:"@FallState,, 'DevAnim');
				SetActiveChild(7, GetBlendTime(7));
			} else {
				`Log("Anim State:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
				AnimStateTime = 0;
				FallState = BF_Land;
				`Log("Anim State:"@FallState,, 'DevAnim');
				SetActiveChild(3, GetBlendTime(3));
			}
			bDidDoubleJump = false;
		}
		LastFallingVelocity = 0;
		return;
	}
	if(LastFallingVelocity < P.Velocity.Z && LastFallingVelocity != 0) {
		bDidDoubleJump = true;
		if(!bIgnoreDoubleJumps) {
			SetActiveChild(4, GetBlendTime(4));
			`Log("Anim State:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
			AnimStateTime = 0;
			FallState = BF_DBL_Up;
			`Log("Anim State:"@FallState,, 'DevAnim');
		}
	}
	if(P.Velocity.Z > 0 && !(FallState == BF_Up || FallState == BF_DBL_Up)) {
		if(bDidDoubleJump && !bIgnoreDoubleJumps/* && !(FallState == BF_Land || FallState == BF_DBL_Land || FallState == BF_PreLand || FallState == BF_DBL_PreLand)*/) {
			SetActiveChild(4, GetBlendTime(4));
			`Log("Anim State:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
			AnimStateTime = 0;
			FallState = BF_DBL_Up;
			`Log("Anim State:"@FallState,, 'DevAnim');
		} else {
			SetActiveChild(0, GetBlendTime(0));
			`Log("Anim State:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
			AnimStateTime = 0;
			FallState = BF_Up;
			`Log("Anim State:"@FallState,, 'DevAnim');
		}
	} else if(P.Velocity.Z < 0) {
		if(FallState == BF_Up || FallState == BF_DBL_Up) {
			if(bDidDoubleJump && !bIgnoreDoubleJumps) {
				SetActiveChild(5, GetBlendTime(5));
				`Log("Anim State:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
				AnimStateTime = 0;
				FallState = BF_DBL_Down;
				`Log("Anim State:"@FallState,, 'DevAnim');
			} else {
				SetActiveChild(1, GetBlendTime(1));
				`Log("Anim State:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
				AnimStateTime = 0;
				FallState = BF_Down;
				`Log("Anim State:"@FallState,, 'DevAnim');
			}
		}
		if(FallState != BF_PreLand && FallState != BF_DBL_PreLand) {
			TraceDist = P.GetGravityZ() * PrelandTime;

			HitActor = P.Trace(HitLocation, HitNormal, P.Location + TraceDist * Normal(P.Velocity), P.Location, false,, HitInfo, 2);
			if (HitActor != None && Volume(HitActor) == none) {
				if(bDidDoubleJump && !bIgnoreDoubleJumps) {
					SetActiveChild(6, GetBlendTime(6));
					`Log("Anim State:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
					AnimStateTime = 0;
					FallState = BF_DBL_PreLand;
					`Log("Anim State:"@FallState,, 'DevAnim');
				} else {
					SetActiveChild(2, GetBlendTime(2));
					`Log("Anim State:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
					AnimStateTime = 0;
					FallState = BF_PreLand;
					`Log("Anim State:"@FallState,, 'DevAnim');
				}
				//bDidDoubleJump = false;
			}
		}
	}
	LastFallingVelocity = P.Velocity.Z;
}
/** Called from InitAnim. Allows initialization of script-side properties of this node. */
//event OnInit();
/** Get notification that this node has become relevant for the final blend. ie TotalWeight is now > 0 */
event OnBecomeRelevant() {
	Local GWPawn P;

	P = GWPawn(SkelComponent.Owner);

	if(P.Velocity.Z > 0) {
		SetActiveChild(0,GetBlendTime(0));
		`Log("Anim State On Become Relevant:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
		AnimStateTime = 0;
		FallState = BF_Up;
	} else {
		SetActiveChild(1,GetBlendTime(1));
		`Log("Anim State On Become Relevant:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
		AnimStateTime = 0;
		FallState = BF_Down;
	}
	`Log("Anim State On Become Relevant:"@FallState,, 'DevAnim');
	LastFallingVelocity = P.Velocity.Z;
}
/** Get notification that this node is no longer relevant for the final blend. ie TotalWeight is now == 0 */
event OnCeaseRelevant() {
	`Log("Anim State On Cease Relevant:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
	AnimStateTime = 0;
	FallState = BF_None;
	`Log("Anim State On Cease Relevant:"@FallState,, 'DevAnim');
	StopAnim();
	bDidDoubleJump = false;
}

DefaultProperties
{
	CategoryDesc = "Grow"

	Children(0)=(Name="Up",Weight=1.0)
	Children(1)=(Name="Down")
	Children(2)=(Name="Pre-Land")
	Children(3)=(Name="Land")
	Children(4)=(Name="Double Up")
	Children(5)=(Name="Double Down")
	Children(6)=(Name="Double Pre-Land")
	Children(7)=(Name="Double Land")
	bFixNumChildren=true
	bTickAnimInScript=true
	bCallScriptEventOnBecomeRelevant=true
	bCallScriptEventOnCeaseRelevant=true
}
