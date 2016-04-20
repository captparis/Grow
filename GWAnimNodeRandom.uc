class GWAnimNodeRandom extends UTAnimBlendBase;

struct RandomAnimInfo
{
	/** Chance this child will be selected */
	var() float		Chance;
	/** Minimum number of loops to play this animation */
	var() Byte		LoopCountMin;
	/** Maximum number of loops to play this animation */
	var() Byte		LoopCountMax;
	/** Blend in time for this child */
	var() float		BlendInTime;
	/** Animation Play Rate Scale */
	var() Vector2D	PlayRateRange;
	/** If it's a still frame, don't play animation. Just randomly pick one, and stick to it until we lose focus */
	var() bool		bStillFrame;

	structdefaultproperties
	{
		Chance=1.f
		LoopCountMin=0
		LoopCountMax=0
		BlendInTime=0.25f
		PlayRateRange=(X=1.f,Y=1.f)
	}
};

var() editinline Array<RandomAnimInfo> RandomInfo;

/** Pointer to AnimNodeSequence currently playing random animation. */
var transient	AnimNodeSequence	PlayingSeqNode;
var transient	INT					LastChildIndex;
var transient   int                 LoopCount;
var transient   int                 currentLoopNum;
var float duration;
var float currentTime;

/** Called from InitAnim. Allows initialization of script-side properties of this node. */
event OnInit() {
	//`Log(GetFuncName());
	if(RandomInfo.Length > Children.Length) {
		RandomInfo.Remove(Children.Length, RandomInfo.Length - Children.Length);
	} else if(RandomInfo.Length < Children.Length) {
		RandomInfo.Add(Children.Length - RandomInfo.Length);
	}
}
/** Get notification that this node has become relevant for the final blend. ie TotalWeight is now > 0 */
event OnBecomeRelevant() {
	//`Log(GetFuncName());
	LastChildIndex=-1;

	SetNewAnimation();
}
/** Get notification that this node is no longer relevant for the final blend. ie TotalWeight is now == 0 */
event OnCeaseRelevant() {
	//`Log(GetFuncName());
	// Clear timers
	StopAnim();
	currentTime = 0;
	duration = 0;
	LastChildIndex = ActiveChildIndex;
}

event OnAnimationComplete() {
	//`Log(GetFuncName());
	// Choose new animation
	if(currentLoopNum >= LoopCount) {
		SetNewAnimation();
	} else {
		currentLoopNum++;
		PlayAnim(false, 1.0f, 0);
		currentTime = 0;
	}
	// Play animation and start timer
}

event TickAnim(FLOAT DeltaSeconds) {
	
	//`Log("CurrentTime"@currentTime@"of"@duration);
	if(currentTime >= duration && duration > 0) {
		OnAnimationComplete();
	}
	currentTime += DeltaSeconds;
}
function SetNewAnimation() {
	local float SumChance;
	local float randChance;
	local int i;
	local int childToPlay;
	local AnimNodeSequence activeChild;

	//`Log(GetFuncName());
	// Choose random animation based on random info
	SumChance = 0;
	if(Children.Length > 1) {
		for(i = 0; i < RandomInfo.Length; i++) {
			SumChance += RandomInfo[i].Chance;
		}
		do {
			randChance = FRand() * SumChance;
			childToPlay = -1;
			for(i = 0; i < RandomInfo.Length; i++) {
				randChance -= RandomInfo[i].Chance;
				if(randChance <= 0) {
					childToPlay = i;
					break;
				}
			}
			if(childToPlay >= Children.Length) {
				childToPlay = -1;
				continue;
			}
		} until(childToPlay != -1); // Keep looping until we get a valid animation
	} else {
		childToPlay = 0;
	}
	// Play Animation and start timer
	LastChildIndex = ActiveChildIndex;
	SetActiveChild(childToPlay, RandomInfo[childToPlay].BlendInTime);
	PlayAnim(false, 1.0f, 0);
	currentLoopNum = 1;
	LoopCount = RandRange(RandomInfo[ActiveChildIndex].LoopCountMin, RandomInfo[ActiveChildIndex].LoopCountMax);
	activeChild = GetActiveChildAnimSequence();
	duration = SkelComponent.GetAnimLength(activeChild.AnimSeqName);
	currentTime = 0;
}

function AnimNodeSequence GetActiveChildAnimSequence() {
	`Log("Search:"@self);
	return Children[ActiveChildIndex].Anim.GetActiveChildAnimSequence();
}
defaultproperties
{
	LastChildIndex=-1

	CategoryDesc = "Grow"

	bTickAnimInScript=true
	bCallScriptEventOnInit=true
	bCallScriptEventOnBecomeRelevant=true
	bCallScriptEventOnCeaseRelevant=true
}