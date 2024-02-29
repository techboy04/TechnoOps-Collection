#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\zombies\_zm_equipment;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_craftables;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\_demo;
#include maps\mp\zombies\_zm_afterlife;
#include maps\mp\zm_alcatraz_travel;

main()
{
	replacefunc(maps\mp\zombies\_zm_craftables::craftable_use_hold_think_internal, ::craftable_use_hold_think_internal_new);
	if (getDvarInt("afterlife_doesnt_down") == 1)
	{
		replacefunc(maps\mp\zombies\_zm_afterlife::afterlife_leave, ::afterlife_leave_new);
	]
}

craftable_use_hold_think_internal_new( player )
{
    wait 0.01;

	buildtime = self.usetime;

    if ( !isdefined( self ) )
    {
        self notify( "craft_failed" );

        if ( isdefined( player.craftableaudio ) )
        {
            player.craftableaudio delete();
            player.craftableaudio = undefined;
        }

        return;
    }

    if ( !isdefined( self.usetime ) )
        self.usetime = int( 3000 );

	if (player hasPerk("specialty_fastreload"))
	{
		buildtime = buildtime/3;
	}

    self.craft_time = buildtime;
    self.craft_start_time = gettime();
    craft_time = self.craft_time;
    craft_start_time = self.craft_start_time;
    player disable_player_move_states( 1 );
    player increment_is_drinking();
    orgweapon = player getcurrentweapon();
    player giveweapon( "zombie_builder_zm" );
    player switchtoweapon( "zombie_builder_zm" );
    self.stub.craftablespawn craftable_set_piece_crafting( player.current_craftable_piece );
    player thread player_progress_bar( craft_start_time, craft_time );

    if ( isdefined( level.craftable_craft_custom_func ) )
        player thread [[ level.craftable_craft_custom_func ]]( self.stub );

    while ( isdefined( self ) && player player_continue_crafting( self.stub.craftablespawn ) && gettime() - self.craft_start_time < self.craft_time )
        wait 0.05;

    player notify( "craftable_progress_end" );
    player maps\mp\zombies\_zm_weapons::switch_back_primary_weapon( orgweapon );
    player takeweapon( "zombie_builder_zm" );

    if ( isdefined( player.is_drinking ) && player.is_drinking )
        player decrement_is_drinking();

    player enable_player_move_states();

    if ( isdefined( self ) && player player_continue_crafting( self.stub.craftablespawn ) && gettime() - self.craft_start_time >= self.craft_time )
    {
        self.stub.craftablespawn craftable_clear_piece_crafting( player.current_craftable_piece );
        self notify( "craft_succeed" );
    }
    else
    {
        if ( isdefined( player.craftableaudio ) )
        {
            player.craftableaudio delete();
            player.craftableaudio = undefined;
        }

        self.stub.craftablespawn craftable_clear_piece_crafting( player.current_craftable_piece );
        self notify( "craft_failed" );
    }
}

afterlife_leave_new( b_revived )
{
    if ( !isdefined( b_revived ) )
        b_revived = 1;

    while ( self ismantling() )
        wait 0.05;

    self clientnotify( "al_t" );

    if ( isdefined( self.afterlife_visionset ) && self.afterlife_visionset )
    {
        maps\mp\_visionset_mgr::vsmgr_deactivate( "visionset", "zm_afterlife", self );

        if ( isdefined( level.optimise_for_splitscreen ) && !level.optimise_for_splitscreen )
            maps\mp\_visionset_mgr::vsmgr_deactivate( "overlay", "zm_afterlife_filter", self );

        self.afterlife_visionset = 0;
    }

    self disableafterlife();
    self.dontspeak = 0;
    self thread afterlife_doors_close();
    self.health = self.maxhealth;
    self setclientfieldtoplayer( "player_in_afterlife", 0 );
    self setclientfield( "player_afterlife_fx", 0 );
    self setclientfieldtoplayer( "clientfield_afterlife_audio", 0 );
    self maps\mp\zombies\_zm_perks::perk_set_max_health_if_jugg( "health_reboot", 1, 0 );
    self allowstand( 1 );
    self allowcrouch( 1 );
    self allowprone( 1 );
    self setmodel( self.str_living_model );
    self setviewmodel( self.str_living_view );

    if ( self.e_afterlife_corpse.revivetrigger.origin != self.e_afterlife_corpse.origin )
        self setorigin( self.e_afterlife_corpse.revivetrigger.origin );
    else
        self setorigin( self.e_afterlife_corpse.origin );

    if ( isdefined( level.e_gondola ) )
    {
        a_gondola_doors_gates = get_gondola_doors_and_gates();

        for ( i = 0; i < a_gondola_doors_gates.size; i++ )
        {
            if ( self.e_afterlife_corpse istouching( a_gondola_doors_gates[i] ) )
            {
                if ( isdefined( level.e_gondola.is_moving ) && level.e_gondola.is_moving )
                    str_location = level.e_gondola.destination;
                else
                    str_location = level.e_gondola.location;

                a_s_orgs = getstructarray( "gondola_dropped_parts_" + str_location, "targetname" );

                foreach ( struct in a_s_orgs )
                {
                    if ( !positionwouldtelefrag( struct.origin ) )
                    {
                        self setorigin( struct.origin );
                        break;
                    }
                }

                break;
            }
        }

        if ( self.e_afterlife_corpse islinkedto( level.e_gondola ) && ( isdefined( level.e_gondola.is_moving ) && level.e_gondola.is_moving ) )
            self.is_on_gondola = 1;
    }

    self setplayerangles( self.e_afterlife_corpse.angles );
    self.afterlife = 0;
    self afterlife_laststand_cleanup( self.e_afterlife_corpse );

//    if ( isdefined( b_revived ) && !b_revived )
//    {
//        self afterlife_remove( 1 );
//    }

    reset_all_afterlife_unitriggers();
	
	if (self.initialrevive == 0)
	{
		self.initialrevive = 1;
		
		primary_weapons = self getweaponslist( 1 );
		for ( x = 0; x < primary_weapons.size; x++ )
		{
			if ( level.headshots_only && is_lethal_grenade( primary_weapons[x] ) )
				continue;

			if ( isdefined( level.zombie_include_equipment ) && isdefined( level.zombie_include_equipment[primary_weapons[x]] ) )
				continue;

			if ( isdefined( level.zombie_weapons_no_max_ammo ) && isdefined( level.zombie_weapons_no_max_ammo[primary_weapons[x]] ) )
				continue;

			if ( self hasweapon( primary_weapons[x] ) )
				self givemaxammo( primary_weapons[x] );
		}
	}
	
}