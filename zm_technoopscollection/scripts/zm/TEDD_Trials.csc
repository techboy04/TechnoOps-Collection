#include clientscripts\mp\_utility;
#include clientscripts\mp\_music;

main()
{
	level._effect["perk_meteor"] = loadfx( "maps/zombie/fx_zmb_trail_perk_meteor" );
}

#using_animtree("zm_transit_automaton");

init_animtree()
{
    scriptmodelsuseanimtree( #animtree );
}