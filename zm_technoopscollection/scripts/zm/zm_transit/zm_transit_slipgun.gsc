#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weap_slipgun;

main()
{
    maps\mp\zombies\_zm_weap_slipgun::init();

    if ( isdefined( level.slipgun_as_equipment ) && level.slipgun_as_equipment )
    {
        register_equipment_for_level( "slipgun_zm" );
    }

    
    if ( isdefined( level.slipgun_as_equipment ) && level.slipgun_as_equipment )
    {
        include_equipment( "slipgun_zm" );
    }
}