class GWWeap_SkillPower extends GWWeap_Ranged;

//Weapon Handling in GWPawn_SkillPower
simulated function AbilityFire() {
	if(CurrentFireMode == FIREMODE_ABILITY && Owner.Physics == PHYS_Falling) {
		GWPawn(Instigator).TriggerAnim(ANIM_ABILITY_END);
		return;
	}
}

simulated function FireAmmunition()
{
	`Log("FireAmmunition"@CurrentFireMode);
	if(CurrentFireMode == FIREMODE_ABILITY && (Owner.Physics == PHYS_Falling || Owner.Physics == PHYS_Swimming)) {
		return;
	}
	if(CurrentFireMode == 0) {
		if(Instigator.IsInState('PlayerAbility')) {
			super.FireAmmunition();
		} else {
			return;
		}
	} else if(CurrentFireMode == 1) {
		LastWeaponFire[CurrentFireMode] = WorldInfo.TimeSeconds;
	
		if(Instigator.IsInState('PlayerAbility')) {
			GWPawn(Instigator).TriggerAnim(ANIM_ABILITY_END);
		} else {
			GWPawn(Instigator).TriggerAnim(ANIM_ABILITY_START);
		}

		UTInventoryManager(InvManager).OwnerEvent('FiredWeapon');
	} else if(CurrentFireMode == FIREMODE_EAT) {
		if(Instigator.IsInState('PlayerAbility')) {
			return;
		} else {
			super.FireAmmunition();
		}
	} else {
		super.FireAmmunition();
	}
}

/*simulated function float GetCooldownPerc() {
	if(Instigator.IsInState('PlayerAbility')) {
		super.GetCooldownPerc();
	}
	return 0;
}*/

simulated function PutDownWeapon()
{
	`Log("Putdown Weapon"@Instigator.IsInState('PlayerAbility'));
	super.PutDownWeapon();
}

DefaultProperties
{
	EatExtent=(X=75,Y=50,Z=50)
	WeaponProjectiles(0)=class'Grow.GWProj_SkillPower'
	//WeaponProjectiles(1)=class'Grow.GWProj_SkillPowerSpecial'


	FireInterval(0)=0.7
	FireInterval(1)=1
	ShotCost(1)=0
	WeaponFireTypes(1)=EWFT_Projectile
	
	//WeaponFireSnd[0]=SoundCue'Grow_Sounds.attacklow_Cue'
	//WeaponFireSnd[1]=SoundCue'Grow_Sounds.attacklow_Cue'
}
