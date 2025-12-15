#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_audio;
#include maps\mp\animscripts\zm_utility;
#include maps\mp\animscripts\zm_shared;
#include maps\mp\_createfx;
#include maps\mp\_fx;
#include maps\mp\zombies\_zm_zonemgr;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\zombies\_zm_weapons;
#include scripts\zm\main;

#using_animtree("zm_transit_automaton");

main()
{
	if(getDvarInt("enable_teddtrials") != 1)
	{
		return;
	}
	precachemodel("p6_anim_zm_bus_driver");
	precacheshader("hud_icon_reward");
	precacheshader("hud_icon_tedd");
	level._effect["perk_meteor"] = loadfx( "maps/zombie/fx_zmb_trail_perk_meteor" );
}

init()
{
	if(getDvarInt("enable_teddtrials") != 1)
	{
		return;
	}
	level thread debug_teddlocations();
	init_animtree();
	init_trial_zones();
	init_tedds();
	level thread playerConnect();
	level thread TEDD_cycle();
}

playerConnect()
{
	for(;;)
	{
		level waittill ("connected", player);
//		player iprintln(level.teddtrialbots.size);
		if(!isDefined(player.rewardsClaimed))
		{
			player.rewardsClaimed = array(false,false,false);
		}
//		player thread checkInputs();
	}
}

spawn_random_TEDD()
{
//	level.players[0] iprintln("Attempted to spawn TEDD");
	spot = random(level.teddtrialbots);
//	level.players[0] iprintln("Random Selection Passed: " + level.teddtrialbots.size);
	level thread spawn_TEDD(spot.location, spot.angle, spot.zones, spot.reward_location, spot.area_name);
}

spawn_TEDD(location, angle, zones, reward_location, area_name)
{
	level notify ("tedd_remove_rewards");
	foreach(player in level.players)
	{
		player.rewardsClaimed[0] = true;
		player.rewardsClaimed[1] = true;
		player.rewardsClaimed[2] = true;
	}
	start = location + (0,0,18000);
	level.teddtrial = spawn( "script_model", start );
	level.teddtrial setmodel( "p6_anim_zm_bus_driver" );
	level.teddtrial useanimtree( #animtree );
	level.teddtrial setanim( %ai_zombie_bus_driver_idle );
	level.teddtrial rotateTo((0,angle,0),.1);
	if(isDefined(zones))
	{
		level.teddtrial.activezone = random(zones);
	}
	playsoundatposition( "tedd_trial_spawn", location + (0,0,500) );
	teddCollision = spawn( "script_model", location);
	teddCollision setModel("collision_clip_32x32x128");
	teddCollision rotateTo((0,angle,0),.1);
	
	level.teddtrial thread TEDD_idle();
	tedd_fx_base = spawn("script_model", start);
	tedd_fx_base setmodel( "tag_origin" );
	tedd_fx = playfxontag(level._effect["perk_meteor"], tedd_fx_base, "tag_origin");
	
	level.teddtrial playsound( "zmb_perks_incoming" );
	tedd_fx_base playloopsound( "zmb_perks_incoming_loop", 6 );
	level.teddtrial moveto(location, 20);
	tedd_fx_base moveto(location, 20);
	level.teddtrial waittill ("movedone");
	earthquake( 0.7, 2.5, level.teddtrial.origin, 1000 );
	level.teddtrial playsound ("zmb_perks_incoming_land_explode");
	play_tedd_trials_vox("enter");
	tedd_fx_base stoploopsound( 0.5 );
	tedd_fx_base.owner = level.teddtrial;
	tedd_fx_base delete();
	tedd_fx delete();
	
	level.teddtrial thread tedd_trial_trigger();
	
	tedd_beam = spawn("script_model", location);
	tedd_beam setmodel( "tag_origin" );
	tedd_beam.angles = tedd_beam.angles + vectorscale( ( -1, 0, -1 ), 90.0 );
	foreach(player in level.players)
	{
		player.rewardsClaimed[0] = false;
		player.rewardsClaimed[1] = false;
		player.rewardsClaimed[2] = false;
	}
	wait 0.1;
	tedd_beam_fx = playfxontag(level._effect["lght_marker"], tedd_beam, "tag_origin");
	
	teddTrigger = spawn( "trigger_radius", (level.teddtrial.origin), 1, 50, 50 );
	teddTrigger setHintString("Press ^3&&1 ^7to begin a trial. [Cost: 750]");
	teddTrigger setcursorhint( "HINT_NOICON" );
	
	teddTrigger thread tedd_trial_trigger();
	
	if(getDvarInt("enable_toasts") == 1)
	{
		send_toast("Tedd Trials located at " + area_name, "hud_icon_tedd");
	}
	
	level waittill ("trials_ended", result);
	
	teddTrigger delete();
	
	foreach(player in level.players)
	{
		player playlocalsound ("trials_end");
	}
	
	if(result == "true")
	{
		level thread spawn_rewards(level.teddtier, reward_location, angle);
		foreach(player in level.players)
		{
			player thread createRewardIcon(reward_location);
		}
	}
	else if(result == "false")
	{
		play_tedd_trials_vox("fail");
	}
	else if(result == "timed_out")
	{

	}
	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		if(isDefined(i.trials_zombie) && i.trials_zombie == true)
		{
			i dodamage(i.health,i.origin);
		}
	}
	teddCollision delete();
	end = location + (0,0,18000);
	tedd_fx_base = spawn("script_model", level.teddtrial.origin);
	tedd_fx_base setmodel( "tag_origin" );
	tedd_fx = playfxontag(level._effect["perk_meteor"], tedd_fx_base, "tag_origin");
	level.teddtrial playsound( "zmb_perks_incoming" );
	tedd_fx_base playloopsound( "zmb_perks_incoming_loop", 6 );
	level.teddtrial moveto(end, 20);
	tedd_fx_base moveto(end, 20);
	tedd_beam delete();
	tedd_beam_fx delete();
	level.teddtrial waittill ("movedone");
	tedd_fx_base stoploopsound( 0.5 );
	level.teddtrial delete();
	tedd_fx_base delete();
	tedd_fx delete();
	level notify ("tedd_exit_done");
	
}

TEDD_round_checker()
{
	level endon ("end_game");
	tedd_round = level.round_number + 6;
	for(;;)
	{
		level waittill ( "between_round_over" );
		if(level.round_number == tedd_round)
		{
			return;
		}
	}
}

TEDD_cycle()
{
	level endon ("end_game");
	for(;;)
	{
		TEDD_round_checker();
		if(isDefined(level.teddtrial))
		{
			level notify ("trials_ended", "timed_out");
			level waittill ("tedd_exit_done");
		}
		level thread spawn_random_TEDD();
	}
}

tedd_trial_trigger()
{
	level endon ("trials_ended");
	for(;;)
	{
		self waittill( "trigger", i );
		if(i usebuttonpressed())
		{
			if(i.score >= 750)
			{
				i.score -= 750;
				self delete();
				start_challenge();
			}
		}
	}
}

register_teddtrial(location, angle, zones, reward_location, area_name)
{
	if(!isDefined(level.teddtrialbots))
	{
		level.teddtrialbots = [];
		id = 0;
	}
	else
	{
		id = level.teddtrialbots.size;
	}
	
	if(!isDefined(level.teddtrialbots[id]))
	{
		level.teddtrialbots[id] = spawnstruct();
	}
	
	level.teddtrialbots[id].location = location;
	if(!isDefined(zones))
	{
		level.teddtrialbots[id].zones = undefined;
	}
	level.teddtrialbots[id].zones = zones;
	level.teddtrialbots[id].angle = angle + 90;
	level.teddtrialbots[id].reward_location = reward_location;
	level.teddtrialbots[id].area_name = area_name;
}

register_trialzone(zone, center_location, zone_name)
{
	if(!isDefined(level.trialzones))
	{
		level.trialzones = [];
		id = 0;
	}
	else
	{
		id = level.trialzones.size;
	}
	
	if(!isDefined(level.trialzones[id]))
	{
		level.trialzones[id] = spawnstruct();
	}
	
	level.trialzones[id].zone = zone;
	level.trialzones[id].center_location = center_location;
	level.trialzones[id].zone_name = zone_name;
}

checkInputs()
{
	for(;;)
	{
		if(self usebuttonpressed())
		{
			println(weaponclass(self getcurrentweapon() ));
		}
		wait 0.05;
	}
}

init_trial_zones()
{

	//Tranzit - Town//
	register_trialzone("zone_town_south", (1950.55, -1485.2, -56.8378), "South Part of Town");
	register_trialzone("zone_bar", (2118.1, 350.376, -22.1396), "Bar");
	register_trialzone("zone_ban", (875.48, 300.003, -39.875), "Bank");
	register_trialzone("zone_town_barber", (954.898, -1160.06, 121.531), "Barber");
	
	//Tranzit - Bus Depot//
	register_trialzone("zone_pri", (-6834.72, 5361.27, -58.8858), "Bus Depot");
	
	//Tranzit - Farm//
	register_trialzone("zone_brn", (8180.83, -4983.64, 48.125), "Barn");
	register_trialzone("zone_farm_house", (8084.09, -6531.5, 117.125), "Farmhouse");
	
	//Tranzit - Diner//
	register_trialzone("zone_gar", (-4675.98, -7757.36, -45.8568), "Garage");
	register_trialzone("zone_din", (-5945.97, -7682.35, 3.85487), "Diner");
	
	//Tranzit - Power Station//
	register_trialzone("zone_pcr", (12192.1, 8283.86, -751.375), "Power Station");
	register_trialzone("zone_pow_warehouse", (10993.9, 8594.8, -404.988), "Warehouse");
	
	//Mob of the Dead//
	register_trialzone("zone_library", (597.627, 10511.1, 1344.28), "Library");
	register_trialzone("zone_warden_office", (-779.236, 9307.55, 1343.37), "Wardens Office");
	register_trialzone("zone_cafeteria", (2752.34, 9644.39, 1336.13), "Cafeteria");
	register_trialzone("zone_infirmary_roof", (3664.02, 9647.75, 1528.13), "Infirmary");
	register_trialzone("zone_roof", (3417.51, 9665.19, 1713.13), "Roof");
	register_trialzone("cellblock_shower", (1848.29, 9797.4, 1145.13), "Showers");
	register_trialzone("zone_dock", (-1107.99, 5656.58, -71.875), "Docks");
	
	//Nuketown//
	register_trialzone("openhouse1_backyard_zone", (-1500.55, 598.076, -55.5645), "Green House Backyard");
	register_trialzone("openhouse1_f2_zone", (-836.599, 444.055, 80.4456), "Green House Upper Floor");
	register_trialzone("openhouse1_f1_zone", (-676.723, 394.307, -53.3399), "Green House Downstairs");
	register_trialzone("openhouse2_backyard_zone", (1572.28, 493.941, -44.6594), "Yellow House Backyard");
	register_trialzone("openhouse2_f2_zone", (869.741, 276.335, 79.125), "Yellow House Upper Floor");
	register_trialzone("openhouse2_f1_zone", (870.643, 261.397, -56.8721), "Yellow House Downstairs");
	
	//Buried//
	register_trialzone("zone_underground_jail", (-972.507, 687.542, 8.125), "Jail"); //
	register_trialzone("zone_gun_store", (-564.086, -1187.99, 8.125), "Gunsmith"); //
	register_trialzone("zone_underground_bar", (736.315, -1461.14, 55.3528), "Saloon");
	register_trialzone("zone_candy_store", (621.106, -169.619, 8.125), "Candy Store");
	register_trialzone("zone_underground_courthouse", (206.195, 1029.33, 8.125), "Courthouse");
	register_trialzone("zone_church_main", (1623.12, 2176.31, 39.1379), "Church");
}

init_tedds()
{
	if(getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_transit")
		{
			if(getDvar("ui_zm_mapstartlocation") == "town")
			{
				register_teddtrial((771.071, -290.728, -61.875), -90, array("zone_town_south","zone_bar","zone_ban","zone_town_barber"), (748.37, -487.865, -61.875), "Town");
			}
			else if (getDvar("ui_zm_mapstartlocation") == "transit")
			{
				register_teddtrial((-7108.74, 4946.49, -55.875), -93.5464, array("zone_pri"), (-7536.65, 4906.57, -55.875), "Bus Depot");
			}
			else if (getDvar("ui_zm_mapstartlocation") == "farm")
			{
				register_teddtrial((8180.23, -5811.71, 33.7715), -94.1748, array("zone_brn", "zone_farm_house"), (7799.67, -5770.7, 4.20267), "Farm");
			}
		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			register_teddtrial((-1935.53, 697.965, -48.3402), -74.7143, array("openhouse1_backyard_zone","openhouse1_f2_zone","openhouse1_f1_zone"), (-1572.68, 332, -63.5391), "Green House Backyard");
			register_teddtrial((1494.78, -1.5133, -63.8845), 145.726, array("openhouse2_backyard_zone","openhouse2_f2_zone","openhouse2_f1_zone"), (1608.72, 324.353, -60.8731), "Yellow House Backyard");
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{
			register_teddtrial((3620.22, 9503.64, 1530.87), 96.9983, array("zone_infirmary_roof","zone_cafeteria"), (3681.24, 9679.69, 1528.13), "Cafeteria?");
			register_teddtrial((451.271, 8628.06, 1128.13), 136.758, array("zone_warden_office", "cellblock_shower"), (112.682, 8751.85, 1133.6), "Wardens Office");
			register_teddtrial((-897.283, 5742, -71.875), 52.4971, array("zone_dock"), (-734.918, 5950.11, -51.5203), "Docks");
			register_teddtrial((758.359, 10359.6, 1344.13), 137.344, array("zone_library"), (672.461, 10466.7, 1336.13), "Library");
		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			register_teddtrial((-437.004, 222.706, -25.0735), 86.2858, array("zone_underground_jail","zone_gun_store"), (-415.011, 368.8, -22.4509), "Front of Bank");
			register_teddtrial((659.949, 1071.86, 10.3413), 9.76358, array("zone_underground_bar","zone_candy_store","zone_underground_courthouse","zone_church_main"), (1128.76, 906.329, -32.6249), "Graveyard");
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			register_teddtrial((-5011.39, -7788.78, -59.0191), 132.803, array("zone_gar","zone_din"), (-5160.02, -7201.63, -59.4591), "Diner");
			register_teddtrial((11032.9, 7884.8, -580.284), -62.5179, array("zone_pcr","zone_pow_warehouse"), (10912.6, 7541.54, -588.767), "Powerhouse");
			register_teddtrial((8180.23, -5811.71, 33.7715), -94.1748, array("zone_brn", "zone_farm_house"), (7799.67, -5770.7, 4.20267), "Farm");
			register_teddtrial((-7108.74, 4946.49, -55.875), -93.5464, array("zone_pri"), (-7536.65, 4906.57, -55.875), "Bus Depot");
			register_teddtrial((771.071, -290.728, -61.875), 0, array("zone_town_south","zone_bar","zone_ban","zone_town_barber"), (748.37, -487.865, -61.875), "Town");
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{

		}
		else if(getDvar("mapname") == "zm_highrise")
		{

		}
	}
	level notify ("finished_logging_trials");
}

init_animtree()
{
    scriptmodelsuseanimtree( #animtree );
}

TEDD_idle()
{
    for(;;)
	{
		idle_anims = [];
		idle_anims[0] = %ai_zombie_bus_driver_idle_a;
		idle_anims[1] = %ai_zombie_bus_driver_idle_b;
		idle_anims[2] = %ai_zombie_bus_driver_idle_c;
		idle_anims[3] = %ai_zombie_bus_driver_idle_d;
		idle_anims[4] = %ai_zombie_bus_driver_idle;
	
		driveranim = random( idle_anims );
	
		self setanim( driveranim );
		self thread sndplaydriveranimsnd( driveranim );
		wait( getanimlength( driveranim ) );
		wait 10;
	}
}

sndplaydriveranimsnd( the_anim )
{
    if ( the_anim == %ai_zombie_bus_driver_idle_twitch_a )
    {
        wait 0.55;
        self playsound( "evt_zmb_robot_jerk" );
        wait 1.2;
        self playsound( "evt_zmb_robot_hat" );
        wait 0.79;
        self playsound( "evt_zmb_robot_spin" );
        wait 1.1;
        self playsound( "evt_zmb_robot_hat" );
        self playsound( "evt_zmb_robot_spin" );
    }
    else if ( the_anim == %ai_zombie_bus_driver_idle_twitch_focused )
    {
        wait 0.25;
        self playsound( "evt_zmb_robot_jerk" );
        wait 4.8;
        self playsound( "evt_zmb_robot_jerk" );
    }
    else if ( the_anim == %ai_zombie_bus_driver_idle_twitch_panicked )
    {
        wait 0.31;
        self playsound( "evt_zmb_robot_jerk" );
        wait 0.79;
        self playsound( "evt_zmb_robot_jerk" );
        wait 1.3;
        self playsound( "evt_zmb_robot_jerk" );
        wait 0.18;
        self playsound( "evt_zmb_robot_spin" );
        wait 0.52;
        self playsound( "evt_zmb_robot_hat" );
    }
    else if ( the_anim == %ai_zombie_bus_driver_idle_twitch_b )
    {
        wait 0.22;
        self playsound( "evt_zmb_robot_hat" );
        wait 1.06;
        self playsound( "evt_zmb_robot_spin" );
        wait 1.05;
        self playsound( "evt_zmb_robot_hat" );
        wait 1.07;
        self playsound( "evt_zmb_robot_spin" );
        wait 0.59;
        self playsound( "evt_zmb_robot_hat" );
    }
    else if ( the_anim == %ai_zombie_bus_driver_idle_d )
    {
        wait 0.24;
        self playsound( "evt_zmb_robot_spin" );
        wait 1.04;
        self playsound( "evt_zmb_robot_hat" );
    }
    else if ( the_anim == %ai_zombie_bus_driver_emp_powerdown )
    {
        wait 0.1;
        self playsound( "evt_zmb_robot_jerk" );
        wait 0.9;
        self playsound( "evt_zmb_robot_jerk" );
    }
    else if ( the_anim == %ai_zombie_bus_driver_emp_powerup )
    {
        wait 0.63;
        self playsound( "evt_zmb_robot_jerk" );
    }
}

start_challenge()
{
	level endon ("trials_ended");
	level.tedd_score = 0;
	level.tedd_score_max = 10;
	level.teddtier = 0;
	timer = 180;
	challenges = array("action_kill_air","action_kill_crouch","action_kill_ads","action_kill_hipfire","no_dmg","grenade_kill");
	if(isDefined(self.zones))
	{
		challenges[challenges.size] = "zone_capture";
		challenges[challenges.size] = "zone_kill";
	}
	chosen_challenge = random(challenges);
	
	level thread spawn_trial_zombies();
	
    switch( chosen_challenge ) {
    	case "action_kill_air":
        	foreach(player in level.players)
			{
				player thread tedd_trial_kill("action_kill_air");
			}
			level.tedd_score_max = set_max_score(100);
			break;
    	case "action_kill_crouch":
        	foreach(player in level.players)
			{
				player thread tedd_trial_kill("action_kill_crouch");
			}
			level.tedd_score_max = set_max_score(150);
			break;
    	case "action_kill_ads":
        	foreach(player in level.players)
			{
				player thread tedd_trial_kill("action_kill_ads");
			}
			level.tedd_score_max = set_max_score(150);
			break;
    	case "action_kill_hipfire":
        	foreach(player in level.players)
			{
				player thread tedd_trial_kill("action_kill_hipfire");
			}
			level.tedd_score_max = set_max_score(150);
			break;
    	case "no_dmg":
        	level thread tedd_trial_no_damage();
			level.tedd_score_max = set_max_score_time(180);
			break;
    	case "phd_kill":
        	break;
    	case "grenade_kill":
			level.tedd_score_max = set_max_score(70);
        	foreach(player in level.players)
			{
				player thread tedd_trial_kill("grenade_kill");
			}
			break;
    	case "zone_capture":
        	level thread tedd_trial_zone_capture(level.teddtrial.activezone);
			level thread trials_icon(get_registered_zone_location(level.teddtrial.activezone));
			level.tedd_score_max = set_max_score_time(180);
			break;
    	case "zone_kill":
        	foreach(player in level.players)
			{
				player thread tedd_trial_kill("zone_kill");
			}
			level.tedd_score_max = set_max_score(150);
			level thread trials_icon(get_registered_zone_location(level.teddtrial.activezone));
			break;
    	default:
        	shader = "";
    }
//	foreach(player in level.players)
//	{
//		player iprintln("Active Challenge " + chosen_challenge);
//	}
	level thread challenge_tracker(chosen_challenge);
	level thread teddtrialshud(chosen_challenge, timer);
	foreach(player in level.players)
	{
		player playlocalsound ("trials_start");
	}
	level thread playtrialsmusic();
	challenge_timer(timer);
}

set_max_score(score)
{
	size = 0;
	foreach(player in level.players)
	{
		if(!isDefined(player.isbot))
		{
			size += 1;
		}
	}
	
	increase = int(score * 0.35);
	number = increase * size;
	if(size == 1)
	{
		return score;
	}
	else
	{
		return number;
	}
}

set_max_score_time(timer)
{
	increase = int(timer * 0.90);
	return increase;
}

tedd_trial_kill(type)
{
	self endon ("disconnect");
	level endon ("trials_ended");
	for(;;)
	{
		self waittill ("zom_kill", zombie);
		if(type == "grenade_kill")
		{
			if(zombie.damagemod == "MOD_GRENADE" || zombie.damagemod == "MOD_GRENADE_SPLASH" || zombie.damagemod == "MOD_EXPLOSIVE" )
			{
				level notify ("tedd_trials_score");
			}
		}
		else if(type == "action_kill_crouch")
		{
			if(self getstance() == "prone" || self getstance() == "crouch")
			{
				level notify ("tedd_trials_score");
			}
		}
		else if(type == "action_kill_air")
		{
			if(!self isonground() )
			{
				level notify ("tedd_trials_score");
			}
		}
		else if(type == "action_kill_ads")
		{
			if(self adsbuttonpressed())
			{
				level notify ("tedd_trials_score");
			}
		}
		else if(type == "action_kill_hipfire")
		{
			if(!self adsbuttonpressed())
			{
				level notify ("tedd_trials_score");
			}
		}
		else if(type == "zone_kill")
		{
			if(self get_player_zone() == level.teddtrial.activezone)
			{
				level notify ("tedd_trials_score");
			}
		}
	}
}

tedd_trial_global_kill(type)
{
	level endon ("end_game");
	level endon ("trials_ended");
	for(;;)
	{
		if(type == "trap_kill")
		{
			level waittill ( "trap_kill" );
			level notify ("tedd_trials_score");
		}
	}
}

tedd_trial_zone_capture(zone)
{
	level endon ("end_game");
	level endon ("trials_ended");
	for(;;)
	{
		foreach(player in level.players)
		{
			if(player get_player_zone() == zone)
			{
				level notify ("tedd_trials_score");
			}
		}
		wait 1;
	}
}

tedd_trial_no_damage()
{
	level endon ("trials_ended");
	for(;;)
	{
		count = 0;
		foreach(player in level.players)
		{
			if(player.health == player.maxhealth)
			{
				count += 1;
			}
		}
		if(count == level.players.size)
		{
			level notify ("tedd_trials_score");
		}
		wait 1;
	}
}

is_zone_registered(zone)
{
	foreach(zones_struct in level.trialzones)
	{
		if(zones_struct.zone == zone)
		{
			return true;
		}
	}
	return false;
}

get_registered_zone_location(zone)
{
	foreach(zones_struct in level.trialzones)
	{
		if(zones_struct.zone == zone)
		{
			return zones_struct.center_location;
		}
	}
	return undefined;
}

get_registered_zone_name(zone)
{
	foreach(zones_struct in level.trialzones)
	{
		if(zones_struct.zone == zone)
		{
			return zones_struct.zone_name;
		}
	}
	return undefined;
}

trials_icon(location)
{
	zone_icon = newHudElem();
	zone_icon thread removeHUDEndGame();
    zone_icon.x = location[ 0 ];
    zone_icon.y = location[ 1 ];
	zone_icon.z = location[ 2 ] + 20;
	zone_icon.color = (1,1,1);
    zone_icon.isshown = 1;
    zone_icon.archived = 0;
    zone_icon setshader( "hud_icon_tedd", 8, 8 );
	zone_icon setwaypoint( 1 );
	level waittill("trials_ended");
	zone_icon destroy();
}

challenge_tracker(challenge)
{
	level endon ("end_game");
	level endon ("trials_ended");
//	level.tedd_score_max = 99999;
	for(;;)
	{
		level waittill ("tedd_trials_score");
		level.tedd_score += 1;
		level notify ("trials_update_score");
		check_reward_tier();
		
		if(level.tedd_score >= level.tedd_score_max)
		{
			level notify ("trials_ended", "true");
			wait 0.1;
			level notify ("trials_stop_updating");
		}
		else
		{
			foreach(player in level.players)
			{
				player playlocalsound("trials_tick");
			}
		}
	}
}

spawn_trial_zombies()
{
	level endon ("trials_ended");
	
	for(;;)
	{
		wait randomfloatrange(0,1);
		spawner = random( level.zombie_spawners );
		if(maps\mp\zombies\_zm_utility::get_round_enemy_array().size < 20)
		{
			ai = spawn_zombie( spawner, "zombie", spawner.origin );
			ai.trials_zombie = true;
			ai.dont_give_points = 1;
		}
	}
}

challenge_timer(time)
{
	wait time;
	if(level.teddtier == 0)
	{
		level notify ("trials_ended", "false");
	}
	else
	{
		level notify ("trials_ended", "true");
	}
}

teddtrialshud(challenge, time)
{
	level endon("end_game");
	
	y = -20;
	
	level.trialhud = newHudElem();
	level.trialhud.alignx = "left";
	level.trialhud.aligny = "center";
	level.trialhud.horzalign = "user_left";
	level.trialhud.vertalign = "user_center";
	level.trialhud.x = 38;
	level.trialhud.y = y - 10;
	level.trialhud.fontscale = 1;
	level.trialhud.alpha = 1;
	level.trialhud.color = ( 1, 1, 1 );
	level.trialhud.hidewheninmenu = 1;
	level.trialhud.foreground = 0;
	level.trialhud setText (getChallengeText(challenge) + " - Goal: " + level.tedd_score_max);
	level.trialhud thread removeHUDEndGame();
	
	trialicon = newHudElem();
	trialicon.alignx = "left";
	trialicon.aligny = "center";
	trialicon.horzalign = "user_left";
	trialicon.vertalign = "user_center";
	trialicon.x = 16;
	trialicon.y = y;
	trialicon.fontscale = 1;
	trialicon.alpha = 1;
	trialicon.color = ( 1, 1, 1 );
	trialicon.hidewheninmenu = 1;
	trialicon.foreground = 0;
	trialicon setshader( "hud_icon_reward", 16, 16 );
	trialicon thread removeHUDEndGame();

	trialscore = newHudElem();
	trialscore.alignx = "left";
	trialscore.aligny = "center";
	trialscore.horzalign = "user_left";
	trialscore.vertalign = "user_center";
	trialscore.x = 38;
	trialscore.y = y;
	trialscore.fontscale = 1;
	trialscore.alpha = 1;
	trialscore.color = ( 1, 1, 1 );
	trialscore.hidewheninmenu = 1;
	trialscore.foreground = 0;
	trialscore.label = &"Score: ";
	trialscore setValue(0);
	trialscore thread removeHUDEndGame();

	trialtimer = newHudElem();
	trialtimer.alignx = "left";
	trialtimer.aligny = "center";
	trialtimer.horzalign = "user_left";
	trialtimer.vertalign = "user_center";
	trialtimer.x = 38;
	trialtimer.y = y + 10;
	trialtimer.fontscale = 1;
	trialtimer.alpha = 1;
	trialtimer.color = ( 1, 1, 1 );
	trialtimer.hidewheninmenu = 1;
	trialtimer.foreground = 0;
	trialtimer.label = &"";
	trialtimer thread removeHUDEndGame();
	
	trialtimer setTimer(time);
	
	level thread reward_tier_colors(trialtimer, trialicon, trialscore);
	level thread update_score_text(trialscore);
	
	level waittill ("trials_ended", result);
	
	wait 1;
	
	if(result == "true")
	{
		level.trialhud setText ("Challenge Successful!");
		level.trialhud.color = ( 0, 1, 0 );
	}
	else if(result == "false")
	{
		level.trialhud setText ("Challenge Failed!");
		level.trialhud.color = ( 1, 0, 0 );
	}
	level notify ("trials_stop_updating");
	trialtimer destroy();
	trialscore destroy();
	wait 8;
	level.trialhud destroy();
	trialicon destroy();

}

update_score_text(hud)
{
	level endon ("trials_stop_updating");
	for(;;)
	{
		level waittill ("trials_update_score");
		hud setValue(level.tedd_score);
	}
}

reward_tier_colors(timerhud, trialicon, scoreicon)
{
	level endon ("trials_stop_updating");
	for(;;)
	{
		if(level.teddtier == 1)
		{
			level.trialhud.color = ( 0, 1, 1 );
			timerhud.color = ( 0, 1, 1 );
			trialicon.color = ( 0, 1, 1 );
			scoreicon.color = ( 0, 1, 1 );
		}
		else if(level.teddtier == 2)
		{
			level.trialhud.color = ( 1, 0, 1 );
			timerhud.color = ( 1, 0, 1 );
			trialicon.color = ( 1, 0, 1 );
			scoreicon.color = ( 1, 0, 1 );
		}
		else if(level.teddtier == 3)
		{
			level.trialhud.color = ( 1, 1, 0 );
			timerhud.color = ( 1, 1, 0 );
			trialicon.color = ( 1, 1, 0 );
			scoreicon.color = ( 1, 1, 0 );
		}
		else
		{
			level.trialhud.color = ( 1, 1, 1 );
			timerhud.color = ( 1, 1, 1 );
			trialicon.color = ( 1, 1, 1 );
			scoreicon.color = ( 1, 1, 1 );
		}
		wait 0.01;
	}
}

check_reward_tier()
{
	max = level.tedd_score_max;
	tier_1 = int(max * 0.50);
	tier_2 = int(max * 0.75);
	tier_3 = int(max * 1);
	
//	level.players[0] iprintln(tier_1 + " - " + tier_2 + " - " + tier_3);
	
	if(level.tedd_score >= tier_1 && level.teddtier == 0)
	{
		level notify ("trials_tier", 1);
		play_tedd_trials_vox("tier_1");
		level.teddtier = 1;
		return;
	}
	if(level.tedd_score >= tier_2 && level.teddtier == 1)
	{
		level notify ("trials_tier", 2);
		play_tedd_trials_vox("tier_2");
		level.teddtier = 2;
		return;
	}
	if(level.tedd_score >= tier_3 && level.teddtier == 2)
	{
		level notify ("trials_tier", 3);
		play_tedd_trials_vox("tier_3");
		level.teddtier = 3;
		return;
	}
}

reward_checker()
{
	level endon ("trials_ended");
	
	for(;;)
	{
		level waittill ("trials_tier", number);
	}
}

getChallengeText(type)
{
//	level.players[0] iprintln (type);
	if(type == "grenade_kill")
	{
		return "Kill Zombies using Grenades";
	}
	else if(type == "action_kill_crouch")
	{
		return "Kill Zombies while Crouching";
	}
	else if(type == "action_kill_air")
	{
		return "Kill Zombies while midair";
	}
	else if(type == "action_kill_ads")
	{
		return "Kill Zombies while aiming";
	}
	else if(type == "action_kill_hipfire")
	{
		return "Kill Zombies while hipfiring";
	}
	else if(type == "zone_kill")
	{
		return "Kill Zombies in " + get_registered_zone_name(level.teddtrial.activezone);
	}
	else if(type == "zone_capture")
	{
		return "Stand in " + get_registered_zone_name(level.teddtrial.activezone);
	}
	else if(type == "no_dmg")
	{
		return "Take no damage";
	}
}

play_tedd_trials_vox(type)
{
	if(type == "enter")
	{
		sounds = array("tedd_trial_enterance_1","tedd_trial_enterance_2");
		sfx = random(sounds);
		if(sfx == "tedd_trial_enterance_1")
		{
			subtitle = "AHHH! We are all gonna die! Goodbye cruel world! Goodbye! Oh, we made it.";
			duration = 9;
			global = false;
		}
		else if(sfx == "tedd_trial_enterance_2")
		{
			subtitle = "AAAHHH-Did anyone else feel that?";
			duration = 5;
			global = false;
		}
	}
	else if(type == "fail")
	{
		sounds = array("tedd_trial_fail_1","tedd_trial_fail_2","tedd_trial_fail_3","tedd_trial_fail_4");
		sfx = random(sounds);
		if(sfx == "tedd_trial_fail_1")
		{
			subtitle = "Warning! Warning! Software failture imminent.";
			duration = 4;
			global = true;
		}
		else if(sfx == "tedd_trial_fail_2")
		{
			subtitle = "Youll be sorry asshole!";
			duration = 3;
			global = true;
		}
		else if(sfx == "tedd_trial_fail_3")
		{
			subtitle = "Keep fucking with me! See if I dont kill you all!";
			duration = 4;
			global = true;
		}
		else if(sfx == "tedd_trial_fail_4")
		{
			subtitle = "Fuck you!";
			duration = 2;
			global = true;
		}
	}
	else if(type == "success")
	{
		subtitle = "";
		duration = 4;
		sfx = "";
		global = true;
	}
	else if(type == "tier_1")
	{
		subtitle = "Consolidated Coach Corporation Bus-Lines invites you to upgrade to first class.";
		duration = 5;
		sfx = "vox_trial_upgrade_1";
		global = true;
	}
	else if(type == "tier_2")
	{
		subtitle = "Clear the road ahead, move up to Deluxe Coach!";
		duration = 4;
		sfx = "vox_trial_upgrade_2";
		global = true;
	}
	else if(type == "tier_3")
	{
		subtitle = "More accommodations available on Consolidated Coach Corporation Double-Decker class!";
		duration = 6;
		sfx = "vox_trial_upgrade_3";
		global = true;
	}
	foreach(player in level.players)
	{
		if(global == true)
		{
			player thread sendsubtitletext("T.E.D.D", 1, subtitle, sfx, duration);
		}
		else
		{
			if(distance(player.origin, level.teddtrial.origin) <= 1000)
			{
				player thread sendsubtitletext("T.E.D.D", 1, subtitle, sfx, duration);
			}
		}
	}
}

playtrialsmusic()
{
    if(level.exfilstarted == 1)
	{
		return;
	}
	ent = spawn( "script_origin", ( 0, 0, 0 ) );
    ent thread stoptrialsmusic();
	themes = array("cw","bo6_1");
	chosen_themes = random(themes);
//	level.players[0] iprintln (chosen_themes);
	if(getDvarInt("enable_debug") == 1)
	{
		foreach(player in level.players)
		{
			player iprintln(chosen_themes);
		}
	}
	if(chosen_themes == "bo6_1")
	{
		ent playsound( "mus_trials_loop_2_intro");
		wait 16;
		ent playloopsound( "mus_trials_loop_2", 1 );
	}
	else if(chosen_themes == "cw")
	{
		ent playloopsound( "mus_trials_loop", 1 );
	}
}

stoptrialsmusic()
{
    level waittill_any( "end_game", "trials_ended", "exfil_started");
    self stoploopsound( 0.5 );
    wait 0.5;
    self delete();
}

spawn_rewards(rarity, location, angle)
{
	perks = [];
	if(rarity == 1) //Uncommon
	{
		if(level.zombiemode_using_deadshot_perk == 1)
		{
			perks[perks.size] = "specialty_ads_zombies";
		}
		if(level.zombiemode_using_tombstone_perk == 1)
		{
			perks[perks.size] = "specialty_tombstone_zombies";
		}
		if(level.script == "zm_buried")
		{
			perks[perks.size] = "specialty_vulture_zombies";
		}
	}
	else if(rarity == 2) //Rare
	{
		if(level.zombiemode_using_revive_perk == 1)
		{
			perks[perks.size] = "specialty_quickrevive_zombies";
		}
		if(level.zombiemode_using_marathon_perk == 1)
		{
			perks[perks.size] = "specialty_marathon_zombies";
		}
//		if(level.zombiemode_using_doubletap_perk == 1)
//		{
//			perks[perks.size] = "specialty_doubletap_zombies";
//		}
	}
	else if(rarity == 3) //Legendary
	{
		if(level.zombiemode_using_juggernaut_perk == 1)
		{
			perks[perks.size] = "specialty_armorvest";
		}
		if(level.zombiemode_using_marathon_perk == 1)
		{
			perks[perks.size] = "specialty_longersprint";
		}
//		if(level.zombiemode_using_divetonuke_perk == 1)
//		{
//			perks[perks.size] = "specialty_divetonuke";
//		}
		if(level.zombiemode_using_additionalprimaryweapon_perk == 1)
		{
			perks[perks.size] = "specialty_additionalprimaryweapon";
		}
//		if(level.zombiemode_using_electric_cherry_perk == 1)
//		{
//			perks[perks.size] = "specialty_electric_cherry";
//		}
	}
	chosen_perk = random(perks);
	
	if(rarity == 1)
	{
		chosen_weapon = random(filterGuns(array("pistol","sniper")));
		score = 250;
	}
	else if(rarity == 2)
	{
		chosen_weapon = random(filterGuns(array("smg")));
		score = 750;
	}
	else if(rarity == 3)
	{
		chosen_weapon = random(filterGuns(array("rifle")));
		score = 1500;
	}
	
	center = location + (0,0,40);
	
	level thread spawn_points(center, score);
	level thread spawn_weapon_reward(center + (80,0,0), chosen_weapon);
	level thread spawn_perk_reward(center + (-80,0,0), chosen_perk);
}

//player.rewardsClaimed
//[0] = Points Checker
//[1] = Weapon Checker
//[2] = Perk Checker

remove_reward(triggerent, modelent)
{
	level waittill ("tedd_remove_rewards");
	triggerent delete();
	modelent delete();
}

filterGuns(types)
{
	list = [];
	foreach(type in types)
	{
		foreach (guns in level.zombie_weapons)
		{
			if(isGun(guns.weapon_name))
			{
				if( weaponclass( guns.weapon_name ) == type )
				{
					if ( maps\mp\zombies\_zm_weapons::can_upgrade_weapon( guns.weapon_name ) )
					{
						list[list.size] = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( guns.weapon_name, false );
					}
				}
			}
		}
	}
	return list;
}

get_front_location(location, angle, distance)
{
	if(!isDefined(distance))
	{
		distance = 100;
	}
	
	trace = bullettrace( location, location + vectorscale( ( anglestoforward( angle ) ), distance ), 1, self );
    return trace["position"];
}

spawn_points(location, points)
{
	pointsTrigger = spawn( "trigger_radius", location, 1, 20, 20 );
	pointsTrigger setHintString("Press ^3&&1 ^7to take " + points);
	pointsTrigger setcursorhint( "HINT_NOICON" );
	pointsModel = spawn("script_model", location);
	pointsModel setmodel ("zombie_z_money_icon");
	level thread remove_reward(pointsTrigger, pointsModel);
	for(;;)
	{
		pointsTrigger waittill( "trigger", i );
		if(i usebuttonpressed())
		{
			if(i.rewardsClaimed[0] == false)
			{
				i.rewardsClaimed[0] = true;
				i.score += points;
				i playlocalsound("zmb_cha_ching");
				if(if_all_players_already_claimed(0))
				{
					break;
				}
			}
		}
	}
	pointsTrigger delete();
	pointsModel delete();
}

spawn_weapon_reward(location, weapon)
{
	weaponTrigger = spawn( "trigger_radius", location, 1, 20, 20 );
	weaponTrigger setHintString("Press ^3&&1 ^7to take " + weapon);
	weaponTrigger setcursorhint( "HINT_NOICON" );
	weaponModel = spawn("script_model", location);
	weaponModel setmodel (getweaponmodel(weapon));
	level thread remove_reward(weaponTrigger, weaponModel);
	for(;;)
	{
		weaponTrigger waittill( "trigger", i );
		if(i usebuttonpressed())
		{
			if(i.rewardsClaimed[1] == false)
			{
				i.rewardsClaimed[1] = true;
				i playlocalsound( "zmb_weap_wall" );
				weapon_limit = get_player_weapon_limit( i );
				primaries = i getweaponslistprimaries();
				if ( isDefined( primaries ) && primaries.size >= weapon_limit )
				{
					i maps\mp\zombies\_zm_weapons::weapon_give( weapon );
				}
				else
				{
					i giveweapon(weapon, 0);
				}
				i switchtoweapon(weapon);
				if(if_all_players_already_claimed(1))
				{
					break;
				}
			}
		}
	}
	weaponTrigger delete();
	weaponModel delete();
}

spawn_perk_reward(location, perk)
{
	perkTrigger = spawn( "trigger_radius", location, 1, 20, 20 );
	perkTrigger setHintString("Press ^3&&1 ^7to take " + perk);
	perkTrigger setcursorhint( "HINT_NOICON" );
	perkModel = spawn("script_model", location);
	perkModel setmodel (get_perk_weapon_model( perk ));
	level thread remove_reward(perkTrigger, perkModel);
	for(;;)
	{
		perkTrigger waittill( "trigger", i );
		if(i usebuttonpressed())
		{
			if (!i hasperk( perk ) )
			{
				if(i.rewardsClaimed[2] == false)
				{
					i.rewardsClaimed[2] = true;
					i thread maps\mp\zombies\_zm_audio::playerexert( "burp" );
					i thread maps\mp\zombies\_zm_perks::give_perk( perk, 0 );
					if(if_all_players_already_claimed(2))
					{
						break;
					}
				}
			}
		}
	}
	perkTrigger delete();
	perkModel delete();
}

if_all_players_already_claimed(rewardnum)
{
	count = 0;
	foreach(player in level.players)
	{
		if(player.rewardsClaimed[rewardnum] == true)
		{
			count += 1;
		}
	}
	if(level.players.size == count)
	{
		return true;
	}
	else
	{
		return false;
	}
}

get_perk_weapon_model( perk )
{
    switch ( perk )
    {
        case " _upgrade":
        case "specialty_armorvest":
            weapon = level.machine_assets["juggernog"].weapon;
            break;
        case "specialty_quickrevive":
        case "specialty_quickrevive_upgrade":
            weapon = level.machine_assets["revive"].weapon;
            break;
        case "specialty_fastreload":
        case "specialty_fastreload_upgrade":
            weapon = level.machine_assets["speedcola"].weapon;
            break;
        case "specialty_rof":
        case "specialty_rof_upgrade":
            weapon = level.machine_assets["doubletap"].weapon;
            break;
        case "specialty_longersprint":
        case "specialty_longersprint_upgrade":
            weapon = level.machine_assets["marathon"].weapon;
            break;
        case "specialty_flakjacket":
        case "specialty_flakjacket_upgrade":
            weapon = level.machine_assets["divetonuke"].weapon;
            break;
        case "specialty_deadshot":
        case "specialty_deadshot_upgrade":
            weapon = level.machine_assets["deadshot"].weapon;
            break;
        case "specialty_additionalprimaryweapon":
        case "specialty_additionalprimaryweapon_upgrade":
            weapon = level.machine_assets["additionalprimaryweapon"].weapon;
            break;
        case "specialty_scavenger":
        case "specialty_scavenger_upgrade":
            weapon = level.machine_assets["tombstone"].weapon;
            break;
        case "specialty_finalstand":
        case "specialty_finalstand_upgrade":
            weapon = level.machine_assets["whoswho"].weapon;
            break;
    }

    if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].perk_bottle ) )
        weapon = level._custom_perks[perk].perk_bottle;

    return getweaponmodel( weapon );
}

createRewardIcon(Origin,Tier)
{
	self.reward_icon = newClientHudElem(self);
    self.reward_icon.x = Origin[0];
    self.reward_icon.y = Origin[1];
	self.reward_icon.z = Origin[2] + 40;
    self.reward_icon.alpha = 1;
    self.reward_icon setshader( "hud_icon_reward", 4, 4 );
    self.reward_icon setwaypoint( 1 );

	if(level.teddtier == 1)
	{
		self.reward_icon.color = ( 0, 1, 1 );
	}
	else if(level.teddtier == 2)
	{
		self.reward_icon.color = ( 1, 0, 1 );
	}
	else if(level.teddtier == 3)
	{
		self.reward_icon.color = ( 1, 1, 0 );
	}
	else
	{
		self.reward_icon.color = ( 1, 1, 1 );
	}

	for(;;)
	{
		if(self.rewardsClaimed[0] == true && self.rewardsClaimed[1] == true && self.rewardsClaimed[2] == true)
		{
			break;
		}
		wait 0.1;
	}
	
	self.reward_icon destroy();
}

debug_teddlocations()
{
	level waittill ("finished_logging_trials");
	if(getDvarInt("debug_teddlocations") == 1)
	{
		foreach(spot in level.teddtrialbots)
		{
			start = spot.location;
			angle = spot.angle;
			debugmodel = spawn( "script_model", start );
			debugmodel setmodel( "p6_anim_zm_bus_driver" );
			debugmodel useanimtree( #animtree );
			debugmodel animmode( "normal" );
			debugmodel setanim( %ai_zombie_bus_driver_idle );
			debugmodel rotateTo((0,angle,0),.1);
		}
	}
}