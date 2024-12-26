#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;

init()
{
    if(getDvarInt("enable_all_weapons") != 1)
	{
		return;
	}
	precacheitem( "uzi_zm" );
    precacheitem( "uzi_upgraded_zm" );
    precacheitem( "thompson_zm" );
    precacheitem( "thompson_upgraded_zm" );
    precacheitem( "ak47_zm" );
    precacheitem( "ak47_upgraded_zm" );
    precacheitem( "mp40_stalker_zm" );
    precacheitem( "mp40_stalker_upgraded_zm" );
    precacheitem( "scar_zm" );
    precacheitem( "scar_upgraded_zm" );
    precacheitem( "mg08_zm" );
    precacheitem( "mg08_upgraded_zm" );
    precacheitem( "minigun_alcatraz_zm" );
    precacheitem( "minigun_alcatraz_upgraded_zm" );
    precacheitem( "evoskorpion_zm" );
    precacheitem( "evoskorpion_upgraded_zm" );
    precacheitem( "hk416_zm" );
    precacheitem( "hk416_upgraded_zm" );
    precacheitem( "ksg_zm" );
    precacheitem( "ksg_upgraded_zm" );
    precacheitem( "pdw57_zm" );
    precacheitem( "pdw57_upgraded_zm" );
    precacheitem( "mp44_zm" );
    precacheitem( "mp44_upgraded_zm" );
    precacheitem( "ballista_zm" );
    precacheitem( "ballista_upgraded_zm" );
    precacheitem( "rnma_zm" );
    precacheitem( "rnma_upgraded_zm" );
    precacheitem( "an94_zm" );
    precacheitem( "an94_upgraded_zm" );
    precacheitem( "lsat_zm" );
    precacheitem( "lsat_upgraded_zm" );
    precacheitem( "svu_zm" );
    precacheitem( "svu_upgraded_zm" );
    precacheitem( "c96_zm" );
    precacheitem( "c96_upgraded_zm" );
    // Tranzit weapons
    precacheitem( "beretta93r_extclip_zm" );
    precacheitem( "beretta93r_extclip_upgraded_zm" );
    precacheitem( "ak74u_extclip_zm" );
    precacheitem( "ak74u_extclip_upgraded_zm" );
    precacheitem( "qcw05_zm" );
    precacheitem( "qcw05_upgraded_zm" );
    precacheitem( "sf_qcw05_upgraded_zm" );
    precacheitem( "type95_zm" );
    precacheitem( "type95_upgraded_zm" );
    precacheitem( "gl_type95_zm" );
    precacheitem( "xm8_zm" );
    precacheitem( "xm8_upgraded_zm" );
    precacheitem( "gl_xm8_zm" );
    precacheitem( "rpd_zm" );
    precacheitem( "rpd_upgraded_zm" );
    precacheitem( "python_zm" );
    precacheitem( "python_upgraded_zm" );
    precacheitem( "saritch_zm" );
    precacheitem( "saritch_upgraded_zm" );
    precacheitem( "dualoptic_saritch_upgraded_zm" );
    precacheitem( "m16_zm" );
    precacheitem( "m16_gl_upgraded_zm" );
    precacheitem( "gl_m16_upgraded_zm" );
    precacheitem( "srm1216_zm" );
    precacheitem( "srm1216_upgraded_zm" );
    precacheitem( "hamr_zm" );
    precacheitem( "hamr_upgraded_zm" );
    precacheitem( "kard_zm" );
    precacheitem( "kard_upgraded_zm" );
    precacheitem( "m32_zm" );
    precacheitem( "m32_upgraded_zm" );
    precacheitem( "barretm82_zm" );
    precacheitem( "barretm82_upgraded_zm" );
    precacheitem( "m1911_zm" );
    precacheitem( "m1911_upgraded_zm" );
    precacheitem( "m1911lh_upgraded_zm" );
}