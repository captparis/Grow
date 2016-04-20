class GWLastSecondMessage extends UTLastSecondMessage;

static function SoundNodeWave AnnouncementSound(int MessageIndex, Object OptionalObject, PlayerController PC)
{
	if ( MessageIndex == 1 )
		return SoundNodeWave'Placeholder.NullSound';
	else
		return SoundNodeWave'Placeholder.NullSound';
}

DefaultProperties
{
}
