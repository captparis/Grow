class GWPlayerReplicationInfo extends UTPlayerReplicationInfo
	dependson(GWConstants);

var SkeletalMesh HatMeshes[3];
var byte HatIndex[EForm];

replication {
	if(bNetDirty || (bNetInitial && Role != ROLE_Authority))
		HatIndex;
}
simulated event ReplicatedEvent(name VarName) {
	local GWPawn UTP;

	if ( VarName == 'HatIndex' ) {
		foreach WorldInfo.AllPawns(class'GWPawn', UTP) {
			if (UTP.PlayerReplicationInfo == self || (UTP.DrivenVehicle != None && UTP.DrivenVehicle.PlayerReplicationInfo == self)) {
				if(HatIndex[UTP.Form] == 255) {
					UTP.SetHatFromInfo(none);
				} else {
					UTP.SetHatFromInfo(HatMeshes[HatIndex[UTP.Form]]);
				}
			}
		}
	}

	Super.ReplicatedEvent(VarName);
}
DefaultProperties
{
	HatIndex[0]=255
	HatIndex[1]=255
	HatIndex[2]=255
	HatIndex[3]=255
	HatIndex[4]=255
	HatIndex[5]=255
	HatIndex[6]=255
	HatIndex[7]=255
	HatIndex[8]=255
	HatIndex[9]=255
	HatIndex[10]=255
	VoiceClass=class'GWVoice_Mute'
	HatMeshes[0]=SkeletalMesh'G_H_TopHat.Mesh.SK_TopHat'
}
