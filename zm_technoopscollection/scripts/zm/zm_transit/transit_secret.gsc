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
	precacheshader("objective_marker");
	precacheshader("defense_marker");
	precacheshader("search_marker");
}

init()
{
	setLogsLocation();
	
	if(getDvar("mapname") == "zm_transit" && getDvar( "g_gametype" ) == "zclassic" && getDvarInt("gamemode") == 0)
	{

	}
	else
	{
		return;
	}
	
	level._poi_override = ::unused_override;
	level.partmodels = array("p6_zm_bu_sq_satellite_dish","p6_zm_bu_sq_crystal","p6_zm_tm_barbedwire_tube");
	level.parts = array(true,true,true);
	level.dirtPilesList = array((7726.28, -5133.31, 37.4349),(7813.05, -4956.94, 43.0341),(7806.02, -4723.67, 44.2192));
	level thread workbench((1486.65, 2060.84, -47.8691), 0);
	level.pickeduplavamachine = false;
	lavaPools = array((1337.36, 176.989, -69.875),(-11303, -2026.11, 184.125),(10049.9, -1216.3, -217.875));
	
	level.chosenLavaPool = lavaPools[randomintrange(0,lavaPools.size - 1)];
	
//	level waittill ("power_on");
	level thread spawnPhone();
	level.defensemode = false;
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
	for(;;)
	{
		can_sprint = false;
		zombies = getAiArray(level.zombie_team);
		foreach(zombie in zombies)
//		zombie.cloned_distance = self.origin;
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
//					level thread chooseDirtReward();
//					level thread digPilePowerup(level.zombie_include_powerups[randomintrange(0,level.zombie_include_powerups.size - 1)], digTrigger.origin);
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
//		level.dog_spawners = getentarray( "zombie_dog_spawner", "script_noteworthy" );
//		later_dogs = getentarray( "later_round_dog_spawners", "script_noteworthy" );
//		level.dog_spawners = arraycombine( level.dog_spawners, later_dogs, 1, 0 );
		
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
	do_vox_subtitles("Phone", "*static*", 2, "");
	do_vox_subtitles("Phone", "Hello? Anyone there?", 3, "vox_intro_1");
	do_vox_subtitles("Entity", "I recognize that voice!", 2, "vox_intro_2");
	do_vox_subtitles("Phone", "Im stuck in some part of the Aether, like a deeper layer of it.", 4, "vox_intro_3");
	do_vox_subtitles("Entity", "He cant hear us. We gotta build a bigger connection!", 3, "vox_intro_4");
	do_vox_subtitles("Entity", "You must find the parts to the device so we can contact him!", 4, "vox_intro_5");
	
	level thread ignoreAllPlayers(0);

	level thread createGuidedPartIcon(0, (7930.38, -5716.31, 11.3838));
	wait 0.2;
	level thread createGuidedPartIcon(1, (-11340.5, -983.951, 192.125));
	wait 0.2;
	level thread createGuidedPartIcon(2, (1478.87, -434.099, -67.875));
	wait 0.2;
	level thread createGuidedShovelIcon((-4183,-7764,-61));

	level thread setObjective("Find the parts", "", (0,0,0));

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
				do_vox_subtitles("Entity", "The satellite will be perfect for projecting the connection.", 3, "vox_part_1");
			}
			else if(partnum == 1)
			{
				do_vox_subtitles("Entity", "That crystal is useful for going past the Aethers barrier. Letting us reach to him!", 5, "vox_part_2");
			}
			else if(partnum == 2)
			{
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
	
	level thread setObjective("Defend the Machine", "defense_marker", location);
	
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
	
	level thread do_vox_subtitles("Entity", "I guess they dont like that!", 2, "vox_part_2_start"); //????

	level thread startSecondPartHorde();
	
	level thread changeZombieTarget();
	level thread step2defensehud();
	
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
	
	//(-1869.18, -6016.01, -103.602)
	//(6597.45, -4372.54, -60.875)
	//(10004.8, 7751.69, -582.875)
	//(1331.44, 196.033, -69.875)
	//(-9285.7, 4334.71, 44.5352)
	//(-11208.6, -1158.58, 194.125)
	//(-11208.6, -1158.58, 194.125)
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
	if(self.turned)
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
			level.machine machine_damage(1);
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
	locations = array((-6480.5, 5292.81, 3.07276),(-6453.53, 5307.02, 4.07276));
	
	location = randomintrange(0,1);
	
	phoneTrigger = spawn( "trigger_radius", (locations[location]), 1, 20, 100 );
	phoneTrigger setHintString("Press ^3&&1 ^7to answer");
	phoneTrigger setcursorhint( "HINT_NOICON" );
	
	level thread playphone(locations[location]);
	
	for(;;)
	{
		phoneTrigger waittill( "trigger", i );
		
		if(i usebuttonpressed())
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
	level.holdround = true;
	
	level maps\mp\zombies\_zm_powerups::specific_powerup_drop("full_ammo", (1490.28, 1962.94, -47.4356));
	
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
	
	do_vox_subtitles("Entity", "Uh oh. Looks like the undead dont like the workbench. You must protect it!", 5, "vox_final_intro_5");
	
	level thread ignoreAllPlayers(0);
	
	level.workbenchmaxhealth = 300;
	
	level.workbenchhealth = level.workbenchmaxhealth;
	
	level notify ("main_defense_over");
	level thread playfinaltransitionmusic();

	level thread finalDefenseEncounter();
	level thread startDefenseHorde();
	
	level thread finaldefensehud();
	foreach (player in level.players)
	{
		player thread finaldefensehealthbar();
	}
	
	level.defensemode = true;
	
	level._poi_override = ::quest_zombie;
	
	level notify ("final_encounter_started");
	
	thread defenseBench((1225.66, -1054.34, -55.875), 0);
	level.defense_text.label = &"Get to the workbench at Town ^6";
	level thread setObjective("Defend the Workbench at Town", "defense_marker", (1136.61, -1232.16, -55.875));
	level.candamagebench = true;
	startEncounterIfPlayersAreNear();
	level.candamagebench = false;
	destroyFinalDefenseHUD();
	do_vox_subtitles("Entity", "This spot is no good! Moving to a new area!", 3, "vox_final_1");
	createFinalDefenseHUD();
	level.defense_text.label = &"Get to the workbench at Farm ^6";
	thread defenseBench((7927.59, -5516.93, 37.3758),-100.569);
	level thread setObjective("Defend the Workbench at Farm", "defense_marker", (7927.59, -5516.93, 37.3758));
	level.candamagebench = true;
	startEncounterIfPlayersAreNear();
	level.candamagebench = false;
	destroyFinalDefenseHUD();
	do_vox_subtitles("Entity", "God damnit not here either!", 2, "vox_final_2");
	createFinalDefenseHUD();
	level.defense_text.label = &"Get to the workbench at Diner ^6";
	thread defenseBench((-5248.32, -7148.79, -58.875),0);
	level thread setObjective("Defend the Workbench at Diner", "defense_marker", (-5373.39, -7802.24, -67.3002));
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
	do_vox_subtitles("Entity", "Humans! Your gratitude will be acknowledged!", 5, "vox_final_7");
	
	
	level notify ("main_quest_over");
	
	level thread setObjective("", "", (0,0,0));
	
	level thread spawnRewards((-5183.93, -7318.26, -68.9245));
	
	foreach (player in level.players)
	{
		player thread give_player_all_perks();
	}
	
	level.completedmodmainquest = true;
	level.defensemode = false;
	level.infinalphase = false;
	level.zombie_total = 0;
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
		player.defense_bar destroy();
		player.defense_bar.bar destroy();
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
	
		level.defense_text.label = &"Defend the Workbench: ^6";
		level.defense_text setTimer(90);
		wait_with_endon(90);
	
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
	level.defense_text.foreground = 1;
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
	
	while(level.infinalphase)
	{
		if(isDefined(self.defense_bar))
		{
			self.defense_bar updatebar(level.workbenchhealth / level.workbenchmaxhealth);
		}
		wait 0.1;
	}
	
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
			level.workbench workbench_damage(2);
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
					zombie set_zombie_run_cycle("super_sprint");

					
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

//	level.defense_text.label = &"" + text + "^6";

	level thread createGuidedIcon(shader);
}

setPartIcons(partnum, location)
{
	level thread createGuidedPartIcon(partnum, location);
}

createGuidedIcon(shader)
{
	if(1)
	{
		return;
	}
	
	if (isDefined(level.objectiveicon))
	{
		level.objectiveicon destroy();
		wait 0.1;
	}
	
	level.objectiveicon = newHudElem();
	level.objectiveicon.color = (1,1,1);
    level.objectiveicon.alpha = 1;
	level.objectiveicon.archived = 1;
	level.objectiveicon.isshown = 1;
	level.objectiveicon setshader( shader, 6, 6 );
    level.objectiveicon setwaypoint( 1 );
	
	level.objectiveicon.x = level.objectiveorigin[0];
	level.objectiveicon.y = level.objectiveorigin[1];
	level.objectiveicon.z = level.objectiveorigin[2] + 40;
	
	for(;;)
	{
		wait 0.1;
	}
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
					if(randomintrange(1,100) >= 98)
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
			partTrigger delete();
			partModel delete();
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