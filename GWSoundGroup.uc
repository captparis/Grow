class GWSoundGroup extends UTPawnSoundGroup;

var SoundCue HappySound;
var SoundCue EvolveSound;
var SoundCue AttackSound;
var SoundCue AbilitySound;
var SoundCue EatSound;
var SoundCue ChewSound;
var SoundCue SpitSound;
var SoundCue SpewSound;

static function PlayHappySound(Pawn P) {
	P.Playsound(Default.HappySound, false, true, true);
}

static function PlayEvolveSound(Pawn P) {
	P.Playsound(Default.EvolveSound, false, true);
}
static function PlayAttackSound(Pawn P) {
	P.Playsound(Default.AttackSound, false, true, true);
}
static function PlayAbilitySound(Pawn P) {
	P.Playsound(Default.AbilitySound, false, true, true);
}
static function PlaySpewSound(Pawn P) {
	P.Playsound(Default.SpewSound, false, true, true);
}
static function PlayEatSound(Pawn P) {
	P.Playsound(Default.EatSound, false, true, true);
}
static function PlayChewSound(Pawn P) {
	P.Playsound(Default.ChewSound, false, true, true);
}
static function PlaySpitSound(Pawn P) {
	P.Playsound(Default.SpitSound, false, true, true);
}
static function PlayDyingSound(Pawn P){
	P.Playsound(Default.DyingSound, false, true, true);
}

static function SoundCue GetFootstepSound(int FootDown, name MaterialType) {
	//`Log("Step:"@FootDown);
	return default.DefaultFootstepSound; // checking for a '' material in case of empty array elements
}

static function SoundCue GetJumpSound(name MaterialType) {
	return default.DefaultJumpingSound; // checking for a '' material in case of empty array elements
}

static function SoundCue GetLandSound(name MaterialType) {
	return default.DefaultLandingSound; // checking for a '' material in case of empty array elements
}

static function PlayTakeHitSound(Pawn P, int Damage) {
	if(Damage < 50) {
		P.PlaySound(default.HitSounds[0]);
	} else {
		P.PlaySound(default.HitSounds[1]);
	}
}

defaultproperties
{
	DrownSound=SoundCue'Placeholder.NullCue'
	GaspSound=SoundCue'Placeholder.NullCue'
	
	DefaultJumpingSound=SoundCue'Placeholder.NullCue'

	DefaultFootstepSound=SoundCue'Grow_John_Assets.Sounds.A_Character_Footstep_DefaultCue'

	JumpingSounds.Empty
	JumpingSounds.Add((MaterialType="",Sound=SoundCue'Placeholder.NullCue'))
	DoubleJumpSound=SoundCue'Placeholder.NullCue'
	DefaultLandingSound=SoundCue'Placeholder.NullCue'
	LandingSounds.Empty

	BulletImpactSound=SoundCue'Placeholder.NullCue'
	

	HappySound=SoundCue'Placeholder.NullCue'
	EvolveSound=SoundCue'Grow_John_Assets.GrowingSounds.Growing_Success_Sound'
	DyingSound=SoundCue'Grow_Sounds.deadhigh_Cue'
	HitSounds[0]=SoundCue'Grow_John_Assets.Sounds.Normal_Impact'
	HitSounds[1]=SoundCue'Grow_John_Assets.Sounds.HeavyCrit_Impact'

	AttackSound=SoundCue'Placeholder.NullCue'
	AbilitySound=SoundCue'Placeholder.NullCue'
	EatSound=SoundCue'Grow_Sounds.eatinghigh_Cue'
	ChewSound=SoundCue'Grow_Sounds.eatinghigh_Cue'
	SpitSound=SoundCue'Grow_Character_Audio.nomsoundcues.NomSpitSoundCue'
	SpewSound=Soundcue'Placeholder.NullCue'
}