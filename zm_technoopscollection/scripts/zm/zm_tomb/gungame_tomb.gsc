#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zm_tomb_craftables;
#include maps\mp\zm_tomb_dig;

main()
{
	if (getDvarInt("gamemode") == 1)
	{
		replacefunc(maps\mp\zm_tomb_craftables::staffcraftable_air, ::staffcraftable_air_minigame);
		replacefunc(maps\mp\zm_tomb_craftables::staffcraftable_fire, ::staffcraftable_fire_minigame);
		replacefunc(maps\mp\zm_tomb_craftables::staffcraftable_lightning, ::staffcraftable_lightning_minigame);
		replacefunc(maps\mp\zm_tomb_craftables::staffcraftable_water, ::staffcraftable_water_minigame);
		
		replacefunc(maps\mp\zm_tomb_dig::waittill_dug, ::waittill_dug_minigame);
	}
}

staffcraftable_air_minigame()
{

}

staffcraftable_fire_minigame()
{

}

staffcraftable_lightning_minigame()
{

}

staffcraftable_water_minigame()
{

}

waittill_dug_minigame( s_dig_spot )
{
    while ( true )
    {
        self waittill( "trigger", player );

        if ( isdefined( player.dig_vars["has_shovel"] ) && player.dig_vars["has_shovel"] )
        {
            player playsound( "evt_dig" );
            s_dig_spot.dug = 1;
            level.n_dig_spots_cur--;
            playfx( level._effect["digging"], self.origin );
            player setclientfieldtoplayer( "player_rumble_and_shake", 1 );
            player maps\mp\zombies\_zm_stats::increment_client_stat( "tomb_dig", 0 );
            player maps\mp\zombies\_zm_stats::increment_player_stat( "tomb_dig" );
            s_staff_piece = s_dig_spot maps\mp\zm_tomb_main_quest::dig_spot_get_staff_piece( player );

            if ( isdefined( s_staff_piece ) )
            {
                s_staff_piece maps\mp\zm_tomb_main_quest::show_ice_staff_piece( self.origin );
                player dig_reward_dialog( "dig_staff_part" );
            }
            else
            {
                n_good_chance = 50;

                if ( player.dig_vars["n_spots_dug"] == 0 || player.dig_vars["n_losing_streak"] == 3 )
                {
                    player.dig_vars["n_losing_streak"] = 0;
                    n_good_chance = 100;
                }

                if ( player.dig_vars["has_upgraded_shovel"] )
                {
                    if ( !player.dig_vars["has_helmet"] )
                    {
                        n_helmet_roll = randomint( 100 );

                        if ( n_helmet_roll >= 95 )
                        {
                            player.dig_vars["has_helmet"] = 1;
                            n_player = player getentitynumber() + 1;
                            level setclientfield( "helmet_player" + n_player, 1 );
                            player playsoundtoplayer( "zmb_squest_golden_anything", player );
                            player maps\mp\zombies\_zm_stats::increment_client_stat( "tomb_golden_hard_hat", 0 );
                            player maps\mp\zombies\_zm_stats::increment_player_stat( "tomb_golden_hard_hat" );
                            return;
                        }
                    }

                    n_good_chance = 70;
                }

                n_prize_roll = randomint( 100 );

                if ( n_prize_roll > n_good_chance )
                {
                    if ( cointoss() )
                    {
                        player dig_reward_dialog( "dig_grenade" );
                        self thread dig_up_grenade( player );
                    }
                    else
                    {
                        player dig_reward_dialog( "dig_zombie" );
                        self thread dig_up_zombie( player, s_dig_spot );
                    }

                    player.dig_vars["n_losing_streak"]++;
                }
                else
                    self thread dig_up_powerup( player );
            }

            if ( !player.dig_vars["has_upgraded_shovel"] )
            {
                player.dig_vars["n_spots_dug"]++;

                if ( player.dig_vars["n_spots_dug"] >= 30 )
                {
                    player.dig_vars["has_upgraded_shovel"] = 1;
                    player thread ee_zombie_blood_dig();
                    n_player = player getentitynumber() + 1;
                    level setclientfield( "shovel_player" + n_player, 2 );
                    player playsoundtoplayer( "zmb_squest_golden_anything", player );
                    player maps\mp\zombies\_zm_stats::increment_client_stat( "tomb_golden_shovel", 0 );
                    player maps\mp\zombies\_zm_stats::increment_player_stat( "tomb_golden_shovel" );
                }
            }

            return;
        }
    }
}