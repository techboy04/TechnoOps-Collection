#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_equip_subwoofer;

main()
{
	if(getDvarInt("power_activates_buildables") == 1)
	{
		replacefunc(maps\mp\zombies\_zm_equip_subwoofer::startsubwooferdeploy, ::startsubwooferdeploy_new);
	}
}


startsubwooferdeploy_new( weapon, armed )
{
    self endon( "death" );
    self endon( "disconnect" );
    self endon( "equip_subwoofer_zm_taken" );
    self thread watchforcleanup();

    if ( isdefined( self.subwoofer_kills ) )
    {
        weapon.subwoofer_kills = self.subwoofer_kills;
        self.subwoofer_kills = undefined;
    }

    if ( !isdefined( weapon.subwoofer_kills ) )
        weapon.subwoofer_kills = 0;

    if ( !isdefined( self.subwoofer_health ) )
    {
        self.subwoofer_health = 60;
        self.subwoofer_power_level = 4;
    }

    if ( isdefined( weapon ) )
    {
/#
        self thread debugsubwoofer();
#/

        while(!flag("power_on"))
		{
			wait 0.1;
		}
		weapon.power_on = 1;

		self thread subwooferthink( weapon, armed );

        if ( !( isdefined( level.equipment_subwoofer_needs_power ) && level.equipment_subwoofer_needs_power ) )
            self thread startsubwooferdecay( weapon );

        self thread maps\mp\zombies\_zm_buildables::delete_on_disconnect( weapon );
        weapon waittill( "death" );

        if ( isdefined( level.subwoofer_sound_ent ) )
        {
            level.subwoofer_sound_ent playsound( "wpn_zmb_electrap_stop" );
            level.subwoofer_sound_ent delete();
            level.subwoofer_sound_ent = undefined;
        }

        self notify( "subwoofer_cleanup" );
    }
}