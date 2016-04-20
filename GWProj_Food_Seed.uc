class GWProj_Food_Seed extends GWProj_Food;

simulated function Explode(vector HitLocation, vector HitNormal) {
	if ( Role == ROLE_Authority )
	{
		if(HitNormal.Z > 0.7)
		//`Log(HitNormal @ "=" @ MakeRotator(HitNormal.Z * 180 * DegToUnrRot, HitNormal.X * 180 * DegToUnrRot, HitNormal.Y * 180 * DegToUnrRot));
		Spawn(class'GWPlant_All',,,HitLocation + HitNormal * 60, MakeRotator(0,0,0)); //MakeRotator(HitNormal.Z * 180 * DegToUnrRot, HitNormal.X * 180 * DegToUnrRot, HitNormal.Y * 180 * DegToUnrRot));
	}
	super.Explode(HitLocation, HitNormal);
}

DefaultProperties
{
	ProjExplosionTemplate=ParticleSystem'Grow_John_Assets.Effects.pomegranite_explosion_effect'
}
