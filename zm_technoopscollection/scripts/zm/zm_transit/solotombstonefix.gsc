#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_sidequests;
#include maps\mp\zm_transit_utility;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\gametypes_zm\_globallogic_score;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_zonemgr;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_powerups;
#include maps\mp\zombies\_zm_buildables;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_utility;

main()
{
	replacefunc(maps\mp\zm_transit_utility::solo_tombstone_removal, ::solo_tombstone_removal_new);
	replacefunc(maps\mp\zm_transit_sq::richtofen_sidequest_a, ::richtofen_sidequest_a_new);
	replacefunc(maps\mp\zm_transit_buildables::init_buildables, ::init_buildables_new);
	replacefunc(maps\mp\zm_transit_buildables::include_buildables, ::include_buildables_new);
    level thread onPlayerConnect();
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
	level endon("game_ended");
    for(;;)
    {
        self waittill("spawned_player");
    }
}

solo_tombstone_removal_new()
{
	return;
}

richtofen_sidequest_a_new()
{
    level endon( "power_off" );
    level.sq_progress["rich"]["A_jetgun_built"] = 0;
    level.sq_progress["rich"]["A_jetgun_tower"] = 0;
    level.sq_progress["rich"]["A_complete"] = 0;
    ric_fail_out = undefined;
    ric_fail_heat = undefined;

    if ( !( isdefined( level.buildables_built["jetgun_zm"] ) && level.buildables_built["jetgun_zm"] ) )
        wait_for_buildable( "jetgun_zm" );

    level.sq_progress["rich"]["A_jetgun_built"] = 1;

    while ( true )
    {
        level.sq_volume waittill( "trigger", who );

        if ( isplayer( who ) && isalive( who ) && who getcurrentweapon() == "jetgun_zm" && ( !isdefined( who.jetgun_heatval ) || who.jetgun_heatval < 1 ) )
        {
            who thread left_sq_area_watcher( level.sq_volume );
            self.checking_jetgun_fire = 0;
            break;
        }
        else if ( isplayer( who ) && isalive( who ) && who getcurrentweapon() == "jetgun_zm" && ( isdefined( who.jetgun_heatval ) && who.jetgun_heatval > 1 ) )
        {
            if ( !isdefined( ric_fail_heat ) )
            {
                ric_fail_heat = 1;
                level thread richtofensay( "vox_zmba_sidequest_jet_low_0", undefined, 0, 10 );
            }
        }
    }

    level thread richtofensay( "vox_zmba_sidequest_jet_empty_0", undefined, 0, 16 );
    player = get_players();
    player[0] setclientfield( "screecher_sq_lights", 1 );
    update_sidequest_stats( "sq_transit_rich_stage_2" );
    level thread richtofen_sidequest_complete_check( "A_complete" );
    level.sq_progress["rich"]["A_jetgun_tower"] = 1;
}

include_buildables_new()
{
    battery = generate_zombie_buildable_piece( "pap", "p6_zm_buildable_battery", 32, 64, 0, "zm_hud_icon_battery", ::onpickup_common, ::ondrop_common, undefined, "tag_part_03", undefined, 1 );
    riotshield_dolly = generate_zombie_buildable_piece( "riotshield_zm", "t6_wpn_zmb_shield_dolly", 32, 64, 0, "zm_hud_icon_dolly", ::onpickup_common, ::ondrop_common, undefined, "TAG_RIOT_SHIELD_DOLLY", undefined, 2 );
    riotshield_door = generate_zombie_buildable_piece( "riotshield_zm", "t6_wpn_zmb_shield_door", 48, 15, 25, "zm_hud_icon_cardoor", ::onpickup_common, ::ondrop_common, undefined, "TAG_RIOT_SHIELD_DOOR", undefined, 3 );
    riotshield = spawnstruct();
    riotshield.name = "riotshield_zm";
    riotshield add_buildable_piece( riotshield_dolly );
    riotshield add_buildable_piece( riotshield_door );
    riotshield.onbuyweapon = ::onbuyweapon_riotshield;
    riotshield.triggerthink = ::riotshieldbuildable;
    include_buildable( riotshield );
    maps\mp\zombies\_zm_buildables::hide_buildable_table_model( "riotshield_zm_buildable_trigger" );
    powerswitch_arm = generate_zombie_buildable_piece( "powerswitch", "p6_zm_buildable_pswitch_hand", 32, 64, 10, "zm_hud_icon_arm", ::onpickup_common, ::ondrop_common, undefined, undefined, undefined, 4 );
    powerswitch_lever = generate_zombie_buildable_piece( "powerswitch", "p6_zm_buildable_pswitch_body", 48, 64, 0, "zm_hud_icon_panel", ::onpickup_common, ::ondrop_common, undefined, undefined, undefined, 5 );
    powerswitch_box = generate_zombie_buildable_piece( "powerswitch", "p6_zm_buildable_pswitch_lever", 32, 15, 0, "zm_hud_icon_lever", ::onpickup_common, ::ondrop_common, undefined, undefined, undefined, 6 );
    powerswitch = spawnstruct();
    powerswitch.name = "powerswitch";
    powerswitch add_buildable_piece( powerswitch_arm );
    powerswitch add_buildable_piece( powerswitch_lever );
    powerswitch add_buildable_piece( powerswitch_box );
    powerswitch.onuseplantobject = ::onuseplantobject_powerswitch;
    powerswitch.triggerthink = ::powerswitchbuildable;
    include_buildable( powerswitch );
    packapunch_machine = generate_zombie_buildable_piece( "pap", "p6_zm_buildable_pap_body", 48, 64, 0, "zm_hud_icon_papbody", ::onpickup_common, ::ondrop_common, undefined, "tag_part_02", undefined, 7 );
    packapunch_legs = generate_zombie_buildable_piece( "pap", "p6_zm_buildable_pap_table", 48, 15, 0, "zm_hud_icon_chairleg", ::onpickup_common, ::ondrop_common, undefined, "tag_part_01", undefined, 8 );
    packapunch = spawnstruct();
    packapunch.name = "pap";
    packapunch add_buildable_piece( battery, "tag_part_03", 0 );
    packapunch add_buildable_piece( packapunch_machine );
    packapunch add_buildable_piece( packapunch_legs );
    packapunch.triggerthink = ::papbuildable;
    include_buildable( packapunch );
    maps\mp\zombies\_zm_buildables::hide_buildable_table_model( "pap_buildable_trigger" );
    turbine_fan = generate_zombie_buildable_piece( "turbine", "p6_zm_buildable_turbine_fan", 32, 64, 0, "zm_hud_icon_fan", ::onpickup_common, ::ondrop_common, undefined, "tag_part_03", undefined, 9 );
    turbine_panel = generate_zombie_buildable_piece( "turbine", "p6_zm_buildable_turbine_rudder", 32, 64, 0, "zm_hud_icon_rudder", ::onpickup_common, ::ondrop_common, undefined, "tag_part_04", undefined, 10 );
    turbine_body = generate_zombie_buildable_piece( "turbine", "p6_zm_buildable_turbine_mannequin", 32, 15, 0, "zm_hud_icon_mannequin", ::onpickup_common, ::ondrop_common, undefined, "tag_part_01", undefined, 11 );
    turbine = spawnstruct();
    turbine.name = "turbine";
    turbine add_buildable_piece( turbine_fan );
    turbine add_buildable_piece( turbine_panel );
    turbine add_buildable_piece( turbine_body );
    turbine.onuseplantobject = ::onuseplantobject_turbine;
    turbine.triggerthink = ::turbinebuildable;
    include_buildable( turbine );
    maps\mp\zombies\_zm_buildables::hide_buildable_table_model( "turbine_buildable_trigger" );
    turret_barrel = generate_zombie_buildable_piece( "turret", "t6_wpn_lmg_rpd_world", 32, 64, 10, "zm_hud_icon_turrethead", ::onpickup_common, ::ondrop_common, undefined, "tag_aim", undefined, 12 );
    turret_body = generate_zombie_buildable_piece( "turret", "p6_zm_buildable_turret_mower", 48, 64, 0, "zm_hud_icon_lawnmower", ::onpickup_common, ::ondrop_common, undefined, "tag_part_01", undefined, 13 );
    turret_ammo = generate_zombie_buildable_piece( "turret", "p6_zm_buildable_turret_ammo", 32, 15, 0, "zm_hud_icon_ammobox", ::onpickup_common, ::ondrop_common, undefined, "tag_part_02", undefined, 14 );
    turret = spawnstruct();
    turret.name = "turret";
    turret add_buildable_piece( turret_barrel );
    turret add_buildable_piece( turret_body );
    turret add_buildable_piece( turret_ammo );
    turret.triggerthink = ::turretbuildable;
    include_buildable( turret );
    maps\mp\zombies\_zm_buildables::hide_buildable_table_model( "turret_buildable_trigger" );
    electric_trap_spool = generate_zombie_buildable_piece( "electric_trap", "p6_zm_buildable_etrap_base", 32, 64, 0, "zm_hud_icon_coil", ::onpickup_common, ::ondrop_common, undefined, "tag_part_02", undefined, 15 );
    electric_trap_coil = generate_zombie_buildable_piece( "electric_trap", "p6_zm_buildable_etrap_tvtube", 32, 64, 10, "zm_hud_icon_tvtube", ::onpickup_common, ::ondrop_common, undefined, "tag_part_01", undefined, 16 );
    electric_trap = spawnstruct();
    electric_trap.name = "electric_trap";
    electric_trap add_buildable_piece( electric_trap_spool );
    electric_trap add_buildable_piece( electric_trap_coil );
    electric_trap add_buildable_piece( battery, "tag_part_03", 0 );
    electric_trap.triggerthink = ::electrictrapbuildable;
    include_buildable( electric_trap );
    maps\mp\zombies\_zm_buildables::hide_buildable_table_model( "electric_trap_buildable_trigger" );
    jetgun_wires = generate_zombie_buildable_piece( "jetgun_zm", "p6_zm_buildable_jetgun_wires", 32, 64, 0, "zm_hud_icon_jetgun_wires", ::onpickup_common, ::ondrop_common, undefined, "TAG_WIRES", undefined, 17 );
    jetgun_engine = generate_zombie_buildable_piece( "jetgun_zm", "p6_zm_buildable_jetgun_engine", 48, 64, 0, "zm_hud_icon_jetgun_engine", ::onpickup_common, ::ondrop_common, undefined, "TAG_ENGINE", undefined, 18 );
    jetgun_gauges = generate_zombie_buildable_piece( "jetgun_zm", "p6_zm_buildable_jetgun_guages", 32, 15, 0, "zm_hud_icon_jetgun_gauges", ::onpickup_common, ::ondrop_common, undefined, "TAG_DIALS", undefined, 19 );
    jetgun_handle = generate_zombie_buildable_piece( "jetgun_zm", "p6_zm_buildable_jetgun_handles", 32, 15, 0, "zm_hud_icon_jetgun_handles", ::onpickup_common, ::ondrop_common, undefined, "TAG_HANDLES", undefined, 20 );
    jetgun = spawnstruct();
    jetgun.name = "jetgun_zm";
    jetgun add_buildable_piece( jetgun_wires );
    jetgun add_buildable_piece( jetgun_engine );
    jetgun add_buildable_piece( jetgun_gauges );
    jetgun add_buildable_piece( jetgun_handle );
    jetgun.onbuyweapon = ::onbuyweapon_jetgun;
    jetgun.triggerthink = ::jetgunbuildable;
    include_buildable( jetgun );
    maps\mp\zombies\_zm_buildables::hide_buildable_table_model( "jetgun_zm_buildable_trigger" );
    cattlecatcher_plow = generate_zombie_buildable_piece( "cattlecatcher", "veh_t6_civ_bus_zombie_cow_catcher", 72, 100, 20, "zm_hud_icon_plow", ::onpickup_common, ::ondrop_common, undefined, undefined, undefined, 21 );
    bushatch_hatch = generate_zombie_buildable_piece( "bushatch", "veh_t6_civ_bus_zombie_roof_hatch", 32, 64, 5, "zm_hud_icon_hatch", ::onpickup_common, ::ondrop_common, undefined, undefined, undefined, 22 );
    busladder_ladder = generate_zombie_buildable_piece( "busladder", "com_stepladder_large_closed", 32, 64, 0, "zm_hud_icon_ladder", ::onpickup_common, ::ondrop_common, undefined, undefined, undefined, 23 );
    cattlecatcher = spawnstruct();
    cattlecatcher.name = "cattlecatcher";
    cattlecatcher add_buildable_piece( cattlecatcher_plow );
    cattlecatcher.triggerthink = ::cattlecatcherbuildable;
    include_buildable( cattlecatcher );
    bushatch = spawnstruct();
    bushatch.name = "bushatch";
    bushatch add_buildable_piece( bushatch_hatch );
    bushatch.triggerthink = ::bushatchbuildable;
    include_buildable( bushatch );
    dinerhatch = spawnstruct();
    dinerhatch.name = "dinerhatch";
    dinerhatch add_buildable_piece( bushatch_hatch );
    dinerhatch.triggerthink = ::dinerhatchbuildable;
    include_buildable( dinerhatch );
    busladder = spawnstruct();
    busladder.name = "busladder";
    busladder add_buildable_piece( busladder_ladder );
    busladder.triggerthink = ::busladderbuildable;
    include_buildable( busladder );

    if ( !isdefined( level.gamedifficulty ) || level.gamedifficulty != 0 )
    {
        sq_common_electricbox = generate_zombie_buildable_piece( "sq_common", "p6_zm_buildable_sq_electric_box", 32, 64, 0, "zm_hud_icon_sq_powerbox", ::onpickup_common, ::ondrop_common, undefined, "tag_part_02", undefined, 24 );
        sq_common_meteor = generate_zombie_buildable_piece( "sq_common", "p6_zm_buildable_sq_meteor", 76, 64, 0, "zm_hud_icon_sq_meteor", ::onpickup_common, ::ondrop_common, undefined, "tag_part_04", undefined, 25 );
        sq_common_scaffolding = generate_zombie_buildable_piece( "sq_common", "p6_zm_buildable_sq_scaffolding", 64, 96, 0, "zm_hud_icon_sq_scafold", ::onpickup_common, ::ondrop_common, undefined, "tag_part_01", undefined, 26 );
        sq_common_transceiver = generate_zombie_buildable_piece( "sq_common", "p6_zm_buildable_sq_transceiver", 64, 96, 0, "zm_hud_icon_sq_tranceiver", ::onpickup_common, ::ondrop_common, undefined, "tag_part_03", undefined, 27 );
        sqcommon = spawnstruct();
        sqcommon.name = "sq_common";
        sqcommon add_buildable_piece( sq_common_electricbox );
        sqcommon add_buildable_piece( sq_common_meteor );
        sqcommon add_buildable_piece( sq_common_scaffolding );
        sqcommon add_buildable_piece( sq_common_transceiver );
        sqcommon.triggerthink = ::sqcommonbuildable;
        include_buildable( sqcommon );
        maps\mp\zombies\_zm_buildables::hide_buildable_table_model( "sq_common_buildable_trigger" );
    }
}

init_buildables_new()
{
    level.buildable_piece_count = 29;
    add_zombie_buildable( "riotshield_zm", &"ZOMBIE_BUILD_RIOT", &"ZOMBIE_BUILDING_RIOT", &"ZOMBIE_BOUGHT_RIOT" );
    add_zombie_buildable( "jetgun_zm", &"ZOMBIE_BUILD_JETGUN", &"ZOMBIE_BUILDING_JETGUN", &"ZOMBIE_BOUGHT_JETGUN" );
    add_zombie_buildable( "turret", &"ZOMBIE_BUILD_TURRET", &"ZOMBIE_BUILDING_TURRET", &"ZOMBIE_BOUGHT_TURRET" );
    add_zombie_buildable( "electric_trap", &"ZOMBIE_BUILD_ELECTRIC_TRAP", &"ZOMBIE_BUILDING_ELECTRIC_TRAP", &"ZOMBIE_BOUGHT_ELECTRIC_TRAP" );
    add_zombie_buildable( "cattlecatcher", &"ZOMBIE_BUILD_CATTLE_CATCHER", &"ZOMBIE_BUILDING_CATTLE_CATCHER" );
    add_zombie_buildable( "bushatch", &"ZOMBIE_BUILD_BUSHATCH", &"ZOMBIE_BUILDING_BUSHATCH" );
    add_zombie_buildable( "dinerhatch", &"ZOMBIE_BUILD_DINERHATCH", &"ZOMBIE_BUILDING_DINERHATCH" );
    add_zombie_buildable( "busladder", &"ZOMBIE_BUILD_BUSLADDER", &"ZOMBIE_BUILDING_BUSLADDER" );
    add_zombie_buildable( "powerswitch", &"ZOMBIE_BUILD_POWER_SWITCH", &"ZOMBIE_BUILDING_POWER_SWITCH" );
    add_zombie_buildable( "pap", &"ZOMBIE_BUILD_PAP", &"ZOMBIE_BUILDING_PAP" );
    add_zombie_buildable( "turbine", &"ZOMBIE_BUILD_TURBINE", &"ZOMBIE_BUILDING_TURBINE", &"ZOMBIE_BOUGHT_TURBINE" );
    add_zombie_buildable( "sq_common", &"ZOMBIE_BUILD_SQ_COMMON", &"ZOMBIE_BUILDING_SQ_COMMON" );
}