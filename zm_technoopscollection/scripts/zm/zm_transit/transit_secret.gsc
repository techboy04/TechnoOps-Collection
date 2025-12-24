#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\_utility;
#include maps\mp\_createfx;
#include maps\mp\_fx;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm_audio;
#include maps\mp\zombies\_zm_zonemgr;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_ai_dogs;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_ai_basic;
#include maps\mp\zombies\_zm_powerups;
#include scripts\zm\main;
#include maps\mp\zombies\_zm_afterlife;
#include maps\mp\gametypes_zm\_spawnlogic;
#include maps\mp\zombies\_zm_ai_avogadro;
#include maps\mp\animscripts\zm_death;
#include maps\mp\animscripts\shared;
#include maps\mp\animscripts\utility;
#include maps\mp\animscripts\zm_utility;
#include maps\mp\animscripts\zm_shared;
#include maps\mp\_visionset_mgr;
#include maps\mp\zm_transit_bus;


main()
{
	precachemodel("p6_zm_tm_radio_01");
	precachemodel("p6_zm_tm_radio_01_panel2_blood");
	precachemodel( "p6_zm_tm_dig_mound" );
	precachemodel("p6_zm_bu_sq_satellite_dish");
	precachemodel("p6_zm_bu_sq_crystal");
	precachemodel("p6_zm_work_bench");
	precachemodel("p6_zm_tm_generator_pump");
	precachemodel("p6_zm_tm_barbedwire_tube");
	precachemodel("p6_zm_tm_barbedwire_blockade");
	
	precacheshader("zom_hud_shovel_gold");
	precacheshader("zom_hud_icon_buildable_item_jg_wires");
	precacheshader("zom_hud_icon_buildable_tower_crystal");
	precacheshader("zom_hud_icon_buildable_tower_satellite");

	replacefunc(maps\mp\zombies\_zm::round_spawn_failsafe, ::round_spawn_failsafe_new);
    replaceFunc(maps\mp\zm_transit_distance_tracking::delete_zombie_noone_looking, ::delete_zombie_noone_looking);
	replacefunc(maps\mp\zombies\_zm::actor_damage_override, ::actor_damage_override);
	replacefunc(maps\mp\zombies\_zm_ai_avogadro::avogadro_prespawn, ::avogadro_prespawn);

	precachemodel("c_zom_avagadro_fb");
}

init()
{
	setLogsLocation();
	
	custom_secret_song_spawns(array((-6304.36, 5337.64, -55.875),(1747.24, -1438.61, -55.875),(-6496.36, -7859.64, 6.45054)), array(45,-134.287,-45), "mus_custom_transit_ee");
	
	if(getDvar("mapname") == "zm_transit" && getDvar( "g_gametype" ) == "zclassic" && (getDvarInt("gamemode") == 0 || getDvarInt("gamemode") == 8))
	{

	}
	else
	{
		return;
	}
	
	if(getDvarInt("guided_mode") == 1)
	{
		createGuidedHUD();
		level thread GuidedModeChecks();
	}
	level._poi_override = ::unused_override;
	level.hasdigger = false;
	level.workbenchbuilt = false;
	level.workbenchactivated = false;
	level.partmodels = array("p6_zm_bu_sq_satellite_dish","p6_zm_bu_sq_crystal","p6_zm_tm_barbedwire_tube");
	level.parts = array(false,false,false);
	level.dirtPilesList = array((7726.28, -5133.31, 37.4349),(7813.05, -4956.94, 43.0341),(7806.02, -4723.67, 44.2192));
	level thread workbench((1486.65, 2060.84, -47.8691), 0);
	level.pickeduplavamachine = false;
	lavaPools = array((1337.36, 176.989, -69.875),(-11303, -2026.11, 184.125),(10049.9, -1216.3, -217.875));
	
	if(getDvarInt("force_spawn_boss") == 1)
	{
		level thread spawnBossStart();
	}
	
	level.chosenLavaPool = lavaPools[randomintrange(0,lavaPools.size - 1)];
	
	level waittill ("power_on");
	level thread spawnPhone();
	level.defensemode = false;
}

GuidedModeChecks()
{
//	updateGuidedHUDIcon(destination, icon, includeDistanceText);
	level waittill ("start_of_round");
	updateGuidedHUDIcon((12165.7, 8464.13, -751.375), "objective_marker", true);
	updateGuidedHUD("Turn on the Power");
	level waittill ("power_on");
	updateGuidedHUDIcon((-6480.5, 5292.81, 3.07276), "objective_marker", true);
	updateGuidedHUD("Answer the Phone in the Bus Depot");
	while(level.mainqueststarted == false)
	{
		wait 0.1;
	}
	updateGuidedHUDIcon((-4183, -7764, -61.86), "objective_marker", true);
	updateGuidedHUD("Pickup the Shovel at the Diner");
	while(level.hasshovel == false)
	{
		wait 0.1;
	}
	updateGuidedHUDIcon((7775.22, -5054.64, 40), "search_marker", true);
	updateGuidedHUD("Dig up the Sattelite at the Barn");
	while(level.parts[0] == false)
	{
		wait 0.1;
	}
	updateGuidedHUDIcon((4101.23, 5488.46, -63.875), "objective_marker", true);
	updateGuidedHUD("Kill Zombies near the Radio to drop Wires");
	while(level.parts[2] == false)
	{
		wait 0.1;
	}
	updateGuidedHUDIcon((1525.15, 2226.91, -52.5979), "objective_marker", true);
	updateGuidedHUD("Pickup the Lava Digger Machine near the Workbench");
	while(level.hasdigger == false)
	{
		wait 0.1;
	}
	GuidedModeMachine();
	updateGuidedHUDIcon(level.chosenLavaPool, "objective_marker", true);
	updateGuidedHUD("Pickup the Crystal from the Machine");
	while(level.parts[1] == false)
	{
		wait 0.1;
	}
	updateGuidedHUDIcon((1486.65, 2060.84, -47.8691), "objective_marker", true);
	updateGuidedHUD("Place all the parts onto the Workbench");
	while(level.workbenchbuilt == false)
	{
		wait 0.1;
	}
	updateGuidedHUDIcon((1486.65, 2060.84, -47.8691), "objective_marker", true);
	updateGuidedHUD("Fuel the Workbench with Zombie Kills");
	while(level.currentsouls < level.maxsouls)
	{
		wait 0.1;
	}
	updateGuidedHUDIcon((1486.65, 2060.84, -47.8691), "objective_marker", true);
	updateGuidedHUD("Begin the Workbench Connection");
	while(level.workbenchactivated == false)
	{
		wait 0.1;
	}
	updateGuidedHUDIcon((1486.65, 2060.84, -47.8691), "objective_marker", true);
	updateGuidedHUD("Defend the Workbench");
	while(level.workbenchactivated == true)
	{
		wait 0.1;
	}
	updateGuidedHUDIcon((1765.37, -88.9562, -33.9563), "objective_marker", true);
	updateGuidedHUD("Interact with the floating Crystal and deal with the Disturbance");
	while(level.bossstarted == 0)
	{
		wait 0.1;
	}
	removeGuidedHUDIcon();
	removeGuidedHUD();
}

GuidedModeMachine()
{
	for(;;)
	{
		updateGuidedHUDIcon(level.chosenLavaPool, "objective_marker", true);
		updateGuidedHUD("Place the Digger on a Lava Pool");
		while(level.defensemode == false)
		{
			wait 0.1;
		}
		updateGuidedHUDIcon(level.chosenLavaPool, "defense_marker", true);
		updateGuidedHUD("Defend the Machine until time runs out");
		level waittill_any( "machine_destroyed", "end_quest_rage", "end_game" );
		if(!isDefined(level.machine))
		{
			wait 0.1;
		}
		else
		{
			break;
		}
	}
}

spawnRadio(location, angle, log, log_duration)
{
	radioTrigger = spawn( "trigger_radius", (location), 1, 50, 50 );
	radioTrigger setHintString("Press ^3&&1 ^7to tune a channel");
	radioTrigger setcursorhint( "HINT_NOICON" );
	radioModel = spawn( "script_model", (location));
	radioModel setmodel ("p6_zm_tm_radio_01");
    radioModel attach( "p6_zm_tm_radio_01_panel2_blood", "tag_j_cover" );
	radioModel rotateTo((0,angle,0),.1);
	radioTrigger.channel = 0;
	radioTrigger.audiofile = log;
	radioTrigger.canPlayLog = false;
	radioTrigger.initLog = false;
	radioTrigger thread channels(randomintrange(1,3));
	for(;;)
	{
		radioTrigger waittill( "trigger", i );
		if ( i usebuttonpressed() )
		{
			if (radioTrigger.canChange == true)
			{
				radioTrigger.canChange = false;
				radioTrigger setHintString("Tuning...");
				if (radioTrigger.channel >= 3)
				{
					radioTrigger.channel = 0;
				}
				radioTrigger.channel += 1;
				radioTrigger notify ("channel_change");
			}
			
			if (radioTrigger.canPlayLog == true)
			{
				radioTrigger setHintString("");
				radioTrigger playsound (log);
				wait log_duration;
				if(radioTrigger.initLog == false)
				{
					radioTrigger.initLog = true;
					level.radiosused += 1;
					if(level.radiosused == level.totalradios)
					{
						if(getDvar("mapname") == "zm_transit" && getDvar("g_gametype") == "zclassic")
						{
							level thread spawnSecretRadio((1052.16, 394.948, -270.865),0);
						}
					}
				}
				radioTrigger setHintString("Press ^3&&1 ^7to play the decrypted audio log");
			}
		}
		wait 0.1;
	}
}

channels(num)
{
	self.channel = 0;
	for(;;)
	{
		self waittill ("channel_change");
		self setHintString(""); 
		self stopsounds();
		wait 0.1;
		self playsound( "radio_tune" );
		wait 4;
		if(self.channel == num && level.pickedupscrambler == 1)
		{
			self.canChange = false;
			self setHintString("Decrypting..."); 
			self startHorde();
			self.canPlayLog = true;
			self setHintString("Press ^3&&1 ^7to play the decrypted audio log");
		}
		else
		{
			self.canChange = true;
			self setHintString("Press ^3&&1 ^7to tune a channel");
			if(self.channel == 1)
			{
				self thread loopMusic("radio_music_1");
			}
			else if(self.channel == 2)
			{
				self thread loopMusic("radio_music_2");
			}
			else if (self.channel == 3)
			{
				self thread loopMusic("radio_music_3");
			}
		}
	}
}

startHorde()
{
	self thread loopMusic("radio_static");

	spawner = random( level.zombie_spawners );
	
	spawn_point = level.zombie_spawn_locations[randomint( level.zombie_spawn_locations.size )];

	oldtotal = maps\mp\zombies\_zm_utility::get_round_enemy_array().size + level.zombie_total;

	level.zombie_total = 100;

	spawn_zombie( spawner, spawner.target_name, spawn_point);
	
	self thread forcerun();

	wait 30;
	
	end_horde();
	
	level.zombie_total = oldtotal;
	
	wait 1;
	
	self stopsounds();
}

loopMusic(music)
{
	self endon ("channel_change");
	self endon ("end_horde");
	for(;;)
	{
		self playsound( music );
		wait 0.1;
	}
}

forcerun()
{
 	self endon ("end_horde");
	level endon ("boss_died");
	for(;;)
	{
		can_sprint = false;
		zombies = getAiArray(level.zombie_team);
		foreach(zombie in zombies)
		if(!isDefined(zombie.cloned_distance))
			zombie.cloned_distance = zombie.origin;
		else if(distance(zombie.cloned_distance, zombie.origin) > 15){
			can_sprint = true;
			zombie.cloned_distance = zombie.origin;
			if(zombie.zombie_move_speed == "run" || zombie.zombie_move_speed != "sprint")
				zombie maps\mp\zombies\_zm_utility::set_zombie_run_cycle("sprint");
		}else if(distance(zombie.cloned_distance, zombie.origin) <= 15){
			can_sprint = false;
			zombie.cloned_distance = zombie.origin;
			zombie maps\mp\zombies\_zm_utility::set_zombie_run_cycle("run");
		}
		wait 1;
	}
}

end_horde()
{
	zombies = getaiarray( level.zombie_team );
	
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}
	
	self notify ("end_horde");
}

setLogsLocation()
{
	if ( getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("ui_zm_mapstartlocation") == "town")
		{
			level thread spawnRadio((1965.17, -114.181, -17),90,"vox_town_audiolog", 14);
			level.totalradios = 1;
			level thread placeScrambler((842.799, -1535.87, -28.8237),(-45,-2,0));
		}
		else if (getDvar("ui_zm_mapstartlocation") == "transit")
		{
			level thread spawnRadio((-5998.35, 4408.7, -46.0484),-169,"vox_busdepot_audiolog", 16);
			level.totalradios = 1;
		}
		else if (getDvar("ui_zm_mapstartlocation") == "farm")
		{
			level thread spawnRadio((8482.81, -5274.12, 306.288),-122,"vox_farm_audiolog", 11);
			level.totalradios = 1;
			level thread placeScrambler((8490.05, -5865.29, 68.2933),(-45,0,104));
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_transit") //transit
		{
			level thread placeScrambler((-7779.18, 4483.31, -21.3313),(270,-162.59,0));
			
			level thread spawnRadio((-11028, -163.923, 212.214),-18,"vox_transit_audiolog_1", 22); //Tunnel
			
			level thread spawnRadio((1166.46, -5708.31, -63.8756),27,"vox_transit_audiolog_2", 13); //Forest
			
			level thread spawnRadio((13722, -212.855, -124.357),-88,"vox_transit_audiolog_3", 19); //Nacht
			
			level.totalradios = 3;
		}
	}
	level.pickedupscrambler = 0;
}

spawnSecretRadio(location, angle)
{
	secretRadioTrigger = spawn( "trigger_radius", (location), 1, 50, 50 );
	secretRadioTrigger setHintString("Press ^3&&1 ^7to tune a channel");
	secretRadioTrigger setcursorhint( "HINT_NOICON" );
	secretRadioModel = spawn( "script_model", (location));
	secretRadioModel setmodel ("p6_zm_tm_radio_01");
    secretRadioModel attach( "p6_zm_tm_radio_01_panel2_blood", "tag_j_cover" );
	secretRadioModel rotateTo((0,angle,0),.1);
	secretRadioTrigger.channel = 0;
	secretRadioTrigger thread secretchannels(3);
	
	secretRadioTrigger.audiofile = "vox_transit_audiolog_4";
	secretRadioTrigger.canPlayLog = false;
	secretRadioTrigger.initLog = false;
	
	for(;;)
	{
		secretRadioTrigger waittill( "trigger", i );
		if ( i usebuttonpressed() )
		{
			if (secretRadioTrigger.canChange == true)
			{
				secretRadioTrigger.canChange = false;
				secretRadioTrigger setHintString("Tuning...");
				if (secretRadioTrigger.channel >= 3)
				{
					secretRadioTrigger.channel = 0;
				}
				secretRadioTrigger.channel += 1;
				secretRadioTrigger notify ("channel_change");
			}
			
			if (secretRadioTrigger.canPlayLog == true)
			{
				secretRadioTrigger setHintString("");
				secretRadioTrigger playsound (secretRadioTrigger.audiofile);
				wait 28;
				if(secretRadioTrigger.initLog == false)
				{
					secretRadioTrigger.initLog = true;
				}
				secretRadioTrigger setHintString("Press ^3&&1 ^7to play the decrypted audio log");
			}
		}
	}
}

startSuperHorde()
{
	self thread loopMusic("radio_static");

	spawner = random( level.zombie_spawners );
	
	spawn_point = level.zombie_spawn_locations[randomint( level.zombie_spawn_locations.size )];

	oldtotal = maps\mp\zombies\_zm_utility::get_round_enemy_array().size + level.zombie_total;

	level.zombie_total = 100;
	
	spawn_zombie( spawner, spawner.target_name, spawn_point);
	
	self thread forcerun();

	wait 60;
	
	self end_horde();
	
	level.zombie_total = oldtotal;
	
	wait 0.1;
	
	self stopsounds();
}

secretchannels(num)
{
	self.channel = 0;
	for(;;)
	{
		self waittill ("channel_change");
		self setHintString(""); 
		self stopsounds();
		wait 0.1;
		self playsound( "radio_tune" );
		wait 4;
		if(self.channel == num)
		{
			self.canChange = false;
			self startSuperHorde();
			self.canPlayLog = true;
			self setHintString("Press ^3&&1 ^7to play the decrypted audio log");
		}
		else
		{
			self.canChange = true;
			self setHintString("Press ^3&&1 ^7to tune a channel");
			if(self.channel == 1)
			{
				self thread loopMusic("radio_music_1");
			}
			else if(self.channel == 2)
			{
				self thread loopMusic("radio_music_2");
			}
		}
	}
}

spawnDirtPile(location, isPart)
{
	digTrigger = spawn( "trigger_radius", (location), 1, 50, 50 );
	digTrigger setHintString("A shovel is required");
	digTrigger setcursorhint( "HINT_NOICON" );
	digModel = spawn( "script_model", (location));
	digModel setmodel ("p6_zm_tm_dig_mound");
	angle = randomintrange(0,180);
	digModel rotateTo((0,angle,0),.1);
	
	for(;;)
	{
		digTrigger waittill( "trigger", i );
		
		if(level.hasshovel == true)
		{
			
			digTrigger setHintString("Press ^3&&1 ^7to dig");
			
			if ( i usebuttonpressed() )
			{
				if(isPart)
				{
					level thread spawnPart(location, 0);
				}
				else
				{
					level thread digPilePowerup("bonus_points_team", digTrigger.origin);
				}
			
				digTrigger delete();
				digModel delete();
			}
		}
		wait 0.1;
	}
}

createPiles(chosenpile)
{
	foreach (pile in level.dirtPilesList)
	{
		if (pile == chosenpile)
		{
			isPart = true;
		}
		else
		{
			isPart = false;
		}
		level thread spawnDirtPile(pile, isPart);
	}
}

displaySpawnerSize()
{
	for(;;)
	{
		
		foreach (player in level.players)
		{
			player iprintln(level.machine.health);
		}
		
		wait 5;
	}
}

tranzitEEsequence()
{
	level thread ignoreAllPlayers(1);
	thread nuke_flash();
	wait 2;
	do_vox_subtitles("Phone", "Hello? Anyone there?", 3, "vox_intro_1");
	do_vox_subtitles("Entity", "I recognize that voice!", 2, "vox_intro_2");
	do_vox_subtitles("Phone", "Im stuck in some part of the Aether, like a deeper layer of it.", 4, "vox_intro_3");
	do_vox_subtitles("Entity", "He cant hear us. We gotta build a bigger connection!", 3, "vox_intro_4");
	do_vox_subtitles("Entity", "You must find the parts to the device so we can contact him!", 4, "vox_intro_5");
	level.mainqueststarted = true;
	level thread ignoreAllPlayers(0);
	
	level thread minion_round_watcher();

	level thread createPiles(random(level.dirtPilesList));
	level thread spawnMachine((1525.15, 2226.91, -52.5979));

	foreach (player in level.players)
	{
		player thread random_part3_players();
	}
	
	level waittill ("quest_step_1");
	wait 5;
	do_vox_subtitles("Entity", "Perfect! Now we must power it up with some fresh flesh!", 4, "vox_step_1");
	level thread setObjective("Powerup the Workbench", "objective_marker", (1618.14, 2065.54, -61.4088));
	workbench_fuel_step();
	do_vox_subtitles("Entity", "Its fully powered! Lets turn it on!", 3, "vox_step_2");
	level thread spawnFinalEncounterTrigger((1486.65, 2060.84, -47.8691));
}

chooseDirtReward()
{

}

spawnPart(location, partnum)
{
	partTrigger = spawn( "trigger_radius", (location), 1, 50, 50 );
	partTrigger setHintString("Press ^3&&1 ^7to pickup");
	partTrigger setcursorhint( "HINT_NOICON" );
	partModel = spawn( "script_model", (location));
	partModel setmodel (level.partmodels[partnum]);
	angle = randomintrange(0,180);
	partModel rotateTo((0,angle,0),.1);
	
	wait 1;
	
	for(;;)
	{
		partTrigger waittill( "trigger", i );
		if ( i usebuttonpressed() )
		{	
			i playlocalsound( "fly_equipment_pickup_plr" );

			level.parts[partnum] = true;
			
			partTrigger delete();
			partModel delete();

			if(partnum == 0)
			{
				if(getDvarInt("enable_toasts") == 1)
				{
					send_toast(i.name + " picked up a Satellite", "zom_hud_icon_buildable_tower_satellite", "Quest Item");
				}
				else
				{
					notify_player_action(i.name + " picked up a satellite");
				}
				do_vox_subtitles("Entity", "The satellite will be perfect for projecting the connection.", 3, "vox_part_1");
			}
			else if(partnum == 1)
			{
				if(getDvarInt("enable_toasts") == 1)
				{
					send_toast(i.name + " picked up a Crystal", "zom_hud_icon_buildable_tower_crystal", "Quest Item");
				}
				else
				{
					notify_player_action(i.name + " picked up a crystal");
				}
				do_vox_subtitles("Entity", "That crystal is useful for going past the Aethers barrier. Letting us reach to him!", 5, "vox_part_2");
			}
			else if(partnum == 2)
			{
				if(getDvarInt("enable_toasts") == 1)
				{
					send_toast(i.name + " picked up Wires", "zm_hud_icon_jetgun_wires", "Quest Item");
				}
				else
				{
					notify_player_action(i.name + " picked up wires");
				}
				do_vox_subtitles("Entity", "Those electronic parts could help add that extra energy to our connection.", 4, "vox_part_3");
			}
			
			if(level.parts[0] == true && level.parts[1] == true && level.parts[2] == true)
			{
				do_vox_subtitles("Entity", "We have all the parts! Lets finish that workbench.", 3, "vox_part_finished");
			}
		}
		wait 0.1;
	}
}

spawnLavaDiggerTrigger(location)
{
	diggerTrigger = spawn( "trigger_radius", (location), 1, 50, 50 );
	diggerTrigger setHintString("Press ^3&&1 ^7to place the lava machine");
	diggerTrigger setcursorhint( "HINT_NOICON" );
	
	for(;;)
	{
		diggerTrigger waittill( "trigger", i );
		diggerTrigger setHintString("Press ^3&&1 ^7to place the lava machine");
		if ( i usebuttonpressed() && level.exfilstarted == 0)
		{
			level thread spawnDiggerMachine(location);
			diggerTrigger delete();
		}
		wait 0.1;
	}
}

loopDiggerFX()
{
	level endon ("machine_destroyed");
	level endon ("end_quest_rage");
	
	for(;;)
	{
		playfx(level._effect["turbine_on"], level.machine.origin);
		playfx(level._effect["turbine_med"], level.machine.origin);
		playfx(level._effect["turbine_low"], level.machine.origin);
		playfx(level._effect["turbine_aoe"], level.machine.origin);
		wait 1;
	}
}

playstep2music()
{
    ent = spawn( "script_origin", ( 0, 0, 0 ) );
    ent thread stopstep2music();
	ent playloopsound( "mus_machine_loop", 0.1 );
}

stopstep2music()
{
    level waittill_any( "machine_destroyed", "end_quest_rage", "end_game" );
    self stoploopsound(0.1);
    wait 1;
    self delete();
}


spawnDiggerMachine(location)
{
	level endon ("machine_destroyed");
	
	partTrigger = spawn( "trigger_radius", (location + (0,0,15)), 1, 50, 50 );
	partTrigger setcursorhint( "HINT_NOICON" );
	level.machine = spawn( "script_model", (location));
	level.machine setmodel ("t6_wpn_zmb_jet_gun_world");
	angle = randomintrange(0,180);
	level.machine rotateTo((90,90,180),.01);
	
	level.machine.health = 100;
	
	if(level.zombie_total > 0)
	{
		level.oldtotal = level.zombie_total;
	}
	else
	{
		level.oldtotal = 4;
	}
	
	thread nuke_flash();
	
	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}

	earthquake( 1, 1.8, location, 256 );
	
	if(getDvarInt("guided_mode") == 1)
	{
		level thread do_vox_subtitles("Entity", "I guess they dont like that!", 2, "vox_part_2_start"); //????
	}

	level thread startSecondPartHorde();
	
	level thread changeZombieTarget();
	level thread step2defensehud();
	level thread minion_spawner_defense();
	
	level.defensemode = true;
	
	level._poi_override = ::defense_zombie;
	
	foreach(player in level.players)
	{
		player thread step2defensehealthbar();
	}
	
	level thread loopDiggerFX();
	
	level thread playstep2music();
	
	wait 90;
	
	level.defensemode = false;
	
	level._poi_override = ::unused_override;
	
	zombies = getaiarray( level.zombie_team );
	
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}
	
	level notify ("end_quest_rage");
	level.zombie_total = level.oldtotal;
	thread nuke_flash();
	earthquake( 1, 1.8, location, 256 );
	partTrigger delete();
	
	offset_x = location[0] + 0.2;
	offset_y = location[1] + 16.01;
	offset_z = location[2] + 20.016;
	
	
	level thread spawnPart((offset_x,offset_y,offset_z), 1);
	
	level thread setObjective("Find the parts", "", (0,0,0));
}

// (-11206.8, -1142.57, 204.141)
end_machine_defense_fail()
{
	level.defensemode = false;
	
	zombies = getaiarray( level.zombie_team );
	
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}
	
	level notify ("end_quest_rage");
	level notify ("machine_destroyed");
	
	level.zombie_total = level.oldtotal;
	
	thread nuke_flash();
	
	earthquake( 1, 1.8, level.machine.origin, 256 );
	
	level.machine delete();
	
	do_vox_subtitles("Entity", "Oh no! The machine is destroyed! Repairing it now.", 4, "vox_part_2_fail");
	
	level waittill("between_round_over");
	
	level thread spawnLavaDiggerTrigger(level.chosenLavaPool);
	
	do_vox_subtitles("Entity", "The machine is repaired. You can start it again!", 3, "vox_part_2_tryagain");
}


startSecondPartHorde()
{
	level endon ("end_quest_rage");
	
	for(;;)
	{
		level.zombie_total = 40;
		wait 0.1;
	}
}

changeZombieTarget()
{
    level endon ("end_quest_rage");
	
	for(;;)
    {
        playables = getentarray( "player_volume", "script_noteworthy" );
        zombies = getAIArray( level.zombie_team );
        foreach (zombie in zombies)
        {
            for( a = 0; a < playables.size; a++ )
            {
                if( (!( isdefined(zombie.is_mechz) && zombie.is_mechz )  && !( isdefined( zombie.ATK ) && zombie.ATK ) && isdefined( zombie ) && zombie isTouching( playables[ a ] ) && zombie.completed_emerging_into_playable_area == 1 && zombie.is_traversing == 0 && !( isdefined( zombie.is_traversing ) && zombie.is_traversing ) && zombie.ai_state == "find_flesh"))
                {
                    zombie.ATK = 1;
					zombie set_zombie_run_cycle("sprint");
					
					zombie thread attack_function();
                }
            }
        }
        wait 0.05;
    }
}

defense_zombie()
{
    TargetOrg = [];

	TargetOrg[0] = level.machine.origin;
	TargetOrg[1] = level.machine;

    if ( ( isdefined(self.is_mechz) && self.is_mechz ) || level.defensemode != true)
    {
        return undefined;
    }

	if(self.turned && isDefined(self.turned))
	{
		return;
	}
	return TargetOrg;
}

quest_zombie()
{
    TargetOrg = [];

	TargetOrg[0] = groundpos( level.workbench.origin );
	TargetOrg[1] = level.workbench;

    if ( ( isdefined(self.is_mechz) && self.is_mechz ) || level.defensemode != true)
    {
        return undefined;
    }
	
	if(self.turned && isDefined(self.turned))
	{
		//attack zombies
	}
	else
	{
		return TargetOrg;
	}
}

unused_override()
{
	if(isDefined(self.turned) && self.turned)
	{
		//attack zombies
	}
	else
		zombie_poi = self get_zombie_point_of_interest( self.origin );
	
	return zombie_poi;
}

attack_function()
{
    self endon( "death" );
	
    if(getdvar("mapname") == "zm_tomb")
        attackanim = "zm_generator_melee";
    else
        attackanim = "zm_riotshield_melee";
    
    if ( !self.has_legs )
        attackanim += "_crawl";
    for(;;)
    {
        if(distance(self.origin, level.machine.origin) <= 50 && level.defensemode == 1)
        {
			angles = VectorToAngles( level.machine.origin - self.origin );
			self animscripted( self.origin, angles, attackanim );
			if(getDvarInt("guided_mode") == 1)
			{
				level.machine machine_damage(1);
			}
			else
			{
				level.machine machine_damage(3);
			}
			wait 1;
        }
		else
        {
            self stopanimscripted();
        }    
        wait 0.05; 
    }
}

machine_damage(amount)
{
	if(level.defensemode != true)
	{
		return;
	}
	
	self playsound("fly_riotshield_zm_impact_zombies");
	
	self.health -= amount;
	
	if(self.health <= 0)
	{
		self playsound("wpn_riotshield_zm_destroy");
		level thread end_machine_defense_fail();
	}
}

step2defensehud()
{
	level endon("end_game");

	level.step2defense_text = newhudelem();
	level.step2defense_text.alignx = "left";
	level.step2defense_text.aligny = "top";
	level.step2defense_text.horzalign = "user_left";
	level.step2defense_text.vertalign = "user_top";
	level.step2defense_text.x = 60;
	level.step2defense_text.y = 20;
	level.step2defense_text.fontscale = 1;
	level.step2defense_text.alpha = 1;
	level.step2defense_text.color = ( 1, 1, 1 );
	level.step2defense_text.hidewheninmenu = 1;
	level.step2defense_text.foreground = 0;
	level.step2defense_text.label = &"Defend the machine: ^6";
	level.step2defense_text setTimer(90);
	
	level waittill ("end_quest_rage");
	
	level.step2defense_text destroy();
}

step2defensehealthbar()
{
	defense_bar = self createprimaryprogressbar();
	defense_bar setpoint("TOP_LEFT", undefined, 0, 0);
	defense_bar.hidewheninmenu = 1;
	defense_bar.bar.hidewheninmenu = 1;
	defense_bar.barframe.hidewheninmenu = 1;
	defense_bar.alpha = 1;
	
	while(level.defensemode)
	{
		defense_bar updatebar(level.machine.health / 100);
		wait 0.1;
	}
	
	defense_bar.barframe destroy();
	defense_bar.bar destroy();
	defense_bar destroy();
}

// Workbench (1486.65, 2060.84, -47.8691) p6_zm_work_bench -4.13693				Sat dish = (1481.32, 2071.77, 11.1344) - Angle: 178.554  (1480.42, 2077.18, 31.2526)

workbench(location, angle)
{
	benchTrigger = spawn( "trigger_radius", (location), 1, 50, 50 );
	benchTrigger setHintString("Press ^3&&1 ^7to build");
	benchTrigger setcursorhint( "HINT_NOICON" );
	benchModel = spawn( "script_model", (location));
	benchModel setmodel ("p6_zm_work_bench");
	benchModel rotateTo((0,angle,0),.1);
	
	radioModel = spawn( "script_model", (location + (0,0,43.73217)));
	radioModel setmodel ("p6_zm_buildable_sq_transceiver");
	radioModel rotateTo((0,angle+90,0),.1);
	
	wait 3;
	
	level.workbench = benchModel;
	
	wait 1;
	
	for(;;)
	{
		benchTrigger waittill( "trigger", i );
		
		if((level.parts[0] == true) && (level.parts[1] == true) && (level.parts[2] == true))
		{
			benchTrigger setHintString("Press ^3&&1 ^7to build");
			if ( i usebuttonpressed() )
			{
				thread placeitem(location, angle);
				benchTrigger setHintString("");

				level waittill ("final_encounter_started");
				
				playfx(level._turbine_disappear_fx, benchModel.origin);
				playfx(level._turbine_disappear_fx, radioModel.origin);
				
				benchModel delete();
				radioModel delete();
				benchTrigger delete();
			}
		}
		else
		{
			benchTrigger setHintString("Need more parts!");
		}
		
		wait 0.1;
	}
}

placeitem(location, angle)
{
	level notify ("quest_step_1");
	level.workbenchbuilt = true;

	satModel = spawn( "script_model", (location[0] - 5.33, location[1] + 10.93, location[2] + 59.0035));
	satModel setmodel ("p6_zm_bu_sq_satellite_dish");
	satModel rotateTo((0, angle + 178.554,0),.1);
	
	cryModel = spawn("script_model", (location [0] - 6.23, location[1] + 16.34, location[2] + 79.1217) );
	cryModel setmodel ("p6_zm_bu_sq_crystal");
	cryModel rotateTo((45, angle + 89.6274,0),.1);
	
	playfx(level._effect["powerup_grabbed"], satModel.origin);
	playfx(level._effect["powerup_grabbed"], cryModel.origin);
	
	level waittill ("final_encounter_started");
	
	playfx(level._turbine_disappear_fx, satModel.origin);
	playfx(level._turbine_disappear_fx, cryModel.origin);
	
	satModel delete();
	cryModel delete();
	
}

//	cryModel = spawn("script_model", (1480.42, 2077.18, 31.2526) );
//	satModel = spawn( "script_model", (1481.32, 2071.77, 11.1344));

defenseBench(location, angle)
{
	benchModel = spawn( "script_model", (location));
	benchModel setmodel ("p6_zm_work_bench");
	benchModel rotateTo((0,angle,0),.1);
	
	radioModel = spawn( "script_model", (location + (0,0,43.73217)));
	radioModel setmodel ("p6_zm_buildable_sq_transceiver");
	radioModel rotateTo((0,angle+90,0),.1);

	satModel = spawn( "script_model", (location[0] - 5.33, location[1] + 10.93, location[2] + 59.0035));
	satModel setmodel ("p6_zm_bu_sq_satellite_dish");
	satModel rotateTo((0, angle + 178.554,0),.1);
	
	cryModel = spawn("script_model", (location [0] - 6.23, location[1] + 16.34, location[2] + 79.1217) );
	cryModel setmodel ("p6_zm_bu_sq_crystal");
	cryModel rotateTo((45, angle + 89.6274,0),.1);
	
	level thread loopBenchFX(array(benchModel.origin,radioModel.origin,satModel.origin,cryModel.origin));
	
	level.workbench = benchModel;
	
	playfx(level._effect["powerup_grabbed"], satModel.origin);
	playfx(level._effect["powerup_grabbed"], cryModel.origin);
	
	level thread playRadioAmbience(radioModel.origin);
	
	level waittill ("main_defense_over");
	
	playfx(level._turbine_disappear_fx, radioModel.origin);
	playfx(level._turbine_disappear_fx, satModel.origin);
	playfx(level._turbine_disappear_fx, cryModel.origin);
	playfx(level._turbine_disappear_fx, benchModel.origin);
	
	benchModel delete();
	radioModel delete();
	satModel delete();
	cryModel delete();
	
}

workbench_fuel_step()
{
	foreach (player in level.players)
	{
		player thread workbench_fuel_players();
	}
	
	level.currentsouls = 0;
	level.maxsouls = 50;
	
	level thread loopFuelFX();
	
	while(level.currentsouls < level.maxsouls)
	{
		level waittill ("fuel_machine");
		level.currentsouls += 1;
		wait 0.1;
	}
	level notify ("fuel_completed");
}

loopFuelFX()
{
	level endon ("fuel_completed");
	
	for(;;)
	{
		soul = level.currentsouls;
		maxsoul = level.maxsouls;
		
		low = maxsoul/4;
		med = maxsoul/2;
		high = maxsoul/2 + maxsoul/4;
	
		playfx(level._effect["turbine_on"], level.workbench.origin);
		if(soul >= low)
		{
			playfx(level._effect["turbine_low"], level.workbench.origin);
		}
		if(soul >= med)
		{
			playfx(level._effect["turbine_med"], level.workbench.origin);
		}
		if(soul >= high)
		{
			playfx(level._effect["turbine_aoe"], level.workbench.origin);
		}
		wait randomfloatrange(0.1,1);
	}
}

workbench_fuel_players()
{
	level endon ("fuel_completed");
	
	for(;;)
	{
		self waittill( "zom_kill", zombie);
		if(distance(zombie.origin, level.workbench.origin) <= 600 )
		{
			playfx(level._effect["powerup_grabbed"], zombie.origin);
			level notify ("fuel_machine");
		}
		wait 0.1;
	}
}

spawnPhone()
{
	locations = (-6480.5, 5292.81, 3.07276);
	
	phoneTrigger = spawn( "trigger_radius", (locations), 1, 20, 100 );
	phoneTrigger setHintString("Press ^3&&1 ^7to answer");
	phoneTrigger setcursorhint( "HINT_NOICON" );
	
	if(!is_quest_blocked())
	{
		level thread playphone(locations);
	}
	
	for(;;)
	{
		phoneTrigger waittill( "trigger", i );
		
		if(i usebuttonpressed() && !is_quest_blocked(i))
		{
			phoneTrigger setHintString("");
			level notify ("phone_answered");
			phoneTrigger playsound("mus_story_1_intro");
			level thread tranzitEEsequence();
			break;
		}
		
		wait 0.1;
	}
}

playphone(location)
{
    ent = spawn( "script_origin", location );
    ent thread stopphone();
	ent playloopsound( "phone_ring", 0.1 );
}

stopphone()
{
    level waittill_any( "end_game", "phone_answered" );
    self stoploopsound( 0.1 );
    wait 1;
    self delete();
}

finalEncounterSequence()
{
	level maps\mp\zombies\_zm_powerups::specific_powerup_drop("full_ammo", (1490.28, 1962.94, -47.4356));
	
	level.holdround = true;
	level.zombie_total = 0;
	
	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}
	thread nuke_flash();
	
	level thread ignoreAllPlayers(1);
	
	earthquake( 1, 1.8, level.workbench.origin, 256 );
	
	level.infinalphase = true;
	
	level thread playfinalintromusic();
	
	wait 2;

	do_vox_subtitles("Entity", "Establishing connection…", 2, "vox_final_intro_1");
	do_vox_subtitles("Entity", "Its working! Its actually working!", 3, "vox_final_intro_2");
	do_vox_subtitles("Phone", "*garbles* Hello? I think I can hea- *static*", 4, "vox_final_intro_3");
	do_vox_subtitles("Entity", "The connection is choppy! Moving the bench for a better signal!", 3, "vox_final_intro_4");
	
	if(getDvarInt("guided_mode") == 1)
	{
		do_vox_subtitles("Entity", "Uh oh. Looks like the undead dont like the workbench. You must protect it!", 5, "vox_final_intro_5");
	}
	
	level thread ignoreAllPlayers(0);
	
	level.workbenchmaxhealth = 300;
	
	level.workbenchhealth = level.workbenchmaxhealth;
	
	level notify ("main_defense_over");
	level thread playfinaltransitionmusic();

	level thread finalDefenseEncounter();
	level thread startDefenseHorde();
	
	level thread finaldefensehud();
	level thread minion_spawner_defense();
	foreach (player in level.players)
	{
		player thread finaldefensehealthbar();
	}
	
	level.defensemode = true;
	
	level._poi_override = ::quest_zombie;
	
	level notify ("final_encounter_started");
	
	thread defenseBench((1225.66, -1054.34, -55.875), 0);
	level.defense_text.label = &"Get to the workbench at Town ^6";
	updateGuidedHUDIcon((1225.66, -1054.34, -55.875), "defense_marker", false);
	level.candamagebench = true;
	startEncounterIfPlayersAreNear();
	level.candamagebench = false;
	destroyFinalDefenseHUD();
	do_vox_subtitles("Entity", "This spot is no good! Moving to a new area!", 3, "vox_final_1");
	createFinalDefenseHUD();
	level.defense_text.label = &"Get to the workbench at Farm ^6";
	thread defenseBench((7927.59, -5516.93, 37.3758),-100.569);
	updateGuidedHUDIcon((7927.59, -5516.93, 37.3758), "defense_marker", false);
	level.candamagebench = true;
	startEncounterIfPlayersAreNear();
	level.candamagebench = false;
	destroyFinalDefenseHUD();
	do_vox_subtitles("Entity", "God damnit not here either!", 2, "vox_final_2");
	createFinalDefenseHUD();
	level.defense_text.label = &"Get to the workbench at Diner ^6";
	thread defenseBench((-5248.32, -7148.79, -58.875),0);
	updateGuidedHUDIcon((-5248.32, -7148.79, -58.875), "defense_marker", false);
	level.candamagebench = true;
	level thread if_all_players_are_too_far_away();
	startEncounterIfPlayersAreNear(1);
	level.candamagebench = false;
	
	level notify ("stop_endless_horde");
	
	level.zombie_total = 0;
	
	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}
	thread nuke_flash();
	earthquake( 1, 1.8, level.workbench.origin, 256 );

	destroyFinalDefenseHUD();

	do_vox_subtitles("Entity", "I got it! The connection is stable!", 3, "vox_final_3");
	do_vox_subtitles("Phone", "Its strong! I hear you perfectly!", 3, "vox_final_4");
	do_vox_subtitles("Entity", "Im getting you out of there! This connection should definitely help. Look out for the portal!", 5, "vox_final_5");
	do_vox_subtitles("Phone", "I see it! Entering now! *portal sounds*", 10, "vox_final_6");

	level notify ("main_quest_over");
	
	earthquake( 1, 5, level.workbench.origin, 3000 );

	do_vox_subtitles("Entity", "Something is jamming the signal!", 2, "vox_final_8");
	do_vox_subtitles("Entity", "Sounds like its coming from the Town!", 3, "vox_final_9");
	level.workbenchactivated = false;

	level thread spawnBossStart();

	level.defensemode = false;
	level.infinalphase = false;
	level.zombie_total = 14;
	level._poi_override = ::unused_override;
	level.holdround = false;
}

give_player_all_perks()
{
	foreach (player in level.players)
	{
		player.dovghud = 1;
	}
	
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
	foreach (player in level.players)
	{
		player.dovghud = 0;
	}
	
}

destroyFinalDefenseHUD()
{
	level.defense_text destroy();
	foreach (player in level.players)
	{
		player.defense_bar.bar destroy();
		player.defense_bar.barframe destroy();
		player.defense_bar destroy();
	}
}

createFinalDefenseHUD()
{
	level thread finaldefensehud();
	foreach (player in level.players)
	{
		player thread finaldefensehealthbar();
	}
}

startEncounterIfPlayersAreNear(isFinal)
{
	for(;;)
	{
		level.defensemode = false;
	
		isNear = false;

		while(!isNear)
		{
			foreach (player in level.players)
			{
				if(distance(player.origin, level.workbench.origin) <= 600 )
				{
					isNear = true;
				}
			}
			wait 0.1;
		}
	
		level.defensemode = true;
	
		level notify ("main_defense_start");
		level thread playfinalmusic();
	
		level thread if_all_players_are_too_far_away();
		
		time = randomintrange(60,90);
	
		level.defense_text.label = &"Defend the Workbench: ^6";
		level.defense_text setTimer(time);
		wait_with_endon(time);
	
		if(level.workbenchhealth <= 0)
		{
			workbench_is_destroyed(isFinal);
		}
		else
		{
			level.defense_text destroy();
			level notify ("main_defense_over");
			if(isFinal && isDefined(isFinal))
			{
				return;
			}
			level thread playfinaltransitionmusic();
			level thread finaldefensehud();
			break;
		}
		wait 0.1;
	}
}

wait_with_endon(num)
{
	level endon ("encounter_failed");
	wait num;
}

workbench_is_destroyed(isFinal)
{
	level.defensemode = false;
	destroyFinalDefenseHUD();
	level thread ignoreAllPlayers(1);

	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}
	thread nuke_flash();
	
	level._poi_override = ::unused_override;
	earthquake( 1, 1.8, level.workbench.origin, 256 );
	do_vox_subtitles("Entity", "The workbench was destroyed! Repairing it now!", 5, "vox_final_fail");
	createFinalDefenseHUD();
	level.defense_text.label = &"Survive until the workbench is repaired";
	level thread ignoreAllPlayers(0);
	
	wait 30;

	destroyFinalDefenseHUD();
	do_vox_subtitles("Entity", "The workbench is repaired! Get to it!", 5, "vox_final_repaired");
	createFinalDefenseHUD();

	level.defense_text.label = &"Get back to the workbench!";
	
	level.workbenchhealth = level.workbenchmaxhealth;
	level._poi_override = ::quest_zombie;
}

finaldefensehud()
{
	level endon("end_game");

	if(isDefined(level.defense_text))
	{
		level.defense_text destroy();
	}

	level.defense_text = newhudelem();
	level.defense_text.alignx = "left";
	level.defense_text.aligny = "top";
	level.defense_text.horzalign = "user_left";
	level.defense_text.vertalign = "user_top";
	level.defense_text.x = 60;
	level.defense_text.y = 20;
	level.defense_text.fontscale = 1;
	level.defense_text.alpha = 1;
	level.defense_text.color = ( 1, 1, 1 );
	level.defense_text.hidewheninmenu = 1;
	level.defense_text.foreground = 0;
}

finaldefensehealthbar()
{
	if(isDefined(self.defense_bar))
	{
		self.defense_bar.bar destroy();
		self.defense_bar destroy();
	}
	
	self.defense_bar = self createprimaryprogressbar();
	self.defense_bar setpoint("TOP_LEFT", undefined, 0, 0);
	self.defense_bar.hidewheninmenu = 1;
	self.defense_bar.bar.hidewheninmenu = 1;
	self.defense_bar.barframe.hidewheninmenu = 1;
	self.defense_bar.alpha = 1;
	self.defense_bar.foreground = 1;
	self.defense_bar.bar.foreground = 1;
	self.defense_bar.barframe.background = 1;
	
	
	while(level.infinalphase)
	{
		if(isDefined(self.defense_bar))
		{
			self.defense_bar updatebar(level.workbenchhealth / level.workbenchmaxhealth);
		}
		wait 0.1;
	}
	
	self.defense_bar.barframe destroy();
	self.defense_bar.bar destroy();
	self.defense_bar destroy();
}

workbench_attack_function()
{
    self endon( "death" );
    if(getdvar("mapname") == "zm_tomb")
        attackanim = "zm_generator_melee";
    else
        attackanim = "zm_riotshield_melee";
    
    if ( !self.has_legs )
        attackanim += "_crawl";
    for(;;)
    {
        if(distance(self.origin, level.workbench.origin) <= 50 && level.candamagebench == true)
        {
			angles = VectorToAngles( level.workbench.origin - self.origin );
			self animscripted( self.origin, angles, attackanim );
			if(getDvarInt("guided_mode") == 1)
			{
				level.workbench workbench_damage(1);
			}
			else
			{
				level.workbench workbench_damage(2);
			}
			wait 1;
        }
		else
        {
            self stopanimscripted();
        }    
        wait 0.05; 
    }
}

workbench_damage(amount)
{
	if(level.defensemode != true)
	{
		return;
	}
	
	self playsound("fly_riotshield_zm_impact_zombies");
	
	level.workbenchhealth -= amount;
	
	if(level.workbenchhealth <= 0)
	{
		self playsound("wpn_riotshield_zm_destroy");
		playfx(level._turbine_disappear_fx, self.origin + (0,0,40));
//		level thread end_workbench_defense_fail();
		level notify ("encounter_failed");
		level.workbenchdestroyed = true;
	}
}

finalDefenseEncounter()
{
	level endon ("main_quest_over");
	
	for(;;)
    {
        playables = getentarray( "player_volume", "script_noteworthy" );
        zombies = getAIArray( level.zombie_team );
        foreach (zombie in zombies)
        {
            for( a = 0; a < playables.size; a++ )
            {
                if( !( isdefined(zombie.is_mechz) && zombie.is_mechz )  && !( isdefined( zombie.ATK ) && zombie.ATK ) && isdefined( zombie ) && zombie isTouching( playables[ a ] ) && zombie.completed_emerging_into_playable_area == 1 && zombie.is_traversing == 0 && !( isdefined( zombie.is_traversing ) && zombie.is_traversing ) && zombie.ai_state == "find_flesh")
                {
                    zombie.ATK = 1;
					zombie set_zombie_run_cycle("sprint");

					
                    zombie thread workbench_attack_function();
                }
            }
        }
        wait 0.05;
    }
}

playfinalmusic()
{
    ent = spawn( "script_origin", ( 0, 0, 0 ) );
    ent thread stopfinalmusic();
	ent playloopsound( "mus_defense_loop", 0.1 );
}

stopfinalmusic()
{
    level waittill_any( "end_game", "main_quest_over", "main_defense_over" );
    self stoploopsound( 1.5 );
    wait 1;
    self delete();
}

playfinalintromusic()
{
    ent = spawn( "script_origin", ( 0, 0, 0 ) );
    ent thread stopfinalintromusic();
	ent playloopsound( "mus_defense_intro", 0.1 );
}

stopfinalintromusic()
{
    level waittill_any( "end_game", "main_defense_over" );
    self stoploopsound( 1.5 );
    wait 1;
    self delete();
}


playfinaltransitionmusic()
{
    ent = spawn( "script_origin", ( 0, 0, 0 ) );
    ent thread stopfinaltransitionmusic();
	ent playloopsound( "mus_defense_transition", 0.1 );
}

stopfinaltransitionmusic()
{
    level waittill_any( "end_game", "main_quest_over", "main_defense_start" );
    self stoploopsound( 1.5 );
    wait 1;
    self delete();
}

startDefenseHorde()
{
	level endon ("main_quest_over");
	level endon ("stop_endless_horde");
	
	for(;;)
	{
		level.zombie_total = 40;
		wait 0.1;
	}
}

loopBenchFX(effectsarray)
{
	level endon ("main_defense_over");
	
	maxeffect = effectsarray.size - 1;
	
	randomeffect = randomintrange(0,maxeffect);
	
	for(;;)
	{
		randomeffect = randomintrange(0,maxeffect);
		playfx(level._effect["turbine_on"], effectsarray[randomeffect]);
		
		wait randomfloatrange(0.1,1);
	}
}

// Objective List - ObjectiveDescription,IconShader,Location

setObjective(text, shader, location)
{	
	if(1)
	{
		return;
	}
	
	level.objective = text;
	level.objectiveorigin = location;
	
	level.guided_text.label = text;
}

setPartIcons(partnum, location)
{
	level thread createGuidedPartIcon(partnum, location);
}

createGuidedPartIcon(partnum, location)
{
	if(1)
	{
		return;
	}

	particon = newHudElem();
	particon.color = (1,1,1);
    particon.alpha = 1;
	particon.archived = 1;
	particon.isshown = 1;
	particon setshader( "search_marker", 6, 6 );
	particon setwaypoint( 1 );
	
	particon.x = location[0];
	particon.y = location[1];
	particon.z = location[2] + 40;
	
	while(level.parts[partnum] != true)
	{
		if(level.defensemode == true)
		{
			particon.alpha = 0;
		}
		else
		{
			particon.alpha = 1;
		}
		
		wait 0.1;
	}
	
	particon destroy();
}

createGuidedShovelIcon(location)
{
	if(1)
	{
		return;
	}

	particon = newHudElem();
	particon.color = (1,1,1);
    particon.alpha = 1;
	particon.archived = 1;
	particon.isshown = 1;
	particon setshader( "objective_marker", 4, 4 );
	particon setwaypoint( 1 );
	
	particon.x = location[0];
	particon.y = location[1];
	particon.z = location[2] + 40;
	
	while(level.hasshovel != true)
	{	
		wait 0.1;
	}
	
	particon destroy();
}

guidedmodehud()
{
	level endon("end_game");

	level.guided_text = newhudelem();
	level.guided_text.alignx = "left";
	level.guided_text.aligny = "top";
	level.guided_text.horzalign = "user_left";
	level.guided_text.vertalign = "user_top";
	level.guided_text.x = 60;
	level.guided_text.y = 200;
	level.guided_text.fontscale = 1;
	level.guided_text.alpha = 1;
	level.guided_text.color = ( 1, 1, 1 );
	level.guided_text.hidewheninmenu = 1;
	level.guided_text.foreground = 1;
}

guidedmodehealthbar()
{
	level.guided_bar = self createprimaryprogressbar();
	level.guided_bar setpoint("TOP_LEFT", undefined, 0, 100);
	level.guided_bar.hidewheninmenu = 1;
	level.guided_bar.bar.hidewheninmenu = 1;
	level.guided_bar.barframe.hidewheninmenu = 1;
	level.guided_bar.alpha = 1;
	
	while(!(level.completedmodmainquest))
	{
		if(isDefined(level.guidedhealth) || isDefined(level.guidedmaxhealth))
		{
			level.guided_bar.alpha = 1;
			level.guided_bar updatebar(level.guidedhealth / level.guidedmaxhealth);
		}
		else
		{
			level.guided_bar.alpha = 0;
		}
		wait 0.1;
	}
	
	level.guided_bar.bar destroy();
	level.guided_bar destroy();
}

random_part3_players()
{
	level endon ("zombie_dropped_part");
	
	level thread spawnFrequencyRadio((4101.23, 5488.46, -63.875), -66.1908);
	
	for(;;)
	{
		self waittill( "zom_kill", zombie);
		
		if(distance(zombie.origin, (4101.23, 5488.46, -63.875)) <= 1000 )
		{
			playables = getentarray( "player_volume", "script_noteworthy" );
			for( a = 0; a < playables.size; a++ )
			{
				if( !( isdefined(zombie.is_mechz) && zombie.is_mechz )  && zombie isTouching( playables[ a ] ) && zombie.completed_emerging_into_playable_area == 1 && zombie.is_traversing == 0 && !( isdefined( zombie.is_traversing ) && zombie.is_traversing ) && zombie.ai_state == "find_flesh")
				{
					if(getDvarInt("guided_mode") == 1)
					{
						random = 60;
					}
					else
					{
						random = 80;
					}
					
					if(randomintrange(1,100) >= 80)
					{
						playfx(level._effect["powerup_grabbed"], zombie.origin);
						level thread spawnpart(zombie.origin, 2);
						level notify( "stop_frequency" );
						level notify ("zombie_dropped_part");
					}
				}
			}
		}
		wait 0.1;
	}
}

spawnMachine(location)
{
	partTrigger = spawn( "trigger_radius", (location), 1, 50, 50 );
	partTrigger setHintString("Press ^3&&1 ^7to pickup the machine");
	partTrigger setcursorhint( "HINT_NOICON" );
	partModel = spawn( "script_model", (location + (0,0,50)));
	partModel setmodel ("t6_wpn_zmb_jet_gun_world");
	angle = randomintrange(0,180);
	partModel rotateTo((90,angle,180),.01);
	
	for(;;)
	{
		partTrigger waittill( "trigger", i );
		if ( i usebuttonpressed() )
		{	
			level.hasdigger = true;
			partTrigger delete();
			partModel delete();
			if(getDvarInt("enable_toasts") == 1)
			{
				send_toast(i.name + " picked up the Lava Digging Machine.", "zm_hud_icon_jetgun_engine", "Quest Item");
			}
			do_vox_subtitles("Entity", "This machine can dig through lava pools, a workbench part might be in one.", 4, "vox_pickup_machine");
			level thread spawnLavaDiggerTrigger(level.chosenLavaPool);
		}
		wait 0.1;
	}
}

ignoreAllPlayers(enabled)
{
	level notify ("ignoreallplayers");
	
	wait 0.1;
	
	level endon ("ignoreallplayers");
	
	for(;;)
	{
		foreach(player in level.players)
		{
			if(enabled)
			{
				player.ignoreme = 1;
			}
			else
			{
				player.ignoreme = 0;
			}
		}
		wait 0.1;
	}
}

spawnFinalEncounterTrigger(location)
{
	partTrigger = spawn( "trigger_radius", (location), 1, 50, 50 );
	partTrigger setHintString("Press ^3&&1 ^7to activate the Workbench");
	partTrigger setcursorhint( "HINT_NOICON" );
	
	for(;;)
	{
		partTrigger waittill( "trigger", i );
		if ( i usebuttonpressed() && level.exfilstarted == 0)
		{	
			level.workbenchactivated = true;
			level thread finalEncounterSequence();
			break;
		}
		wait 0.1;
	}
}

digPilePowerup(powerup, origin)
{
	wait 3;
	powerup = level maps\mp\zombies\_zm_powerups::specific_powerup_drop(powerup, origin);
    if (powerup == "teller_withdrawl")
        powerup.value = 1000;
	powerup thread maps\mp\zombies\_zm_powerups::powerup_timeout();
}

spawnRewards(location)
{
	origin = location;
	
	level thread maps\mp\zombies\_zm_powerups::specific_powerup_drop("full_ammo", origin);

	for( i = 0; i < 8; i++ )
	{
		x = origin[0] + randomintrange(-150,150);
		y = origin[1] + randomintrange(-150,150);
		z = origin[2];
		
		if(i == 1)
		{
			level thread spawnWeaponPickup("ray_gun_zm", (x,y,z));
		}
		else if(i == 2)
		{
			level thread spawnWeaponPickup("slipgun_upgraded_zm", (x,y,z));
		}
		else
		{
			level thread maps\mp\zombies\_zm_powerups::specific_powerup_drop("bonus_points_team", (x,y,z));
		}
		wait 1;
	}
}

//(-6028.18, 4313.79, 2.03459)

placeScrambler(location, angle)
{
	radioTrigger = spawn( "trigger_radius", (location), 1, 30, 30 );
//	radioTrigger setHintString("Press ^3&&1 ^7to pickup scrambler");
	radioTrigger setcursorhint( "HINT_NOICON" );
	radioModel = spawn( "script_model", (location));
	radioModel setmodel ("p6_zm_tm_radio_01_panel2_blood");
	radioModel rotateTo(angle,.1);
	for(;;)
	{
		radioTrigger waittill( "trigger", i );
		if( i usebuttonpressed() )
		{
			level.pickedupscrambler = 1;
			if(getDvarInt("enable_toasts") == 1)
			{
				send_toast(i.name + " picked up a Radio Scrambler", "objective_marker", "Mysterious Item");
			}
			else
			{
				notify_player_action(i.name + " picked up a radio scrambler");
			}
			radioTrigger delete();
			radioModel delete();
		}
		wait 0.1;
	}
}

spawnFrequencyRadio(location, angle)
{
	radioTrigger = spawn( "trigger_radius", (location), 1, 50, 50 );
	radioTrigger setHintString("");
	radioTrigger setcursorhint( "HINT_NOICON" );
	radioModel = spawn( "script_model", (location));
	radioModel setmodel ("p6_zm_tm_radio_01");
    radioModel attach( "p6_zm_tm_radio_01_panel2_blood", "tag_j_cover" );
	radioModel rotateTo((0,angle,0),.1);
	level thread frequencySound(location);
}

frequencySound(location)
{
    ent = spawn( "script_origin", location );
    ent thread stopfrequencymusic();
	ent playloopsound( "electronic_sound", 0.1 );
}


stopfrequencymusic()
{
    level waittill_any ( "stop_frequency", "end_game" );
    self stoploopsound(0.1);
    wait 1;
    self delete();
}

if_all_players_are_too_far_away()
{
	while(level.candamagebench == true)
	{
		playersfar = 0;
		
		foreach (player in level.players)
		{
			if(isDefined(level.workbench))
			{
				if(distance(level.workbench.origin, player.origin) >= 3000)
				{
					playersfar += 1;
				}
			}
		}
		
		if(playersfar == level.players.size)
		{
			level.workbench workbench_damage(8);
		}
		
		wait 1;
	}
}

playRadioAmbience(location)
{
    ent = spawn( "script_origin", location );
    ent thread stopradioambience();
	ent playloopsound( "amb_radio", 0.1 );
}


stopradioambience()
{
    level waittill ("main_defense_over");
    self stoploopsound(0.1);
    wait 1;
    self delete();
}

FinalEncounterVote()
{
	maxvotes = level.players.size;
	
	level.finalVoteHUD = newhudelem();
	level.finalVoteHUD.x = 0;
	level.finalVoteHUD.y -= 20;
	level.finalVoteHUD.alpha = 1;
	level.finalVoteHUD.alignx = "center";
	level.finalVoteHUD.aligny = "bottom";
    level.finalVoteHUD.horzalign = "user_center";
    level.finalVoteHUD.vertalign = "user_bottom";
	level.finalVoteHUD.foreground = 0;
	level.finalVoteHUD.fontscale = 1.5;
	level.finalVoteHUD setText ("Press [{+melee}] and [{+speed_throw}] to ready up!: ^5" + level.playersready + "/" + maxvotes);
	level waittill ("vote_end");
	level.finalVoteHUD fadeovertime( 0.25 );
	level.finalVoteHUD.alpha = 0;
	level.finalVoteHUD destroy();
}

//#using_animtree("zm_transit_avogadro");

spawn_boss( spawner, target_name, spawn_point, round_number, origin )
{
	
	if ( !isdefined( spawner ) )
    {
/#
        println( "ZM >> spawn_zombie - NO SPAWNER DEFINED" );
#/
        return undefined;
    }

    while ( getfreeactorcount() < 1 )
        wait 0.05;

    spawner.script_moveoverride = 1;

    if ( isdefined( spawner.script_forcespawn ) && spawner.script_forcespawn )
    {
        guy = spawner spawnactor();

        if ( isdefined( level.giveextrazombies ) )
            guy [[ level.giveextrazombies ]]();

        guy enableaimassist();

        if ( isdefined( round_number ) )
            guy._starting_round_number = round_number;

        guy.aiteam = level.zombie_team;
        guy clearentityowner();
        level.zombiemeleeplayercounter = 0;
        guy thread run_spawn_functions();
        guy.origin = origin;
        guy show();
//		guy setmodel( "c_zom_avagadro_fb" );
		guy thread set_boss_anims();
		
		guy.has_legs = 1;
		guy.no_gib = 1;
		guy.allowpain = 1;
		guy.is_avogadro = 1;
		guy.ignore_nuke = 1;
		guy.ignore_lava_damage = 1;
		guy.ignore_devgui_death = 1;
		guy.ignore_electric_trap = 1;
		guy.ignore_game_over_death = 1;
		guy.ignore_enemyoverride = 1;
		guy.ignore_solo_last_stand = 1;
		guy.ignore_riotshield = 1;
		guy.displayname = "Avogadro";
		
    }

    spawner.count = 666;

    if ( !spawn_failed( guy ) )
    {
        if ( isdefined( target_name ) )
            guy.targetname = target_name;

        return guy;
    }

    return undefined;
}

force_spawn_boss(origin)
{
	level.holdround = true;
	level.zombie_total = 0;
	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}

	spawner = random( level.avogadro_spawners );
	level.bossentity = spawn_boss( spawner, "avogadro", origin );
	wait 1;
	base = spawn( "script_model", (1443,-520,55) );
	base setModel ("tag_origin");
	level.bossentity unlink();
	level.bossentity enableLinkTo();
	level.bossentity.origin = origin;
	level.bossentity linkto (base);
	level.bossentity.maxhealth = 750000 + (150000 * level.players.size);
	level.bossentity.health = level.bossentity.maxhealth;
	level.bossentity thread boss_killed();
	level.bossentity.spot = origin;
	level.bossentity thread zombie_complete_emerging_into_playable_area();
	zones = array("zone_bar","zone_tow","zone_ban","zone_ban_vault","zone_tbu","zone_town_barber","zone_town_south","zone_town_west","zone_town_east","zone_town_north");
	foreach (player in level.players)
	{
		player thread boss_bar();
		if(!player boss_zone_checker(zones))
		{
			player setplayerangles ((0,-93,0));
			origin = (1550,581,-60);
			x = origin[0] + randomintrange(-150,150);
			y = origin[1] + randomintrange(-150,150);
			z = origin[2];
			player setorigin ((x,y,z));
		}
	}
	level thread boss_cloud_update_fx();
	level thread playbossmusic();
	level.bossentity.isInvulnerable = 1;
	level.bossentity.isBoss = 1;
	level thread boss_out_of_bounds();
	level thread boss_intro_quotes();
	level.the_bus bus_power_off();
	wait 22;
	level thread forcerun();
	earthquake( 1, 5, level.bossentity.origin, 3000 );
	level.bossentity.isInvulnerable = 0;
	level.bossentity thread boss_status();
	level.bossentity thread boss_attacks();
	level thread infinite_zombies();

}

players_are_near(origin, distance)
{
	num = 0;
	foreach(player in level.players)
	{
		if(!isDefined(player.bot))
		{
			if(distance(player.origin, origin) < distance)
			{
				num += 1;
			}
		}
	}

	max_players = 0;
	
	foreach(player in level.players)
	{
		if(!isDefined(player.bot))
		{
			max_players += 1;
		}
	}
	
	if(num == max_players)
	{
		return true;
	}
	else
	{
		return false;
	}
}

boss_intro_quotes()
{
	wait 2;
	do_vox_subtitles("Entity", "I cant do anything! You must eliminate the distrubance!", 4, "vox_boss_start_1");
	do_vox_subtitles("Avogadro", "Not so fast! Those scientists trapped me in that lab!", 5, "vox_boss_start_2");
	do_vox_subtitles("Avogadro", "Letting me out was a huge mistake!", 2, "vox_boss_start_3");
	do_vox_subtitles("Avogadro", "Your lives end here! Once and for all!", 4, "vox_boss_start_4");
}

infinite_zombies()
{
	while(isDefined(level.bossentity))
	{
		level.zombie_total = 15;
		wait 0.1;
	}
	level.zombie_total = 0;
}

create_boss_icon()
{
    height_offset = 30;
    hud_elem = newhudelem();
    hud_elem.x = self.origin[0];
    hud_elem.y = self.origin[1];
    hud_elem.z = self.origin[2] + height_offset;
    hud_elem.alpha = 1;
    hud_elem.archived = 1;
    hud_elem setshader( "waypoint_revive", 5, 5 );
    hud_elem setwaypoint( 1 );
    hud_elem.hidewheninmenu = 1;
    hud_elem.immunetodemogamehudsettings = 1;

    while ( isDefined(level.bossentity) )
    {
        hud_elem.x = self.origin[0];
        hud_elem.y = self.origin[1];
        hud_elem.z = self.origin[2] + height_offset;
        wait 0.01;
    }
	
	hud_elem destroy();
}

spam_health()
{
	while(1)
	{
		foreach(player in level.players)
		{
//			player iprintln(level.bossentity.health + "/" + level.bossentity.maxhealth);
			player iprintln(player.origin + " - " + player.angles);
			player iprintln(get_minion_amount());
		}
		wait 1;
	}
}

delete_zombie_noone_looking( how_close )
{
    self endon( "death" );

    if ( !isdefined( how_close ) )
        how_close = 1000;

    distance_squared_check = how_close * how_close;
    too_far_dist = distance_squared_check * 3;

    if ( isdefined( level.zombie_tracking_too_far_dist ) )
        too_far_dist = level.zombie_tracking_too_far_dist * level.zombie_tracking_too_far_dist;

    self.inview = 0;
    self.player_close = 0;
    players = get_players();

    for ( i = 0; i < players.size; i++ )
    {
        if ( players[i].sessionstate == "spectator" )
            continue;

        if ( isdefined( level.only_track_targeted_players ) )
        {
            if ( !isdefined( self.favoriteenemy ) || self.favoriteenemy != players[i] )
                continue;
        }

        can_be_seen = self player_can_see_me( players[i] );

        if ( can_be_seen && distancesquared( self.origin, players[i].origin ) < too_far_dist )
            self.inview++;

        if ( distancesquared( self.origin, players[i].origin ) < distance_squared_check )
            self.player_close++;
    }

    wait 0.1;

    if ( self.inview == 0 && self.player_close == 0 )
    {
        if ( !isdefined( self.animname ) || isdefined( self.animname ) && self.animname != "zombie" )
            return;

        if ( isdefined( self.electrified ) && self.electrified == 1 )
            return;

        if ( isdefined( self.in_the_ground ) && self.in_the_ground == 1 )
            return;

        zombies = getaiarray( "axis" );

        if ( ( !isdefined( self.damagemod ) || self.damagemod == "MOD_UNKNOWN" ) && self.health < self.maxhealth )
        {
            if ( !( isdefined( self.exclude_distance_cleanup_adding_to_total ) && self.exclude_distance_cleanup_adding_to_total ) && !( isdefined( self.isscreecher ) && self.isscreecher ) )
            {
                if(self != level.bossentity)
				{
					level.zombie_total++;
					level.zombie_respawned_health[level.zombie_respawned_health.size] = self.health;
				}
            }
        }
        else if ( zombies.size + level.zombie_total > 24 || zombies.size + level.zombie_total <= 24 && self.health >= self.maxhealth )
        {
            if ( !( isdefined( self.exclude_distance_cleanup_adding_to_total ) && self.exclude_distance_cleanup_adding_to_total ) && !( isdefined( self.isscreecher ) && self.isscreecher ) )
            {
                if(self != level.bossentity)
				{
					level.zombie_total++;
				}

                if ( self.health < level.zombie_health )
                    level.zombie_respawned_health[level.zombie_respawned_health.size] = self.health;
            }
        }

        self maps\mp\zombies\_zm_spawner::reset_attack_spot();
		if(self != level.bossentity)
		{
			self notify( "zombie_delete" );
			self delete();
		}
        recalc_zombie_array();
    }
}

round_spawn_failsafe_new()
{
    self endon( "death" );
    prevorigin = self.origin;

    while ( true )
    {
        if ( !level.zombie_vars["zombie_use_failsafe"] )
            return;

        if ( isdefined( self.ignore_round_spawn_failsafe ) && self.ignore_round_spawn_failsafe )
            return;

        wait 30;

        if ( !self.has_legs )
            wait 10.0;

        if ( isdefined( self.is_inert ) && self.is_inert )
            continue;

        if ( isdefined( self.lastchunk_destroy_time ) )
        {
            if ( gettime() - self.lastchunk_destroy_time < 8000 )
                continue;
        }

        if ( self.origin[2] < level.zombie_vars["below_world_check"] )
        {
            if ( isdefined( level.put_timed_out_zombies_back_in_queue ) && level.put_timed_out_zombies_back_in_queue && !flag( "dog_round" ) && !( isdefined( self.isscreecher ) && self.isscreecher ) )
            {
                empty = 0;
                //level.zombie_total++;
                //level.zombie_total_subtract++;
            }

/#

#/
            empty = 0;
            //self dodamage( self.health + 100, ( 0, 0, 0 ) );
            break;
        }

        if ( distancesquared( self.origin, prevorigin ) < 576 )
        {
            if ( isdefined( level.put_timed_out_zombies_back_in_queue ) && level.put_timed_out_zombies_back_in_queue && !flag( "dog_round" ) )
            {
                if ( !self.ignoreall && !( isdefined( self.nuked ) && self.nuked ) && !( isdefined( self.marked_for_death ) && self.marked_for_death ) && !( isdefined( self.isscreecher ) && self.isscreecher ) && ( isdefined( self.has_legs ) && self.has_legs ) )
                {
                    empty = 0;
                    //level.zombie_total++;
                    //level.zombie_total_subtract++;
                }
            }

            level.zombies_timeout_playspace++;
/#

#/
            empty = 0;
            //self dodamage( self.health + 100, ( 0, 0, 0 ) );
            break;
        }

        prevorigin = self.origin;
    }
}


boss_bar()
{
	health_bar = self createbar((1, 0, 0), level.secondaryprogressbarwidth * 2, level.secondaryprogressbarheight);
	health_bar setpoint("top", undefined, 0, -175);
	health_bar.hidewheninmenu = 1;
	health_bar.bar.hidewheninmenu = 1;
	health_bar.barframe.hidewheninmenu = 1;
	health_bar.alpha = 1;
	
	health_bar.foreground = 1;
	health_bar.barframe.background = 1;
	health_bar.bar.foreground = 1;
	
	health_bar_text = self createprimaryprogressbartext();
	health_bar_text setpoint("top", undefined, 0, -165);
	health_bar_text.hidewheninmenu = 1;
	health_bar_text.fontscale = 1;
	health_bar_text.foreground = 1;
	
	health_bar_text setText(level.bossentity.displayname);
	
	while(isDefined(level.bossentity))
	{
		health_bar updatebar(level.bossentity.health / level.bossentity.maxhealth);
		
		if(level.bossentity.isInvulnerable == 1)
		{
			health_bar.bar.color = (0,0,1);
		}
		else
		{
			health_bar.bar.color = (1,1,1);
		}
		
		if(level.intermission)
		{
			health_bar.alpha = 0;
			health_bar_text.alpha = 0;
			health_bar.barframe.alpha = 0;
			health_bar.bar.alpha = 0;
		}
		
		wait 0.01;
	}
	health_bar.bar destroy();
	health_bar.barframe destroy();
	health_bar destroy();
	health_bar_text destroy();
	
}

set_boss_anims()
{
	wait 2;
	self traversemode( "gravity" );
	self.ignore_all_poi = 1;
	self.is_traversing = 0;
	level.bossentity.origin = level.bossentity.spot;
    self.state = "chamber";
    self setanimstatefromasd( "zm_chamber_idle" );
	wait 1;
	self stopanimscripted();
}

boss_attacks()
{
	level endon("boss_died");
	while(1)
	{
		boss_range_attack( get_random_player() );
		wait 9;
	}
}

get_random_player()
{
	result = [];
	foreach (player in level.players)
	{
		result[result.size] = player;
	}
	return random(result);
}

boss_range_attack(enemy)
{
    if ( isdefined( enemy ) )
    {
        self thread shoot_bolt_wait( "ranged_attack", enemy );
        self show();
        self animscripted( self.origin, self.angles, "zm_ranged_attack_in" );
        maps\mp\animscripts\zm_shared::donotetracks( "ranged_attack" );
        self animscripted( self.origin, self.angles, "zm_ranged_attack_loop" );
        maps\mp\animscripts\zm_shared::donotetracks( "ranged_attack" );
        self animscripted( self.origin, self.angles, "zm_ranged_attack_out" );
        maps\mp\animscripts\zm_shared::donotetracks( "ranged_attack" );
		self setanimstatefromasd( "zm_chamber_idle" );
    }
}

shoot_bolt_wait( animname, enemy )
{
    self endon( "melee_pain" );
    self waittillmatch( animname, "fire" );
    self.shield = 0;
    self notify( "stop_health" );

    if ( isdefined( self.health_fx ) )
    {
        self.health_fx unlink();
        self.health_fx delete();
    }

    self thread shoot_bolt( enemy );
	earthquake( 0.7, 1, self.origin, 1500 );
}

minion_spawner_defense()
{
	level endon ("end_quest_rage");
	level endon ("stop_endless_horde");
	for(;;)
	{
		count = 0;
		zombies = getaiarray( level.zombie_team );
		foreach(zombie in zombies)
		{
			if(isDefined(zombie.isminion) && zombie.isminion == true)
			{
				count += 1;
			}
		}
		if(count <= 5)
		{
			spawn_regular_minion(1);
		}
		
		wait randomfloatrange(5,60);
	}
}

minion_round_watcher()
{
	level endon ("boss_died");
	randomnum = level.round_number + 1;
	loops = 0;
	for(;;)
	{
		level waittill ("between_round_over");
		if(level.round_number == randomnum)
		{
			loops += 1;
			spawn_regular_minion(loops);
			randomnum = level.round_number + randomintrange(3,5);
		}
	}
}

spawn_regular_minion(times)
{
	minionslist = [];
	
	for( i = 0; i < times; i++ )
	{
		spawner = random( level.zombie_spawners );
		ai = spawn_boss_minion( spawner, "zombie", spawner.origin );
		ai thread minion_dies();
		ai set_zombie_run_cycle("sprint");
		ai.isminion = true;
		level.zombie_total--;
		minionslist[minionslist.size] = ai;
	}
	
	wait 1;
	
	foreach(minion in minionslist)
	{
		minion.maxhealth = 5000;
		minion.health = minion.maxhealth;
		minion.is_on_fire = true;
	}
}

boss_status()
{
	max_phase = 4;
	phase_bar = level.bossentity.maxhealth / 4;
	if(getDvarInt("guided_mode") == 1)
	{
		halfsies = int(max_phase / 4);
	}
	else
	{
		halfsies = int(max_phase / 2);
	}
	phase = 1;
	self.isInvulnerable = 0;
	self thread loop_shock_line_fx();

	
	while(1)
	{
		if(max_phase != phase)
		{
			if(level.bossentity.health <= phase_bar * (max_phase - phase))
			{
				self playsound( "zmb_avogadro_pain" );
				self.isInvulnerable = 1;
				self playsound( "zmb_avogadro_warp_out" );
				level thread spawn_wave_minions(phase);
				level.bossentity thread phase_watch();
				level waittill ("minions_eliminated");
				if(getDvarInt("guided_mode") == 1)
				{
					level thread maps\mp\zombies\_zm_powerups::specific_powerup_drop("full_ammo", (1446.1, -121.101, -61.875));
				}
				else
				{
					if(phase == halfsies)
					{
						level thread maps\mp\zombies\_zm_powerups::specific_powerup_drop("full_ammo", (1446.1, -121.101, -61.875));
					}
				}
				phase += 1;
			}
		}
		wait 0.1;
	}
}

phase_watch()
{
	wait 1;
	while(get_minion_amount() > 0)
	{
		wait 1;
	}
	level notify ("minions_eliminated");
	self playsound( "zmb_avogadro_warp_out" );
	self.isInvulnerable = 0;
	self disableInvulnerability();

}

actor_damage_override( inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, shitloc, psoffsettime, boneindex )
{
    if ( !isdefined( self ) || !isdefined( attacker ) )
        return damage;
		
	if( isDefined(self.isInvulnerable) && self.isInvulnerable == 1)
		return 0;

    if ( weapon == "tazer_knuckles_zm" || weapon == "jetgun_zm" )
        self.knuckles_extinguish_flames = 1;
    else if ( weapon != "none" )
        self.knuckles_extinguish_flames = undefined;

    if ( isdefined( attacker.animname ) && attacker.animname == "quad_zombie" )
    {
        if ( isdefined( self.animname ) && self.animname == "quad_zombie" )
            return 0;
    }

    if ( !isplayer( attacker ) && isdefined( self.non_attacker_func ) )
    {
        if ( isdefined( self.non_attack_func_takes_attacker ) && self.non_attack_func_takes_attacker )
            return self [[ self.non_attacker_func ]]( damage, weapon, attacker );
        else
            return self [[ self.non_attacker_func ]]( damage, weapon );
    }

    if ( !isplayer( attacker ) && !isplayer( self ) )
        return damage;

    if ( !isdefined( damage ) || !isdefined( meansofdeath ) )
        return damage;

    if ( meansofdeath == "" )
        return damage;

    old_damage = damage;
    final_damage = damage;

    if ( isdefined( self.actor_damage_func ) )
        final_damage = [[ self.actor_damage_func ]]( inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, shitloc, psoffsettime, boneindex );

/#
    if ( getdvarint( #"scr_perkdebug" ) )
        println( "Perk/> Damage Factor: " + final_damage / old_damage + " - Pre Damage: " + old_damage + " - Post Damage: " + final_damage );
#/

    if ( attacker.classname == "script_vehicle" && isdefined( attacker.owner ) )
        attacker = attacker.owner;

    if ( isdefined( self.in_water ) && self.in_water )
    {
        if ( int( final_damage ) >= self.health )
            self.water_damage = 1;
    }

    attacker thread maps\mp\gametypes_zm\_weapons::checkhit( weapon );

    if ( attacker maps\mp\zombies\_zm_pers_upgrades_functions::pers_mulit_kill_headshot_active() && is_headshot( weapon, shitloc, meansofdeath ) )
        final_damage = final_damage * 2;

    if ( isdefined( level.headshots_only ) && level.headshots_only && isdefined( attacker ) && isplayer( attacker ) )
    {
        if ( meansofdeath == "MOD_MELEE" && ( shitloc == "head" || shitloc == "helmet" ) )
            return int( final_damage );

        if ( is_explosive_damage( meansofdeath ) )
            return int( final_damage );
        else if ( !is_headshot( weapon, shitloc, meansofdeath ) )
            return 0;
    }

    return int( final_damage );
}


avogadro_prespawn()
{
    if(isDefined(level.bossstarted) && level.bossstarted == 1)
		return;
	
	self endon( "death" );
    level endon( "intermission" );
    level.avogadro = self;
    self.has_legs = 1;
    self.no_gib = 1;
    self.is_avogadro = 1;
    self.ignore_enemy_count = 1;
    recalc_zombie_array();
    self.ignore_nuke = 1;
    self.ignore_lava_damage = 1;
    self.ignore_devgui_death = 1;
    self.ignore_electric_trap = 1;
    self.ignore_game_over_death = 1;
    self.ignore_enemyoverride = 1;
    self.ignore_solo_last_stand = 1;
    self.ignore_riotshield = 1;
    self.allowpain = 0;
    self.core_model = getent( "core_model", "targetname" );

    if ( isdefined( self.core_model ) )
    {
        if ( !isdefined( self.core_model.angles ) )
            self.core_model.angles = ( 0, 0, 0 );

        self forceteleport( self.core_model.origin, self.core_model.angles );
    }

    self set_zombie_run_cycle( "walk" );
    self animmode( "normal" );
    self orientmode( "face enemy" );
    self maps\mp\zombies\_zm_spawner::zombie_setup_attack_properties();
    self maps\mp\zombies\_zm_spawner::zombie_complete_emerging_into_playable_area();
    self setfreecameralockonallowed( 0 );
    self.zmb_vocals_attack = "zmb_vocals_zombie_attack";
    self.meleedamage = 5;
    self.actor_damage_func = ::avogadro_damage_func;
    self.non_attacker_func = ::avogadro_non_attacker;
    self.anchor = spawn( "script_origin", self.origin );
    self.anchor.angles = self.angles;
    self.phase_time = 0;
    self.audio_loop_ent = spawn( "script_origin", self.origin );
    self.audio_loop_ent linkto( self, "tag_origin" );
    self.hit_by_melee = 0;
    self.damage_absorbed = 0;
    self.ignoreall = 1;
    self.zombie_init_done = 1;
    self notify( "zombie_init_done" );
    self.stun_zombie = ::stun_avogadro;
    self.jetgun_fling_func = ::fling_avogadro;
    self.jetgun_drag_func = ::drag_avogadro;
    self.depot_lava_pit = ::busplowkillzombie;
    self.busplowkillzombie = ::busplowkillzombie;
    self.region_timer = gettime() + 500;
    self.shield = 1;
}

boss_killed()
{
    self waittill ("death");
	level notify ("boss_died");
	level.zombie_total = 0;
	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}
	earthquake( 1, 10, self.origin, 5000 );
	thread nuke_flash(5);
    self playsound( "zmb_avogadro_death" );
    playfx( level._effect["avogadro_ascend"], self.origin );
    self.deathanim = "zm_exit";
	wait 5;
	self delete();
	
	do_vox_subtitles("Entity", "That Avogadro had powers that prevented me from intercepting...", 4, "vox_boss_end_1");
	do_vox_subtitles("Entity", "How did he get such power? No matter, its dealt with now.", 6, "vox_boss_end_2");
	
	level.holdround = false;

	level.completedmodmainquest = true;
	if(getDvarInt("guided_mode") == 1)
	{
		level notify ("end_game");
	}
	else
	{
		if(getDvarInt("stats_completed_quest_1") != 1)
		{
			setDvar("stats_completed_quest_1", 1);
		}
		
		if(getDvarInt("continue_game_after_quest"))
		{
			level thread spawnRewards((1446.1, -121.101, -61.875));
			level.the_bus bus_power_on();
			foreach (player in level.players)
			{
				player thread give_player_all_perks();
			}
		}
		else
		{
			level notify ("end_game");
		}
	}
}

boss_cloud_update_fx()
{
	self endon( "cloud_fx_end" );
	level endon( "end_game" );
	region = [];
	region[ 0 ] = "town";
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

spawn_boss_minion( spawner, target_name, spawn_point, round_number, origin )
{
    if ( !isdefined( spawner ) )
    {
/#
        println( "ZM >> spawn_zombie - NO SPAWNER DEFINED" );
#/
        return undefined;
    }

    while ( getfreeactorcount() < 1 )
        wait 0.05;

    spawner.script_moveoverride = 1;

    if ( isdefined( spawner.script_forcespawn ) && spawner.script_forcespawn )
    {
        guy = spawner spawnactor();

        if ( isdefined( level.giveextrazombies ) )
            guy [[ level.giveextrazombies ]]();

        guy enableaimassist();

        if ( isdefined( round_number ) )
            guy._starting_round_number = round_number;

        guy.aiteam = level.zombie_team;
        guy clearentityowner();
        level.zombiemeleeplayercounter = 0;
        guy thread run_spawn_functions();
        guy.origin = origin;
        guy show();
		guy setmodel( "c_zom_avagadro_fb" );
		guy.isminion = 1;
		
    }

    spawner.count = 666;

    if ( !spawn_failed( guy ) )
    {
        if ( isdefined( target_name ) )
            guy.targetname = target_name;

        return guy;
    }

    return undefined;
}

spawn_wave_minions(phase)
{
	level.minionslist = [];

	for( i = 0; i < 8; i++ )
	{
		spawner = random( level.zombie_spawners );
		ai = spawn_boss_minion( spawner, "zombie", spawner.origin );
		ai thread minion_dies();
		ai.isminion = true;
		ai set_zombie_run_cycle("sprint");
		level.zombie_total--;
		level.minionslist[level.minionslist.size] = ai;
	}
	
	wait 1;
	
	foreach(minion in level.minionslist)
	{
		minion.maxhealth = 5000;
		minion.health = minion.maxhealth;
		minion.is_on_fire = true;
	}
	
	level notify ("finished_spawning_minions");
	if(phase == 1)
	{
		do_vox_subtitles("Avogadro", "Minions! Come on out!", 3, "vox_boss_minions");
	}
}

get_minion_amount()
{
	num = 0;
	
	foreach (i in level.minionslist)
	{
		if(isAlive(i))
		{
			num += 1;
		}
	}
	
	return num;
}

shock_line_fx( entity )
{
    source_pos = self gettagorigin( "tag_weapon_right" );
    target_pos = entity geteye();
    bolt = spawn( "script_model", source_pos );
    bolt setmodel( "tag_origin" );
    wait 0.1;
    self playsound( "zmb_avogadro_attack" );
    fx = playfxontag( level._effect["avogadro_bolt"], bolt, "tag_origin" );
    bolt moveto( target_pos, 0.2 );
    bolt waittill( "movedone" );
    bolt.owner = self;
    bolt delete();
}

shock_fx()
{
	maps\mp\_visionset_mgr::vsmgr_activate( "overlay", "zm_ai_avogadro_electrified", self, 1, 1 );
	self shellshock( "electrocution", 1 );
	self playsoundtoplayer( "zmb_avogadro_electrified", self );
	self dodamage( 10, self.origin );
}

loop_shock_line_fx()
{
	level endon ("boss_died");
	
	for(;;)
	{
		zombies = getAIArray( level.zombie_team );
		foreach (i in zombies)
		{
			if(isAlive(i) && (isDefined(i.isminion) && i.isminion == 1) && level.bossentity.isInvulnerable == 1)
			{
				level.bossentity thread shock_line_fx( i );
			}
		}
		wait 1.5;
	}
}

playbossmusic()
{
    ent = spawn( "script_origin", ( 0, 0, 0 ) );
	ent playloopsound ("mus_transitfight_intro");
	wait 22;
    ent thread stopbossmusic();
	ent playloopsound( "mus_transitfight_loop", 0.1 );
}

stopbossmusic()
{
    level waittill_any( "boss_died", "end_game" );
    self stoploopsound( 1.5 );
    wait 1;
	self playloopsound ("mus_transitfight_outro");
	wait 21;
	self stoploopsound( 1.5 );
	wait 2;
    self delete();
}

loop_bossStartFX(origin)
{
	while(level.bossstarted != 1)
	{
		playfx( level._effect["avogadro_phasing"], self.origin + (0,0,-20) );
		wait 2;
	}
}

spawnBossStart()
{
	level.bossStartTrigger = spawn( "trigger_radius", ((1765.37, -88.9562, -33.9563)), 1, 50, 50 );
	level.bossStartTrigger setHintString("Press ^3&&1 ^7to investigate the disturbance \n[Final Encounter] A vote will be casted.");
	level.bossStartTrigger setcursorhint( "HINT_NOICON" );
	level.bossStartModel = spawn( "script_model", ((1765.37, -88.9562, -33.9563)));
	level.bossStartModel setmodel ("p6_zm_bu_sq_crystal");
	angle = randomintrange(0,180);
	level.bossStartModel rotateTo((0,167.966,0),.1);
	
	level.bossStartTrigger thread loop_bossStartFX();

	level.bossStartModel thread loop_boss_model();

	for(;;)
	{
		level.bossStartTrigger waittill( "trigger", i );
			
		if ( i usebuttonpressed() )
		{
			showVoting(i.name + " wants to start the Final Encounter", i, ::startFinalEncounter);
		}
		wait 0.1;
	}
}

startFinalEncounter()
{
	level.bossStartModel thread electricity_towards_boss((1443,-520,55));
	level.bossStartModel moveto((1443,-520,55),8);
	level.bossStartModel waittill("movedone");
	level.bossstarted = 1;
	level thread force_spawn_boss((1443,-520,55));
	thread nuke_flash(3);
	earthquake( 1, 2, (1443,-520,55), 1000 );
	level notify ("stop_boss_sequence");
	thread give_bots_special_weapons();
	level.bossStartTrigger delete();
	level.bossStartModel delete();
}

electricity_towards_boss(origin)
{
	level endon ("stop_boss_sequence");
	for(;;)
	{
		x = origin[0] + randomintrange(-1000,1000);
		y = origin[1] + randomintrange(-1000,1000);
		z = origin[2] + 500;
		thread shoot_bolt_position((x,y,z),(1443,-520,55));
		playfx( level._effect["avogadro_phasing"], (1443,-520,55) - (0,0,20) );
		playfx( level._effect["avogadro_phasing"], self.origin - (0,0,20) );
		delay = randomfloatrange(0.1,0.5);
		wait delay;
	}
}

shoot_bolt_position( loc, destination )
{
    source_pos = loc;
    target_pos = destination;
    bolt = spawn( "script_model", source_pos );
    bolt setmodel( "tag_origin" );
    wait 0.1;
    bolt playsound( "zmb_avogadro_attack" );
    fx = playfxontag( level._effect["avogadro_bolt"], bolt, "tag_origin" );
    bolt moveto( target_pos, 0.2 );
    bolt waittill( "movedone" );
    bolt.owner = self;
    bolt delete();
}


minion_dies()
{
	self waittill ("death", attacker);
	playfx(level._effect["turbine_aoe"], self.origin);
	self playsound ("wpn_emp_bomb_static_start");
	if(isplayer(attacker))
	{
		foreach (player in level.players)
		{
			if(distance(self.origin, player.origin) <= 100)
			{
				player thread shock_fx();
			}
		}
	}
	self delete();
}

loop_boss_model()
{
	while(level.bossstarted != 1)
	{
		self moveto(self.origin + (0,0,20),1.5);
		self waittill("movedone");
		self moveto(self.origin + (0,0,-20),3.5);
		self waittill("movedone");
	}
}

boss_out_of_bounds()
{
	level endon ("boss_died");
	zones = array("zone_bar","zone_tow","zone_ban","zone_ban_vault","zone_tbu","zone_town_barber","zone_town_south","zone_town_west","zone_town_east","zone_town_north");
	
	for(;;)
	{
		foreach (player in level.players)
		{

			if(!player boss_zone_checker(zones))
			{
				maps\mp\_visionset_mgr::vsmgr_activate( "overlay", "zm_ai_avogadro_electrified", player, 1, 1 );
				player shellshock( "electrocution", 1 );
				player playsoundtoplayer( "zmb_avogadro_electrified", player );
				player dodamage( 40, player.origin );				
			}
		}
		wait 2;
	}
}

boss_zone_checker(zones)
{
	foreach(zone in zones)
	{
		if(self get_current_zone() == zone)
		{
			return true;
		}
	}
	return false;
}

do_gib_new()
{
    if ( !is_mature() )
        return;

    if ( !isdefined( self.a.gib_ref ) )
        return;

    if ( isdefined( self.is_on_fire ) && self.is_on_fire )
        return;

    if ( self is_zombie_gibbed() )
        return;
		
	if ( self.isminion == true )
		return;

    self set_zombie_gibbed();
    gib_ref = self.a.gib_ref;
    limb_data = get_limb_data( gib_ref );

    if ( !isdefined( limb_data ) )
    {
/#
        println( "^3animscriptszm_death.gsc - limb_data is not setup for gib_ref on model: " + self.model + " and gib_ref of: " + self.a.gib_ref );
#/
        return;
    }

    if ( !( isdefined( self.dont_throw_gib ) && self.dont_throw_gib ) )
        self thread throw_gib( limb_data["spawn_tags_array"] );

    if ( gib_ref == "head" )
    {
        self.hat_gibbed = 1;
        self.head_gibbed = 1;
        size = self getattachsize();

        for ( i = 0; i < size; i++ )
        {
            model = self getattachmodelname( i );

            if ( issubstr( model, "head" ) )
            {
                if ( isdefined( self.hatmodel ) )
                    self detach( self.hatmodel, "" );

                self detach( model, "" );

                if ( isdefined( self.torsodmg5 ) )
                    self attach( self.torsodmg5, "", 1 );

                break;
            }
        }
    }
    else
    {
        self setmodel( limb_data["body_model"] );
        self attach( limb_data["legs_model"] );
    }
}