class GWAnimNodeSequenceList extends UTAnimNodeSequence;

/** When a given sequence is finished, it will continue to select new sequences from this list */
var() array<name> AnimationList;

event OnInit()
{
	Super(AnimNodeSequence).OnInit();

	if (bAutoStart)
	{
		if(AnimationList.Length == 0) 
			PlayAnim(bLooping, Rate);
		else
			PlayAnimationSet(AnimationList, Rate, true);
	}
}

event OnBecomeRelevant() {
	if(AnimationList.Length == 0)
		PlayAnim(bLooping, Rate);
	else
		`Log("Rate:"@Rate, , 'DevAnim');
		PlayAnimationSet(AnimationList, Rate, true);
}

DefaultProperties
{
	bCallScriptEventOnInit=true
	bCallScriptEventOnBecomeRelevant=true
}
