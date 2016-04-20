class GWAnimBlendByFall_Scamper extends GWAnimBlendByFall;

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
		if(bDidDoubleJump && !bIgnoreDoubleJumps) {
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
				//SetActiveChild(5, 0.1);
				`Log("Anim State:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
				AnimStateTime = 0;
				FallState = BF_DBL_Down;
				`Log("Anim State:"@FallState,, 'DevAnim');
			} else {
				//SetActiveChild(1, 0.1);
				`Log("Anim State:"@FallState@"for"@AnimStateTime@"seconds.",, 'DevAnim');
				AnimStateTime = 0;
				FallState = BF_Down;
				`Log("Anim State:"@FallState,, 'DevAnim');
			}
		}
		if(FallState != BF_PreLand && FallState != BF_DBL_PreLand) {
			TraceDist = 520 * PrelandTime;

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
			}
		}
	}
	LastFallingVelocity = P.Velocity.Z;
}