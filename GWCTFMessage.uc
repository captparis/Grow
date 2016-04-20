class GWCTFMessage extends UTCarriedObjectMessage;
/**
 * Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
 */
//
// CTF Messages
//
// Switch 0: Capture Message
//	RelatedPRI_1 is the scorer.
//	OptionalObject is the flag.
//
// Switch 1: Return Message
//	RelatedPRI_1 is the scorer.
//	OptionalObject is the flag.
//
// Switch 2: Dropped Message
//	RelatedPRI_1 is the holder.
//	OptionalObject is the flag's team teaminfo.
//
// Switch 3: Was Returned Message
//	OptionalObject is the flag's team teaminfo.
//
// Switch 4: Has the flag.
//	RelatedPRI_1 is the holder.
//	OptionalObject is the flag's team teaminfo.
//
// Switch 5: Auto Send Home.
//	OptionalObject is the flag's team teaminfo.
//
// Switch 6: Pickup stray.
//	RelatedPRI_1 is the holder.
//	OptionalObject is the flag's team teaminfo.

/**
* Kill pending flag messages when a score happens
*/
static function bool ShouldBeRemoved(UTQueuedAnnouncement MyAnnouncement, class<UTLocalMessage> NewAnnouncementClass, int NewMessageIndex)
{
	if ( NewAnnouncementClass == class'GWTeamScoreMessage' )
	{
		return true;
	}
	
	return super.ShouldBeRemoved(MyAnnouncement, NewAnnouncementClass, NewMessageIndex);
}

static function SoundNodeWave AnnouncementSound(int MessageIndex, Object OptionalObject, PlayerController PC)
{
	switch (MessageIndex)
	{
		// red team
		// Returned the flag.
	case 0:
	case 1:
	case 3: // because it fell out of the world
	case 5:
		return default.ReturnSounds[0];
		break;

		// Dropped the flag.
	case 2:
		return default.DroppedSounds[0];
		break;

		// taken the flag
	case 4: // taken from dropped position
	case 6: // taken from base
		return default.TakenSounds[0];
		break;

		// blue team
		// Returned the flag.
	case 7:
	case 8:
	case 10: // because it fell out of the world
	case 12:
		return default.ReturnSounds[1];
		break;

		// Dropped the flag.
	case 9:
		return default.DroppedSounds[1];
		break;

		// taken the flag
	case 11: // taken from dropped position
	case 13: // taken from base
		return default.TakenSounds[1];
		break;

	}
	return SoundNodeWave'Placeholder.NullSound';
}

defaultproperties
{
	ReturnSounds(0)=SoundNodeWave'Grow_Sounds.eggpickup'
	ReturnSounds(1)=SoundNodeWave'Grow_Sounds.eggpickup'
	DroppedSounds(0)=SoundNodeWave'Grow_Sounds.bouncegrowth2'
	DroppedSounds(1)=SoundNodeWave'Grow_Sounds.bouncegrowth2'
	TakenSounds(0)=SoundNodeWave'Grow_Sounds.eggpick1'
	TakenSounds(1)=SoundNodeWave'Grow_Sounds.eggpick1'

	bIsUnique=True
	FontSize=2
	MessageArea=1
	bBeep=false
	DrawColor=(R=0,G=160,B=255,A=255)
}
