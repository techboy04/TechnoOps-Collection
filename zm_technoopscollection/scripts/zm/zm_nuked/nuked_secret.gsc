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
#include maps\mp\zm_nuked;
#include scripts\zm\main;

main()
{
	precachemodel("p_glo_books_single");
	replacefunc(maps\mp\zm_nuked::nuked_standard_intermission, ::nuked_standard_intermission);
	replacefunc(maps\mp\zm_nuked::nuked_doomsday_clock_think, ::nuked_doomsday_clock_think);
}

init()
{
	level thread spawnBunker();
	setup_sidestuff();
	level.cantalktobunker = false;
	level.bunkerchatter = 0;
	level.mainqueststarted = false;
	level.activatepower = false;
	level.soulboxcount = 0;
	level.pausedoomsday = false;
	level.iscardclean = false;
	level.talkerroundpassed = false;
	level thread earthquake_sound();
	level thread local_audio_file();
	level thread facility_talk();
	level thread setup_sidestuff();
	level thread talk_round_think();
	level thread spawn_shootable_power((517.701, -225.238, -1.60953));
	
	custom_secret_song_spawns(array((638.568, 629.444, -20.5512),(-1037.25, 13.6642, -62.3842),(901.645, 461.189, -19.5676)),array(-89.5405,156.158,16.9171),"mus_custom_nuketown_ee");
}

spawnBunker()
{
	BunkerTrigger = spawn( "trigger_radius", ((-1351.54, 995.177, -63.875)), 1, 20, 100 );
	BunkerTrigger setHintString("");
	BunkerTrigger setcursorhint( "HINT_NOICON" );

	
	for(;;)
	{
		BunkerTrigger waittill( "trigger", i );
		
		if(i usebuttonpressed())
		{
			if(level.mainqueststarted != true)
			{
				level.mainqueststarted = true;
				BunkerTrigger setHintString("");
				level notify ("bunker_answered");
				BunkerTrigger playsound ("zmb_bunker_bang");
				wait 1;
				level thread nukedEEsequence();
				wait 15;
			}
			else
			{	
				if(level.soulboxcount == 2 && level.iscardclean)
				{
					PlaceCleanID();
					level.soulboxcount += 1;
					level.cantalktobunker = false;
				}				
				
				if(level.cantalktobunker)
				{
					level.cantalktobunker = false;
					talking_to_voice();
					level.cantalktobunker = true;
				}
			}
		}
		
		wait 0.1;
	}
}

nukedEEsequence()
{
	foreach(player in level.players)
	{
		player.ignoreme = 1;
	}

	level thread spawn_defuse_machines((668.882, 674.805, -56.875), -30.2057);
	level thread spawn_defuse_machines((-711.524, 544.72, 80.125), -161.075);
	level thread spawn_defuse_machines((-257.264, 553.082, -60.7844), 117.896);

	level.cantalktobunker = false;
	level notify ("bunker_talk", "vox_nuketown_intro_1");
	do_vox_subtitles("Voice", "Holy shit humanity is still around? How long has it been?", 4, "");
	level notify ("bunker_talk", "vox_nuketown_intro_2");
	do_vox_subtitles("Voice", "Wait! Let me take a look at you first, just to be safe.", 4, "");
	if(level.should_use_cia)
	{
		level notify ("bunker_talk", "vox_nuketown_intro_3_cia_1");
		do_vox_subtitles("Voice", "Wheres your suit? Its pretty dangerous out here.", 3, "");
		level notify ("bunker_talk", "vox_nuketown_intro_3_cia_2");
		do_vox_subtitles("Voice", "Well if you survived long enough, youll be fine here.", 3, "");
	}
	else
	{
		level notify ("bunker_talk", "vox_nuketown_intro_3_cdc");
		do_vox_subtitles("Voice", "Luckily you got that suit on you. Cant imagine how bad it is out there.", 4, "");
	}
	level notify ("bunker_talk", "vox_nuketown_intro_4");
	do_vox_subtitles("Voice", "Listen ive been stuck here for awhile, security protocol locked me in here.", 4, "");
	level notify ("bunker_talk", "vox_nuketown_intro_5");
	do_vox_subtitles("Voice", "Weird how its still active but there is nothing powering it.", 4, "");
	level notify ("bunker_talk", "vox_nuketown_intro_6");
	do_vox_subtitles("Voice", "Something may need to be done outside to turns on the backup power.", 3, "");
	level.cantalktobunker = true;
	
	foreach(player in level.players)
	{
		player.ignoreme = 0;
	}

	level.activatepower = true;
	level waittill ("secret_power_on");

	level.cantalktobunker = false;
	level notify ("facility_talk", "vox_nuketown_facility_1");
	do_vox_subtitles("P.A.", "Facility power restored. Please enter your ID.", 4, "");
	do_vox_subtitles("Voice", "I also took the liberty in connecting to your radio so you can hear me a little better.", 5, "vox_nuketown_radio_1");
	do_vox_subtitles("Voice", "My level is too low to access it.", 2, "vox_nuketown_intro_7");
	do_vox_subtitles("Voice", "A high level ID tag is out there somewhere.", 3, "vox_nuketown_intro_8");
	do_vox_subtitles("Voice", "They kept their cards inside a book in attempt to protect them from the missiles. Theyre not very bright.", 6, "vox_nuketown_intro_9");
	level.cantalktobunker = true;
	
	level thread spawnIDPart();
	level waittill ("secret_id_pickedup");

	level.cantalktobunker = false;
	do_vox_subtitles("Voice", "That card seems dirty. The computer will definiately not be able to read it.", 4, "vox_nuketown_radio_2");
	level.cantalktobunker = true;
	
	spawnSoulBoxStart();
	do_vox_subtitles("Voice", "Seems like it did half the job, maybe find another one to finish the process.", 4, "vox_nuketown_radio_3");
	spawnSoulBoxStart();
	do_vox_subtitles("Voice", "It looks readable! Place it near the Bunker, I can teleport it in here.", 4, "vox_nuketown_radio_4");
	do_vox_subtitles("Voice", "The teleporter is a prototype, too small to teleport me and Marlton out anyways.", 6, "vox_nuketown_radio_5");
	level.iscardclean = true;
	
	level waittill ("secret_id_clean");
	level.cantalktobunker = false;
	do_vox_subtitles("Voice", "Lets hope this works.", 1, "vox_nuketown_radio_6");
	
	wait 5;

	earthquake( 1, 1, (0,0,0), 950 );
	level notify ("nuketown_earthquake");
	level notify ("facility_talk", "vox_nuketown_facility_2");
	do_vox_subtitles("P.A.", "ID Accepted. Welcome Back Frank McCain.", 4, "");
	do_vox_subtitles("Voice", "This UI is a bit confusing, give me a few.", 3, "vox_nuketown_radio_7");
	level.cantalktobunker = true;
	
	waiting_through_ui();

	level.cantalktobunker = false;
	do_vox_subtitles("Voice", "Figured it out! I think.", 2, "vox_nuketown_radio_9");
	level notify ("facility_talk", "vox_nuketown_facility_3");
	do_vox_subtitles("P.A.", "Unable to identify security connection.", 3, "");
	do_vox_subtitles("Voice", "Always something with this damn place!", 3, "vox_nuketown_radio_10");
	do_vox_subtitles("Voice", "I got an idea, we can overload the protocol! Fuel this energy orb.", 5, "vox_nuketown_radio_11");
	level.cantalktobunker = true;
	
	payload_step_start();

	level.holdround = true;
	level.zombie_total = 0;
	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}

	level.cantalktobunker = false;
	level notify ("facility_talk", "vox_nuketown_facility_4");
	do_vox_subtitles("P.A.", "Security Connection Identified. Disabling Security Protocol...", 4, "");
	earthquake( 1, 1, (0,0,0), 950 );
	level notify ("nuketown_earthquake");
	level thread playdefusemusic();
	level thread alarm_sound();
	level notify ("facility_talk", "vox_nuketown_facility_5");
	level notify ("move_defusal_nukes");
	do_vox_subtitles("P.A.", "Connection Interfered! Self Destruct Activating...", 4, "");
	do_vox_subtitles("Voice", "No! No! No! I cant die in here! Please defuse those bombs!", 5, "vox_nuketown_radio_12");
	level.cantalktobunker = true;
	level.pausedoomsday = true;
	level thread maintain_defusal_zombie_count();
	start_nuke_segment();

	level.zombie_total = 0;
	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}

	level.cantalktobunker = false;
	level notify ("facility_talk", "vox_nuketown_facility_6");
	do_vox_subtitles("P.A.", "Self Destruct Cancelled. Security Protocol Lifted.", 4, "");
	do_vox_subtitles("Voice", "Yes! Thank you! I gotta finish some things here and I will leave once its quiet.", 5, "vox_nuketown_radio_13");
	level.cantalktobunker = true;
	level.holdround = false;
	level.zombie_total = 14;
	level.pausedoomsday = false;
	level.completedmodmainquest = true;
	if(getDvarInt("stats_completed_quest_2") != 1)
	{
		setDvar("stats_completed_quest_2", 1);
	}
	if(getDvarInt("continue_game_after_quest") == 1)
	{
		do_vox_subtitles("Voice", "Come to the bunker. I got some gifts for you!", 2, "vox_nuketown_radio_14");
		level thread spawnRewards((-1351.54, 995.177, -63.875));
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

local_audio_file()
{
	ent = spawn( "script_origin", (-1351.54, 995.177, -63.875) );
	for(;;)
	{
		level waittill ("bunker_talk", audio);
		ent playsound(audio);
	}
}

facility_talk()
{
//	ent = spawn( "script_origin", (86.3554, -1863.19, 1297.37) );
	ent = spawn( "script_origin", (0, 0, 700) );
	for(;;)
	{
		level waittill ("facility_talk", audio);
		ent playsound(audio);
	}
}

nuked_doomsday_clock_think()
{
    min_hand_model = getent( "clock_min_hand", "targetname" );
    min_hand_model.position = 0;

    while ( true )
    {
        if(!level.pausedoomsday)
		{
			level waittill( "update_doomsday_clock" );
			level thread update_doomsday_clock( min_hand_model );
		}
		else
		{
			wait 0.01;
		}
    }
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
			level thread spawnWeaponPickup("raygun_mark2_zm", (x,y,z));
		}
		else
		{
			level thread maps\mp\zombies\_zm_powerups::specific_powerup_drop("bonus_points_team", (x,y,z));
		}
		wait 1;
	}
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

talking_to_voice()
{
	
	if(!can_talk_round())
	{
		return;
	}
	
	lines = array("Told Broken Arrow it was a bad idea having a facility here. But they dont ever listen.","Marlton! What the fuck did you do to my MREs!","I saw a space station looking into the Moon, maybe it has something to do with this mess.","Things keep dropping from the sky, where did they even come from?","Those manniquins creep me out. Cant imagine what they look like now.","Do you hear the voices Marlton? Commanding me to do something.");
	audio = array("vox_nuketown_bunker_1","vox_nuketown_bunker_2","vox_nuketown_bunker_3","vox_nuketown_bunker_4","vox_nuketown_bunker_5","vox_nuketown_bunker_6");
	duration =  array(6,3,4,4,4,4);
	if(lines.size > level.bunkerchatter)
	{
		level notify ("bunker_talk", audio[level.bunkerchatter]);
		do_vox_subtitles("Voice", lines[level.bunkerchatter], duration[level.bunkerchatter], "");
		level.bunkerchatter += 1;
		level.talkerroundpassed = false;
	}
}

can_talk_round()
{
	if(level.talkerroundpassed == true)
	{
		return true;
	}
	else
	{
		return false;
	}
}

talk_round_think()
{
	for(;;)
	{
		level waittill ("between_round_over");
		level.talkerroundpassed = true;
	}
}

spawnIDPart()
{
	CardPickup = spawn( "trigger_radius", ((1055.2, 441.634, 108)), 1, 20, 100 );
	CardPickup setHintString("");
	CardPickup setcursorhint( "HINT_NOICON" );
	
	CardModel = spawn( "script_model", ((1055.2, 441.634, 108)));
	CardModel setmodel ("p_glo_books_single");
	CardModel rotateTo((90,-148.901,0),.1);

	
	for(;;)
	{
		CardPickup waittill( "trigger", i );
		if(i usebuttonpressed())
		{
			level notify ("secret_id_pickedup");
			CardPickup delete();
			CardModel delete();
			break;
		}
	}
}

PlaceCleanID()
{
	CardModel = spawn( "script_model", ((-1351.54, 995.177, -63.875)));
	CardModel setmodel ("p_glo_books_single");
	CardModel rotateTo((0,0,0),.1);
	wait 2;
	CardModel moveTo((-1331.75, 1050, -77.0928),0.8);
	CardModel waittill ("movedone");
	level notify ("secret_id_clean");
}

spawnSoulboxStart()
{
	if(level.soulboxcount == 0)
	{
		location = (1397.01, 534.993, -16.5647);
	}
	else
	{
		location = (-887.023, 710.607, -9.32891);
	}
	
	SoulBoxStart = spawn( "trigger_radius", (location), 1, 20, 100 );
	SoulBoxStart setHintString("");
	SoulBoxStart setcursorhint( "HINT_NOICON" );
	
	for(;;)
	{
		SoulBoxStart waittill( "trigger", i );
		if(i usebuttonpressed())
		{
			add_soul_box(location, -76, 450, 20, "p_glo_books_single");
			SoulBoxStart delete();
			break;
		}
		wait 0.1;
	}
}

spawnSoulboxPickup()
{
	if(level.soulboxcount == 0)
	{
		location = (1397.01, 534.993, -16.5647);
	}
	else
	{
		location = (-887.023, 710.607, -9.32891);
	}
	
	SoulBoxPickup = spawn( "trigger_radius", (location), 1, 20, 100 );
	SoulBoxPickup setHintString("");
	SoulBoxPickup setcursorhint( "HINT_NOICON" );
	
	SoulBoxModel = spawn( "script_model", location);
	SoulBoxModel setmodel ("p_glo_books_single");
	SoulBoxModel rotateTo((0,0,0),.1);
	
	level.soulboxcount += 1;
	
	for(;;)
	{
		SoulBoxPickup waittill( "trigger", i );
		if(i usebuttonpressed())
		{
			if(level.soulboxcount == 2)
			{
//				level.iscardclean = true;
			}
			
			SoulBoxPickup delete();
			SoulBoxModel delete();
			break;
		}
		wait 0.1;
	}
}

add_soul_box(location, rotation, range, soul_requirement, box_model)
{
	soulBox = spawn("script_model", location);
	soulBox setModel (box_model);
	soulBox rotateTo((0,rotation,0),0.1);
	soulBox.range = range;
	soulBox.totalsouls = 0;
	
	soulBox thread soul_box_watch_kills();
	
	while(soulBox.totalsouls <= soul_requirement)
	{
		wait 0.1;
	}
	
	foreach(player in level.players)
	{
		player.watchingsoulbox = undefined;
	}
	
	soulBox notify ("soul_box_done");
	soulBox playsound ("zmb_laugh_child");
	soulBox delete();
	
	spawnSoulboxPickup();
}

soul_box_watch_kills()
{
	self endon ("soul_box_done");
	for(;;)
	{
		foreach(player in level.players)
		{
			player thread soul_box_player(self, self.range);
		}
		wait 0.1;
	}
}

soul_box_player(soulBox, range)
{
	soulBox endon ("soul_box_done");
	if(!isDefined(self.watchingsoulbox))
	{
		self.watchingsoulbox = 1;
	}
	else
	{
		return;
	}
	for(;;)
	{
		self waittill( "zom_kill", zombie);
		if(distance(zombie.origin, soulBox.origin) <= range )
		{
			soulBox thread soul_box_particle_trail(zombie);
		}
		wait 0.1;
	}
}

soul_box_particle_trail(zombie)
{
    soul = spawn( "script_model", zombie getEye() );
    soul setmodel( "tag_origin" );
    wait 0.1;
    fx = playfxontag( level._effect["powerup_on_caution"], soul, "tag_origin" );
	soul thread remove_souls_on_box_finish(fx, self);
    soul moveto( self.origin, 0.8 );
    wait 0.8;
	soul playsound ("zmb_souls_collect");
    soul.owner = self;
    soul delete();
	fx delete();
	playfx(level._effect["powerup_grabbed"], self.origin);
	self.totalsouls += 1;
	if(self.totalsouls == 1)
	{
		self thread add_flame();
	}
}

remove_souls_on_box_finish(fx, soulBox)
{
	self endon ("death");
	soulBox waittill ("soul_box_done");
	self delete();
	fx delete();
}

add_flame()
{
    flame = spawn( "script_model", self.origin);
    flame setmodel( "tag_origin" );
    wait 0.1;
    fx = playfxontag( level._effect["fx_fire_fireplace_md"], flame, "tag_origin" );
	self waittill ("soul_box_done");
	flame delete();
	fx delete();
}

waiting_through_ui()
{
	for( i = 0; i < 3; i++ )
	{
		level waittill ("between_round_over");
		if(i == 1)
		{
			do_vox_subtitles("Voice", "Who made this? Monkeys?", 3, "vox_nuketown_radio_8");
		}
	}
}

nuked_standard_intermission()
{
    self closemenu();
    self closeingamemenu();
    level endon( "stop_intermission" );
    self endon( "disconnect" );
    self endon( "death" );
    self notify( "_zombie_game_over" );
    self.score = self.score_total;
    self.sessionstate = "intermission";
    self.spectatorclient = -1;
    self.killcamentity = -1;
    self.archivetime = 0;
    self.psoffsettime = 0;
    self.friendlydamage = undefined;
    self.game_over_bg = newclienthudelem( self );
    self.game_over_bg.x = 0;
    self.game_over_bg.y = 0;
    self.game_over_bg.horzalign = "fullscreen";
    self.game_over_bg.vertalign = "fullscreen";
    self.game_over_bg.foreground = 1;
    self.game_over_bg.sort = 1;
    self.game_over_bg setshader( "black", 640, 480 );
    self.game_over_bg.alpha = 1;
    clientnotify( "znfg" );
	if(level.mainquestcomplete == 1)
	{
	
	}
	else
	{
		level thread moon_rocket_follow_path();
	}
    wait 0.1;
    self.game_over_bg fadeovertime( 1 );
    self.game_over_bg.alpha = 0;
    flag_wait( "rocket_hit_nuketown" );
    self.game_over_bg fadeovertime( 1 );
    self.game_over_bg.alpha = 1;
}

spawn_shootable_power(location)
{
	powerModel = spawn("trigger_damage", location, 0, 40, 72);
	
	for(;;)
	{
		powerModel waittill( "damage", amount, attacker);
		if(1)
		{
			flame = spawn( "script_model", location);
			flame setmodel( "tag_origin" );
			wait 0.1;
			fx = playfxontag( level._effect["fx_fire_fireplace_md"], flame, "tag_origin" );
			while(!level.activatepower == true)
			{
				wait 0.1;
			}
			wait 2;
			powerModel playsound ("zmb_bunker_power_on");
			level notify ("nuketown_earthquake");
			earthquake( 1, 1, (0,0,0), 950 );
			wait 3;
			earthquake( 1, 1, (0,0,0), 1800 );
			level notify ("nuketown_earthquake");
			wait 1;
			earthquake( 1, 1, (0,0,0), 1800 );
			level notify ("nuketown_earthquake");
			wait 2;
			earthquake( 1, 1, (0,0,0), 1800 );
			level notify ("nuketown_earthquake");
			wait 6;
			level notify ("secret_power_on");
			break;
		}
		else
		{
			wait 0.01;
		}
	}
}

payload_step_start()
{
    orb = spawn( "script_model", (-1439.78, 1068.52, -63.875) + (0,0,50));
    orb setmodel( "tag_origin" );
    wait 0.1;
    fx = playfxontag(level._effect["powerup_on_solo"], orb, "tag_origin" );
	orbPickup = spawn( "trigger_radius", (-1439.78, 1068.52, -63.875), 1, 20, 100 );
	orbPickup setHintString("Press ^3&&1 ^7to start the Orb Fueling Challenge");
	orbPickup setcursorhint( "HINT_NOICON" );
	for(;;)
	{
		orbPickup waittill( "trigger", i );
		if(i usebuttonpressed())
		{
			orbPickup delete();
			level thread nuke_flash( 3 );
			orb payload_step();
			break;
		}
	}
}

spawn_power_effect(origin)
{
    power = spawn( "script_model", origin);
    power setmodel( "tag_origin" );
	zombies = getaiarray( level.zombie_team );
	for(;;)
	{
		zombies = getaiarray( level.zombie_team );
		if(zombies.size > 0)
		{
			fx = playfxontag( level._effect["fx_mp_elec_spark_burst_xsm_thin"], power, "tag_origin" );
			wait 0.8;
		}
		else
		{
			power delete();
			break;
		}
	}
}

payload_step()
{
	level.holdround = true;
	level.zombie_total = 0;
	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}
	level.pausedoomsday = true;
	
	level thread playpayloadintromusic();
	paths = array((-1473.46, 343.727, -62.875),(-928.396, 475.883, -55.875),(-862.63, 459.467, 80.9992),(921.89, 316.634, 79.125),(840.782, 639.248, -56.875),(1472.5, 778.073, -70.521),(-1352.49, 995.398, -63.875));

	foreach (path in paths)
	{
		self moveto( path + (0,0,50), 5 );
		self waittill( "movedone" );
		self payload_wait_for_player();
		earthquake( 1, 1, self.origin, 950 );
		self summon_wave();
	}

	level notify ("payload_over");
	level thread nuke_flash( 3 );

	level.zombie_total = 15;
	level.holdround = false;
	level.pausedoomsday = false;

	FinalEncounterTrigger = spawn( "trigger_radius", (self.origin), 50, 50, 50 );
	FinalEncounterTrigger setHintString("Press ^3&&1 ^7to send the Orb \n[Final Encounter] All Players need to be nearby.");
	FinalEncounterTrigger setcursorhint( "HINT_NOICON" );
	for(;;)
	{
		FinalEncounterTrigger waittill( "trigger", i );
		if ( i usebuttonpressed() )
		{
			if(players_are_near(FinalEncounterTrigger.origin, 100))
			{
				level thread nuke_flash( 3 );
				level.holdround = true;
				level.zombie_total = 0;
				zombies = getaiarray( level.zombie_team );
				foreach (i in zombies)
				{
					i dodamage(i.health,i.origin);
				}
				FinalEncounterTrigger delete();
				wait 2;
				self moveTo((-1331.75, 1050, -77.0928),0.8);
				self waittill( "movedone" );
				break;
			}
		}
		wait 0.1;
	}
}

players_are_near(origin, distance)
{
	num = 0;
	foreach(player in level.players)
	{
		if(distance(player.origin, origin) < distance)
		{
			num += 1;
		}
	}
	
	max_players = level.players.size;
	
	foreach(player in level.players)
	{
		if(isDefined(player.bot))
		{
			max_players -= 1;
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

payload_wait_for_player()
{
	for(;;)
	{
		foreach(player in level.players)
		{
			if(distance(player.origin, self.origin) <= 300)
			{
				return;
			}
		}
		wait 0.01;
	}
}

summon_wave()
{
	times = 30;
	
	for( i = 0; i < times; i++ )
	{
		spawner = random( level.zombie_spawners );
		self thread spawn_zombie_with_particle_trail(spawner);
		wait randomfloatrange(0,1);
	}
	self thread spawn_power_effect(self.origin);
	for(;;)
	{
		zombies = getaiarray( level.zombie_team );
		if(zombies.size == 0)
		{
			return;
		}
		wait 0.01;
	}
}

spawn_zombie_with_particle_trail(spawner)
{
    ai = spawn_zombie( spawner, "zombie", spawner.origin );
	soul = spawn( "script_model", self.origin );
    soul setmodel( "tag_origin" );
    wait 0.1;
    fx = playfxontag( level._effect["powerup_on_solo"], soul, "tag_origin" );
	soul thread remove_souls_on_box_finish(fx, self);
    soul moveto( ai.origin, 0.8 );
    wait 0.8;
    soul.owner = self;
    soul delete();
	fx delete();
	playfx(level._effect["powerup_grabbed"], ai.origin);
	ai set_zombie_run_cycle("sprint");
}

summon_runner_wave()
{
	times = 15;
	
	for( i = 0; i < times; i++ )
	{
		spawner = random( level.zombie_spawners );
		ai = spawn_zombie( spawner, "zombie", spawner.origin );
		ai set_zombie_run_cycle("super_sprint");
	}
	
	for(;;)
	{
		zombies = getaiarray( level.zombie_team );
		if(zombies.size == 0)
		{
			return;
		}
		wait 0.01;
	}
}


//Defuse Locaitons

//(668.882, 674.805, -56.875) - Angle: -30.2057
//(-711.524, 544.72, 80.125) - Angle: -161.075
//(-257.264, 553.082, -60.7844) - Angle: 117.896

spawn_defuse_machines(location, angle)
{
	defusalTrigger = spawn( "trigger_radius", location, 1, 50, 50 );
	defusalTrigger setHintString("");
	defusalTrigger setcursorhint( "HINT_NOICON" );
	defusalModel = spawn( "script_model", location);
	defusalModel setmodel ("p6_zm_tm_crate_01_short");
	defusalModel rotateTo((0,angle+90,0),.1);
	
	defusalCollision = spawn( "script_model", location);
	defusalCollision setModel("collision_clip_32x32x128");
	defusalCollision rotateTo((0,angle+90,0),.1);
	
	level waittill ("move_defusal_nukes");

	defusalBomb = spawn("script_model", location);
	defusalBomb setModel ("zombie_bomb");
	defusalBomb rotateTo((-90,angle,0),.1);

	ending_location = (defusalBomb.origin + (0,0,60));
	defusalBomb moveto(ending_location,10);
	defusalBomb waittill("movedone");

	defusalTrigger setHintString("Press ^3&&1 ^7to defuse.");
	defusalTrigger.candefuse = true;
	defusalTrigger.defused = false;
	
	defusalModel thread alarm_effect();
	
	level.bombs[level.bombs.size] = defusalTrigger;
	
	for(;;)
	{
		defusalTrigger waittill( "trigger", i );
		if ( i usebuttonpressed() )
		{
			if(defusalTrigger.defused == false)
			{
				if(defusalTrigger.candefuse == true)
				{
					earthquake( 1, 1, defusalTrigger.origin, 500 );
					defusalTrigger setHintString("Defusing...");
					defusalTrigger thread loop_ticking();
					defusalTrigger bomb_defusal_start(defusalBomb);
					defusalModel notify ("bomb_defused");
					defusalTrigger notify ("bomb_defused");
					defusalTrigger setHintString("Bomb Defused!");
					earthquake( 1, 1, defusalTrigger.origin, 500 );
					defusalBomb delete();
					break;
				}
				else
				{
					defusalTrigger setHintString ("The defuser is being used elsewhere!");
					wait 2;
					defusalTrigger setHintString("Press ^3&&1 ^7to defuse.");
				}
			}
			else
			{
				defusalTrigger setHintString("Bomb Defused!");
			}
		}
		wait 0.1;
	}
}

alarm_effect()
{
	self endon ("bomb_defused");
	for(;;)
	{
		playfx( level._effect["powerup_grabbed"], self.origin );
		wait 1;
	}
}

bomb_defusal_start(bomb_entity)
{
	level endon ("defusal_timeup");
	foreach(bomb in level.bombs)
	{
		if(bomb != self)
		{
			bomb.candefuse = false;
		}
	}
	level thread summon_runner_wave();
	ending_location = (bomb_entity.origin - (0,0,60));
	bomb_entity moveto(ending_location,20);
	bomb_entity waittill("movedone");
	level.bombsdefused += 1;
	foreach(bomb in level.bombs)
	{
		if(bomb != self)
		{
			bomb.candefuse = true;
		}
	}
}

loop_ticking()
{
	level endon ("defusal_timeup");
	level endon ("defusal_end");
	self endon ("bomb_defused");
	for(;;)
	{
		self playsound( "zmb_clock_hand" );
		wait 0.5;
	}
}

boss_bar()
{
	level.bombsdefused = 0;
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
	
	health_bar_text setText("Self Destruct Bombs");
	
	while(level.bombsdefused < 3 && !level.bombexplode)
	{
		health_bar updatebar((3 - level.bombsdefused) / 3);

		health_bar.bar.color = (1,1,1);
		
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

maintain_defusal_zombie_count()
{
	level endon ("defusal_end");
	level endon ("defusal_timeup");
	for(;;)
	{
		zombies = getaiarray( level.zombie_team );
		if(zombies.size <= 15)
		{
			spawner = random( level.zombie_spawners );
			ai = spawn_zombie( spawner, "zombie", spawner.origin );
			ai set_zombie_run_cycle("sprint");		
		}
		wait 0.01;
	}
}

nukedefusalhud()
{
	level endon("end_game");

	max_time = level.nuketimer;

	level.nukedefusal_text = newhudelem();
	level.nukedefusal_text.alignx = "left";
	level.nukedefusal_text.aligny = "top";
	level.nukedefusal_text.horzalign = "user_left";
	level.nukedefusal_text.vertalign = "user_top";
	level.nukedefusal_text.x = 60;
	level.nukedefusal_text.y = 20;
	level.nukedefusal_text.fontscale = 1;
	level.nukedefusal_text.alpha = 1;
	level.nukedefusal_text.color = ( 1, 1, 1 );
	level.nukedefusal_text.hidewheninmenu = 1;
	level.nukedefusal_text.foreground = 0;
	level.nukedefusal_text.label = &"Defuse the Bombs: ^6";
	level.nukedefusal_text setTimer(max_time);
	
	level waittill_any ("defusal_end","defusal_timeup");
	
	level.nukedefusal_text destroy();
}

start_nuke_segment()
{
	level.holdround = true;
	level.nuketimer = 100;
	level.zombie_total = 0;
	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}
	foreach(player in level.players)
	{
		player thread boss_bar();
	}
	level thread nukedefusalhud();
	level notify ("defusal_start");
	begin_countdown();
}

begin_countdown()
{
	level endon ("defusal_end");
	earthquake( 1, 1, (0,0,0), 1800 );
	level notify ("nuketown_earthquake");
	thread wait_for_bombs_defused();
	wait level.nuketimer;
	level notify ("defusal_timeup");
	zombies = getaiarray( level.zombie_team );
	foreach (i in zombies)
	{
		i dodamage(i.health,i.origin);
	}
	level.bombexplode = true;
	wait 0.2;
	level notify ("nuketown_earthquake");
	earthquake( 1, 9999, (0,0,0), 3000 );
	get_players()[ 0 ] playsound( "evt_nuke_flash" );

	fadetowhite = newhudelem();
	fadetowhite.x = 0;
	fadetowhite.y = 0;
	fadetowhite.alpha = 0;
	fadetowhite.horzalign = "fullscreen";
	fadetowhite.vertalign = "fullscreen";
	fadetowhite.foreground = 1;
	fadetowhite setshader( "white", 640, 480 );
	fadetowhite fadeovertime( 1 );
	fadetowhite.alpha = 1;
	wait 3;
	
	for( i = 0; i < 100; i++ )
	{
		color = (100-i)/100;
		fadetowhite.color = (color,color,color);
		wait 0.01;
	}
	wait 1;
	fadetowhite.foreground = 0;
	level notify ("end_game");
	wait 999;
}

wait_for_bombs_defused()
{
	level endon ("defusal_timeup");
	while(level.bombsdefused < 3)
	{
	
		wait 0.01;
	}
	level notify ("defusal_end");
}

alarm_sound()
{
	level endon ("defusal_end");
	level endon ("defusal_timeup");
	ent = spawn( "script_origin", ( 0, 0, 0 ) );
	for(;;)
	{
		ent playsound ("zmb_bunker_alert");
		wait 5;
	}
}

playpayloadmusic()
{
    ent = spawn( "script_origin", ( 0, 0, 0 ) );
    ent thread stoppayloadmusic();
	ent playloopsound( "mus_nuketown_payload_loop", 0.1 );
}

stoppayloadmusic()
{
    level waittill_any( "end_game", "payload_over" );
    self stoploopsound( 1.5 );
    wait 1;
    self delete();
}

playpayloadintromusic()
{
    ent = spawn( "script_origin", ( 0, 0, 0 ) );
	ent playsound( "mus_nuketown_payload_start");
	wait 17;
	ent stopsounds();
	level thread playpayloadmusic();
	ent delete();
}

playdefusemusic()
{
    ent = spawn( "script_origin", ( 0, 0, 0 ) );
	ent playloopsound( "mus_nuketown_defusal_start", 0.1 );
	level waittill ("defusal_start");
	ent stoploopsound( 0.1 );
    ent thread stopdefusemusic();
	ent playloopsound( "mus_nuketown_defusal", 0.1 );
}

stopdefusemusic()
{
    level waittill_any( "end_game", "defusal_end", "defusal_timeup" );
    self stoploopsound( 1.5 );
    wait 1;
    self delete();
}

earthquake_sound()
{
	ent = spawn( "script_origin", ( 0, 0, 0 ) );
	for(;;)
	{
		level waittill ("nuketown_earthquake");
		ent playsound ("zmb_nuketown_earthquake");
	}
}

setup_sidestuff()
{
	level thread juggSideSecret();
}

jugSecret(location, angle)
{
	jugModel = spawn( "script_model", location);
	jugModel setmodel ("t6_wpn_zmb_perk_bottle_jugg_world");
	jugModel rotateTo((90,angle,0),.1);
	
	jugDamage = spawn( "trigger_damage", location, 0, 20, 72);
	
	for(;;)
	{
		jugDamage waittill( "damage", amount, who );
		playfx(level._effect["powerup_grabbed"], jugModel.origin);
		jugModel delete();
		jugDamage delete();
		break;
	}
}

juggSideSecret()
{
	jugSecret((609.014, -1870.91, 135.295), -170.305);
	jugSecret((-515.9, -1151.06, 192.907), 156.672);
	jugSecret((120.821, -1198.27, 42.4109), 0);
	jugPickup((120.821, -1198.27, 42.4109), (85.8834, -292.757, -21.9625));
}

jugPickup(location, destination)
{
	jugModel = spawn( "script_model", location);
	jugModel setmodel ("t6_wpn_zmb_perk_bottle_jugg_world");
	jugModel rotateTo((0,0,0),.1);
	
	jugParticle = spawn("script_model", location);
	jugParticle setmodel("tag_origin");
	fx = playfxontag( level._effect["powerup_on"], jugParticle, "tag_origin");
	jugParticle linkto(jugModel, "tag_origin");
	jugModel moveto(destination, 10);
	
	jugModel waittill ("movedone");
	
	jugTrigger = spawn( "trigger_radius", (destination), 1, 20, 100 );
	
	for(;;)
	{
		jugTrigger waittill ("trigger", i);
		if(isPlayer(i))
		{
			playfx(level._effect["powerup_grabbed"], destination);
			jugParticle delete();
			jugTrigger delete();
			jugModel delete();
			fx delete();
			foreach(player in level.players)
			{
				player thread give_perk( "specialty_armorvest", 1 );
			}
			break;
		}
	}
}

custom_jumpscare(location)
{
	jumpscareDamageTrigger = spawn("trigger_damage", location, 0, 40, 72);
	
	for(;;)
	{
		jumpscareDamageTrigger waittill( "damage", amount, attacker);
		if(jumpscareInUse == false)
		{
			jumpscareInUse = true;
			jumpscarehud = newclienthudelem( self );
			jumpscarehud.x = 0;
			jumpscarehud.y = 0;
			jumpscarehud.alpha = 0;
			jumpscarehud.horzalign = "fullscreen";
			jumpscarehud.vertalign = "fullscreen";
			jumpscarehud.foreground = 1;
			jumpscarehud setshader( "nuketown_jumpscare", 640, 480 );
			jumpscarehud fadeovertime( 0.1 );
			jumpscarehud.alpha = 0.8;
			wait 1;
			jumpscarehud fadeovertime( 0.1 );
			jumpscarehud.alpha = 0;
			wait 1.1;
			jumpscarehud destroy();
			jumpscareInUse = false;
		}
	}
}


//(499.823, 256.719, 78.7544)