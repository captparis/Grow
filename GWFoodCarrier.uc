class GWFoodCarrier extends UTWeapon
	dependson(GWConstants);

//var SFoodInfo FI;
var class<GWSoundGroup> SoundGroupClass;
var int SpitSize;

simulated function bool TryPutDown() {
	return false;
}
simulated function bool DoOverrideNextWeapon()
{
	if(HasAnyAmmo())
		return true;
	return false;
}
simulated function float GetWeaponRating()
{
	if(HasAnyAmmo())
		return 1000;
	return -1000;
}

simulated function ChewFire() {
	local SFoodInfo FI;
	IncrementFlashCount();
	FI = class'GWConstants'.default.FoodStats[GWPawn(Owner).CurrentEatenFoodType];
	GWPawn(Owner).EatPart.ActivateSystem(false);
	
	GWPawn(Owner).Health = Clamp(GWPawn(Owner).Health + FI.HealAmount, GWPawn(Owner).Health, GWPawn(Owner).HealthMax);
	GWPawn(Owner).IncrementAbility(FI.StatName, FI.FoodAmount);
	if(FI.EffectType != EFFECT_FOOD_NONE)
		GWPawn(Owner).IncrementStatusEffect(FI.EffectType, Instigator.Controller);
	GWPawn(Owner).CurrentEatenFoodMesh.SetScale(float(Max(AmmoCount, 1)) / FI.Size);
	if(Role == ROLE_Authority && GWFeastGame(WorldInfo.Game) != none) {
		WorldInfo.Game.ScoreObjective(GWPawn(Owner).PlayerReplicationInfo, 1);
	}

	//SoundGroupClass.static.PlayChewSound(GWPawn(Owner)); 
}
simulated function SpitFire() {
	local GWProj_Food	SpawnedProjectile;
	
	SpawnedProjectile = GWProj_Food(ProjectileFire());
	
	if( SpawnedProjectile != None && !SpawnedProjectile.bDeleteMe && Role == ROLE_Authority) {
		SpawnedProjectile.InitStats(GWPawn(Owner).CurrentEatenFoodType, SpitSize);
	}
	GWPawn(Owner).CurrentEatenFoodType = FOOD_NONE;
	GWPawn(Owner).ClientSetFood(FOOD_NONE, false);
	//SoundGroupClass.static.PlaySpitSound(GWPawn(Owner)); 
}
function class<Projectile> GetProjectileClass()
{
	return class'GWConstants'.default.FoodStats[GWPawn(Owner).CurrentEatenFoodType].ProjClass;
}
simulated function IncrementFlashCount()
{
	if( Instigator != None )
	{
		if(CurrentFireMode == 2)
			Instigator.IncrementFlashCount( Self, 3 );
		else
			Instigator.IncrementFlashCount( Self, 4 );
	}
}
simulated event Destroyed()
{
	`Log("Destroying Weapon");
	super.Destroyed();
}

simulated event PostBeginPlay() {
	super.PostBeginPlay();
	if(SoundGroupClass == none) {
		//`Log(name@Owner);
		SoundGroupClass = class<GWSoundGroup>(GWPawn(Owner).SoundGroupClass);
	}
}

simulated function FireAmmunition()
{
	//LastWeaponFire[CurrentFireMode] = WorldInfo.TimeSeconds;
	switch(CurrentFireMode) {
	case 0:
	case 1:
		GWPawn(Instigator).TriggerAnim(ANIM_SPIT);
		break;
	case 2:
		GWPawn(Instigator).TriggerAnim(ANIM_CHEW);
		break;
	}
	PlayFiringSound();
	FireWeapon();
	UTInventoryManager(InvManager).OwnerEvent('FiredWeapon');
}

simulated function PlayFiringSound()
{
	if(SoundGroupClass == none) {
		//`Log(name@Owner);
		SoundGroupClass = class<GWSoundGroup>(GWPawn(Owner).SoundGroupClass);
	}
	switch(CurrentFireMode) {
	case 0:
	case 1:
		SoundGroupClass.static.PlaySpitSound(GWPawn(Owner));
		break;
	case 2:
		SoundGroupClass.static.PlayChewSound(GWPawn(Owner));
		break;
	}
	MakeNoise(1.0);
}

/**
 * FireAmmunition: Perform all logic associated with firing a shot
 * - Fires ammunition (instant hit or spawn projectile)
 * - Consumes ammunition
 *
 * Network: LocalPlayer and Server
 */

simulated function FireWeapon()
{
	// Use ammunition to fire
	ConsumeAmmo( CurrentFireMode );

	// Handle the different fire types
	switch(CurrentFireMode) {
	case 0:
	case 1:
		SpitFire();
		break;
	case 2:
		ChewFire();
		break;
	}

	NotifyWeaponFired( CurrentFireMode );
}

function ConsumeAmmo( byte FireModeNum )
{
	// Subtract the Ammo
	if(FireModeNum == 0 || FireModeNum == 1) {
		SpitSize = AmmoCount;
		AddAmmo(-AmmoCount);
	} else {
		AddAmmo(-1);
	}
}

simulated function WeaponEmpty()
{
	// If we were firing, stop
	if ( IsFiring() )
	{
		GotoState('Active');
	}

	GWPawn(Owner).CurrentEatenFoodType = FOOD_NONE;
	//GWPawn(Owner).Health = Clamp(GWPawn(Owner).Health + (FI.HealAmount * FI.Size), GWPawn(Owner).Health, GWPawn(Owner).HealthMax);
	//GWPawn(Owner).IncrementAbility(FI.StatName, (FI.FoodAmount * FI.Size));
	GWPawn(Owner).ClientSetFood(FOOD_NONE, false);

	if ( Instigator != none && Instigator.IsLocallyControlled() )
	{
		Instigator.InvManager.SwitchToBestWeapon( true );
	}
	Destroy();
}

function DropFrom(vector StartLocation, vector StartVelocity)
{

	// Become inactive
	GotoState('Inactive');

	// Stop Firing
	ForceEndFire();
	// Detach weapon components from instigator
	DetachWeapon();

	// tell the super to DropFrom() which will
	// should remove the item from our inventory
	Super(Inventory).DropFrom(StartLocation, StartVelocity);

	AIController = None;
}

/**
 * hook to override Previous weapon call.
 */
simulated function bool DoOverridePrevWeapon()
{
	if(HasAnyAmmo())
		return true;
	return false;
}

DefaultProperties
{
	// Weapon SkeletalMesh
	Begin Object class=AnimNodeSequence Name=MeshSequenceA
	End Object

	DroppedPickupClass=none
	// Weapon SkeletalMesh
	Begin Object Name=FirstPersonMesh
		SkeletalMesh=SkeletalMesh'WP_ShockRifle.Mesh.SK_WP_ShockRifle_1P'
		AnimSets(0)=AnimSet'WP_ShockRifle.Anim.K_WP_ShockRifle_1P_Base'
		Animations=MeshSequenceA
		Rotation=(Yaw=-16384)
		FOV=60.0
	End Object

	InstantHitMomentum(0)=+60000.03

	WeaponFireTypes(0)=EWFT_Custom
	WeaponFireTypes(1)=EWFT_Custom
	WeaponFireTypes(2)=EWFT_Custom
	FiringStatesArray(2)=WeaponFiring
	//WeaponProjectiles(1)=class'UTGameContent.UTProj_ShockBall'

	InstantHitDamage(0)=0
	FireInterval(0)=+0.5
	FireInterval(1)=+0.5
	FireInterval(2)=+0.5
	InstantHitDamageTypes(0)=none
	InstantHitDamageTypes(1)=None

	//InventoryWeight=1
	ShotCost(0)=1
	ShotCost(1)=1
	ShotCost(2)=1
	AmmoCount=5
	MaxAmmoCount=100
	InventoryGroup=9
}
