class GWProj_Food_Chilli extends GWProj_Food;


/* HurtRadius()
 Hurt locally authoritative actors within the radius.
*/
simulated function bool HurtRadius
(
	float DamageAmount,
								    float InDamageRadius,
				    class<DamageType> DamageType,
									float Momentum,
									vector HurtOrigin,
									optional actor IgnoredActor,
									optional Controller InstigatedByController = Instigator != None ? Instigator.Controller : None,
									optional bool bDoFullDamage
)
{
	local Actor	Victim;
	local bool bCausedDamage;
	local TraceHitInfo HitInfo;
	local StaticMeshComponent HitComponent;
	local KActorFromStatic NewKActor;

	if ( bHurtEntry )
		return false;

	bCausedDamage = false;
	if (InstigatedByController == None)
	{
		InstigatedByController = InstigatorController;
	}

	// if ImpactedActor is set, we actually want to give it full damage, and then let him be ignored by super.HurtRadius()
	if ( (ImpactedActor != None) && (ImpactedActor != self)  )
	{
		ImpactedActor.TakeRadiusDamage(InstigatedByController, DamageAmount, InDamageRadius, DamageType, Momentum, HurtOrigin, true, self);
		bCausedDamage = ImpactedActor.bProjTarget;
		if(GWPawn(ImpactedActor) != none && ImpactedActor != Instigator) {
			GWPawn(ImpactedActor).IncrementStatusEffect(class'GWConstants'.default.FoodStats[FT].EffectType, InstigatedByController);
		}
	}

	bHurtEntry = true;
	foreach VisibleCollidingActors( class'Actor', Victim, InDamageRadius, HurtOrigin,,,,, HitInfo )
	{
		if ( Victim.bWorldGeometry )
		{
			// check if it can become dynamic
			// @TODO note that if using StaticMeshCollectionActor (e.g. on Consoles), only one component is returned.  Would need to do additional octree radius check to find more components, if desired
			HitComponent = StaticMeshComponent(HitInfo.HitComponent);
			if ( (HitComponent != None) && HitComponent.CanBecomeDynamic() )
			{
				NewKActor = class'KActorFromStatic'.Static.MakeDynamic(HitComponent);
				if ( NewKActor != None )
				{
					Victim = NewKActor;
				}
			}
		}
		if ( !Victim.bWorldGeometry && (Victim != self) && (Victim != IgnoredActor) && (Victim.bCanBeDamaged || Victim.bProjTarget) )
		{
			Victim.TakeRadiusDamage(InstigatedByController, DamageAmount, InDamageRadius, DamageType, Momentum, HurtOrigin, bDoFullDamage, self);
			if(GWPawn(Victim) != none && Victim != Instigator) {
				GWPawn(Victim).IncrementStatusEffect(class'GWConstants'.default.FoodStats[FT].EffectType, InstigatedByController);
			}
			bCausedDamage = bCausedDamage || Victim.bProjTarget;
		}
	}
	bHurtEntry = false;
	return ( bCausedDamage );
}

DefaultProperties
{
	DamageRadius=300
}
