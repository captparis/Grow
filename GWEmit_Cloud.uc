class GWEmit_Cloud extends GWReplicatedEmitter;
var repnotify byte ColorSet;

replication {
	if(bNetInitial || bNetDirty)
		ColorSet;
}

simulated event ReplicatedEvent(name Varname) {
	if(Varname == 'ColorSet') {
		SetColor(ColorSet);
	}
	super.ReplicatedEvent(Varname);
}

simulated function SetColor(byte newColor) {
	switch(newColor) {
	case 1:
		ParticleSystemComponent.SetMaterialParameter('BallMat', MaterialInstanceConstant'Grow_Effects.Materials.CloudParticles_RGB_Masked_Mat_INST_Red');
		ParticleSystemComponent.SetMaterialParameter('RingMat', MaterialInstanceConstant'Grow_Effects.Materials.CloudParticles_RGB_Particle_Mat_INST_Red');
		ParticleSystemComponent.SetMaterialParameter('ArrowMat', MaterialInstanceConstant'Grow_Effects.Materials.Triangle_Mat_INST_Red');
		break;
	case 2:
		ParticleSystemComponent.SetMaterialParameter('BallMat', MaterialInstanceConstant'Grow_Effects.Materials.CloudParticles_RGB_Masked_Mat_INST_Blue');
		ParticleSystemComponent.SetMaterialParameter('RingMat', MaterialInstanceConstant'Grow_Effects.Materials.CloudParticles_RGB_Particle_Mat_INST_Blue');
		ParticleSystemComponent.SetMaterialParameter('ArrowMat', MaterialInstanceConstant'Grow_Effects.Materials.Triangle_Mat_INST_Blue');
		break;
	case 3:
		ParticleSystemComponent.SetMaterialParameter('BallMat', MaterialInstanceConstant'Grow_Effects.Materials.CloudParticles_RGB_Masked_Mat_INST_Yellow');
		ParticleSystemComponent.SetMaterialParameter('RingMat', MaterialInstanceConstant'Grow_Effects.Materials.CloudParticles_RGB_Particle_Mat_INST_Yellow');
		ParticleSystemComponent.SetMaterialParameter('ArrowMat', MaterialInstanceConstant'Grow_Effects.Materials.Triangle_Mat_INST_Yellow');
		break;
	}
	if(Role == ROLE_Authority) {
		bNetDirty = true;
		bForceNetUpdate = true;
		ColorSet = newColor;
	}
}

DefaultProperties
{
	//ServerLifeSpan=5
	EmitterTemplate=ParticleSystem'Grow_Effects.Effects.Grow_Smoke_Effect'
}
