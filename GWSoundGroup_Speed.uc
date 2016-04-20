class GWSoundGroup_Speed extends GWSoundGroup;

var SoundCue StinkSound;
var SoundCue TailWhipSound;

static function PlayStinkSound(Pawn P) {
	P.PlaySound(Default.StinkSound, false, true, true);
}
static function PlayTailWhipSound(Pawn P){
	P.PlaySound(Default.TailWhipSound, false, true, true);
}

DefaultProperties
{
	DyingSound=SoundCue'Grow_Character_Audio.scampersoundcues.Scamper_Die_SoundCue'
	HitSounds[0]=SoundCue'Grow_Character_Audio.scampersoundcues.Scamper_Hurt_SoundCue'
	HitSounds[1]=SoundCue'Grow_Character_Audio.scampersoundcues.Scamper_Hurt_SoundCue'

	AttackSound=SoundCue'Grow_Character_Audio.scampersoundcues.Scamper_Attack_SoundCue'
	AbilitySound=SoundCue'Grow_Character_Audio.scampersoundcues.ScamperSpeedboostSoundCue'
	EatSound=SoundCue'Grow_Character_Audio.scampersoundcues.Scamper_Eat_SoundCues'
	ChewSound=SoundCue'Grow_Character_Audio.scampersoundcues.Scamper_Eat_SoundCues'
	SpitSound=SoundCue'Grow_Character_Audio.scampersoundcues.Scamper_Spit_SoundCue'
	StinkSound=SoundCue'Grow_Character_Audio.scampersoundcues.ScamperStinkSoundCue'
	TailWhipSound=SoundCue'Grow_Character_Audio.scampersoundcues.ScamperTailWhipSoundCue'
	SpewSound=Soundcue'Grow_Character_Audio.scampersoundcues.Scamper_Puke_SoundCue'
}
