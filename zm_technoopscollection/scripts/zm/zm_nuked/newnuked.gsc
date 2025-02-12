#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zm_nuked_perks;

main()
{
	replacefunc(maps\mp\zm_nuked_perks::perks_from_the_sky, ::new_perks_from_the_sky);
	replacefunc(maps\mp\zm_nuked::update_doomsday_clock, ::new_update_doomsday_clock);
}

new_perks_from_the_sky()
{
    level thread turn_perks_on();
    top_height = 8000;
    machines = [];
    machine_triggers = [];
    machines[0] = getent( "vending_revive", "targetname" );

    if ( !isdefined( machines[0] ) )
        return;

    machine_triggers[0] = getent( "vending_revive", "target" );
    move_perk( machines[0], top_height, 5.0, 0.001 );
    machine_triggers[0] trigger_off();
    machines[1] = getent( "vending_doubletap", "targetname" );
    machine_triggers[1] = getent( "vending_doubletap", "target" );
    move_perk( machines[1], top_height, 5.0, 0.001 );
    machine_triggers[1] trigger_off();
    machines[2] = getent( "vending_sleight", "targetname" );
    machine_triggers[2] = getent( "vending_sleight", "target" );
    move_perk( machines[2], top_height, 5.0, 0.001 );
    machine_triggers[2] trigger_off();
    machines[3] = getent( "vending_jugg", "targetname" );
    machine_triggers[3] = getent( "vending_jugg", "target" );
    move_perk( machines[3], top_height, 5.0, 0.001 );
    machine_triggers[3] trigger_off();
    machine_triggers[4] = getent( "specialty_weapupgrade", "script_noteworthy" );
    machines[4] = getent( machine_triggers[4].target, "targetname" );
    move_perk( machines[4], top_height, 5.0, 0.001 );
    machine_triggers[4] trigger_off();
    flag_wait( "initial_blackscreen_passed" );
    wait( randomfloatrange( 5.0, 15.0 ) );
    players = get_players();

	if(getDvarInt("nuketown_perks_mode") == 1)
	{
		drop_all_perks(machines, machine_triggers);
	}
	else if(getDvarInt("nuketown_perks_mode") == 2)
	{
		level waittill ("clock_chime");
		bring_random_perk( machines, machine_triggers );
		level waittill ("clock_chime");
		bring_random_perk( machines, machine_triggers );
		level waittill ("clock_chime");
		bring_random_perk( machines, machine_triggers );
		level waittill ("clock_chime");
		bring_random_perk( machines, machine_triggers );
		level waittill ("clock_chime");
		bring_random_perk( machines, machine_triggers );
	}
	else if(getDvarInt("nuketown_perks_mode") == 3)
	{
		level waittill( "between_round_over" );
		bring_random_perk( machines, machine_triggers );
		level waittill( "between_round_over" );
		bring_random_perk( machines, machine_triggers );
		level waittill( "between_round_over" );
		bring_random_perk( machines, machine_triggers );
		level waittill( "between_round_over" );
		bring_random_perk( machines, machine_triggers );
		level waittill( "between_round_over" );
		bring_random_perk( machines, machine_triggers );
	}
	else
	{
		if ( players.size == 1 )
		{
			wait 4.0;
			index = 0;
			bring_perk( machines[index], machine_triggers[index] );
			arrayremoveindex( machines, index );
			arrayremoveindex( machine_triggers, index );
		}

		
		wait_for_round_range( 3, 5 );
		wait( randomintrange( 30, 60 ) );
		bring_random_perk( machines, machine_triggers );
		wait_for_round_range( 6, 9 );
		wait( randomintrange( 30, 60 ) );
		bring_random_perk( machines, machine_triggers );
		wait_for_round_range( 10, 14 );
		wait( randomintrange( 60, 120 ) );
		bring_random_perk( machines, machine_triggers );
		wait_for_round_range( 15, 19 );
		wait( randomintrange( 60, 120 ) );
		bring_random_perk( machines, machine_triggers );
		wait_for_round_range( 20, 25 );
		wait( randomintrange( 60, 120 ) );
		bring_random_perk( machines, machine_triggers );
	}
	
	level thread finishedperkssound();

}

drop_all_perks(machines, machine_triggers)
{
    count = machines.size;

    if ( count <= 0 )
        return;

    for (index = 0; index < machines.size; index++)
	{
		level thread bring_perk( machines[index], machine_triggers[index] );
		arrayremoveindex( machines[index], machine_triggers[index] );
		arrayremoveindex( machines[index], machine_triggers[index] );
	}
}

new_update_doomsday_clock( min_hand_model )
{
    while ( is_true( min_hand_model.is_updating ) )
        wait 0.05;

    min_hand_model.is_updating = 1;

    if ( min_hand_model.position == 0 )
    {
        min_hand_model.position = 3;
        min_hand_model rotatepitch( -90, 1 );
        min_hand_model playsound( "zmb_clock_hand" );
        min_hand_model waittill( "rotatedone" );
        min_hand_model playsound( "zmb_clock_chime" );
		level notify ("clock_chime");
    }
    else
    {
        min_hand_model.position--;
        min_hand_model rotatepitch( 30, 1 );
        min_hand_model playsound( "zmb_clock_hand" );
        min_hand_model waittill( "rotatedone" );
    }

    level notify( "nuke_clock_moved" );
    min_hand_model.is_updating = 0;
}

finishedperkssound()
{
    ent = spawn( "script_origin", ( 0, 0, 0 ) );
	for(i = 0; i < 5; i++)
	{
		ent playsound( "zmb_clock_chime" );
		wait 2;
	}
}