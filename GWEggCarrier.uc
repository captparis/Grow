class GWEggCarrier extends UTWeapon;

simulated function bool TryPutDown() {
	return false;
}
simulated function bool DoOverrideNextWeapon()
{
	if(UTPlayerReplicationInfo(Instigator.PlayerReplicationInfo).bHasFlag)
		return true;
	return false;
}
simulated function float GetWeaponRating()
{
	if(UTPlayerReplicationInfo(Instigator.PlayerReplicationInfo).bHasFlag)
		return 1000;
	return -1000;
}

simulated function CustomFire() {
	local UTCarriedObject Flag;
	local Vector Direction;

	if( Role == ROLE_Authority ) {
		if(UTPlayerReplicationInfo(Instigator.PlayerReplicationInfo).bHasFlag) {
			Flag = UTPlayerReplicationInfo(Instigator.PlayerReplicationInfo).GetFlag();
			Flag.Drop();
			Direction = Vector(GetAdjustedAim( GetPhysicalFireStartLoc()));
			Flag.SetRotation(Rotator(Direction));

			Flag.Velocity = 2000 * Direction + vect3d(0,0,1) * 400;
		}
	}
	`Log("Egg tossed");
	//Instigator.InvManager.RemoveFromInventory(self);
}
simulated event Destroyed()
{
	`Log("Destroying Weapon");
	super.Destroyed();
}
simulated event Tick( float DeltaTime ) {
	//`Log("Ammo Count:"@AmmoCount);
	if(!UTPlayerReplicationInfo(Instigator.PlayerReplicationInfo).bHasFlag) {
		//GWPawn(Owner).InvManager.NextWeapon();
	//	`Log("Destroying Weapon. No Egg");

	}
	super.Tick(DeltaTime);
}

simulated function WeaponEmpty()
{
	// If we were firing, stop
	if ( IsFiring() )
	{
		GotoState('Active');
	}

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
	if(UTPlayerReplicationInfo(Instigator.PlayerReplicationInfo).bHasFlag)
		return true;
	return false;
}

simulated function bool HasAmmo( byte FireModeNum, optional int Amount )
{
	if(UTPlayerReplicationInfo(Instigator.PlayerReplicationInfo).bHasFlag)
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

	InstantHitMomentum(0)=+60000.0

	WeaponFireTypes(0)=EWFT_Custom
	WeaponFireTypes(1)=EWFT_Custom
	//WeaponProjectiles(1)=class'UTGameContent.UTProj_ShockBall'

	InstantHitDamage(0)=0
	FireInterval(0)=+0.77
	FireInterval(1)=+0.6
	InstantHitDamageTypes(0)=none
	InstantHitDamageTypes(1)=None

	//InventoryWeight=1
	ShotCost(0)=1
	ShotCost(1)=1
	AmmoCount=1
	MaxAmmoCount=1
	InventoryGroup=9
}
