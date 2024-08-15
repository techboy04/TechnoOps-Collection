#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\zombies\_zm_craftables;
#include maps\mp\zm_tomb_capture_zones;
#include maps\mp\zombies\_zm_score;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\animscripts\zm_death;
#include maps\mp\animscripts\zm_utility;
#include maps\mp\zombies\_zm_net;
#include maps\mp\zm_tomb_giant_robot_ffotd;
#include maps\mp\animscripts\zm_shared;
#include maps\mp\zombies\_zm_ai_mechz;
#include maps\mp\zombies\_zm_weap_one_inch_punch;
#include maps\mp\zm_tomb_teleporter;
#include maps\mp\zombies\_zm_zonemgr;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_audio;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_clone;
#include maps\mp\zm_tomb_vo;
#include maps\mp\zombies\_zm;
#include maps\mp\zm_tomb_giant_robot;

#using_animtree("zm_tomb_giant_robot_hatch");

main()
{
	if (getDvarInt("enable_recapturerounds") == 0)
	{
		replacefunc(maps\mp\zm_tomb_capture_zones::recapture_round_start, ::recapture_round_start_new);
	}
	replacefunc(maps\mp\zombies\_zm_craftables::craftable_use_hold_think_internal, ::craftable_use_hold_think_internal_new);
	if (getDvarInt("enable_originsfootchanges") == 1)
	{
		replacefunc(maps\mp\zm_tomb_giant_robot::giant_robot_start_walk, ::giant_robot_start_walk_new);
	}
	if (getDvarInt("enable_samanthaintro") == 0)
	{
		replacefunc(maps\mp\zm_tomb_vo::start_samantha_intro_vo, ::start_samantha_intro_vo_new);
	}
}

recapture_round_start_new()
{

}

craftable_use_hold_think_internal_new( player )
{
    wait 0.01;

    if ( !isdefined( self ) )
    {
        self notify( "craft_failed" );

        if ( isdefined( player.craftableaudio ) )
        {
            player.craftableaudio delete();
            player.craftableaudio = undefined;
        }

        return;
    }

    if ( !isdefined( self.usetime ) )
        self.usetime = int( 3000 );

	if (player hasPerk("specialty_fastreload"))
	{
		self.usetime = self.usetime/3;
	}

    self.craft_time = self.usetime;
    self.craft_start_time = gettime();
    craft_time = self.craft_time;
    craft_start_time = self.craft_start_time;
    player disable_player_move_states( 1 );
    player increment_is_drinking();
    orgweapon = player getcurrentweapon();
    player giveweapon( "zombie_builder_zm" );
    player switchtoweapon( "zombie_builder_zm" );
    self.stub.craftablespawn craftable_set_piece_crafting( player.current_craftable_piece );
    player thread player_progress_bar( craft_start_time, craft_time );

    if ( isdefined( level.craftable_craft_custom_func ) )
        player thread [[ level.craftable_craft_custom_func ]]( self.stub );

    while ( isdefined( self ) && player player_continue_crafting( self.stub.craftablespawn ) && gettime() - self.craft_start_time < self.craft_time )
        wait 0.05;

    player notify( "craftable_progress_end" );
    player maps\mp\zombies\_zm_weapons::switch_back_primary_weapon( orgweapon );
    player takeweapon( "zombie_builder_zm" );

    if ( isdefined( player.is_drinking ) && player.is_drinking )
        player decrement_is_drinking();

    player enable_player_move_states();

    if ( isdefined( self ) && player player_continue_crafting( self.stub.craftablespawn ) && gettime() - self.craft_start_time >= self.craft_time )
    {
        self.stub.craftablespawn craftable_clear_piece_crafting( player.current_craftable_piece );
        self notify( "craft_succeed" );
    }
    else
    {
        if ( isdefined( player.craftableaudio ) )
        {
            player.craftableaudio delete();
            player.craftableaudio = undefined;
        }

        self.stub.craftablespawn craftable_clear_piece_crafting( player.current_craftable_piece );
        self notify( "craft_failed" );
    }
}

giant_robot_start_walk_new( n_robot_id, b_has_hatch )
{
    if ( !isdefined( b_has_hatch ) )
        b_has_hatch = 1;

    ai = getent( "giant_robot_walker_" + n_robot_id, "targetname" );
    level.gr_foot_hatch_closed[n_robot_id] = 0;
    ai.b_has_hatch = b_has_hatch;
    ai ent_flag_clear( "kill_trigger_active" );
    ai ent_flag_clear( "robot_head_entered" );

    if ( isdefined( ai.b_has_hatch ) && ai.b_has_hatch )
        m_sole = getent( "target_sole_" + n_robot_id, "targetname" );

    if ( isdefined( m_sole ) && ( isdefined( ai.b_has_hatch ) && ai.b_has_hatch ) )
    {
        m_sole setcandamage( 1 );
        m_sole.health = 99999;
        m_sole useanimtree( #animtree );
        m_sole unlink();
    }

    wait 10;

    if ( isdefined( m_sole ) )
    {
        if ( cointoss() )
            ai.hatch_foot = "right";
        else
            ai.hatch_foot = "right";

/#
        if ( isdefined( level.devgui_force_giant_robot_foot ) && ( isdefined( ai.b_has_hatch ) && ai.b_has_hatch ) )
            ai.hatch_foot = level.devgui_force_giant_robot_foot;
#/

        if ( ai.hatch_foot == "left" )
        {
            n_sole_origin = ai gettagorigin( "TAG_ATTACH_HATCH_LE" );
            v_sole_angles = ai gettagangles( "TAG_ATTACH_HATCH_LE" );
            ai.hatch_foot = "left";
            str_sole_tag = "TAG_ATTACH_HATCH_LE";
            ai attach( "veh_t6_dlc_zm_robot_foot_hatch", "TAG_ATTACH_HATCH_RI" );
        }
        else if ( ai.hatch_foot == "right" )
        {
            n_sole_origin = ai gettagorigin( "TAG_ATTACH_HATCH_RI" );
            v_sole_angles = ai gettagangles( "TAG_ATTACH_HATCH_RI" );
            ai.hatch_foot = "right";
            str_sole_tag = "TAG_ATTACH_HATCH_RI";
            ai attach( "veh_t6_dlc_zm_robot_foot_hatch", "TAG_ATTACH_HATCH_LE" );
        }

        m_sole.origin = n_sole_origin;
        m_sole.angles = v_sole_angles;
        wait 0.1;
        m_sole linkto( ai, str_sole_tag, ( 0, 0, 0 ) );
        m_sole show();
        ai attach( "veh_t6_dlc_zm_robot_foot_hatch_lights", str_sole_tag );
    }

    if ( !( isdefined( ai.b_has_hatch ) && ai.b_has_hatch ) )
    {
        ai attach( "veh_t6_dlc_zm_robot_foot_hatch", "TAG_ATTACH_HATCH_RI" );
        ai attach( "veh_t6_dlc_zm_robot_foot_hatch", "TAG_ATTACH_HATCH_LE" );
    }

    wait 0.05;
    ai thread giant_robot_think( ai.trig_stomp_kill_right, ai.trig_stomp_kill_left, ai.clip_foot_right, ai.clip_foot_left, m_sole, n_robot_id );
}

start_samantha_intro_vo_new()
{

}

giant_robot_think_new( trig_stomp_kill_right, trig_stomp_kill_left, clip_foot_right, clip_foot_left, m_sole, n_robot_id )
{
    self thread robot_walk_animation( n_robot_id );
    self show();

    if ( isdefined( m_sole ) )
        self thread sole_cleanup( m_sole );

    self.is_walking = 1;
    self thread monitor_footsteps( trig_stomp_kill_right, "right" );
    self thread monitor_footsteps( trig_stomp_kill_left, "left" );
    self thread monitor_footsteps_fx( trig_stomp_kill_right, "right" );
    self thread monitor_footsteps_fx( trig_stomp_kill_left, "left" );
    self thread monitor_shadow_notetracks( "right" );
    self thread monitor_shadow_notetracks( "left" );
    self thread sndgrthreads( "left" );
    self thread sndgrthreads( "right" );

	str_tag = "TAG_ATTACH_HATCH_RI";
	n_foot = 1;

    m_sole.health = 99999;
    level.gr_foot_hatch_closed[self.giant_robot_id] = 0;
    level setclientfield( "play_foot_open_fx_robot_" + self.giant_robot_id, n_foot );
    m_sole clearanim( %ai_zombie_giant_robot_hatch_close, 1 );
    m_sole setanim( %ai_zombie_giant_robot_hatch_open_idle, 1, 0.2, 1 );

    a_players = getplayers();

    if ( n_robot_id != 3 && !( isdefined( level.giant_robot_discovered ) && level.giant_robot_discovered ) )
    {
        foreach ( player in a_players )
            player thread giant_robot_discovered_vo( self );
    }
    else if ( flag( "three_robot_round" ) && !( isdefined( level.three_robot_round_vo ) && level.three_robot_round_vo ) )
    {
        foreach ( player in a_players )
            player thread three_robot_round_vo( self );
    }

    if ( n_robot_id != 3 && !( isdefined( level.shoot_robot_vo ) && level.shoot_robot_vo ) )
    {
        foreach ( player in a_players )
            player thread shoot_at_giant_robot_vo( self );
    }

    self waittill( "giant_robot_stop" );
    self.is_walking = 0;
    self stopanimscripted();
    sp_giant_robot = getent( "ai_giant_robot_" + self.giant_robot_id, "targetname" );
    self.origin = sp_giant_robot.origin;
    level setclientfield( "play_foot_open_fx_robot_" + self.giant_robot_id, 0 );
    self ghost();
    self detachall();
    level notify( "giant_robot_walk_cycle_complete" );
}