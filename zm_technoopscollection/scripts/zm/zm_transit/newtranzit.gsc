#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_sidequests;
#include maps\mp\zm_transit_utility;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\gametypes_zm\_globallogic_score;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_zonemgr;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_powerups;
#include maps\mp\zombies\_zm_buildables;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zm_transit_classic;
#include maps\mp\zm_transit_buildables;

main()
{
	replacefunc(maps\mp\zm_transit_utility::solo_tombstone_removal, ::solo_tombstone_removal_new);
	replacefunc(maps\mp\zm_transit_sq::richtofen_sidequest_a, ::richtofen_sidequest_a_new);

	if(getDvarInt("tranzit_place_dinerhatch") == 1)
	{
		replacefunc(maps\mp\zm_transit_classic::diner_hatch_access, ::diner_hatch_access_new);
		replacefunc(maps\mp\zm_transit_buildables::dinerhatchbuildable, ::dinerhatchbuildable_new);
	}

	if(getDvarInt("power_activates_buildables") == 1)
	{
		replacefunc(maps\mp\zombies\_zm_equip_electrictrap::startelectrictrapdeploy, ::startelectrictrapdeploy_new);
		replacefunc(maps\mp\zombies\_zm_equip_turret::startturretdeploy, ::startturretdeploy_new);
	}

    level thread onPlayerConnect();
}

init()
{
	if(getDvarInt("tranzit_tedd_tracker") == 1)
	{
		level thread TEDDTrackerHUD();
	}
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
	level endon("game_ended");
    for(;;)
    {
        self waittill("spawned_player");
    }
}

solo_tombstone_removal_new()
{
	return;
}

richtofen_sidequest_a_new()
{
    level endon( "power_off" );
    level.sq_progress["rich"]["A_jetgun_built"] = 0;
    level.sq_progress["rich"]["A_jetgun_tower"] = 0;
    level.sq_progress["rich"]["A_complete"] = 0;
    ric_fail_out = undefined;
    ric_fail_heat = undefined;

    if ( !( isdefined( level.buildables_built["jetgun_zm"] ) && level.buildables_built["jetgun_zm"] ) )
        wait_for_buildable( "jetgun_zm" );

    level.sq_progress["rich"]["A_jetgun_built"] = 1;

    while ( true )
    {
        level.sq_volume waittill( "trigger", who );

        if ( isplayer( who ) && isalive( who ) && who getcurrentweapon() == "jetgun_zm" )
        {
            who thread left_sq_area_watcher( level.sq_volume );
            self.checking_jetgun_fire = 0;
            break;
        }
        else if ( isplayer( who ) && isalive( who ) && who getcurrentweapon() == "jetgun_zm" )
        {
            if ( !isdefined( ric_fail_heat ) )
            {
                ric_fail_heat = 1;
                level thread richtofensay( "vox_zmba_sidequest_jet_low_0", undefined, 0, 10 );
            }
        }
    }

    level thread richtofensay( "vox_zmba_sidequest_jet_empty_0", undefined, 0, 16 );
    player = get_players();
    player[0] setclientfield( "screecher_sq_lights", 1 );
    update_sidequest_stats( "sq_transit_rich_stage_2" );
    level thread richtofen_sidequest_complete_check( "A_complete" );
    level.sq_progress["rich"]["A_jetgun_tower"] = 1;
}

diner_hatch_access_new()
{
    diner_hatch = getent( "diner_hatch", "targetname" );
    diner_hatch_col = getent( "diner_hatch_collision", "targetname" );
    diner_hatch_mantle = getent( "diner_hatch_mantle", "targetname" );

    if ( !isdefined( diner_hatch ) || !isdefined( diner_hatch_col ) )
        return;

    diner_hatch hide();
    diner_hatch_mantle.start_origin = diner_hatch_mantle.origin;
    diner_hatch_mantle.origin = diner_hatch_mantle.origin + vectorscale( ( 0, 0, 1 ), 500.0 );
    diner_hatch show();
    diner_hatch_col delete();
    diner_hatch_mantle.origin = diner_hatch_mantle.start_origin;
}

dinerhatchbuildable_new()
{

}

loopdestination()
{
	bus = level.the_bus;
	while(1)
	{
		foreach (player in level.players)
		{
			player iprintln(getBusStatus(bus.destinationindex));
		}
		wait 1;
	}
}

getBusStatus(num)
{
	if (num == 0)
		name = "Bus Depot";
	else if (num == 1)
		name = "Tunnels";
	else if (num == 2)
		name = "Diner";
	else if (num == 3)
		name = "Forest";
	else if (num == 4)
		name = "Farm";
	else if (num == 5)
		name = "Cornfields";
	else if (num == 6)
		name = "Power Station";
	else if (num == 7)
		name = "Cabin";
	else if (num == 8)
		name = "Town";
	else if (num == 9)
		name = "Bridge";

	return name;
	
}

isBusMoving(bus)
{	
	if(bus.ismoving == 1)
		return "moving";
	else
		return "located";
}

TEDDTrackerHUD()
{
	bus = level.the_bus;
	
	tedd_tracker = newHudElem();
	tedd_tracker.alignx = "left";
	tedd_tracker.aligny = "bottom";
	tedd_tracker.horzalign = "user_left";
	tedd_tracker.vertalign = "user_bottom";
	tedd_tracker.x += 0;
	tedd_tracker.y += 0;
	tedd_tracker.fontscale = 1;
	tedd_tracker.alpha = 0.5;
	tedd_tracker.color = ( 1, 1, 1 );
	tedd_tracker.hidewheninmenu = 1;
	tedd_tracker.foreground = 1;
	tedd_tracker setText("T.E.D.D is " + isBusMoving(bus) + " at ^2" + getBusStatus(bus.destinationindex));
	
	oldindex = bus.destinationindex;
	
	while(1)
	{
		if(bus.destinationindex != oldindex)
		{
			tedd_tracker setText("T.E.D.D is " + isBusMoving(bus) + " at ^2" + getBusStatus(bus.destinationindex));
			oldindex = bus.destinationindex;
		}
		
		if(bus.ismoving != oldmoving)
		{
			tedd_tracker setText("T.E.D.D is " + isBusMoving(bus) + " at ^2" + getBusStatus(bus.destinationindex));
			oldmoving = bus.ismoving;
		}
		wait 0.1;
	}
}

startturretdeploy_new( weapon )
{
    self endon( "death" );
    self endon( "disconnect" );
    self endon( "equip_turret_zm_taken" );
    self thread watchforcleanup();

    if ( !isdefined( self.turret_health ) )
        self.turret_health = 60;

    if ( isdefined( weapon ) )
    {
        while(!flag("power_on"))
		{
			wait 0.1;
		}
		
		weapon hide();
        wait 0.1;

        weapon.turret notify( "stop_burst_fire_unmanned" );

        if ( !isdefined( weapon ) )
            return;

        if ( isdefined( self.turret ) )
        {
            self.turret notify( "stop_burst_fire_unmanned" );
            self.turret notify( "turret_deactivated" );
            self.turret delete();
        }

        turret = spawnturret( "misc_turret", weapon.origin, "zombie_bullet_crouch_zm" );
        turret.turrettype = "sentry";
        turret setturrettype( turret.turrettype );
        turret setmodel( "p6_anim_zm_buildable_turret" );
        turret.origin = weapon.origin;
        turret.angles = weapon.angles;
        turret linkto( weapon );
        turret makeunusable();
        turret.owner = self;
        turret setowner( turret.owner );
        turret maketurretunusable();
        turret setmode( "auto_nonai" );
        turret setdefaultdroppitch( 45.0 );
        turret setconvergencetime( 0.3 );
        turret setturretteam( self.team );
        turret.team = self.team;
        turret.damage_own_team = 1;
        turret.turret_active = 1;
        weapon.turret = turret;
        self.turret = turret;

        weapon.power_on = 1;

        turret thread maps\mp\zombies\_zm_mgturret::burst_fire_unmanned();

        self thread turretdecay( weapon );

        self thread maps\mp\zombies\_zm_buildables::delete_on_disconnect( weapon );

        while ( isdefined( weapon ) )
        {
            if ( !is_true( weapon.power_on ) )
            {
                if ( isdefined( self.buildableturret.sound_ent ) )
                {
                    self.buildableturret.sound_ent playsound( "wpn_zmb_turret_stop" );
                    self.buildableturret.sound_ent delete();
                    self.buildableturret.sound_ent = undefined;
                }
            }

            wait 0.1;
        }

        if ( isdefined( self.buildableturret.sound_ent ) )
        {
            self.buildableturret.sound_ent playsound( "wpn_zmb_turret_stop" );
            self.buildableturret.sound_ent delete();
            self.buildableturret.sound_ent = undefined;
        }

        if ( isdefined( turret ) )
        {
            turret notify( "stop_burst_fire_unmanned" );
            turret notify( "turret_deactivated" );
            turret delete();
        }

        self.turret = undefined;
        self notify( "turret_cleanup" );
    }
}

startelectrictrapdeploy_new( weapon )
{
    self endon( "death" );
    self endon( "disconnect" );
    self endon( "equip_electrictrap_zm_taken" );
    self thread watchforcleanup();
    electricradius = 45;

    if ( !isdefined( self.electrictrap_health ) )
        self.electrictrap_health = 60;

    if ( isdefined( weapon ) )
    {
/#
        weapon thread debugelectrictrap( electricradius );
#/

        while(!flag("power_on"))
		{
			wait 0.1;
		}

        weapon.power_on = 1;

        self thread electrictrapthink( weapon, electricradius );

        if ( !( isdefined( level.equipment_etrap_needs_power ) && level.equipment_etrap_needs_power ) )
            self thread electrictrapdecay( weapon );

        self thread maps\mp\zombies\_zm_buildables::delete_on_disconnect( weapon );
        weapon waittill( "death" );

        if ( isdefined( level.electrap_sound_ent ) )
        {
            level.electrap_sound_ent playsound( "wpn_zmb_electrap_stop" );
            level.electrap_sound_ent delete();
            level.electrap_sound_ent = undefined;
        }

        self notify( "etrap_cleanup" );
    }
}