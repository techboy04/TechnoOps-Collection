#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\zombies\_zm_weapons;

init()
{
	precacheitem( "slipgun_zm" );
	precacheitem( "slipgun_upgraded_zm" );
	precacheitem( "slip_bolt_zm" );
	precacheitem( "slip_bolt_upgraded_zm" );
    if (level.script == "zm_transit")
	{
		// include_weapon("blundergat_zm");
		// include_weapon("blundergat_upgraded_zm", 0);
		// include_weapon("blundersplat_zm");
		// include_weapon("blundersplat_upgraded_zm", 0);
    //add_zombie_weapon( "blundergat_zm", "blundergat_upgraded_zm", &"ZOMBIE_WEAPON_BLUNDERGAT", 500, "wpck_shot", "", undefined, 1 );
    //add_zombie_weapon( "blundersplat_zm", "blundersplat_upgraded_zm", &"ZOMBIE_WEAPON_BLUNDERGAT", 500, "wpck_shot", "", undefined );
	}
}
