class GWProj_SkillSpeedSpecial extends GWProj;

simulated function SpawnExplosionEffects(vector HitLocation, vector HitNormal)
{
	local FogVolumeSphericalDensityInfoSpawnable FogInfo;
	local MaterialInstanceTimeVarying MITV;
	local PlayerController PC;
	local byte TeamNum;
	local MaterialInterface TeamFogMat;
	local LinearColor TeamFogColour;

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		TeamFogMat=MaterialInstanceTimeVarying'G_FX_CH_Toot.Materials.MITV_SmokeBomb_Neutral';
		if(GWPawn_SkillSpeed(Instigator) != none) {
			TeamNum = GetTeamNum();
			if(TeamNum != 0 && TeamNum != 1) {
				TeamNum = 2;
			}
			TeamFogMat = GWPawn_SkillSpeed(Instigator).FogMaterial[TeamNum];
			switch(TeamNum) {
			case 0:
				TeamFogColour = MakeLinearColor(0.592438,0,0.804559,1);
				break;
			case 1:
				TeamFogColour = MakeLinearColor(0.804559,0.523443,0.031551,1);
				break;
			case 2:
				TeamFogColour = MakeLinearColor(0.5,0.5,0.7,1);
				break;
			}
		}
		FogInfo = Spawn(class'FogVolumeSphericalDensityInfoSpawnable', , , HitLocation);
		if(FogInfo != none) {
			FogInfo.LifeSpan = 10;
			MITV = new(self) class'MaterialInstanceTimeVarying';
			MITV.SetParent(TeamFogMat);
			MITV.SetDuration( 10 );
			FogInfo.AutomaticMeshComponent.SetScale(10);
			FogInfo.AutomaticMeshComponent.SetMaterial(0, MITV);
			FogInfo.AutomaticMeshComponent.TranslucencySortPriority=1000;
			//FogVolumeSphericalDensityComponent(FogInfo.DensityComponent).SphereRadius = 1200;
			PC = GetALocalPlayerController();
	
			if(PC.Pawn.GetTeamNum() == TeamNum) {
				FogVolumeSphericalDensityComponent(FogInfo.DensityComponent).MaxDensity = 0.005;
			} else {
				FogVolumeSphericalDensityComponent(FogInfo.DensityComponent).MaxDensity = 0.05;
			}
			FogVolumeSphericalDensityComponent(FogInfo.DensityComponent).ApproxFogLightColor = TeamFogColour;
			FogVolumeSphericalDensityComponent(FogInfo.DensityComponent).bAffectsTranslucency = false;
		}
		bSuppressExplosionFX = true; // so we don't get called again
	}
}
DefaultProperties
{
	ProjFlightTemplate=ParticleSystem'Grow_Effects.Effects.Smoke_Bomb_Projectile'
	//ProjExplosionTemplate=ParticleSystem'Grow_Effects.Effects.Smoke_Bomb_Cloud'
	Damage=0//12
	CheckRadius=24
	Begin Object Name=CollisionCylinder
		CollisionRadius=18
		CollisionHeight=18
	End Object
}
