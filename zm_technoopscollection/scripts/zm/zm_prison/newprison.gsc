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
#include maps\mp\zombies\_zm_ai_brutus;
#include maps\mp\zm_alcatraz_classic;
#include maps\mp\zm_alcatraz_amb;
#include maps\mp\zm_prison_sq_final;
#include maps\mp\zm_alcatraz_sq_vo;
#include maps\mp\gametypes_zm\_hud;


main()
{
	replacefunc(maps\mp\zombies\_zm_craftables::craftable_use_hold_think_internal, ::craftable_use_hold_think_internal_new);
	replacefunc(maps\mp\zm_alcatraz_utility::check_solo_status, ::check_solo_status_new);
	replacefunc(maps\mp\zombies\_zm_afterlife::afterlife_laststand, ::afterlife_laststand_new);
	replacefunc(maps\mp\zombies\_zm_afterlife::afterlife_revive_invincible, ::afterlife_revive_invincible_new);
	replacefunc(maps\mp\zombies\_zm_afterlife::afterlife_fake_death, ::afterlife_fake_death_new);
	replacefunc(maps\mp\zm_alcatraz_sq::plane_boarding_thread, ::plane_boarding_thread_new);
	replacefunc(maps\mp\zm_alcatraz_sq::electric_chair_player_thread, ::electric_chair_player_thread_new);
	replacefunc(maps\mp\zm_alcatraz_sq::electric_chair_trigger_thread, ::electric_chair_trigger_thread_new);
	replacefunc(maps\mp\zm_prison::zm_player_fake_death, ::zm_player_fake_death_new);
	if (getDvarInt("afterlife_doesnt_down") == 1)
	{
		replacefunc(maps\mp\zombies\_zm_afterlife::afterlife_leave, ::afterlife_leave_new);
	}
	if(getDvarInt("gamemode") != 0)
	{
		replacefunc(maps\mp\zombies\_zm_ai_brutus::wait_on_box_alarm, ::wait_on_box_alarm_new);
		replacefunc(maps\mp\zombies\_zm_ai_brutus::get_best_brutus_spawn_pos, ::get_best_brutus_spawn_pos_new);
		replacefunc(maps\mp\zm_alcatraz_classic::fake_kill_player, ::fake_kill_player_new);
		if(getDvarInt("gamemode") != 3 || getDvarInt("gamemode") != 5)
		{
			replacefunc(maps\mp\zm_prison::alcatraz_afterlife_doors, ::alcatraz_afterlife_doors_new);
			replacefunc(maps\mp\zombies\_zm_afterlife::init, ::init_afterlife);
			replacefunc(maps\mp\zm_alcatraz_classic::power_on_perk_machines, ::power_on_perk_machines_new);
		}
	}
}

check_solo_status_new()
{
    if(getDvarInt("planeparts_per_player") == 0)
	{
		level.is_forever_solo_game = 1;
	}
	else if(getDvarInt("planeparts_per_player") == 1)
	{
		level.is_forever_solo_game = 0;
	}
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

power_on_perk_machines_new()
{
    a_shockboxes = getentarray( "perk_afterlife_trigger", "script_noteworthy" );

    foreach ( e_shockbox in a_shockboxes )
    {
        e_shockbox notify( "damage", 1, level );
        wait 1;
    }
}

init_afterlife()
{
    level.zombiemode_using_afterlife = 1;
    flag_init( "afterlife_start_over" );
    level.afterlife_revive_tool = "syrette_afterlife_zm";
    precacheitem( level.afterlife_revive_tool );
    precachemodel( "drone_collision" );
    maps\mp\_visionset_mgr::vsmgr_register_info( "visionset", "zm_afterlife", 9000, 120, 1, 1 );
    maps\mp\_visionset_mgr::vsmgr_register_info( "overlay", "zm_afterlife_filter", 9000, 120, 1, 1 );

    registerclientfield( "toplayer", "player_lives", 9000, 2, "int" );
    registerclientfield( "toplayer", "player_in_afterlife", 9000, 1, "int" );
    registerclientfield( "toplayer", "player_afterlife_mana", 9000, 5, "float" );
    registerclientfield( "allplayers", "player_afterlife_fx", 9000, 1, "int" );
    registerclientfield( "toplayer", "clientfield_afterlife_audio", 9000, 1, "int" );
    registerclientfield( "toplayer", "player_afterlife_refill", 9000, 1, "int" );
    registerclientfield( "scriptmover", "player_corpse_id", 9000, 3, "int" );
    afterlife_load_fx();
    level thread afterlife_hostmigration();
    precachemodel( "c_zom_ghost_viewhands" );
    precachemodel( "c_zom_hero_ghost_fb" );
    precacheitem( "lightning_hands_zm" );
    precachemodel( "p6_zm_al_shock_box_on" );
    precacheshader( "waypoint_revive_afterlife" );
    a_afterlife_interact = getentarray( "afterlife_interact", "targetname" );
    array_thread( a_afterlife_interact, ::afterlife_interact_object_think );
    level.zombie_spawners = getentarray( "zombie_spawner", "script_noteworthy" );
    array_thread( level.zombie_spawners, ::add_spawn_function, ::afterlife_zombie_damage );
    a_afterlife_triggers = getstructarray( "afterlife_trigger", "targetname" );

    foreach ( struct in a_afterlife_triggers )
        afterlife_trigger_create( struct );

    level.afterlife_interact_dist = 256;
    level.is_player_valid_override = ::is_player_valid_afterlife;
    level.can_revive = ::can_revive_override;
    level.round_prestart_func = ::afterlife_start_zombie_logic;
    level.custom_pap_validation = ::is_player_valid_afterlife;
    level.player_out_of_playable_area_monitor_callback = ::player_out_of_playable_area;
    level thread afterlife_gameover_cleanup();
    level.afterlife_get_spawnpoint = ::afterlife_get_spawnpoint;
    level.afterlife_zapped = ::afterlife_zapped;
    level.afterlife_give_loadout = ::afterlife_give_loadout;
    level.afterlife_save_loadout = ::afterlife_save_loadout;
}


wait_on_box_alarm_new()
{
    while ( true )
    {
        self.zbarrier waittill( "randomization_done" );
        level.num_pulls_since_brutus_spawn++;

        if ( level.brutus_in_grief )
            level.brutus_min_pulls_between_box_spawns = randomintrange( 7, 10 );

        if ( level.num_pulls_since_brutus_spawn >= level.brutus_min_pulls_between_box_spawns )
        {
            rand = randomint( 1000 );

            if ( level.brutus_in_grief )
                level notify( "spawn_brutus", 1 );
            else if ( rand <= level.brutus_alarm_chance )
            {
                if ( flag( "moving_chest_now" ) )
                    continue;

                if ( attempt_brutus_spawn( 1 ) )
                {
                    if ( level.next_brutus_round == level.round_number + 1 )
                        level.next_brutus_round++;

                    level.brutus_alarm_chance = level.brutus_min_alarm_chance;
                }
            }
            else if ( level.brutus_alarm_chance < level.brutus_max_alarm_chance )
                level.brutus_alarm_chance = level.brutus_alarm_chance + level.brutus_alarm_chance_increment;
        }
		wait 0.1;
    }
}

get_best_brutus_spawn_pos_new( zone_name )
{

}

#using_animtree("fxanim_props");

alcatraz_afterlife_doors_new()
{
    wait 0.05;

    if ( !isdefined( level.shockbox_anim ) )
    {
        level.shockbox_anim["on"] = %fxanim_zom_al_shock_box_on_anim;
        level.shockbox_anim["off"] = %fxanim_zom_al_shock_box_off_anim;
    }

    if ( isdefined( self.script_noteworthy ) && self.script_noteworthy == "afterlife_door" )
    {
        self sethintstring( &"ZM_PRISON_AFTERLIFE_DOOR" );
/#
        self thread afterlife_door_open_sesame();
#/
        s_struct = getstruct( self.target, "targetname" );

        if ( !isdefined( s_struct ) )
        {
/#
            iprintln( "Afterlife Door was not targeting a valid struct" );
#/
            return;
        }
        else
        {
            m_shockbox = getent( s_struct.target, "targetname" );
            m_shockbox.health = 5000;
            m_shockbox setcandamage( 1 );
            m_shockbox useanimtree( #animtree );
            t_bump = spawn( "trigger_radius", m_shockbox.origin, 0, 28, 64 );
            t_bump.origin = m_shockbox.origin + anglestoforward( m_shockbox.angles ) * 0 + anglestoright( m_shockbox.angles ) * 28 + anglestoup( m_shockbox.angles ) * 0;

            if ( isdefined( t_bump ) )
            {
                t_bump setcursorhint( "HINT_NOICON" );
                t_bump sethintstring( &"ZM_PRISON_AFTERLIFE_INTERACT" );
            }

            while ( true )
            {
				if (1)
                {
                    if ( isdefined( level.afterlife_interact_dist ) )
                    {
						if(1)
                        {
                            t_bump delete();
                            m_shockbox playsound( "zmb_powerpanel_activate" );
                            playfxontag( level._effect["box_activated"], m_shockbox, "tag_origin" );
                            m_shockbox setmodel( "p6_zm_al_shock_box_on" );
                            m_shockbox setanim( level.shockbox_anim["on"] );

                            if ( isdefined( m_shockbox.script_string ) && ( m_shockbox.script_string == "wires_shower_door" || m_shockbox.script_string == "wires_admin_door" ) )
                                array_delete( getentarray( m_shockbox.script_string, "script_noteworthy" ) );

                            break;
                        }
                    }
                }
            }
        }
    }
    else
    {
        while ( true )
        {
            if ( !self maps\mp\zombies\_zm_blockers::door_buy() )
                continue;

            break;
        }
    }
}

fake_kill_player_new( n_start_pos )
{

}

afterlife_laststand_new( b_electric_chair )
{
    if ( !isdefined( b_electric_chair ) )
        b_electric_chair = 0;

    self endon( "disconnect" );
    self endon( "afterlife_bleedout" );
    level endon( "end_game" );

    if ( isdefined( level.afterlife_laststand_override ) )
    {
        self thread [[ level.afterlife_laststand_override ]]( b_electric_chair );
        return;
    }

    self.dontspeak = 1;
    self.health = 1000;
    b_has_electric_cherry = 0;

    if ( self hasperk( "specialty_grenadepulldeath" ) )
        b_has_electric_cherry = 1;

    self [[ level.afterlife_save_loadout ]]();
    self afterlife_fake_death();

    if ( isdefined( b_electric_chair ) && !b_electric_chair )
        wait 1;

    if ( isdefined( b_has_electric_cherry ) && b_has_electric_cherry && ( isdefined( b_electric_chair ) && !b_electric_chair ) )
    {
        self maps\mp\zombies\_zm_perk_electric_cherry::electric_cherry_laststand();
        wait 2;
    }

    self setclientfieldtoplayer( "clientfield_afterlife_audio", 1 );

    if ( flag( "afterlife_start_over" ) )
    {
        self clientnotify( "al_t" );
        wait 1;
        self thread fadetoblackforxsec( 0, 1, 0.5, 0.5, "white" );
        wait 0.5;
    }

    self ghost();
    self.e_afterlife_corpse = self afterlife_spawn_corpse();
    self thread afterlife_clean_up_on_disconnect();
    self notify( "player_fake_corpse_created" );
    self afterlife_fake_revive();
    self afterlife_enter();
    self.e_afterlife_corpse setclientfield( "player_corpse_id", self getentitynumber() + 1 );
    wait 0.5;
    self show();

    if ( !( isdefined( self.hostmigrationcontrolsfrozen ) && self.hostmigrationcontrolsfrozen ) )
        self freezecontrols( 0 );

	if(!self.alreadyingodmode)
	{
		self disableinvulnerability();
	}
    self.e_afterlife_corpse waittill( "player_revived", e_reviver );
    self notify( "player_revived" );
    self seteverhadweaponall( 1 );
    self enableinvulnerability();
    self.afterlife_revived = 1;
    playsoundatposition( "zmb_afterlife_spawn_leave", self.e_afterlife_corpse.origin );
    self afterlife_leave();
    self thread afterlife_revive_invincible();
    self playsound( "zmb_afterlife_revived_gasp" );
}

afterlife_revive_invincible_new()
{
    self endon( "disconnect" );
    wait 2;
	if(!self.alreadyingodmode)
	{
		self disableinvulnerability();
	}
    self seteverhadweaponall( 0 );
    self.afterlife_revived = undefined;
}

electric_chair_player_thread_new( m_linkpoint, chair_number, n_effects_duration )
{
    self endon( "death_or_disconnect" );
	
	e_home_telepoint = getstruct( "home_telepoint_" + chair_number, "targetname" );
    e_corpse_location = getstruct( "corpse_starting_point_" + chair_number, "targetname" );
    self disableweapons();
	self.alreadyingodmode = isgodmode( self );
    self enableinvulnerability();
    self setstance( "stand" );
    self allowstand( 1 );
    self allowcrouch( 0 );
    self allowprone( 0 );
    self playerlinktodelta( m_linkpoint, "tag_origin", 1, 20, 20, 20, 20 );
    self setplayerangles( m_linkpoint.angles );
    self playsoundtoplayer( "zmb_electric_chair_2d", self );
    self do_player_general_vox( "quest", "chair_electrocution", undefined, 100 );
    self ghost();
    self.ignoreme = 1;
    self.dontspeak = 1;
    self setclientfieldtoplayer( "isspeaking", 1 );
    wait( n_effects_duration - 2 );

    switch ( self.character_name )
    {
        case "Arlington":
            self playsoundontag( "vox_plr_3_arlington_electrocution_0", "J_Head" );
            break;
        case "Sal":
            self playsoundontag( "vox_plr_1_sal_electrocution_0", "J_Head" );
            break;
        case "Billy":
            self playsoundontag( "vox_plr_2_billy_electrocution_0", "J_Head" );
            break;
        case "Finn":
            self playsoundontag( "vox_plr_0_finn_electrocution_0", "J_Head" );
            break;
    }

    wait 2;
    level.zones["zone_golden_gate_bridge"].is_enabled = 1;
    level.zones["zone_golden_gate_bridge"].is_spawning_allowed = 1;
    self.keep_perks = 1;
	if(!self.alreadyingodmode)
	{
		self disableinvulnerability();
	}
    self.afterlife = 1;
    self thread afterlife_laststand( 1 );
    self unlink();
    self setstance( "stand" );
    self waittill( "player_fake_corpse_created" );
    self thread track_player_completed_cycle();
    trace_start = e_corpse_location.origin + vectorscale( ( 0, 0, 1 ), 100.0 );
    trace_end = e_corpse_location.origin + vectorscale( ( 0, 0, -1 ), 100.0 );
    corpse_trace = bullettrace( trace_start, trace_end, 0, self.e_afterlife_corpse );
    self.e_afterlife_corpse.origin = corpse_trace["position"];
    self setorigin( e_home_telepoint.origin );
    self enableweapons();
    self setclientfieldtoplayer( "rumble_electric_chair", 0 );

    if ( level.n_quest_iteration_count == 2 )
    {
        self waittill( "player_revived" );
        wait 1;
        self do_player_general_vox( "quest", "start_2", undefined, 100 );
    }
}

plane_boarding_thread_new()
{
    self endon( "death_or_disconnect" );
    flag_set( "plane_is_away" );

	self thread player_disconnect_watcher();
    self thread player_death_watcher();
/#
    iprintlnbold( "plane boarding thread started" );
#/
    flag_set( "plane_boarded" );
    self setclientfieldtoplayer( "effects_escape_flight", 1 );
    level.brutus_respawn_after_despawn = 0;
    a_nml_teleport_targets = [];

    for ( i = 1; i < 6; i++ )
        a_nml_teleport_targets[i - 1] = getstruct( "nml_telepoint_" + i, "targetname" );

    level.characters_in_nml[level.characters_in_nml.size] = self.character_name;
    self.on_a_plane = 1;
    level.someone_has_visited_nml = 1;
    self.n_passenger_index = level.characters_in_nml.size;
    m_plane_craftable = getent( "plane_craftable", "targetname" );
    m_plane_about_to_crash = getent( "plane_about_to_crash", "targetname" );
    veh_plane_flyable = getent( "plane_flyable", "targetname" );
    t_plane_fly = getent( "plane_fly_trigger", "targetname" );
    t_plane_fly sethintstring( &"ZM_PRISON_PLANE_BOARD" );
	self.alreadyingodmode = isgodmode( self );
    self enableinvulnerability();
    self playerlinktodelta( m_plane_craftable, "tag_player_crouched_" + ( self.n_passenger_index + 1 ) );
    self allowstand( 0 );
    flag_wait( "plane_departed" );
    level notify( "sndStopBrutusLoop" );
    self clientnotify( "sndPS" );
    self playsoundtoplayer( "zmb_plane_takeoff", self );
    level thread maps\mp\zombies\_zm_audio::sndmusicstingerevent( "plane_takeoff", self );
    self playerlinktodelta( veh_plane_flyable, "tag_player_crouched_" + ( self.n_passenger_index + 1 ) );
    self setclientfieldtoplayer( "effects_escape_flight", 2 );
    flag_wait( "plane_approach_bridge" );
    self thread snddelayedimp();
    self setclientfieldtoplayer( "effects_escape_flight", 3 );
    self unlink();
    self playerlinktoabsolute( veh_plane_flyable, "tag_player_crouched_" + ( self.n_passenger_index + 1 ) );
    flag_wait( "plane_zapped" );
    flag_set( "activate_player_zone_bridge" );
    self playsoundtoplayer( "zmb_plane_fall", self );
    self setclientfieldtoplayer( "effects_escape_flight", 4 );
    self.dontspeak = 1;
    self setclientfieldtoplayer( "isspeaking", 1 );
    self playerlinktodelta( m_plane_about_to_crash, "tag_player_crouched_" + ( self.n_passenger_index + 1 ), 1, 0, 0, 0, 0, 1 );
    self forcegrenadethrow();
    str_current_weapon = self getcurrentweapon();
    self giveweapon( "falling_hands_zm" );
    self switchtoweaponimmediate( "falling_hands_zm" );
    self setweaponammoclip( "falling_hands_zm", 0 );
    players = getplayers();

    foreach ( player in players )
    {
        if ( player != self )
            player setinvisibletoplayer( self );
    }

    flag_wait( "plane_crashed" );
    self setclientfieldtoplayer( "effects_escape_flight", 5 );
    self takeweapon( "falling_hands_zm" );

    if ( isdefined( str_current_weapon ) && str_current_weapon != "none" )
        self switchtoweaponimmediate( str_current_weapon );

    self thread fadetoblackforxsec( 0, 2, 0, 0.5, "black" );
    self thread snddelayedmusic();
    self unlink();
    self allowstand( 1 );
    self setstance( "stand" );
    players = getplayers();

    foreach ( player in players )
    {
        if ( player != self )
            player setvisibletoplayer( self );
    }

    flag_clear( "spawn_zombies" );
    self setorigin( a_nml_teleport_targets[self.n_passenger_index].origin );
    e_poi = getstruct( "plane_crash_poi", "targetname" );
    vec_to_target = e_poi.origin - self.origin;
    vec_to_target = vectortoangles( vec_to_target );
    vec_to_target = ( 0, vec_to_target[1], 0 );
    self setplayerangles( vec_to_target );
    n_shellshock_duration = 5;
    self shellshock( "explosion", n_shellshock_duration );
    self.dontspeak = 0;
    self setclientfieldtoplayer( "isspeaking", 0 );
    self notify( "player_at_bridge" );
    wait( n_shellshock_duration );
	if(!self.alreadyingodmode)
	{
		self disableinvulnerability();
	}
    self.on_a_plane = 0;

    if ( level.characters_in_nml.size == 1 )
        self vo_bridge_soliloquy();
    else if ( level.characters_in_nml.size == 4 )
        vo_bridge_four_part_convo();

    wait 10;
    self playsoundtoplayer( "zmb_ggb_swarm_start", self );
    flag_set( "spawn_zombies" );
    level.brutus_respawn_after_despawn = 1;
    wait 5;
    character_name = level.characters_in_nml[randomintrange( 0, level.characters_in_nml.size )];
    players = getplayers();

    foreach ( player in players )
    {
        if ( isdefined( player ) && player.character_name == character_name )
            player thread do_player_general_vox( "quest", "zombie_arrive_gg", undefined, 100 );
    }
}

afterlife_fake_death_new()
{
    level notify( "fake_death" );
    self notify( "fake_death" );
    self takeallweapons();
    self allowstand( 0 );
    self allowcrouch( 0 );
    self allowprone( 1 );
    self setstance( "prone" );

    if ( self is_jumping() )
    {
        while ( self is_jumping() )
            wait 0.05;
    }

    playfx( level._effect["afterlife_enter"], self.origin );
    self.ignoreme = 1;
	self.alreadyingodmode = isgodmode( self );
    self enableinvulnerability();
    self freezecontrols( 1 );
}

electric_chair_trigger_thread_new( chair_number )
{
    level notify( "electric_chair_trigger_thread_" + chair_number );
    level endon( "electric_chair_trigger_thread_" + chair_number );
    m_electric_chair = getent( "electric_chair_" + chair_number, "targetname" );
    n_effects_wait_1 = 4;
    n_effects_wait_2 = 0.15;
    n_effects_wait_3 = 2;
    n_effects_wait_4 = 2;
    n_effects_duration = n_effects_wait_1 + n_effects_wait_2 + n_effects_wait_3 + n_effects_wait_4;

    while ( true )
    {
        self waittill( "trigger", e_triggerer );
        character_name = e_triggerer.character_name;

        if ( isplayer( e_triggerer ) && is_player_valid( e_triggerer ) )
        {
            e_triggerer.alreadyingodmode = isgodmode( e_triggerer );
			e_triggerer enableinvulnerability();
            self sethintstring( "" );
            self trigger_off();
            flag_set( "plane_trip_to_nml_successful" );

            if ( level.characters_in_nml.size == 1 )
                clean_up_bridge_brutuses();

            v_origin = m_electric_chair gettagorigin( "seated" ) + ( 10, 0, -40 );
            v_seated_angles = m_electric_chair gettagangles( "seated" );
            m_linkpoint = spawn_model( "tag_origin", v_origin, v_seated_angles );

            if ( isdefined( level.electric_chair_player_thread_custom_func ) )
                e_triggerer thread [[ level.electric_chair_player_thread_custom_func ]]( m_linkpoint, chair_number, n_effects_duration );
            else
                e_triggerer thread electric_chair_player_thread( m_linkpoint, chair_number, n_effects_duration );

            chair_corpse = e_triggerer maps\mp\zombies\_zm_clone::spawn_player_clone( e_triggerer, e_triggerer.origin, undefined );
            chair_corpse linkto( m_electric_chair, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
            chair_corpse.ignoreme = 1;
            chair_corpse show();
            chair_corpse detachall();
            chair_corpse setvisibletoall();
            chair_corpse setinvisibletoplayer( e_triggerer );
            chair_corpse maps\mp\zombies\_zm_clone::clone_animate( "chair" );

            if ( isdefined( e_triggerer ) )
                e_triggerer setclientfieldtoplayer( "rumble_electric_chair", 1 );

            wait( n_effects_wait_1 );
            m_fx_1 = spawn_model( "tag_origin", ( -516.883, -3912.04, -7494.9 ), vectorscale( ( 0, 1, 0 ), 180.0 ) );
            m_fx_2 = spawn_model( "tag_origin", ( -517.024, -3252.66, -7496.2 ), ( 0, 0, 0 ) );
            level setclientfield( "scripted_lightning_flash", 1 );
            wait( n_effects_wait_2 );
            playfxontag( level._effect["fx_alcatraz_lightning_finale"], m_fx_1, "tag_origin" );
            playfxontag( level._effect["fx_alcatraz_lightning_finale"], m_fx_2, "tag_origin" );
            m_fx_3 = spawn_model( "tag_origin", ( -753.495, -3092.62, -8416.6 ), vectorscale( ( 1, 0, 0 ), 270.0 ) );
            playfxontag( level._effect["fx_alcatraz_lightning_wire"], m_fx_3, "tag_origin" );
            wait( n_effects_wait_3 );
            m_electric_chair play_fx( "fx_alcatraz_elec_chair", m_electric_chair.origin, m_electric_chair.angles, "bridge_empty" );

            if ( isdefined( e_triggerer ) )
                e_triggerer setclientfieldtoplayer( "rumble_electric_chair", 2 );

            wait( n_effects_wait_4 );
            playfxontag( level._effect["fx_alcatraz_afterlife_zmb_tport"], m_electric_chair, "tag_origin" );

            if ( isdefined( e_triggerer ) )
                e_triggerer playsoundtoplayer( "zmb_afterlife_death", e_triggerer );

            chair_corpse delete();

            if ( level.characters_in_nml.size == 1 )
                clean_up_bridge_brutuses();

            if ( isinarray( level.characters_in_nml, character_name ) )
                arrayremovevalue( level.characters_in_nml, character_name );

            m_fx_1 delete();
            m_fx_2 delete();
            self sethintstring( &"ZM_PRISON_ELECTRIC_CHAIR_ACTIVATE" );
            self trigger_on();
        }
    }
}

zm_player_fake_death_new( vdir )
{
    level notify( "fake_death" );
    self notify( "fake_death" );
    stance = self getstance();
    self.ignoreme = 1;
	self.alreadyingodmode = isgodmode( self );
    self enableinvulnerability();
    self takeallweapons();

    if ( isdefined( self.insta_killed ) && self.insta_killed )
    {
        self maps\mp\zombies\_zm::player_fake_death();
        self allowprone( 1 );
        self allowcrouch( 0 );
        self allowstand( 0 );
        wait 0.25;
        self freezecontrols( 1 );
    }
    else
    {
        self freezecontrols( 1 );
        self thread fall_down( vdir, stance );
        wait 1;
    }
}