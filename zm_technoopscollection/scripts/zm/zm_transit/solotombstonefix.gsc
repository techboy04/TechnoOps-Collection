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

main()
{
	replacefunc(maps\mp\zm_transit_utility::solo_tombstone_removal, ::solo_tombstone_removal_new);
	replacefunc(maps\mp\zm_transit_sq::richtofen_sidequest_a, ::richtofen_sidequest_a_new);
    level thread onPlayerConnect();
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

        if ( isplayer( who ) && isalive( who ) && who getcurrentweapon() == "jetgun_zm" && ( !isdefined( who.jetgun_heatval ) || who.jetgun_heatval < 1 ) )
        {
            who thread left_sq_area_watcher( level.sq_volume );
            self.checking_jetgun_fire = 0;
            break;
        }
        else if ( isplayer( who ) && isalive( who ) && who getcurrentweapon() == "jetgun_zm" && ( isdefined( who.jetgun_heatval ) && who.jetgun_heatval > 1 ) )
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
