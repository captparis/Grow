class GWAnimNodeSequence extends AnimNodeSequence;

var() bool bPlayFromStart;

event OnBecomeRelevant() {
	//`Log(self@"became relevant");
	if (bPlayFromStart) {
		SetPosition(0.0f, false);
	}
}

defaultproperties {
	bPlayFromStart=true
	bCallScriptEventOnBecomeRelevant=TRUE
}