#include maps\mp\_utility;
#include maps\_utility;
#include maps\_effects;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_zonemgr;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zm_transit_bus;
#include maps\mp\zm_transit_utility;
#include maps\mp\zombies\_zm_power;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_magicbox;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\zombies\_zm_pers_upgrades_functions;
#include maps\mp\zombies\_zm_audio;
#include maps\mp\_demo;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_score;
#include maps\mp\zombies\_zm_chugabud;
#include maps\mp\_visionset_mgr;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_powerups;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\zombies\_zm_audio_announcer;
#include maps\mp\zombies\_zm_blockers;

main()
{
	replacefunc(maps\mp\zombies\_zm_utility::wait_network_frame, ::wait_network_frame);

	create_dvar("gamemode", 0);
	create_dvar("gungame_ladder", 1);
	
	precacheshader("scorebar_zom_1");
   	precacheshader("menu_mp_weapons_1911");
	precacheshader("demo_pause");
	
	precachemodel("zombie_sign_please_wait");
	precachemodel("zombie_skull");

	replacefunc(maps\mp\zombies\_zm_buildables::buildable_use_hold_think_internal, ::buildable_use_hold_think_internal_new);

	replacefunc(maps\mp\zombies\_zm_pers_upgrades::pers_upgrade_init, ::pers_upgrade_init_new);
	replacefunc(maps\mp\zombies\_zm_magicbox::treasure_chest_move, ::treasure_chest_move_new);
	replacefunc(maps\mp\zombies\_zm_magicbox::treasure_chest_weapon_spawn, ::treasure_chest_weapon_spawn_new);
	
	replacefunc(maps\mp\zombies\_zm_blockers::blocker_trigger_think, ::blocker_trigger_think_new);
	
	if(getDvarInt("gamemode") == 0)
	{
		replacefunc(maps\mp\zombies\_zm::round_think, ::new_round_think);
		replacefunc(maps\mp\zombies\_zm::round_over, ::new_round_over);	

		replacefunc(maps\mp\zombies\_zm_powerups::full_ammo_on_hud, ::full_ammo_on_hud_new);
		replacefunc(maps\mp\zombies\_zm_powerups::start_fire_sale, ::start_fire_sale_new);
		replacefunc(maps\mp\zombies\_zm_powerups::insta_kill_powerup, ::insta_kill_powerup_new);
		replacefunc(maps\mp\zombies\_zm_powerups::double_points_powerup, ::double_points_powerup_new);
		replacefunc(maps\mp\zombies\_zm_powerups::start_carpenter, ::new_start_carpenter);
		replacefunc(maps\mp\zombies\_zm_powerups::start_carpenter_new, ::new_start_carpenter_new);
		replacefunc(maps\mp\zombies\_zm_powerups::full_ammo_powerup, ::full_ammo_powerup_new);
		
		replacefunc(maps\mp\zombies\_zm_power::change_power, ::change_power_new);
		
		replacefunc(maps\mp\zombies\_zm::round_wait, ::round_wait_exfil);
	}
	else
	{
		replacefunc(maps\mp\zombies\_zm_audio_announcer::init, ::init_audio_announcer);

		replacefunc(maps\mp\zombies\_zm::round_think, ::round_think_minigame);
		
		if(getDvarInt("gamemode") != 3)
		{
			replacefunc(maps\mp\zombies\_zm::round_wait, ::round_wait_minigame);
			replacefunc(maps\mp\zombies\_zm::round_over, ::round_over_minigame);
		}
		
		if(getDvarInt("gamemode") == 1 || getDvarInt("gamemode") == 3)
		{
			replacefunc(maps\mp\zombies\_zm_magicbox::treasure_chest_init, ::new_treasure_chest_init);
			replacefunc(maps\mp\zombies\_zm_weapons::weapon_spawn_think, ::new_weapon_spawn_think);
			if(getDvarInt("gamemode") == 1)
			{
				replacefunc(maps\mp\zombies\_zm_perks::vending_weapon_upgrade, ::new_vending_weapon_upgrade);
	
				replacefunc(maps\mp\zombies\_zm_laststand::auto_revive, ::auto_revive_gungame);
				replacefunc(maps\mp\zombies\_zm::player_damage_override, ::player_damage_override_gungame);
				replacefunc(maps\mp\zombies\_zm_powerups::powerup_grab, ::powerup_grab_gungame);
				replacefunc(maps\mp\zombies\_zm_powerups::init_powerups, ::init_powerups_minigame);
				replacefunc(maps\mp\zombies\_zm::end_game, ::end_game_minigame);
			}
		}
	}

	init_dvars();
	main_directorscut();
}

wait_network_frame()
{
	wait 0.01;
}


init()
{
    level thread onPlayerConnect();
    level thread betaMessage();
    level thread command_thread();
    level thread updateSomeSettings();
    
	precacheshader("riotshield_zm_icon");
	precacheshader("zm_riotshield_tomb_icon");
	precacheshader("zm_riotshield_hellcatraz_icon");
	precacheshader("menu_mp_fileshare_custom");

	level.player_out_of_playable_area_monitor = 0;

//    level thread featuresList();
    
    level.modlist = [];
    level.modids = [];

	if( getDvarInt("gamemode") != 0)
	{
		if (getDvarInt("gamemode") != 3)
		{
			init_gamemode_powerups();
		}
		level.perk_purchase_limit = 9;
		level.playersready = 0;
		if(getDvarInt("gamemode") == 1)
		{
			level.gungamestarted = 0;
			level.zombieskilled = 0;
			createlist();
			
			for( i = 0; i < 8; i++ )
			{
				thread playerScoresHUD(i, level.players[i]);
				wait 0.01;
			}
			level thread introHUD();
			
		}
		else if (getDvarInt("gamemode") == 2)
		{
			level.maxtime = 300;
			level.roundspassed = 1;
			level.crankedstarted = 0;
			level.zombieskilled = 0;
			level thread maintain_zombie_count();
			
			level.zombie_vars["zombie_powerup_fire_sale_on"] = 1;
		
			for ( i = 0; i < level.chests.size; i++ )
			{
				if ( level.chest_index != i )
				{
					level.chests[i].was_temp = 0;

					if ( is_true( level.chests[i].hidden ) )
						level.chests[i] thread maps\mp\zombies\_zm_magicbox::show_chest();

					wait_network_frame();
				}
			}
			level thread introHUD();
		}
		else if(getDvarInt("gamemode") == 3)
		{
			level.perk_purchase_limit = 9;
			level thread createMysterylist();
			level.playersready = 0;
			level.mysterygunsstarted = 0;
			level thread roll_weapon_on_round_over();
			level thread introHUD();			
		}
		if (getDvarInt("gamemode") == 2)
		{
			level thread nextroundtimer();
		}
		level.leaper_rounds_enabled = 0;
	}

    if (getDvarInt("enable_rampage") == 1 && getDvarInt("gamemode") == 0)
    {
    	init_rageinducer();
    	level.modlist[level.modlist.size] = "Rampage Statue";
    	level.modids[level.modids.size] = "rampage";
    }

    if (getDvarInt("enable_origins_mud") == 0)
    {
    	level.a_e_slow_areas = 0;
    }
    
	if(getDvarInt("enable_match_timer") == 1 && getDvarInt("gamemode") == 0)
	{
		level thread timer_hud();
	}
	
    if ((getDvarInt("enable_compass") == 1) || (getDvarInt("max_clients") > 4))
	{
    	if(getDvarInt("gamemode") == 0)
		{
			init_compass();
			level.modlist[level.modlist.size] = "Compass";
			level.modids[level.modids.size] = "compass";
		}
    }
    	
    if ((getDvarInt("enable_notifier") == 1) || (getDvarInt("max_clients") > 4))
    {
    	if(getDvarInt("gamemode") == 0)
		{
			init_zonenotifer();
			level.modlist[level.modlist.size] = "Zone Notifier";
			level.modids[level.modids.size] = "zonenotifier";
		}
    }
    	
    if (getDvarInt("enable_bonuspoints") == 1)
    	init_bonuspoints();
    	level.modlist[level.modlist.size] = "Bonus Points";
    	level.modids[level.modids.size] = "bonuspoints";
    	
    if (getDvarInt("enable_usefulnuke") == 1)
    {
    	init_usefulnuke();
    	level.modlist[level.modlist.size] = "Useful Nuke";
    	level.modids[level.modids.size] = "usefulnuke";
    }
    	
    if (getDvarInt("enable_bo4ammo") == 1)
    {
    	init_bo4ammo();
    	level.modlist[level.modlist.size] = "Bo4 Ammo";
    	level.modids[level.modids.size] = "bo4ammo";
    }
    	
    if (getDvarInt("enable_transitpower") == 1)
    {
    	level thread init_transitpower();
    	level.modlist[level.modlist.size] = "Transit Better Power";
    	level.modids[level.modids.size] = "transitpower";
    }
    	
    if (getDvarInt("enable_exfil") == 1 && getDvarInt("gamemode") == 0)
    {
		init_exfil();
    	level.modlist[level.modlist.size] = "Exfil";
    	level.modids[level.modids.size] = "exfil";
    }
    	
    if (getDvarInt("enable_fasttravel") == 1 && getDvarInt("gamemode") == 0)
    {
    	init_fasttravel();
    	level.modlist[level.modlist.size] = "Fast Travel";
    	level.modids[level.modids.size] = "fasttravel";
    }

    if (getDvar("mapname") == "zm_transit")
    {
    	init_transitmisc();
    	
    	level.bonescollected = 0;
    
    	thread spawnBone(4925,6658,-58,-123);
    	thread spawnBone(12997,-1015,-205,42);
    	thread spawnBone(-7737,5358,-58,-123);
    	thread spawnTombstone(8752,-6055,78,-175);
    	thread spawnShovel(-4183,-7764,-61,176);
    	
    }
    	
    if (getDvarInt("enable_vghudanim") == 1)
    {
    	init_vghudanim();
    	level.modlist[level.modlist.size] = "Vanguard Perk Animation";
    	level.modids[level.modids.size] = "vghudanim";
    }
    
    if (getDvarInt("enable_secretmusicsurvival") == 1)
    {
    	init_secretmusic();
    	level.modlist[level.modlist.size] = "Secret Music EE in Survival";
    	level.modids[level.modids.size] = "secretmusic";
    }
    	
    if (getDvarInt("enable_instantpap") == 1)
    {
    	init_instantpap();
    	level.modlist[level.modlist.size] = "Instant PAP";
    	level.modids[level.modids.size] = "instantpap";
    }

	if (getDvarInt("enable_globalatm") == 1 && getDvarInt("gamemode") == 0)
    {
    	init_globalatm();
    	level.modlist[level.modlist.size] = "Global ATM";
    	level.modids[level.modids.size] = "globalatm";
    }

    if(getDvarInt("enable_zombiecount") == 1 && getDvarInt("gamemode") == 0)
    {
    	init_enemycounter();
    	level.modlist[level.modlist.size] = "Enemy Counter";
    	level.modids[level.modids.size] = "enemycounter";
    }
    	
    if (getDvarInt("enable_healthbar") == 1)
    {
    	init_health();
    	level.modlist[level.modlist.size] = "Health and Shield Bar";
    	level.modids[level.modids.size] = "healthbar";
    }
    	
    if (getDvarInt("enable_hitmarker") == 1)
    {
    	init_hitmarker();
    	level.modlist[level.modlist.size] = "Hitmarker";
    	level.modids[level.modids.size] = "hitmarker";
    }
    	
    if (getDvarInt("enable_upgradedperks") == 1)
    {
    	init_upgradedperks();
    	level.modlist[level.modlist.size] = "Upgraded Perks";
    	level.modids[level.modids.size] = "upgradedperks";
    }
    
    if (getDvarInt("enable_infected") == 1 && getDvarInt("gamemode") == 0)
    {
    	init_infected();
    	level.modlist[level.modlist.size] = "Infected";
    	level.modids[level.modids.size] = "infected";
    }
    
    if (getDvarInt("enable_weaponanimation") == 1 && getDvarInt("gamemode") == 0)
    {
		level.modlist[level.modlist.size] = "Starter Weapon Animation";
		level.modids[level.modids.size] = "starter";
	}
	else
	{
		if(getDvarInt("enable_grabbablestarter") == 1 && getDvarInt("gamemode") == 0)
		{
			init_startergrab();
			level.modlist[level.modlist.size] = "Grabbable Starter";
			level.modids[level.modids.size] = "grabbablestarter";
		}
	}
		
	if (getDvarInt("enable_earlyspawn") == 1)
	{
		level.modlist[level.modlist.size] = "Spawn Early Rounds";
		level.modids[level.modids.size] = "earlyspawn";
	}
	
	if(getDvarInt("enable_directorscut") == 1)
	{
		level thread init_directorscut();
		level.modlist[level.modlist.size] = "Directors Cut";
		level.modids[level.modids.size] = "directorscut";
	}

	if( getDvar( "g_gametype" ) == "zclassic" && level.scr_zm_map_start_location == "transit" )
	{
		if(getDvarInt("enable_ladderintown") == 1)
		{
			level thread spawnTranzitLadder();
		}
		if(getDvarInt("wallweapon_in_town") == 1 && getDvarInt("gamemode") == 0)
		{
			level thread init_townwallweapon();
		}
	}

    if (getDvarInt("perk_limit") > 9)
    {
    	level.perk_purchase_limit = 9;
    }
    else
    {
    	level.perk_purchase_limit = getDvarInt("perk_limit");
    }


	if (getDvarInt("enable_fog") == 1)
	{
		setDvar( "r_fog", 1 );
	}
	else
	{
		setDvar( "r_fog", 0 );
	}


    if (getDvarInt("enable_debug") == 1)
    {
    	level thread init_debug();
    }
    
    level.using_solo_revive = true;
    level.is_forever_solo_game = true;
    level.revive_machine_is_solo = true;
    
    if(getDvar("mapname") == "zm_transit" && getDvarInt("solo_tombstone") == 1)
    {
    	level.modlist[level.modlist.size] = "Solo Tombstone";
    	level.modids[level.modids.size] = "solotomb";
	}
    
	if(getDvarInt("gamemode") != 0)
	{
		level.callbackactorkilled = ::actor_killed_override;
	}
	
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
		if (getDvarInt("gamemode") != 0)
		{
			player iprintln("This gamemode is in beta! Join the discord for updates and feedback: discord.gg/dkwyDzW");
		}
		
		player.firstsetup = 0;
		player.currentzone = "";
		
		player.initiatephdline = 0;
		
		if (getDvarInt("gamemode") == 1)
		{
			player.progmax = 8;
			player.weaponprog = 0;
			player.weaponlevel = -1;
			player changeweapon(false);
			player thread loopmaxammo();
		}
		else if (getDvarInt("gamemode") == 2)
		{
			player thread kill_on_downed();
		}
		
		player thread respawnPlayer();
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
	level endon("game_ended");
	
	thread init_player_things();

    for(;;)
    {
        self waittill("spawned_player");
        self endon("disconnect");
        
        if(getDvarInt("gamemode") == 0)
		{
			giveStarterWeapons();
		}
		else
		{
			self.lives = 999;
			self.timerpaused = 0;

			if (level.gungamestarted == 0 || level.crankedstarted == 0 || level.mysterygunsstarted == 0)
			{
				self EnableInvulnerability();
				self thread wait_for_ready_input();
				level waittill ("end");
			}
			else
			{
				self disableInvulnerability();
			}
			if (getDvarInt("gamemode") == 1)
			{
				self thread gungameHUD();
			}
			else if (getDvarInt("gamemode") == 2)
			{
				self thread crankedHUD();
			}
		}
    }
}

create_dvar( dvar, set )
{
    if( getDvar( dvar ) == "" )
		setDvar( dvar, set );
}

init_dvars()
{
	create_dvar("enable_custom_subtitles", 1);
	create_dvar("enable_permaperks", 0);
	//Rage Inducer
	create_dvar("enable_rampage", 1);
	create_dvar("rampage_max_round", 20);
	//Compass
	create_dvar( "enable_compass", 1);
    create_dvar( "enable_direction", 1 );
    create_dvar( "enable_zone", 1 );
    create_dvar( "enable_angle", 1 );
	//Zone Notifier
	create_dvar("enable_notifier", 1);
	//Bonus Points
	create_dvar("enable_bonuspoints", 1);
	create_dvar("bonuspoints_points", 100);
	//Useful Nuke
	create_dvar("enable_usefulnuke", 1);
	create_dvar("usefulnuke_points", 60);
	//Bo4 Ammo
	create_dvar("enable_bo4ammo", 1);
	//Tramsit Power
	create_dvar("enable_transitpower", 1);
	//Transit Misc
	create_dvar("enable_transitmisc", 1);
	
	create_dvar("tranzit_place_dinerhatch", 1);
	create_dvar("tranzit_tedd_tracker", 1);
	
	create_dvar("enable_lavadamage", 0);
	
	create_dvar("solo_tombstone", 1);
	
	create_dvar("enable_earlyspawn", 1);
	create_dvar("enable_weaponanimation", 1);
	create_dvar("perk_limit", 10);
	
	//Fast Travel Tranzit
	create_dvar("enable_fasttravel", 1);
	create_dvar("fasttravel_price", 1500);
    create_dvar("fasttravel_activateonpower", 0);
    
    create_dvar("enable_healthbar", 1);

	create_dvar("health_bar_look", 0);

    create_dvar("enable_zombiecount", 1);
    
    create_dvar("enable_exfil", 1);
    
    create_dvar("enable_debug", 0);
    
    create_dvar("enable_instantpap", 1);
    
    create_dvar("enable_vghudanim", 1);
    
    create_dvar("enable_secretmusicsurvival", 1);

    create_dvar("enable_hitmarker", 1);

    create_dvar("enable_upgradedperks", 1);
    
    create_dvar("enable_globalatm", 1);
    
    create_dvar("enable_origins_mud", 0);
	
    create_dvar("cinematic_mode", 0);
    
    create_dvar("hide_HUD", 0);
    
    create_dvar("enable_directorscut", 0);
    
    //Infected from AW Zombies
    
    create_dvar("enable_infected", 1);
    
    create_dvar("infected_start_round", 15);
    
    create_dvar("infected_infect_chance", 60);
	
	create_dvar("enable_grabbablestarter", 1);
    
    create_dvar("infected_infect_timer", 30);
    
    create_dvar("infected_infect_decrease", 5);
    
    create_dvar("infected_cure_price", 1500);
    
    create_dvar("enable_timenextround", 1);
    
    create_dvar("enable_ladderintown", 1);

	create_dvar("enable_match_timer", 1);
	
	create_dvar("enable_bleedout_bar", 1);
	
	create_dvar("enable_timebetweenround", 1);
	
	create_dvar("use_customtimebetween", 0);
	
	create_dvar("timebetween_rounds", 10);
	
	create_dvar("wallweapon_in_town", 1);
	
	create_dvar("enable_recapturerounds", 0);
	
	create_dvar("enable_originsfootchanges", 1);
	
	create_dvar("enable_samanthaintro", 0);
	
	create_dvar("afterlife_doesnt_down", 1);
	
	create_dvar("nuketown_perks_mode", 2);
	
	create_dvar("power_activates_buildables", 1);
}

init_player_things()
{
	if(self.firstsetup == 0)
	{
		if( getDvarInt("gamemode") != 0)
		{
			level waittill ("end");
		}
		
		self.firstsetup = 1;
		self thread newround();
		if (getDvarInt("enable_rampage") == 1 && getDvarInt("gamemode") == 0)
			self player_rageinducer();
		if ((getDvarInt("enable_compass") == 1) || (getDvarInt("max_clients") > 4))
		{
			if( getDvarInt("gamemode") == 0)
			{
				self player_compass();
			}
		}
		if ((getDvarInt("enable_notifier") == 1) || (getDvarInt("max_clients") > 4))
		{
			if( getDvarInt("gamemode") == 0)
			{
				self player_zonenotifer();
			}
		}
		if (getDvarInt("enable_bonuspoints") == 1)
			self player_bonuspoints();
		if (getDvarInt("enable_usefulnuke") == 1)
			self player_usefulnuke();
		if (getDvarInt("enable_bo4ammo") == 1)
			self player_bo4ammo();
		if (getDvarInt("enable_transitpower") == 1)
			self player_transitpower();
		
		self player_transitmisc();
		
		if(getDvarInt("enable_bleedout_bar") == 1 && getDvarInt("gamemode") == 0)
		{
			self thread bleedout_bar_hud();
		}
		

		if (getDvarInt("enable_exfil") == 1 && getDvarInt("gamemode") == 0)
			self player_exfil();
		if (getDvarInt("enable_healthbar") == 1)
			self player_health();
		if (getDvarInt("enable_fasttravel") == 1)
			self player_fasttravel();
		if (getDvarInt("enable_vghudanim") == 1)
			self player_vghudanim();
		if (getDvarInt("enable_secretmusicsurvival") == 1)
			self player_secretmusic();
		if (getDvarInt("enable_instantpap") == 1)
			self player_instantpap();
				
		if (getDvarInt("enable_infected") == 1 && getDvarInt("gamemode") == 0)
			self player_infected();
			
		if(getDvarInt("enable_zombiecount") == 1 && getDvarInt("gamemode") == 0)
			self player_enemycounter();
		
		
		if (getDvarInt("enable_debug") == 1)
    		self player_debug();
    	
//    	self thread toggle_hud();

    	if (getDvarInt("enable_hitmarker") == 1)
    		self player_hitmarker();
    	
   		if (getDvarInt("enable_upgradedperks") == 1)
    		self player_upgradedperks();
    	
    	if (getDvarInt("enable_globalatm") == 1 && getDvarInt("gamemode") == 0)
    		self player_globalatm();
    	
    	if (getDvarInt("enable_weaponanimation") == 1 && getDvarInt("gamemode") == 0)
    	{
    		if (getDvar("mapname") != "zm_prison")
			{
				self thread weaponanimation();
			}
		}
		else
		{
			if(getDvarInt("enable_grabbablestarter") == 1 && getDvarInt("gamemode") == 0)
			{
				weap = level.start_weapon;
				self takeweapon(weap);
				self weapon_give( "no_hands_zm", 0, 0, 1 );
				if (getDvarInt("enable_custom_subtitles") == 1)
				{
					self thread sendsubtitletext(self.name, 1, "I got to find a weapon!", 3);
				}
			}
		}
		
		if (getDvarInt("enable_earlyspawn") == 1 && getDvarInt("gamemode") == 0)
		{
			self thread spawnIfRoundOne();
			self thread spawnPlayerEarly();
		}

		self iprintln("Loaded TechnoOps Collection - Have fun!");
		wait 5;
		self iprintln("Loaded " + level.modlist.size + " mods. Use .modlist to view the loaded mods");
		wait 2;
		self iprintln("Use .help to see a list of commands");
	}
}

change_zombies_speed(speedtoset){
	level endon("end_game");
	sprint = speedtoset;
	can_sprint = false;
 	while(true){
 		if (level.ragestarted == 1)
 		{
 			can_sprint = false;
    		zombies = getAiArray(level.zombie_team);
    		foreach(zombie in zombies)
    		if(!isDefined(zombie.cloned_distance))
    			zombie.cloned_distance = zombie.origin;
    		else if(distance(zombie.cloned_distance, zombie.origin) > 15){
    			can_sprint = true;
    			zombie.cloned_distance = zombie.origin;
    			if(zombie.zombie_move_speed == "run" || zombie.zombie_move_speed != sprint)
    				zombie maps\mp\zombies\_zm_utility::set_zombie_run_cycle(sprint);
    		}else if(distance(zombie.cloned_distance, zombie.origin) <= 15){
    			can_sprint = false;
    			zombie.cloned_distance = zombie.origin;
    			zombie maps\mp\zombies\_zm_utility::set_zombie_run_cycle("run");
    		}
    	}
    	wait 0.25;
    }
}

nuke_flash( team )
{
	if ( isDefined( team ) )
	{
		get_players()[ 0 ] playsoundtoteam( "evt_nuke_flash", team );
	}
	else
	{
		get_players()[ 0 ] playsound( "evt_nuke_flash" );
	}
	fadetowhite = newhudelem();
	fadetowhite.x = 0;
	fadetowhite.y = 0;
	fadetowhite.alpha = 0;
	fadetowhite.horzalign = "fullscreen";
	fadetowhite.vertalign = "fullscreen";
	fadetowhite.foreground = 1;
	fadetowhite setshader( "white", 640, 480 );
	fadetowhite fadeovertime( 0.2 );
	fadetowhite.alpha = 0.8;
	wait 1;
	fadetowhite fadeovertime( 1 );
	fadetowhite.alpha = 0;
	wait 1.1;
	fadetowhite destroy();
}

setRagelocation()
{
	if ( getDvar( "g_gametype" ) == "zgrief" || getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead grief
		{
			level.effectlocation = (1666,9044,1340);
			level.modelangle = (0,0,0);
		}
		else if(getDvar("mapname") == "zm_buried") //buried grief
		{
			level.effectlocation = (-884,296,-30);
			level.modelangle = (0,270,0);
		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			level.effectlocation = (-210,949,-70);
			level.modelangle = (0,290,0);
		}
		else if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			if(getDvar("ui_zm_mapstartlocation") == "town")
			{
				level.effectlocation = (1685,432,-61); //town
				level.modelangle = (0,270,0);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "transit")
			{
				level.effectlocation = (-6689,5111,-55); //bus depot
				level.modelangle = (0,180,0);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "farm")
			{
				level.effectlocation = (8760,-5635,55); //farm
				level.modelangle = (0,270,0);
			}
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{
			level.effectlocation = (1910,10332,1345);
			level.modelangle = (0,90,0);
		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			level.effectlocation = (-1023,-430,295);
			level.modelangle = (0,90,0);
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			level.effectlocation = (-6689,5111,-55);
			level.modelangle = (0,180,0);
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			level.effectlocation = (2488,5477,-375);
			level.modelangle = (0,0,0);
		}
		else if(getDvar("mapname") == "zm_highrise")
		{
			level.effectlocation = (1285,1071,3420); //die rise
			level.modelangle = (0,45,0);
		}
	}
}

show_big_message(setmsg, sound)
{
    msg = setmsg;
    players = get_players();

    if ( isdefined( level.hostmigrationtimer ) )
    {
        while ( isdefined( level.hostmigrationtimer ) )
            wait 0.05;

        wait 4;
    }

    foreach ( player in players )
        player thread show_big_hud_msg( msg );
        player playsound(sound);

}

show_big_hud_msg( msg, msg_parm, offset, cleanup_end_game )
{
    self endon( "disconnect" );

    while ( isdefined( level.hostmigrationtimer ) )
        wait 0.05;

    large_hudmsg = newclienthudelem( self );
    large_hudmsg.alignx = "center";
    large_hudmsg.aligny = "middle";
    large_hudmsg.horzalign = "center";
    large_hudmsg.vertalign = "middle";
    large_hudmsg.y -= 130;

    if ( self issplitscreen() )
        large_hudmsg.y += 70;

    if ( isdefined( offset ) )
        large_hudmsg.y += offset;

    large_hudmsg.foreground = 1;
    large_hudmsg.fontscale = 5;
    large_hudmsg.alpha = 0;
    large_hudmsg.color = ( 1, 1, 1 );
    large_hudmsg.hidewheninmenu = 1;
    large_hudmsg.font = "default";

    if ( isdefined( cleanup_end_game ) && cleanup_end_game )
    {
        level endon( "end_game" );
        large_hudmsg thread show_big_hud_msg_cleanup();
    }

    if ( isdefined( msg_parm ) )
        large_hudmsg settext( msg, msg_parm );
    else
        large_hudmsg settext( msg );

    large_hudmsg changefontscaleovertime( 0.25 );
    large_hudmsg fadeovertime( 0.25 );
    large_hudmsg.alpha = 1;
    large_hudmsg.fontscale = 2;
    wait 3.25;
    large_hudmsg changefontscaleovertime( 1 );
    large_hudmsg fadeovertime( 1 );
    large_hudmsg.alpha = 0;
    large_hudmsg.fontscale = 5;
    wait 1;
    large_hudmsg notify( "death" );

    if ( isdefined( large_hudmsg ) )
        large_hudmsg destroy();
}

show_big_hud_msg_cleanup()
{
    self endon( "death" );

    level waittill( "end_game" );

    if ( isdefined( self ) )
        self destroy();
}

loadingMessage(script)
{
	flag_wait("initial_blackscreen_passed");
}

betaMessage()
{
	betamessage = newhudelem();
	betamessage.x -= 15;
	betamessage.y -= 20;
	betamessage.alpha = 0.2;
    betamessage.horzalign = "right";
    betamessage.vertalign = "top";
	betamessage.foreground = 1;
	betamessage setText ("TechnoOps Collection");
}

featuresList()
{
	featureslist = newhudelem();
	featureslist.x -= 35;
	featureslist.y -= 30;
	featureslist.alpha = 0.2;
    featureslist.horzalign = "left";
    featureslist.vertalign = "top";
	featureslist.foreground = 1;
	featureslist setText ("Features:/n-Exfil/n-Bo4 Ammo/n-Bonus Points/n-Compass/n-Rage Inducer/n-Useful Nuke/n-Zone Notifier");
}


toggle_hud()
{
	while ( true )
	{
		
		if(self.togglehud != getDvarInt("hide_HUD"))
		{
			self.togglehud = getDvarInt("hide_HUD");
		
			if (getDvarInt("hide_HUD") == 1)
			{
				self.hud_disabled = true;
				self setclientuivisibilityflag( "hud_visible", 0 );
//				self setClientDvar(cg_drawcrosshair, 0);
			}
			else if (getDvarInt("hide_HUD") == 0) 
			{
				self.hud_disabled = false;
				self setclientuivisibilityflag( "hud_visible", 1 );
//				self setClientDvar(cg_drawcrosshair, 1);
			}
		}
		
		wait 1;
	}
}

weaponanimation()
{
	weap = level.start_weapon;
	self takeweapon(weap);
	flag_wait( "initial_blackscreen_passed" );
	wait(1);
	self giveweapon(weap);
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
	self switchtoweapon(weap);
	level.skipstartcheck = 1;

	if(getDvarInt("enable_directorscut") == 1)
	{
		player_directorscut();
	}

}

spawnIfRoundOne() //spawn player
{
	wait 3;
	if (self.sessionstate == "spectator" && level.round_number <= 5)
	{
		self iprintln("Get ready to be spawned!");
		wait 5;
		self [[ level.spawnplayer ]]();
		if ( level.script != "zm_tomb" || level.script != "zm_prison" || !is_classic() )
		{
			thread maps\mp\zombies\_zm::refresh_player_navcard_hud();
		}
	}
}

spawnPlayerEarly()
{
	while(1)
	{
		if (level.exfilstarted != 1)
		{
			if (self.sessionstate == "spectator" && level.round_number > 5 && self.canrespawn == 0)
			{
				if (maps\mp\zombies\_zm_utility::get_round_enemy_array().size + level.zombie_total <= 5)
				{
					self iprintln("Get ready to be spawned!");
					wait 5;
					self [[ level.spawnplayer ]]();
					if ( level.script != "zm_tomb" || level.script != "zm_prison" || !is_classic() )
					{
						thread maps\mp\zombies\_zm::refresh_player_navcard_hud();
					}
				}
			self.canrespawn = 1;
			}
		}
		wait 1;
	}
}

randomNumber(min, max)
{
    array = [];
    for(m = min; m <= max; m++)
        array[m] = min+m;
    int = array_randomize(array);
    return(int);
}

updateSomeSettings()
{
	for(;;)
	{
		if (level.perk_purchase_limit != getDvarInt("perk_limit"))
		{
			if (getDvarInt("perk_limit") > 9)
			{
				level.perk_purchase_limit = 9;
			}
			else
			{
				level.perk_purchase_limit = getDvarInt("perk_limit");
			}
		}
		wait 0.5;
	}
}

giveStarterWeapons()
{
	if (level.round_number >= 5 && level.round_number < 20)
	{
		self giveweapon("galil_zm");
		if (self.pers[ "isBot" ] == 1)
		{
			self SetSpawnWeapon("galil_zm");
		}
	}
	else if (level.round_number >= 20)
	{
		self giveweapon("galil_upgraded_zm");
		if (self.pers[ "isBot" ] == 1)
		{
			self SetSpawnWeapon("galil_upgraded_zm");
		}
	}
	if (level.round_number >= 15)
	{
		self maps\mp\zombies\_zm_perks::give_perk( "specialty_armorvest", 0 );
	}
}

newround()
{
	for(;;)
	{
		level waittill ("start_of_round");
		self.canrespawn = 0;
	}
}


spawnBone(x,y,z,angle)
{	
	boneModel = spawn( "script_model", ( x,y,z), 1, 100, 100 ); //ch_tombstone1
	boneModel setModel ("semtex_bag");
	boneModel rotateTo ((0,angle,0),1);
	
	
	boneTrigger = spawn( "trigger_radius", ( x,y,z ), 1, 100, 100 ); //defaultvehicle
	boneTrigger setcursorhint( "HINT_NOICON" );

	level waittill ("pickedup_ee_shovel");

	boneTrigger setHintString("^7Press ^3&&1 ^7to dig up bones");
	while(1)
	{
		boneTrigger waittill( "trigger", i );
		if ( i usebuttonpressed())
		{
			i playsound( "zmb_weap_wall" );
			level.bonescollected += 1;
			playfx(level._effect["rise_dust"], (x,y,z));
			playfx(level._effect["powerup_grabbed"], (x,y,z));
			boneModel delete();
			boneTrigger delete();
			foreach ( player in get_players() )
				player thread sendsubtitletext("???", 3, boneLines(), 3);
			break;
		}
	}
}

spawnTombstone(x,y,z,angle)
{	
	stoneModel = spawn( "script_model", ( x,y,z), 1, 100, 100 );
	stoneModel setModel ("ch_tombstone1");
	stoneModel rotateTo ((0,angle,0),1);
	
	
	storeTrigger = spawn( "trigger_radius", ( x,y,z ), 1, 100, 100 );
	storeTrigger setcursorhint( "HINT_NOICON" );

	storeTrigger setHintString("");
	while(1)
	{
		storeTrigger waittill( "trigger", i );
		
		if(level.bonescollected == 3)
		{
			storeTrigger setHintString("^7Press ^3&&1 ^7to touch the tombstone\n\n^7RIP - Precious\n'My little hellhound'");
		}
		
		if ( i usebuttonpressed() && level.bonescollected == 3)
		{
			i playsound( "zmb_weap_wall" );
			playfx(level._effect["rise_dust"], (x,y,z));
			playfx(level._effect["powerup_grabbed"], (x,y,z));
			foreach ( player in get_players() )
				player thread sendsubtitletext("???", 3, "Why are you touching her grave!", 3);
			level.bonescollected += 1;
			thread spawnRaygun(x,y,z,angle);
			
			storeTrigger delete();
		}
	}
}

spawnRaygun(x,y,z,angle)
{
	freeRaygun = spawn( "trigger_radius", (x,y,z+60), 10, 200, 200 );
	freeRaygun setHintString("^7RIP - Precious\n'My little hellhound'");
	freeRaygun setcursorhint( "HINT_NOICON" );
	
	raygunModel = spawn( "script_model", (x,y,z+60), 1, 100, 100 );
	raygunModel setModel ("weapon_usa_ray_gun");
	raygunModel rotateTo ((0,angle+90,0),.1);
	
	foreach ( player in get_players() )
		player thread sendsubtitletext("???", 1, "Looks like she gave you a gift. How thoughtful!", 3);
	
	while(1)
	{
		freeRaygun waittill( "trigger", i );
		if ( i usebuttonpressed() )
		{
			if (!(i hasweapon("ray_gun_zm")))
			{
				i maps\mp\zombies\_zm_weapons::weapon_give("ray_gun_zm");
			}
		}
	}
}

spawnShovel(x,y,z,angle)
{	
	shovelModel = spawn( "script_model", ( x,y,z), 1, 100, 100 );
	shovelModel setModel ("world_dw_knife_bowie");
	shovelModel rotateTo ((0,angle,0),1);
	
	
	shovelTrigger = spawn( "trigger_radius", ( x,y,z ), 1, 100, 100 );
	shovelTrigger setcursorhint( "HINT_NOICON" );

	shovelTrigger setHintString("^7Press ^3&&1 ^7to pick up Shovel");
	while(1)
	{
		shovelTrigger waittill( "trigger", i );
		if ( i usebuttonpressed())
		{
			i playsound( "fly_equipment_pickup_plr" );
			level notify ("pickedup_ee_shovel");
			shovelModel delete();
			shovelTrigger delete();
			foreach ( player in get_players() )
				player thread sendsubtitletext("???", 3, "What are you doing with that shovel?", 4);
			break;
		}
	}
}


//////////////////////////////////
//
//	[Bo4 Ammo Script]
//
//////////////////////////////////



init_bo4ammo()
{

}

player_bo4ammo()
{

}

doBO4MaxAmmo()
{
    weaps = self getweaponslist(1);
    foreach (weap in weaps) {
        self givemaxammo(weap);
        self setweaponammoclip(weap, weaponclipsize(weap));
    }
}



//////////////////////////////////
//
//	[Bonus Points Script]
//
//	Individual mod link: https://github.com/techboy04/Bonus-Points-T6Zombies
//
//////////////////////////////////


init_bonuspoints()
{
	setBonusPoints();
}

player_bonuspoints()
{

}

perk_trigger(x,y,z)
{
	trigger = spawn( "trigger_radius", ( x,y,z ), 1, 50, 50 );
	while(1)
	{
		trigger waittill( "trigger", i );
		if ( i GetStance() == "prone" )
		{
			if (level.zombie_vars[i.team]["zombie_point_scalar"] == 1)
			{
				i.score += getDvarInt("bonuspoints_points");
			}
			else
			{
				i.score += (getDvarInt("bonuspoints_points") * 2);
			}
			i playsound( "zmb_cha_ching" );
			trigger delete();
			break;
		}
	}
}

setBonusPoints()
{
	if ( getDvar( "g_gametype" ) == "zgrief" || getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead grief
		{
			level thread perk_trigger(2811,9306,1336); //deadshot
			level thread perk_trigger(-500,8645,1336); //speedcola
			level thread perk_trigger(1164,9675,1545); //doubletap
			level thread perk_trigger(1768,10656,1336); //juggernog
			level thread perk_trigger(371,10652,1336); //phd
		}
		else if(getDvar("mapname") == "zm_buried") //buried grief
		{
			level thread perk_trigger(1429,2267,16); //quickrevive
			level thread perk_trigger(-131,-357,144); //speedcola
			level thread perk_trigger(2326,975,88); //doubletap
			level thread perk_trigger(-663,1030,8); //juggernog
			level thread perk_trigger(762,1503,-6); //staminup
			level thread perk_trigger(-712,-1210,144); //mulekick
		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			level thread perk_trigger(764,-71,-63); //perk 1
			level thread perk_trigger(1581,947,-60); //perk 2
			level thread perk_trigger(679,43,79); //perk 3
			level thread perk_trigger(2028,192,-63); //perk 4
			level thread perk_trigger(-2018,255,-61); //perk 5
			level thread perk_trigger(-1676,954,-63); //perk 6
			level thread perk_trigger(-124,725,-63); //perk 7
			level thread perk_trigger(1347,626,-57); //perk 8
			level thread perk_trigger(-427,664,-63); //perk 9
			level thread perk_trigger(-857,100,-55); //perk 10
		}
		else if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			level thread perk_trigger(1850,141,88); //quickrevive
			level thread perk_trigger(835,85,-39); //speedcola
			level thread perk_trigger(2072,-1372,-49); //doubletap
			level thread perk_trigger(1046,-1521,128); //juggernog
			level thread perk_trigger(1745,479,-55); //staminup
			level thread perk_trigger(1752,-1097,-55); //tombstone

			level thread perk_trigger(8050,-5497,40); //quickrevive
			level thread perk_trigger(8136,-6340,117); //speedcola
			level thread perk_trigger(8037,-4632,264); //doubletap
			level thread perk_trigger(8183,-6430,245); //juggernog
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{
			level thread perk_trigger(4019,9526,1528); //deadshot
			level thread perk_trigger(-495,8646,1336); //speedcola
			level thread perk_trigger(325,9100,1132); //doubletap
			level thread perk_trigger(513,6646,208); //juggernog
			level thread perk_trigger(1146,9671,1545); //electric
		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			level thread perk_trigger(-923,-255,288); //quickrevive
			level thread perk_trigger(142,636,176); //speedcola
			level thread perk_trigger(2426,48,88); //doubletap
			level thread perk_trigger(-664,1030,8); //juggernog
			level thread perk_trigger(6984,389,108); //staminup
			level thread perk_trigger(-712,-1210,144); //mulekick
			level thread perk_trigger(1432,2267,16); //vultureaid
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			level thread perk_trigger(-6707,5031,-55); //quickrevive
			level thread perk_trigger(-5508,-7857,0); //speedcola
			level thread perk_trigger(8043,-4632,264); //doubletap
			level thread perk_trigger(1047,-1521,128); //juggernog
			level thread perk_trigger(1848,475,-55); //staminup
			level thread perk_trigger(10907,8311,-407); //tombstone
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			level thread perk_trigger(2358,5048,-303); //quickrevive
			level thread perk_trigger(885,3249,-170); //speedcola
			level thread perk_trigger(-2,-441,-493); //mulekick
			level thread perk_trigger(2327,-193,139); //juggernog
			level thread perk_trigger(-2381,-8,234); //staminup
		}
	}
}



//////////////////////////////////
//
//	[Compass Script]
//
//	Individual mod link: https://github.com/techboy04/Compass-T6Zombies
//
//////////////////////////////////


init_compass()
{

}

player_compass()
{
	if (getDvarInt("cinematic_mode") != 1)
	{
		self thread compassHud();
	}
}

compassHud()
{
	level endon("end_game");
	self endon( "disconnect" );

	compass_hud = newClientHudElem(self);
	compass_hud.alignx = "center";
	compass_hud.aligny = "top";
	compass_hud.horzalign = "user_center";
//	compass_hud.vertalign = "user_top";
	compass_hud.x += 0;
//	compass_hud.y += 10;
	compass_hud.fontscale = 2;
	compass_hud.alpha = 1;
	compass_hud.color = ( 1, 1, 1 );
	compass_hud.hidewheninmenu = 1;
	compass_hud.foreground = 1;

	angle_hud = newClientHudElem(self);
	angle_hud.alignx = "center";
	angle_hud.aligny = "top";
	angle_hud.horzalign = "user_center";
//	angle_hud.vertalign = "user_top";
	angle_hud.x += 0;
//	angle_hud.y = compass_hud.y + 23;
	angle_hud.fontscale = 1.2;
	angle_hud.alpha = 1;
	angle_hud.color = ( 1, 1, 1 );
	angle_hud.hidewheninmenu = 1;
	angle_hud.foreground = 1;

	zone_hud = newClientHudElem(self);
	zone_hud.alignx = "center";
	zone_hud.aligny = "top";
	zone_hud.horzalign = "user_center";
//	zone_hud.vertalign = "user_top";
	zone_hud.x += 0;
//	zone_hud.y = angle_hud.y + 10;
	zone_hud.fontscale = 1.2;
	zone_hud.alpha = 1;
	zone_hud.color = ( 1, 1, 1 );
	zone_hud.hidewheninmenu = 1;
	zone_hud.foreground = 1;

	while(1)
	{
		if (getDvarInt( "enable_direction" ) == 1)
		{
			compass_hud settext (gettext(getangle()));
			compass_hud.y = 10;
		}
		else
		{
			compass_hud settext (" ");
			compass_hud.y = 0;
		}
		
		if (getDvarInt( "enable_angle" ) == 1)
		{
			angle_hud setvalue (getangle());
			angle_hud.y = compass_hud.y + 23;
		}
		else
		{
			angle_hud settext (" ");
			angle_hud.y = compass_hud.y + 0;
		}
		
		if (getDvarInt( "enable_zone" ) == 1)
		{
			zone_hud settext (get_zone_display_name(self get_current_zone()));
			zone_hud.y = angle_hud.y + 10;
		}
		else
		{
			zone_hud settext (" ");
			zone_hud.y = angle_hud.y + 0;
		}
		
		wait 0.05;
	}
}

gettext(direction)
{
	if (direction >= 337.5 && direction <= 22.5)
	{
		return "N";
	}
	else if (direction >= 67.5 && direction <= 112.5)
	{
		return "E";
	}
	else if (direction >= 157.5 && direction <= 202.5)
	{
		return "S";
	}
	else if (direction >= 247.5 && direction <= 292.5)
	{
		return "W";
	}
	//Directionals
	else if (direction >= 22.5 && direction <= 67.5)
	{
		return "NE";
	}
	else if (direction >= 112.5 && direction <= 157.5)
	{
			return "SE";
	}
	else if (direction >= 202.5 && direction <= 247.5)
	{
		return "SW";
	}
	else if (direction >= 292.5 && direction <= 337.5)
	{
		return "NW";
	}
	else
	{
		return "N";
	}
}

getangle()
{
	direction = int(self.angles[1]);
	direction = direction * -1;
	if (direction <= 0)
	{
		direction = 359 + direction;
	}
	return direction;
}

get_zone_display_name(zone)
{
	if (!isDefined(zone))
	{
		return "";
	}

	name = zone;

	if (level.script == "zm_transit" || level.script == "zm_transit_dr")
	{
		if (zone == "zone_pri")
		{
			name = "Bus Depot";
		}
		else if (zone == "zone_pri2")
		{
			name = "Bus Depot Hallway";
		}
		else if (zone == "zone_station_ext")
		{
			name = "Outside Bus Depot";
		}
		else if (zone == "zone_trans_2b")
		{
			name = "Fog After Bus Depot";
		}
		else if (zone == "zone_trans_2")
		{
			name = "Tunnel Entrance";
		}
		else if (zone == "zone_amb_tunnel")
		{
			name = "Tunnel";
		}
		else if (zone == "zone_trans_3")
		{
			name = "Tunnel Exit";
		}
		else if (zone == "zone_roadside_west")
		{
			name = "Outside Diner";
		}
		else if (zone == "zone_gas")
		{
			name = "Gas Station";
		}
		else if (zone == "zone_roadside_east")
		{
			name = "Outside Garage";
		}
		else if (zone == "zone_trans_diner")
		{
			name = "Fog Outside Diner";
		}
		else if (zone == "zone_trans_diner2")
		{
			name = "Fog Outside Garage";
		}
		else if (zone == "zone_gar")
		{
			name = "Garage";
		}
		else if (zone == "zone_din")
		{
			name = "Diner";
		}
		else if (zone == "zone_diner_roof")
		{
			name = "Diner Roof";
		}
		else if (zone == "zone_trans_4")
		{
			name = "Fog After Diner";
		}
		else if (zone == "zone_amb_forest")
		{
			name = "Forest";
		}
		else if (zone == "zone_trans_10")
		{
			name = "Outside Church";
		}
		else if (zone == "zone_town_church")
		{
			name = "Outside Church To Town";
		}
		else if (zone == "zone_trans_5")
		{
			name = "Fog Before Farm";
		}
		else if (zone == "zone_far")
		{
			name = "Outside Farm";
		}
		else if (zone == "zone_far_ext")
		{
			name = "Farm";
		}
		else if (zone == "zone_brn")
		{
			name = "Barn";
		}
		else if (zone == "zone_farm_house")
		{
			name = "Farmhouse";
		}
		else if (zone == "zone_trans_6")
		{
			name = "Fog After Farm";
		}
		else if (zone == "zone_amb_cornfield")
		{
			name = "Cornfield";
		}
		else if (zone == "zone_cornfield_prototype")
		{
			name = "Prototype";
		}
		else if (zone == "zone_trans_7")
		{
			name = "Upper Fog Before Power Station";
		}
		else if (zone == "zone_trans_pow_ext1")
		{
			name = "Fog Before Power Station";
		}
		else if (zone == "zone_pow")
		{
			name = "Outside Power Station";
		}
		else if (zone == "zone_prr")
		{
			name = "Power Station";
		}
		else if (zone == "zone_pcr")
		{
			name = "Power Station Control Room";
		}
		else if (zone == "zone_pow_warehouse")
		{
			name = "Warehouse";
		}
		else if (zone == "zone_trans_8")
		{
			name = "Fog After Power Station";
		}
		else if (zone == "zone_amb_power2town")
		{
			name = "Cabin";
		}
		else if (zone == "zone_trans_9")
		{
			name = "Fog Before Town";
		}
		else if (zone == "zone_town_north")
		{
			name = "North Town";
		}
		else if (zone == "zone_tow")
		{
			name = "Center Town";
		}
		else if (zone == "zone_town_east")
		{
			name = "East Town";
		}
		else if (zone == "zone_town_west")
		{
			name = "West Town";
		}
		else if (zone == "zone_town_south")
		{
			name = "South Town";
		}
		else if (zone == "zone_bar")
		{
			name = "Bar";
		}
		else if (zone == "zone_town_barber")
		{
			name = "Bookstore";
		}
		else if (zone == "zone_ban")
		{
			name = "Bank";
		}
		else if (zone == "zone_ban_vault")
		{
			name = "Bank Vault";
		}
		else if (zone == "zone_tbu")
		{
			name = "Below Bank";
		}
		else if (zone == "zone_trans_11")
		{
			name = "Fog After Town";
		}
		else if (zone == "zone_amb_bridge")
		{
			name = "Bridge";
		}
		else if (zone == "zone_trans_1")
		{
			name = "Fog Before Bus Depot";
		}
	}
	else if (level.script == "zm_nuked")
	{
		if (zone == "culdesac_yellow_zone")
		{
			name = "Yellow House Cul-de-sac";
		}
		else if (zone == "culdesac_green_zone")
		{
			name = "Green House Cul-de-sac";
		}
		else if (zone == "truck_zone")
		{
			name = "Truck";
		}
		else if (zone == "openhouse1_f1_zone")
		{
			name = "Green House Downstairs";
		}
		else if (zone == "openhouse1_f2_zone")
		{
			name = "Green House Upstairs";
		}
		else if (zone == "openhouse1_backyard_zone")
		{
			name = "Green House Backyard";
		}
		else if (zone == "openhouse2_f1_zone")
		{
			name = "Yellow House Downstairs";
		}
		else if (zone == "openhouse2_f2_zone")
		{
			name = "Yellow House Upstairs";
		}
		else if (zone == "openhouse2_backyard_zone")
		{
			name = "Yellow House Backyard";
		}
		else if (zone == "ammo_door_zone")
		{
			name = "Yellow House Backyard Door";
		}
	}
	else if (level.script == "zm_highrise")
	{
		if (zone == "zone_green_start")
		{
			name = "Green Highrise Level 3b";
		}
		else if (zone == "zone_green_escape_pod")
		{
			name = "Escape Pod";
		}
		else if (zone == "zone_green_escape_pod_ground")
		{
			name = "Escape Pod Shaft";
		}
		else if (zone == "zone_green_level1")
		{
			name = "Green Highrise Level 3a";
		}
		else if (zone == "zone_green_level2a")
		{
			name = "Green Highrise Level 2a";
		}
		else if (zone == "zone_green_level2b")
		{
			name = "Green Highrise Level 2b";
		}
		else if (zone == "zone_green_level3a")
		{
			name = "Green Highrise Restaurant";
		}
		else if (zone == "zone_green_level3b")
		{
			name = "Green Highrise Level 1a";
		}
		else if (zone == "zone_green_level3c")
		{
			name = "Green Highrise Level 1b";
		}
		else if (zone == "zone_green_level3d")
		{
			name = "Green Highrise Behind Restaurant";
		}
		else if (zone == "zone_orange_level1")
		{
			name = "Upper Orange Highrise Level 2";
		}
		else if (zone == "zone_orange_level2")
		{
			name = "Upper Orange Highrise Level 1";
		}
		else if (zone == "zone_orange_elevator_shaft_top")
		{
			name = "Elevator Shaft Level 3";
		}
		else if (zone == "zone_orange_elevator_shaft_middle_1")
		{
			name = "Elevator Shaft Level 2";
		}
		else if (zone == "zone_orange_elevator_shaft_middle_2")
		{
			name = "Elevator Shaft Level 1";
		}
		else if (zone == "zone_orange_elevator_shaft_bottom")
		{
			name = "Elevator Shaft Bottom";
		}
		else if (zone == "zone_orange_level3a")
		{
			name = "Lower Orange Highrise Level 1a";
		}
		else if (zone == "zone_orange_level3b")
		{
			name = "Lower Orange Highrise Level 1b";
		}
		else if (zone == "zone_blue_level5")
		{
			name = "Lower Blue Highrise Level 1";
		}
		else if (zone == "zone_blue_level4a")
		{
			name = "Lower Blue Highrise Level 2a";
		}
		else if (zone == "zone_blue_level4b")
		{
			name = "Lower Blue Highrise Level 2b";
		}
		else if (zone == "zone_blue_level4c")
		{
			name = "Lower Blue Highrise Level 2c";
		}
		else if (zone == "zone_blue_level2a")
		{
			name = "Upper Blue Highrise Level 1a";
		}
		else if (zone == "zone_blue_level2b")
		{
			name = "Upper Blue Highrise Level 1b";
		}
		else if (zone == "zone_blue_level2c")
		{
			name = "Upper Blue Highrise Level 1c";
		}
		else if (zone == "zone_blue_level2d")
		{
			name = "Upper Blue Highrise Level 1d";
		}
		else if (zone == "zone_blue_level1a")
		{
			name = "Upper Blue Highrise Level 2a";
		}
		else if (zone == "zone_blue_level1b")
		{
			name = "Upper Blue Highrise Level 2b";
		}
		else if (zone == "zone_blue_level1c")
		{
			name = "Upper Blue Highrise Level 2c";
		}
	}
	else if (level.script == "zm_prison")
	{
		if (zone == "zone_start")
		{
			name = "D-Block";
		}
		else if (zone == "zone_library")
		{
			name = "Library";
		}
		else if (zone == "zone_cellblock_west")
		{
			name = "Cell Block 2nd Floor";
		}
		else if (zone == "zone_cellblock_west_gondola")
		{
			name = "Cell Block 3rd Floor";
		}
		else if (zone == "zone_cellblock_west_gondola_dock")
		{
			name = "Cell Block Gondola";
		}
		else if (zone == "zone_cellblock_west_barber")
		{
			name = "Michigan Avenue";
		}
		else if (zone == "zone_cellblock_east")
		{
			name = "Times Square";
		}
		else if (zone == "zone_cafeteria")
		{
			name = "Cafeteria";
		}
		else if (zone == "zone_cafeteria_end")
		{
			name = "Cafeteria End";
		}
		else if (zone == "zone_infirmary")
		{
			name = "Infirmary 1";
		}
		else if (zone == "zone_infirmary_roof")
		{
			name = "Infirmary 2";
		}
		else if (zone == "zone_roof_infirmary")
		{
			name = "Roof 1";
		}
		else if (zone == "zone_roof")
		{
			name = "Roof 2";
		}
		else if (zone == "zone_cellblock_west_warden")
		{
			name = "Sally Port";
		}
		else if (zone == "zone_warden_office")
		{
			name = "Warden's Office";
		}
		else if (zone == "cellblock_shower")
		{
			name = "Showers";
		}
		else if (zone == "zone_citadel_shower")
		{
			name = "Citadel To Showers";
		}
		else if (zone == "zone_citadel")
		{
			name = "Citadel";
		}
		else if (zone == "zone_citadel_warden")
		{
			name = "Citadel To Warden's Office";
		}
		else if (zone == "zone_citadel_stairs")
		{
			name = "Citadel Tunnels";
		}
		else if (zone == "zone_citadel_basement")
		{
			name = "Citadel Basement";
		}
		else if (zone == "zone_citadel_basement_building")
		{
			name = "China Alley";
		}
		else if (zone == "zone_studio")
		{
			name = "Building 64";
		}
		else if (zone == "zone_dock")
		{
			name = "Docks";
		}
		else if (zone == "zone_dock_puzzle")
		{
			name = "Docks Gates";
		}
		else if (zone == "zone_dock_gondola")
		{
			name = "Upper Docks";
		}
		else if (zone == "zone_golden_gate_bridge")
		{
			name = "Golden Gate Bridge";
		}
		else if (zone == "zone_gondola_ride")
		{
			name = "Gondola";
		}
	}
	else if (level.script == "zm_buried")
	{
		if (zone == "zone_start")
		{
			name = "Processing";
		}
		else if (zone == "zone_start_lower")
		{
			name = "Lower Processing";
		}
		else if (zone == "zone_tunnels_center")
		{
			name = "Center Tunnels";
		}
		else if (zone == "zone_tunnels_north")
		{
			name = "Courthouse Tunnels 2";
		}
		else if (zone == "zone_tunnels_north2")
		{
			name = "Courthouse Tunnels 1";
		}
		else if (zone == "zone_tunnels_south")
		{
			name = "Saloon Tunnels 3";
		}
		else if (zone == "zone_tunnels_south2")
		{
			name = "Saloon Tunnels 2";
		}
		else if (zone == "zone_tunnels_south3")
		{
			name = "Saloon Tunnels 1";
		}
		else if (zone == "zone_street_lightwest")
		{
			name = "Outside General Store & Bank";
		}
		else if (zone == "zone_street_lightwest_alley")
		{
			name = "Outside General Store & Bank Alley";
		}
		else if (zone == "zone_morgue_upstairs")
		{
			name = "Morgue";
		}
		else if (zone == "zone_underground_jail")
		{
			name = "Jail Downstairs";
		}
		else if (zone == "zone_underground_jail2")
		{
			name = "Jail Upstairs";
		}
		else if (zone == "zone_general_store")
		{
			name = "General Store";
		}
		else if (zone == "zone_stables")
		{
			name = "Stables";
		}
		else if (zone == "zone_street_darkwest")
		{
			name = "Outside Gunsmith";
		}
		else if (zone == "zone_street_darkwest_nook")
		{
			name = "Outside Gunsmith Nook";
		}
		else if (zone == "zone_gun_store")
		{
			name = "Gunsmith";
		}
		else if (zone == "zone_bank")
		{
			name = "Bank";
		}
		else if (zone == "zone_tunnel_gun2stables")
		{
			name = "Stables To Gunsmith Tunnel 2";
		}
		else if (zone == "zone_tunnel_gun2stables2")
		{
			name = "Stables To Gunsmith Tunnel";
		}
		else if (zone == "zone_street_darkeast")
		{
			name = "Outside Saloon & Toy Store";
		}
		else if (zone == "zone_street_darkeast_nook")
		{
			name = "Outside Saloon & Toy Store Nook";
		}
		else if (zone == "zone_underground_bar")
		{
			name = "Saloon";
		}
		else if (zone == "zone_tunnel_gun2saloon")
		{
			name = "Saloon To Gunsmith Tunnel";
		}
		else if (zone == "zone_toy_store")
		{
			name = "Toy Store Downstairs";
		}
		else if (zone == "zone_toy_store_floor2")
		{
			name = "Toy Store Upstairs";
		}
		else if (zone == "zone_toy_store_tunnel")
		{
			name = "Toy Store Tunnel";
		}
		else if (zone == "zone_candy_store")
		{
			name = "Candy Store Downstairs";
		}
		else if (zone == "zone_candy_store_floor2")
		{
			name = "Candy Store Upstairs";
		}
		else if (zone == "zone_street_lighteast")
		{
			name = "Outside Courthouse & Candy Store";
		}
		else if (zone == "zone_underground_courthouse")
		{
			name = "Courthouse Downstairs";
		}
		else if (zone == "zone_underground_courthouse2")
		{
			name = "Courthouse Upstairs";
		}
		else if (zone == "zone_street_fountain")
		{
			name = "Fountain";
		}
		else if (zone == "zone_church_graveyard")
		{
			name = "Graveyard";
		}
		else if (zone == "zone_church_main")
		{
			name = "Church Downstairs";
		}
		else if (zone == "zone_church_upstairs")
		{
			name = "Church Upstairs";
		}
		else if (zone == "zone_mansion_lawn")
		{
			name = "Mansion Lawn";
		}
		else if (zone == "zone_mansion")
		{
			name = "Mansion";
		}
		else if (zone == "zone_mansion_backyard")
		{
			name = "Mansion Backyard";
		}
		else if (zone == "zone_maze")
		{
			name = "Maze";
		}
		else if (zone == "zone_maze_staircase")
		{
			name = "Maze Staircase";
		}
	}
	else if (level.script == "zm_tomb")
	{
		if (isDefined(self.teleporting) && self.teleporting)
		{
			return "";
		}

		if (zone == "zone_start")
		{
			name = "Lower Laboratory";
		}
		else if (zone == "zone_start_a")
		{
			name = "Upper Laboratory";
		}
		else if (zone == "zone_start_b")
		{
			name = "Generator 1";
		}
		else if (zone == "zone_bunker_1a")
		{
			name = "Generator 3 Bunker 1";
		}
		else if (zone == "zone_fire_stairs")
		{
			name = "Fire Tunnel";
		}
		else if (zone == "zone_bunker_1")
		{
			name = "Generator 3 Bunker 2";
		}
		else if (zone == "zone_bunker_3a")
		{
			name = "Generator 3";
		}
		else if (zone == "zone_bunker_3b")
		{
			name = "Generator 3 Bunker 3";
		}
		else if (zone == "zone_bunker_2a")
		{
			name = "Generator 2 Bunker 1";
		}
		else if (zone == "zone_bunker_2")
		{
			name = "Generator 2 Bunker 2";
		}
		else if (zone == "zone_bunker_4a")
		{
			name = "Generator 2";
		}
		else if (zone == "zone_bunker_4b")
		{
			name = "Generator 2 Bunker 3";
		}
		else if (zone == "zone_bunker_4c")
		{
			name = "Tank Station";
		}
		else if (zone == "zone_bunker_4d")
		{
			name = "Above Tank Station";
		}
		else if (zone == "zone_bunker_tank_c")
		{
			name = "Generator 2 Tank Route 1";
		}
		else if (zone == "zone_bunker_tank_c1")
		{
			name = "Generator 2 Tank Route 2";
		}
		else if (zone == "zone_bunker_4e")
		{
			name = "Generator 2 Tank Route 3";
		}
		else if (zone == "zone_bunker_tank_d")
		{
			name = "Generator 2 Tank Route 4";
		}
		else if (zone == "zone_bunker_tank_d1")
		{
			name = "Generator 2 Tank Route 5";
		}
		else if (zone == "zone_bunker_4f")
		{
			name = "zone_bunker_4f";
		}
		else if (zone == "zone_bunker_5a")
		{
			name = "Workshop Downstairs";
		}
		else if (zone == "zone_bunker_5b")
		{
			name = "Workshop Upstairs";
		}
		else if (zone == "zone_nml_2a")
		{
			name = "No Man's Land Walkway";
		}
		else if (zone == "zone_nml_2")
		{
			name = "No Man's Land Entrance";
		}
		else if (zone == "zone_bunker_tank_e")
		{
			name = "Generator 5 Tank Route 1";
		}
		else if (zone == "zone_bunker_tank_e1")
		{
			name = "Generator 5 Tank Route 2";
		}
		else if (zone == "zone_bunker_tank_e2")
		{
			name = "zone_bunker_tank_e2";
		}
		else if (zone == "zone_bunker_tank_f")
		{
			name = "Generator 5 Tank Route 3";
		}
		else if (zone == "zone_nml_1")
		{
			name = "Generator 5 Tank Route 4";
		}
		else if (zone == "zone_nml_4")
		{
			name = "Generator 5 Tank Route 5";
		}
		else if (zone == "zone_nml_0")
		{
			name = "Generator 5 Left Footstep";
		}
		else if (zone == "zone_nml_5")
		{
			name = "Generator 5 Right Footstep Walkway";
		}
		else if (zone == "zone_nml_farm")
		{
			name = "Generator 5";
		}
		else if (zone == "zone_nml_celllar")
		{
			name = "Generator 5 Cellar";
		}
		else if (zone == "zone_bolt_stairs")
		{
			name = "Lightning Tunnel";
		}
		else if (zone == "zone_nml_3")
		{
			name = "No Man's Land 1st Right Footstep";
		}
		else if (zone == "zone_nml_2b")
		{
			name = "No Man's Land Stairs";
		}
		else if (zone == "zone_nml_6")
		{
			name = "No Man's Land Left Footstep";
		}
		else if (zone == "zone_nml_8")
		{
			name = "No Man's Land 2nd Right Footstep";
		}
		else if (zone == "zone_nml_10a")
		{
			name = "Generator 4 Tank Route 1";
		}
		else if (zone == "zone_nml_10")
		{
			name = "Generator 4 Tank Route 2";
		}
		else if (zone == "zone_nml_7")
		{
			name = "Generator 4 Tank Route 3";
		}
		else if (zone == "zone_bunker_tank_a")
		{
			name = "Generator 4 Tank Route 4";
		}
		else if (zone == "zone_bunker_tank_a1")
		{
			name = "Generator 4 Tank Route 5";
		}
		else if (zone == "zone_bunker_tank_a2")
		{
			name = "zone_bunker_tank_a2";
		}
		else if (zone == "zone_bunker_tank_b")
		{
			name = "Generator 4 Tank Route 6";
		}
		else if (zone == "zone_nml_9")
		{
			name = "Generator 4 Left Footstep";
		}
		else if (zone == "zone_air_stairs")
		{
			name = "Wind Tunnel";
		}
		else if (zone == "zone_nml_11")
		{
			name = "Generator 4";
		}
		else if (zone == "zone_nml_12")
		{
			name = "Generator 4 Right Footstep";
		}
		else if (zone == "zone_nml_16")
		{
			name = "Excavation Site Front Path";
		}
		else if (zone == "zone_nml_17")
		{
			name = "Excavation Site Back Path";
		}
		else if (zone == "zone_nml_18")
		{
			name = "Excavation Site Level 3";
		}
		else if (zone == "zone_nml_19")
		{
			name = "Excavation Site Level 2";
		}
		else if (zone == "ug_bottom_zone")
		{
			name = "Excavation Site Level 1";
		}
		else if (zone == "zone_nml_13")
		{
			name = "Generator 5 To Generator 6 Path";
		}
		else if (zone == "zone_nml_14")
		{
			name = "Generator 4 To Generator 6 Path";
		}
		else if (zone == "zone_nml_15")
		{
			name = "Generator 6 Entrance";
		}
		else if (zone == "zone_village_0")
		{
			name = "Generator 6 Left Footstep";
		}
		else if (zone == "zone_village_5")
		{
			name = "Generator 6 Tank Route 1";
		}
		else if (zone == "zone_village_5a")
		{
			name = "Generator 6 Tank Route 2";
		}
		else if (zone == "zone_village_5b")
		{
			name = "Generator 6 Tank Route 3";
		}
		else if (zone == "zone_village_1")
		{
			name = "Generator 6 Tank Route 4";
		}
		else if (zone == "zone_village_4b")
		{
			name = "Generator 6 Tank Route 5";
		}
		else if (zone == "zone_village_4a")
		{
			name = "Generator 6 Tank Route 6";
		}
		else if (zone == "zone_village_4")
		{
			name = "Generator 6 Tank Route 7";
		}
		else if (zone == "zone_village_2")
		{
			name = "Church";
		}
		else if (zone == "zone_village_3")
		{
			name = "Generator 6 Right Footstep";
		}
		else if (zone == "zone_village_3a")
		{
			name = "Generator 6";
		}
		else if (zone == "zone_ice_stairs")
		{
			name = "Ice Tunnel";
		}
		else if (zone == "zone_bunker_6")
		{
			name = "Above Generator 3 Bunker";
		}
		else if (zone == "zone_nml_20")
		{
			name = "Above No Man's Land";
		}
		else if (zone == "zone_village_6")
		{
			name = "Behind Church";
		}
		else if (zone == "zone_chamber_0")
		{
			name = "The Crazy Place Lightning Chamber";
		}
		else if (zone == "zone_chamber_1")
		{
			name = "The Crazy Place Lightning & Ice";
		}
		else if (zone == "zone_chamber_2")
		{
			name = "The Crazy Place Ice Chamber";
		}
		else if (zone == "zone_chamber_3")
		{
			name = "The Crazy Place Fire & Lightning";
		}
		else if (zone == "zone_chamber_4")
		{
			name = "The Crazy Place Center";
		}
		else if (zone == "zone_chamber_5")
		{
			name = "The Crazy Place Ice & Wind";
		}
		else if (zone == "zone_chamber_6")
		{
			name = "The Crazy Place Fire Chamber";
		}
		else if (zone == "zone_chamber_7")
		{
			name = "The Crazy Place Wind & Fire";
		}
		else if (zone == "zone_chamber_8")
		{
			name = "The Crazy Place Wind Chamber";
		}
		else if (zone == "zone_robot_head")
		{
			name = "Robot's Head";
		}
	}

	return name;
}


//////////////////////////////////
//
//	[Debug Script]
//
//////////////////////////////////


init_debug()
{
    level.player_out_of_playable_area_monitor = 0;
//    replacefunc(maps/mp/zombies/_zm_powerups::full_ammo_powerup, ::full_ammo_powerup);
}

player_debug()
{
	self thread debugHUD();
	self thread debugXHUD();
	self thread debugYHUD();
	self thread debugZHUD();
	self thread debugAngleHUD();
	self thread debugHiddenHUD();
	self thread debugNoClipHUD();
	self thread toggleNoClip();
	self thread toggleHidden();
	self thread debugTitleHUD();
	self thread debugPositionHUD();
	self thread checkInputs();
	self thread printInputs();
	self.toggledebug = 1;
	self.togglehidden = 0;
	self.isNoClipping = 0;
	self.savePosition = self.origin;
	self.score += 999999;
	level.sq_progress[ "rich" ][ "A_jetgun_built" ] = 1;
}

checkInputs()
{
	while(1)
	{
		if(self actionslotfourbuttonpressed()) self switchCords();
		if(self actionslotthreebuttonpressed()) self switchHidden();
		if(self actionslottwobuttonpressed()) self Toggle_NoClip();
		if(self secondaryoffhandbuttonpressed()) self savePosition();
		if(self fragbuttonpressed()) self loadPosition();
		wait 0.05;
	}
}

debugHUD()
{
	level endon("end_game");
	self endon( "disconnect" );

	debug_hud = newClientHudElem(self);
	debug_hud.alignx = "left";
	debug_hud.aligny = "center";
	debug_hud.horzalign = "user_left";
	debug_hud.vertalign = "user_center";
	debug_hud.x += 10;
	debug_hud.y -= 60;
	debug_hud.fontscale = 1;
	debug_hud.alpha = 1;
	debug_hud.color = ( 1, 1, 1 );
	debug_hud.hidewheninmenu = 1;
	debug_hud.foreground = 1;
	debug_hud setText ("[{+actionslot 4}] = Toggle Position");

	while(1)
	{
		if (1)
		{
			debug_hud.alpha = 1;
		}
		else
		{
			debug_hud.alpha = 0;
		}
		
		wait 0.05;
	}
}

debugXHUD()
{
	level endon("end_game");
	self endon( "disconnect" );

	x_hud = newClientHudElem(self);
	x_hud.alignx = "left";
	x_hud.aligny = "center";
	x_hud.horzalign = "user_left";
	x_hud.vertalign = "user_center";
	x_hud.x += 15;
	x_hud.y -= 45;
	x_hud.fontscale = 1;
	x_hud.alpha = 1;
	x_hud.color = ( 1, 1, 1 );
	x_hud.hidewheninmenu = 1;
	x_hud.foreground = 1;
	x_hud.label = &"X: ^6";

	while(1)
	{
		if (self.toggledebug == 1)
		{
			x_hud.alpha = 1;
		}
		else
		{
			x_hud.alpha = 0;
		}
		
		x_hud setValue(self.origin[0]);
		
		wait 0.05;
	}
}

debugYHUD()
{
	level endon("end_game");
	self endon( "disconnect" );

	y_hud = newClientHudElem(self);
	y_hud.alignx = "left";
	y_hud.aligny = "center";
	y_hud.horzalign = "user_left";
	y_hud.vertalign = "user_center";
	y_hud.x += 15;
	y_hud.y -= 30;
	y_hud.fontscale = 1;
	y_hud.alpha = 1;
	y_hud.color = ( 1, 1, 1 );
	y_hud.hidewheninmenu = 1;
	y_hud.foreground = 1;
	y_hud.label = &"Y: ^6";

	while(1)
	{
		if (self.toggledebug == 1)
		{
			y_hud.alpha = 1;
		}
		else
		{
			y_hud.alpha = 0;
		}
		
		y_hud setValue(self.origin[1]);
		
		wait 0.05;
	}
}

debugZHUD()
{
	level endon("end_game");
	self endon( "disconnect" );

	z_hud = newClientHudElem(self);
	z_hud.alignx = "left";
	z_hud.aligny = "center";
	z_hud.horzalign = "user_left";
	z_hud.vertalign = "user_center";
	z_hud.x += 15;
	z_hud.y -= 15;
	z_hud.fontscale = 1;
	z_hud.alpha = 1;
	z_hud.color = ( 1, 1, 1 );
	z_hud.hidewheninmenu = 1;
	z_hud.foreground = 1;
	z_hud.label = &"Z: ^6";

	while(1)
	{
		if (self.toggledebug == 1)
		{
			z_hud.alpha = 1;
		}
		else
		{
			z_hud.alpha = 0;
		}
		
		z_hud setValue(self.origin[2]);
		
		wait 0.05;
	}
}

debugAngleHUD()
{
	level endon("end_game");
	self endon( "disconnect" );

	debugangle_hud = newClientHudElem(self);
	debugangle_hud.alignx = "left";
	debugangle_hud.aligny = "center";
	debugangle_hud.horzalign = "user_left";
	debugangle_hud.vertalign = "user_center";
	debugangle_hud.x += 15;
	debugangle_hud.y = 0;
	debugangle_hud.fontscale = 1;
	debugangle_hud.alpha = 1;
	debugangle_hud.color = ( 1, 1, 1 );
	debugangle_hud.hidewheninmenu = 1;
	debugangle_hud.foreground = 1;
	debugangle_hud.label = &"Angle: ^6";

	while(1)
	{
		if (self.toggledebug == 1)
		{
			debugangle_hud.alpha = 1;
		}
		else
		{
			debugangle_hud.alpha = 0;
		}
		
		debugangle_hud setValue(self.angles[1]);
		
		wait 0.05;
	}
}

debugHiddenHUD()
{
	level endon("end_game");
	self endon( "disconnect" );

	debug_hud = newClientHudElem(self);
	debug_hud.alignx = "left";
	debug_hud.aligny = "center";
	debug_hud.horzalign = "user_left";
	debug_hud.vertalign = "user_center";
	debug_hud.x += 10;
	debug_hud.y -= 75;
	debug_hud.fontscale = 1;
	debug_hud.alpha = 1;
	debug_hud.color = ( 1, 1, 1 );
	debug_hud.hidewheninmenu = 1;
	debug_hud.foreground = 1;
	debug_hud setText ("[{+actionslot 3}] = Toggle Visibility");

	while(1)
	{
		if (1)
		{
			debug_hud.alpha = 1;
		}
		else
		{
			debug_hud.alpha = 0;
		}
		
		wait 0.05;
	}
}

toggleHidden()
{
	level endon("end_game");
	self endon( "disconnect" );

	debug_hud = newClientHudElem(self);
	debug_hud.alignx = "center";
	debug_hud.aligny = "top";
	debug_hud.horzalign = "user_center";
	debug_hud.vertalign = "user_top";
	debug_hud.x = 0;
	debug_hud.y += 15;
	debug_hud.fontscale = 1;
	debug_hud.alpha = 1;
	debug_hud.color = ( 0, 1, 0 );
	debug_hud.hidewheninmenu = 1;
	debug_hud.foreground = 1;
	debug_hud setText ("HIDDEN");

	while(1)
	{
		if (self.ignoreme == 1)
		{
			debug_hud.alpha = 1;
		}
		else
		{
			debug_hud.alpha = 0;
		}
		
		wait 0.05;
	}
}

switchHidden()
{
	if (self.togglehidden == 1)
	{
		self.togglehidden = 0;
		self.ignoreme = 0;
		self DisableInvulnerability();
	}
	else if (self.togglehidden == 0)
	{
		self.togglehidden = 1;
		self.ignoreme = 1;
		self EnableInvulnerability();
	}
}

switchCords()
{
	if (self.toggledebug == 1)
	{
		self.toggledebug = 0;
	}
	else if (self.toggledebug == 0)
	{
		self.toggledebug = 1;
	}
}

debugNoClipHUD()
{
	level endon("end_game");
	self endon( "disconnect" );

	debug_hud = newClientHudElem(self);
	debug_hud.alignx = "left";
	debug_hud.aligny = "center";
	debug_hud.horzalign = "user_left";
	debug_hud.vertalign = "user_center";
	debug_hud.x += 10;
	debug_hud.y -= 90;
	debug_hud.fontscale = 1;
	debug_hud.alpha = 1;
	debug_hud.color = ( 1, 1, 1 );
	debug_hud.hidewheninmenu = 1;
	debug_hud.foreground = 1;
	debug_hud setText ("[{+actionslot 2}] = Toggle No Clip");

	while(1)
	{
		if (1)
		{
			debug_hud.alpha = 1;
		}
		else
		{
			debug_hud.alpha = 0;
		}
		
		wait 0.05;
	}
}

toggleNoClip()
{
	level endon("end_game");
	self endon( "disconnect" );

	debug_hud = newClientHudElem(self);
	debug_hud.alignx = "center";
	debug_hud.aligny = "top";
	debug_hud.horzalign = "user_center";
	debug_hud.vertalign = "user_top";
	debug_hud.x = 0;
	debug_hud.y += 30;
	debug_hud.fontscale = 1;
	debug_hud.alpha = 1;
	debug_hud.color = ( 0, 1, 0 );
	debug_hud.hidewheninmenu = 1;
	debug_hud.foreground = 1;
	debug_hud setText ("No Clip");

	while(1)
	{
		if (self.isNoClipping == 1)
		{
			debug_hud.alpha = 1;
		}
		else
		{
			debug_hud.alpha = 0;
		}
		
		wait 0.05;
	}
}

Toggle_NoClip()
{
    self notify("StopNoClip");   
    if(!isDefined(self.NoClip))
        self.NoClip = false;
    self.NoClip = !self.NoClip;
    if(self.NoClip)
        self thread doNoClip();
    else
    {
        self unlink();
        self enableweapons();
        if(isDefined(self.NoClipEntity))
        {
            self.NoClipEntity delete();
            self.NoClipEntity = undefined;
        }       
    }
    if (self.NoClip == false)
    {
    	self.isNoClipping = 0;
    }
    self iPrintln("NoClip " + (self.NoClip ? "^2ON" : "^1OFF"));
}

doNoClip()
{
    self notify("StopNoClip");
    if(isDefined(self.NoClipEntity))
    {
        self.NoClipEntity delete();
        self.NoClipEntity = undefined;
    }   
    self endon("StopNoClip");
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    self.NoClipEntity = spawn( "script_origin", self.origin, 1);
    self.NoClipEntity.angles = self.angles;
    self playerlinkto(self.originObj, undefined);
    NoClipFly = true;
    self disableweapons();
    self playerLinkTo(self.NoClipEntity);
  //  self iPrintln("Press [{+smoke}] To ^2Enable ^7NoClip.");
   // self iPrintln("Press [{+gostand}] To Move Fast.");
  // self iPrintln("Press [{+stance}] To ^1Disable ^7NoClip.");
    while(isDefined(self.NoClip) && self.NoClip)
    {
  //      if(self secondaryOffhandButtonPressed() && !NoClipFly)
   //     {
   //         self disableweapons();
   //         self playerLinkTo(self.NoClipEntity);
   //         NoClipFly = 1;
   //         self.isNoClipping = 1;
   //     }
        if(self attackbuttonpressed() && NoClipFly)
            self.NoClipEntity moveTo(self.origin + vectorscale(anglesToForward(self getPlayerAngles()),30), .01);
        else if(self sprintbuttonpressed() && NoClipFly)
            self.NoClipEntity moveTo(self.origin + vectorscale(anglesToForward(self getPlayerAngles()),170), .01);
   //     else if(self stanceButtonPressed() && NoClipFly)
  //      {
  //          self unlink();
  //          self enableweapons();
  //          NoClipFly = 0;
  //          self.isNoClipping = 0;
  //      }
        wait .01;
   }
}

debugPositionHUD()
{
	level endon("end_game");
	self endon( "disconnect" );

	debug_hud = newClientHudElem(self);
	debug_hud.alignx = "left";
	debug_hud.aligny = "center";
	debug_hud.horzalign = "user_left";
	debug_hud.vertalign = "user_center";
	debug_hud.x += 10;
	debug_hud.y -= 110;
	debug_hud.fontscale = 1;
	debug_hud.alpha = 1;
	debug_hud.color = ( 1, 1, 1 );
	debug_hud.hidewheninmenu = 1;
	debug_hud.foreground = 1;
	debug_hud setText ("[{+smoke}] to Save Position - [{+frag}] to Go to Position");

	while(1)
	{
		if (1)
		{
			debug_hud.alpha = 1;
		}
		else
		{
			debug_hud.alpha = 0;
		}
		
		wait 0.05;
	}
}

savePosition()
{
	self.savePosition = self.origin;
	self iPrintLn("Saved Position as " + self.savePosition);
	println("Saved Position as " + self.savePosition);
}

loadPosition()
{
	self setorigin (self.savePosition);
	self iPrintLn("Teleported to position " + self.savePosition);
}

debugTitleHUD()
{
	level endon("end_game");
	self endon( "disconnect" );

	debug_hud = newClientHudElem(self);
	debug_hud.alignx = "left";
	debug_hud.aligny = "center";
	debug_hud.horzalign = "user_left";
	debug_hud.vertalign = "user_center";
	debug_hud.x += 10;
	debug_hud.y -= 135;
	debug_hud.fontscale = 2;
	debug_hud.alpha = 1;
	debug_hud.color = ( 1, 1, 1 );
	debug_hud.hidewheninmenu = 1;
	debug_hud.foreground = 1;
	debug_hud setText ("Debug Menu");

	while(1)
	{
		if (1)
		{
			debug_hud.alpha = 1;
		}
		else
		{
			debug_hud.alpha = 0;
		}
		
		wait 0.05;
	}
}

skip_bus()
{
//	level.the_bus notify ("depart_early");
	level.the_bus destroy();
}

printInputs()
{
	while(1)
	{
		if(self sprintbuttonpressed()) self iprintln("SPRINT");
		if(self inventorybuttonpressed()) self iprintln("INVENTORY");
		if(self secondaryoffhandbuttonpressed()) self iprintln("[{+smoke}]");
		if(self fragbuttonpressed()) self iprintln("[{+frag}]");
		if(self stancebuttonpressed()) self iprintln("[{+stance}]");
		if(self jumpbuttonpressed()) self iprintln("[{+gostand}]");
		if(self meleebuttonpressed()) self iprintln("[{+melee}]");
		if(self adsbuttonpressed()) self iprintln("[{+speed_throw}]");
		if(self actionslotfourbuttonpressed()) self iprintln("[{+actionslot 4}]");
		if(self actionslotthreebuttonpressed()) self iprintln("[{+actionslot 3}]");
		if(self actionslottwobuttonpressed()) self iprintln("[{+actionslot 2}]");
		if(self actionslotonebuttonpressed()) self iprintln("[{+actionslot 1}]");
		if(self attackbuttonpressed()) self iprintln("[{+attack}]");
		if(self changeseatbuttonpressed()) self iprintln("[{+switchseat}]");
		if(self usebuttonpressed()) self iprintln("[{+usereload}]");
		wait 0.5;
	}
}


//////////////////////////////////
//
//	[Directors Cut Script]
//
//////////////////////////////////

main_directorscut()
{
	replacefunc(maps\mp\zombies\_zm_perks::give_perk, ::give_perk);
}

give_perk( perk, bought )
{
	self setperk( perk );
	self.num_perks++;
	if ( is_true( bought ) )
	{
		self maps\mp\zombies\_zm_audio::playerexert( "burp" );
		if ( is_true( level.remove_perk_vo_delay ) )
		{
			self maps\mp\zombies\_zm_audio::perk_vox( perk );
		}
		else
		{
			self delay_thread( 1.5, ::perk_vox, perk );
		}
		self setblur( 4, 0.1 );
		wait 0.1;
		self setblur( 0, 0.1 );
		self notify( "perk_bought", perk );
	}
	self perk_set_max_health_if_jugg( perk, 1, 0 );
	if ( !is_true( level.disable_deadshot_clientfield ) )
	{
		if ( perk == "specialty_deadshot" )
		{
			self setclientfieldtoplayer( "deadshot_perk", 1 );
		}
		else if ( perk == "specialty_deadshot_upgrade" )
		{
			self setclientfieldtoplayer( "deadshot_perk", 1 );
		}
	}
	if ( perk == "specialty_scavenger" )
	{
		self.hasperkspecialtytombstone = 1;
	}
	players = get_players();
	if ( use_solo_revive() && perk == "specialty_quickrevive" )
	{
		self.lives = 1;
		if ( !isDefined( level.solo_lives_given ) )
		{
			level.solo_lives_given = 0;
		}
		if ( isDefined( level.solo_game_free_player_quickrevive ) )
		{
			level.solo_game_free_player_quickrevive = undefined;
		}
		else
		{
			level.solo_lives_given++;
		}
		if ( level.solo_lives_given >= 6 )
		{
			flag_set( "solo_revive" );
		}
		self thread solo_revive_buy_trigger_move( perk );
	}
	if ( perk == "specialty_finalstand" )
	{
		self.lives = 1;
		self.hasperkspecialtychugabud = 1;
		self notify( "perk_chugabud_activated" );
	}
	if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].player_thread_give ) )
	{
		self thread [[ level._custom_perks[ perk ].player_thread_give ]]();
	}
	self set_perk_clientfield( perk, 1 );
	maps\mp\_demo::bookmark( "zm_player_perk", getTime(), self );
	self maps\mp\zombies\_zm_stats::increment_client_stat( "perks_drank" );
	self maps\mp\zombies\_zm_stats::increment_client_stat( perk + "_drank" );
	self maps\mp\zombies\_zm_stats::increment_player_stat( perk + "_drank" );
	self maps\mp\zombies\_zm_stats::increment_player_stat( "perks_drank" );
	if ( !isDefined( self.perk_history ) )
	{
		self.perk_history = [];
	}
	self.perk_history = add_to_array( self.perk_history, perk, 0 );
	if ( !isDefined( self.perks_active ) )
	{
		self.perks_active = [];
	}
	self.perks_active[ self.perks_active.size ] = perk;
	self notify( "perk_acquired" );
	self thread perk_think( perk );
	
	if ((getDvarInt("cinematic_mode") != 1) && (getDvarInt("enable_vghudanim") == 1))
    {
    	self perkHUD(perk);
    }
}

init_directorscut()
{
    level.player_starting_points = 25000;
}

player_directorscut()
{
	self.director_spawn = 1;
	wait_network_frame();
	wait 1;
	gun = self maps\mp\zombies\_zm_perks::perk_give_bottle_begin("specialty_quickrevive");
	wait 3;
	self maps\mp\zombies\_zm_perks::perk_give_bottle_end(gun, "specialty_quickrevive");
	wait 1;
	self upgrade_gun(self getcurrentweapon());
	wait 1;
	self upgrade_gun("beretta93r_zm");
	self dc_give_player_all_perks();
	if (self.director_spawn == 1)
	{
		self.director_spawn = 0;
		self thread watch_for_respawn();
	}
}

dc_give_player_all_perks()
{
	flag_wait( "initial_blackscreen_passed" );
	wait_network_frame();
	machines = getentarray( "zombie_vending", "targetname" );
	perks = [];
	i = 0;
	while ( i < machines.size )
	{
		if ( machines[ i ].script_noteworthy == "specialty_weapupgrade" )
		{
			i++;
			continue;
		}
		perks[ perks.size ] = machines[ i ].script_noteworthy;
		i++;
	}
	foreach ( perk in perks )
	{
		if ( isDefined( self.perk_purchased ) && self.perk_purchased == perk )
		{
		}
		else
		{
			if ( self hasperk( perk ) || self maps\mp\zombies\_zm_perks::has_perk_paused( perk ) )
			{
			}
			else
			{
				self maps\mp\zombies\_zm_perks::give_perk( perk, 0 );
				wait 0.25;
			}
		}
	}
	if ( level.script == "zm_tomb" )
	{
		self maps\mp\zombies\_zm_perks::give_perk( "specialty_rof", 0 );
		wait 0.25;
		self maps\mp\zombies\_zm_perks::give_perk( "specialty_deadshot", 0 );
		wait 0.25;
		self maps\mp\zombies\_zm_perks::give_perk( "specialty_flakjacket", 0 );
		wait 0.25;
		self maps\mp\zombies\_zm_perks::give_perk( "specialty_grenadepulldeath", 0 );
	}
	self._retain_perks = 1;
}

watch_for_respawn()
{
	self endon( "disconnect" );
	for(;;)
	{
		self waittill_either( "spawned_player", "player_revived" );
		wait_network_frame();
		if ( level.script == "zm_prison" )
		{
			self dc_give_player_all_perks();
		}
		self setmaxhealth( level.zombie_vars[ "zombie_perk_juggernaut_health" ] );
	}
}

upgrade_gun(weapon)
{
	current_weapon = weapon;
	upgrade_as_attachment = will_upgrade_weapon_as_attachment( current_weapon );
	self takeWeapon(current_weapon);
	current_weapon = self maps\mp\zombies\_zm_weapons::switch_from_alt_weapon( current_weapon );
	self.current_weapon = current_weapon;
	upgrade_name = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( current_weapon, upgrade_as_attachment );
	self giveweapon(upgrade_name, 0 , self maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options( upgrade_name ));
	self switchtoweapon (upgrade_name);
}

givePerkBottle(perk)
{
	if(!(self hasPerk(perk) || (self maps\mp\zombies\_zm_perks::has_perk_paused(perk))))
	{
		self.isDrinkingPerk = 1;
		gun = self maps\mp\zombies\_zm_perks::perk_give_bottle_begin(perk);
        evt = self waittill_any_return("fake_death", "death", "player_downed", "weapon_change_complete");
        if (evt == "weapon_change_complete")
       	self maps\mp\zombies\_zm_perks::perk_give_bottle_end(gun, perk);
       	self.isDrinkingPerk = 0;
    	self notify("burp");
	}
}


//////////////////////////////////
//
//	[Enemy Counter Script]
//
//////////////////////////////////


init_enemycounter()
{
	if (getDvarInt("cinematic_mode") != 1)
	{
		level thread enemycounter_hud();
	}
}

player_enemycounter()
{

}


enemycounter_hud()
{
	level endon("end_game");
	self endon("disconnect");

	enemycounter = newhudelem();
	enemycounter.alignx = "center";
	enemycounter.aligny = "bottom";
	enemycounter.horzalign = "user_center";
	enemycounter.vertalign = "user_bottom";
	enemycounter.x += 0;
	enemycounter.y -= 0;
	enemycounter.fontscale = 1;
	enemycounter.alpha = 1;
	enemycounter.color = ( 1, 1, 1 );
	enemycounter.hidewheninmenu = 1;
	enemycounter.foreground = 1;
	enemycounter.label = &"^6Enemies Left: ^1";

	while (1)
	{
		enemycounter setvalue(( maps\mp\zombies\_zm_utility::get_round_enemy_array().size + level.zombie_total ));

		wait 0.05;
	}
}


//////////////////////////////////
//
//	[Exfil Script]
//
//	Individual mod link: https://github.com/techboy04/Exfil-T6Zombies
//
//////////////////////////////////


init_exfil()
{
    precacheshader("waypoint_revive_zm");
    precacheshader("scorebar_zom_1");
    setExfillocation();
    if (level.radiomodel != "")
    {
    	precachemodel(level.radiomodel);
    }
    level thread createExfilIcon();
    level.roundincrease = 5;
    level.canexfil = 0;
    level.nextexfilround = 11;
    level.exfilstarted = 0;
    level.successfulexfil = 0;
    level.gameisending = 0;
    level.exfilplayervotes = 0;
    level thread spawnExfil();
    level thread enableExfil();
    level thread checkForRound();
}

player_exfil()
{
	self thread exfilHUD();
	self thread downOnExfil();
	self thread showscoreboardtext();
}

createExfilIcon()
{
	exfil_icon = newHudElem();
    exfil_icon.x = level.iconlocation[ 0 ];
    exfil_icon.y = level.iconlocation[ 1 ];
	exfil_icon.z = level.iconlocation[ 2 ] + 80;
	exfil_icon.color = (1,1,1);
    exfil_icon.isshown = 1;
    exfil_icon.archived = 0;
    exfil_icon setshader( "waypoint_revive_zm", 6, 6 );
    exfil_icon setwaypoint( 1 );
    
    while(1)
    {
    	if (level.canexfil == 1 && level.exfilstarted == 0)
    	{
    		exfil_icon.alpha = 1;
    	}
    	else if (level.canexfil == 1 && level.exfilstarted == 1)
    	{
    		exfil_icon.alpha = 1;
    		exfil_icon.x = level.exfillocation[ 0 ];
    		exfil_icon.y = level.exfillocation[ 1 ];
 			exfil_icon.z = level.exfillocation[ 2 ] + 80;
			exfil_icon setshader( "waypoint_revive_zm", 0, 0 );
			exfil_icon setwaypoint( 1, "waypoint_revive_zm", 1 );
    	}
    	else if (level.canexfil == 0 && level.exfilstarted == 0)
    	{
    		exfil_icon.alpha = 0;
    	}
    	if (level.gameisending == 1)
    	{
    		exfil_icon.alpha = 0;
    	}
    	wait 0.1;
    }
}

checkForRound()
{
	while(1)
	{
		if(level.round_number == level.nextexfilround)
		{
			level.nextexfilround += level.roundincrease;
			level notify ("can_exfil");
		}
		wait 0.5;
	}
}

enableExfil()
{
	while(1)
	{
		level waittill ("can_exfil");
		level endon ("exfil_started");
		level.canexfil = 1;
		
		if(getDvarInt("enable_custom_subtitles") == 1)
		{
			foreach ( player in get_players() )
				player thread sendsubtitletext(chooseAnnouncer(), 1, exfilAvailable(), 5);
		}
		else
		{
			foreach ( player in get_players() )
	       		player thread showExfilMessage();
		}
		wait 120;
		level.canexfil = 0;
		if(getDvarInt("enable_custom_subtitles") == 1)
		{
			foreach ( player in get_players() )
				player thread sendsubtitletext(chooseAnnouncer(), 1, exfilUnAvailable(), 5);
		}
		else
		{
			foreach ( player in get_players() )
        		player thread showExfilMessage();
        }
	}
}

spawnExfil()
{
	exfilTrigger = spawn( "trigger_radius", (level.iconlocation), 1, 50, 50 );
	exfilTrigger setHintString("");
	exfilTrigger setcursorhint( "HINT_NOICON" );
	if (level.radiomodel != "")
	{
		exfilModel = spawn( "script_model", (level.iconlocation));
		exfilModel setmodel ("p6_zm_buildable_sq_transceiver");
		exfilModel rotateTo(level.radioangle,.1);
	}
	
	while(1)
	{
		exfilTrigger waittill( "trigger", i );
		if (level.exfilstarted == 0 && level.canexfil == 1)
		{
			if ( i usebuttonpressed() )
			{
				
				if (level.exfilvoting == 0)
				{
					level.exfilplayervotes = 0;
					level.exfilvoting = 1;

					level.exfilplayervotes += 1;
					self.exfilvoted = 1;
					if (level.exfilplayervotes >= level.players.size)
					{
						level.votingsuccess = 1;
						level notify ("voting_finished");
					}

					if (level.players.size > 1)
					{
						level thread exfilVoteTimer();
						foreach ( player in get_players() )
						{
							player thread showvoting(i);
							player thread checkVotingInput();
							player.canrespawn = 0;
						}
					
						if (level.votingsuccess != 1)
						{
							level waittill_any ("voting_finished","voting_expired");
						}
					}
					else
					{
						level.votingsuccess = 1;
					}

					if (level.votingsuccess == 1)
					{
						level.exfilvoting = 0;
						earthquake( 0.5, 0.5, self.origin, 800 );
						foreach ( player in get_players() )
						{
							player playsound( "evt_nuke_flash" );
						}
						fadetowhite = newhudelem();
						fadetowhite.x = 0;
						fadetowhite.y = 0;
						fadetowhite.alpha = 0;
						fadetowhite.horzalign = "fullscreen";
						fadetowhite.vertalign = "fullscreen";
						fadetowhite.foreground = 1;
						fadetowhite setshader( "white", 640, 480 );
						fadetowhite fadeovertime( 0.2 );
						fadetowhite.alpha = 0.8;
						wait 1;
					
						level.exfilstarted = 1;
						level thread fixZombieTotal();
						level thread change_zombies_speed("sprint");
						level.zombie_vars[ "zombie_spawn_delay" ] = 0.1;
						playfx( level._effect[ "powerup_on" ], level.exfillocation + (0,0,30) );
						playfx( level._effect[ "lght_marker" ], level.exfillocation );
						level thread spawnExit();
						level thread spawnMiniBoss();
						level notify ("exfil_started");
						foreach ( player in get_players() )
							player thread sendsubtitletext(chooseAnnouncer(), 1, "The portal has opened at " + level.escapezone + "", 5);
					
						fadetowhite fadeovertime( 1 );
						fadetowhite.alpha = 0;
						wait 1.1;
						fadetowhite destroy();
						
						startCountdown(level.starttimer);
					}
				}
			}
			exfilTrigger setHintString("^7Press ^3&&1 ^7to call an exfil");
		}
		else
		{
			exfilTrigger setHintString("");
		}

		wait 0.5;
	}
}

getTimerText(seconds)
{
	
	text = (seconds);
	return text;
}

startCountdown(numtoset)
{
	level endon("game_ended");
	level endon("end_game");
	level.timer = numtoset;
	while(level.timer > 0)
	{
		level.timer -= 1;
		wait 1;
	}
	level notify ("exfil_end");
}

exfilHUD()
{
//	level endon("end_game");
	self endon( "disconnect" );

	exfil_bg = newClientHudElem(self);
	exfil_bg.alignx = "left";
	exfil_bg.aligny = "middle";
	exfil_bg.horzalign = "user_left";
	exfil_bg.vertalign = "user_center";
	exfil_bg.x -= 0;
	exfil_bg.y += 0;
	exfil_bg.fontscale = 2;
	exfil_bg.alpha = 1;
	exfil_bg.color = ( 0, 0, 1 );
	exfil_bg.hidewheninmenu = 1;
	exfil_bg.foreground = 1;
	exfil_bg setShader("scorebar_zom_1", 124, 32);
	
	
	exfil_text = newClientHudElem(self);
	exfil_text.alignx = "left";
	exfil_text.aligny = "middle";
	exfil_text.horzalign = "user_left";
	exfil_text.vertalign = "user_center";
	exfil_text.x += 20;
	exfil_text.y += 5;
	exfil_text.fontscale = 1;
	exfil_text.alpha = 1;
	exfil_text.color = ( 1, 1, 1 );
	exfil_text.hidewheninmenu = 1;
	exfil_text.foreground = 1;
	exfil_text.label = &"Exfil Timer: ^2";
	
	exfil_target = newClientHudElem(self);
	exfil_target.alignx = "left";
	exfil_target.aligny = "middle";
	exfil_target.horzalign = "user_left";
	exfil_target.vertalign = "user_center";
	exfil_target.x += 20;
	exfil_target.y -= 5;
	exfil_target.fontscale = 1;
	exfil_target.alpha = 0;
	exfil_target.color = ( 1, 1, 1 );
	exfil_target.hidewheninmenu = 1;
	exfil_target.foreground = 1;
	exfil_target settext ("Go to the ^2" + level.escapezone);
	
	exfil_kills = newClientHudElem(self);
	exfil_kills.alignx = "left";
	exfil_kills.aligny = "middle";
	exfil_kills.horzalign = "user_left";
	exfil_kills.vertalign = "user_center";
	exfil_kills.x += 20;
	exfil_kills.y -= 5;
	exfil_kills.fontscale = 1;
	exfil_kills.alpha = 0;
	exfil_kills.color = ( 1, 1, 1 );
	exfil_kills.hidewheninmenu = 1;
	exfil_kills.foreground = 1;
	exfil_kills.label = &"Zombie Kills Left: ^2";
	
	thread activateTimer(exfil_text);
	
	while(1)
	{
		exfil_kills setValue (get_round_enemy_array().size + level.zombie_total);
		if ((level.exfilstarted == 1) && (level.gameisending == 0))
		{
			exfil_bg.alpha = 1;
			exfil_target.alpha = 0;
			exfil_text.alpha = 1;
			exfil_kills.alpha = 1;
//			exfil_text setValue (level.timer);
//			exfil_text setTimer(level.timer);
			exfil_target setValue (level.escapezone);
			if ( distance( level.exfillocation, self.origin ) <= 300 )
			{
				exfil_bg.color = ( 0, 1, 0 );
			}
			else
			{
				exfil_bg.color = ( 0, 0, 1 );
			}
			
			if(get_round_enemy_array().size + level.zombie_total == 0)
			{
				exfil_target.alpha = 1;
				exfil_kills.alpha = 0;
			}
			
		}
		else
		{
			exfil_bg.alpha = 0;
			exfil_target.alpha = 0;
			exfil_text.alpha = 0;
			exfil_kills.alpha = 0;
		}
		
		wait 0.5;
	}
}

activateTimer(hud)
{
	level waittill("exfil_started");
	hud setTimer(120);
}

setExfillocation()
{
	if ( getDvar( "g_gametype" ) == "zgrief" || getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead grief
		{
			level.iconlocation = (-769,8671,1374);
			level.escapezone = ("Roof");
			level.radiomodel = ("");
			level.radioangle = (0,90,0);
			level.exfillocation = (2496,9433,1704);
			level.starttimer = 120;
			level.requirezombiekills = 0;
		}
		else if(getDvar("mapname") == "zm_buried") //buried grief
		{
			level.iconlocation = (0,0,0);
			level.escapezone = ("Roof");
			level.radiomodel = ("");
			level.radioangle = (0,0,0);
			level.exfillocation = (0,0,0);
			level.starttimer = 120;
			level.requirezombiekills = 0;
		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			level.iconlocation = (-1349,994,-63);
			level.escapezone = ("Bunker");
			level.radiomodel = ("");
			level.radioangle = (0,0,0);
			level.exfillocation = (-581,375,80);
			level.starttimer = 120;
			level.requirezombiekills = 0;
		}
		else if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			if(getDvar("ui_zm_mapstartlocation") == "town") //town
			{
				level.iconlocation = (1936,646,-55);
				level.escapezone = ("Barber");
				level.radiomodel = ("");
				level.radioangle = (0,0,0);
				level.exfillocation = (744,-1456,128);
				level.starttimer = 120;
				level.requirezombiekills = 1;
			}
			else if (getDvar("ui_zm_mapstartlocation") == "transit") //busdepot
			{
				level.iconlocation = (-6483,5297,-55);
				level.escapezone = ("Exfil Point");
				level.radiomodel = ("");
				level.radioangle = (0,126,0);
				level.exfillocation = (-7388,4239,-63);
				level.starttimer = 120;
				level.requirezombiekills = 1;
			}
			else if (getDvar("ui_zm_mapstartlocation") == "farm") //farm
			{
				level.iconlocation = (7995,-6627,117);
				level.escapezone = ("Barn");
				level.radiomodel = ("");
				level.radioangle = (0,0,0);
				level.exfillocation = (8111,-4787,48);
				level.starttimer = 120;
				level.requirezombiekills = 1;
			}
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{
			level.iconlocation = (-1006,8804,1336);
			level.escapezone = ("Roof");
			level.radiomodel = ("");
			level.radioangle = (0,90,0);
			level.exfillocation = (2496,9433,1704);
			level.starttimer = 120;
			level.requirezombiekills = 0;
		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			level.iconlocation = (1005,-1572,50);
			level.escapezone = ("Tunnel");
			level.radiomodel = ("");
			level.radioangle = (0,0,0);
			level.exfillocation = (-131,250,358);
			level.starttimer = 120;
			level.requirezombiekills = 0;
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			level.iconlocation = (-6201,4108,-7);
			level.escapezone = ("Diner");
			level.radiomodel = ("p6_zm_buildable_sq_transceiver");
			level.radioangle = (0,126,0);
			level.exfillocation = (-4415,-7063,-65);
			level.starttimer = 120;
			level.requirezombiekills = 0;
			
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			level.iconlocation = (2899,5083,-375);
			level.escapezone = ("No Mans Land");
			level.radiomodel = ("");
			level.radioangle = (0,90,0);
			level.exfillocation = (137,-299,320);
			level.starttimer = 120;
			level.requirezombiekills = 0;
		}
		else if(getDvar("mapname") == "zm_highrise")
		{
			level.iconlocation = (1472,1142,3401);
			level.escapezone = ("Roof");
			level.radiomodel = ("");
			level.radioangle = (0,0,0);
			level.exfillocation = (2036,305,2880);
			level.starttimer = 120;
			level.requirezombiekills = 0;
		}
	}
}

spawnExit()
{
	exfilExit = spawn( "trigger_radius", (level.exfillocation), 10, 200, 200 );
	exfilExit setHintString("^7Kill all the Zombies");
	exfilExit setcursorhint( "HINT_NOICON" );
	
	foreach (player in get_players())
	{
		player show_big_message("Kill all the Zombies to open the portal!", "");
	}
	
	waitTillNoZombies();
	
	foreach (player in get_players())
	{
		player show_big_message("All Enemies Eliminated! You can now Escape!", "");
	}
	
	exfilExit setHintString("^7Press ^3&&1 ^7escape");
	
	while(1)
	{
		exfilExit waittill( "trigger", i );
		if ( i usebuttonpressed())
		{
			i enableinvulnerability();
			level.successfulexfil = 1;
			escapetransition = newClientHudElem(i);
			escapetransition.x = 0;
			escapetransition.y = 0;
			escapetransition.alpha = 0;
			escapetransition.horzalign = "fullscreen";
			escapetransition.vertalign = "fullscreen";
			escapetransition.foreground = 0;
			escapetransition setshader( "white", 640, 480 );
			escapetransition.color = (0,0,0);
			escapetransition fadeovertime( 0.5 );
			escapetransition.alpha = 1;
			wait 3;
			
			escapetransition.foreground = 0;
			escapetransition fadeovertime( 0.2 );
			escapetransition.alpha = 0;
			i disableinvulnerability();
			if (level.players.size == 1)
			{
				level thread sendsubtitletext(chooseAnnouncer(), 1, "Everyone has successfully escaped!", 5);
				level notify( "end_game" );
			}
			else
			{
				escapetransition.alpha = 0;
				i thread maps\mp\gametypes_zm\_spectating::setspectatepermissions();
    			i.sessionstate = "spectator";
				escapetransition destroy();
				if (checkAmountPlayers())
				{
					level thread sendsubtitletext(chooseAnnouncer(), 1, "Everyone has successfully escaped!", 5);
					level notify( "end_game" );
				}
				else
				{
					level thread sendsubtitletext(chooseAnnouncer(), 1, i + " has escaped!", 2);
				}
				
			}
			level waittill ("end_game");
			exfilExit setHintString("");
		}
	
	}
}

waitTillNoZombies()
{
	while(get_round_enemy_array().size + level.zombie_total > 0)
	{
		wait 0.1;
	}
}

downOnExfil()
{
	level waittill ("exfil_end");
	if ( distance( level.exfillocation, self.origin ) > 300 )
	{
		
		deathtransition = newClientHudElem(self);
		deathtransition.x = 0;
		deathtransition.y = 0;
		deathtransition.alpha = 0;
		deathtransition.horzalign = "fullscreen";
		deathtransition.vertalign = "fullscreen";
		deathtransition.foreground = 1;
		deathtransition setshader( "white", 640, 480 );
		deathtransition.color = (1,0,0);
		deathtransition fadeovertime( 0.2 );
		deathtransition.alpha = 1;
		wait 1;
		self unsetperk("specialty_quickrevive");
		self.lives = 0;
		self thread show_big_message("You were consumed by the Aether!","");
		self dodamage(self.health, self.origin);
		deathtransition fadeovertime( 1 );
		deathtransition.alpha = 0;
		wait 1.1;
		
		deathtransition.foreground = 0;
		level notify( "end_game" );
	}
	else
	{
		self thread forcePlayersToExfil();
	}
}

showscoreboardtext()
{
	level waittill("end_game");
	level.gameisending = 1;
	wait 8;
	
	scoreboardText = newclienthudelem( self );
    scoreboardText.alignx = "center";
    scoreboardText.aligny = "middle";
    scoreboardText.horzalign = "center";
    scoreboardText.vertalign = "middle";
    scoreboardText.y -= 100;

    if ( self issplitscreen() )
        scoreboardText.y += 70;

    scoreboardText.foreground = 1;
    scoreboardText.fontscale = 8;
    scoreboardText.alpha = 0;
    scoreboardText.color = ( 0, 1, 0 );
    scoreboardText.hidewheninmenu = 1;
    scoreboardText.font = "default";

	if ((level.successfulexfil == 1) && (level.exfilstarted == 1))
	{
		scoreboardText.color = ( 0, 1, 0 );
		scoreboardText settext( "Exfil Successful" );
	}
	else if ((level.successfulexfil == 0) && (level.exfilstarted == 1))
	{
		scoreboardText.color = ( 1, 0, 0 );
		scoreboardText settext( "Exfil Failed" );
	}

    scoreboardText changefontscaleovertime( 0.25 );
    scoreboardText fadeovertime( 0.25 );
    scoreboardText.alpha = 1;
    scoreboardText.fontscale = 4;
}

fixZombieTotal()
{
	level.zombie_total = 40;
}

showExfilMessage()
{	
	belowMSG = newclienthudelem( self );
    belowMSG.alignx = "center";
    belowMSG.aligny = "bottom";
    belowMSG.horzalign = "center";
    belowMSG.vertalign = "bottom";
    belowMSG.y -= 10;
    
    belowMSG.foreground = 1;
    belowMSG.fontscale = 4;
    belowMSG.alpha = 0;
    belowMSG.hidewheninmenu = 1;
    belowMSG.font = "default";

	if (level.canexfil == 0)
	{
		belowMSG settext( "Exfil window gone!" );
		belowMSG.color = ( 1, 0, 0 );
	}
	else if (level.canexfil == 1)
	{
		belowMSG settext( "Exfil is available!" );
		belowMSG.color = ( 0, 1, 0 );
	}

    belowMSG changefontscaleovertime( 0.25 );
    belowMSG fadeovertime( 0.25 );
    belowMSG.alpha = 1;
    belowMSG.fontscale = 2;
    
    wait 8;
    
    belowMSG changefontscaleovertime( 0.25 );
    belowMSG fadeovertime( 0.25 );
    belowMSG.alpha = 0;
    belowMSG.fontscale = 4;
    wait 1.1;
    belowMSG destroy();
}

checkAmountPlayers()
{
	if (level.players.size == 1)
	{
		return true;
	}
	else
	{
		count = 0;
		foreach ( player in level.players )
		{
		if( distance( level.iconlocation, player.origin ) <= 10 )
		    {
	   			count += 1;
	   		}
		}
		if (level.players.size <= count)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
}

forcePlayersToExfil()
{
	self enableinvulnerability();
	level.successfulexfil = 1;
	escapetransition = newClientHudElem(self);
	escapetransition.x = 0;
	escapetransition.y = 0;
	escapetransition.alpha = 0;
	escapetransition.horzalign = "fullscreen";
	escapetransition.vertalign = "fullscreen";
	escapetransition.foreground = 1;
	escapetransition setshader( "white", 640, 480 );
	escapetransition.color = (0,0,0);
	escapetransition fadeovertime( 0.5 );
	escapetransition.alpha = 1;
	wait 3;
			
	escapetransition.foreground = 0;
	self disableinvulnerability();
	if (level.players.size == 1)
	{
		level notify( "end_game" );
	}
	else
	{
		escapetransition.alpha = 0;
		self thread maps\mp\gametypes_zm\_spectating::setspectatepermissions();
    	self.sessionstate = "spectator";
		escapetransition destroy();
		if (checkAmountPlayers())
		{
			level notify( "end_game" );
		}
				
	}
}

showVoting(execPlayer)
{
	self endon( "disconnect" );
	
	level.exfilvoteexec = execPlayer;
	
	hudy = -100;
	
	voting_bg = newClientHudElem(self);
	voting_bg.alignx = "left";
	voting_bg.aligny = "middle";
	voting_bg.horzalign = "user_left";
	voting_bg.vertalign = "user_center";
	voting_bg.x -= 0;
	voting_bg.y = hudy;
	voting_bg.fontscale = 2;
	voting_bg.alpha = 1;
	voting_bg.color = ( 1, 1, 1 );
	voting_bg.hidewheninmenu = 1;
	voting_bg.foreground = 1;
	voting_bg setShader("scorebar_zom_1", 124, 32);
	
	
	voting_text = newClientHudElem(self);
	voting_text.alignx = "left";
	voting_text.aligny = "middle";
	voting_text.horzalign = "user_left";
	voting_text.vertalign = "user_center";
	voting_text.x += 20;
	voting_text.y = hudy + 5;
	voting_text.fontscale = 1;
	voting_text.alpha = 1;
	voting_text.color = ( 1, 1, 1 );
	voting_text.hidewheninmenu = 1;
	voting_text.foreground = 1;
	voting_text.label = &"Timer: ";
	
	voting_target = newClientHudElem(self);
	voting_target.alignx = "left";
	voting_target.aligny = "middle";
	voting_target.horzalign = "user_left";
	voting_target.vertalign = "user_center";
	voting_target.x += 20;
	voting_target.y = hudy - 5;
	voting_target.fontscale = 1;
	voting_target.alpha = 1;
	voting_target.color = ( 1, 1, 1 );
	voting_target.hidewheninmenu = 1;
	voting_target.foreground = 1;
//	voting_target setText ("Press [{+actionslot 4}] to agree on Exfil");
	voting_target setText (execPlayer.name + " wants to Exfil - [{+actionslot 4}] to accept");
//[{+actionslot 4}]
	
	voting_votes = newClientHudElem(self);
	voting_votes.alignx = "left";
	voting_votes.aligny = "middle";
	voting_votes.horzalign = "user_left";
	voting_votes.vertalign = "user_center";
	voting_votes.x += 20;
	voting_votes.y = hudy + 15;
	voting_votes.fontscale = 1;
	voting_votes.alpha = 1;
	voting_votes.color = ( 1, 1, 1 );
	voting_votes.hidewheninmenu = 1;
	voting_votes.foreground = 1;
	voting_votes.label = &"Votes left: ";
	
	while(1)
	{
		voting_text setValue (level.votingtimer);
		votesLeft = level.players.size - level.exfilplayervotes;
		voting_votes setValue (votesLeft);
		if (self.exfilvoted == 0)
		{
			voting_bg.color = ( 0, 0, 1 );
		}
		else if (self.exfilvoted == 1)
		{
			voting_bg.color = ( 0, 1, 0 );
		}
		
		if (level.exfilvoting == 0)
		{
			voting_target destroy();
			voting_bg destroy();
			voting_text destroy();
			voting_votes destroy();
		}
		wait 0.1;
	}
}

checkVotingInput()
{
	level endon ("voting_finished");
	level endon ("voting_expired");
	while(level.exfilvoting == 1 && self.exfilvoted == 0)
	{
		if(self actionslotfourbuttonpressed() || (isDefined(self.bot)))
		{
			level.exfilplayervotes += 1;
			self.exfilvoted = 1;
			if (level.exfilplayervotes >= level.players.size)
			{
				level.votingsuccess = 1;
				level notify ("voting_finished");
			}
		}
		wait 0.1;
	}
}

checkIfPlayersVoted()
{
	level endon ("voting_finished");
	level endon ("voting_expired");
	while(1)
	{
		if (level.exfilplayervotes >= level.players.size)
		{
			level.votingsuccess = 1;
			level notify ("voting_finished");
		}
	}
	wait 0.1;
}

exfilVoteTimer()
{
	level endon ("voting_finished");
	level endon ("voting_expired");
	level.votingtimer = 15;
	while(1)
	{
		level.votingtimer -= 1;
		if (level.votingtimer < 0)
		{
			level.exfilplayervotes = 0;
			foreach (player in getPlayers())
				player.exfilvoted = 0;
			level.exfilvoting = 0;
			level.votingsuccess = 0;
			level notify ("voting_expired");
		}
		wait 1;
	}
}

getRequirement()
{
	return level.players.size;
}

spawnMiniBoss()
{
	if(getDvar("mapname") == "zm_prison")
	{
		level notify( "spawn_brutus", 4 );
	}
	else if(getDvar("mapname") == "zm_tomb")
	{
		level.mechz_left_to_spawn++;
		level notify( "spawn_mechz" );
	}
}


//////////////////////////////////
//
//	[Global ATM Script]
//
//	Individual mod link: https://github.com/techboy04/GlobalATM-T6Zombies
//
//////////////////////////////////


init_globalatm()
{
    if ( getDvar( "g_gametype" ) != "zgrief" )
    {
    	level.globalpoints = 0;
    	level setatmlocation();
    	level thread spawnATMDeposit();
    	level thread spawnATMWithdraw();
    }
}

player_globalatm()
{
	self notifyonplayercommand("useatm", "+activate");
}

spawnATMDeposit()
{
	depositTrigger = spawn( "trigger_radius", (level.depositlocation), 1, 50, 50 );
	depositTrigger setHintString("^7Press ^3&&1 ^7to deposit ^31000 ^7to the global ATM (^3$" + level.globalpoints + "^7)");
	depositTrigger setcursorhint( "HINT_NOICON" );
	depositfx = spawn("script_model", (level.depositlocation), 1, 50, 50 );
	depositfx setmodel("tag_origin");
	playfxontag( level._effect["powerup_on"], depositfx, "tag_origin" );

	while(1)
	{
		depositTrigger waittill( "trigger", i );
		depositTrigger setHintString("^7Press ^3&&1 ^7to deposit ^31000 ^7to the global ATM (^3$" + level.globalpoints + "^7)");
		if ( (i.score >= 1000) )
		{
			i waittill("useatm");
			i.score -= 1000;
			i playsound ("zmb_weap_wall");
			level.globalpoints += 1000;
		}
	}
}

spawnATMWithdraw()
{
	withdrawTrigger = spawn( "trigger_radius", (level.withdrawlocation), 1, 50, 50 );
	withdrawTrigger setHintString("^7Press ^3&&1 ^7to withdraw ^31000 ^7from the global ATM (^3$" + level.globalpoints + "^7)");
	withdrawTrigger setcursorhint( "HINT_NOICON" );
	withdrawfx = spawn("script_model", (level.withdrawlocation), 1, 50, 50 );
	withdrawfx setmodel("tag_origin");
	playfxontag( level._effect["powerup_on"], withdrawfx, "tag_origin" );

	while(1)
	{
		withdrawTrigger waittill( "trigger", i );
		withdrawTrigger setHintString("^7Press ^3&&1 ^7to withdraw ^31000 ^7from the global ATM (^3$" + level.globalpoints + "^7)");
		if ( (level.globalpoints >= 1000) && (level.globalpoints != 0) )
		{
			i waittill("useatm");
			i.score += 1000;
			i playsound ("zmb_cha_ching");
			level.globalpoints -= 1000;
		}
	}
}

setatmlocation()
{
	if ( getDvar( "g_gametype" ) == "zgrief" || getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead grief
		{

		}
		else if(getDvar("mapname") == "zm_buried") //buried grief
		{

		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			level.depositlocation = (-642,271,-35);
			level.withdrawlocation = (-789,652,-35);
		}
		else if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			if(getDvar("ui_zm_mapstartlocation") == "town")
			{
				level.depositlocation = (750,434,-19); //Town
				level.withdrawlocation = (643,23,-19);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "transit")
			{
				level.depositlocation = (-7931,4993,-36); //Town
				level.withdrawlocation = (-8021,4722,-36);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "farm")
			{
				level.depositlocation = (8340,-4711,284);
				level.withdrawlocation = (8047,-5313,284);
			}
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{
			level.depositlocation = (1706,10684,1358);
			level.withdrawlocation = (942,10678,1356);
		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			level.depositlocation = (-448,-237,30);
			level.withdrawlocation = (-443,-37,28);
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			level.depositlocation = (801,76,-38); //Town
			level.withdrawlocation = (643,23,-38);
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			level.depositlocation = (2451,4457,-295);
			level.withdrawlocation = (1935,5058,-287);
		}
		else if(getDvar("mapname") == "zm_highrise")
		{
			level.depositlocation = (1367,-419,1316);
			level.withdrawlocation = (1665,-418,1316);
		}
	}
}


//////////////////////////////////
//
//	[Health Bar Script]
//
//////////////////////////////////


init_health()
{

}

player_health()
{
	if (getDvarInt("cinematic_mode") != 1)
	{
		self thread health_bar_hud();
		self thread shield_hud();
	}
}


health_bar_hud()
{
	level endon("end_game");
	self endon("disconnect");
	flag_wait("initial_blackscreen_passed");

	health_bar = self createprimaryprogressbar();
//	health_bar setpoint("BOTTOM", undefined, -335, -70);
	health_bar.hidewheninmenu = 1;
	health_bar.bar.hidewheninmenu = 1;
	health_bar.barframe.hidewheninmenu = 1;
	health_bar.alpha = 1;

	health_bar_text = self createprimaryprogressbartext();
//	health_bar_text setpoint("BOTTOM", undefined, -410, -70);
	health_bar_text.hidewheninmenu = 1;
//	health_bar_text.fontscale = 1;

	if (getDvarInt("health_bar_look") == 0)
	{
		health_bar_text setpoint("BOTTOM_LEFT", undefined, -40, -108);
		health_bar setpoint("BOTTOM_LEFT", undefined, -40, -93);
		health_bar.color = (0,0,0);
		health_bar.bar.color = (1,1,1);
	}
	else if (getDvarInt("health_bar_look") == 1)
	{
		health_bar_text setpoint("BOTTOM", undefined, -85, 0);
		health_bar setpoint("BOTTOM", undefined, 0, 0);
		health_bar.color = (1,0,0);
		health_bar.bar.color = (1,0.5,0.5);
	}

	while (1)
	{
		if (isDefined(self.e_afterlife_corpse) || ( isDefined( self.revivetrigger ) ))
		{
			if (health_bar.alpha != 0)
			{
				health_bar.alpha = 0;
				health_bar.bar.alpha = 0;
				health_bar.barframe.alpha = 0;
				health_bar_text.alpha = 0;
			}
			
			wait 0.05;
			continue;
		}

		if (health_bar.alpha != 1)
		{
				health_bar.alpha = 1;
				health_bar.bar.alpha = 1;
				health_bar.barframe.alpha = 1;
				health_bar_text.alpha = 1;
		}

		health_bar updatebar(self.health / self.maxhealth);
		health_bar_text setvalue(self.health);

		wait 0.05;
	}
}

shield_hud()
{
	self endon("disconnect");
	flag_wait("initial_blackscreen_passed");

	shield_text = self createprimaryprogressbartext();
	shield_text setpoint("BOTTOM", undefined, 205, 15);
	shield_text.hidewheninmenu = 1;
	
	
	shield_bar = self createprimaryprogressbar();
//	shield_bar setpoint("BOTTOM", undefined, -335, -70);
	shield_bar.hidewheninmenu = 1;
	shield_bar.bar.hidewheninmenu = 1;
	shield_bar.barframe.hidewheninmenu = 1;
	shield_bar setpoint("BOTTOM", undefined, 205, 15);
	shield_bar.color = (0.1,0.5,0.1);
	shield_bar.bar.color = (0,1,0);
	shield_bar.alpha = 1;
	
	shield_hud = newClientHudElem(self);
	shield_hud.alignx = "right";
	shield_hud.aligny = "bottom";
	shield_hud.horzalign = "user_right";
	shield_hud.vertalign = "user_bottom";
//	shield_hud.x -= 175;
	shield_hud.y -= 10;
	shield_hud.x -= 205;
	shield_hud.alpha = 0;
	shield_hud.color = ( 1, 1, 1 );
	shield_hud.hidewheninmenu = 1;
	if(getdvar("mapname") == "zm_transit")
	{
		shield_hud setShader("riotshield_zm_icon", 32, 32);
	}
	if(getdvar("mapname") == "zm_tomb")
	{
		shield_hud setShader("zm_riotshield_tomb_icon", 32, 32);
	}
	if(getdvar("mapname") == "zm_prison")
	{
		shield_hud setShader("zm_riotshield_hellcatraz_icon", 32, 32);
	}
	

	for(;;)
	{
		if (self hasweapon("riotshield_zm") || self hasweapon("alcatraz_shield_zm") || self hasweapon("tomb_shield_zm") )
		{
			shield_text.alpha = 0;
			shield_hud.alpha = 1;
			shield_bar.alpha = 1;
			shield_bar.bar.alpha = 1;
		}
		else
		{
			shield_text.alpha = 0;
			shield_hud.alpha = 0;
			shield_bar.alpha = 0;
			shield_bar.bar.alpha = 0;
		}
		shield_text setvalue(2250 - self.shielddamagetaken);
		wait 0.05;
		
		if(self.shielddamagetaken >= 2250)
		{
			shield_text.alpha = 0;
			shield_bar.alpha = 0;
			shield_hud.alpha = 0;
			shield_bar.bar.alpha = 0;
		}
		shield_bar updatebar((2250 - self.shielddamagetaken) / 2250);
	}
}


//////////////////////////////////
//
//	[Hitmarker Script]
//
//////////////////////////////////


init_hitmarker()
{
	precacheshader("damage_feedback");
}

player_hitmarker()
{
	self thread damagehitmarker();
}

damagehitmarker()
{
    self thread startwaiting();
    self.hitmarker = newdamageindicatorhudelem( self );
    self.hitmarker.horzalign = "center";
    self.hitmarker.vertalign = "middle";
    self.hitmarker.x = -12;
    self.hitmarker.y = -12;
    self.hitmarker.alpha = 0;
    self.hitmarker setshader( "damage_feedback", 24, 48 );
}

startwaiting()
{
    for(;;)
    {
        foreach( zombie in getaiarray( level.zombie_team ) )
        {
            if( !(IsDefined( zombie.waitingfordamage )) )
            {
                zombie thread hitmark();
            }
        }
        wait 0.25;
    }
}

hitmark()
{
    self endon( "killed" );
    self.waitingfordamage = 1;
    for(;;)
    {
        self waittill( "damage", amount, attacker, dir, point, mod );
        attacker.hitmarker.alpha = 0;
        if( isplayer( attacker ) )
        {
            if( isalive( self ) )
            {
                attacker.hitmarker.color = ( 1, 1, 1 );
                attacker.hitmarker.alpha = 1;
                attacker.hitmarker fadeovertime( 1 );
                attacker.hitmarker.alpha = 0;
            }
            else
            {
                attacker.hitmarker.color = ( 1, 0, 0 );
                attacker.hitmarker.alpha = 1;
                attacker.hitmarker fadeovertime( 1 );
                attacker.hitmarker.alpha = 0;
                self notify( "killed" );
            }
        }
    }
}


//////////////////////////////////
//
//	[Instant PAP Script]
//
//	Individual mod link: https://github.com/techboy04/Instant-PAP-T6Zombies
//
//////////////////////////////////


init_instantpap()
{
	if(isDefined(level.custom_pap_validation)){
		level.original_custom_pap_validation = level.custom_pap_validation;
	}
	level.custom_pap_validation = ::instapap;
}

player_instantpap()
{

}

instapap(player){
	current_weapon = player getcurrentweapon();
	current_weapon = player maps\mp\zombies\_zm_weapons::switch_from_alt_weapon( current_weapon );
	if ( !player maps\mp\zombies\_zm_magicbox::can_buy_weapon() && !player maps\mp\zombies\_zm_laststand::player_is_in_laststand() && !is_true( player.intermission ) || player isthrowinggrenade() && !player maps\mp\zombies\_zm_weapons::can_upgrade_weapon( current_weapon ) )
	{
		wait 0.1;
		return 0;
	}
	if ( is_true( level.pap_moving ) )
	{
		return 0;
	}
	if ( player isswitchingweapons() )
	{
		wait 0.1;
		if ( player isswitchingweapons() )
		{
			return 0;
		}
	}
	if ( !maps\mp\zombies\_zm_weapons::is_weapon_or_base_included( current_weapon ) )
	{
		return 0;
	}
	if(isDefined(level.original_custom_pap_validation)){
		if(!self [[ level.original_custom_pap_validation ]]( player )){
			return 0;
		}
	}
	current_cost = self.cost;
	player.restore_ammo = undefined;
	player.restore_clip = undefined;
	player.restore_stock = undefined;
	player_restore_clip_size = undefined;
	player.restore_max = undefined;
	upgrade_as_attachment = will_upgrade_weapon_as_attachment( current_weapon );
	if ( upgrade_as_attachment )
	{
		current_cost = self.attachment_cost;
		player.restore_ammo = 1;
		player.restore_clip = player getweaponammoclip( current_weapon );
		player.restore_clip_size = weaponclipsize( current_weapon );
		player.restore_stock = player getweaponammostock( current_weapon );
		player.restore_max = weaponmaxammo( current_weapon );
	}
	if ( player maps\mp\zombies\_zm_pers_upgrades_functions::is_pers_double_points_active() )
	{
		current_cost = player maps\mp\zombies\_zm_pers_upgrades_functions::pers_upgrade_double_points_cost( current_cost );
	}
	if ( player.score < current_cost ) 
	{
		self playsound( "deny" );
		if ( isDefined( level.custom_pap_deny_vo_func ) )
		{
			player [[ level.custom_pap_deny_vo_func ]]();
		}
		else
		{
			player maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "perk_deny", undefined, 0 );
		}
		return 0;
	}
	
	self.pack_player = player;
	flag_set( "pack_machine_in_use" );
	maps\mp\_demo::bookmark( "zm_player_use_packapunch", getTime(), player );
	player maps\mp\zombies\_zm_stats::increment_client_stat( "use_pap" );
	player maps\mp\zombies\_zm_stats::increment_player_stat( "use_pap" );
	player maps\mp\zombies\_zm_score::minus_to_player_score( current_cost, 1 );
	sound = "evt_bottle_dispense";
	playsoundatposition( sound, self.origin );
	self thread maps\mp\zombies\_zm_audio::play_jingle_or_stinger( "mus_perks_packa_sting" );
	player maps\mp\zombies\_zm_audio::create_and_play_dialog( "weapon_pickup", "upgrade_wait" );
	if ( !is_true( upgrade_as_attachment ) )
	{
		player thread do_player_general_vox( "general", "pap_wait", 10, 100 );
	}
	else
	{
		player thread do_player_general_vox( "general", "pap_wait2", 10, 100 );
	}
	self.current_weapon = current_weapon;
	upgrade_name = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( current_weapon, upgrade_as_attachment );
	
	//wait_for_player_to_take
	upgrade_weapon = upgrade_name;
	player maps\mp\zombies\_zm_stats::increment_client_stat( "pap_weapon_grabbed" );
	player maps\mp\zombies\_zm_stats::increment_player_stat( "pap_weapon_grabbed" );
	current_weapon = player getcurrentweapon();
	if ( is_player_valid( player ) && !player.is_drinking && !is_placeable_mine( current_weapon ) && !is_equipment( current_weapon ) && level.revive_tool != current_weapon && current_weapon != "none" && !player hacker_active() )
	{
		player takeWeapon(current_weapon);
		maps\mp\_demo::bookmark( "zm_player_grabbed_packapunch", getTime(), player );
		self notify( "pap_taken" );
		player notify( "pap_taken" );
		player.pap_used = 1;
		if ( !is_true( upgrade_as_attachment ) )
		{
			player thread do_player_general_vox( "general", "pap_arm", 15, 100 );
		}
		else
		{
			player thread do_player_general_vox( "general", "pap_arm2", 15, 100 );
		}
		weapon_limit = get_player_weapon_limit( player );
		player maps\mp\zombies\_zm_weapons::take_fallback_weapon();
		primaries = player getweaponslistprimaries();
		if ( isDefined( primaries ) && primaries.size >= weapon_limit )
		{
			player maps\mp\zombies\_zm_weapons::weapon_give( upgrade_weapon );
		}
		else
		{
			player giveweapon( upgrade_weapon, 0, player maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options( upgrade_weapon ) );
			player givestartammo( upgrade_weapon );
		}
		player switchtoweapon( upgrade_weapon );
		if ( is_true( player.restore_ammo ) )
		{
			new_clip = player.restore_clip + ( weaponclipsize( upgrade_weapon ) - player.restore_clip_size );
			new_stock = player.restore_stock + ( weaponmaxammo( upgrade_weapon ) - player.restore_max );
			player setweaponammostock( upgrade_weapon, new_stock );
			player setweaponammoclip( upgrade_weapon, new_clip );
		}
		player.restore_ammo = undefined;
		player.restore_clip = undefined;
		player.restore_stock = undefined;
		player.restore_max = undefined;
		player.restore_clip_size = undefined;
		player maps\mp\zombies\_zm_weapons::play_weapon_vo( upgrade_weapon );
	}

	self.current_weapon = "";
	if ( is_true( level.zombiemode_reusing_pack_a_punch ) )
	{
		self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH_ATT", self.cost );
	}
	else
	{
		self sethintstring( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
	}
	self setvisibletoall();
	self.pack_player = undefined;
	flag_clear( "pack_machine_in_use" );
	return 0;	
}


//////////////////////////////////
//
//	[Rampage Statue Script]
//
//	Individual mod link: https://github.com/techboy04/RampageStatue-T6Zombies
//
//////////////////////////////////


init_rageinducer()
{
	setRagelocation();
	level.rolledstaff = 0;
	level.finishedrampage = 0;
	level.rampagevoting = 0;
    level thread spawnInducer();
    level thread LoopStaffModels();
    level thread rampageHUD();
}

player_rageinducer()
{
	if (level.ragestarted == 1)
	{
		self iprintln("Rampage Statue is activated! Be careful!");
	}
}

startInducer()
{
	level thread show_big_message("Rampage Statue has been activated!", "zmb_laugh_child");
	foreach ( player in get_players() )
		player thread sendsubtitletext("Rampage Statue", 1, "Can you prove your worthiness to the statue?", 3);
	thread nuke_flash();
	level.ragestarted = 1;
	level thread change_zombies_speed("sprint");
	playfx( level._effect[ "powerup_on" ], (level.effectlocation[0],level.effectlocation[1],level.effectlocation[2]+60) );
	level.zombie_vars[ "zombie_spawn_delay" ] = 0.1;
	
	level.zombie_round_start_delay = 0;
	
	level thread roundChecker();
	level waittill("end_rage");
	thread nuke_flash();
	level thread change_zombies_speed("walk");
	show_big_message("Rampage Statue is satisfied", "zmb_cha_ching");
	foreach ( player in get_players() )
		player thread sendsubtitletext("Rampage Statue", 1, "The statue is happy! It brought you something special!", 5);
	if (level.round_number < 20)
	{
		level.zombie_vars[ "zombie_spawn_delay" ] = 2;
	}
	else
	{
		level.zombie_vars[ "zombie_spawn_delay" ] = 1.8;
	}
	level.ragestarted = 0;
	level.finishedrampage = 1;
//	level thread maps/mp/zombies/_zm_powerups::specific_powerup_drop( "full_ammo", level.effectlocation );
}

roundChecker()
{
	while(1)
	{
		if (getDvarInt("rampage_max_round") < level.round_number)
		{
			level notify ("end_rage");
			level notify ("begin_staff_roll");
			break;
		}
		wait 0.5;
	}
}

spawnInducer()
{
	level.ragestarted = 0;
	rampageTrigger = spawn( "trigger_radius", (level.effectlocation), 1, 50, 50 );
	rampageTrigger setHintString("^7Press ^3&&1 ^7to activate Rampage Statue\nAll zombies will run for a certain amount of rounds");
	rampageTrigger setcursorhint( "HINT_NOICON" );
	rageInducerModel = spawn( "script_model", (level.effectlocation));
	rageInducerModel setmodel ("defaultactor");
	rageInducerModel rotateTo(level.modelangle,.1);
	
	while(1)
	{
		rampageTrigger waittill( "trigger", i );
		if ((level.round_number < getDvarInt("rampage_max_round")) && (level.ragestarted == 0) && (level.finishedrampage == 0))
		{
			if ( i usebuttonpressed() )
			{
				if (level.rampagevoting == 0)
				{
					level.rampagevoting = 1;
					level.exfilplayervotes = 0;
					
					level.exfilplayervotes += 1;
					i.rampagevoted = 1;
					if (level.exfilplayervotes >= level.players.size)
					{
						level.votingsuccess = 1;
						level notify ("voting_finished");
					}
					
					if (level.players.size > 1)
					{
						level thread rampageVoteTimer();
					
						foreach ( player in get_players() )
						{
							player thread showrampagevoting(i);
							player thread checkRampageVotingInput();
						}

						if (level.votingsuccess != 1)
						{
							level waittill_any ("voting_finished","voting_expired");
						}
					}
					else
					{
						level.votingsuccess = 1;
					}
					if (level.votingsuccess == 1)
					{
						level.rampagevoting = 0;
						if (getDvarInt("rampage_max_round") <= 5)
						{
							setDvar("rampage_max_round", 20);
						}
						level thread startInducer();
						rampageTrigger setHintString("The statue is awaiting your worth");
//						break;
					}

				}
			}
		}
		else if ((level.round_number > getDvarInt("rampage_max_round")) && (level.ragestarted == 0) && (level.finishedrampage == 0))
		{
			rampageTrigger setHintString("^7You were too late!");
		}
		else if ((getDvarInt("rampage_max_round") < level.round_number) && (level.finishedrampage == 1))
		{
			rampageTrigger setHintString("^7Press ^3&&1 ^7to pickup a free " + setStaffHintString());
			if ( i usebuttonpressed() )
			{
				reward = getRewardWeapon();
				i maps\mp\zombies\_zm_weapons::weapon_give(reward);
			}
		}
	}
	wait 0.1;
}

rampageHUD()
{
	level endon("end_game");

	rampage_hud = newhudelem();
	rampage_hud.alignx = "left";
	rampage_hud.aligny = "bottom";
	rampage_hud.horzalign = "user_left";
	rampage_hud.vertalign = "user_bottom";
	rampage_hud.x += 10;
	rampage_hud.y -= 60;
	rampage_hud.fontscale = 1;
	rampage_hud.alpha = 1;
	rampage_hud.color = ( 1, 1, 1 );
	rampage_hud.hidewheninmenu = 1;
	rampage_hud.foreground = 1;
	rampage_hud.label = &"Rounds of Rampage Left: ^6";

	while(1)
	{
		if (level.ragestarted == 1)
		{
			rampage_hud.alpha = 1;
		}
		else
		{
			rampage_hud.alpha = 0;
		}
		
		rampage_hud setValue((getDvarInt("rampage_max_round")) - level.round_number );
		
		wait 0.05;
	}
}

checkAmountPlayersRage()
{
	if (level.players.size == 1)
	{
		return true;
	}
	else
	{
		count = 0;
		foreach ( player in level.players )
		{
		if( distance( level.effectlocation, player.origin ) <= 10 )
		    {
	   			count += 1;
	   		}
		}
		if (level.players.size <= count)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
}


showrampageVoting(activator)
{
	self endon( "disconnect" );
	
	level.rampagevoteexec = activator;
	
	hudy = -100;
	
	voting_bg = newClientHudElem(self);
	voting_bg.alignx = "left";
	voting_bg.aligny = "middle";
	voting_bg.horzalign = "user_left";
	voting_bg.vertalign = "user_center";
	voting_bg.x -= 0;
	voting_bg.y = hudy;
	voting_bg.fontscale = 2;
	voting_bg.alpha = 1;
	voting_bg.color = ( 1, 1, 1 );
	voting_bg.hidewheninmenu = 1;
	voting_bg.foreground = 1;
	voting_bg setShader("scorebar_zom_1", 124, 32);
	
	
	voting_text = newClientHudElem(self);
	voting_text.alignx = "left";
	voting_text.aligny = "middle";
	voting_text.horzalign = "user_left";
	voting_text.vertalign = "user_center";
	voting_text.x += 20;
	voting_text.y = hudy + 5;
	voting_text.fontscale = 1;
	voting_text.alpha = 1;
	voting_text.color = ( 1, 1, 1 );
	voting_text.hidewheninmenu = 1;
	voting_text.foreground = 1;
	voting_text.label = &"Timer: ";
	
	voting_target = newClientHudElem(self);
	voting_target.alignx = "left";
	voting_target.aligny = "middle";
	voting_target.horzalign = "user_left";
	voting_target.vertalign = "user_center";
	voting_target.x += 20;
	voting_target.y = hudy - 5;
	voting_target.fontscale = 1;
	voting_target.alpha = 1;
	voting_target.color = ( 1, 1, 1 );
	voting_target.hidewheninmenu = 1;
	voting_target.foreground = 1;
//	voting_target setText ("Press [{+actionslot 4}] to agree on Exfil");
	voting_target setText (activator.name + " wants to Activate the Rampage Statue - [{+actionslot 4}] to accept");
//[{+actionslot 4}]
	
	voting_votes = newClientHudElem(self);
	voting_votes.alignx = "left";
	voting_votes.aligny = "middle";
	voting_votes.horzalign = "user_left";
	voting_votes.vertalign = "user_center";
	voting_votes.x += 20;
	voting_votes.y = hudy + 15;
	voting_votes.fontscale = 1;
	voting_votes.alpha = 1;
	voting_votes.color = ( 1, 1, 1 );
	voting_votes.hidewheninmenu = 1;
	voting_votes.foreground = 1;
	voting_votes.label = &"Votes left: ";
	
	while(1)
	{
		voting_text setValue (level.votingtimer);
		votesLeft = level.players.size - level.exfilplayervotes;
//		votesLeft = getRequirement();
		voting_votes setValue (votesLeft);
		if (self.rampagevoted == 0)
		{
			voting_bg.color = ( 0, 0, 1 );
		}
		else if (self.rampagevoted == 1)
		{
			voting_bg.color = ( 0, 1, 0 );
		}
		
		if (level.rampagevoting == 0)
		{
			voting_target destroy();
			voting_bg destroy();
			voting_text destroy();
			voting_votes destroy();
		}
		wait 0.1;
	}
}

checkRampageVotingInput()
{
	level endon ("voting_finished");
	level endon ("voting_expired");
	
	while(level.rampagevoting == 1 && self.rampagevoted == 0)
	{
		if(self actionslotfourbuttonpressed() || (isDefined(self.bot)))
		{
			level.exfilplayervotes += 1;
			self.rampagevoted = 1;
			if (level.exfilplayervotes >= level.players.size)
			{
				level.votingsuccess = 1;
				level notify ("voting_finished");
			}
		}
		wait 0.1;
	}
}

rampageVoteTimer()
{
	level endon ("voting_finished");
	level endon ("voting_expired");
	level.votingtimer = 15;
	while(1)
	{
		level.votingtimer -= 1;
		if (level.votingtimer < 0)
		{
			level.rampageplayervotes = 0;
			foreach (player in get_players())
				player.rampagevoted = 0;
			level.rampagevoting = 0;
			level.votingsuccess = 0;
			level notify ("voting_expired");
		}
		wait 1;
	}
}

checkRampageIfPlayersVoted()
{
	level endon ("voting_finished");
	level endon ("voting_expired");
	while(1)
	{
		if (level.rampageplayervotes >= level.players.size)
		{
			level.votingsuccess = 1;
			level notify ("voting_finished");
		}
	}
	wait 0.1;
}

checkWeapon()
{
	if ( getDvar( "g_gametype" ) == "zgrief" || getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead grief
		{
			weapon = "blundergat";
		}
		else if(getDvar("mapname") == "zm_buried") //buried grief
		{
			weapon = "slowgun";
		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			weapon = "raygun_mark2";
		}
		else if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			weapon = "jetgun";
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{
			weapon = "blundergat";
		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			weapon = "slowgun";
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			weapon = "jetgun";
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			weapon = "staff";
		}
		else if(getDvar("mapname") == "zm_highrise") // Die Rise
		{
			weapon = "slipgun";
		}
	}
	
	if (issubstr(self getcurrentweapon(),weapon))
	{
		return false;
	}
	else
	{
		return true;
	}
}

LoopStaffModels()
{
	level waittill ("begin_staff_roll");
	level.staffmodel = spawn( "script_model", (level.effectlocation + (20,0,50)));
	level.staffmodel rotateTo((90,90,180),.1);
	
	if(getDvar("mapname") == "zm_tomb")
	{
		while(1)
		{		
			level.rolledstaff = randomintrange(1, 5);
			if (level.rolledstaff == 1)
			{
				model = ("t6_wpn_zmb_staff_crystal_fire_part");
			}
			else if (level.rolledstaff == 2)
			{
				model = ("t6_wpn_zmb_staff_crystal_air_part");
			}
			else if (level.rolledstaff == 3)
			{
				model = ("t6_wpn_zmb_staff_crystal_bolt_part");
			}
			else if (level.rolledstaff >= 4)
			{
				model = ("t6_wpn_zmb_staff_crystal_water_part");
			}
		
			level.staffmodel setmodel (model);
		
			wait 8;
		}
	}
	else if(getDvar("mapname") == "zm_highrise")
	{
		level.staffmodel setmodel ("t6_wpn_zmb_slipgun_world");
	}
	else if(getDvar("mapname") == "zm_transit")
	{
		level.staffmodel setmodel ("t6_wpn_zmb_jet_gun_world");
	}
	else if(getDvar("mapname") == "zm_prison")
	{
		level.staffmodel setmodel ("t6_wpn_zmb_blundergat_world");
	}
	else if(getDvar("mapname") == "zm_nuked")
	{
		level.staffmodel setmodel ("t6_wpn_zmb_raygun2_world");
	}
	else if(getDvar("mapname") == "zm_buried")
	{
		level.staffmodel setmodel ("t6_wpn_zmb_slowgun_world");
	}
}

getRewardWeapon()
{
	if ( getDvar( "g_gametype" ) == "zgrief" || getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead grief
		{
			weapon = "blundergat_zm";
		}
		else if(getDvar("mapname") == "zm_buried") //buried grief
		{
			weapon = "slowgun_zm";
		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			weapon = "raygun_mark2_zm";
		}
		else if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			weapon = "jetgun_zm";
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{
			weapon = "blundergat_zm";
		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			weapon = "slowgun_zm";
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			weapon = "jetgun_zm";
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			if (level.rolledstaff == 1)
			{
				weapon = "staff_fire_zm";
			}
			else if (level.rolledstaff == 2)
			{
				weapon = "staff_air_zm";
			}
			else if (level.rolledstaff == 3)
			{
				weapon = "staff_lightning_zm";
			}
			else if (level.rolledstaff >= 4)
			{
				weapon = "staff_water_zm";
			}
		}
		else if(getDvar("mapname") == "zm_highrise")
		{
			weapon = "slipgun_zm";
		}
	}
	return weapon;
}

spawnRewardTrigger()
{
	trigger = spawn( "trigger_radius", (level.effectlocation), 1, 50, 50 );
	level.staffmodel = spawn( "script_model", (level.effectlocation));
	while(1)
	{
		trigger waittill( "trigger", i );
		if ( i GetStance() == "prone" )
		{
			i.score += getDvarInt("bonuspoints_points");
			i playsound( "zmb_cha_ching" );
		}
	}
}

setStaffHintString()
{
	if(getDvar("mapname") == "zm_tomb")
	{
		if (level.rolledstaff == 1)
		{
			return "^1Fire Staff";
		}
		else if (level.rolledstaff == 2)
		{
			return "^3Wind Staff";
		}
		else if (level.rolledstaff == 3)
		{
			return "^6Lighting Staff";
		}
		else if (level.rolledstaff >= 4)
		{
			return "^5Ice Staff";
		}
	}
	else if(getDvar("mapname") == "zm_highrise")
	{
		return "^6Sliquifier";
	}
	else if(getDvar("mapname") == "zm_transit")
	{
		return "^9Jetgun";
	}
	else if(getDvar("mapname") == "zm_prison")
	{
		return "^2Blundergat";
	}
	else if(getDvar("mapname") == "zm_nuked")
	{
		return "^1Raygun Mk 2";
	}
	else if(getDvar("mapname") == "zm_buried")
	{
		return "^5Paralyzer";
	}
}


//////////////////////////////////
//
//	[Secret Music Survival Script]
//
//	Individual mod link: https://github.com/techboy04/MusicEESurvival-T6
//
//////////////////////////////////


init_secretmusic()
{
	precachemodel("zombie_teddybear");
	level thread setteddybears();
}

player_secretmusic()
{
    self.teddybears = 0;
}

spawnTeddyBear(x,y,z,angle)
{
	TeddyTrigger = spawn( "trigger_radius", ((x,y,z)), 1, 50, 50 );
	TeddyModel = spawn( "script_model", ((x,y,z)), 1, 50, 50 );
	TeddyModel setmodel("zombie_teddybear");
	TeddyModel rotateto((0,angle,0),.1);

	while(1)
	{
		TeddyTrigger waittill( "trigger", i );
		if ( i usebuttonpressed() )
		{
			i.teddybears += 1;
			i playsound( "zmb_meteor_activate" );
			
			if (i.teddybears == 3) 
			{
				i playsound("mus_zmb_secret_song");
			}
			
			break;
		}
	}
}

setteddybears()
{
	if ( getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			if(getDvar("ui_zm_mapstartlocation") == "town")
			{
				thread spawnTeddyBear(430,-570,-61,26);
				thread spawnTeddyBear(2312,579,-55,-137);
				thread spawnTeddyBear(699,-1387,128,-48);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "transit")
			{
				thread spawnTeddyBear(-7645,5377,-58,-177);
				thread spawnTeddyBear(-6656,4408,-63,-120);
				thread spawnTeddyBear(-6380,5625,-45,-132);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "farm")
			{
				thread spawnTeddyBear(8512,-5913,52,-134);
				thread spawnTeddyBear(8449,-5350,48,127);
				thread spawnTeddyBear(8125,-6730,117,19);
			}
		}
	}
}


//////////////////////////////////
//
//	[Transit Misc Script]
//
//////////////////////////////////


init_transitmisc()
{
	if (getDvarInt("enable_denizens") == 1)
		setDvar( "scr_screecher_ignore_player", 0 );
	else
		setDvar( "scr_screecher_ignore_player", 1 );

	level.skipstartcheck = 0;
//	include_weapon( "jetgun_zm", 1 );
//	replacefunc(maps/mp/zombies/_zm_weap_jetgun::handle_overheated_jetgun, ::handle_overheated_jetgun);
	level.explode_overheated_jetgun = true;
	level.unbuild_overheated_jetgun = false;
	level.take_overheated_jetgun = true;
}

player_transitmisc()
{

//	self maps/mp/zombies/_zm_equipment::equipment_give( "jetgun_zm" );
	self thread jetgun_unlimitedammo();
	self thread switch_jetgun_modes();
	
	if (getDvarInt("enable_fog") == 1)
	{
		self setClientDvar("r_fog", 1);
	}
	else
	{
		self setClientDvar("r_fog", 0);
	}
	
}

jetgun_unlimitedammo()
{
	while(1)
	{
		if(( self getcurrentweapon() == "jetgun_zm" ) && (self.jetgunmode == 0))
		{
//			self.jetgun_heatval = 0;
//			self.jetgun_overheating = 0;
			self setweaponoverheating( 0, 0 );
		}
		wait .1;
	}
}

switch_jetgun_modes()
{
	self notifyonplayercommand("togglejetgunmode", "+actionslot 3");
	self.jetgunmode = 0;
	for(;;)
	{
		self waittill("togglejetgunmode");
		self notify ("jetgun_overheated");
		
	}
}

handle_overheated_jetgun()
{
    self endon( "disconnect" );

    while ( true )
    {
        self waittill( "jetgun_overheated" );

        if ( self getcurrentweapon() == "jetgun_zm" )
        {
            if ( isdefined( level.explode_overheated_jetgun ) && level.explode_overheated_jetgun )
            {
                self thread maps\mp\zombies\_zm_equipment::equipment_release( "jetgun_zm" );
                weapon_org = self gettagorigin( "tag_weapon" );
                self.jetgun_overheating = undefined;
                self.jetgun_heatval = undefined;
                self playsound( "wpn_jetgun_explo" );
            }
            else if ( isdefined( level.unbuild_overheated_jetgun ) && level.unbuild_overheated_jetgun )
            {
                self thread maps\mp\zombies\_zm_equipment::equipment_release( "jetgun_zm" );
                maps\mp\zombies\_zm_buildables::unbuild_buildable( "jetgun_zm", 1 );
                self.jetgun_overheating = undefined;
                self.jetgun_heatval = undefined;
            }
            else if ( isdefined( level.take_overheated_jetgun ) && level.take_overheated_jetgun )
            {
                self thread maps\mp\zombies\_zm_equipment::equipment_release( "jetgun_zm" );
                self.jetgun_overheating = undefined;
                self.jetgun_heatval = undefined;
            }
        }
    }
}


//////////////////////////////////
//
//	[Transit Power Script]
//
//////////////////////////////////


init_transitpower()
{
//	replaceFunc( maps\mp\_zm_transit_utility::solo_tombstone_removal, ::solo_tombstone_removal_override );
	level thread transit_power_local_electric_doors_globally();
	
	if(getDvarInt("enable_lavadamage") == 0)
	{
		foreach( lava_pool in getentarray( "lava_damage", "targetname" ) )
    		lava_pool delete();
    }
}

player_transitpower()
{

}

transit_power_local_electric_doors_globally()
{
	if( !(is_classic() && level.scr_zm_map_start_location == "transit") )
	{
		return;	
	}

	local_power = [];

	for ( ;; )
	{
		flag_wait( "power_on" );

		zombie_doors = getentarray( "zombie_door", "targetname" );
		for ( i = 0; i < zombie_doors.size; i++ )
		{
			if ( isDefined( zombie_doors[i].script_noteworthy ) && zombie_doors[i].script_noteworthy == "local_electric_door" )
			{
				local_power[local_power.size] = maps\mp\zombies\_zm_power::add_local_power( zombie_doors[i].origin, 16 );
			}
		}

		flag_waitopen( "power_on" );

		for (i = 0; i < local_power.size; i++)
		{
			maps\mp\zombies\_zm_power::end_local_power( local_power[i] );
			local_power[i] = undefined;
		}
		local_power = [];
	}
}


//////////////////////////////////
//
//	[Transit Fast Travel Script]
//
//	Individual mod link: https://github.com/techboy04/Tranzit-Fast-Travel-T6Zombies
//
//////////////////////////////////


init_fasttravel()
{
	checkTransit();
}

player_fasttravel()
{

}

checkTransit()
{
	if( getDvar( "g_gametype" ) == "zclassic" && level.scr_zm_map_start_location == "transit" )
	{
		level thread spawnTranzitLadder();
		level thread createTriggers();
		level.activatefasttravel = 0;
	}
}


createTravel(location, destination, angle, whereto)
{
	travelTrigger = spawn( "trigger_radius", (location), 1, 50, 50 );
	travelTrigger setHintString("^7Something needs to be activated...");
	travelTrigger setcursorhint( "HINT_NOICON" );
	travelModel = spawn( "script_model", (location));
	travelModel setmodel ("p6_zm_screecher_hole");
	travelModel rotateTo(angle,.1);
	level waittill ("fasttravel_on");
	playfx( level._effect[ "screecher_vortex" ], (location), anglestoforward((0,45,55)));
	travelTrigger setHintString("^7Press ^3&&1 ^7to travel to ^3" + whereto + "^7 [Cost: " + getdvar("fasttravel_price") + "]");
	while(1)
	{
		travelTrigger waittill( "trigger", i );
		if (i.score >= getdvarInt("fasttravel_price"))
		{
		
			if (level.activatefasttravel == 1)
			{

				if ( i usebuttonpressed() )
				{
					i.score -= getdvarInt("fasttravel_price");
					i playsound( "zmb_weap_wall" );
					fadetowhite = newhudelem();
					fadetowhite.x = 0;
					fadetowhite.y = 0;
					fadetowhite.alpha = 0;
					fadetowhite.horzalign = "fullscreen";
					fadetowhite.vertalign = "fullscreen";
					fadetowhite.foreground = 1;
					fadetowhite setshader( "shellshock_flashed", 640, 480 );
					fadetowhite fadeovertime( 0.2 );
					fadetowhite.alpha = 0.8;
					i.ignoreme = 1;
					wait 2;
					
					i setorigin (destination);
					
					fadetowhite fadeovertime( 1 );
					fadetowhite.alpha = 0;
					
					wait 1.1;
					fadetowhite destroy();
					i.ignoreme = 0;
				}
			}
		}
	}
}

createTriggers()
{
	//Bus Depot Triggers
	level thread createTravel((-7424.21,4201.22,-63.5),(-5143.78,-7402.17,-69),(0,77,0),"Diner"); //To Diner
	level thread createTravel((-6073.19,4519.49,-54.216),(1992.76,-437.126,-61.875),(0,160,0),"Town"); //To Town
	
	//Diner Triggers
	level thread createTravel((-4145.74,-7440.28,-63.875),(6929.9,-5716.29,-59),(0,133,0),"Farm"); //To Farm
	level thread createTravel((-6235.26,-7147.53,-62.744),(-6764.35,5460.54,-55.875),(0,53,0),"Bus Depot"); //To Bus Depot
	
	//Farm Triggers
	level thread createTravel((6821.2,-5470.26,-67),(10889.5,7554.89,-588),(0,164,0),"Power Station"); //To Power
	level thread createTravel((6770.84,-5973.64,-64),(-5143.78,-7402.17,-69),(0,141,0),"Diner"); //To Diner
	
	//Power Triggers
	level thread createTravel((10745.1,7790.9,-585.129),(1992.76,-437.126,-61.875),(0,-90,0),"Town"); //To Town
	level thread createTravel((11310.6,7792.6,-545),(6929.9,-5716.29,-59),(0,-164,0),"Farm"); //To Farm
	
	//Town Triggers
	level thread createTravel((686.931,-732.29,-55.875),(-6764.35,5460.54,-55.875),(0,90,0),"Bus Depot"); //To Bus Depot
	level thread createTravel((1897.9,846.475,-55.2886),(10889.5,7554.89,-588),(0,177,0),"Power"); //To Power
	
	if (getDvarInt("fasttravel_activateonpower") == 1)
	{
		level waittill ("power_on");
		level notify ("fasttravel_on");
		level.activatefasttravel = 1;
		
		foreach (player in level.players)
		{
			player iprintln("Power on");
		}
	}
	else
	{
		level thread spawnTravelActivator(993.641,258.615,-39.875);
	}
}

spawnTravelActivator(x,y,z)
{
	travelActivatorTrigger = spawn( "trigger_radius", ( x,y,z ), 1, 50, 50 );
	travelActivatorTrigger setHintString("^7The power must be activated first!");
	travelActivatorTrigger setcursorhint( "HINT_NOICON" );
	level waittill ("power_on");
	travelActivatorTrigger setHintString("^7Press ^3&&1 ^7to activate Fast Travel phones");
	while(1)
	{
		travelActivatorTrigger waittill( "trigger", i );
		if ( i usebuttonpressed() )
		{
			i playsound( "zmb_weap_wall" );
			level notify ("fasttravel_on");
			level.activatefasttravel = 1;
			travelActivatorTrigger delete();
			break;
		}
	}
}


//////////////////////////////////
//
//	[Upgraded Perks]
//
//////////////////////////////////


init_upgradedperks()
{
	level.playerDamageStub = level.callbackplayerdamage; //damage callback for phd flopper
	level.callbackplayerdamage = ::phd_flopper_dmg_check; //more damage callback stuff. everybody do the flop
	//phd min explosion damage
	level.minPhdExplosionDamage = 1000;
	level.zombie_vars[ "zombie_perk_divetonuke_min_damage" ] = level.minPhdExplosionDamage;
	//phd max explosion damage
	level.maxPhdExplosionDamage = 5000;
	level.zombie_vars[ "zombie_perk_divetonuke_max_damage" ] = level.maxPhdExplosionDamage;
	//phd explosion radius
	level.phdDamageRadius = 300;
	level.zombie_vars[ "zombie_perk_divetonuke_radius" ] = level.phdDamageRadius;
	//enable custom phdflopper
	level.enablePHDFlopper = 1;
	level.zombie_vars[ "enablePHDFlopper" ] = level.enablePHDFlopper;
}

player_upgradedperks()
{
	self thread onPlayerDowned();
	self thread mulekick_save_weapons();
	self thread mulekick_restore_weapons();
	self thread doPHDdive();
	self thread checkPerk();
	self thread MulekickIcon();
}

onPlayerDowned()
{
	self endon("disconnect");
	level endon("end_game");
	
	for(;;)
	{
		self waittill_any( "player_downed", "fake_death", "entering_last_stand");
//		self.hasPHD = undefined; //resets the flopper variable
	}
}

doPHDdive() //credit to extinct. just edited to add self.hasPHD variable
{
	self endon("disconnect");
	level endon("end_game");
	
	for(;;)
	{
		if(isDefined(self.divetoprone) && self.divetoprone)
		{
			if(self isOnGround() && isDefined(self.hasPHD))
			{
				if(level.script == "zm_tomb" || level.script == "zm_buried")	
					explosionfx = level._effect["divetonuke_groundhit"];
				else
					explosionfx = loadfx("explosions/fx_default_explosion");
				self playSound("zmb_phdflop_explo");
				playfx(explosionfx, self.origin);
				self damageZombiesInRange(310, self, "kill");
				wait .3;
			}
		}
		wait .05;
	}
}

damageZombiesInRange(range, what, amount) //damage zombies for phd flopper
{
	enemy = getAiArray(level.zombie_team);
	foreach(zombie in enemy)
	{
		if(distance(zombie.origin, what.origin) < range)
		{
			if(amount == "kill")
				zombie doDamage(zombie.health * 2, zombie.origin, self);
			else
				zombie doDamage(amount, zombie.origin, self);
		}
	}
}

phd_flopper_dmg_check( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, timeoffset, boneindex ) //phdflopdmgchecker lmao
{
	if ( smeansofdeath == "MOD_SUICIDE" || smeansofdeath == "MOD_FALLING" || smeansofdeath == "MOD_PROJECTILE" || smeansofdeath == "MOD_PROJECTILE_SPLASH" || smeansofdeath == "MOD_GRENADE" || smeansofdeath == "MOD_GRENADE_SPLASH" || smeansofdeath == "MOD_EXPLOSIVE" )
	{
		if(isDefined(self.hasPHD)) //if player has phd flopper, dont damage the player
			return;
	}
	[[ level.playerDamageStub ]]( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, timeoffset, boneindex );
}

checkPerk()
{
	while(1)
	{
		self waittill_any("perk_acquired", "perk_lost");
		
		if (self hasPerk("specialty_scavenger") || self hasPerk("specialty_nomotionsensor") || self hasPerk("specialty_finalstand") || self hasPerk("specialty_deadshot"))
		{
			self.hasPHD = 1;
			if(self.initiatephdline == 0)
			{
				self.initiatephdline = 1;
				self thread sendsubtitletext(self.name, 1, "That tastes a bit explosive, that feeling is familiar.", 3);
			}
		}
		else
		{
			self.hasPHD = undefined;
			self.initiatephdline = 0;
		}
		
// Speed Cola makes weapon handling faster
		if (self hasPerk("specialty_fastreload"))
		{
			self setPerk("specialty_fastweaponswitch");
		}
		else if (!self hasPerk("specialty_fastreload"))
		{
			self unsetPerk("specialty_fastweaponswitch");
			self notify( "specialty_fastweaponswitch" + "_stop" );
		}
		
//Stamin up gives unlimited sprint
		if (self hasPerk("specialty_longersprint"))
		{
			self setPerk("specialty_unlimitedsprint");
		}
		else if (!self hasPerk("specialty_longersprint"))
		{
			self unsetPerk("specialty_unlimitedsprint");
			self notify( "specialty_unlimitedsprint" + "_stop" );
		}
		
//Double Tap allows you to quickly melee
		if (self hasPerk("specialty_rof"))
		{
			self setPerk(  "specialty_fastmeleerecovery");
		}
		else if (!self hasPerk("specialty_rof"))
		{
			self unsetPerk(  "specialty_fastmeleerecovery");
			self notify( "specialty_fastmeleerecovery" + "_stop" );
		}
//Give unlimited sprint if the player has all perks on Mob of the Dead and Nuketown
		if ((getDvar("mapname") == "zm_prison") || (getDvar("mapname") == "zm_nuked"))
		{
			if (checkMapperks())
			{
				self setPerk("specialty_unlimitedsprint");
			}
			else if (!checkMapperks())
			{
				self unsetPerk("specialty_unlimitedsprint");
				self notify( "specialty_unlimitedsprint" + "_stop" );
			}
		}
		
		wait 0.1;
	}
}

mulekick_save_weapons()
{
	level endon("end_game");
	self endon("disconnect");
	for (;;)
	{
		if (!self hasPerk("specialty_additionalprimaryweapon"))
		{
			self waittill("perk_acquired");
			wait 0.05;
		}

		if (self hasPerk("specialty_additionalprimaryweapon"))
		{
			primaries = self getweaponslistprimaries();
			if (primaries.size >= 3)
			{
				weapon = primaries[primaries.size - 1];
				self.a_saved_weapon = maps\mp\zombies\_zm_weapons::get_player_weapondata(self, weapon);
			}
			else
			{
				self.a_saved_weapon = undefined;
			}
		}

		wait 0.05;
	}
}

mulekick_restore_weapons()
{
	level endon("end_game");
	self endon("disconnect");
	for (;;)
	{
		self waittill("perk_acquired");

		if (isDefined(self.a_saved_weapon) && self hasPerk("specialty_additionalprimaryweapon"))
		{
			pap_triggers = getentarray( "specialty_weapupgrade", "script_noteworthy" );

			give_wep = 1;
			if ( isDefined( self ) && self maps\mp\zombies\_zm_weapons::has_weapon_or_upgrade( self.a_saved_weapon["name"] ) )
			{
				give_wep = 0;
			}
			else if ( !maps\mp\zombies\_zm_weapons::limited_weapon_below_quota( self.a_saved_weapon["name"], self, pap_triggers ) )
			{
				give_wep = 0;
			}
			else if ( !self maps\mp\zombies\_zm_weapons::player_can_use_content( self.a_saved_weapon["name"] ) )
			{
				give_wep = 0;
			}
			else if ( isDefined( level.custom_magic_box_selection_logic ) )
			{
				if ( !( [[ level.custom_magic_box_selection_logic ]]( self.a_saved_weapon["name"], self, pap_triggers ) ) )
				{
					give_wep = 0;
				}
			}
			else if ( isDefined( self ) && isDefined( level.special_weapon_magicbox_check ) )
			{
				give_wep = self [[ level.special_weapon_magicbox_check ]]( self.a_saved_weapon["name"] );
			}

			if (give_wep)
			{
				current_wep = self getCurrentWeapon();
				self maps\mp\zombies\_zm_weapons::weapondata_give(self.a_saved_weapon);
				self switchToWeapon(current_wep);
			}

			self.a_saved_weapon = undefined;
		}
	}
}

checkmapperks()
{
	if (getDvar("mapname") == "zm_prison")
	{
		if (self.num_perks == 5)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else if(getDvar("mapname") == "zm_nuked")
	{
		if(self.num_perk == 4)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}

MulekickIcon()
{
	self endon( "disconnect" );
	
	mulekickicon = newClientHudElem(self);
	mulekickicon.alignx = "right";
	mulekickicon.aligny = "bottom";
	mulekickicon.horzalign = "user_right";
	mulekickicon.vertalign = "user_bottom";
	mulekickicon.x -= 50;
	mulekickicon.y -= 75;
	mulekickicon.fontscale = 2;
	mulekickicon.alpha = 0;
	mulekickicon.color = ( 1, 1, 1 );
	mulekickicon.hidewheninmenu = 1;
//	mulekickicon.foreground = 1;
	mulekickicon setShader("specialty_additionalprimaryweapon_zombies", 24, 24);
	
	while(1)
	{
//        if (self hasPerk("specialty_additionalprimaryweapon"))
		if( isdefined( self GetWeaponsListPrimaries()[2] ) &&  self GetWeaponsListPrimaries()[2] ==  self GetCurrentWeapon() )
		{
			mulekickicon.alpha = 1;
		}
		else
		{
			mulekickicon.alpha = 0;
		}
        wait 0.5;
	}
}


//////////////////////////////////
//
//	[Useful Nuke]
//
//	Individual mod link: https://github.com/techboy04/Useful-Nuke-T6Zombies
//
//////////////////////////////////


init_usefulnuke()
{

}

player_usefulnuke()
{
	self thread calculateNuke();
}

calculateNuke()
{
    self endon("disconnect");
    level endon("game_end");
    for(;;) {
        self waittill("nuke_triggered");

    	self thread sendsubtitletext(chooseAnnouncer(), 1, "Kaboom!", 1.5);
        
        points = ((get_round_enemy_array().size + level.zombie_total) * getDvarInt("usefulnuke_points"));
        
        if (level.zombie_vars[self.team]["zombie_point_scalar"] != 1)
        {
        	points = points * 2;
        }
        
        for( i = 0; i < level.players.size; i++ )
        {
        	level.players[i].score += points;
        }
        wait 0.02;
    }
}


//////////////////////////////////
//
//	[Vanguard Perk HUD Animation]
//
//	Individual mod link: https://github.com/techboy04/Vanguard-Perk-HUD-Anims-T6Zombies
//
//////////////////////////////////


init_vghudanim()
{
	precacheshader("specialty_electric_cherry_zombie");
	precacheshader("specialty_chugabud_zombies");
}

player_vghudanim()
{

}

perkHUD(perk)
{
	level endon("end_game");
	self endon( "disconnect" );


    switch( perk ) {
    	case "specialty_armorvest":
        	shader = "specialty_juggernaut_zombies";
        	break;
    	case "specialty_quickrevive":
        	shader = "specialty_quickrevive_zombies";
        	break;
    	case "specialty_fastreload":
        	shader = "specialty_fastreload_zombies";
        	break;
    	case "specialty_rof":
        	shader = "specialty_doubletap_zombies";
        	break;  
    	case "specialty_longersprint":
        	shader = "specialty_marathon_zombies";
        	break; 
    	case "specialty_flakjacket":
        	shader = "specialty_divetonuke_zombies";
        	break;  
    	case "specialty_deadshot":
        	shader = "specialty_ads_zombies";
        	break;
    	case "specialty_additionalprimaryweapon":
        	shader = "specialty_additionalprimaryweapon_zombies";
        	break; 
		case "specialty_scavenger": 
			shader = "specialty_tombstone_zombies";
        	break; 
    	case "specialty_finalstand":
			shader = "specialty_chugabud_zombies";
        	break; 
    	case "specialty_nomotionsensor":
			shader = "specialty_vulture_zombies";
        	break; 
    	case "specialty_grenadepulldeath":
			shader = "specialty_electric_cherry_zombie";
        	break; 
    	default:
        	shader = "";
        	break;
    }


	perk_hud = newClientHudElem(self);
	perk_hud.alignx = "center";
	perk_hud.aligny = "middle";
	perk_hud.horzalign = "user_center";
	perk_hud.vertalign = "user_top";
	perk_hud.x += 0;
	perk_hud.y += 120;
	perk_hud.fontscale = 2;
	perk_hud.alpha = 1;
	perk_hud.color = ( 1, 1, 1 );
	perk_hud.hidewheninmenu = 1;
	perk_hud.foreground = 1;
	perk_hud setShader(shader, 128, 128);
	
	
	perk_hud moveOvertime( 0.25 );
    perk_hud fadeovertime( 0.25 );
    perk_hud scaleovertime( 0.25, 64, 64);
    perk_hud.alpha = 1;
    perk_hud.setscale = 2;
    wait 3.25;
    perk_hud moveOvertime( 1 );
    perk_hud fadeovertime( 1 );
    perk_hud.alpha = 0;
    perk_hud.setscale = 5;
    perk_hud scaleovertime( 1, 128, 128);
    wait 1;
    perk_hud notify( "death" );

    if ( isdefined( perk_hud ) )
        perk_hud destroy();
}


getPerkShader(perk)
{
	if(perk == "specialty_armorvest") //Juggernog
		return "Juggernog";
	if(perk == "specialty_rof") //Doubletap
		return "Double Tap";
	if(perk == "specialty_longersprint") //Stamin Up
		return "Stamin-Up";
	if(perk == "specialty_fastreload") //Speedcola
		return "Speed Cola";
	if(perk == "specialty_additionalprimaryweapon") //Mule Kick
		return "Mule Kick";
	if(perk == "specialty_quickrevive") //Quick Revive
		return "Quick Revive";
	if(perk == "specialty_finalstand") //Whos Who
		return "Who's Who";
	if(perk == "specialty_grenadepulldeath") //Electric Cherry
		return "Electric Cherry";
	if(perk == "specialty_flakjacket") //PHD Flopper
		return "PHD Flopper";
	if(perk == "specialty_deadshot") //Deadshot
		return "Deadshot Daiquiri";
	if(perk == "specialty_scavenger") //Tombstone
		return "Tombstone";
	if(perk == "specialty_nomotionsensor") //Vulture
		return "Vulture Aid";
}

give_perk_override( perk, bought )
{
    self setperk( perk );
    self.num_perks++;

    if ( isdefined( bought ) && bought )
    {
        self maps\mp\zombies\_zm_audio::playerexert( "burp" );

        if ( isdefined( level.remove_perk_vo_delay ) && level.remove_perk_vo_delay )
            self maps\mp\zombies\_zm_audio::perk_vox( perk );
        else
            self delay_thread( 1.5, maps\mp\zombies\_zm_audio::perk_vox, perk );

        self setblur( 4, 0.1 );
        wait 0.1;
        self setblur( 0, 0.1 );
        self notify( "perk_bought", perk );
    }

    self perk_set_max_health_if_jugg( perk, 1, 0 );

    if ( !( isdefined( level.disable_deadshot_clientfield ) && level.disable_deadshot_clientfield ) )
    {
        if ( perk == "specialty_deadshot" )
            self setclientfieldtoplayer( "deadshot_perk", 1 );
        else if ( perk == "specialty_deadshot_upgrade" )
            self setclientfieldtoplayer( "deadshot_perk", 1 );
    }

    if ( perk == "specialty_scavenger" )
        self.hasperkspecialtytombstone = 1;

    players = get_players();

    if ( use_solo_revive() && perk == "specialty_quickrevive" )
    {
        self.lives = 1;

        if ( !isdefined( level.solo_lives_given ) )
            level.solo_lives_given = 0;

        if ( isdefined( level.solo_game_free_player_quickrevive ) )
            level.solo_game_free_player_quickrevive = undefined;
        else
            level.solo_lives_given++;

        if ( level.solo_lives_given >= 3 )
            flag_set( "solo_revive" );

        self thread solo_revive_buy_trigger_move( perk );
    }

    if ( perk == "specialty_finalstand" )
    {
        self.lives = 1;
        self.hasperkspecialtychugabud = 1;
        self notify( "perk_chugabud_activated" );
    }

    if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].player_thread_give ) )
        self thread [[ level._custom_perks[perk].player_thread_give ]]();

    self set_perk_clientfield( perk, 1 );
    maps\mp\_demo::bookmark( "zm_player_perk", gettime(), self );
    self maps\mp\zombies\_zm_stats::increment_client_stat( "perks_drank" );
    self maps\mp\zombies\_zm_stats::increment_client_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( "perks_drank" );

    if ( !isdefined( self.perk_history ) )
        self.perk_history = [];

    self.perk_history = add_to_array( self.perk_history, perk, 0 );

    if ( !isdefined( self.perks_active ) )
        self.perks_active = [];

    self.perks_active[self.perks_active.size] = perk;
    self notify( "perk_acquired" );
    self thread perk_think( perk );
    if (getDvarInt("cinematic_mode") != 1)
    {
    	self perkHUD(perk);
    }
}


//////////////////////////////////
//
//	[Zone Notifier]
//
//	Individual mod link: https://github.com/techboy04/Area-Notifier-T6Zombies
//
//////////////////////////////////


init_zonenotifer()
{

}

player_zonenotifer()
{
	self thread zoneCheck();
}

zoneCheck()
{
	while(1)
	{
		if (self.currentzone != self get_zone_name())
		{
			self notify ("zone_change");
			if (isDefined(self.notifier_hudmsg))
    		{
    			self.notifier_hudmsg destroy();
    		}
			
			if (!issubstr(self get_zone_name(),"_"))
			{
				self.currentzone = self get_zone_name();
				if (getDvarInt("cinematic_mode") != 1)
				{
					grief_reset_message(self get_zone_name(), "");
				}
			}
		}
		
		wait 0.2;
	}
}

get_zone_name()
{
	zone = self get_player_zone();
	if (!isDefined(zone))
	{
		return "";
	}

	name = zone;

	if (level.script == "zm_transit")
	{
		if (zone == "zone_pri")
		{
			name = "Bus Depot";
		}
		else if (zone == "zone_pri2")
		{
			name = "Bus Depot";
		}
		else if (zone == "zone_station_ext")
		{
			name = "Bus Depot";
		}
		else if (zone == "zone_trans_2b")
		{
			name = "Bus Depot";
		}
		else if (zone == "zone_trans_2")
		{
			name = "Tunnel";
		}
		else if (zone == "zone_amb_tunnel")
		{
			name = "Tunnel";
		}
		else if (zone == "zone_trans_3")
		{
			name = "Tunnel";
		}
		else if (zone == "zone_roadside_west")
		{
			name = "Diner";
		}
		else if (zone == "zone_gas")
		{
			name = "Diner";
		}
		else if (zone == "zone_roadside_east")
		{
			name = "Diner";
		}
		else if (zone == "zone_trans_diner")
		{
			name = "Diner";
		}
		else if (zone == "zone_trans_diner2")
		{
			name = "Diner";
		}
		else if (zone == "zone_gar")
		{
			name = "Diner";
		}
		else if (zone == "zone_din")
		{
			name = "Diner";
		}
		else if (zone == "zone_diner_roof")
		{
			name = "Diner";
		}
		else if (zone == "zone_trans_4")
		{
			name = "Diner";
		}
		else if (zone == "zone_amb_forest")
		{
			name = "Forest";
		}
		else if (zone == "zone_trans_10")
		{
			name = "Church";
		}
		else if (zone == "zone_town_church")
		{
			name = "Church";
		}
		else if (zone == "zone_trans_5")
		{
			name = "Farm";
		}
		else if (zone == "zone_far")
		{
			name = "Farm";
		}
		else if (zone == "zone_far_ext")
		{
			name = "Farm";
		}
		else if (zone == "zone_brn")
		{
			name = "Farm";
		}
		else if (zone == "zone_farm_house")
		{
			name = "Farm";
		}
		else if (zone == "zone_trans_6")
		{
			name = "Farm";
		}
		else if (zone == "zone_cornfield_prototype")
		{
			name = "Nacht";
		}
		else if (zone == "zone_trans_pow_ext1")
		{
			name = "Power Station";
		}
		else if (zone == "zone_pow")
		{
			name = "Power Station";
		}
		else if (zone == "zone_prr")
		{
			name = "Power Station";
		}
		else if (zone == "zone_pcr")
		{
			name = "Power Station";
		}
		else if (zone == "zone_pow_warehouse")
		{
			name = "Power Station";
		}
		else if (zone == "zone_trans_8")
		{
			name = "Power Station";
		}
		else if (zone == "zone_amb_power2town")
		{
			name = "Cabin";
		}
		else if (zone == "zone_trans_9")
		{
			name = "Town";
		}
		else if (zone == "zone_town_north")
		{
			name = "Town";
		}
		else if (zone == "zone_tow")
		{
			name = "Town";
		}
		else if (zone == "zone_town_east")
		{
			name = "Town";
		}
		else if (zone == "zone_town_west")
		{
			name = "Town";
		}
		else if (zone == "zone_town_south")
		{
			name = "Town";
		}
		else if (zone == "zone_bar")
		{
			name = "Town";
		}
		else if (zone == "zone_town_barber")
		{
			name = "Town";
		}
		else if (zone == "zone_ban")
		{
			name = "Town";
		}
		else if (zone == "zone_ban_vault")
		{
			name = "Town";
		}
		else if (zone == "zone_tbu")
		{
			name = "Town";
		}
		else if (zone == "zone_trans_11")
		{
			name = "Town";
		}
		else if (zone == "zone_trans_1")
		{
			name = "Bus Depot";
		}
	}
	else if (level.script == "zm_nuked")
	{
		if (zone == "culdesac_yellow_zone")
		{
			name = "Yellow House";
		}
		else if (zone == "culdesac_green_zone")
		{
			name = "Green House";
		}
		else if (zone == "openhouse1_f1_zone")
		{
			name = "Green House";
		}
		else if (zone == "openhouse1_f2_zone")
		{
			name = "Green House";
		}
		else if (zone == "openhouse1_backyard_zone")
		{
			name = "Green House";
		}
		else if (zone == "openhouse2_f1_zone")
		{
			name = "Yellow House";
		}
		else if (zone == "openhouse2_f2_zone")
		{
			name = "Yellow House";
		}
		else if (zone == "openhouse2_backyard_zone")
		{
			name = "Yellow House";
		}
		else if (zone == "ammo_door_zone")
		{
			name = "Yellow House";
		}
	}
	else if (level.script == "zm_highrise")
	{
		if (zone == "zone_green_start")
		{
			name = "Green Highrise";
		}
		else if (zone == "zone_green_level1")
		{
			name = "Green Highrise";
		}
		else if (zone == "zone_green_level2a")
		{
			name = "Green Highrise";
		}
		else if (zone == "zone_green_level2b")
		{
			name = "Green Highrise";
		}
		else if (zone == "zone_green_level3a")
		{
			name = "Green Highrise";
		}
		else if (zone == "zone_green_level3b")
		{
			name = "Green Highrise";
		}
		else if (zone == "zone_green_level3c")
		{
			name = "Green Highrise";
		}
		else if (zone == "zone_green_level3d")
		{
			name = "Green Highrise";
		}
		else if (zone == "zone_orange_level1")
		{
			name = "Orange Highrise";
		}
		else if (zone == "zone_orange_level2")
		{
			name = "Orange Highrise";
		}
		else if (zone == "zone_orange_level3a")
		{
			name = "Orange Highrise";
		}
		else if (zone == "zone_orange_level3b")
		{
			name = "Orange Highrise";
		}
		else if (zone == "zone_blue_level5")
		{
			name = "Blue Highrise";
		}
		else if (zone == "zone_blue_level4a")
		{
			name = "Blue Highrise";
		}
		else if (zone == "zone_blue_level4b")
		{
			name = "Blue Highrise";
		}
		else if (zone == "zone_blue_level4c")
		{
			name = "Blue Highrise";
		}
		else if (zone == "zone_blue_level2a")
		{
			name = "Blue Highrise";
		}
		else if (zone == "zone_blue_level2b")
		{
			name = "Blue Highrise";
		}
		else if (zone == "zone_blue_level2c")
		{
			name = "Blue Highrise";
		}
		else if (zone == "zone_blue_level2d")
		{
			name = "Blue Highrise";
		}
		else if (zone == "zone_blue_level1a")
		{
			name = "Blue Highrise";
		}
		else if (zone == "zone_blue_level1b")
		{
			name = "Blue Highrise";
		}
		else if (zone == "zone_blue_level1c")
		{
			name = "Blue Highrise";
		}
	}
	else if (level.script == "zm_prison")
	{
		if (zone == "zone_library")
		{
			name = "Library";
		}
		else if (zone == "zone_cellblock_west")
		{
			name = "Cellblock";
		}
		else if (zone == "zone_cellblock_west_gondola")
		{
			name = "Cellblock";
		}
		else if (zone == "zone_cellblock_west_gondola_dock")
		{
			name = "Cellblock";
		}
		else if (zone == "zone_cellblock_west_barber")
		{
			name = "Cellblock";
		}
		else if (zone == "zone_cellblock_east")
		{
			name = "Cellblock";
		}
		else if (zone == "zone_cafeteria")
		{
			name = "Cafeteria";
		}
		else if (zone == "zone_cafeteria_end")
		{
			name = "Cafeteria";
		}
		else if (zone == "zone_infirmary")
		{
			name = "Infirmary";
		}
		else if (zone == "zone_infirmary_roof")
		{
			name = "Infirmary";
		}
		else if (zone == "zone_roof_infirmary")
		{
			name = "Roof";
		}
		else if (zone == "zone_roof")
		{
			name = "Roof";
		}
		else if (zone == "zone_cellblock_west_warden")
		{
			name = "Cellblock";
		}
		else if (zone == "zone_warden_office")
		{
			name = "Warden's Office";
		}
		else if (zone == "cellblock_shower")
		{
			name = "Cellblock";
		}
		else if (zone == "zone_citadel_shower")
		{
			name = "Cellblock";
		}
		else if (zone == "zone_citadel")
		{
			name = "Citadel";
		}
		else if (zone == "zone_citadel_warden")
		{
			name = "Citadel";
		}
		else if (zone == "zone_citadel_stairs")
		{
			name = "Citadel";
		}
		else if (zone == "zone_citadel_basement")
		{
			name = "Citadel";
		}
		else if (zone == "zone_dock")
		{
			name = "Docks";
		}
		else if (zone == "zone_dock_puzzle")
		{
			name = "Docks";
		}
		else if (zone == "zone_dock_gondola")
		{
			name = "Docks";
		}
		else if (zone == "zone_golden_gate_bridge")
		{
			name = "Golden Gate Bridge";
		}
	}
	else if (level.script == "zm_buried")
	{
		if (zone == "zone_start")
		{
			name = "Processing";
		}
		else if (zone == "zone_start_lower")
		{
			name = "Processing";
		}
		else if (zone == "zone_tunnels_center")
		{
			name = "Tunnels";
		}
		else if (zone == "zone_tunnels_north")
		{
			name = "Tunnels";
		}
		else if (zone == "zone_tunnels_north2")
		{
			name = "Tunnels";
		}
		else if (zone == "zone_tunnels_south")
		{
			name = "Tunnels";
		}
		else if (zone == "zone_tunnels_south2")
		{
			name = "Tunnels";
		}
		else if (zone == "zone_tunnels_south3")
		{
			name = "Tunnels";
		}
		else if (zone == "zone_street_lightwest")
		{
			name = "Underground";
		}
		else if (zone == "zone_street_lightwest_alley")
		{
			name = "Underground";
		}
		else if (zone == "zone_morgue_upstairs")
		{
			name = "Underground";
		}
		else if (zone == "zone_stables")
		{
			name = "Underground";
		}
		else if (zone == "zone_street_darkwest")
		{
			name = "Underground";
		}
		else if (zone == "zone_street_darkwest_nook")
		{
			name = "Underground";
		}
		else if (zone == "zone_gun_store")
		{
			name = "Underground";
		}
		else if (zone == "zone_bank")
		{
			name = "Underground";
		}
		else if (zone == "zone_tunnel_gun2stables")
		{
			name = "Underground";
		}
		else if (zone == "zone_tunnel_gun2stables2")
		{
			name = "Underground";
		}
		else if (zone == "zone_street_darkeast")
		{
			name = "Underground";
		}
		else if (zone == "zone_street_darkeast_nook")
		{
			name = "Underground";
		}
		else if (zone == "zone_underground_bar")
		{
			name = "Underground";
		}
		else if (zone == "zone_tunnel_gun2saloon")
		{
			name = "Underground";
		}
		else if (zone == "zone_toy_store")
		{
			name = "Underground";
		}
		else if (zone == "zone_toy_store_floor2")
		{
			name = "Underground";
		}
		else if (zone == "zone_toy_store_tunnel")
		{
			name = "Underground";
		}
		else if (zone == "zone_candy_store")
		{
			name = "Underground";
		}
		else if (zone == "zone_candy_store_floor2")
		{
			name = "Underground";
		}
		else if (zone == "zone_street_lighteast")
		{
			name = "Underground";
		}
		else if (zone == "zone_underground_courthouse")
		{
			name = "Underground";
		}
		else if (zone == "zone_underground_courthouse2")
		{
			name = "Underground";
		}
		else if (zone == "zone_street_fountain")
		{
			name = "Underground";
		}
		else if (zone == "zone_church_graveyard")
		{
			name = "Underground";
		}
		else if (zone == "zone_church_main")
		{
			name = "Underground";
		}
		else if (zone == "zone_church_upstairs")
		{
			name = "Underground";
		}
		else if (zone == "zone_mansion_lawn")
		{
			name = "Mansion";
		}
		else if (zone == "zone_mansion")
		{
			name = "Mansion";
		}
		else if (zone == "zone_mansion_backyard")
		{
			name = "Mansion";
		}
		else if (zone == "zone_maze")
		{
			name = "Mansion";
		}
		else if (zone == "zone_maze_staircase")
		{
			name = "Mansion";
		}
	}
	else if (level.script == "zm_tomb")
	{
		if (isDefined(self.teleporting) && self.teleporting)
		{
			return "";
		}

		if (zone == "zone_start")
		{
			name = "Laboratory";
		}
		else if (zone == "zone_start_a")
		{
			name = "Laboratory";
		}
		else if (zone == "zone_start_b")
		{
			name = "Laboratory";
		}
		else if (zone == "zone_bunker_1a")
		{
			name = "Bunker";
		}
		else if (zone == "zone_fire_stairs")
		{
			name = "Fire Tunnel";
		}
		else if (zone == "zone_bunker_1")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_3a")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_3b")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_2a")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_2")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_4a")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_4b")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_4c")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_4d")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_tank_c")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_tank_c1")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_4e")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_tank_d")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_tank_d1")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_4f")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_5a")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_5b")
		{
			name = "Bunker";
		}
		else if (zone == "zone_nml_2a")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_2")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_bunker_tank_e")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_tank_e1")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_tank_e2")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_tank_f")
		{
			name = "Bunker";
		}
		else if (zone == "zone_nml_1")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_4")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_0")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_5")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_farm")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_celllar")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_3")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_2b")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_6")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_8")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_10a")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_10")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_7")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_bunker_tank_a")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_bunker_tank_a1")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_tank_a2")
		{
			name = "Bunker";
		}
		else if (zone == "zone_bunker_tank_b")
		{
			name = "Bunker";
		}
		else if (zone == "zone_nml_9")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_11")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_12")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_16")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_17")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_18")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_19")
		{
			name = "No Man's Land";
		}
		else if (zone == "ug_bottom_zone")
		{
			name = "Excavation Site";
		}
		else if (zone == "zone_nml_13")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_14")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_nml_15")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_village_0")
		{
			name = "Village";
		}
		else if (zone == "zone_village_5")
		{
			name = "Village";
		}
		else if (zone == "zone_village_5a")
		{
			name = "Village";
		}
		else if (zone == "zone_village_5b")
		{
			name = "Village";
		}
		else if (zone == "zone_village_1")
		{
			name = "Village";
		}
		else if (zone == "zone_village_4b")
		{
			name = "Village";
		}
		else if (zone == "zone_village_4a")
		{
			name = "Village";
		}
		else if (zone == "zone_village_4")
		{
			name = "Village";
		}
		else if (zone == "zone_village_2")
		{
			name = "Village";
		}
		else if (zone == "zone_village_3")
		{
			name = "Village";
		}
		else if (zone == "zone_village_3a")
		{
			name = "Village";
		}
		else if (zone == "zone_bunker_6")
		{
			name = "Bunker";
		}
		else if (zone == "zone_nml_20")
		{
			name = "No Man's Land";
		}
		else if (zone == "zone_village_6")
		{
			name = "Village";
		}
		else if (zone == "zone_chamber_0")
		{
			name = "The Crazy Place";
		}
		else if (zone == "zone_chamber_1")
		{
			name = "The Crazy Place";
		}
		else if (zone == "zone_chamber_2")
		{
			name = "The Crazy Place";
		}
		else if (zone == "zone_chamber_3")
		{
			name = "The Crazy Place";
		}
		else if (zone == "zone_chamber_4")
		{
			name = "The Crazy Place";
		}
		else if (zone == "zone_chamber_5")
		{
			name = "The Crazy Place";
		}
		else if (zone == "zone_chamber_6")
		{
			name = "The Crazy Place";
		}
		else if (zone == "zone_chamber_7")
		{
			name = "The Crazy Place";
		}
		else if (zone == "zone_chamber_8")
		{
			name = "The Crazy Place";
		}
		else if (zone == "zone_robot_head")
		{
			name = "Robot's Head";
		}
	}

	return name;
}

grief_reset_message(setmsg, sound)
{
    msg = setmsg;

    if ( isdefined( level.hostmigrationtimer ) )
    {
        while ( isdefined( level.hostmigrationtimer ) )
            wait 0.05;

        wait 4;
    }

	self thread show_grief_hud_msg( msg );
    self playsound(sound);

//    player playsound("zmb_cha_ching");
//    player playsound("vox_plr_0_exert_laugh");
}

show_grief_hud_msg( msg, msg_parm, offset, cleanup_end_game )
{
    self endon( "disconnect" );
    self endon( "zone_change" );

    while ( isdefined( level.hostmigrationtimer ) )
        wait 0.05;

    self.notifier_hudmsg = newClientHudElem(self);
    self.notifier_hudmsg.alignx = "center";
    self.notifier_hudmsg.aligny = "middle";
    self.notifier_hudmsg.horzalign = "center";
    self.notifier_hudmsg.vertalign = "middle";
    self.notifier_hudmsg.y -= 100;
//notifier_hudmsg.y -= 130;

    if ( self issplitscreen() )
        self.notifier_hudmsg.y += 70;

    if ( isdefined( offset ) )
        self.notifier_hudmsg.y += offset;

    self.notifier_hudmsg.foreground = 1;
    self.notifier_hudmsg.fontscale = 5;
    self.notifier_hudmsg.alpha = 0;
    self.notifier_hudmsg.color = ( 1, 1, 1 );
    self.notifier_hudmsg.hidewheninmenu = 1;
    self.notifier_hudmsg.font = "default";

    if ( isdefined( cleanup_end_game ) && cleanup_end_game )
    {
        level endon( "end_game" );
        self.notifier_hudmsg thread show_grief_hud_msg_cleanup();
    }

    if ( isdefined( msg_parm ) )
        self.notifier_hudmsg settext( msg, msg_parm );
    else
        self.notifier_hudmsg settext( msg );

	self.notifier_hudmsg changefontscaleovertime( 1.25);
    self.notifier_hudmsg fadeovertime( 1 );
    self.notifier_hudmsg.alpha = 1;
    self.notifier_hudmsg.fontscale = 2;
    wait 3.25;
    self.notifier_hudmsg changefontscaleovertime( 1.25 );
    self.notifier_hudmsg fadeovertime( 1 );
    self.notifier_hudmsg.alpha = 0;
    self.notifier_hudmsg.fontscale = 2;
    wait 1;
    self.notifier_hudmsg notify( "death" );

    self.notifier_hudmsg destroy();
}

show_grief_hud_msg_cleanup()
{
    self endon( "death" );

    level waittill( "end_game" );

    if ( isdefined( self ) )
        self destroy();
}


//////////////////////////////////
//
//	[Commands]
//
//	Individual mod link: []
//
//////////////////////////////////


command_thread()
{
	level endon( "end_game" );
	while ( true )
	{
		level waittill( "say", message, player, isHidden );
		args = strTok( message, " " );
		command = args[ 0 ];
		switch ( command )
		{
			case ".p":
			case ".patch":
			case ".patchnotes":
			case ".case":
			 	player patchnotes_text();
//				player iprintln("Used patchnotes command");
				break;
			case ".mods":
			case ".modlist":
			case ".ml":
			case ".modslist":
				player modslist_text();
				break;
			case ".configs":
			case ".config":
			case ".settings":
			case ".setting":
				player settings_text();
				break;
			case ".about":
				player about_text();
				break;
			case ".help":
				player help_text();
				break;
			case ".info":
				if(isDefined(args[ 1 ]))
				{
					mod = args[ 1 ];
					player about_mods(mod);
				}
				else
				{
					player iPrintLn("^7Usage ^5.info [Mod ID]\n^7Use ^5list ^7as the ID to see a list.");
				}
				break;
			case ".credits":
				player iPrintLn("^6Thanks to the Plutonium community for helping with portions of the mod!\n^2Special thanks to:\n^1Resxt, Bandit, afluffyofox, hinder, ZECxR3ap3r, Jezuz, and 2 Millimeter");
				break;
//			case ".forceexfil":
//				level force_exfil();
//				break;
//			case ".restartround":
//				level restart_round();
//				new_round_think(true);
//				break;
//			case ".infectme":
//				player force_infection();
//				break;
//			case ".cureme":
//				player force_cure();
//				break;
			default:
				break;
		}
	}
}

patchnotes_text()
{
	self iprintln("^5Your Version: ^22.7 - 8.21.2024");
}

modslist_text()
{
	self iPrintLn("^5Active Mods");
	wait 1;
	for( i = 0; i < level.modlist.size; i++ )
	{
		self iPrintLn("^3" + level.modlist[i]);
		wait 1;
	}
}

settings_text()
{
	self iPrintLn("^5Settings:");
	wait 1;
	self iPrintLn("^2Perk Limit:^5 " + getDvar("perk_limit"));
	wait 1;
	self iPrintLn("^2Rampage Max Round:^5 " + getDvar("rampage_max_round"));
	wait 1;
	self iPrintLn("^2Useful Nuke Points:^5 " + getDvar("usefulnuke_points"));
	wait 1;
	self iPrintLn("^2Bonus Points:^5 " + getDvar("bonuspoints_points"));
	wait 1;
	self iPrintLn("^2Fast Travel:^5 " + getDvar("fasttravel_price"));
	wait 1;
	self iPrintLn("^2Fast Travel Need Power:^5 " + getDvar("fasttravel_activateonpower"));
	wait 1;
	self iPrintLn("^2Infected Start Round:^5 " + getDvar("infected_start_round"));
	wait 1;
	self iPrintLn("^2Infected Chance:^5 " + getDvar("infected_infect_chance"));
	wait 1;
	self iPrintLn("^2Infected Timer:^5 " + getDvar("infected_infect_timer"));
	wait 1;
	self iPrintLn("^2Infected Decrease Amount:^5 " + getDvar("infected_infect_decrease"));
	wait 1;
	self iPrintLn("^2Infected Cure Skull Price:^5 " + getDvar("infected_cure_price"));
	wait 1;
	self iPrintLn("^2Hide HUD:^5 " + getDvar("hide_HUD"));
}

about_text()
{
	self iPrintLn("^5TechnoOps is a mod developed by TechWave");
	wait 1;
	self iPrintLn("^5The mod contains all of Techs mods along with some additional ones");
	wait 1;
	self iPrintLn("^5This mod is inspired by Reapers Collection on Black Ops III");
	wait 1;
	self iPrintLn("^5More information: ^2techsgames.xyz/technoopscollection");
}

about_mods(mod)
{
	switch ( mod )
	{
		case "rampage":
			self iPrintLn("^5Rampage Statue");
			self iPrintLn("Within the first 5 rounds, have zombies sprint with no spawn delays\nAfter a certain amount of Rounds you get a free reward.");
			break;
		case "compass":
			self iPrintLn("^5Compass");
			self iPrintLn("Show the selfs direction, angle, and location.");
			break;
		case "zonenotifier":
			self iPrintLn("^5Zone Notifier");
			self iPrintLn("Show the zone you entered in.");
			break;
		case "bonuspoints":
			self iPrintLn("^5Bonus Points");
			self iPrintLn("When proning near the perk machines, you'll get some bonus points.");
			break;
		case "usefulnuke":
			self iPrintLn("^5Useful Nuke");
			self iPrintLn("Get points by the amount of zombies currently spawned.");
			break;
		case "bo4ammo":
			self iPrintLn("^5Bo4 Ammo");
			self iPrintLn("Get a full clip along with a full magazine.");
			break;
		case "transitpower":
			self iPrintLn("^5Tranzit Power");
			self iPrintLn("Power required doors will open upon turning the power on.");
			break;
		case "exfil":
			self iPrintLn("^5Exfil");
			self iPrintLn("Every 5 rounds after Round 10, players can end the game early.");
			break;
		case "fasttravel":
			self iPrintLn("^5Tranzit Fast Travel");
			self iPrintLn("Be able to fast travel across Tranzit.");
			break;
		case "vghudanim":
			self iPrintLn("^5Vanguard Perk HUD Animation");
			self iPrintLn("Show the perk icon as a HUD whenever you get a perk.");
			break;
		case "secretmusic":
			self iPrintLn("^5Secret Music on Survival Maps");
			self iPrintLn("Teddy bear Secret Song is implemented in Survival maps.");
			break;
		case "instantpap":
			self iPrintLn("^5Instant PAP");
			self iPrintLn("Remove the need to place and grab the gun from Pack A Punch.");
			break;
		case "globalatm":
			self iPrintLn("^5Global ATM");
			self iPrintLn("An ATM where players can share points amongst each other.");
			break;
		case "enemycounter":
			self iPrintLn("^5Enemy Counter");
			self iPrintLn("Display an Enemy Counter.");
			break;
		case "healthbar":
			self iPrintLn("^5Health and Shield Bar");
			self iPrintLn("Display your Health and Shield health.");
			break;
		case "hitmarker":
			self iPrintLn("^5Hitmarker");
			self iPrintLn("Have a hitmarker everytime you hit a zombie.");
			break;
		case "upgradedperks":
			self iPrintLn("^5Upgraded Perks");
			self iPrintLn("Some perks have extra functionality.");
			break;
		case "starter":
			self iPrintLn("^5Starter Gun Animation");
			self iPrintLn("Play a gun animation upon respawning.");
			break;
		case "earlyspawn":
			self iPrintLn("^5Early Spawn");
			self iPrintLn("Respawn when there are fewer zombies left.");
			break;
		case "directorscut":
			self iPrintLn("^5Directors Cut");
			self iPrintLn("Get 250k, all perks, and a pack a punched gun on start.");
			break;
		case "infected":
			self iPrintLn("^5Infected");
			self iPrintLn("Chance of getting infected. Based off of Advanced Warfare Zombies' Infected zombie type mechanic.");
			break;
		case "solotomb":
			self iPrintLn("^5Solo Tombstone");
			self iPrintLn("Added Tombstone in solo, this has no effect unless Upgraded Perks are enabled");
			break;
		case "grabbablestarter":
			self iPrintLn("^5Grabbable Starter");
			self iPrintLn("Let players manually pick up the starter weapon. Not compatiable with Starter Animation.");
			break;
		case "list":
			self thread modid_list();
			break;
		default:
			break;
	}
}

modid_list()
{
	self iPrintLn("^5Usage: .info [Mod ID]");
	wait 1;
	self iPrintLn("^5[Mod Name] - [Mod ID]");
	wait 1;
	for( i = 0; i < level.modids.size; i++ )
	{
		self iPrintLn("^3"+ level.modlist[i] + "^7 - ^5" + level.modids[i]);
		wait 1;
	}
}

help_text()
{
	self iPrintLn("^5Commands:");
	wait 1;
	self iPrintLn("^2.help ^7- ^5List of Commands");
	wait 1;
	self iPrintLn("^2.pathnotes ^7- ^5See the mods patch notes");
	wait 1;
	self iPrintLn("^2.settings ^7- ^5Show the values from other config options");
	wait 1;
	self iPrintLn("^2.about ^7- ^5Information about the mod");
	wait 1;
	self iPrintLn("^2.info ^7- ^5Information about certain features");
	wait 1;
	self iPrintLn("^2.modlist ^7- ^5Show the list of currently enabled mods");
	wait 1;
	self iPrintLn("^2.credits ^7- ^5View the credits of the mod");
}


force_exfil()
{
	if (level.canexfil != 1)
	{
		level notify ("can_exfil");
	}
}

restart_round()
{
	level.zombie_total = 0;
	level notify ("restart_round");
}

force_cure()
{
	self.isinfected = 0;
}

force_infection()
{
	self.isinfected = 1;
}

//////////////////////////////////
//
//	[Infected Script]
//
//////////////////////////////////

init_infected()
{
	level thread setCureLocation();
	level thread infectionSpread();
}

player_infected()
{
	self.isinfected = 0;
	self thread InfectedHud();
	self thread BloodInfectHUD();
	self thread playerdamagecheck();
	self thread InfectionCountdown();
	self thread createcureicon(level.curestationloc);
	self thread createplayerinfecticon();
}

spawnCurePlatform(x,y,z)
{
	level.curestationloc = (x,y,z);
	
	cureModel = spawn( "script_model", ( x,y,z+40), 1, 100, 100 ); //defaultvehicle
	cureModel setModel ("zombie_skull");
	
	
	cureTrigger = spawn( "trigger_radius", ( x,y,z ), 1, 100, 100 ); //defaultvehicle
	cureTrigger setHintString("^7The power must be activated first!");
	cureTrigger setcursorhint( "HINT_NOICON" );
	if(getDvar("mapname") != "zm_tomb" && getDvar("mapname") != "zm_prison")
	{
		level waittill ("power_on");
	}
	cureTrigger setHintString("^7Press ^3&&1 ^7to cure from infection" + "^7 [Cost: " + getDvarInt("infected_cure_price") + "]");
	while(1)
	{
		cureTrigger waittill( "trigger", i );
		if ( i usebuttonpressed() && i.isinfected == 1 && i.score >= getDvarInt("infected_cure_price"))
		{
			i.score -= getDvarInt("infected_cure_price");
			i thread cure_player();
			i playsound( "zmb_weap_wall" );
		}
	}
}

playerdamagecheck()
{
	while (true)
	{
		self waittill( "damage", amount, attacker, dir, point, mod );
		
		if (attacker maps\mp\animscripts\zm_utility::is_zombie())
		{
			
			chance = randomintrange(1, 100);
			
			if((chance <= getDvarInt("infected_infect_chance")) && (getDvarInt("infected_start_round") <= level.round_number))
			{
				if(self.isinfected == 0)
				{
					self.isinfected = 1;
					self thread infect();
				}
				else
				{
					self.infecttimer -= getDvarInt("infected_infect_decrease");
				}
			}
		}
	}
}

InfectedHud()
{
	level endon("end_game");
	self endon( "disconnect" );

	infected_hud = newClientHudElem(self);
	infected_hud.alignx = "center";
	infected_hud.aligny = "top";
	infected_hud.horzalign = "user_center";
//	infected_hud.vertalign = "user_top";
	infected_hud.x = 0;
	infected_hud.y += 50;
	infected_hud.fontscale = 2;
	infected_hud.alpha = 1;
	infected_hud.color = ( 0, 1, 0 );
	infected_hud.hidewheninmenu = 1;
	infected_hud.foreground = 1;
	infected_hud.label = &"Infected! Find a cure skull! - ";

	while(1)
	{
		if (isDefined(self.infecttimer))
		{
			infected_hud setValue (self.infecttimer);
		}
		
		if(self.isinfected == 1)
		{
			infected_hud.alpha = 1;
		}
		else
		{
			infected_hud.alpha = 0;
		}
		
		wait 0.05;
	}
}

createcureIcon(x,y,z)
{
	cure_icon = newClientHudElem(self);
	cure_icon.alpha = 0;
	cure_icon.color = (0,1,0);
    cure_icon.archived = 0;
    cure_icon setshader( "specialty_instakill_zombies", 8, 8 );
    cure_icon setwaypoint( 1 );
    
    while(1)
    {
    	
		cure_icon.x = level.curestationloc[0];
		cure_icon.y = level.curestationloc[1];
		cure_icon.z = level.curestationloc[2] + 80;
    	
    	if (self.isinfected == 1)
    	{
    		cure_icon.alpha = 1;
    	}
    	else if (self.isinfected == 0)
    	{
    		cure_icon.alpha = 0;
    	}
    	wait 0.1;
    }
}

createplayerinfecticon()
{
	level endon("end_game");
	self endon( "disconnect" );
	
	infection_icon = newHudElem();
	infection_icon.alpha = 0;
	infection_icon.color = (0,1,0);
    infection_icon.archived = 0;
    infection_icon setshader( "specialty_instakill_zombies", 8, 8 );
    infection_icon setwaypoint( 1 );
    
    while(1)
    {
    	
		infection_icon.x = self.origin[0];
		infection_icon.y = self.origin[1];
		infection_icon.z = self.origin[2] + 80;
    	
    	if (self.isinfected == 1)
    	{
    		infection_icon.alpha = 1;
    	}
    	else if (self.isinfected == 0)
    	{
    		infection_icon.alpha = 0;
    	}
    	wait 0.1;
    }
}


ifDownedWhileInfected()
{
	self endon ("player_cured");
	self waittill_any_return("fake_death", "death", "player_downed");
	self.isinfected = 0;
}

cure_player()
{
	self notify ("player_cured");
	self setblur( 3, 0.1 );
	self.isinfected = 0;
	self.ignoreme = true;
	wait 1;
	self setblur( 0, 1 );
	wait 5;
	self.ignoreme = false;
}

infect()
{
	self.isinfected = 1;
	self.infecttimer = getDvarInt("infected_infect_timer");
	self thread ifDownedWhileInfected();
	
	self setblur( 3, 0.1 );
	wait 0.2;
	self setblur( 0, 1 );
}

setCureLocation()
{
	if ( getDvar( "g_gametype" ) == "zgrief" || getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead grief
		{
			spawnCurePlatform(2737,9270,1337);
		}
		else if(getDvar("mapname") == "zm_buried") //buried grief
		{
			spawnCurePlatform(1010,309,-8);
		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			spawnCurePlatform(530,912,-96);
		}
		else if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			if(getDvar("ui_zm_mapstartlocation") == "town") //town
			{
				spawnCurePlatform(1949,900,-58);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "transit") //busdepot
			{
				spawnCurePlatform(-5924,4746,-59);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "farm") //farm
			{
				spawnCurePlatform(7876,-5738,9);
			}
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{
			spawnCurePlatform(2737,9270,1337);
		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			spawnCurePlatform(1010,309,-8);
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			spawnCurePlatform(1054,-217,-304);
			
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			spawnCurePlatform(0,8,-750);
		}
		else if(getDvar("mapname") == "zm_highrise")
		{
			spawnCurePlatform(2925,120,1297);
		}
	}
}

InfectionCountdown()
{
	while(1)
	{
		if(self.isinfected == 1)
		{
			if(self.infecttimer <= 0)
			{
				self.isinfected = 0;
				self dodamage(self.health, self.origin);
			}
			self.infecttimer -= 1;
		}
		
		wait 1;
	}
}

BloodInfectHUD()
{
	level endon("end_game");
	self endon( "disconnect" );

	infectionbloodHUD = newClientHudElem(self);
	infectionbloodHUD.x = 0;
	infectionbloodHUD.y = 0;
	infectionbloodHUD.horzalign = "fullscreen";
	infectionbloodHUD.vertalign = "fullscreen";
	infectionbloodHUD.background = 1;
	infectionbloodHUD setshader( "white", 640, 480 );
	infectionbloodHUD.color = (0,1,0);
	infectionbloodHUD.alpha = 0.1;
	
	while(1)
	{
		if (self.isinfected == 1)
		{
			infectionbloodHUD.alpha = 0.1;
		}
		else
		{
			infectionbloodHUD.alpha = 0;
		}
		
		wait 0.1;
	}
}

infectionSpread()
{
	while(1)
	{
		if (getDvarInt("infected_start_round") == level.round_number)
		{
			foreach ( player in get_players() )
				player sendsubtitletext(chooseAnnouncer(), 1, "The Element 115 in you has caused you to be vulnerable to infection! Be careful!", 5);
			break;
		}
		else
		{
			wait 0.1;
		}
	}
}

// Remove Round Limit probably

new_round_think( restart )
{
    if ( !isdefined( restart ) )
        restart = 0;

/#
    println( "ZM >> round_think start" );
#/
    level endon( "end_round_think" );

    if ( !( isdefined( restart ) && restart ) )
    {
        if ( isdefined( level.initial_round_wait_func ) )
            [[ level.initial_round_wait_func ]]();

        if ( !( isdefined( level.host_ended_game ) && level.host_ended_game ) )
        {
            players = get_players();

            foreach ( player in players )
            {
                if ( !( isdefined( player.hostmigrationcontrolsfrozen ) && player.hostmigrationcontrolsfrozen ) )
                {
                    player freezecontrols( 0 );
/#
                    println( " Unfreeze controls 8" );
#/
                }

                player maps\mp\zombies\_zm_stats::set_global_stat( "rounds", level.round_number );
            }
        }
    }

    setroundsplayed( level.round_number );

    for (;;)
    {
        maxreward = 50 * level.round_number;

        if ( maxreward > 500 )
            maxreward = 500;

        level.zombie_vars["rebuild_barrier_cap_per_round"] = maxreward;
        level.pro_tips_start_time = gettime();
        level.zombie_last_run_time = gettime();

        if ( isdefined( level.zombie_round_change_custom ) )
            [[ level.zombie_round_change_custom ]]();
        else
        {
            level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_start" );
            round_one_up();
        }

        maps\mp\zombies\_zm_powerups::powerup_round_start();
        players = get_players();
        array_thread( players, maps\mp\zombies\_zm_blockers::rebuild_barrier_reward_reset );

        if ( !( isdefined( level.headshots_only ) && level.headshots_only ) && !restart )
            level thread award_grenades_for_survivors();

        bbprint( "zombie_rounds", "round %d player_count %d", level.round_number, players.size );
/#
        println( "ZM >> round_think, round=" + level.round_number + ", player_count=" + players.size );
#/
        level.round_start_time = gettime();

        while ( level.zombie_spawn_locations.size <= 0 )
            wait 0.1;

        level thread [[ level.round_spawn_func ]]();
        level notify( "start_of_round" );
        recordzombieroundstart();
        players = getplayers();

        for ( index = 0; index < players.size; index++ )
        {
            zonename = players[index] get_current_zone();

            if ( isdefined( zonename ) )
                players[index] recordzombiezone( "startingZone", zonename );
        }

        if ( isdefined( level.round_start_custom_func ) )
            [[ level.round_start_custom_func ]]();

        [[ level.round_wait_func ]]();
        level.first_round = 0;
        level notify( "end_of_round" );
        level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_end" );
        uploadstats();

        if ( isdefined( level.round_end_custom_logic ) )
            [[ level.round_end_custom_logic ]]();

        players = get_players();

        if ( isdefined( level.no_end_game_check ) && level.no_end_game_check )
        {
            level thread last_stand_revive();
            level thread spectators_respawn();
        }
        else if ( 1 != players.size )
            level thread spectators_respawn();

        players = get_players();
        array_thread( players, maps\mp\zombies\_zm_pers_upgrades_system::round_end );
        timer = level.zombie_vars["zombie_spawn_delay"];

        if ( timer > 0.08 )
            level.zombie_vars["zombie_spawn_delay"] = timer * 0.95;
        else if ( timer < 0.08 )
            level.zombie_vars["zombie_spawn_delay"] = 0.08;

        if ( level.gamedifficulty == 0 )
            level.zombie_move_speed = level.round_number * level.zombie_vars["zombie_move_speed_multiplier_easy"];
        else
            level.zombie_move_speed = level.round_number * level.zombie_vars["zombie_move_speed_multiplier"];

        level.round_number++;

//        if ( 255 < level.round_number )
 //           level.round_number = 255;

        setroundsplayed( level.round_number );
        matchutctime = getutc();
        players = get_players();

        foreach ( player in players )
        {
            if ( level.curr_gametype_affects_rank && level.round_number > 3 + level.start_round )
                player maps\mp\zombies\_zm_stats::add_client_stat( "weighted_rounds_played", level.round_number );

            player maps\mp\zombies\_zm_stats::set_global_stat( "rounds", level.round_number );
            player maps\mp\zombies\_zm_stats::update_playing_utc_time( matchutctime );
        }

        check_quickrevive_for_hotjoin();
        level round_over();
        level notify( "between_round_over" );
        restart = 0;
    }
}


new_round_over()
{
    if ( isdefined( level.noroundnumber ) && level.noroundnumber == 1 )
        return;

    time = level.zombie_vars["zombie_between_round_time"];
    players = getplayers();

    for ( player_index = 0; player_index < players.size; player_index++ )
    {
        if ( !isdefined( players[player_index].pers["previous_distance_traveled"] ) )
            players[player_index].pers["previous_distance_traveled"] = 0;

        distancethisround = int( players[player_index].pers["distance_traveled"] - players[player_index].pers["previous_distance_traveled"] );
        players[player_index].pers["previous_distance_traveled"] = players[player_index].pers["distance_traveled"];
        players[player_index] incrementplayerstat( "distance_traveled", distancethisround );

        if ( players[player_index].pers["team"] != "spectator" )
        {
            zonename = players[player_index] get_current_zone();

            if ( isdefined( zonename ) )
                players[player_index] recordzombiezone( "endingZone", zonename );
        }
    }

    recordzombieroundend();
    if (level.ragestarted == 1)
    {

    }
    else
    {
		if(getDvarInt("enable_timenextround") == 1)
		{
			timebetweenroundhud(time);
		}
		else
		{
    		wait( time );
		}
    }
}


//Custom Subtitles

sendsubtitletext(charactername, team, text, time)
{
	if(getDvarInt("enable_custom_subtitles") == 1)
	{	
		if(isDefined(self.subtitleText))
		{
			self waittill ("subtitle_done");
			self.subtitleText destroy();
		}
	
	
		if (team == 1)
		{
			teamcolor = "^4";
		}
		else if (team == 2)
		{
			teamcolor = "^1";
		}
		else
		{
			teamcolor = "^3";
		}
	
	
		self.subtitleText = newclienthudelem( self );
    	self.subtitleText.alignx = "center";
    	self.subtitleText.aligny = "bottom";
    	self.subtitleText.horzalign = "center";
    	self.subtitleText.vertalign = "bottom";
    	self.subtitleText.fontscale = 1.5;
    	self.subtitleText.y = 0;
    
    	self.subtitleText.foreground = 1;
    	self.subtitleText.alpha = 0;
    	self.subtitleText.hidewheninmenu = 1;
    	self.subtitleText.font = "default";

		self.subtitleText settext( teamcolor + charactername + "^7: " + text );
		self.subtitleText.color = ( 1, 1, 1 );

    	self.subtitleText moveovertime( 0.25 );
    	self.subtitleText fadeovertime( 0.25 );
    	self.subtitleText.alpha = 1;
    	self.subtitleText.y = -10;
    
    	wait time;
    
    	self.subtitleText moveovertime( 0.25 );
    	self.subtitleText fadeovertime( 0.25 );
    	self.subtitleText.alpha = 0;
    	self.subtitleText.y = -20;
    	wait 1.1;
    	self.subtitleText destroy();
    	self notify ("subtitle_done");
    }
}

exfilAvailable()
{
	msg = array("An escape portal is available!","A portal has opened for exfil.","Exfil available!","A tear into the aether has opened. You can exfil through it!");
	
	chance = randomintrange(0, msg.size - 1);
	
	return msg[chance];
}

exfilUnAvailable()
{
	msg = array("The portal has closed!","Exfil window closed!","The aether tear has closed. Should re-open soon!");
	
	chance = randomintrange(0, msg.size - 1);
	
	return msg[chance];
}

boneLines()
{
	if (level.bonescollected == 1)
		text = "What are you doing?";
	else if (level.bonescollected == 2)
		text = "Why are you doing this!";
	else if (level.bonescollected == 3)
		text = "Hey! stop it!";
	
	return text;
}

chooseAnnouncer()
{
	if (getDvar("mapname") == "zm_transit")
		return "Richtofen";
	else if (getDvar("mapname") == "zm_nuked")
		return "Richtofen";
	else if (getDvar("mapname") == "zm_tomb")
		return "Samantha Maxis";
	else if (getDvar("mapname") == "zm_prison")
		return "Afterlife Spirit";
	else if (getDvar("mapname") == "zm_buried")
		return "Richtofen";
	else if (getDvar("mapname") == "zm_highrise")
		return "Richtofen";
}

buildable_use_hold_think_internal_new( player, bind_stub )
{
    if ( !isdefined( bind_stub ) )
        bind_stub = self.stub;

    wait 0.01;

    if ( !isdefined( self ) )
    {
        self notify( "build_failed" );

        if ( isdefined( player.buildableaudio ) )
        {
            player.buildableaudio delete();
            player.buildableaudio = undefined;
        }

        return;
    }

    if ( !isdefined( self.usetime ) )
        self.usetime = int( 3000 );

	if (player hasPerk("specialty_fastreload"))
	{
		self.usetime = self.usetime/3;
	}
	
    self.build_time = self.usetime;
    self.build_start_time = gettime();
    build_time = self.build_time;
    build_start_time = self.build_start_time;
    player disable_player_move_states( 1 );
    player increment_is_drinking();
    orgweapon = player getcurrentweapon();
    build_weapon = "zombie_builder_zm";

    if ( isdefined( bind_stub.build_weapon ) )
        build_weapon = bind_stub.build_weapon;

    player giveweapon( build_weapon );
    player switchtoweapon( build_weapon );
    slot = bind_stub.buildablestruct.buildable_slot;
    bind_stub.buildablezone buildable_set_piece_building( player player_get_buildable_piece( slot ) );
    player thread player_progress_bar( build_start_time, build_time, bind_stub.building_prompt );

    if ( isdefined( level.buildable_build_custom_func ) )
        player thread [[ level.buildable_build_custom_func ]]( self.stub );

    while ( isdefined( self ) && player player_continue_building( bind_stub.buildablezone, self.stub ) && gettime() - self.build_start_time < self.build_time )
        wait 0.05;

    player notify( "buildable_progress_end" );
    player maps\mp\zombies\_zm_weapons::switch_back_primary_weapon( orgweapon );
    player takeweapon( "zombie_builder_zm" );

    if ( isdefined( player.is_drinking ) && player.is_drinking )
        player decrement_is_drinking();

    player enable_player_move_states();

    if ( isdefined( self ) && player player_continue_building( bind_stub.buildablezone, self.stub ) && gettime() - self.build_start_time >= self.build_time )
    {
        buildable_clear_piece_building( player player_get_buildable_piece( slot ) );
        self notify( "build_succeed" );
    }
    else
    {
        if ( isdefined( player.buildableaudio ) )
        {
            player.buildableaudio delete();
            player.buildableaudio = undefined;
        }

        buildable_clear_piece_building( player player_get_buildable_piece( slot ) );
        self notify( "build_failed" );
    }
}




// Reworked powerups

full_ammo_on_hud_new( drop_item, player_team )
{
   	if(getDvarInt("enable_custom_subtitles") == 1)
   	{
   		self endon( "disconnect" );
   		foreach ( i in get_players() )
    		i thread sendsubtitletext(chooseAnnouncer(), 1, "Max Ammo!", 1.5);
    }
    else
    {	
    	hudelem = maps\mp\gametypes_zm\_hud_util::createserverfontstring( "objective", 2, player_team );
    	hudelem maps\mp\gametypes_zm\_hud_util::setpoint( "TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] - level.zombie_vars["zombie_timer_offset_interval"] * 2 );
    	hudelem.sort = 0.5;
    	hudelem.alpha = 0;
    	hudelem fadeovertime( 0.5 );
    	hudelem.alpha = 1;

    	if ( isdefined( drop_item ) )
        	hudelem.label = drop_item.hint;

    	hudelem thread full_ammo_move_hud( player_team );
    }
}

start_fire_sale_new( item )
{
    foreach ( i in get_players() )
    	i thread sendsubtitletext(chooseAnnouncer(), 1, "Fire Sale!", 1.5);
    
    if ( level.zombie_vars["zombie_powerup_fire_sale_time"] > 0 && is_true( level.zombie_vars["zombie_powerup_fire_sale_on"] ) )
    {
        level.zombie_vars["zombie_powerup_fire_sale_time"] = level.zombie_vars["zombie_powerup_fire_sale_time"] + 30;
        return;
    }

    level notify( "powerup fire sale" );
    level endon( "powerup fire sale" );
    level thread maps\mp\zombies\_zm_audio_announcer::leaderdialog( "fire_sale" );
    level.zombie_vars["zombie_powerup_fire_sale_on"] = 1;
    level thread toggle_fire_sale_on();
    level.zombie_vars["zombie_powerup_fire_sale_time"] = 30;

    while ( level.zombie_vars["zombie_powerup_fire_sale_time"] > 0 )
    {
        wait 0.05;
        level.zombie_vars["zombie_powerup_fire_sale_time"] = level.zombie_vars["zombie_powerup_fire_sale_time"] - 0.05;
    }

    level.zombie_vars["zombie_powerup_fire_sale_on"] = 0;
    level notify( "fire_sale_off" );
}

insta_kill_powerup_new( drop_item, player )
{
    level notify( "powerup instakill_" + player.team );
    level endon( "powerup instakill_" + player.team );

    if ( isdefined( level.insta_kill_powerup_override ) )
    {
        level thread [[ level.insta_kill_powerup_override ]]( drop_item, player );
        return;
    }

    if ( is_classic() )
        player thread maps\mp\zombies\_zm_pers_upgrades_functions::pers_upgrade_insta_kill_upgrade_check();

    team = player.team;
    level thread insta_kill_on_hud( drop_item, team );
    level.zombie_vars[team]["zombie_insta_kill"] = 1;
    foreach ( i in get_players() )
    	i thread sendsubtitletext(chooseAnnouncer(), 1, "Insta Kill!", 1.5);
    wait 30;
    level.zombie_vars[team]["zombie_insta_kill"] = 0;
    players = get_players( team );

    for ( i = 0; i < players.size; i++ )
    {
        if ( isdefined( players[i] ) )
            players[i] notify( "insta_kill_over" );
    }
}

double_points_powerup_new( drop_item, player )
{
    level notify( "powerup points scaled_" + player.team );
    level endon( "powerup points scaled_" + player.team );
    team = player.team;
    level thread point_doubler_on_hud( drop_item, team );

    foreach ( i in get_players() )
    	i thread sendsubtitletext(chooseAnnouncer(), 1, "Double Points!", 1.5);

    if ( isdefined( level.pers_upgrade_double_points ) && level.pers_upgrade_double_points )
        player thread maps\mp\zombies\_zm_pers_upgrades_functions::pers_upgrade_double_points_pickup_start();

    if ( isdefined( level.current_game_module ) && level.current_game_module == 2 )
    {
        if ( isdefined( player._race_team ) )
        {
            if ( player._race_team == 1 )
                level._race_team_double_points = 1;
            else
                level._race_team_double_points = 2;
        }
    }

    level.zombie_vars[team]["zombie_point_scalar"] = 2;
    players = get_players();

    for ( player_index = 0; player_index < players.size; player_index++ )
    {
        if ( team == players[player_index].team )
            players[player_index] setclientfield( "score_cf_double_points_active", 1 );
    }

    wait 30;
    level.zombie_vars[team]["zombie_point_scalar"] = 1;
    level._race_team_double_points = undefined;
    players = get_players();

    for ( player_index = 0; player_index < players.size; player_index++ )
    {
        if ( team == players[player_index].team )
            players[player_index] setclientfield( "score_cf_double_points_active", 0 );
    }
}
		
new_start_carpenter( origin )
{
    foreach ( i in get_players() )
    	i thread sendsubtitletext(chooseAnnouncer(), 1, "Carpenter!", 1.5);
    	i.shielddamagetaken = 0;
    
    window_boards = getstructarray( "exterior_goal", "targetname" );
    total = level.exterior_goals.size;
    carp_ent = spawn( "script_origin", ( 0, 0, 0 ) );
    carp_ent playloopsound( "evt_carpenter" );

    while ( true )
    {
        windows = get_closest_window_repair( window_boards, origin );

        if ( !isdefined( windows ) )
        {
            carp_ent stoploopsound( 1 );
            carp_ent playsoundwithnotify( "evt_carpenter_end", "sound_done" );
            carp_ent waittill( "sound_done" );
            break;
        }
        else
            arrayremovevalue( window_boards, windows );

        while ( true )
        {
            if ( all_chunks_intact( windows, windows.barrier_chunks ) )
                break;

            chunk = get_random_destroyed_chunk( windows, windows.barrier_chunks );

            if ( !isdefined( chunk ) )
                break;

            windows thread maps\mp\zombies\_zm_blockers::replace_chunk( windows, chunk, undefined, maps\mp\zombies\_zm_powerups::is_carpenter_boards_upgraded(), 1 );

            if ( isdefined( windows.clip ) )
            {
                windows.clip enable_trigger();
                windows.clip disconnectpaths();
            }
            else
                blocker_disconnect_paths( windows.neg_start, windows.neg_end );

            wait_network_frame();
            wait 0.05;
        }

        wait_network_frame();
    }

    players = get_players();

    for ( i = 0; i < players.size; i++ )
        players[i] maps\mp\zombies\_zm_score::player_add_points( "carpenter_powerup", 200 );

    carp_ent delete();
}

new_start_carpenter_new( origin )
{
    foreach ( i in get_players() )
    	i thread sendsubtitletext(chooseAnnouncer(), 1, "Carpenter!", 1.5);
    	i.shielddamagetaken = 0;

    level.carpenter_powerup_active = 1;
    window_boards = getstructarray( "exterior_goal", "targetname" );

    if ( isdefined( level._additional_carpenter_nodes ) )
        window_boards = arraycombine( window_boards, level._additional_carpenter_nodes, 0, 0 );

    carp_ent = spawn( "script_origin", ( 0, 0, 0 ) );
    carp_ent playloopsound( "evt_carpenter" );
    boards_near_players = get_near_boards( window_boards );
    boards_far_from_players = get_far_boards( window_boards );
    level repair_far_boards( boards_far_from_players, maps\mp\zombies\_zm_powerups::is_carpenter_boards_upgraded() );

    for ( i = 0; i < boards_near_players.size; i++ )
    {
        window = boards_near_players[i];
        num_chunks_checked = 0;
        last_repaired_chunk = undefined;

        while ( true )
        {
            if ( all_chunks_intact( window, window.barrier_chunks ) )
                break;

            chunk = get_random_destroyed_chunk( window, window.barrier_chunks );

            if ( !isdefined( chunk ) )
                break;

            window thread maps\mp\zombies\_zm_blockers::replace_chunk( window, chunk, undefined, maps\mp\zombies\_zm_powerups::is_carpenter_boards_upgraded(), 1 );
            last_repaired_chunk = chunk;

            if ( isdefined( window.clip ) )
            {
                window.clip enable_trigger();
                window.clip disconnectpaths();
            }
            else
                blocker_disconnect_paths( window.neg_start, window.neg_end );

            wait_network_frame();
            num_chunks_checked++;

            if ( num_chunks_checked >= 20 )
                break;
        }

        if ( isdefined( window.zbarrier ) )
        {
            if ( isdefined( last_repaired_chunk ) )
            {
                while ( window.zbarrier getzbarrierpiecestate( last_repaired_chunk ) == "closing" )
                    wait 0.05;

                if ( isdefined( window._post_carpenter_callback ) )
                    window [[ window._post_carpenter_callback ]]();
            }

            continue;
        }

        while ( isdefined( last_repaired_chunk ) && last_repaired_chunk.state == "mid_repair" )
            wait 0.05;
    }

    carp_ent stoploopsound( 1 );
    carp_ent playsoundwithnotify( "evt_carpenter_end", "sound_done" );
    carp_ent waittill( "sound_done" );
    players = get_players();

    for ( i = 0; i < players.size; i++ )
        players[i] maps\mp\zombies\_zm_score::player_add_points( "carpenter_powerup", 200 );

    carp_ent delete();
    level notify( "carpenter_finished" );
    level.carpenter_powerup_active = undefined;
}

full_ammo_powerup_new( drop_item, player )
{
    players = get_players( player.team );

    if ( isdefined( level._get_game_module_players ) )
        players = [[ level._get_game_module_players ]]( player );

    for ( i = 0; i < players.size; i++ )
    {
        if ( players[i] maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
            continue;

        primary_weapons = players[i] getweaponslist( 1 );
        players[i] notify( "zmb_max_ammo" );
        players[i] notify( "zmb_lost_knife" );
        players[i] notify( "zmb_disable_claymore_prompt" );
        players[i] notify( "zmb_disable_spikemore_prompt" );
        if (getDvarInt("enable_bo4ammo") == 1)
        {
        	players[i] doBO4MaxAmmo();
        }

        for ( x = 0; x < primary_weapons.size; x++ )
        {
            if ( level.headshots_only && is_lethal_grenade( primary_weapons[x] ) )
                continue;

            if ( isdefined( level.zombie_include_equipment ) && isdefined( level.zombie_include_equipment[primary_weapons[x]] ) )
                continue;

            if ( isdefined( level.zombie_weapons_no_max_ammo ) && isdefined( level.zombie_weapons_no_max_ammo[primary_weapons[x]] ) )
                continue;

            if ( players[i] hasweapon( primary_weapons[x] ) )
                players[i] givemaxammo( primary_weapons[x] );
        }
    }

    level thread full_ammo_on_hud( drop_item, player.team );
}

pers_upgrade_init_new()
{
    if (getDvarInt("enable_permaperks") == 1)
    {
    	setup_pers_upgrade_boards();
    	setup_pers_upgrade_revive();
   		setup_pers_upgrade_multi_kill_headshots();
    	setup_pers_upgrade_cash_back();
    	setup_pers_upgrade_insta_kill();
    	setup_pers_upgrade_jugg();
    	setup_pers_upgrade_carpenter();
    	setup_pers_upgrade_flopper();
    	setup_pers_upgrade_perk_lose();
    	setup_pers_upgrade_pistol_points();
    	setup_pers_upgrade_double_points();
    	setup_pers_upgrade_sniper();
    	setup_pers_upgrade_box_weapon();
    	setup_pers_upgrade_nube();
    	level thread pers_upgrades_monitor();
    }
}

treasure_chest_move_new( player_vox )
{
    level waittill( "weapon_fly_away_start" );
    players = get_players();
    array_thread( players, ::play_crazi_sound );

    if ( isdefined( player_vox ) )
        player_vox delay_thread( randomintrange( 2, 7 ), maps\mp\zombies\_zm_audio::create_and_play_dialog, "general", "box_move" );

    level waittill( "weapon_fly_away_end" );

    if ( isdefined( self.zbarrier ) )
        self hide_chest( 1 );

    wait 0.1;
    post_selection_wait_duration = 7;

    if ( level.zombie_vars["zombie_powerup_fire_sale_on"] == 1 && self [[ level._zombiemode_check_firesale_loc_valid_func ]]() )
    {
        current_sale_time = level.zombie_vars["zombie_powerup_fire_sale_time"];
        wait_network_frame();
        self thread fire_sale_fix();
        level.zombie_vars["zombie_powerup_fire_sale_time"] = current_sale_time;

        while ( level.zombie_vars["zombie_powerup_fire_sale_time"] > 0 )
            wait 0.1;
    }
    else
        post_selection_wait_duration = post_selection_wait_duration + 5;

    level.verify_chest = 0;

    if ( isdefined( level._zombiemode_custom_box_move_logic ) )
        [[ level._zombiemode_custom_box_move_logic ]]();
    else
        default_box_move_logic();

    if ( isdefined( level.chests[level.chest_index].box_hacks["summon_box"] ) )
        level.chests[level.chest_index] [[ level.chests[level.chest_index].box_hacks["summon_box"] ]]( 0 );

//    wait( post_selection_wait_duration );
    playfx( level._effect["poltergeist"], level.chests[level.chest_index].zbarrier.origin );
    level.chests[level.chest_index] show_chest();
    flag_clear( "moving_chest_now" );
    self.zbarrier.chest_moving = 0;
}

timebetweenroundhud(num)
{
	if ( isdefined(level.roundtimehud))
	{
		level.roundtimehud destroy();
	}
	
	if(getDvarInt("use_customtimebetween") == 1)
	{
		hudtimer = getDvarInt("timebetween_rounds");
	}
	else
	{
		hudtimer = num;
	}
	
	hudtimer -= 1;
	
	level.roundtimehud = newhudelem();

	level.roundtimehud.alignx = "left";
	level.roundtimehud.aligny = "top";
	level.roundtimehud.horzalign = "left";
	level.roundtimehud.vertalign = "top";
	level.roundtimehud.x += 5;
	level.roundtimehud.y = 0;

	level.roundtimehud.fontscale = 2;
	level.roundtimehud.alpha = 0;
	level.roundtimehud.color = ( 1, 1, 1 );
	level.roundtimehud.hidewheninmenu = 1;
	level.roundtimehud.foreground = 1;
	level.roundtimehud.label = &"^4Next round starts in ^2";

	level.roundtimehud fadeovertime(0.2);
	level.roundtimehud.alpha = 1;
	wait 0.2;

	while(hudtimer >= 0)
	{
		level.roundtimehud setValue(hudtimer);
		wait 1;
		hudtimer -= 1;
	}
	level.roundtimehud fadeovertime(0.2);
	level.roundtimehud.alpha = 0;
	wait 0.2;
	level.roundtimehud destroy();
}

spawnTranzitLadder()
{
	ladderTrigger = spawn( "trigger_radius", ((1686.34, -1666, -25.875)), 1, 15, 15 );
	ladderTrigger setHintString("^7Hold ^3[{+gostand}] ^7to climb");
	ladderTrigger setcursorhint( "HINT_NOICON" );
	ladderModel = spawn( "script_model", ((1686.34, -1666, -55.875)));
	ladderModel setmodel ("com_stepladder_large_closed");
	ladderModel rotateTo((0,-180,0),.1);
	
	while(1)
	{
		ladderTrigger waittill( "trigger", i );
		if ( i jumpbuttonpressed() )
		{
			i setorigin((1685.01, -1723.89, 42.8876));
		}
		wait 0.1;
	}
}

//Wall Weapon in Town

init_townwallweapon()
{
	level._effect["wall_m16"] = loadfx( "maps/zombie/fx_zmb_wall_buy_m16" ); 
    flag_wait( "initial_blackscreen_passed" );
    thread townwallweaponmonitorbox(( 2273.641, 167.5, 140.125 ), ( 0, 180, 0 ), "m16_zm", 1200, 600 );
    thread townplaychalkfx("wall_m16", ( 2274.641, 168, 140.125 ), ( 0, 180, 0 ));
}

townplaychalkfx(effect, origin, angles)
{
    for(;;)
	{
		fx = SpawnFX(level._effect[ effect ], origin,AnglesToForward(angles),AnglesToUp(angles));
		TriggerFX(fx);
		level waittill("connected", player);
		fx Delete();
	}
}

townwallweaponmonitorbox(origin, angles, weapon, cost, ammo )
{
    name = get_weapon_display_name( weapon );
	trigger = spawn("trigger_radius", origin, 0, 35, 80);
	trigger SetCursorHint("HINT_NOICON");
	trigger SetHintString("Hold ^3&&1^7 for " + name + " [Cost: " + cost + "]");
    for(;;)
    {
		trigger waittill("trigger", player);
		
		if(player has_upgrade(weapon))
		{
			trigger SetHintString("Hold ^3&&1^7 for ammo [Cost: 4500]");
		}
		else if(player hasweapon(weapon))
		{
			trigger SetHintString("Hold ^3&&1^7 for ammo [Cost: " + ammo + "]");
		}
		
        if(player usebuttonpressed() && !player maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
        {
            if( !(player has_weapon_or_upgrade(weapon)) && player.score >= cost && player can_buy_weapon())
            {
                player playsound( "zmb_cha_ching" );
                player.score -= cost;
                player thread weapon_give( weapon, 0, 1 );
                if(!isdefined(model))
                {
                    play_sound_at_pos( "weapon_show", origin, player );
                    model = spawn("script_model", origin);
                    model.angles = angles;
                    model setmodel(getweaponmodel( weapon ));
                }
                wait 3;
            }
            else
            {
                if(player has_upgrade(weapon) && player.score >= 4500)
                {
                    if(player ammo_give(get_upgrade_weapon(weapon)))
                    {
                        player.score -= 4500;
                        player playsound("zmb_cha_ching");
                        wait 3;
                    }
                }
                else if(player hasweapon(weapon) && player.score >= ammo)
                {
                    if(player ammo_give(weapon))
                    {
                        player.score -= ammo;
                        player playsound("zmb_cha_ching");
                        wait 3;
                    }
                }
            }
		}
		
		if(player has_upgrade(weapon))
		{
			trigger SetHintString("Hold ^3&&1^7 for ammo [Cost: 4500]");
		}
		else if(player hasweapon(weapon))
		{
			trigger SetHintString("Hold ^3&&1^7 for ammo [Cost: " + ammo + "]");
		}
		
		wait .1;
	}
}

timer_hud()
{
	hud = newHudElem();
	hud.alignx = "right";
	hud.aligny = "top";
	hud.horzalign = "user_right";
	hud.vertalign = "user_top";
	hud.x -= 5;
	hud.y += 24;
	hud.fontscale = 1.4;
	hud.alpha = 0;
	hud.color = ( 1, 1, 1 );
	hud.hidewheninmenu = 1;
	hud.foreground = 1;
	hud.label = &"Total: ";

	hud endon("death");

	hud thread destroy_on_intermission();

	hud thread set_time_frozen_on_end_game();

	hud.alpha = 1;

	if ( !flag( "initial_blackscreen_passed" ) )
	{
		hud set_time_frozen(0, "initial_blackscreen_passed");
	}

	if ( getDvar( "g_gametype" ) == "zgrief" )
	{
		hud set_time_frozen(0);
	}

	hud setTimerUp(0);
	hud.start_time = getTime();
	level.timer_hud_start_time = hud.start_time;
}

set_time_frozen(time, endon_notify)
{
	if ( isDefined( endon_notify ) )
	{
		level endon( endon_notify );
	}
	else if ( getDvar( "g_gametype" ) == "zgrief" )
	{
		level endon( "restart_round_start" );
	}
	else
	{
		level endon( "start_of_round" );
	}

	self endon( "death" );

	if(time != 0)
	{
		time -= 0.5; // need to set it below the number or it shows the next number
	}

	while (1)
	{
		if(time == 0)
		{
			self setTimerUp(time);
		}
		else
		{
			self setTimer(time);
		}

		wait 0.5;
	}
}

set_time_frozen_on_end_game()
{
	level endon("intermission");

	level waittill_any("end_game", "freeze_timers");

	time = int((getTime() - self.start_time) / 1000);

	self set_time_frozen(time, "forever");
}

bleedout_bar_hud()
{
	self endon("disconnect");

	while (1)
	{
		self waittill("entering_last_stand");

		if(is_gametype_active("zcleansed"))
		{
			continue;
		}

		// don't show for last player downed
		if(!self maps\mp\zombies\_zm_laststand::player_is_in_laststand())
		{
			continue;
		}

		hud = self createbar((1, 0, 0), level.secondaryprogressbarwidth * 2, level.secondaryprogressbarheight);
		hud setpoint("CENTER", undefined, level.secondaryprogressbarx, -1 * level.secondaryprogressbary);
		hud.hidewheninmenu = 1;
		hud.bar.hidewheninmenu = 1;
		hud.barframe.hidewheninmenu = 1;
		hud.sort = 1;
		hud.bar.sort = 2;
		hud.barframe.sort = 3;
		hud.barframe destroy();
		hud thread destroy_on_intermission();

		self thread bleedout_bar_hud_updatebar(hud);

		self waittill_any("player_revived", "bled_out", "player_suicide");

		hud.bar destroy();
		hud destroy();
	}
}

// scaleovertime doesn't work past 30 seconds so here is a workaround
bleedout_bar_hud_updatebar(hud)
{
	self endon("player_revived");
	self endon("bled_out");
	self endon("player_suicide");

	vars = [];

	vars["bleedout_time"] = getDvarInt("player_lastStandBleedoutTime");
	vars["interval_time"] = 30;
	vars["interval_frac"] = vars["interval_time"] / vars["bleedout_time"];
	vars["num_intervals"] = int(vars["bleedout_time"] / vars["interval_time"]) + 1;

	hud updatebar(1);

	for(i = 0; i < vars["num_intervals"]; i++)
	{
		vars["time"] = vars["bleedout_time"];
		if(vars["time"] > vars["interval_time"])
		{
			vars["time"] = vars["interval_time"];
		}

		vars["frac"] = 0.99 - ((i + 1) * vars["interval_frac"]);

		barwidth = int((hud.width * vars["frac"]) + 0.5);
		if(barwidth < 1)
		{
			barwidth = 1;
		}

		hud.bar scaleovertime(vars["time"], barwidth, hud.height);

		wait vars["time"];

		vars["bleedout_time"] -= vars["time"];
	}
}

destroy_on_end_game()
{
	self endon("death");

	level waittill("end_game");

	if(isDefined(self.bar))
	{
		self.bar destroy();
	}

	if(isDefined(self.barframe))
	{
		self.barframe destroy();
	}

	self destroy();
}

destroy_on_intermission()
{
	self endon("death");

	level waittill("intermission");

	if(isDefined(self.bar))
	{
		self.bar destroy();
	}

	if(isDefined(self.barframe))
	{
		self.barframe destroy();
	}

	self destroy();
}

treasure_chest_weapon_spawn_new( chest, player, respin )
{
    if ( isdefined( level.using_locked_magicbox ) && level.using_locked_magicbox )
    {
        self.owner endon( "box_locked" );
        self thread maps\mp\zombies\_zm_magicbox_lock::clean_up_locked_box();
    }

    self endon( "box_hacked_respin" );
    self thread clean_up_hacked_box();
    assert( isdefined( player ) );
    self.weapon_string = undefined;
    modelname = undefined;
    rand = undefined;
	if (player hasPerk("specialty_rof"))
	{
		number_cycles = 5;
	}
	else
	{
		number_cycles = 40;
	}

    if ( isdefined( chest.zbarrier ) && !player hasPerk("specialty_rof") )
    {
        if ( isdefined( level.custom_magic_box_do_weapon_rise ) )
            chest.zbarrier thread [[ level.custom_magic_box_do_weapon_rise ]]();
        else
            chest.zbarrier thread magic_box_do_weapon_rise();
    }

    for ( i = 0; i < number_cycles; i++ )
    {
        if ( i < 20 )
        {
            wait 0.05;
            continue;
        }

        if ( i < 30 )
        {
            wait 0.1;
            continue;
        }

        if ( i < 35 )
        {
            wait 0.2;
            continue;
        }

        if ( i < 38 )
            wait 0.3;
    }

    if ( isdefined( level.custom_magic_box_weapon_wait ) )
        [[ level.custom_magic_box_weapon_wait ]]();

    if ( isdefined( player.pers_upgrades_awarded["box_weapon"] ) && player.pers_upgrades_awarded["box_weapon"] )
        rand = maps\mp\zombies\_zm_pers_upgrades_functions::pers_treasure_chest_choosespecialweapon( player );
    else
        rand = treasure_chest_chooseweightedrandomweapon( player );

    self.weapon_string = rand;
    wait 0.1;

    if ( isdefined( level.custom_magicbox_float_height ) )
        v_float = anglestoup( self.angles ) * level.custom_magicbox_float_height;
    else
        v_float = anglestoup( self.angles ) * 40;

    self.model_dw = undefined;
    self.weapon_model = spawn_weapon_model( rand, undefined, self.origin + v_float, self.angles + vectorscale( ( 0, 1, 0 ), 180.0 ) );

    if ( weapon_is_dual_wield( rand ) )
        self.weapon_model_dw = spawn_weapon_model( rand, get_left_hand_weapon_model_name( rand ), self.weapon_model.origin - vectorscale( ( 1, 1, 1 ), 3.0 ), self.weapon_model.angles );

    if ( getdvar( #"magic_chest_movable" ) == "1" && !( isdefined( chest._box_opened_by_fire_sale ) && chest._box_opened_by_fire_sale ) && !( isdefined( level.zombie_vars["zombie_powerup_fire_sale_on"] ) && level.zombie_vars["zombie_powerup_fire_sale_on"] && self [[ level._zombiemode_check_firesale_loc_valid_func ]]() ) )
    {
        random = randomint( 100 );

        if ( !isdefined( level.chest_min_move_usage ) )
            level.chest_min_move_usage = 4;

        if ( level.chest_accessed < level.chest_min_move_usage )
            chance_of_joker = -1;
        else
        {
            chance_of_joker = level.chest_accessed + 20;

            if ( level.chest_moves == 0 && level.chest_accessed >= 8 )
                chance_of_joker = 100;

            if ( level.chest_accessed >= 4 && level.chest_accessed < 8 )
            {
                if ( random < 15 )
                    chance_of_joker = 100;
                else
                    chance_of_joker = -1;
            }

            if ( level.chest_moves > 0 )
            {
                if ( level.chest_accessed >= 8 && level.chest_accessed < 13 )
                {
                    if ( random < 30 )
                        chance_of_joker = 100;
                    else
                        chance_of_joker = -1;
                }

                if ( level.chest_accessed >= 13 )
                {
                    if ( random < 50 )
                        chance_of_joker = 100;
                    else
                        chance_of_joker = -1;
                }
            }
        }

        if ( isdefined( chest.no_fly_away ) )
            chance_of_joker = -1;

        if ( isdefined( level._zombiemode_chest_joker_chance_override_func ) )
            chance_of_joker = [[ level._zombiemode_chest_joker_chance_override_func ]]( chance_of_joker );

        if ( chance_of_joker > random )
        {
            self.weapon_string = undefined;
            self.weapon_model setmodel( level.chest_joker_model );
            self.weapon_model.angles = self.angles + vectorscale( ( 0, 1, 0 ), 90.0 );

            if ( isdefined( self.weapon_model_dw ) )
            {
                self.weapon_model_dw delete();
                self.weapon_model_dw = undefined;
            }

            self.chest_moving = 1;
            flag_set( "moving_chest_now" );
            level.chest_accessed = 0;
            level.chest_moves++;
        }
    }

    self notify( "randomization_done" );

    if ( flag( "moving_chest_now" ) && !( level.zombie_vars["zombie_powerup_fire_sale_on"] && self [[ level._zombiemode_check_firesale_loc_valid_func ]]() ) )
    {
        if ( isdefined( level.chest_joker_custom_movement ) )
            self [[ level.chest_joker_custom_movement ]]();
        else
        {
            wait 0.5;
            level notify( "weapon_fly_away_start" );
            wait 2;

            if ( isdefined( self.weapon_model ) )
            {
                v_fly_away = self.origin + anglestoup( self.angles ) * 500;
                self.weapon_model moveto( v_fly_away, 4, 3 );
            }

            if ( isdefined( self.weapon_model_dw ) )
            {
                v_fly_away = self.origin + anglestoup( self.angles ) * 500;
                self.weapon_model_dw moveto( v_fly_away, 4, 3 );
            }

            self.weapon_model waittill( "movedone" );
            self.weapon_model delete();

            if ( isdefined( self.weapon_model_dw ) )
            {
                self.weapon_model_dw delete();
                self.weapon_model_dw = undefined;
            }

            self notify( "box_moving" );
            level notify( "weapon_fly_away_end" );
        }
    }
    else
    {
        acquire_weapon_toggle( rand, player );

        if ( rand == "tesla_gun_zm" || rand == "ray_gun_zm" )
        {
            if ( rand == "ray_gun_zm" )
                level.pulls_since_last_ray_gun = 0;

            if ( rand == "tesla_gun_zm" )
            {
                level.pulls_since_last_tesla_gun = 0;
                level.player_seen_tesla_gun = 1;
            }
        }

        if ( !isdefined( respin ) )
        {
            if ( isdefined( chest.box_hacks["respin"] ) )
                self [[ chest.box_hacks["respin"] ]]( chest, player );
        }
        else if ( isdefined( chest.box_hacks["respin_respin"] ) )
            self [[ chest.box_hacks["respin_respin"] ]]( chest, player );

        if ( isdefined( level.custom_magic_box_timer_til_despawn ) )
            self.weapon_model thread [[ level.custom_magic_box_timer_til_despawn ]]( self );
        else
            self.weapon_model thread timer_til_despawn( v_float );

        if ( isdefined( self.weapon_model_dw ) )
        {
            if ( isdefined( level.custom_magic_box_timer_til_despawn ) )
                self.weapon_model_dw thread [[ level.custom_magic_box_timer_til_despawn ]]( self );
            else
                self.weapon_model_dw thread timer_til_despawn( v_float );
        }

        self waittill( "weapon_grabbed" );

        if ( !chest.timedout )
        {
            if ( isdefined( self.weapon_model ) )
                self.weapon_model delete();

            if ( isdefined( self.weapon_model_dw ) )
                self.weapon_model_dw delete();
        }
    }

    self.weapon_string = undefined;
    self notify( "box_spin_done" );
}

sortPlayerArray()
{
	self.finalArray = [];

	foreach (player in level.players )
	{
		if (player != self)
		{
			self.finalArray[self.finalArray.size] = player;
		}
	}
	return self.finalArray.size;
}

reworkedHUD()
{
	self setclientuivisibilityflag( "hud_visible", 0 );
	self iprintln("Attempted to hide HUD");
}


//////////////////////////////////////////////////////////
//
//	Starter Weapon Grab script
//
/////////////////////////////////////////////////////////

init_startergrab()
{
    if(getDvar("mapname") != "zm_prison")
	{
		level thread setStartLocation();
	}
}

setStartLocation()
{
	if ( getDvar( "g_gametype" ) == "zgrief" || getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead grief
		{

		}
		else if(getDvar("mapname") == "zm_buried") //buried grief
		{

		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			thread spawnStarterCrate((-253.12, 544.922, -55.375), "m1911_zm", "t6_wpn_pistol_m1911_world", 120);
		}
		else if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			if(getDvar("ui_zm_mapstartlocation") == "town") //town
			{
				thread spawnStarterCrate((1667.92, -735.349, -22.4021), "m1911_zm", "t6_wpn_pistol_m1911_world", -150);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "transit") //busdepot
			{
				thread spawnStarterCrate((-7171.67, 5355.02, -30.0795), "m1911_zm", "t6_wpn_pistol_m1911_world", -1);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "farm") //farm
			{
				thread spawnStarterCrate((8024.63, -6233.51, 142.837), "m1911_zm", "t6_wpn_pistol_m1911_world", 127);
			}
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{

		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			thread spawnStarterCrate((-2996.58, -47.6409, 1365.13), "m1911_zm", "t6_wpn_pistol_m1911_world", -90);
			thread spawnStarterCrate((-1256.88, -104.969, 298.125), "m1911_zm", "t6_wpn_pistol_m1911_world", -90);
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			thread spawnStarterCrate((-6985.49, 5321, -32.8871), "m1911_zm", "t6_wpn_pistol_m1911_world", 90);
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			thread spawnStarterCrate((2458.98, 5057.47, -335.298), "c96_zm", "t6_wpn_zmb_mc96_world", -14);
		}
		else if(getDvar("mapname") == "zm_highrise")
		{
			thread spawnStarterCrate((1553.25, 1581.86, 3418.72), "m1911_zm", "t6_wpn_pistol_m1911_world", 112);
		}
	}
}

spawnStarterCrate(location, weapon, weaponmodel, angle)
{
	starterTrigger = spawn( "trigger_radius", location, 1, 50, 50 );
	starterTrigger setHintString("^7Press ^3&&1 ^7to pick up ^3" + get_weapon_display_name( weapon ));
	starterTrigger setcursorhint( "HINT_NOICON" );
//	starterModel = spawn( "script_model", location);
//	starterModel setmodel ("char_ger_zombieeye");
//	starterModel rotateTo(angle,.1);

	starterGunModel = spawn( "script_model", (location[0], location[1], location[2]));
	starterGunModel setmodel (weaponmodel);
	starterGunModel rotateTo((0,angle - 270,0),.1);
	
	while(1)
	{
		starterTrigger waittill( "trigger", player );
		if ( player usebuttonpressed() )
		{
			if(player usebuttonpressed() && !player maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
			{
				if(player hasweapon(weapon))
				{
					if(player ammo_give(weapon))
					{
						player playsound("zmb_cha_ching");
					}
				}
				else
				{
					player playsound( "zmb_cha_ching" );
					player thread weapon_give( weapon, 0, 1 );
					wait 3;
				}
			}
		}
		wait 0.5;
	}
}

////////////////////////////////////////////////////////////
//
//
//	[Gamemodes]
//
//
////////////////////////////////////////////////////////////


respawnPlayer()
{
	if(getDvarInt("gamemode") != 0)
	{
		wait 5;
		if (self.sessionstate == "spectator")
		{
			self [[ level.spawnplayer ]]();
		}
		self startHUDMessage();
	}
}



init_powerups_minigame()
{
    flag_init( "zombie_drop_powerups" );

    if ( isdefined( level.enable_magic ) && level.enable_magic )
        flag_set( "zombie_drop_powerups" );

    if ( !isdefined( level.active_powerups ) )
        level.active_powerups = [];

    if ( !isdefined( level.zombie_powerup_array ) )
        level.zombie_powerup_array = [];

    if ( !isdefined( level.zombie_special_drop_array ) )
        level.zombie_special_drop_array = [];

    if (getDvarInt("gamemode") == 1)
	{
		add_zombie_powerup( "nuke", "zombie_bomb", &"ZOMBIE_POWERUP_NUKE", ::func_should_never_drop, 0, 0, 0, "misc/fx_zombie_mini_nuke_hotness" );
		add_zombie_powerup( "insta_kill", "zombie_skull", &"ZOMBIE_POWERUP_INSTA_KILL", ::func_should_never_drop, 0, 0, 0, undefined, "powerup_instant_kill", "zombie_powerup_insta_kill_time", "zombie_powerup_insta_kill_on" );
		add_zombie_powerup( "full_ammo", "zombie_ammocan", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 0 );
		add_zombie_powerup( "double_points", "zombie_x2_icon", &"ZOMBIE_POWERUP_DOUBLE_POINTS", ::func_should_never_drop, 0, 0, 0, undefined, "powerup_double_points", "zombie_powerup_point_doubler_time", "zombie_powerup_point_doubler_on" );
		add_zombie_powerup( "carpenter", "zombie_carpenter", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 0 );
		add_zombie_powerup( "fire_sale", "zombie_firesale", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 0, undefined, "powerup_fire_sale", "zombie_powerup_fire_sale_time", "zombie_powerup_fire_sale_on" );
		add_zombie_powerup( "bonfire_sale", "zombie_pickup_bonfire", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 0, undefined, "powerup_bon_fire", "zombie_powerup_bonfire_sale_time", "zombie_powerup_bonfire_sale_on" );
		add_zombie_powerup( "minigun", "zombie_pickup_minigun", &"ZOMBIE_POWERUP_MINIGUN", ::func_should_never_drop, 1, 0, 0, undefined, "powerup_mini_gun", "zombie_powerup_minigun_time", "zombie_powerup_minigun_on" );
		add_zombie_powerup( "free_perk", "zombie_pickup_perk_bottle", &"ZOMBIE_POWERUP_FREE_PERK", ::func_should_never_drop, 0, 0, 0 );
		add_zombie_powerup( "tesla", "zombie_pickup_minigun", &"ZOMBIE_POWERUP_MINIGUN", ::func_should_never_drop, 1, 0, 0, undefined, "powerup_tesla", "zombie_powerup_tesla_time", "zombie_powerup_tesla_on" );
		add_zombie_powerup( "random_weapon", "zombie_pickup_minigun", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 1, 0, 0 );
		add_zombie_powerup( "bonus_points_player", "zombie_z_money_icon", &"ZOMBIE_POWERUP_BONUS_POINTS", ::func_should_never_drop, 1, 0, 0 );
		add_zombie_powerup( "bonus_points_team", "zombie_z_money_icon", &"ZOMBIE_POWERUP_BONUS_POINTS", ::func_should_never_drop, 0, 0, 0 );
		add_zombie_powerup( "lose_points_team", "zombie_z_money_icon", &"ZOMBIE_POWERUP_LOSE_POINTS", ::func_should_never_drop, 0, 0, 1 );
		add_zombie_powerup( "lose_perk", "zombie_pickup_perk_bottle", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 1 );
		add_zombie_powerup( "empty_clip", "zombie_ammocan", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 1 );
		add_zombie_powerup( "insta_kill_ug", "zombie_skull", &"ZOMBIE_POWERUP_INSTA_KILL", ::func_should_never_drop, 1, 0, 0, undefined, "powerup_instant_kill_ug", "zombie_powerup_insta_kill_ug_time", "zombie_powerup_insta_kill_ug_on", 5000 );
	}
	else if (getDvarInt("gamemode") == 2)
	{
		add_zombie_powerup( "nuke", "zombie_bomb", &"ZOMBIE_POWERUP_NUKE", ::func_should_never_drop, 0, 0, 0, "misc/fx_zombie_mini_nuke_hotness" );
		add_zombie_powerup( "insta_kill", "zombie_skull", &"ZOMBIE_POWERUP_INSTA_KILL", ::func_should_always_drop, 0, 0, 0, undefined, "powerup_instant_kill", "zombie_powerup_insta_kill_time", "zombie_powerup_insta_kill_on" );
		add_zombie_powerup( "full_ammo", "zombie_ammocan", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_always_drop, 0, 0, 0 );
		add_zombie_powerup( "double_points", "zombie_x2_icon", &"ZOMBIE_POWERUP_DOUBLE_POINTS", ::func_should_never_drop, 0, 0, 0, undefined, "powerup_double_points", "zombie_powerup_point_doubler_time", "zombie_powerup_point_doubler_on" );
		add_zombie_powerup( "carpenter", "zombie_carpenter", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 0 );
		add_zombie_powerup( "fire_sale", "zombie_firesale", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 0, undefined, "powerup_fire_sale", "zombie_powerup_fire_sale_time", "zombie_powerup_fire_sale_on" );
		add_zombie_powerup( "bonfire_sale", "zombie_pickup_bonfire", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 0, undefined, "powerup_bon_fire", "zombie_powerup_bonfire_sale_time", "zombie_powerup_bonfire_sale_on" );
		add_zombie_powerup( "minigun", "zombie_pickup_minigun", &"ZOMBIE_POWERUP_MINIGUN", ::func_should_never_drop, 1, 0, 0, undefined, "powerup_mini_gun", "zombie_powerup_minigun_time", "zombie_powerup_minigun_on" );
		add_zombie_powerup( "free_perk", "zombie_pickup_perk_bottle", &"ZOMBIE_POWERUP_FREE_PERK", ::func_should_never_drop, 0, 0, 0 );
		add_zombie_powerup( "tesla", "zombie_pickup_minigun", &"ZOMBIE_POWERUP_MINIGUN", ::func_should_never_drop, 1, 0, 0, undefined, "powerup_tesla", "zombie_powerup_tesla_time", "zombie_powerup_tesla_on" );
		add_zombie_powerup( "random_weapon", "zombie_pickup_minigun", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 1, 0, 0 );
		add_zombie_powerup( "bonus_points_player", "zombie_z_money_icon", &"ZOMBIE_POWERUP_BONUS_POINTS", ::func_should_never_drop, 1, 0, 0 );
		add_zombie_powerup( "bonus_points_team", "zombie_z_money_icon", &"ZOMBIE_POWERUP_BONUS_POINTS", ::func_should_never_drop, 0, 0, 0 );
		add_zombie_powerup( "lose_points_team", "zombie_z_money_icon", &"ZOMBIE_POWERUP_LOSE_POINTS", ::func_should_never_drop, 0, 0, 1 );
		add_zombie_powerup( "lose_perk", "zombie_pickup_perk_bottle", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 1 );
		add_zombie_powerup( "empty_clip", "zombie_ammocan", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_never_drop, 0, 0, 1 );
		add_zombie_powerup( "insta_kill_ug", "zombie_skull", &"ZOMBIE_POWERUP_INSTA_KILL", ::func_should_never_drop, 1, 0, 0, undefined, "powerup_instant_kill_ug", "zombie_powerup_insta_kill_ug_time", "zombie_powerup_insta_kill_ug_on", 5000 );
	}


    if ( isdefined( level.level_specific_init_powerups ) )
        [[ level.level_specific_init_powerups ]]();

    randomize_powerups();
    level.zombie_powerup_index = 0;
    randomize_powerups();
    level.rare_powerups_active = 0;
    level.firesale_vox_firstime = 0;
    level thread powerup_hud_monitor();

    if ( isdefined( level.quantum_bomb_register_result_func ) )
    {
        [[ level.quantum_bomb_register_result_func ]]( "random_powerup", ::quantum_bomb_random_powerup_result, 5, level.quantum_bomb_in_playable_area_validation_func );
        [[ level.quantum_bomb_register_result_func ]]( "random_zombie_grab_powerup", ::quantum_bomb_random_zombie_grab_powerup_result, 5, level.quantum_bomb_in_playable_area_validation_func );
        [[ level.quantum_bomb_register_result_func ]]( "random_weapon_powerup", ::quantum_bomb_random_weapon_powerup_result, 60, level.quantum_bomb_in_playable_area_validation_func );
        [[ level.quantum_bomb_register_result_func ]]( "random_bonus_or_lose_points_powerup", ::quantum_bomb_random_bonus_or_lose_points_powerup_result, 25, level.quantum_bomb_in_playable_area_validation_func );
    }

    registerclientfield( "scriptmover", "powerup_fx", 1000, 3, "int" );
}

kill_on_downed()
{
	for(;;)
	{
		self waittill ("player_downed");
		self thread bleed_out();
		self.isEliminated = 1;
		
		foreach (player in level.players)
		{
			player thread showBelowMessage(self.name + " has been eliminated!", "zmb_weap_wall");
		}
		
		if (if_all_players_eliminated())
		{
			level.winner = self.name;
			level notify ("end_game");
		}
	}
}

if_all_players_eliminated()
{
	count = 0;
	foreach (player in level.players)
	{
		if (player.isEliminated != 1)
		{
			count += 1;
		}
	}
	
	if (count == 1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

cranked_timer()
{
	self.seconds = level.maxtime;
	miliseconds = 10;
	while(self.timerstarted == 1 && self.seconds > 0)
	{
		if(self.timerpaused == 0)
		{
			self.seconds -= 1;
			miliseconds -= 1;
			if (miliseconds <= 0)
			{
				miliseconds = 10;
				if (self.seconds <= 100)
				{
					self thread red_glow(self.nametarget);
					self playsound ("zmb_box_poof");
				}
			}
		}
		wait 0.1;
	}
	if(level.players.size == 1)
	{
		level.winner = self.name;
	}
	self dodamage(self.health, self.origin);
}

maintain_zombie_count()
{
	while(1)
	{
		level.zombie_total = 40;
		wait 1;
	}
}

red_glow(elem)
{
	self endon("reset_glow");
	colornum = 0;
	while (colornum < 1)
	{
		elem.color = ( 1, colornum, colornum );
		colornum += 0.05;
		wait 0.01;
	}
}

green_glow(elem)
{
	self endon("reset_glow");
	colornum = 0;
	while (colornum < 1)
	{
		elem.color = ( colornum, 1, colornum );
		colornum += 0.05;
		wait 0.01;
	}
}


///////////////////////////////////////////////////
//
//
//
//			[Gamemode Specific Powerups]
//
//
//
//////////////////////////////////////////////////


new_treasure_chest_init( start_chest_name )
{

}

new_weapon_spawn_think()
{

}

new_vending_weapon_upgrade()
{

}

actor_killed_override( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime )
{
	if ( game["state"] == "postgame" )
		return;

	if ( isai( attacker ) && isdefined( attacker.script_owner ) )
	{
		if ( attacker.script_owner.team != self.aiteam )
			attacker = attacker.script_owner;
	}

	if ( attacker.classname == "script_vehicle" && isdefined( attacker.owner ) )
		attacker = attacker.owner;

	if ( isdefined( attacker ) && isplayer( attacker ) )
	{
		multiplier = 1;

		if ( is_headshot( sweapon, shitloc, smeansofdeath ) )
			multiplier = 1.5;

		type = undefined;

		if ( isdefined( self.animname ) )
		{
			switch ( self.animname )
			{
				case "quad_zombie":
					type = "quadkill";
					break;
				case "ape_zombie":
					type = "apekill";
					break;
				case "zombie":
					type = "zombiekill";
					break;
				case "zombie_dog":
					type = "dogkill";
				break;
			}
		}

		if (getDvarInt("gamemode") == 1)
		{
			if (attacker.weaponprog >= attacker.progmax - 1)
			{
				attacker.weaponprog = 0;
				attacker changeweapon(false);
//				attacker.progmax = (attacker.weaponlevel * 2);
				attacker.progmax = 8;
			}
			else
			{
				attacker.weaponprog += 1;
			}
			level.zombie_total = 50;
			level.zombieskilled += 1;
			if (level.zombieskilled == 20)
			{
				level.zombieskilled = 0;
				level notify ("force_next_round");
			}
		}
		else if (getDvarInt("gamemode") == 2)
		{
			if (attacker.timerstarted == 0)
			{
				attacker.timerstarted = 1;
				attacker thread cranked_timer();
				attacker thread showBelowMessage("Let the carnage begin!", "zmb_weap_wall");
			}
			else
			{
				if (attacker.seconds < level.maxtime)
				{
					attacker.seconds = level.maxtime;
				}
			}
			attacker notify("reset_glow");
			attacker thread green_glow(attacker.nametarget);
		}

    }

	if ( isdefined( self.is_ziplining ) && self.is_ziplining )
		self.deathanim = undefined;

	if ( isdefined( self.actor_killed_override ) )
		self [[ self.actor_killed_override ]]( einflictor, attacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime );
}


createlist()
{
	level.weaponlist = [];
	
	list = [];
	
	if(getDvar("mapname") == "zm_tomb")
	{
		starter = "c96_zm";
	}
	else
	{
		starter = "m1911_zm";
	}
	
	level.weaponlist[level.weaponlist.size] = starter;
	
	if (getDvarInt("gungame_ladder") == 1 || getDvarInt("gungame_ladder") == 3)
	{
		if ( maps\mp\zombies\_zm_weapons::can_upgrade_weapon( starter ) )
		{
			level.weaponlist[level.weaponlist.size] = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( starter, false );
		}
	}
	
	foreach (guns in level.zombie_weapons)
	{
		if (isGun(guns.weapon_name))
		{
			list[list.size] = guns.weapon_name;
			
			if (getDvarInt("gungame_ladder") == 1 || getDvarInt("gungame_ladder") == 3)
			{
				if ( maps\mp\zombies\_zm_weapons::can_upgrade_weapon( guns.weapon_name ) )
				{
					list[list.size] = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( guns.weapon_name, false );
				}
			}
		}
	}
	
	if (getDvarInt("gungame_ladder") == 2 || getDvarInt("gungame_ladder") == 3)
	{
		list = array_randomize(list);
	}
	level.weaponlist = arraycombine(level.weaponlist, list, 1, 0);
	
}

isGun(gun)
{
	blockedguns = array("frag_grenade_zm", "sticky_grenade_zm", "claymore_zm", "cymbal_monkey_zm", "emp_grenade_zm", "knife_ballistic_no_melee_zm", "knife_ballistic_bowie_zm", "knife_ballistic_zm", "riotshield_zm", "jetgun_zm", "tazer_knuckles_zm", "time_bomb_zm", "tomb_shield_zm", "staff_air_zm", "staff_air_upgraded2_zm", "staff_air_upgraded3_zm", "staff_air_upgraded_zm", "staff_fire_zm", "staff_fire_upgraded_zm", "staff_fire_upgraded2_zm", "staff_fire_upgraded3_zm", "staff_lightning_zm", "staff_lightning_upgraded_zm", "staff_lightning2_upgraded_zm", "staff_lightning3_upgraded_zm", "staff_water_zm", "staff_water_zm_cheap", "staff_water_upgraded_zm", "staff_water_upgraded2_zm", "staff_water_upgraded3_zm", "staff_revive_zm", "beacon_zm", "claymore_zm");
	blockedguns2 = array("bouncing_tomahawk_zm", "upgraded_tomahawk_zm", "alcatraz_shield_zm", "tower_trap_zm", "tower_trap_upgraded_zm", "knife_zm", "knife_zm_alcatraz", "spoon_zm_alcatraz", "spork_zm_alcatraz", "frag_grenade_zm", "claymore_zm", "willy_pete_zm", "c96_zm", "m1911_zm");
	foreach (blocked in blockedguns)
	{
		if (gun == blocked)
		{
			return 0;
		}
	}
	foreach (blocked in blockedguns2)
	{
		if (gun == blocked)
		{
			return 0;
		}
	}
	return 1;
}

changeweapon(demoted)
{
	primaries = self getweaponslistprimaries();
	
	foreach (weapon in primaries)
	{
		self takeweapon(weapon);
	}
	
	if (self.weaponlevel >= (level.weaponlist.size - 1))
	{
		level.winner = self.name;
		level notify( "end_game" );
	}
	
	if (self.weaponlevel >= 0)
	{
	
	}

	if (demoted == 1)
	{
		if(self.weaponlevel != 0)
		{
			self.weaponlevel -= 1;
			self playsound ("zmb_cha_ching");
		}
	}
	else
	{
		self.weaponlevel += 1;
		self playsound ("zmb_cha_ching");
	}
	
	self GiveWeapon(level.weaponlist[self.weaponlevel]);
	self SetSpawnWeapon(level.weaponlist[self.weaponlevel]);
}

gungameHUD()
{
//	level endon("end_game");
	self endon( "disconnect" );
	
	nametext = newClientHudElem(self);
	nametext.alignx = "center";
	nametext.aligny = "bottom";
	nametext.horzalign = "user_center";
	nametext.vertalign = "user_bottom";
	nametext.x -= 80;
	nametext.y -= 40;
	nametext.fontscale = 1;
	nametext.alpha = 1;
	nametext.color = ( 1, 1, 1 );
	nametext.hidewheninmenu = 1;
	nametext.foreground = 1;
	nametext.label = &"Weapons left: ^6";
	
	nametarget = newClientHudElem(self);
	nametarget.alignx = "center";
	nametarget.aligny = "bottom";
	nametarget.horzalign = "user_center";
	nametarget.vertalign = "user_bottom";
	nametarget.x += 80;
	nametarget.y -= 40;
	nametarget.fontscale = 1;
	nametarget.alpha = 1;
	nametarget.color = ( 1, 1, 1 );
	nametarget.hidewheninmenu = 1;
	nametarget.foreground = 1;
	nametarget.label = &"Kills Left: ^6";
	
	while(1)
	{
		nametext setValue (level.weaponlist.size - self.weaponlevel);
		nametarget setValue (self.progmax - self.weaponprog);
		wait 0.1;
	}

}

crankedHUD()
{
	level endon("end_game");
	self endon( "disconnect" );
	
	self.nametext = newClientHudElem(self);
	self.nametext.alignx = "left";
	self.nametext.aligny = "center";
	self.nametext.horzalign = "user_left";
	self.nametext.vertalign = "user_center";
	self.nametext.x = 8;
	self.nametext.y = 0;
	self.nametext.fontscale = 2;
	self.nametext.alpha = 1;
	self.nametext.color = ( 1, 1, 1 );
	self.nametext.hidewheninmenu = 1;
	self.nametext.foreground = 1;
	self.nametext setText ("Cranked!");
	
	self.nametarget = newClientHudElem(self);
	self.nametarget.alignx = "left";
	self.nametarget.aligny = "center";
	self.nametarget.horzalign = "user_left";
	self.nametarget.vertalign = "user_center";
	self.nametarget.x = 8;
	self.nametarget.y += 16;
	self.nametarget.fontscale = 3;
	self.nametarget.alpha = 1;
	self.nametarget.color = ( 1, 1, 1 );
	self.nametarget.hidewheninmenu = 1;
	self.nametarget.foreground = 1;
	self.nametarget.label = &"";
//	self.nametarget setText(self.seconds + ":" + self.miliseconds);
	
	while(1)
	{
		self.nametarget setValue (self.seconds/10);
		wait 0.01;
	}

}

get_remaining_player()
{
	foreach (player in level.players)
	{
		if (isAlive(player))
		{
			count += 1;
			ref = player;
		}
	}
	if (count == 1)
	{
		return ref;
	}
	else
	{
		return;
	}
}

loopmaxammo()
{
    while(1)
	{
		if ( self hasweapon( self getcurrentweapon() ) )
			self givemaxammo( self getcurrentweapon() );
		wait 0.1;
	}
}

showBelowMessage(text, sound)
{	
	if(isDefined(self.belowMSD))
	{
		return;
	}
	else
	{
	
		if(isDefined(sound))
			self playsound(sound);

	
		self.belowMSG = newclienthudelem( self );
		self.belowMSG.alignx = "center";
		self.belowMSG.aligny = "bottom";
		self.belowMSG.horzalign = "center";
		self.belowMSG.vertalign = "bottom";
		self.belowMSG.y -= 10;
    
		self.belowMSG.foreground = 1;
		self.belowMSG.fontscale = 4;
		self.belowMSG.alpha = 0;
		self.belowMSG.hidewheninmenu = 1;
		self.belowMSG.font = "default";

		self.belowMSG settext( text );
		self.belowMSG.color = ( 1, 1, 1 );

		self.belowMSG changefontscaleovertime( 0.25 );
		self.belowMSG fadeovertime( 0.25 );
		self.belowMSG.alpha = 1;
		self.belowMSG.fontscale = 2;
    
		wait 3;
    
		self.belowMSG changefontscaleovertime( 0.25 );
		self.belowMSG fadeovertime( 0.25 );
		self.belowMSG.alpha = 0;
		self.belowMSG.fontscale = 4;
		wait 1.1;
		self.belowMSG destroy();
	}
}

init_audio_announcer()
{
    game["zmbdialog"] = [];
    game["zmbdialog"]["prefix"] = "vox_zmba";
    createvox( "boxmove", "event_magicbox" );
    createvox( "dogstart", "event_dogstart" );
    thread init_gamemodespecificvox( getdvar( #"ui_gametype" ), getdvar( #"ui_zm_mapstartlocation" ) );
    level.allowzmbannouncer = 1;
}

powerup_grab_gungame( powerup_team )
{
    if ( isdefined( self ) && self.zombie_grabbable )
    {
        self thread powerup_zombie_grab( powerup_team );
        return;
    }

    self endon( "powerup_timedout" );
    self endon( "powerup_grabbed" );
    range_squared = 4096;

    while ( isdefined( self ) )
    {
        players = get_players();

        for ( i = 0; i < players.size; i++ )
        {
            if ( ( self.powerup_name == "minigun" || self.powerup_name == "tesla" || self.powerup_name == "random_weapon" || self.powerup_name == "meat_stink" ) && ( players[i] maps\mp\zombies\_zm_laststand::player_is_in_laststand() || players[i] usebuttonpressed() && players[i] in_revive_trigger() ) )
                continue;

            if ( isdefined( self.can_pick_up_in_last_stand ) && !self.can_pick_up_in_last_stand && players[i] maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
                continue;

            ignore_range = 0;

            if ( isdefined( players[i].ignore_range_powerup ) && players[i].ignore_range_powerup == self )
            {
                players[i].ignore_range_powerup = undefined;
                ignore_range = 1;
            }

            if ( distancesquared( players[i].origin, self.origin ) < range_squared || ignore_range )
            {
                if ( isdefined( level._powerup_grab_check ) )
                {
                    if ( !self [[ level._powerup_grab_check ]]( players[i] ) )
                        continue;
                }

                if ( isdefined( level.zombie_powerup_grab_func ) )
                    level thread [[ level.zombie_powerup_grab_func ]]();
                else
                {
                    switch ( self.powerup_name )
                    {
                        case "nuke":
                            level thread nuke_powerup( self, players[i].team );
                            players[i] thread powerup_vo( "nuke" );
                            zombies = getaiarray( level.zombie_team );
                            players[i].zombie_nuked = arraysort( zombies, self.origin );
                            players[i] notify( "nuke_triggered" );
                            break;
                        case "full_ammo":
                            level thread full_ammo_powerup( self, players[i] );
                            players[i] thread powerup_vo( "full_ammo" );
                            break;
                        case "double_points":
                            level thread double_points_powerup( self, players[i] );
                            players[i] thread powerup_vo( "double_points" );
                            break;
                        case "insta_kill":
                            level thread insta_kill_powerup( self, players[i] );
                            players[i] thread powerup_vo( "insta_kill" );
                            break;
                        case "carpenter":
                            if ( is_classic() )
                                players[i] thread maps\mp\zombies\_zm_pers_upgrades::persistent_carpenter_ability_check();

                            if ( isdefined( level.use_new_carpenter_func ) )
                                level thread [[ level.use_new_carpenter_func ]]( self.origin);
                            else
                                players[i] thread start_carpenter(self.origin);

                            players[i] thread powerup_vo( "carpenter" );
                            break;
                        case "fire_sale":
                            level thread start_fire_sale( self );
                            players[i] thread powerup_vo( "firesale" );
                            break;
                        case "bonfire_sale":
                            level thread start_bonfire_sale( self );
                            players[i] thread powerup_vo( "firesale" );
                            break;
                        case "minigun":
                            level thread minigun_weapon_powerup( players[i] );
                            players[i] thread powerup_vo( "minigun" );
                            break;
                        case "free_perk":
                            level thread free_perk_powerup( self );
                            break;
                        case "tesla":
                            level thread tesla_weapon_powerup( players[i] );
                            players[i] thread powerup_vo( "tesla" );
                            break;
                        case "random_weapon":
                            if ( !level random_weapon_powerup( self, players[i] ) )
                                continue;

                            break;
                        case "bonus_points_player":
                            level thread bonus_points_player_powerup( self, players[i] );
                            players[i] thread powerup_vo( "bonus_points_solo" );
                            break;
                        case "bonus_points_team":
                            level thread bonus_points_team_powerup( self );
                            players[i] thread powerup_vo( "bonus_points_team" );
                            break;
                        case "teller_withdrawl":
                            level thread teller_withdrawl( self, players[i] );
                            break;
                        default:
                            if ( isdefined( level._zombiemode_powerup_grab ) )
                                level thread [[ level._zombiemode_powerup_grab ]]( self, players[i] );
                            else
                            {
/#
                                println( "Unrecognized poweup." );
#/
                            }

                            break;
                    }
                }

                maps\mp\_demo::bookmark( "zm_player_powerup_grabbed", gettime(), players[i] );

                if ( should_award_stat( self.powerup_name ) )
                {
                    players[i] maps\mp\zombies\_zm_stats::increment_client_stat( "drops" );
                    players[i] maps\mp\zombies\_zm_stats::increment_player_stat( "drops" );
                    players[i] maps\mp\zombies\_zm_stats::increment_client_stat( self.powerup_name + "_pickedup" );
                    players[i] maps\mp\zombies\_zm_stats::increment_player_stat( self.powerup_name + "_pickedup" );
                }

                if ( self.solo )
                {
                    playfx( level._effect["powerup_grabbed_solo"], self.origin );
                    playfx( level._effect["powerup_grabbed_wave_solo"], self.origin );
                }
                else if ( self.caution )
                {
                    playfx( level._effect["powerup_grabbed_caution"], self.origin );
                    playfx( level._effect["powerup_grabbed_wave_caution"], self.origin );
                }
                else
                {
                    playfx( level._effect["powerup_grabbed"], self.origin );
                    playfx( level._effect["powerup_grabbed_wave"], self.origin );
                }

                if ( isdefined( self.stolen ) && self.stolen )
                    level notify( "monkey_see_monkey_dont_achieved" );

                if ( isdefined( self.grabbed_level_notify ) )
                    level notify( self.grabbed_level_notify );

                self.claimed = 1;
                self.power_up_grab_player = players[i];
                wait 0.1;
                playsoundatposition( "zmb_powerup_grabbed", self.origin );
                self stoploopsound();
                self hide();

                if ( self.powerup_name != "fire_sale" )
                {
                    if ( isdefined( self.power_up_grab_player ) )
                    {
                        if ( isdefined( level.powerup_intro_vox ) )
                        {
                            level thread [[ level.powerup_intro_vox ]]( self );
                            return;
                        }
                        else if ( isdefined( level.powerup_vo_available ) )
                        {
                            can_say_vo = [[ level.powerup_vo_available ]]();

                            if ( !can_say_vo )
                            {
                                self powerup_delete();
                                self notify( "powerup_grabbed" );
                                return;
                            }
                        }
                    }
                }

                level thread maps\mp\zombies\_zm_audio_announcer::leaderdialog( self.powerup_name, self.power_up_grab_player.pers["team"] );
                self powerup_delete();
                self notify( "powerup_grabbed" );
            }
        }

        wait 0.1;
    }
}

end_game_minigame()
{
    level waittill( "end_game" );
	
	if(getDvarInt("gamemode") == 2)
	{
		level.winner = get_remaining_player().name;
	}
	
    check_end_game_intermission_delay();
/#
    println( "end_game TRIGGERED " );
#/
    clientnotify( "zesn" );

    if ( isdefined( level.sndgameovermusicoverride ) )
        level thread maps\mp\zombies\_zm_audio::change_zombie_music( level.sndgameovermusicoverride );
    else
        level thread maps\mp\zombies\_zm_audio::change_zombie_music( "game_over" );

    players = get_players();

    for ( i = 0; i < players.size; i++ )
        setclientsysstate( "lsm", "0", players[i] );

    for ( i = 0; i < players.size; i++ )
    {
        if ( players[i] player_is_in_laststand() )
        {
            players[i] recordplayerdeathzombies();
            players[i] maps\mp\zombies\_zm_stats::increment_player_stat( "deaths" );
            players[i] maps\mp\zombies\_zm_stats::increment_client_stat( "deaths" );
            players[i] maps\mp\zombies\_zm_pers_upgrades_functions::pers_upgrade_jugg_player_death_stat();
        }

        if ( isdefined( players[i].revivetexthud ) )
            players[i].revivetexthud destroy();
    }

    stopallrumbles();
    level.intermission = 1;
    level.zombie_vars["zombie_powerup_insta_kill_time"] = 0;
    level.zombie_vars["zombie_powerup_fire_sale_time"] = 0;
    level.zombie_vars["zombie_powerup_point_doubler_time"] = 0;
    wait 0.1;
    game_over = [];
    survived = [];
    players = get_players();
    setmatchflag( "disableIngameMenu", 1 );

    foreach ( player in players )
    {
        player closemenu();
        player closeingamemenu();
    }

    if ( !isdefined( level._supress_survived_screen ) )
    {
        for ( i = 0; i < players.size; i++ )
        {
            if ( isdefined( level.custom_game_over_hud_elem ) )
                game_over[i] = [[ level.custom_game_over_hud_elem ]]( players[i] );
            else
            {
                game_over[i] = newclienthudelem( players[i] );
                game_over[i].alignx = "center";
                game_over[i].aligny = "middle";
                game_over[i].horzalign = "center";
                game_over[i].vertalign = "middle";
                game_over[i].y = game_over[i].y - 130;
                game_over[i].foreground = 1;
                game_over[i].fontscale = 3;
                game_over[i].alpha = 0;
                game_over[i].color = ( 1, 1, 1 );
                game_over[i].hidewheninmenu = 1;
				if (isDefined(level.winner))
				{
					game_over[i] settext( level.winner + " wins!" );
				}
				else
				{
					game_over[i] settext( "Nobody Wins!" );
				}
                game_over[i] fadeovertime( 1 );
                game_over[i].alpha = 1;

                if ( players[i] issplitscreen() )
                {
                    game_over[i].fontscale = 2;
                    game_over[i].y = game_over[i].y + 40;
                }
            }

            survived[i] = newclienthudelem( players[i] );
            survived[i].alignx = "center";
            survived[i].aligny = "middle";
            survived[i].horzalign = "center";
            survived[i].vertalign = "middle";
            survived[i].y = survived[i].y - 100;
            survived[i].foreground = 1;
            survived[i].fontscale = 2;
            survived[i].alpha = 0;
            survived[i].color = ( 1, 1, 1 );
            survived[i].hidewheninmenu = 1;

            if ( players[i] issplitscreen() )
            {
                survived[i].fontscale = 1.5;
                survived[i].y = survived[i].y + 40;
            }

            if ( level.round_number < 2 )
            {
                if ( level.script == "zombie_moon" )
                {
                    if ( !isdefined( level.left_nomans_land ) )
                    {
                        nomanslandtime = level.nml_best_time;
                        player_survival_time = int( nomanslandtime / 1000 );
                        player_survival_time_in_mins = maps\mp\zombies\_zm::to_mins( player_survival_time );
                        survived[i] settext( &"ZOMBIE_SURVIVED_NOMANS", player_survival_time_in_mins );
                    }
                    else if ( level.left_nomans_land == 2 )
                        survived[i] settext( &"ZOMBIE_SURVIVED_ROUND" );
                }
                else
                    survived[i] settext( "Match has ended" );
            }
            else
                if (isDefined(level.winner))
				{
					survived[i] settext( "Your Score: " + players[i].weaponlevel );
				}
				else
				{
					survived[i] settext( "Match has ended" );
				}

            survived[i] fadeovertime( 1 );
            survived[i].alpha = 1;
        }
    }

    if ( isdefined( level.custom_end_screen ) )
        level [[ level.custom_end_screen ]]();

    for ( i = 0; i < players.size; i++ )
    {
        players[i] setclientammocounterhide( 1 );
        players[i] setclientminiscoreboardhide( 1 );
    }

    uploadstats();
    maps\mp\zombies\_zm_stats::update_players_stats_at_match_end( players );
    maps\mp\zombies\_zm_stats::update_global_counters_on_match_end();
    wait 1;
    wait 3.95;
    players = get_players();

    foreach ( player in players )
    {
        if ( isdefined( player.sessionstate ) && player.sessionstate == "spectator" )
            player.sessionstate = "playing";
    }

    wait 0.05;
    players = get_players();

    if ( !isdefined( level._supress_survived_screen ) )
    {
        for ( i = 0; i < players.size; i++ )
        {
            survived[i] destroy();
            game_over[i] destroy();
        }
    }
    else
    {
        for ( i = 0; i < players.size; i++ )
        {
            if ( isdefined( players[i].survived_hud ) )
                players[i].survived_hud destroy();

            if ( isdefined( players[i].game_over_hud ) )
                players[i].game_over_hud destroy();
        }
    }

    intermission();
    wait( level.zombie_vars["zombie_intermission_time"] );
    level notify( "stop_intermission" );
    array_thread( get_players(), ::player_exit_level );
    bbprint( "zombie_epilogs", "rounds %d", level.round_number );
    wait 1.5;
    players = get_players();

    for ( i = 0; i < players.size; i++ )
        players[i] cameraactivate( 0 );

    exitlevel( 0 );
    wait 666;
}

round_think_minigame( restart )
{
	if(level.gungamestarted == 0 || level.crankedstarted == 0 || level.mysterygunsstarted == 0)
	{
		level waittill ("end");
	}
	
	if ( !isdefined( restart ) )
        restart = 0;

/#
    println( "ZM >> round_think start" );
#/
    level endon( "end_round_think" );

    if ( !( isdefined( restart ) && restart ) )
    {
        if ( isdefined( level.initial_round_wait_func ) )
            [[ level.initial_round_wait_func ]]();

        if ( !( isdefined( level.host_ended_game ) && level.host_ended_game ) )
        {
            players = get_players();

            foreach ( player in players )
            {
                if ( !( isdefined( player.hostmigrationcontrolsfrozen ) && player.hostmigrationcontrolsfrozen ) )
                {
                    player freezecontrols( 0 );
/#
                    println( " Unfreeze controls 8" );
#/
                }

                player maps\mp\zombies\_zm_stats::set_global_stat( "rounds", level.round_number );
            }
        }
    }

    setroundsplayed( level.round_number );

    for (;;)
    {
        maxreward = 50 * level.round_number;

        if ( maxreward > 500 )
            maxreward = 500;

        level.zombie_vars["rebuild_barrier_cap_per_round"] = maxreward;
        level.pro_tips_start_time = gettime();
        level.zombie_last_run_time = gettime();

        if ( isdefined( level.zombie_round_change_custom ) )
            [[ level.zombie_round_change_custom ]]();
        else
        {
            level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_start" );
            round_one_up();
        }

        maps\mp\zombies\_zm_powerups::powerup_round_start();
        players = get_players();
        array_thread( players, maps\mp\zombies\_zm_blockers::rebuild_barrier_reward_reset );

        if ( !( isdefined( level.headshots_only ) && level.headshots_only ) && !restart )
            level thread award_grenades_for_survivors();

        bbprint( "zombie_rounds", "round %d player_count %d", level.round_number, players.size );
/#
        println( "ZM >> round_think, round=" + level.round_number + ", player_count=" + players.size );
#/
        level.round_start_time = gettime();

        while ( level.zombie_spawn_locations.size <= 0 )
            wait 0.1;

        level thread [[ level.round_spawn_func ]]();
        level notify( "start_of_round" );
        recordzombieroundstart();
        players = getplayers();

        for ( index = 0; index < players.size; index++ )
        {
            zonename = players[index] get_current_zone();

            if ( isdefined( zonename ) )
                players[index] recordzombiezone( "startingZone", zonename );
        }

        if ( isdefined( level.round_start_custom_func ) )
            [[ level.round_start_custom_func ]]();

        [[ level.round_wait_func ]]();
        level.first_round = 0;
        level notify( "end_of_round" );
		if (getDvarInt("gamemode") == 3)
		{
			level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_end" );
		}
		level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_start" );
        uploadstats();

        if ( isdefined( level.round_end_custom_logic ) )
            [[ level.round_end_custom_logic ]]();

        players = get_players();

        if ( isdefined( level.no_end_game_check ) && level.no_end_game_check )
        {
            level thread last_stand_revive();
			if (getDvarInt("gamemode") == 2)
			{
				level thread spectators_respawn();
			}
        }
//        else if ( 1 != players.size )
//            level thread spectators_respawn();

        players = get_players();
        array_thread( players, maps\mp\zombies\_zm_pers_upgrades_system::round_end );
        timer = level.zombie_vars["zombie_spawn_delay"];

        if ( timer > 0.08 )
            level.zombie_vars["zombie_spawn_delay"] = timer * 0.95;
        else if ( timer < 0.08 )
            level.zombie_vars["zombie_spawn_delay"] = 0.08;

        if ( level.gamedifficulty == 0 )
            level.zombie_move_speed = level.round_number * level.zombie_vars["zombie_move_speed_multiplier_easy"];
        else
            level.zombie_move_speed = level.round_number * level.zombie_vars["zombie_move_speed_multiplier"];

        level.round_number++;

        if ( 255 < level.round_number )
            level.round_number = 255;

        setroundsplayed( level.round_number );
        matchutctime = getutc();
        players = get_players();

        foreach ( player in players )
        {
            if ( level.curr_gametype_affects_rank && level.round_number > 3 + level.start_round )
                player maps\mp\zombies\_zm_stats::add_client_stat( "weighted_rounds_played", level.round_number );

            player maps\mp\zombies\_zm_stats::set_global_stat( "rounds", level.round_number );
            player maps\mp\zombies\_zm_stats::update_playing_utc_time( matchutctime );
        }

        check_quickrevive_for_hotjoin();
        level round_over();
        level notify( "between_round_over" );
        restart = 0;
    }
}

wait_for_ready_input()
{
	level endon ("end");
	level.introHUD setText ("Press [{+melee}] and [{+speed_throw}] to ready up!: ^5" + level.playersready + "/" + level.players.size);
	if (!isDefined(self.bot))
	{
		self waittill ("can_readyup");
	}
	while(1)
	{
		if((self meleebuttonpressed() && self adsbuttonpressed()) || (isDefined(self.bot)))
		{
			if (self.voted == 0)
			{
				level.playersready += 1;
				self.voted = 1;
				level.introHUD setText ("Press [{+melee}] and [{+speed_throw}] to ready up!: ^5" + level.playersready + "/" + level.players.size);
				if (level.playersready == level.players.size)
				{
					wait 1;
					if (getDvarInt("gamemode") == 1)
					{
						level.gungamestarted = 1;
					}
					else if (getDvarInt("gamemode") == 2)
					{
						level.crankedstarted = 1;					
					}
					else if (getDvarInt("gamemode") == 3)
					{
						level.mysterygunsstarted = 1;
					}
					level thread minigames_timer_hud();
					foreach (player in level.players)
					{
						player disableInvulnerability();
					}
					level notify ("end");
				}
			}
		}
		wait 0.01;
	}
}

introHUD()
{
	flag_wait( "initial_blackscreen_passed" );
	level.introHUD = newhudelem();
	level.introHUD.x = 0;
	level.introHUD.y -= 20;
	level.introHUD.alpha = 1;
	level.introHUD.alignx = "center";
	level.introHUD.aligny = "bottom";
    level.introHUD.horzalign = "user_center";
    level.introHUD.vertalign = "user_bottom";
	level.introHUD.foreground = 0;
	level.introHUD.fontscale = 1.5;
	level.introHUD setText ("Press [{+melee}] and [{+speed_throw}] to ready up!: ^5" + level.playersready + "/" + level.players.size);
	level waittill ("end");
	level.introHUD fadeovertime( 0.25 );
	level.introHUD.alpha = 0;
	level.introHUD destroy();
}

playerScoresHUD(index, ref)
{
	y = (index * 24) + -120;
	
	namebg = newhudelem();;
	namebg.alignx = "left";
	namebg.aligny = "center";
	namebg.horzalign = "user_left";
	namebg.vertalign = "user_center";
	namebg.x -= 10;
	namebg.y += y - 4;
	namebg.fontscale = 2;
	namebg.alpha = 0;
	namebg.color = ( 1, 1, 0 );
	namebg.hidewheninmenu = 1;
	namebg.foreground = 0;
	namebg setShader("scorebar_zom_1", 124, 32);

	nameHUD = newhudelem();;
	nameHUD.x = 10;
	nameHUD.y += y;
	nameHUD.alpha = 0;
	nameHUD.alignx = "left";
	nameHUD.aligny = "center";
	nameHUD.horzalign = "user_left";
	nameHUD.vertalign = "user_center";
	nameHUD.fontscale = 0;
	nameHUD.foreground = 0;
	nameHUD setText (ref.name);

	scoreHUD = newhudelem();;
	scoreHUD.x = 10;
	scoreHUD.y = nameHUD.y + 10;
	scoreHUD.alpha = 0;
	scoreHUD.alignx = "left";
	scoreHUD.aligny = "center";
	scoreHUD.horzalign = "user_left";
	scoreHUD.vertalign = "user_center";
	scoreHUD.fontscale = 0;
	scoreHUD.foreground = 0;
	scoreHUD.label = ("");
	
	while(1)
	{
		ref = level.players[index];
		scoreHUD setValue (ref.weaponlevel);
		
		if(ref != oldref)
		{
			nameHUD setText (ref.name);
			oldref = ref;
		}

		if ( (ref.weaponlevel == level.weaponlist.size - 1) && isDefined(level.players[index]))
		{
			namebg.alpha = 1;
		}
		else
		{
			namebg.alpha = 0;
		}
		
		if (level.gungamestarted == 0)
		{
			scoreHUD.alpha = 0;
			nameHUD.alpha = 0;
		}
		else
		{
			if (isDefined(level.players[index]))
			{
				scoreHUD.alpha = 1;
				nameHUD.alpha = 1;
			}
			else
			{
				scoreHUD.alpha = 0;
				nameHUD.alpha = 0;
			}
		}
		wait 0.1;
	}
}

auto_revive_gungame( reviver, dont_enable_weapons )
{
    if ( isdefined( self.revivetrigger ) )
    {
        self.revivetrigger.auto_revive = 1;

        if ( self.revivetrigger.beingrevived == 1 )
        {
            while ( true )
            {
                if ( self.revivetrigger.beingrevived == 0 )
                    break;

                wait_network_frame();
            }
        }

        self.revivetrigger.auto_trigger = 0;
    }

    self reviveplayer();
    self maps\mp\zombies\_zm_perks::perk_set_max_health_if_jugg( "health_reboot", 1, 0 );
    setclientsysstate( "lsm", "0", self );
    self notify( "stop_revive_trigger" );

    if ( isdefined( self.revivetrigger ) )
    {
        self.revivetrigger delete();
        self.revivetrigger = undefined;
    }

    self cleanup_suicide_hud();

    if ( !isdefined( dont_enable_weapons ) || dont_enable_weapons == 0 )
        self laststand_enable_player_weapons();

    self allowjump( 1 );
    self.laststand = undefined;

    if ( !( isdefined( level.isresetting_grief ) && level.isresetting_grief ) )
    {
        reviver.revives++;
        reviver maps\mp\zombies\_zm_stats::increment_client_stat( "revives" );
        reviver maps\mp\zombies\_zm_stats::increment_player_stat( "revives" );
        self recordplayerrevivezombies( reviver );
        maps\mp\_demo::bookmark( "zm_player_revived", gettime(), self, reviver );
    }

    self notify( "player_revived", reviver );
	self changeweapon(true);
	
	wait 5;
	
	self.ignoreme = 0;
}

player_damage_override_gungame( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime )
{
    if ( isdefined( level._game_module_player_damage_callback ) )
        self [[ level._game_module_player_damage_callback ]]( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime );

    idamage = self check_player_damage_callbacks( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime );

    if ( isdefined( self.use_adjusted_grenade_damage ) && self.use_adjusted_grenade_damage )
    {
        self.use_adjusted_grenade_damage = undefined;

        if ( self.health > idamage )
            return idamage;
    }

    if ( !idamage )
        return 0;

    if ( self maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
        return 0;

    if ( isdefined( einflictor ) )
    {
        if ( isdefined( einflictor.water_damage ) && einflictor.water_damage )
            return 0;
    }

    if ( isdefined( eattacker ) && ( isdefined( eattacker.is_zombie ) && eattacker.is_zombie || isplayer( eattacker ) ) )
    {
        if ( isdefined( self.hasriotshield ) && self.hasriotshield && isdefined( vdir ) )
        {
            if ( isdefined( self.hasriotshieldequipped ) && self.hasriotshieldequipped )
            {
                if ( self player_shield_facing_attacker( vdir, 0.2 ) && isdefined( self.player_shield_apply_damage ) )
                {
                    self [[ self.player_shield_apply_damage ]]( 100, 0 );
                    return 0;
                }
            }
            else if ( !isdefined( self.riotshieldentity ) )
            {
                if ( !self player_shield_facing_attacker( vdir, -0.2 ) && isdefined( self.player_shield_apply_damage ) )
                {
                    self [[ self.player_shield_apply_damage ]]( 100, 0 );
                    return 0;
                }
            }
        }
    }

    if ( isdefined( eattacker ) )
    {
        if ( isdefined( self.ignoreattacker ) && self.ignoreattacker == eattacker )
            return 0;

        if ( isdefined( self.is_zombie ) && self.is_zombie && ( isdefined( eattacker.is_zombie ) && eattacker.is_zombie ) )
            return 0;

        if ( isdefined( eattacker.is_zombie ) && eattacker.is_zombie )
        {
            self.ignoreattacker = eattacker;
            self thread remove_ignore_attacker();

            if ( isdefined( eattacker.custom_damage_func ) )
                idamage = eattacker [[ eattacker.custom_damage_func ]]( self );
            else if ( isdefined( eattacker.meleedamage ) )
                idamage = eattacker.meleedamage;
            else
                idamage = 50;
        }

        eattacker notify( "hit_player" );

        if ( smeansofdeath != "MOD_FALLING" )
        {
            self thread playswipesound( smeansofdeath, eattacker );

            if ( isdefined( eattacker.is_zombie ) && eattacker.is_zombie || isplayer( eattacker ) )
                self playrumbleonentity( "damage_heavy" );

            canexert = 1;

            if ( isdefined( level.pers_upgrade_flopper ) && level.pers_upgrade_flopper )
            {
                if ( isdefined( self.pers_upgrades_awarded["flopper"] ) && self.pers_upgrades_awarded["flopper"] )
                    canexert = smeansofdeath != "MOD_PROJECTILE_SPLASH" && smeansofdeath != "MOD_GRENADE" && smeansofdeath != "MOD_GRENADE_SPLASH";
            }

            if ( isdefined( canexert ) && canexert )
            {
                if ( randomintrange( 0, 1 ) == 0 )
                    self thread maps\mp\zombies\_zm_audio::playerexert( "hitmed" );
                else
                    self thread maps\mp\zombies\_zm_audio::playerexert( "hitlrg" );
            }
        }
    }

    finaldamage = idamage;

    if ( is_placeable_mine( sweapon ) || sweapon == "freezegun_zm" || sweapon == "freezegun_upgraded_zm" )
        return 0;

    if ( isdefined( self.player_damage_override ) )
        self thread [[ self.player_damage_override ]]( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime );

    if ( smeansofdeath == "MOD_FALLING" )
    {
        if ( self hasperk( "specialty_flakjacket" ) && isdefined( self.divetoprone ) && self.divetoprone == 1 )
        {
            if ( isdefined( level.zombiemode_divetonuke_perk_func ) )
                [[ level.zombiemode_divetonuke_perk_func ]]( self, self.origin );

            return 0;
        }

        if ( isdefined( level.pers_upgrade_flopper ) && level.pers_upgrade_flopper )
        {
            if ( self maps\mp\zombies\_zm_pers_upgrades_functions::pers_upgrade_flopper_damage_check( smeansofdeath, idamage ) )
                return 0;
        }
    }

    if ( smeansofdeath == "MOD_PROJECTILE" || smeansofdeath == "MOD_PROJECTILE_SPLASH" || smeansofdeath == "MOD_GRENADE" || smeansofdeath == "MOD_GRENADE_SPLASH" )
    {
        if ( self hasperk( "specialty_flakjacket" ) )
            return 0;

        if ( isdefined( level.pers_upgrade_flopper ) && level.pers_upgrade_flopper )
        {
            if ( isdefined( self.pers_upgrades_awarded["flopper"] ) && self.pers_upgrades_awarded["flopper"] )
                return 0;
        }

        if ( self.health > 75 && !( isdefined( self.is_zombie ) && self.is_zombie ) )
            return 75;
    }

    if ( idamage < self.health )
    {
        if ( isdefined( eattacker ) )
        {
            if ( isdefined( level.custom_kill_damaged_vo ) )
                eattacker thread [[ level.custom_kill_damaged_vo ]]( self );
            else
                eattacker.sound_damage_player = self;

            if ( isdefined( eattacker.has_legs ) && !eattacker.has_legs )
                self maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "crawl_hit" );
            else if ( isdefined( eattacker.animname ) && eattacker.animname == "monkey_zombie" )
                self maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "monkey_hit" );
        }

        return finaldamage;
    }

    if ( isdefined( eattacker ) )
    {
        if ( isdefined( eattacker.animname ) && eattacker.animname == "zombie_dog" )
        {
            self maps\mp\zombies\_zm_stats::increment_client_stat( "killed_by_zdog" );
            self maps\mp\zombies\_zm_stats::increment_player_stat( "killed_by_zdog" );
        }
        else if ( isdefined( eattacker.is_avogadro ) && eattacker.is_avogadro )
        {
            self maps\mp\zombies\_zm_stats::increment_client_stat( "killed_by_avogadro", 0 );
            self maps\mp\zombies\_zm_stats::increment_player_stat( "killed_by_avogadro" );
        }
    }

    self thread clear_path_timers();

    if ( level.intermission )
        level waittill( "forever" );

    flag_set( "instant_revive" );
	self thread wait_and_revive();
}

round_over_minigame()
{
    if ( isdefined( level.noroundnumber ) && level.noroundnumber == 1 )
        return;

    time = level.zombie_vars["zombie_between_round_time"];
    players = getplayers();

    for ( player_index = 0; player_index < players.size; player_index++ )
    {
        if ( !isdefined( players[player_index].pers["previous_distance_traveled"] ) )
            players[player_index].pers["previous_distance_traveled"] = 0;

        distancethisround = int( players[player_index].pers["distance_traveled"] - players[player_index].pers["previous_distance_traveled"] );
        players[player_index].pers["previous_distance_traveled"] = players[player_index].pers["distance_traveled"];
        players[player_index] incrementplayerstat( "distance_traveled", distancethisround );

        if ( players[player_index].pers["team"] != "spectator" )
        {
            zonename = players[player_index] get_current_zone();

            if ( isdefined( zonename ) )
                players[player_index] recordzombiezone( "endingZone", zonename );
        }
    }

    recordzombieroundend();
}

minigames_timer_hud()
{
	hud = newHudElem();
	hud.alignx = "left";
	hud.aligny = "top";
	hud.horzalign = "user_left";
	hud.vertalign = "user_top";
	hud.x = 25;
	hud.y += 24;
	hud.fontscale = 2;
	hud.alpha = 0;
	hud.color = ( 1, 1, 1 );
	hud.hidewheninmenu = 1;
	hud.foreground = 0;
	hud.label = &"";

	hud endon("death");

	hud.alpha = 1;

	hud thread set_time_frozen_on_end_game();

	if ( !flag( "initial_blackscreen_passed" ) )
	{
		hud set_time_frozen(0, "initial_blackscreen_passed");
	}

	if ( getDvar( "g_gametype" ) == "zgrief" )
	{
		hud set_time_frozen(0);
	}

	hud setTimerUp(0);
	hud.start_time = getTime();
	level.timer_hud_start_time = hud.start_time;
	level waittill ("end_game");
	hud destroy();
}

round_wait_minigame()
{
    level endon( "restart_round" );
/#
    if ( getdvarint( #"zombie_rise_test" ) )
        level waittill( "forever" );
#/
/#
    if ( getdvarint( #"zombie_cheat" ) == 2 || getdvarint( #"zombie_cheat" ) >= 4 )
        level waittill( "forever" );
#/
	level waittill ("force_next_round");

    wait 1;

    if ( flag( "dog_round" ) )
    {
        wait 7;

        while ( level.dog_intermission )
            wait 0.5;

        increment_dog_round_stat( "finished" );
    }
    else
    {
        while ( true )
        {
            should_wait = 0;

            if ( isdefined( level.is_ghost_round_started ) && [[ level.is_ghost_round_started ]]() )
                should_wait = 1;
			else if (( isdefined( level.next_leaper_round ) && level.next_leaper_round == ( level.round_number + 1 )))
                should_wait = 1;
            else
                should_wait = 0;

            if ( !should_wait )
                return;

            if ( flag( "end_round_wait" ) )
                return;
			
            wait 1.0;
        }
    }
}

nextroundtimer()
{
	count = 0;
	while(1)
	{
		count += 1;
		if (count == 40)
		{
			count = 0;
			level notify ("force_next_round");
			level.roundspassed += 1;
			if (level.roundspassed == 5)
			{
				level.roundspassed = 0;
				if(level.maxtime > 50)
				{
					level.maxtime -= 50;
					foreach (player in level.players)
					{
						player thread showBelowMessage("The timer shrinks!", "zmb_weap_wall");
					}
				}
				else if (level.maxtime == 50)
				{
					level.maxtime -= 10;
					foreach (player in level.players)
					{
						player thread showBelowMessage("The timer shrinks the last time!", "zmb_weap_wall");
					}				
				}
			}
		}
		wait 1;
	}
}

startHUDMessage()
{
	flag_wait( "initial_blackscreen_passed" );
	
	hud = newClientHudElem(self);
	hud.alignx = "center";
	hud.aligny = "top";
	hud.horzalign = "user_center";
	hud.vertalign = "user_top";
	hud.x = 0;
	hud.y += 24;
	hud.fontscale = 3;
	hud.alpha = 0;
	hud.color = ( 1, 1, 1 );
	hud.hidewheninmenu = 1;
	hud.foreground = 1;
	hud settext("TechnoOps Collection:");
	hud.fontscale = 3;
	hud changefontscaleovertime( 1 );
    hud fadeovertime( 1 );
    hud.alpha = 1;
    hud.fontscale = 1.5;

	wait 1;

	hud2 = newClientHudElem(self);
	hud2.alignx = "center";
	hud2.aligny = "top";
	hud2.horzalign = "user_center";
	hud2.vertalign = "user_top";
	hud2.x = 0;
	hud2.y += 42;
	hud2.fontscale = 8;
	hud2.alpha = 0;
	hud2.color = ( 1, 1, 1 );
	hud2.hidewheninmenu = 1;
	hud2.foreground = 1;
	if (getDvarInt("gamemode") == 1)
	{
		hud2 settext("Gun Game");
	}
	else if (getDvarInt("gamemode") == 2)
	{
		hud2 settext("Cranked");
	}
	else if (getDvarInt("gamemode") == 3)
	{
		hud2 settext("Mystery Guns");
	}
	hud2.fontscale = 8;
	hud2 changefontscaleovertime( 1 );
    hud2 fadeovertime( 1 );
    hud2.alpha = 1;
    hud2.fontscale = 4;

	wait 1;
	
	hud3 = newClientHudElem(self);
	hud3.alignx = "center";
	hud3.aligny = "top";
	hud3.horzalign = "user_center";
	hud3.vertalign = "user_top";
	hud3.x = 0;
	hud3.y += 90;
	hud3.fontscale = 2;
	hud3.alpha = 0;
	hud3.color = ( 1, 1, 1 );
	hud3.hidewheninmenu = 1;
	hud3.foreground = 1;
	if (getDvarInt("gamemode") == 1)
	{
		hud3 settext("Get a specified amount of kills to advance. First to complete the ladder wins!");
	}
	else if (getDvarInt("gamemode") == 2)
	{
		hud3 settext("Get kills to reset the timer, when timer reaches zero, youre eliminated!");
	}
	else if (getDvarInt("gamemode") == 3)
	{
		hud3 settext("Weapons roll after each round. If weapon is upgraded, the next will be upgraded aswell.");
	}
	hud3.fontscale = 2;
	hud3 changefontscaleovertime( 1 );
    hud3 fadeovertime( 1 );
    hud3.alpha = 1;
    hud3.fontscale = 1.5;
	wait 1;
	self notify ("can_readyup");

    if(level.gungamestarted == 0)
	{
		level waittill ("end");
	}
	else
	{
		wait 3.25;
	}

    hud changefontscaleovertime( 1 );
    hud fadeovertime( 1 );
    hud.alpha = 0;
    hud.fontscale = 4;
//    wait 1;
	
    hud2 changefontscaleovertime( 1 );
    hud2 fadeovertime( 1 );
    hud2.alpha = 0;
    hud2.fontscale = 6;
//    wait 1;
	
    hud3 changefontscaleovertime( 1 );
    hud3 fadeovertime( 1 );
    hud3.alpha = 0;
    hud3.fontscale = 2;
    wait 1;
	
	hud destroy();
	hud2 destroy();
	hud3 destroy();
}


init_gamemode_powerups()
{
    if(isDefined(level._zombiemode_powerup_grab))
		level.original_zombiemode_powerup_grab = level._zombiemode_powerup_grab;

    level._zombiemode_powerup_grab = ::custom_powerup_grab;

   	include_zombie_powerup("unlimited_ammo");
   	level.unlimited_ammo_duration = 30;
   	add_zombie_powerup("unlimited_ammo", "T6_WPN_AR_GALIL_WORLD", &"ZOMBIE_POWERUP_UNLIMITED_AMMO", ::func_should_always_drop, 0, 0, 0);
	powerup_set_can_pick_up_in_last_stand("unlimited_ammo", 1);
	
	if(getDvarInt("gamemode") == 2)
	{
		include_zombie_powerup("pause_timer");
		level.pause_timer_duration = 10;
		add_zombie_powerup("pause_timer", "zombie_teddybear", &"ZOMBIE_POWERUP_PAUSE_TIMER", ::func_paused_timer, 0, 0, 0);
		powerup_set_can_pick_up_in_last_stand("pause_timer", 1);
	}

	else if (getDvarInt("gamemode") == 1)
	{
		include_zombie_powerup("upgrade_weapon");
		add_zombie_powerup("upgrade_weapon", "zombie_sign_please_wait", &"ZOMBIE_POWERUP_UPGRADE_WEAPON", ::func_should_always_drop, 0, 0, 0);
		powerup_set_can_pick_up_in_last_stand("upgrade_weapon", 1);

		include_zombie_powerup("next_tier");
		add_zombie_powerup("next_tier", "zombie_skull", &"ZOMBIE_POWERUP_NEXT_TIER", ::func_should_always_drop, 0, 0, 0);
		powerup_set_can_pick_up_in_last_stand("next_tier", 1);
	}
}



custom_powerup_grab(s_powerup, e_player)
{
	if (s_powerup.powerup_name == "unlimited_ammo")
		e_player thread unlimited_ammo_powerup();
		
	else if (s_powerup.powerup_name == "pause_timer")
		e_player thread pause_timer_powerup();
		
	else if (s_powerup.powerup_name == "upgrade_weapon")
		e_player thread upgrade_weapon_powerup();
		
	else if (s_powerup.powerup_name == "next_tier")
		e_player thread next_tier_powerup();
	
	//pass args onto the original custom powerup grab function
	else if (isDefined(level.original_zombiemode_powerup_grab))
		level thread [[level.original_zombiemode_powerup_grab]](s_powerup, e_player);
}

unlimited_ammo_powerup()
{
	self notify("end_unlimited_ammo");
	self playsound("zmb_cha_ching");
	self thread turn_on_unlimited_ammo();
	self thread unlimited_ammo_on_hud();
	self thread notify_unlimited_ammo_end();
}

pause_timer_powerup()
{
	self notify("end_pause_timer");
	self playsound("zmb_cha_ching");
	self thread turn_on_pause_timer();
	self thread pause_timer_on_hud();
	self thread notify_pause_timer_end();
}

upgrade_weapon_powerup()
{
	self notify("end_upgrade_weapon");
	self playsound("zmb_cha_ching");
	self thread turn_on_upgrade_weapon();
	self thread upgrade_weapon_on_hud();
	self thread notify_upgrade_weapon_end();
}

next_tier_powerup()
{
	self notify("end_next_tier");
	self playsound("zmb_cha_ching");
	self thread turn_on_next_tier();
	self thread next_tier_on_hud();
	self thread notify_next_tier_end();
}

unlimited_ammo_on_hud()
{
	self endon("disconnect");
	//hud elems for text & icon
	unlimited_ammo_hud_string = newclienthudelem(self);
	unlimited_ammo_hud_string.elemtype = "font";
	unlimited_ammo_hud_string.font = "objective";
	unlimited_ammo_hud_string.fontscale = 2;
	unlimited_ammo_hud_string.x = 0;
	unlimited_ammo_hud_string.y = 0;
	unlimited_ammo_hud_string.width = 0;
	unlimited_ammo_hud_string.height = int( level.fontheight * 2 );
	unlimited_ammo_hud_string.xoffset = 0;
	unlimited_ammo_hud_string.yoffset = 0;
	unlimited_ammo_hud_string.children = [];
	unlimited_ammo_hud_string setparent(level.uiparent);
	unlimited_ammo_hud_string.hidden = 0;
	unlimited_ammo_hud_string maps\mp\gametypes_zm\_hud_util::setpoint("TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] - (level.zombie_vars["zombie_timer_offset_interval"] * 2));
	unlimited_ammo_hud_string.sort = .5;
	unlimited_ammo_hud_string.alpha = 0;
	unlimited_ammo_hud_string fadeovertime(.5);
	unlimited_ammo_hud_string.alpha = 1;

	unlimited_ammo_hud_string setText("Bottomless Clip!");
	unlimited_ammo_hud_string thread unlimited_ammo_hud_string_move();
	
	unlimited_ammo_hud_icon = newclienthudelem(self);
	unlimited_ammo_hud_icon.horzalign = "center";
	unlimited_ammo_hud_icon.vertalign = "bottom";
	unlimited_ammo_hud_icon.x = -75;
	unlimited_ammo_hud_icon.y = 0;
	unlimited_ammo_hud_icon.alpha = 1;
	unlimited_ammo_hud_icon.hidewheninmenu = true;   
	unlimited_ammo_hud_icon setshader("menu_mp_weapons_1911", 40, 40);
	self thread unlimited_ammo_hud_icon_blink(unlimited_ammo_hud_icon);
	self thread destroy_unlimited_ammo_icon_hud(unlimited_ammo_hud_icon);
}

unlimited_ammo_hud_string_move()
{
	wait .5;
	self fadeovertime(1.5);
	self moveovertime(1.5);
	self.y = 270;
	self.alpha = 0;
	wait 1.5;
	self destroy();
}

unlimited_ammo_hud_icon_blink(elem)
{
	level endon("disconnect");
	self endon("disconnect");
	self endon("end_unlimited_ammo");
	time_left = level.unlimited_ammo_duration;
	for(;;)
	{
		//less than 5sec left on powerup, blink fast
		if(time_left <= 5)
			time = .1;
		//less than 10sec left on powerup, blink
		else if(time_left <= 10)
			time = .2;
		//over 20sec left, dont blink
		else
		{
			wait .05;
			time_left -= .05;
			continue;
		}
		elem fadeovertime(time);
		elem.alpha = 0;
		wait time;
		elem fadeovertime(time);
		elem.alpha = 1;
		wait time;
		time_left -= time * 2;
	}
}

destroy_unlimited_ammo_icon_hud(elem)
{
	level endon("game_ended");
	self waittill_any_timeout(level.unlimited_ammo_duration+1, "disconnect", "end_unlimited_ammo");
	elem destroy();
}

turn_on_unlimited_ammo()
{
	level endon("game_ended");
	self endon("disonnect");
	self endon("end_unlimited_ammo");
	for(;;)
	{
		self setWeaponAmmoClip(self GetCurrentWeapon(), 150);
		wait .05;
	}
}

notify_unlimited_ammo_end()
{
	level endon("game_ended");
	self endon("disonnect");
	self endon("end_unlimited_ammo");
	wait level.unlimited_ammo_duration;
	//the same sound that plays when instakill powerup ends
	self playsound("zmb_insta_kill");
	self notify("end_unlimited_ammo");
}

pause_timer_on_hud()
{
	self endon("disconnect");
	//hud elems for text & icon
	pause_timer_hud_string = newclienthudelem(self);
	pause_timer_hud_string.elemtype = "font";
	pause_timer_hud_string.font = "objective";
	pause_timer_hud_string.fontscale = 2;
	pause_timer_hud_string.x = 0;
	pause_timer_hud_string.y = 0;
	pause_timer_hud_string.width = 0;
	pause_timer_hud_string.height = int( level.fontheight * 2 );
	pause_timer_hud_string.xoffset = 0;
	pause_timer_hud_string.yoffset = 0;
	pause_timer_hud_string.children = [];
	pause_timer_hud_string setparent(level.uiparent);
	pause_timer_hud_string.hidden = 0;
	pause_timer_hud_string maps\mp\gametypes_zm\_hud_util::setpoint("TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] - (level.zombie_vars["zombie_timer_offset_interval"] * 2));
	pause_timer_hud_string.sort = .5;
	pause_timer_hud_string.alpha = 0;
	pause_timer_hud_string fadeovertime(.5);
	pause_timer_hud_string.alpha = 1;

	pause_timer_hud_string setText("Timer Paused!");
	pause_timer_hud_string thread pause_timer_hud_string_move();
	
	pause_timer_hud_icon = newclienthudelem(self);
	pause_timer_hud_icon.horzalign = "center";
	pause_timer_hud_icon.vertalign = "bottom";
	pause_timer_hud_icon.x = -120;
	pause_timer_hud_icon.y = 0;
	pause_timer_hud_icon.alpha = 1;
	pause_timer_hud_icon.hidewheninmenu = true;   
	pause_timer_hud_icon setshader("demo_pause", 40, 40);
	self thread pause_timer_hud_icon_blink(pause_timer_hud_icon);
	self thread destroy_pause_timer_icon_hud(pause_timer_hud_icon);
}

pause_timer_hud_string_move()
{
	wait .5;
	self fadeovertime(1.5);
	self moveovertime(1.5);
	self.y = 270;
	self.alpha = 0;
	wait 1.5;
	self destroy();
}

pause_timer_hud_icon_blink(elem)
{
	level endon("disconnect");
	self endon("disconnect");
	self endon("end_pause_timer");
	time_left = level.pause_timer_duration;
	for(;;)
	{
		//less than 5sec left on powerup, blink fast
		if(time_left <= 5)
			time = .1;
		//less than 10sec left on powerup, blink
		else if(time_left <= 10)
			time = .2;
		//over 20sec left, dont blink
		else
		{
			wait .05;
			time_left -= .05;
			continue;
		}
		elem fadeovertime(time);
		elem.alpha = 0;
		wait time;
		elem fadeovertime(time);
		elem.alpha = 1;
		wait time;
		time_left -= time * 2;
	}
}

destroy_pause_timer_icon_hud(elem)
{
	level endon("game_ended");
	self waittill_any_timeout(level.pause_timer_duration+1, "disconnect", "end_pause_timer");
	elem destroy();
}

turn_on_pause_timer()
{
	level endon("game_ended");
	self endon("disonnect");
	self endon("end_pause_timer");
	self.timerpaused = 1;
}

notify_pause_timer_end()
{
	level endon("game_ended");
	self endon("disonnect");
	self endon("end_pause_timer");
	wait level.pause_timer_duration;
	//the same sound that plays when instakill powerup ends
	self playsound("zmb_insta_kill");
	self.timerpaused = 0;
	self notify("end_pause_timer");
}

func_paused_timer()
{
	foreach (player in get_players())
	{
		if (player.timerpaused == 1)
		{
			return false;
		}
	}
	return true;
}

upgrade_weapon_on_hud()
{
	self endon("disconnect");
	//hud elems for text & icon
	upgrade_weapon_hud_string = newclienthudelem(self);
	upgrade_weapon_hud_string.elemtype = "font";
	upgrade_weapon_hud_string.font = "objective";
	upgrade_weapon_hud_string.fontscale = 2;
	upgrade_weapon_hud_string.x = 0;
	upgrade_weapon_hud_string.y = 0;
	upgrade_weapon_hud_string.width = 0;
	upgrade_weapon_hud_string.height = int( level.fontheight * 2 );
	upgrade_weapon_hud_string.xoffset = 0;
	upgrade_weapon_hud_string.yoffset = 0;
	upgrade_weapon_hud_string.children = [];
	upgrade_weapon_hud_string setparent(level.uiparent);
	upgrade_weapon_hud_string.hidden = 0;
	upgrade_weapon_hud_string maps\mp\gametypes_zm\_hud_util::setpoint("TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] - (level.zombie_vars["zombie_timer_offset_interval"] * 2));
	upgrade_weapon_hud_string.sort = .5;
	upgrade_weapon_hud_string.alpha = 0;
	upgrade_weapon_hud_string fadeovertime(.5);
	upgrade_weapon_hud_string.alpha = 1;
	
	upgrade_weapon_hud_string setText("Upgrade Weapon!");
	upgrade_weapon_hud_string thread upgrade_weapon_hud_string_move();
}

upgrade_weapon_hud_string_move()
{
	wait .5;
	self fadeovertime(1.5);
	self moveovertime(1.5);
	self.y = 270;
	self.alpha = 0;
	wait 1.5;
	self destroy();
}


turn_on_upgrade_weapon()
{
	level endon("game_ended");
	self endon("disonnect");
	self endon("end_upgrade_weapon");
	
	if ( maps\mp\zombies\_zm_weapons::can_upgrade_weapon( self getcurrentweapon() ) )
	{
		weap = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( self getcurrentweapon(), false );
		self takeweapon(self getcurrentweapon());
		self weapon_give( weap, 0, 0, 1 );
		self notify("end_upgrade_weapon");
	}
}

notify_upgrade_weapon_end()
{
	level endon("game_ended");
	self endon("disonnect");
	self endon("end_upgrade_weapon");
	self notify("end_upgrade_weapon");
}

next_tier_on_hud()
{
	self endon("disconnect");
	//hud elems for text & icon
	next_tier_hud_string = newclienthudelem(self);
	next_tier_hud_string.elemtype = "font";
	next_tier_hud_string.font = "objective";
	next_tier_hud_string.fontscale = 2;
	next_tier_hud_string.x = 0;
	next_tier_hud_string.y = 0;
	next_tier_hud_string.width = 0;
	next_tier_hud_string.height = int( level.fontheight * 2 );
	next_tier_hud_string.xoffset = 0;
	next_tier_hud_string.yoffset = 0;
	next_tier_hud_string.children = [];
	next_tier_hud_string setparent(level.uiparent);
	next_tier_hud_string.hidden = 0;
	next_tier_hud_string maps\mp\gametypes_zm\_hud_util::setpoint("TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] - (level.zombie_vars["zombie_timer_offset_interval"] * 2));
	next_tier_hud_string.sort = .5;
	next_tier_hud_string.alpha = 0;
	next_tier_hud_string fadeovertime(.5);
	next_tier_hud_string.alpha = 1;
	
	next_tier_hud_string setText("Next Tier!");
	next_tier_hud_string thread next_tier_hud_string_move();
}

next_tier_hud_string_move()
{
	wait .5;
	self fadeovertime(1.5);
	self moveovertime(1.5);
	self.y = 270;
	self.alpha = 0;
	wait 1.5;
	self destroy();
}


turn_on_next_tier()
{
	level endon("game_ended");
	self endon("disonnect");
	self endon("end_next_tier");
	
	self.weaponprog = 0;
	self changeweapon(false);
	self.progmax = 8;
}

notify_next_tier_end()
{
	level endon("game_ended");
	self endon("disonnect");
	self endon("end_next_tier");
	self notify("end_next_tier");
}

////////////////////////
//
//	Mystery Guns
//
///////////////////////

createMysterylist()
{
	level.weaponlist = [];
	
	foreach (guns in level.zombie_weapons)
	{
		if (isGun(guns.weapon_name))
		{
			level.weaponlist[level.weaponlist.size] = guns.weapon_name;
		}
	}
}

changemysteryweapon()
{
	if (isDefined(self.e_afterlife_corpse))
	{
		self waittill( "player_revived" );
		wait 1.5;
	}
	
	shouldupgrade = maps\mp\zombies\_zm_weapons::can_upgrade_weapon( self getcurrentweapon() );
	
	primaries = self getweaponslistprimaries();
	
	foreach (weapon in primaries)
	{
		self takeweapon(weapon);
	}
	
	gun = rollgun();
	
	if (shouldupgrade)
	{
		self weapon_give( gun, 0, 0, 1 );
	}
	else
	{
		upgradedgun = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( gun, false );
		
		self weapon_give( upgradedgun, 0, 0, 1 );
	}
}

rollgun()
{
	rand = random(level.weaponlist);
	
	return rand;
}

roll_weapon_on_round_over()
{
	for(;;)
	{
		level waittill( "between_round_over" );
		foreach (player in get_players())
		{
			player changeMysteryweapon();
		}
	}
}

round_wait_exfil()
{
    level endon( "restart_round" );
/#
    if ( getdvarint( #"zombie_rise_test" ) )
        level waittill( "forever" );
#/
/#
    if ( getdvarint( #"zombie_cheat" ) == 2 || getdvarint( #"zombie_cheat" ) >= 4 )
        level waittill( "forever" );
#/
    wait 1;

    if ( flag( "dog_round" ) )
    {
        wait 7;

        while ( level.dog_intermission )
            wait 0.5;

        increment_dog_round_stat( "finished" );
    }
    else
    {
        while ( true )
        {
            should_wait = 0;

			if (level.exfilstarted == 0)
			{
				if ( isdefined( level.is_ghost_round_started ) && [[ level.is_ghost_round_started ]]() )
					should_wait = 1;
				else
					should_wait = get_current_zombie_count() > 0 || level.zombie_total > 0 || level.intermission;

				if ( !should_wait )
					return;

				if ( flag( "end_round_wait" ) )
					return;
			}

            wait 1.0;
        }
    }
}

do_post_chunk_repair_delay_new( player )
{
	if (player hasperk("specialty_rof") && getDvarInt("enable_upgradedperks") == 1)
	{
		wait 0.1;
	}
	else
	{
		wait 1;
	}
}

blocker_trigger_think_new()
{
    self endon( "blocker_hacked" );

    if ( isdefined( level.no_board_repair ) && level.no_board_repair )
        return;

/#
    println( "ZM >> TRIGGER blocker_trigger_think " );
#/
    level endon( "stop_blocker_think" );
    cost = 10;

    if ( isdefined( self.zombie_cost ) )
        cost = self.zombie_cost;

    original_cost = cost;

    if ( !isdefined( self.unitrigger_stub ) )
    {
        radius = 94.21;
        height = 94.21;

        if ( isdefined( self.trigger_location ) )
            trigger_location = self.trigger_location;
        else
            trigger_location = self;

        if ( isdefined( trigger_location.radius ) )
            radius = trigger_location.radius;

        if ( isdefined( trigger_location.height ) )
            height = trigger_location.height;

        trigger_pos = groundpos( trigger_location.origin ) + vectorscale( ( 0, 0, 1 ), 4.0 );
        self.unitrigger_stub = spawnstruct();
        self.unitrigger_stub.origin = trigger_pos;
        self.unitrigger_stub.radius = radius;
        self.unitrigger_stub.height = height;
        self.unitrigger_stub.script_unitrigger_type = "unitrigger_radius";
        self.unitrigger_stub.hint_string = get_hint_string( self, "default_reward_barrier_piece" );
        self.unitrigger_stub.cursor_hint = "HINT_NOICON";
        self.unitrigger_stub.trigger_target = self;
        maps\mp\zombies\_zm_unitrigger::register_static_unitrigger( self.unitrigger_stub, ::blocker_unitrigger_think );
        maps\mp\zombies\_zm_unitrigger::unregister_unitrigger( self.unitrigger_stub );

        if ( !isdefined( trigger_location.angles ) )
            trigger_location.angles = ( 0, 0, 0 );

        self.unitrigger_stub.origin = groundpos( trigger_location.origin ) + vectorscale( ( 0, 0, 1 ), 4.0 ) + anglestoforward( trigger_location.angles ) * -11;
    }

    self thread trigger_delete_on_repair();
    thread maps\mp\zombies\_zm_unitrigger::register_static_unitrigger( self.unitrigger_stub, ::blocker_unitrigger_think );
/#
    if ( getdvarint( #"zombie_debug" ) > 0 )
        thread debug_blocker( trigger_pos, radius, height );
#/

    while ( true )
    {
        self waittill( "trigger", player );
        has_perk = player has_blocker_affecting_perk();

        if ( all_chunks_intact( self, self.barrier_chunks ) )
        {
            self notify( "all_boards_repaired" );
            return;
        }

        if ( no_valid_repairable_boards( self, self.barrier_chunks ) )
        {
            self notify( "no valid boards" );
            return;
        }

        if ( isdefined( level._zm_blocker_trigger_think_return_override ) )
        {
            if ( self [[ level._zm_blocker_trigger_think_return_override ]]( player ) )
                return;
        }

        while ( true )
        {
            players = get_players();

            if ( player_fails_blocker_repair_trigger_preamble( player, players, self.unitrigger_stub.trigger, 0 ) )
                break;

            if ( isdefined( self.zbarrier ) )
            {
                chunk = get_random_destroyed_chunk( self, self.barrier_chunks );
                self thread replace_chunk( self, chunk, has_perk, isdefined( player.pers_upgrades_awarded["board"] ) && player.pers_upgrades_awarded["board"] );
            }
            else
            {
                chunk = get_random_destroyed_chunk( self, self.barrier_chunks );

                if ( isdefined( chunk.script_parameter ) && chunk.script_parameters == "repair_board" || chunk.script_parameters == "barricade_vents" )
                {
                    if ( isdefined( chunk.unbroken_section ) )
                    {
                        chunk show();
                        chunk solid();
                        chunk.unbroken_section self_delete();
                    }
                }
                else
                    chunk show();

                if ( !isdefined( chunk.script_parameters ) || chunk.script_parameters == "board" || chunk.script_parameters == "repair_board" || chunk.script_parameters == "barricade_vents" )
                {
                    if ( !( isdefined( level.use_clientside_board_fx ) && level.use_clientside_board_fx ) )
                    {
                        if ( !isdefined( chunk.material ) || isdefined( chunk.material ) && chunk.material != "rock" )
                            chunk play_sound_on_ent( "rebuild_barrier_piece" );

                        playsoundatposition( "zmb_cha_ching", ( 0, 0, 0 ) );
                    }
                }

                if ( chunk.script_parameters == "bar" )
                {
                    chunk play_sound_on_ent( "rebuild_barrier_piece" );
                    playsoundatposition( "zmb_cha_ching", ( 0, 0, 0 ) );
                }

                if ( isdefined( chunk.script_parameters ) )
                {
                    if ( chunk.script_parameters == "bar" )
                    {
                        if ( isdefined( chunk.script_noteworthy ) )
                        {
                            if ( chunk.script_noteworthy == "5" )
                                chunk hide();
                            else if ( chunk.script_noteworthy == "3" )
                                chunk hide();
                        }
                    }
                }

                self thread replace_chunk( self, chunk, has_perk, isdefined( player.pers_upgrades_awarded["board"] ) && player.pers_upgrades_awarded["board"] );
            }

            if ( isdefined( self.clip ) )
            {
                self.clip enable_trigger();
                self.clip disconnectpaths();
            }
            else
                blocker_disconnect_paths( self.neg_start, self.neg_end );

            bbprint( "zombie_uses", "playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type %s", player.name, player.score, level.round_number, original_cost, self.target, self.origin, "repair" );
            self do_post_chunk_repair_delay_new(player);

            if ( !is_player_valid( player ) )
                break;

            player handle_post_board_repair_rewards( cost, self );

            if ( all_chunks_intact( self, self.barrier_chunks ) )
            {
                self notify( "all_boards_repaired" );
                return;
            }

            if ( no_valid_repairable_boards( self, self.barrier_chunks ) )
            {
                self notify( "no valid boards" );
                return;
            }
        }
    }
}

change_power_new( delta, origin, radius )
{
    if ( !self.power )
    {
        self.power = 1;
        self [[ self.power_on_func ]]( origin, radius );
    }

    self.powered_count++;
}