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
#include maps\mp\_visionset_mgr;
#include maps\mp\zombies\_zm_ai_avogadro;
#include maps\mp\zm_transit_bus;
#include maps\mp\zombies\_zm_ai_basic;
#include maps\mp\zm_tranzit;
#include scripts\zm\main;
#include maps\mp\zm_transit_sq;


main()
{
	replacefunc(maps\mp\zm_transit_utility::solo_tombstone_removal, ::solo_tombstone_removal_new);
	replaceFunc(maps\mp\zombies\_zm_ai_avogadro::cloud_update_fx, ::custom_cloud_update_fx);
	replacefunc(maps\mp\zm_transit_sq::richtofen_sidequest_a, ::richtofen_sidequest_a_new);
	replacefunc(maps\mp\zm_transit_sq::maxis_sidequest_complete, ::maxis_sidequest_complete_new);
	replacefunc(maps\mp\zm_transit::include_equipment_for_level, ::include_equipment_for_level);
//	replaceFunc(maps\mp\zm_transit_sq::richtofen_sidequest_c, ::custom_richtofen_sidequest_c);
	
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
	replacefunc(maps\mp\zm_transit_lava::player_lava_damage, ::player_lava_damage);
    level thread onPlayerConnect();
}

init()
{
	if(getDvar("mapname") == "zm_transit")
	{
		if(getDvar("g_gametype") == "zclassic")
		{
			if(getDvarInt("tranzit_tedd_tracker") == 1)
			{
				level thread TEDDTrackerHUD();
			}
			level thread power_station_vision_change();
		}
	}
	
	if( getPlayers() <= 1 )
	{
		replaceFunc(maps\mp\zm_transit_sq::get_how_many_progressed_from, ::custom_get_how_many_progressed_from);
		replaceFunc(maps\mp\zm_transit_sq::maxis_sidequest_b, ::custom_maxis_sidequest_b);
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

        if ( isplayer( who ) && isalive( who ) && who getcurrentweapon() == "jetgun_zm" && who attackbuttonpressed())
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

custom_get_how_many_progressed_from( story, a, b )
{
	if ( isDefined( level.sq_progress[ story ][ a ] ) || isDefined( level.sq_progress[ story ][ b ] ) )
	{
		return 2;
	}
	return 0;
}

custom_maxis_sidequest_b()
{
	level endon( "power_on" );
	while ( 1 )
	{
		level waittill( "stun_avogadro", avogadro );
		if ( isDefined( level.sq_progress[ "maxis" ][ "A_turbine_1" ] ) && is_true( level.sq_progress[ "maxis" ][ "A_turbine_1" ].powered ) )
		{
			if ( isDefined( avogadro ) && avogadro istouching( level.sq_volume ) )
			{
				level notify( "end_avogadro_turbines" );
				break;
			}
		}
		else
		{
		}
	}
	level notify( "maxis_stage_b" );
	level thread maxissay( "vox_maxi_avogadro_emp_0", ( 7737, -416, -142 ) );
	update_sidequest_stats( "sq_transit_maxis_stage_3" );
	player = get_players();
	player[ 0 ] setclientfield( "sq_tower_sparks", 1 );
	player[ 0 ] setclientfield( "screecher_maxis_lights", 1 );
	level thread maxis_sidequest_complete_check( "B_complete" );
}

maxis_sidequest_complete_new()
{
    turbinescriptnoteworthy1 = undefined;
    turbinescriptnoteworthy2 = undefined;

    if ( isdefined( level.sq_progress["maxis"]["C_screecher_1"] ) && isdefined( level.sq_progress["maxis"]["C_screecher_1"].script_noteworthy ) )
        turbinescriptnoteworthy1 = level.sq_progress["maxis"]["C_screecher_1"].script_noteworthy;

    if ( isdefined( level.sq_progress["maxis"]["C_screecher_2"] ) && isdefined( level.sq_progress["maxis"]["C_screecher_2"].script_noteworthy ) )
        turbinescriptnoteworthy2 = level.sq_progress["maxis"]["C_screecher_2"].script_noteworthy;

    update_sidequest_stats( "sq_transit_maxis_complete" );
    level sidequest_complete( "maxis" );
    level.sq_progress["maxis"]["FINISHED"] = 1;
    level.maxcompleted = 1;
    clientnotify( "sq_kfx" );

    if ( isdefined( level.richcompleted ) && level.richcompleted )
        level clientnotify( "sq_krt" );

    wait 1;
    clientnotify( "sqm" );
    wait 1;
    level set_screecher_zone_origin( turbinescriptnoteworthy1 );
    wait 1;
    clientnotify( "sq_max" );
    wait 1;
    level set_screecher_zone_origin( turbinescriptnoteworthy2 );
    wait 1;
    clientnotify( "sq_max" );
    level thread droppowerup( "maxis" );
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

custom_cloud_update_fx()
{
	self endon( "cloud_fx_end" );
	level endon( "end_game" );
	region = [];
	region[ 0 ] = "cornfield";
	self.current_region = undefined;
	if ( !isDefined( self.sndent ) )
	{
		self.sndent = spawn( "script_origin", ( 0, 0, 1 ) );
		self.sndent playloopsound( "zmb_avogadro_thunder_overhead" );
	}
	cloud_time = getTime();
	vo_counter = 0;
	while ( 1 )
	{
		if ( getTime() >= cloud_time )
		{
			if ( isDefined( self.current_region ) )
			{
				exploder_num = level.transit_region[ self.current_region ].exploder;
				stop_exploder( exploder_num );
			}
			rand_region = array_randomize( region );
			region_str = rand_region[ 0 ];
			if ( !isDefined( self.current_region ) )
			{
				region_str = region[ 0 ];
			}
			idx = 0;
			if ( idx >= 0 )
			{
				region_str = region[ idx ];
			}
			avogadro_print( "clouds in region " + region_str );
			self.current_region = region_str;
			exploder_num = level.transit_region[ region_str ].exploder;
			exploder( exploder_num );
			self.sndent moveto( level.transit_region[ region_str ].sndorigin, 3 );
			cloud_time = getTime() + 30000;
		}
		if ( vo_counter > 50 )
		{
			player = self get_player_in_region();
			if ( isDefined( player ) )
			{
				if ( isDefined( self._in_cloud ) && self._in_cloud )
				{
					player thread do_player_general_vox( "general", "avogadro_above", 90, 10 );
				}
				else
				{
					player thread do_player_general_vox( "general", "avogadro_arrive", 60, 40 );
				}
			}
			else
			{
				level thread avogadro_storm_vox();
			}
			vo_counter = 0;
		}
		wait 0.1;
		vo_counter++;
	}
}

give_personality_characters()
{
    if ( isdefined( level.hotjoin_player_setup ) && [[ level.hotjoin_player_setup ]]( "c_zom_farmgirl_viewhands" ) )
        return;

    self detachall();

	self thread character_selector();

//    if ( !isdefined( self.characterindex ) )
//        self.characterindex = assign_lowest_unused_character_index();

    self.favorite_wall_weapons_list = [];
    self.talks_in_danger = 0;
/#
    if ( getdvar( #"_id_40772CF1" ) != "" )
        self.characterindex = getdvarint( #"_id_40772CF1" );
#/

    self character\c_transit_player_oldman::main();
    self setviewmodel( "c_zom_oldman_viewhands" );
    level.vox maps\mp\zombies\_zm_audio::zmbvoxinitspeaker( "player", "vox_plr_", self );
    self.favorite_wall_weapons_list[self.favorite_wall_weapons_list.size] = "frag_grenade_zm";
    self.favorite_wall_weapons_list[self.favorite_wall_weapons_list.size] = "claymore_zm";
    self set_player_is_female( 0 );

    self setmovespeedscale( 1 );
    self setsprintduration( 4 );
    self setsprintcooldown( 0 );
    self set_player_tombstone_index();
    self thread set_exert_id();
}

character_selector()
{
	self thread character_input();
	
	self waittill ("character_change");
	
	self.ignoreme = 0;
	
	self freezecontrols( 0 );
}

change_character(characternum)
{
	
	switch ( characternum )
    {
        case 2:
            self character\c_transit_player_farmgirl::main();
            self setviewmodel( "c_zom_farmgirl_viewhands" );
            level.vox maps\mp\zombies\_zm_audio::zmbvoxinitspeaker( "player", "vox_plr_", self );
            self.favorite_wall_weapons_list[self.favorite_wall_weapons_list.size] = "rottweil72_zm";
            self.favorite_wall_weapons_list[self.favorite_wall_weapons_list.size] = "870mcs_zm";
            self set_player_is_female( 1 );
            break;
        case 0:
            self character\c_transit_player_oldman::main();
            self setviewmodel( "c_zom_oldman_viewhands" );
            level.vox maps\mp\zombies\_zm_audio::zmbvoxinitspeaker( "player", "vox_plr_", self );
            self.favorite_wall_weapons_list[self.favorite_wall_weapons_list.size] = "frag_grenade_zm";
            self.favorite_wall_weapons_list[self.favorite_wall_weapons_list.size] = "claymore_zm";
            self set_player_is_female( 0 );
            break;
        case 3:
            self character\c_transit_player_engineer::main();
            self setviewmodel( "c_zom_engineer_viewhands" );
            level.vox maps\mp\zombies\_zm_audio::zmbvoxinitspeaker( "player", "vox_plr_", self );
            self.favorite_wall_weapons_list[self.favorite_wall_weapons_list.size] = "m14_zm";
            self.favorite_wall_weapons_list[self.favorite_wall_weapons_list.size] = "m16_zm";
            self set_player_is_female( 0 );
            break;
        case 1:
            self character\c_transit_player_reporter::main();
            self setviewmodel( "c_zom_reporter_viewhands" );
            level.vox maps\mp\zombies\_zm_audio::zmbvoxinitspeaker( "player", "vox_plr_", self );
            self.talks_in_danger = 1;
            level.rich_sq_player = self;
            self.favorite_wall_weapons_list[self.favorite_wall_weapons_list.size] = "beretta93r_zm";
            self set_player_is_female( 0 );
            break;
    }

	self.characterindex = characternum;
    self thread set_exert_id();
}

character_input()
{
	self endon ("character_change");
	
	for(;;)
	{
		self.ignoreme = 1;
		
		self freezecontrols( 1 );
		
		if(self actionslotfourbuttonpressed())
			self change_character(3);
			self notify ("character_change");
		if(self actionslotthreebuttonpressed())
			self change_character(2);
			self notify ("character_change");
		if(self actionslottwobuttonpressed())
			self change_character(1);
			self notify ("character_change");
		if(self actionslotonebuttonpressed())
			self change_character(0);
			self notify ("character_change");
		wait 0.01;
	}
}

assign_lowest_unused_character_index()
{
    charindexarray = [];
    charindexarray[0] = 0;
    charindexarray[1] = 1;
    charindexarray[2] = 2;
    charindexarray[3] = 3;
    players = get_players();
	if ( players.size == 1 )
    {
        return 1;
    }
    else if ( players.size == 2 )
    {
        foreach ( player in players )
        {
            if ( isdefined( player.characterindex ) )
            {
                if ( player.characterindex == 2 || player.characterindex == 0 )
                {
                    if ( randomint( 100 ) > 50 )
                        return 1;

                    return 3;
                }
                else if ( player.characterindex == 3 || player.characterindex == 1 )
                {
                    if ( randomint( 100 ) > 50 )
                        return 0;

                    return 2;
                }
            }
        }
    }
    else
    {
        foreach ( player in players )
        {
            if ( isdefined( player.characterindex ) )
                arrayremovevalue( charindexarray, player.characterindex, 0 );
        }

        if ( charindexarray.size > 0 )
            return charindexarray[0];
    }

    return 0;
}

include_equipment_for_level()
{
    level.equipment_turret_needs_power = 1;
    level.equipment_etrap_needs_power = 1;
    include_equipment( "jetgun_zm" );
    include_equipment( "riotshield_zm" );
    include_equipment( "equip_turbine_zm" );
    include_equipment( "equip_turret_zm" );
    include_equipment( "equip_electrictrap_zm" );
    level.equipment_planted = ::equipment_planted;
    level.equipment_safe_to_drop = ::equipment_safe_to_drop;
    level.check_force_deploy_origin = ::use_safe_spawn_on_bus;
    level.explode_overheated_jetgun = 1;
    level.exploding_jetgun_fx = level._effect["lava_burning"];
}

power_station_vision_change()
{
	level.default_r_exposureValue = 3;
	level.changed_r_exposureValue = 4;
	time = 1;

	flag_wait("start_zombie_round_logic");

	while (1)
	{
		players = get_players();

		foreach (player in players)
		{
			if (!isDefined(player.power_station_vision_set))
			{
				player.power_station_vision_set = 0;
				player.r_exposureValue = level.default_r_exposureValue;
				player setClientDvar("r_exposureTweak", 1);
				player setClientDvar("r_exposureValue", level.default_r_exposureValue);
			}

			spectating_player = player get_current_spectating_player();

			if (!player.power_station_vision_set)
			{
				if (spectating_player maps\mp\zombies\_zm_zonemgr::entity_in_zone("zone_prr") || spectating_player maps\mp\zombies\_zm_zonemgr::entity_in_zone("zone_pcr"))
				{
					player.power_station_vision_set = 1;
					player thread change_dvar_over_time("r_exposureValue", level.changed_r_exposureValue, time, 1);
				}
			}
			else
			{
				if (!(spectating_player maps\mp\zombies\_zm_zonemgr::entity_in_zone("zone_prr") || spectating_player maps\mp\zombies\_zm_zonemgr::entity_in_zone("zone_pcr")))
				{
					player.power_station_vision_set = 0;
					player thread change_dvar_over_time("r_exposureValue", level.default_r_exposureValue, time, 0);
				}
			}
		}

		wait 0.05;
	}
}

change_dvar_over_time(dvar, val, time, increment)
{
	self notify("change_dvar_over_time");
	self endon("change_dvar_over_time");

	intervals = time * 20;
	rate = (level.changed_r_exposureValue - level.default_r_exposureValue) / intervals;

	i = 0;

	while (i < intervals)
	{
		if (increment)
		{
			self.r_exposureValue += rate;

			if (self.r_exposureValue > val)
			{
				self.r_exposureValue = val;
			}
		}
		else
		{
			self.r_exposureValue -= rate;

			if (self.r_exposureValue < val)
			{
				self.r_exposureValue = val;
			}
		}

		self setClientDvar(dvar, self.r_exposureValue);

		if (self.r_exposureValue == val)
		{
			return;
		}

		i++;
		wait 0.05;
	}

	self setClientDvar(dvar, val);
}

get_current_spectating_player()
{
	if (self.currentspectatingclient == -1)
	{
		return self;
	}

	players = get_players();

	foreach (player in players)
	{
		if (self.currentspectatingclient == player getentitynumber())
		{
			return player;
		}
	}

	return self;
}

custom_richtofen_sidequest_c()
{
	level endon( "power_off" );
	level endon( "richtofen_sq_complete" );
	setDvar( "scr_screecher_ignore_player", 0 );
	screech_zones = getstructarray( "screecher_escape", "targetname" );
	level thread screecher_light_hint();
	level thread screecher_light_on_sq();
	level.sq_richtofen_c_screecher_lights = [];
	while ( 1 )
	{
		level waittill( "safety_light_power_off", screecher_zone );
		while ( !level.sq_progress[ "rich" ][ "A_complete" ] || !level.sq_progress[ "rich" ][ "B_complete" ] )
		{
			level thread richtofensay( "vox_zmba_sidequest_emp_nomag_0" );
		}
		level.sq_richtofen_c_screecher_lights[ level.sq_richtofen_c_screecher_lights.size ] = screecher_zone;
		level.sq_progress[ "rich" ][ "C_screecher_light" ]++;
		if ( level.sq_progress[ "rich" ][ "C_screecher_light" ] >= level.player.size )
		{
			break;
		}
		else
		{
			if ( isDefined( level.checking_for_richtofen_c_failure ) && !level.checking_for_richtofen_c_failure )
			{
				level thread check_for_richtofen_c_failure();
			}
		}
	}
	level thread richtofensay( "vox_zmba_sidequest_4emp_mag_0" );
	level notify( "richtofen_c_complete" );
	if (getDvarInt("enable_denizens") == 1)
		setDvar( "scr_screecher_ignore_player", 0 );
	else
		setDvar( "scr_screecher_ignore_player", 1 );
	player = get_players();
	player[ 0 ] setclientfield( "screecher_sq_lights", 0 );
	level thread richtofen_sidequest_complete_check( "C_complete" );
}

player_lava_damage( trig )
{
    self endon( "zombified" );
    self endon( "death" );
    self endon( "disconnect" );
    max_dmg = 15;
    min_dmg = 5;
    burn_time = 1;

    if ( isdefined( self.is_zombie ) && self.is_zombie )
        return;

    self thread player_stop_burning();

    if ( isdefined( trig.script_float ) )
    {
        max_dmg = max_dmg * trig.script_float;
        min_dmg = min_dmg * trig.script_float;
        burn_time = burn_time * trig.script_float;

        if ( burn_time >= 1.5 )
            burn_time = 1.5;
    }

    if ( !isdefined( self.is_burning ) && is_player_valid( self ) && self player_can_burn())
    {
        self.is_burning = 1;
        maps\mp\_visionset_mgr::vsmgr_activate( "overlay", "zm_transit_burn", self, burn_time, level.zm_transit_burn_max_duration );
        self notify( "burned" );

        if ( isdefined( trig.script_float ) && trig.script_float >= 0.1 )
            self thread player_burning_fx();

        if ( !self hasperk( "specialty_armorvest" ) || self.health - 100 < 1 )
        {
            radiusdamage( self.origin, 10, max_dmg, min_dmg );
            wait 0.5;
            self.is_burning = undefined;
        }
        else
        {
            if ( self hasperk( "specialty_armorvest" ) )
                self dodamage( 15, self.origin );
            else
                self dodamage( 1, self.origin );

            wait 0.5;
            self.is_burning = undefined;
        }
    }
}

player_can_burn()
{
	return true;
	
	if(getDvarInt("enable_lavadamage") == 0)
	{
		return false;
	}
	else if(getDvarInt("enable_lavadamage") == 1)
	{
		return true;
	}
	else if(getDvarInt("enable_lavadamage") == 2)
	{
		if(!self hasperk ("specialty_divetonuke_zombies"))
		{
			return true;
		}
		return false;
	}
	else
	{
		return false;
	}
}