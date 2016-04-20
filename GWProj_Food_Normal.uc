class GWProj_Food_Normal extends GWProj_Food;

//var int DamageHP;
//var StaticMeshComponent MeshParam;

simulated function InitStats(EFood FoodType, int hp) {
	local SFoodInfo FI;

	`Log(name$"::"$GetFuncName()@"set food"@FoodType,, 'DevFood');

	FI = class'GWConstants'.default.FoodStats[FoodType];
	MeshParam.SetStaticMesh(FI.Mesh);
	MeshParam.SetScale(hp / float(FI.HealAmount));
	if(Role == ROLE_Authority) {
		Damage = default.Damage * hp;
		FT = FoodType;
		FoodStrength = hp;
	}
	switch (FoodType) {
	case FOOD_CANDY_LARGE:
	case FOOD_CANDY_MEDIUM:
	case FOOD_CANDY_SMALL:
		ProjEffects.SetVectorParameter('trailCol', vect3d(1, 0.5, 0));
		ProjEffects.SetMaterialParameter('PartMatGibs', MaterialInstanceConstant'Grow_John_Assets.Materials.Eating_Chunks_Speed_Mat_INST');
		break;
	case FOOD_FRUIT_LARGE:
	case FOOD_FRUIT_MEDIUM:
	case FOOD_FRUIT_SMALL:
		ProjEffects.SetVectorParameter('trailCol', vect3d(0, 0.25, 1));
		ProjEffects.SetMaterialParameter('PartMatGibs', MaterialInstanceConstant'Grow_John_Assets.Materials.Eating_Chunks_Skill_Mat_INST');
		break;
	case FOOD_MEAT_LARGE:
	case FOOD_MEAT_MEDIUM:
	case FOOD_MEAT_SMALL:
		ProjEffects.SetVectorParameter('trailCol', vect3d(1, 0, 0));
		ProjEffects.SetMaterialParameter('PartMatGibs', MaterialInstanceConstant'Grow_John_Assets.Materials.Eating_Chunks_Power_Mat_INST');
		break;
	}
}
simulated function SetExplosionEffectParameters(ParticleSystemComponent ProjExplosion) {
	switch (FT) {
	case FOOD_CANDY_LARGE:
	case FOOD_CANDY_MEDIUM:
	case FOOD_CANDY_SMALL:
		ProjExplosion.SetMaterialParameter('PartMat', MaterialInstanceConstant'Grow_John_Assets.Materials.Gib_Speed_Material_INST');
		ProjExplosion.SetMaterialParameter('PartMatGibs', MaterialInstanceConstant'Grow_John_Assets.Materials.Eating_Chunks_Speed_Mat_INST');
		break;
	case FOOD_FRUIT_LARGE:
	case FOOD_FRUIT_MEDIUM:
	case FOOD_FRUIT_SMALL:
		ProjExplosion.SetMaterialParameter('PartMat', MaterialInstanceConstant'Grow_John_Assets.Materials.Gib_Skill_Material_INST');
		ProjExplosion.SetMaterialParameter('PartMatGibs', MaterialInstanceConstant'Grow_John_Assets.Materials.Eating_Chunks_Skill_Mat_INST');
		break;
	case FOOD_MEAT_LARGE:
	case FOOD_MEAT_MEDIUM:
	case FOOD_MEAT_SMALL:
		ProjExplosion.SetMaterialParameter('PartMat', MaterialInstanceConstant'Grow_John_Assets.Materials.Gib_Power_Material_INST');
		ProjExplosion.SetMaterialParameter('PartMatGibs', MaterialInstanceConstant'Grow_John_Assets.Materials.Eating_Chunks_Power_Mat_INST');
		break;
	}
}
/**
 * Spawn Explosion Effects
 */
simulated function SpawnExplosionEffects(vector HitLocation, vector HitNormal)
{
	local vector Direction;
	local ParticleSystemComponent ProjExplosion;
	local Actor EffectAttachActor;
	local MaterialInstanceTimeVarying MITV_Decal;
	local array<MaterialInstance> DecalMaterialArray;
	local LinearColor Colour;

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (ProjectileLight != None)
		{
			DetachComponent(ProjectileLight);
			ProjectileLight = None;
		}
		if (ProjExplosionTemplate != None && EffectIsRelevant(Location, false, MaxEffectDistance))
		{
			// Disabling for the demo to prevent explosions from attaching to the pawn...
//			EffectAttachActor = (bAttachExplosionToVehicles || (UTVehicle(ImpactedActor) == None)) ? ImpactedActor : None;
			EffectAttachActor = None;
			if (!bAdvanceExplosionEffect)
			{
				ProjExplosion = WorldInfo.MyEmitterPool.SpawnEmitter(ProjExplosionTemplate, HitLocation, rotator(HitNormal), EffectAttachActor);
			}
			else
			{
				Direction = normal(Velocity - 2.0 * HitNormal * (Velocity dot HitNormal)) * Vect(1,1,0);
				ProjExplosion = WorldInfo.MyEmitterPool.SpawnEmitter(ProjExplosionTemplate, HitLocation, rotator(Direction), EffectAttachActor);
				ProjExplosion.SetVectorParameter('Velocity',Direction);
				ProjExplosion.SetVectorParameter('HitNormal',HitNormal);
			}
			SetExplosionEffectParameters(ProjExplosion);

			// this code is mostly duplicated in:  UTGib, UTProjectile, UTVehicle, UTWeaponAttachment be aware when updating
			DecalMaterialArray.AddItem(MaterialInstanceTimeVarying'Grow_John_Assets.Decals.splat1_INST');
			DecalMaterialArray.AddItem(MaterialInstanceTimeVarying'Grow_John_Assets.Decals.splat2_INST');
			ExplosionDecal = DecalMaterialArray[Round(RandRange(0, DecalMaterialArray.Length - 1))];
			if( MaterialInstanceTimeVarying(ExplosionDecal) != none ) {
				// hack, since they don't show up on terrain anyway
				if ( Terrain(ImpactedActor) == None ) {
					MITV_Decal = new(self) class'MaterialInstanceTimeVarying';
					MITV_Decal.SetParent( ExplosionDecal );
					switch (FT) {
					case FOOD_CANDY_LARGE:
					case FOOD_CANDY_MEDIUM:
					case FOOD_CANDY_SMALL:
						Colour = MakeLinearColor(1, 0.5, 0, 0.5);
						break;
					case FOOD_FRUIT_LARGE:
					case FOOD_FRUIT_MEDIUM:
					case FOOD_FRUIT_SMALL:
						Colour = MakeLinearColor(0, 0.25, 1, 0.5);
						break;
					case FOOD_MEAT_LARGE:
					case FOOD_MEAT_MEDIUM:
					case FOOD_MEAT_SMALL:
						Colour = MakeLinearColor(1, 0, 0, 0.5);
						break;
					}
					MITV_Decal.SetVectorParameterValue('splatCol',Colour);
					//MITV_Decal.bAutoActivateAll = true;
					if(GWPawn(ImpactedActor) != none) {
						WorldInfo.MyDecalManager.SpawnDecal(MITV_Decal, HitLocation, rotator(-HitNormal), DecalWidth, DecalHeight, 256, FALSE, FRand() * 360, GWPawn(ImpactedActor).Mesh,, true);
					} else {
						WorldInfo.MyDecalManager.SpawnDecal(MITV_Decal, HitLocation, rotator(-HitNormal), DecalWidth, DecalHeight, 256, FALSE, FRand() * 360,,, true);
					}
					//here we need to see if we are an MITV and then set the burn out times to occur
					MITV_Decal.SetScalarStartTime('FadeOut', 10 );
				}
			} else {
				WorldInfo.MyDecalManager.SpawnDecal( ExplosionDecal, HitLocation, rotator(-HitNormal), DecalWidth, DecalHeight, 10.0, true );
			}
		}

		if (ExplosionSound != None && !bSuppressSounds)
		{
			PlaySound(ExplosionSound, true);
		}

		bSuppressExplosionFX = true; // so we don't get called again
	}
}

DefaultProperties
{
	ProjFlightTemplate=ParticleSystem'Grow_John_Assets.Effects.Food_Trail_Effect'
	ProjExplosionTemplate=ParticleSystem'Grow_John_Assets.Effects.Food_Splat_Effect'
	Damage=30
	Physics=PHYS_Falling

	Begin Object Name=CollisionCylinder
		CollisionRadius=18
		CollisionHeight=18
	End Object
	/*Begin Object Class=StaticMeshComponent Name=FoodComponent
		BlockActors=false
		BlockActors=false
		CollideActors=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		HiddenGame=false
		HiddenEditor=true
		LightingChannels=(Dynamic=true)
		Scale3D=(X=1.0,Y=1.0,Z=1.0)
	End Object
	MeshParam = FoodComponent
	Components.Add(FoodComponent)*/
	DecalWidth=256
	DecalHeight=256
	bAdvanceExplosionEffect = true
}
