#include clientscripts\mp\_filter;
#include clientscripts\mp\_visionset_mgr;

init()
{
	level waittill ("connected", player);
	player waittill ("spawned_player");
	wait 0.1;
	player iprintln ("Tried to give you Turned affect");
	enable_filter_zm_turned( player, 0, 0 );
	player setsonarattachmentenabled(1);
}