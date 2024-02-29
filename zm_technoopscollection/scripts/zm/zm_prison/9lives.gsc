#include maps\mp\zombies\_zm_afterlife;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm_utility;


//-------------------------------- P L E A S E  R E A D -----------------------------------//

/*
I am deeply sorry I couldn't get the hud to display the current lives, me and staff member homura
have tried for many days to fix this issue, but unfortunately, we couldn't. So bare with me as you'll
have to rely on the chat to know how many lives you have, the cause of this error is in line 61, it 
would seem to be that it only displays base 4 numbers. If anyone has a fix, leave a comment on the forum post
or message me directly if you know a fix. GLHF!!!!!

hehe sorta fixed by Techie :)
*/

init()
{
	level.clientid = 0;
	level thread onplayerconnect();
}

onplayerconnect()
{

	for ( ;; )
	{
		level waittill( "connecting", player );
		player.clientid = level.clientid;
		level.clientid++;
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{   
    for(;;)
    {
        self waittill("spawned_player");
        if(getDvar("mapname") == "zm_prison")
        {
        	self thread livesHUD();
//			self thread printIndefin();
       		self thread afterlife_player_refill_watch();
       	}
    }
}

afterlife_player_refill_watch()
{
	self endon( "_zombie_game_over" );
	self endon("disconnect");
	level endon( "stage_final" );
	while ( 1 )
	{
		level waittill( "end_of_round" );
		wait 2;
		self afterlife_add();
		reset_all_afterlife_unitriggers();
	}
}

afterlife_add()
{
	    if (self.lives >= 0 && self.lives < 9) 
		{
          
			self.lives++;
			self thread afterlife_add_fx();

		}
	self playsoundtoplayer( "zmb_afterlife_add", self );
	self setclientfieldtoplayer( "player_lives", self.lives );
} 

printIndefin()
{
	self endon("death");
	self endon("disconnect");

	for(;;)
	{
		self iprintln("Your current available lives are " + self.lives);
		wait 10;
	}
}

livesHUD()
{	
	afterlife_bg = newClientHudElem(self);
    afterlife_bg.horzalign = "right";
    afterlife_bg.vertalign = "bottom";
	afterlife_bg.x -= 55;
	afterlife_bg.y -= 80;
	afterlife_bg.fontscale = 2;
	afterlife_bg.alpha = 1;
	afterlife_bg.color = ( 0.2, 0.1, 0.1 );
	afterlife_bg.hidewheninmenu = 1;
	afterlife_bg.foreground = 1;
	afterlife_bg setShader("progress_bar_bg", 124, 32);
	
	afterlifehud = newClientHudElem(self);
	afterlifehud.x -= 35;
//	afterlifehud.y -= 55;
	afterlifehud.y -= 70;
	afterlifehud.alpha = 1;
    afterlifehud.horzalign = "right";
    afterlifehud.vertalign = "bottom";
	afterlifehud.hidewheninmenu = 1;
	afterlifehud.foreground = 1;
	afterlifehud.label = &"Afterlife Lives: ^6";

	while(1)
	{
		afterlifehud setValue (self.lives);
		wait .5;
	}
}


