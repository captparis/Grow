class GWWeap_Beam extends GWWeap_Ranged;

/** The Particle System Template for the Beam */
var particleSystem BeamTemplate[2];

/** Holds the Emitter for the Beam */
var ParticleSystemComponent BeamEmitter[2];

/** Where to attach the Beam */
var name BeamSockets[2];

/** The name of the EndPoint parameter */
var name EndPointParamName;

/** Animations to play before firing the beam */
var name	BeamPreFireAnim[2];
var name	BeamFireAnim[2];
var name	BeamPostFireAnim[2];

var ForceFeedbackWaveform	BeamWeaponFireWaveForm;

/** Holds the actor that this weapon is linked to. */
var Actor LinkedTo;
/** Holds the component we hit on the linked actor, for determining the linked beam endpoint on multi-component actors (such as Onslaught powernodes) */
var PrimitiveComponent LinkedComponent;

/** players holding link guns within this distance of each other automatically link up */
var float WeaponLinkDistance;

/** Holds the list of link guns linked to this weapon */
var array<GWWeap_Beam> LinkedList;	// I made a funny Hahahahah :)

/** Holds the Actor currently being hit by the beam */
var Actor	Victim;

/** Holds the current strength (in #s) of the link */
var repnotify int LinkStrength;

/** Holds the amount of flexibility of the link beam */
var float 	LinkFlexibility;

/** Holds the amount of time to maintain the link before breaking it.  This is important so that you can pass through
    small objects without having to worry about regaining the link */
var float 	LinkBreakDelay;

/** Momentum transfer for link beam (per second) */
var float	MomentumTransfer;

/** beam ammo consumption (per second) */
var float BeamAmmoUsePerSecond;

/** This is a time used with LinkBrekaDelay above */
var float	ReaccquireTimer;

/** true if beam currently hitting target */
var bool	bBeamHit;

/** whether link gun should auto-recharge */
var bool	bAutoCharge;

/** recharge rate in ammo per second */
var float RechargeRate;

/** saved partial damage (in case of high frame rate */
var float	SavedDamage;

/** saved partial ammo use */
var float SavedAmmoUse;

/** minimum SavedDamage before we actually apply it
 * (needs to be large enough to counter any scaling factors that might reduce to below 1)
 */
var float MinimumDamage;

/** Saved partial ammo consumption */
var float	PartialAmmo;

var MaterialInstanceConstant WeaponMaterialInstance;

var SoundCue StartAltFireSound;
var SoundCue EndAltFireSound;

var UTEmitter BeamEndpointEffect;

/** activated whenever we're linked to other players (LinkStrength > 1) */
var ParticleSystemComponent PoweredUpEffect;

/** socket to attach PoweredUpEffect to on our mesh */
var name PoweredUpEffectSocket;

/** Where beam that isn't hitting a target is currently attached */
var vector BeamAttachLocation;

/** Last time new beam attachment location was calculated */
var float  LastBeamAttachTime;

/** Normal for beam attachment */
var vector BeamAttachNormal;

/** Actor to which beam is being attached */
var actor  BeamAttachActor;

var ParticleSystem TeamMuzzleFlashTemplates[3];
var ParticleSystem HighPowerMuzzleFlashTemplate;

/** True if have picked up link booster */
var repnotify bool bFullPower;

/** team based colors for altfire beam when targeting a teammate */
var color LinkBeamColors[3];
/** team based systems for altfire beam when targetting a teammate*/
var ParticleSystem LinkBeamSystems[3];
/** templates for beam impact effect */
var ParticleSystem TeamBeamEndpointTemplates[3];

var int HealPoints;

replication
{
	if (bNetDirty)
		LinkedTo, LinkStrength, bBeamHit, bFullPower;
}

simulated function AddBeamEmitter()
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (BeamEmitter[CurrentFireMode] == None)
		{
			if (BeamTemplate[CurrentFireMode] != None)
			{
				BeamEmitter[CurrentFireMode] = new class'UTParticleSystemComponent';
				//BeamEmitter[CurrentFireMode].SetDepthPriorityGroup(SDPG_Foreground);
				BeamEmitter[CurrentFireMode].SetTemplate(BeamTemplate[CurrentFireMode]);
				//BeamEmitter[CurrentFireMode].SetHidden(false);
				BeamEmitter[CurrentFireMode].SetTickGroup( TG_PostUpdateWork );
				BeamEmitter[CurrentFireMode].bUpdateComponentInTick = true;
				BeamEmitter[CurrentFireMode].SetIgnoreOwnerHidden(TRUE);
				BeamEmitter[CurrentFireMode].SetOwnerNoSee(false);
				Instigator.Mesh.AttachComponentToSocket( BeamEmitter[CurrentFireMode],BeamSockets[CurrentFireMode] );
				//BeamEmitter[CurrentFireMode].ActivateSystem();
			}
		}
		else
		{
			BeamEmitter[CurrentFireMode].ActivateSystem();
		}
	}
}



/**
 * This function looks at who/what the beam is touching and deals with it accordingly.  bInfoOnly
 * is true when this function is called from a Tick.  It causes the link portion to execute, but no
 * damage/health is dealt out.
 */

simulated function UpdateBeam(float DeltaTime)
{
	local Vector		StartTrace, EndTrace, AimDir;
	local ImpactInfo	RealImpact, NearImpact;

	// define range to use for CalcWeaponFire()
	StartTrace	= Instigator.GetWeaponStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));
	EndTrace	= StartTrace + AimDir * GetTraceRange();

	// Trace a shot
	RealImpact = CalcWeaponFire( StartTrace, EndTrace );
	bUsingAimingHelp = false;
	//`Log("Beam Target:"@RealImpact.HitActor@"in"@StartTrace@"-"@EndTrace);
	if ( (RealImpact.HitActor == None) || !RealImpact.HitActor.bProjTarget )
	{
		// console aiming help
		NearImpact = InstantAimHelp(StartTrace, EndTrace, RealImpact);

	}
	if ( NearImpact.HitActor != None )
	{
		bUsingAimingHelp = true;
		ProcessBeamHit(StartTrace, AimDir, NearImpact, DeltaTime);
		UpdateBeamEmitter(NearImpact.HitLocation, NearImpact.HitNormal, NearImpact.HitActor);
	}
	else
	{
		// Allow children to process the hit
		ProcessBeamHit(StartTrace, AimDir, RealImpact, DeltaTime);
		UpdateBeamEmitter(RealImpact.HitLocation, RealImpact.HitNormal, RealImpact.HitActor);
	}
}

simulated function DisplayDebug(HUD HUD, out float out_YL, out float out_YPos)
{
	super.DisplayDebug(Hud, out_YL, out_YPos);

	if (BeamEmitter[CurrentFireMode] != none)
	{
	    HUD.Canvas.SetPos(4,out_YPos);
	    HUD.Canvas.DrawText("Beam:"@BeamEmitter[CurrentFireMode]@BeamEmitter[CurrentFireMode].HiddenGame);
	    out_YPos+= out_YL;
	}
}

simulated function PostBeginPlay()
{

	Super.PostBeginPlay();

	if (Role == ROLE_Authority)
	{
		SetTimer(0.25, true, 'FindLinkedWeapons');
	}
}

simulated function ParticleSystem GetTeamMuzzleFlashTemplate(byte TeamNum)
{
	if (TeamNum >= ArrayCount(default.TeamMuzzleFlashTemplates))
	{
		TeamNum = ArrayCount(default.TeamMuzzleFlashTemplates) - 1;
	}
	return default.TeamMuzzleFlashTemplates[TeamNum];
}

simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional Name SocketName)
{
	Super.AttachWeaponTo(MeshCpnt, SocketName);

	if (PoweredUpEffect != None && !PoweredUpEffect.bAttached)
	{
		Instigator.Mesh.AttachComponentToSocket(PoweredUpEffect, PoweredUpEffectSocket);
	}
}

simulated function UpdateBeamEmitter(vector FlashLocation, vector HitNormal, actor HitActor)
{
	local color BeamColor;
	local ParticleSystem BeamSystem, BeamEndpointTemplate, MuzzleFlashTemplate;
	local byte TeamNum;
	local LinearColor LinColor;

	if (LinkedTo != None)
	{
		FlashLocation = GetLinkedToLocation();
	}

	if (BeamEmitter[CurrentFireMode] != none)
	{
		SetBeamEmitterHidden( false/*!UTPawn(Instigator).IsFirstPerson()*/ );
		BeamEmitter[CurrentFireMode].SetVectorParameter(EndPointParamName,FlashLocation);
		//BeamEmitter[CurrentFireMode].SetVectorParameter(EndPointParamName,vect3d(100, 100, 100));
		//`Log("FlashLocation:"@FlashLocation);
		//BeamEmitter[CurrentFireMode].GetVectorParameter(EndPointParamName,FlashLocation);
		//`Log("RealFlashLocation:"@FlashLocation);
	}

	if (LinkedTo != None && WorldInfo.GRI.GameClass.Default.bTeamGame)
	{
		TeamNum = Instigator.GetTeamNum();
		GetTeamBeamInfo(TeamNum, BeamColor, BeamSystem, BeamEndpointTemplate);
		MuzzleFlashTemplate = GetTeamMuzzleFlashTemplate(TeamNum);
	}
	else
	{
		GetTeamBeamInfo(255, BeamColor, BeamSystem, BeamEndpointTemplate);

		MuzzleFlashTemplate = GetTeamMuzzleFlashTemplate(255);
	}

	if (BeamEmitter[CurrentFireMode] != None)
	{
		BeamEmitter[CurrentFireMode].SetColorParameter('Link_Beam_Color', BeamColor);
		if (BeamEmitter[CurrentFireMode].Template != BeamSystem)
		{
			BeamEmitter[CurrentFireMode].SetTemplate(BeamSystem);
		}
	}

	if (MuzzleFlashPSC != None)
	{
		MuzzleFlashPSC.SetColorParameter('Link_Beam_Color', BeamColor);
		if (MuzzleFlashTemplate != MuzzleFlashPSC.Template)
		{
			MuzzleFlashPSC.SetTemplate(MuzzleFlashTemplate);
		}
	}
	if (UTLinkGunMuzzleFlashLight(MuzzleFlashLight) != None)
	{
		UTLinkGunMuzzleFlashLight(MuzzleFlashLight).SetTeam((LinkedTo != None && WorldInfo.GRI.GameClass.Default.bTeamGame) ? Instigator.GetTeamNum() : byte(255));
	}

	if (WeaponMaterialInstance != None)
	{
		LinColor = ColorToLinearColor(BeamColor);
		WeaponMaterialInstance.SetVectorParameterValue('TeamColor', LinColor);
	}

	if (WorldInfo.NetMode != NM_DedicatedServer && Instigator != None && Instigator.IsFirstPerson())
	{
		if (BeamEndpointEffect != None && !BeamEndpointEffect.bDeleteMe)
		{
			BeamEndpointEffect.SetLocation(FlashLocation);
			BeamEndpointEffect.SetRotation(rotator(HitNormal));
			if (BeamEndpointEffect.ParticleSystemComponent.Template != BeamEndpointTemplate)
			{
				BeamEndpointEffect.SetTemplate(BeamEndpointTemplate, true);
			}
		}
		else
		{
			BeamEndpointEffect = Spawn(class'UTEmitter', self,, FlashLocation, rotator(HitNormal));
			BeamEndpointEffect.SetTemplate(BeamEndpointTemplate, true);
			BeamEndpointEFfect.LifeSpan = 0.0;
		}
		if(BeamEndpointEffect != none)
		{
			if(HitActor != none && UTPawn(HitActor) == none)
			{
				BeamEndpointEffect.SetFloatParameter('Touch',1);
			}
			else
			{
				BeamEndpointEffect.SetFloatParameter('Touch',0);
			}
		}
	}
}

/**
 * When destroyed, make sure we clean ourselves from any chains
 */
simulated event Destroyed()
{
	super.Destroyed();
	Unlink();
	LinkedComponent = None;

	KillEndpointEffect();
}

simulated function SetBeamEmitterHidden(bool bHide)
{
	if (BeamEmitter[CurrentFireMode] != None && bHide)
	{
		KillEndpointEffect();
	}

	if (BeamEmitter[CurrentFireMode] != none)
		BeamEmitter[CurrentFireMode].SetHidden(bHide);
}

simulated function KillBeamEmitter()
{
	if (BeamEmitter[CurrentFireMode] != none)
	{
		BeamEmitter[CurrentFireMode].SetHidden(true);
		BeamEmitter[CurrentFireMode].DeactivateSystem();
	}

	KillEndpointEffect();
}

/** deactivates the beam endpoint effect, if present */
simulated function KillEndpointEffect()
{
	if (BeamEndpointEffect != None)
	{
		BeamEndpointEffect.ParticleSystemComponent.DeactivateSystem();
		BeamEndpointEffect.LifeSpan = 2.0;
		BeamEndpointEffect = None;
	}
}

function ConsumeAmmo( byte FireModeNum )
{
	if ( bAutoCharge && (Role == ROLE_Authority) )
	{
		SetTimer(RechargeRate+1.0, false, 'RechargeAmmo');
	}
	super.ConsumeAmmo(FireModeNum);
}

/** ConsumeBeamAmmo()
consume beam ammo per tick.
*/
function ChargeAbility(float Amount)
{
	PartialAmmo += Amount;
	if (PartialAmmo >= 1.0)
	{
		AddAmmo(int(PartialAmmo));
		PartialAmmo -= int(PartialAmmo);
	}
}

function RechargeAmmo() {}

/**
 * Process the hit info
 */
simulated function ProcessBeamHit(vector StartTrace, vector AimDir, out ImpactInfo TestImpact, float DeltaTime)
{
	local float DamageAmount;
	local vector PushForce, ShotDir, SideDir; //, HitLocation, HitNormal, AttachDir;
	local UTPawn UTP;

	Victim = TestImpact.HitActor;

	// If we are on the server, attempt to setup the link
	if (Role == ROLE_Authority)
	{
		// Try linking
		AttemptLinkTo(Victim, TestImpact.HitInfo.HitComponent);

		// set the correct firemode on the pawn, since it will change when linked
		SetCurrentFireMode(CurrentFireMode);

		// if we do not have a link, set the flash location to whatever we hit
		// (if we do have one, AttemptLinkTo() will set the correct flash location for the Actor we're linked to)
		if (LinkedTo == None)
		{
			SetFlashLocation(TestImpact.HitLocation);
		}

		// cause damage or add health/power/etc.
		bBeamHit = false;

		// compute damage amount
		CalcLinkStrength();
		DamageAmount = InstantHitDamage[0];
		UTP = UTPawn(Instigator);
		if ( UTP != None )
		{
			DamageAmount = DamageAmount/UTP.FireRateMultiplier;
		}
		if ( LinkStrength > 1 )
		{
			DamageAmount *= FClamp(0.75*LinkStrength, 1.5, 2.0);
		}
		SavedDamage += DamageAmount * DeltaTime;
		DamageAmount = int(SavedDamage);
		if (DamageAmount >= MinimumDamage)
		{
			SavedDamage -= DamageAmount;
			if (LinkedTo != None)
			{
				LinkedTo.HealDamage(DamageAmount * Instigator.GetDamageScaling(), Instigator.Controller, InstantHitDamageTypes[0]);
				ChargeAbility(DamageAmount);
			}
			else
			{
				// If not on the same team, hurt them
				if (Victim != None && !WorldInfo.Game.GameReplicationInfo.OnSameTeam(Victim, Instigator))
				{
					bBeamHit = !Victim.bWorldGeometry;
					//`Log("Hit:"@Victim@Victim.bWorldGeometry);
					if ( DamageAmount > 0 )
					{
						ShotDir = Normal(TestImpact.HitLocation - Location);
						SideDir = Normal(ShotDir Cross vect(0,0,1));
						PushForce =  vect(0,0,1) + Normal(SideDir * (SideDir dot (TestImpact.HitLocation - Victim.Location)));
						PushForce *= (Victim.Physics == PHYS_Walking) ? 0.1*MomentumTransfer : DeltaTime*MomentumTransfer;
						Victim.TakeDamage(DamageAmount, Instigator.Controller, TestImpact.HitLocation, PushForce, InstantHitDamageTypes[0], TestImpact.HitInfo, self);
						if(Pawn(Victim) != none)
							ChargeAbility(DamageAmount);
					}
				}
			}
		}
	}
	else
	{
		// if we do not have a link, set the flash location to whatever we hit
		// (otherwise beam update will override with link location)
		if (LinkedTo == None)
		{
			SetFlashLocation(TestImpact.HitLocation);
		}
		else if (TestImpact.HitActor == LinkedTo && TestImpact.HitInfo.HitComponent != None)
		{
			// the linked component can't be replicated to the client, so set it here
			LinkedComponent = TestImpact.HitInfo.HitComponent;
		}
		if (Victim != None && (Victim.Role == ROLE_Authority) )
		{
			bBeamHit = !Victim.bWorldGeometry;
			if ( DamageAmount > 0 )
			{
				ShotDir = Normal(TestImpact.HitLocation - Location);
				SideDir = Normal(ShotDir Cross vect(0,0,1));
				PushForce =  vect(0,0,1) + Normal(SideDir * (SideDir dot (TestImpact.HitLocation - Victim.Location)));
				PushForce *= (Victim.Physics == PHYS_Walking) ? 0.1*MomentumTransfer : DeltaTime*MomentumTransfer;
				Victim.TakeDamage(DamageAmount, Instigator.Controller, TestImpact.HitLocation, PushForce, InstantHitDamageTypes[0], TestImpact.HitInfo, self);
			}
		}
	}
}

/**
 * Returns a vector that specifics the point of linking.
 */
simulated function vector GetLinkedToLocation()
{

	if (LinkedTo == None)
	{
		return vect(0,0,0);
	} else if (Pawn(LinkedTo) != None)
	{
		return LinkedTo.Location + Pawn(LinkedTo).BaseEyeHeight * vect(0,0,0.5);
	}
	else if (LinkedComponent != None)
	{
		return LinkedComponent.GetPosition();
	}
	else
	{
		return LinkedTo.Location;
	}
}

/**
 * This function looks at how the beam is hitting and determines if this person is linkable
 */
function AttemptLinkTo(Actor Who, PrimitiveComponent HitComponent)
{
	local UTVehicle UTV;
	local UTPawn P;
	local Vector 		StartTrace, EndTrace, V, HitLocation, HitNormal;
	local Actor			HitActor;

	// redirect to vehicle if owned by a vehicle and the vehicle allows it
	if( Who != none )
	{
		UTV = UTVehicle(Who.Owner);
		if (UTV != None && UTV.AllowLinkThroughOwnedActor(Who))
		{
			Who = UTV;
		}
	}

	// Check for linking to pawns
	UTV = UTVehicle(Who);
	if (UTV != None && UTV.bValidLinkTarget)
	{
		// Check teams to make sure they are on the same side or empty
		if ( WorldInfo.Game.GameReplicationInfo.OnSameTeam(UTV,Instigator) || (!UTV.bTeamLocked && UTV.CanEnterVehicle(Instigator)) )
		{
			if ( !WorldInfo.Game.GameReplicationInfo.OnSameTeam(UTV,Instigator)
				&& (Instigator.GetTeamNum() != 255) )
			{
				UTV.SetTeamNum( Instigator.GetTeamNum() );
			}
			LinkedComponent = HitComponent;
			if ( LinkedTo != UTV )
			{
				UnLink();
				LinkedTo = UTV;
				UTV.IncrementLinkedToCount();
			}
		}
		else
		{
			// Enemy got in the way, break any links
			UnLink();
		}
	}

	P = UTPawn(Who);
	if (P != None)
	{
		// Check teams to make sure they are on the same side or empty
		if ( WorldInfo.Game.GameReplicationInfo.OnSameTeam(P,Instigator))
		{
			LinkedComponent = HitComponent;
			if ( LinkedTo != P )
			{
				UnLink();
				LinkedTo = P;
			}
		}
		else
		{
			// Enemy got in the way, break any links
			UnLink();
		}
	}

	if (LinkedTo != None)
	{
		// Determine if the link has been broken for another reason
		if (LinkedTo.bDeleteMe || (Pawn(LinkedTo) != None && Pawn(LinkedTo).Health <= 0))
		{
			UnLink();
			return;
		}

		// if we were passed in LinkedTo, we know we hit it straight on already, so skip the rest
		if (LinkedTo != Who)
		{
			StartTrace = Instigator.GetWeaponStartTraceLocation();
			EndTrace = GetLinkedtoLocation();

			// First, check to see if we have skewed too much, or if the LinkedTo pawn has died and
			// we didn't get cleaned up.
			V = Normal(EndTrace - StartTrace);
			if ( V dot vector(Instigator.GetViewRotation()) < LinkFlexibility || VSize(EndTrace - StartTrace) > 1.5 * WeaponRange )
			{
				UnLink();
				return;
			}

			//  If something is blocking us and the actor, drop the link
			HitActor = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
			if (HitActor != none && HitActor != LinkedTo)
			{
				UnLink(true);		// In this case, use a delayed UnLink
			}
		}
	}

	// if we are linked, make sure the proper flash location is set
	if (LinkedTo != None)
	{
		SetFlashLocation(GetLinkedtoLocation());
	}
}

/**
 * Unlink this weapon from it's parent.  If bDelayed is true, it will give a
 * short delay before unlinking to allow the player to re-establish the link
 */
function UnLink(optional bool bDelayed)
{
	local UTVehicle V;

	if (!bDelayed)
	{
		V = UTVehicle(LinkedTo);
		if(V != none)
		{
			V.DecrementLinkedToCount();
		}
		LinkedTo = None;
		LinkedComponent = None;
	}
	else if (ReaccquireTimer <= 0)
	{
		// Set the Delay timer
		ReaccquireTimer = LinkBreakDelay;
	}
}

/** checks for nearby friendly link gun users and links to them */
function FindLinkedWeapons()
{
	local UTPawn P;
	local GWWeap_Beam Link;

	LinkedList.length = 0;
	if (Instigator != None && (bReadyToFire() || IsFiring()))
	{
		foreach WorldInfo.AllPawns(class'UTPawn', P, Instigator.Location, WeaponLinkDistance)
		{
			if (P != Instigator && !P.bNoWeaponFiring && P.DrivenVehicle == None)
			{
				Link = GWWeap_Beam(P.Weapon);
				if (Link != None && WorldInfo.GRI.OnSameTeam(Instigator, P) && FastTrace(P.Location, Instigator.Location))
				{
					LinkedList[LinkedList.length] = Link;
				}
			}
		}
	}
	CalcLinkStrength();

	if (WorldInfo.NetMode != NM_DedicatedServer && PoweredUpEffect != None)
	{
		if (LinkStrength > 1)
		{
			if (!PoweredUpEffect.bIsActive)
			{
				PoweredUpEffect.ActivateSystem();
			}
		}
		else if (PoweredUpEffect.bIsActive)
		{
			PoweredUpEffect.DeactivateSystem();
		}
	}
}

/** gets a list of the entire link chain */
function GetLinkedWeapons(out array<GWWeap_Beam> LinkedWeapons)
{
	local int i;

	LinkedWeapons[LinkedWeapons.length] = self;
	for (i = 0; i < LinkedList.length; i++)
	{
		if (LinkedWeapons.Find(LinkedList[i]) == INDEX_NONE)
		{
			LinkedList[i].GetLinkedWeapons(LinkedWeapons);
		}
	}
}

/** this function figures out the strength of this link */
function CalcLinkStrength()
{
	local array<GWWeap_Beam> LinkedWeapons;

	GetLinkedWeapons(LinkedWeapons);
	LinkStrength = LinkedWeapons.length;
}

simulated function ChangeVisibility(bool bIsVisible)
{
	Super.ChangeVisibility(bIsVisible);

	if (PoweredUpEffect != None)
	{
		PoweredUpEffect.SetHidden(!bIsVisible);
	}
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'LinkStrength')
	{
		if (LinkStrength > 1)
		{
			if (!PoweredUpEffect.bIsActive)
			{
				PoweredUpEffect.ActivateSystem();
			}
		}
		else if (PoweredUpEffect.bIsActive)
		{
			PoweredUpEffect.DeactivateSystem();
		}
	}
	else if ( VarName == 'bFullPower' )
	{
		if ( bFullPower )
			BoostPower();
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

/*********************************************************************************************
 * State WeaponFiring
 * See UTWeapon.WeaponFiring
 *********************************************************************************************/

simulated state WeaponSprayFiring
{
	/** view shaking for the beam mode is handled in RefireCheckTimer() */
	simulated function ShakeView();

	/**
	 * In this weapon, RefireCheckTimer consumes ammo and deals out health/damage.  It's not
	 * concerned with the effects.  They are handled in the tick()
	 */
	simulated function RefireCheckTimer()
	{
		local UTPlayerController PC;

		// If weapon should keep on firing, then do not leave state and fire again.
		if( ShouldRefire() )
		{
			// trigger a view shake for the local player here, because effects are called every tick
			// but we don't want to shake that often
			PC = UTPlayerController(Instigator.Controller);
			if (PC != None && LocalPlayer(PC.Player) != None && CurrentFireMode < FireCameraAnim.length && FireCameraAnim[CurrentFireMode] != None)
			{
				PC.PlayCameraAnim(FireCameraAnim[CurrentFireMode], (GetZoomedState() > ZST_ZoomingOut) ? PC.GetFOVAngle() / PC.DefaultFOV : 1.0);
			}
			return;
		}

		// Otherwise we're done firing, so go back to active state.
		GotoState('Active');

		// if out of ammo, then call weapon empty notification
		if( !HasAnyAmmo() )
		{
			WeaponEmpty();
		}
	}

	simulated function PlayFireEffects( byte FireModeNum, optional vector HitLocation )
	{
		local UTPlayerController PC;

		// Start muzzle flash effect
		CauseMuzzleFlash();

	    // Play controller vibration
		PC = UTPlayerController(Instigator.Controller);
	    if( PC != None && LocalPlayer(PC.Player) != None )
	    {
		    // only do rumble if we are a player controller
		    PC.ClientPlayForceFeedbackWaveform( BeamWeaponFireWaveForm );
	    }

		ShakeView();
	}

	event OnAnimEnd(AnimNodeSequence SeqNode, float PlayedTime, float ExcessTime)
	{
		if ((SeqNode == None || SeqNode.AnimSeqName != BeamFireAnim[CurrentFireMode]) && BeamFireAnim[CurrentFireMode] != '')
		{
			PlayWeaponAnimation(BeamFireAnim[CurrentFireMode],1.0,true);
		}
	}


	simulated function bool IsFiring()
	{
		return true;
	}

	simulated function bool TryPutDown()
	{
		bWeaponPutDown = true;
		return false;
	}
	/**
	 * When done firing, we have to make sure we unlink the weapon.
	 */
	simulated function EndFire(byte FireModeNum)
	{
		UnLink();
		Global.EndFire(FireModeNum);

		if ( bWeaponPutDown )
		{
			// if switched to another weapon, put down right away
			GotoState('WeaponPuttingDown');
			return;
		}
		else
		{
			GotoState('Active');
		}
	}

	simulated function SetCurrentFireMode(byte FiringModeNum)
	{
		local byte InstigatorFireMode;

		CurrentFireMode = FiringModeNum;

		// on the pawn, set a value of 2 if we're linked so the weapon attachment knows the difference
		// and a value of 3 if we're not linked to anyone but others are linked to us
		if (Instigator != None)
		{
			if (CurrentFireMode == 0)
			{
				if (LinkedTo != None)
				{
					InstigatorFireMode = 2;
				}
				else
				{
					CalcLinkStrength();
					if ( (LinkStrength > 1) || (Instigator.DamageScaling >= 2.0) )
					{
						if ( bBeamHit )
							InstigatorFireMode = 4;
						else
							InstigatorFireMode = 3;
					}
					else
					{
						if ( bBeamHit )
							InstigatorFireMode = 5;
						else
							InstigatorFireMode = CurrentFireMode;
					}
				}
			}
			else
			{
				InstigatorFireMode = CurrentFireMode;
			}

			Instigator.SetFiringMode(Self, InstigatorFireMode);
		}
	}

	function SetFlashLocation(vector HitLocation)
	{
		Global.SetFlashLocation(HitLocation);
		// SetFlashLocation() resets Instigator's FiringMode so we need to make sure our overridden value stays applied
		SetCurrentFireMode(CurrentFireMode);
	}

	/**
	 * Update the beam and handle the effects
	 * FIXMESTEVE MOVE TO TICKSPECIAL
	 */
	simulated function Tick(float DeltaTime)
	{
		// If we are in danger of losing the link, check to see if
		// time has run out.
		if ( ReaccquireTimer > 0 )
		{
	    		ReaccquireTimer -= DeltaTime;
	    		if (ReaccquireTimer <= 0)
	    		{
		    		ReaccquireTimer = 0.0;
		    		UnLink();
		    	}
		}

		// Retrace everything and see if there is a new LinkedTo or if something has changed.
		UpdateBeam(DeltaTime);
	}

	simulated function BeginState(Name PreviousStateName)
	{
		local UTPawn POwner;

		`LogInv("PreviousStateName:" @ PreviousStateName);

		// Fire the first shot right away
		RefireCheckTimer();
		TimeWeaponFiring( CurrentFireMode );

		if (BeamPreFireAnim[CurrentFireMode] != '')
		{
			PlayWeaponAnimation( BeamPreFireAnim[CurrentFireMode], 1.0);
		}
		else if (BeamFireAnim[CurrentFireMode] != '')
		{
			PlayWeaponAnimation( BeamFireAnim[CurrentFireMode], 1.0);
		}

		POwner = UTPawn(Instigator);
		if (POwner != None)
		{
			AddBeamEmitter();
			POwner.SetWeaponAmbientSound(WeaponFireSnd[CurrentFireMode]);
		}

		WeaponPlaySound(StartAltFireSound);
	}

	simulated function EndState(Name NextStateName)
	{
		local color EffectColor;
		local LinearColor LinEffectColor;
		local UTPawn POwner;
		local UTPlayerController PC;

		`LogInv("NextStateName:" @ NextStateName);
		WeaponPlaySound(EndAltFireSound);

		POwner = UTPawn(Instigator);
		if (POwner != None)
		{
			POwner.SetWeaponAmbientSound(None);
		}

		ClearTimer('RefireCheckTimer');
		ClearFlashLocation();

		if (BeamPostFireAnim[CurrentFireMode] != '')
		{
			PlayWeaponAnimation( BeamPostFireAnim[CurrentFireMode], 1.0);
		}

	    // Stop controller vibration
		PC = UTPlayerController(Instigator.Controller);
	    if( PC != None && LocalPlayer(PC.Player) != None )
	    {
		    // only do rumble if we are a player controller
		    PC.ClientStopForceFeedbackWaveform( BeamWeaponFireWaveForm );
	    }

		super.EndState(NextStateName);

		KillBeamEmitter();

		ReaccquireTimer = 0.0;
		UnLink();
		Victim = None;

		// reset material and muzzle flash to default color
		GetTeamBeamInfo(255, EffectColor);
		if (WeaponMaterialInstance != None)
		{
			LinEffectColor = ColorToLinearColor(EffectColor);
			WeaponMaterialInstance.SetVectorParameterValue('TeamColor', LinEffectColor);
		}
		if (MuzzleFlashPSC != None)
		{
			MuzzleFlashPSC.ClearParameter('Link_Beam_Color');
		}
	}


	/** You can run around spamming the beam and needing to look around all speed **/
	simulated function bool CanViewAccelerationWhenFiring()
	{
		return TRUE;
	}
}

simulated state WeaponPuttingDown
{
	simulated function WeaponIsDown()
	{
		// make sure we're completely unlinked before we change weapons
		Unlink();
		LinkedList.length = 0;

		Super.WeaponIsDown();
	}
}


//-----------------------------------------------------------------
// AI Interface

function float GetAIRating()
{
	local UTBot B;
	local UTVehicle V;
	local UTGameObjective O;
	local float Dist;

	B = UTBot(Instigator.Controller);
	if (B == None || B.Squad == None)
	{
		return AIRating;
	}

	V = UTSquadAI(B.Squad).GetLinkVehicle(B);
	if ( (V != None)
		&& (VSize(Instigator.Location - V.Location) < 1.5 * WeaponRange)
		&& (V.Health < V.HealthMax) && (V.LinkHealMult > 0) )
	{
		return 1.2;
	}

	V = UTVehicle(B.RouteGoal);
	if ( (V != None) && (B.Enemy == None) && (VSize(Instigator.Location - B.RouteGoal.Location) < 1.5 * WeaponRange)
	     && V.TeamLink(B.GetTeamNum()) )
	{
		return 1.2;
	}

	O = UTGameObjective(B.Squad.SquadObjective);
	if (O != None && O.TeamLink(B.GetTeamNum()) && O.NeedsHealing()
	     && VSize(Instigator.Location - O.Location) < 1.1 * GetTraceRange() && B.LineOfSightTo(O))
	{
		return 1.2;
	}

	if ( B.Enemy != None )
	{
		Dist = VSize(B.Enemy.Location - Instigator.Location);
		if ( Dist > 3500 )
		{
			return AIRating * 3500/Dist;
		}
	}

	return AIRating * FMin(Pawn(Owner).GetDamageScaling(), 1.5);
}

function bool FocusOnLeader(bool bLeaderFiring)
{
	local UTBot B;
	local UTVehicle LinkVehicle;
	local Actor Other;
	local vector HitLocation, HitNormal, StartTrace;
	local Controller SquadLeader;
	
	B = UTBot(Instigator.Controller);
	if ( B == None || B.Squad == None )
	{
		return false;
	}
	SquadLeader = UTSquadAI(B.Squad).SquadLeader;
	if ( SquadLeader == None )
	{
		return false;
	}
	if ( PlayerController(SquadLeader) != None )
	{
		LinkVehicle = UTVehicle(SquadLeader.Pawn);
	}
	else
	{
		LinkVehicle = UTSquadAI(B.Squad).GetLinkVehicle(B);
	}
	if ( LinkVehicle == None )
	{
		LinkVehicle = UTVehicle(SquadLeader.Pawn);
		if ( LinkVehicle == None )
		{
			return false;
		}
	}
	if ( ((B.Enemy != None) && !LinkVehicle.bKeyVehicle) || (LinkVehicle.Health >= LinkVehicle.HealthMax) || (LinkVehicle.LinkHealMult <= 0) )
	{
		return false;
	}
	StartTrace = Instigator.GetPawnViewLocation();
	if (VSize(LinkVehicle.Location - StartTrace) < GetTraceRange())
	{
		Other = Trace(HitLocation, HitNormal, LinkVehicle.GetTargetLocation(), StartTrace, true);
		if ( Other == LinkVehicle )
		{
			B.Focus = Other;
			return true;
		}
	}
	return false;
}

/* BestMode()
choose between regular or alt-fire
*/
function byte BestMode()
{
	local float EnemyDist;
	local UTBot B;
	local UTVehicle V;
	local UTGameObjective ObjTarget;

	// currently no beams on mobile devices, so disallow the alt-fire
	if (WorldInfo.IsConsoleBuild(CONSOLE_Mobile))
	{
		return 0;
	}

	B = UTBot(Instigator.Controller);
	if ( B == None )
	{
		return 0;
	}

	ObjTarget = UTGameObjective(B.Focus);
	if ( (ObjTarget != None) && ObjTarget.TeamLink(B.GetTeamNum()) )
	{
		return 1;
	}
	if ( FocusOnLeader(B.Focus == UTSquadAI(B.Squad).SquadLeader.Pawn) )
	{
		return 1;
	}

	V = UTVehicle(B.Focus);
	if ( (V != None) && WorldInfo.GRI.OnSameTeam(B,V) )
	{
		return 1;
	}
	if ( B.Enemy == None )
	{
		return 0;
	}
	EnemyDist = VSize(B.Enemy.Location - Instigator.Location);
	if ( EnemyDist > WeaponRange )
	{
		return 0;
	}
	return 1;
}

function bool CanHeal(Actor Other)
{
	if (!HasAmmo(1))
	{
		return false;
	}
	else if (UTGameObjective(Other) != None)
	{
		return UTGameObjective(Other).TeamLink(Instigator.GetTeamNum());
	}
	else
	{
		return (UTVehicle(Other) != None && UTVehicle(Other).LinkHealMult > 0.f);
	}
}

function float GetOptimalRangeFor(Actor Target)
{
	// return alt beam range if shooting at teammate (healing/linking)
	return (WorldInfo.GRI.OnSameTeam(Target, Instigator) ? WeaponRange : Super.GetOptimalRangeFor(Target));
}

function float SuggestAttackStyle()
{
	return 0.8;
}

function float SuggestDefenseStyle()
{
	return -0.4;
}

/**
 * Detect that we are trying to pickup another link gun and switch to full power
 */
function bool DenyPickupQuery(class<Inventory> ItemClass, Actor Pickup)
{
	if ( ItemClass==Class )
	{
		BoostPower();
	}
	return super.DenyPickupQuery(ItemClass, Pickup);
}

/** 
  * Increase weapon power (after picking up Link Booster) 
  */
simulated function BoostPower()
{
	AIRating = 0.71;
	CurrentRating = 0.71;
	FireInterval[0] = 0.16;
	WeaponRange = 900;
	bFullPower = true;
	if ( WeaponMaterialInstance != None )
	{
		WeaponMaterialInstance.SetVectorParameterValue('Paint_Color', class'UTHUD'.default.WhiteLinearColor);
	}
}

simulated state WeaponEquipping
{
	simulated event BeginState(Name PreviousStateName)
	{
		local LinearColor TeamColor;

		super.BeginState(PreviousStateName);

		// if not full power, and team game, team color the linkgun
		if ( !bFullPower && (WorldInfo.GRI != None) && WorldInfo.GRI.GameClass.default.bTeamGame 
			&& (Instigator != None) && (Instigator.PlayerReplicationInfo != None) && (Instigator.PlayerReplicationInfo.Team != None) )
		{
			if ( Instigator.PlayerReplicationInfo.Team.TeamIndex == 0 )
			{
				TeamColor.R = 0.2;
			}
			else
			{
				TeamColor.B = 0.4;
			}
			WeaponMaterialInstance.SetVectorParameterValue('Paint_Color', TeamColor);
		}
	}
}

simulated function AbilityFire() {
	local vector AimOrigin, AimDirection;
	local GWPawn tempTarget;
	local Vector targetLocation;
	local Rotator targetRotation;
	local float HealModifier;

	HealModifier = AmmoCount / float(MaxAmmoCount);
	if(HealModifier == 0) {
		return;
	}
	// define range to use for CalcWeaponFire()
	AimOrigin = InstantFireStartTrace();
	IncrementFlashCount();
	AddAmmo(-AmmoCount);
	foreach VisibleCollidingActors(class'GWPawn', tempTarget, 1000, AimOrigin) {
		//Boost Damage (Call a function in Pawn)
		if(Instigator == tempTarget) {
			continue;
		}
		tempTarget.GetActorEyesViewPoint(targetLocation, targetRotation); //Get Pawn's Location
		if(HealRadiusCollision(AimOrigin, AbilityExtent * HealModifier, AimDirection, tempTarget.HitBoxInfo, targetLocation, Vector(targetRotation))) {
			if(GWPawn(Instigator).IsSameTeamOrSelf(tempTarget)) {
				tempTarget.HealDamage(HealPoints * HealModifier,Instigator.Controller,none);
				tempTarget.IncrementStatusEffect(EFFECT_NEWT_HEAL, Instigator.Controller);
			} else {
				tempTarget.TakeRadiusDamage(Instigator.Controller, 0, 1000, class'DmgType_Fell', 500000 * HealModifier, AimOrigin, true, Instigator);
			}
		}
	}

}

/*simulated function DrawAbilityTargets(HUD H) {
	local GWPawn targetPawn;
	local Vector StartTrace;

	// define range to use for CalcWeaponFire()
	StartTrace = Instigator.Location;

	foreach VisibleCollidingActors(class'GWPawn', targetPawn, AbilityRange, StartTrace) {
		//Boost Damage (Call a function in Pawn)
		if(GWPawn(Owner).IsSameTeam(targetPawn)) {
			H.Draw3DLine(StartTrace, targetPawn.Location, MakeColor(0, 255, 0));
		}
	}
}*/
simulated function bool HealRadiusCollision(Vector pos0, Vector rad0, Vector dir0, SPawnHitBoxes box1, Vector pos1, Vector dir1) {
	local Shape Shape0;
	local Shape Shape1;

	Shape0.m_pos = pos0;
	Shape0.m_rot = QuatToCQuat(QuatFromRotator(Rotator(dir0)));
	Shape0.m_radius = vect3d(0,0,0);
	Shape0.m_type = SHAPE_POINT;

	Shape1.m_pos = pos1 + dir1 * box1.Offset;
	Shape1.m_rot = QuatToCQuat(QuatFromRotator(Rotator(dir1)));
	Shape1.m_radius = box1.Radius + vect3d(rad0.X,rad0.X,rad0.X);
	Shape1.m_type = SHAPE_CUBE;

	return CollisionManager.HasCollision(Shape0, Shape1);
}

static function GetTeamBeamInfo(byte TeamNum, optional out color BeamColor, optional out ParticleSystem BeamSystem, optional out ParticleSystem BeamEndpointTemplate)
{
	BeamColor = default.LinkBeamColors[(TeamNum < ArrayCount(default.LinkBeamColors)) ? int(TeamNum) : ArrayCount(default.LinkBeamColors) - 1];
	BeamSystem = default.LinkBeamSystems[(TeamNum < ArrayCount(default.LinkBeamSystems)) ? int(TeamNum) : ArrayCount(default.LinkBeamSystems) - 1];
	BeamEndpointTemplate = default.TeamBeamEndpointTemplates[(TeamNum < ArrayCount(default.TeamBeamEndpointTemplates)) ? int(TeamNum) : ArrayCount(default.TeamBeamEndpointTemplates) - 1];
}

defaultproperties
{

	EatExtent=(X=75,Y=25,Z=25)
	AbilityExtent=(X=400)
	AmmoRegenAmount=0
	HealPoints = 50

	FireInterval(1)=2//25
	
	ShotCost(1)=0
	WeaponFireTypes(1)=EWFT_InstantHit

	ShotCost(0)=0
	WeaponFireTypes(0)=EWFT_InstantHit

	WeaponColor=(R=255,G=255,B=0,A=255)
	FireInterval(0)=+0.24
	PlayerViewOffset=(X=16.0,Y=-18,Z=-18.0)

	FiringStatesArray(0)=WeaponSprayFiring

	Begin Object Class=ParticleSystemComponent Name=PoweredUpComponent
		Template=ParticleSystem'WP_LinkGun.Effects.P_WP_Linkgun_PoweredUp'
		bAutoActivate=false
		DepthPriorityGroup=SDPG_Foreground
		SecondsBeforeInactive=1.0f
	End Object
	PoweredUpEffect=PoweredUpComponent
	PoweredUpEffectSocket=PowerEffectSocket

	FireOffset=(X=12,Y=10,Z=-10)

	//WeaponEquipSnd=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_RaiseCue'
	//WeaponPutDownSnd=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_LowerCue'
	//WeaponFireSnd(1)=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_FireCue'
	//WeaponFireSnd(0)=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_AltFireCue'

	MaxDesireability=0.7
	AIRating=+0.3
	CurrentRating=+0.3
	bFastRepeater=true
	bInstantHit=false
	bSplashJump=false
	bRecommendSplashDamage=false
	bSniping=false
	ShouldFireOnRelease(0)=0
	ShouldFireOnRelease(1)=0
	InventoryGroup=1
	GroupWeight=0.5
	bAutoCharge=true
	RechargeRate=1.0

	WeaponRange=500
	LinkStrength=1
	LinkFlexibility=1	// determines how easy it is to maintain a link.
							// 1=must aim directly at linkee, 0=linkee can be 90 degrees to either side of you

	LinkBreakDelay=0		// link will stay established for this long extra when blocked (so you don't have to worry about every last tree getting in the way)
	WeaponLinkDistance=160.0

	//PickupSound=SoundCue'A_Pickups.Weapons.Cue.A_Pickup_Weapons_Link_Cue'

	MomentumTransfer=50000.0
	MinimumDamage=5.0

	EffectSockets(0)=WeaponPoint
	EffectSockets(1)=WeaponPoint

	MuzzleFlashSocket=WeaponPoint
	MuzzleFlashPSCTemplate[1]=ParticleSystem'WP_LinkGun.Effects.P_FX_LinkGun_MF_Primary'
	MuzzleFlashPSCTemplate[0]=ParticleSystem'WP_LinkGun.Effects.P_FX_LinkGun_MF_Beam'
	bMuzzleFlashPSCLoops=true
	MuzzleFlashLightClass=class'UTGame.UTLinkGunMuzzleFlashLight'

	bShowAltMuzzlePSCWhenWeaponHidden=TRUE

	TeamMuzzleFlashTemplates[0]=ParticleSystem'WP_LinkGun.Effects.P_FX_LinkGun_MF_Beam_Red'
	TeamMuzzleFlashTemplates[1]=ParticleSystem'WP_LinkGun.Effects.P_FX_LinkGun_MF_Beam_Blue'
	TeamMuzzleFlashTemplates[2]=ParticleSystem'WP_LinkGun.Effects.P_FX_LinkGun_MF_Beam'
	HighPowerMuzzleFlashTemplate=ParticleSystem'WP_LinkGun.Effects.P_FX_LinkGun_MF_Beam_Gold'

	MuzzleFlashColor=(R=120,G=255,B=120,A=255)
	MuzzleFlashDuration=0.33;

	//BeamTemplate[0]=ParticleSystem'G_FX_CH_Newt.Effects.P_WP_Linkgun_Altbeam_Blue'
	BeamTemplate[0]=ParticleSystem'G_FX_CH_Newt.Effects.P_WP_Linkgun_Altbeam_Blue'
	BeamSockets[0]=WeaponPoint
	BeamTemplate[1]=ParticleSystem'G_FX_CH_Newt.Effects.P_WP_Linkgun_Altbeam_Blue'
	BeamSockets[1]=WeaponPoint
	EndPointParamName=LinkBeamEnd

	IconX=412
	IconY=82
	IconWidth=40
	IconHeight=36

	//StartAltFireSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_AltFireStartCue'
	//EndAltFireSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_AltFireStopCue'
	CrossHairCoordinates=(U=384,V=0,UL=64,VL=64)

	LockerRotation=(pitch=0,yaw=0,roll=-16384)
	IconCoordinates=(U=453,V=467,UL=147,VL=41)

	Begin Object Class=ForceFeedbackWaveform Name=BeamForceFeedbackWaveform1
		Samples(0)=(LeftAmplitude=20,RightAmplitude=10,LeftFunction=WF_Constant,RightFunction=WF_Constant,Duration=0.100)
		bIsLooping=TRUE
	End Object
	BeamWeaponFireWaveForm=BeamForceFeedbackWaveform1

	LinkBeamColors(0)=(R=255,G=64,B=64,A=255)
	LinkBeamColors(1)=(R=64,G=64,B=255,A=255)
	LinkBeamColors(2)=(R=128,G=220,B=120,A=255)
	//LinkBeamSystems[0]=ParticleSystem'G_FX_CH_Newt.Effects.P_WP_Linkgun_Altbeam_Blue'
	LinkBeamSystems[0]=ParticleSystem'G_FX_CH_Newt.Effects.P_WP_Linkgun_Altbeam_Blue'
	LinkBeamSystems[1]=ParticleSystem'G_FX_CH_Newt.Effects.P_WP_Linkgun_Altbeam_Blue'
	LinkBeamSystems[2]=ParticleSystem'G_FX_CH_Newt.Effects.P_WP_Linkgun_Altbeam_Blue'
	TeamBeamEndpointTemplates[0]=ParticleSystem'G_FX_CH_Newt.Effects.PS_Watergun_Impact_Splash'
	TeamBeamEndpointTemplates[1]=ParticleSystem'G_FX_CH_Newt.Effects.PS_Watergun_Impact_Splash'
	TeamBeamEndpointTemplates[2]=ParticleSystem'G_FX_CH_Newt.Effects.PS_Watergun_Impact_Splash'

	InstantHitDamage(0)=50
	MaxAmmoCount = 1000
	AmmoCount = 0
}
