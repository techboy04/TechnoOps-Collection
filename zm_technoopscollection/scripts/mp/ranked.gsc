#include common_scripts\utility;
#include maps\mp\_utility;

main()
{
	if ( GetDvarInt( "scr_disablePlutoniumFixes" ) )
	{
		return;
	}

	if ( isDedicated() )
	{
		// never forfeit
		replaceFunc( GetFunction( "maps/mp/gametypes/_globallogic", "checkforforfeit" ), ::neverForfeit, -1 );

		// fix team change exploit
		replaceFunc( GetFunction( "maps/mp/gametypes/_globallogic_player", "spectate_player_watcher" ), ::spectate_player_watcher_fix, -1 );

		// fix menuresponse exploits
		replaceFunc( GetFunction( "maps/mp/gametypes/_globallogic", "forceend" ), ::noop, -1 );
		replaceFunc( GetFunction( "maps/mp/gametypes/_globallogic", "gamehistoryplayerquit" ), ::noop, -1 );
		replaceFunc( GetFunction( "maps/mp/gametypes/_globallogic", "killserverpc" ), ::noop, -1 );

		// use item restrictions
		if ( getdvarint( "scr_useItemRestrictions" ) )
		{
			replaceFunc( GetFunction( "maps/mp/gametypes/_class", "giveloadout" ), ::giveloadout_override, -1 );
			replaceFunc( GetFunction( "maps/mp/gametypes/_class", "getkillstreakindex" ), ::getkillstreakindex_override, -1 );
		}
	}
}

init()
{
	if ( GetDvarInt( "scr_disablePlutoniumFixes" ) )
	{
		return;
	}

	if ( isDedicated() )
	{
		// allow team changing on dedis (gts)
		level.allow_teamchange = getgametypesetting( "allowInGameTeamChange" ) + "";
		SetDvar( "ui_allow_teamchange", level.allow_teamchange );

		// readd teambalancing
		if ( level.teambased )
		{
			level thread updateTeamBalance();
		}
	}

	level thread on_player_connect();
}

on_player_connect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		player thread player_connected();
	}
}

player_connected()
{
	self endon( "disconnect" );

	if ( isDedicated() )
	{
		// fix max allocation exploit
		if ( !self istestclient() )
		{
			self thread fix_max_allocation_exploit();
		}
	}

	self thread watch_on_throw_grenade();
}

watch_on_throw_grenade()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "grenade_fire", grenade, weaponName );

		// stop grenade team change exploit
		if ( isDedicated() )
		{
			grenade thread deleteOnOwnerTeamChange( self );
		}
	}
}

fix_max_allocation_exploit()
{
	self endon( "disconnect" );

	this_class = "";

	for ( ;; )
	{
		wait 0.05;

		if ( !isDefined( self.class ) )
		{
			continue;
		}

		if ( this_class == self.class )
		{
			continue;
		}

		this_class = self.class;

		if ( !issubstr( self.class, "CLASS_CUSTOM" ) )
		{
			continue;
		}

		class_num = int( self.class[self.class.size - 1] ) - 1;

		if ( self GetLoadoutAllocation( class_num ) <= level.maxAllocation )
		{
			continue;
		}

		self.class = level.defaultclass;
		self.pers["class"] = level.defaultclass;

		if ( !isAlive( self ) )
		{
			continue;
		}

		self suicide();
	}
}

deleteOnOwnerTeamChange( owner )
{
	self endon( "death" );

	owner waittill_any( "disconnect", "joined_team", "joined_spectators" );

	self delete ();
}

updateTeamBalance()
{
	level thread [[ GetFunction( "maps/mp/teams/_teams", "updateteambalancedvar" ) ]]();

	wait .15;

	if ( level.teamBalance && isRoundBased() && level.numlives )
	{
		if ( isDefined( game["BalanceTeamsNextRound"] ) )
		{
			iPrintLnbold( &"MP_AUTOBALANCE_NEXT_ROUND" );
		}

		level waittill( "game_ended" );
		wait 1;

		if ( isDefined( game["BalanceTeamsNextRound"] ) )
		{
			level balanceTeams();
			game["BalanceTeamsNextRound"] = undefined;
		}
		else if ( needsTeamBalance() )
		{
			game["BalanceTeamsNextRound"] = true;
		}
	}
	else
	{
		level endon ( "game_ended" );

		for ( ;; )
		{
			if ( level.teamBalance > 0 )
			{
				if ( needsTeamBalance() )
				{
					iPrintLnBold( &"MP_AUTOBALANCE_SECONDS", 15 );
					wait 15.0;

					if ( needsTeamBalance() )
					{
						level balanceTeams();
					}
				}

				wait 59.0;
			}

			wait 1.0;
		}
	}
}

getBinaryTeamData()
{
	allies = 0;
	axis = 0;

	for ( i = 0; i < level.players.size; i++ )
	{
		if ( !isdefined( level.players[i].pers["team"] ) )
		{
			continue;
		}

		if ( level.players[i].pers["team"] == "allies" )
		{
			allies++;
		}
		else if ( level.players[i].pers["team"] == "axis" )
		{
			axis++;
		}
	}

	answer = spawnstruct();
	answer.allies = allies;
	answer.axis = axis;

	return answer;
}

getLeastPlayTimePlayerForTeam( team )
{
	answer = undefined;

	for ( i = 0; i < level.players.size; i++ )
	{
		if ( !isdefined( level.players[i].pers["team"] ) || !isdefined( level.players[i].pers["teamTime"] ) )
		{
			continue;
		}

		if ( level.players[i].pers["team"] != team )
		{
			continue;
		}

		if ( isDefined( answer ) && level.players[i].pers["teamTime"] < answer.pers["teamTime"] )
		{
			continue;
		}

		answer = level.players[i];
	}

	return answer;
}

needsTeamBalance()
{
	if ( level.teamBalance <= 0 )
	{
		return false;
	}

	teamdata = getBinaryTeamData();

	if ( abs( teamdata.allies - teamdata.axis ) > level.teamBalance )
	{
		return true;
	}

	return false;
}

balanceTeams()
{
	iPrintLnBold( game["strings"]["autobalance"] );

	while ( needsTeamBalance() )
	{
		teamdata = getBinaryTeamData();

		switchto = "axis";

		if ( teamdata.axis > teamdata.allies )
		{
			switchto = "allies";
		}

		switcher = getLeastPlayTimePlayerForTeam( getotherteam( switchto ) );

		if ( !isDefined( switcher ) )
		{
			break;
		}

		switcher changeTeam( switchto );
	}
}

changeTeam( team )
{
	self endon( "disconnect" );

	if ( team != self.pers["team"] )
	{
		if ( self.sessionstate == "playing" || self.sessionstate == "dead" )
		{
			self.switching_teams = true;
			self.joining_team = team;
			self.leaving_team = self.pers["team"];
			self suicide();
		}
	}

	self.pers["team"] = team;
	self.team = team;
	self.pers["class"] = undefined;
	self.class = undefined;
	self.pers["weapon"] = undefined;
	self.pers["savedmodel"] = undefined;

	self [[ GetFunction( "maps/mp/gametypes/_globallogic_ui", "updateObjectiveText" ) ]]();
	self [[ GetFunction( "maps/mp/gametypes/_spectating", "setspectatepermissions" ) ]]();

	if ( level.teamBased )
	{
		self.sessionteam = team;
	}
	else
	{
		self.sessionteam = "none";
		self.ffateam = team;
	}

	if ( !isAlive( self ) )
	{
		self.statusicon = "hud_status_dead";
	}

	self notify( "joined_team" );
	level notify( "joined_team" );
	self setclientscriptmainmenu( game["menu_class"] );
	self openmenu( game["menu_class"] );
	self notify( "end_respawn" );
}

noop()
{
}

neverForfeit()
{
	return false;
}

spectate_player_watcher_fix()
{
	self endon( "disconnect" );

	if ( !level.splitscreen && !level.hardcoremode && getdvarint( "scr_showperksonspawn" ) == 1 && game["state"] != "postgame" && !isdefined( self.perkhudelem ) )
	{
		if ( level.perksenabled == 1 )
		{
			self [[ GetFunction( "maps/mp/gametypes/_hud_util", "showperks" ) ]]();
		}

		self thread [[ GetFunction( "maps/mp/gametypes/_globallogic_ui", "hideloadoutaftertime" ) ]]( 0 );
	}

	self.watchingactiveclient = 1;
	self.waitingforplayerstext = undefined;

	while ( true )
	{
		if ( self.pers["team"] != "spectator" || level.gameended )
		{
			self [[ GetFunction( "maps/mp/gametypes/_hud_message", "clearshoutcasterwaitingmessage" ) ]]();

			if ( !level.inprematchperiod )
			{
				self freezecontrols( 0 );
			}

			self.watchingactiveclient = 0;
			break;
		}
		else
		{
			count = 0;

			for ( i = 0; i < level.players.size; i++ )
			{
				if ( level.players[i].team != "spectator" )
				{
					count++;
					break;
				}
			}

			if ( count > 0 )
			{
				if ( !self.watchingactiveclient )
				{
					self [[ GetFunction( "maps/mp/gametypes/_hud_message", "clearshoutcasterwaitingmessage" ) ]]();
					self freezecontrols( 0 );
				}

				self.watchingactiveclient = 1;
			}
			else
			{
				if ( self.watchingactiveclient )
				{
					[[ level.onspawnspectator ]]();
					self freezecontrols( 1 );
					self [[ GetFunction( "maps/mp/gametypes/_hud_message", "setshoutcasterwaitingmessage" ) ]]();
				}

				self.watchingactiveclient = 0;
			}

			wait 0.5;
		}
	}
}

restrict_attachments( weapon )
{
	tokens = strTok( weapon, "+" );

	if ( tokens.size <= 1 )
	{
		return weapon;
	}

	new_weapon = tokens[ 0 ];

	for ( i = 1; i < tokens.size; i++ )
	{
		if ( isitemrestricted( tokens[ i ] ) )
		{
			continue;
		}

		new_weapon += "+" + tokens[ i ];
	}

	return new_weapon;
}

getkillstreakindex_override( class, killstreaknum )
{
	killstreaknum++;
	killstreakstring = "killstreak" + killstreaknum;
	answer = self getloadoutitem( class, killstreakstring );

	if ( !isDefined( answer ) || answer < 0 )
	{
		return undefined;
	}

	data = level.tbl_killstreakdata[answer];

	if ( !isdefined( data ) )
	{
		return undefined;
	}

	if ( isitemrestricted( data ) )
	{
		return undefined;
	}

	return answer;
}

giveloadout_override( team, class )
{
	pixbeginevent( "giveLoadout" );
	self takeallweapons();
	primaryindex = 0;
	self.specialty = [];
	self.killstreak = [];
	primaryweapon = undefined;
	self notify( "give_map" );
	class_num_for_killstreaks = 0;
	primaryweaponoptions = 0;
	secondaryweaponoptions = 0;
	playerrenderoptions = 0;
	primarygrenadecount = 0;
	iscustomclass = 0;

	if ( issubstr( class, "CLASS_CUSTOM" ) )
	{
		pixbeginevent( "custom class" );
		class_num = int( class[class.size - 1] ) - 1;

		if ( -1 == class_num )
		{
			class_num = 9;
		}

		self.class_num = class_num;
		self [[ GetFunction( "maps/mp/gametypes/_class", "reset_specialty_slots" ) ]]( class_num );
		playerrenderoptions = self calcplayeroptions( class_num );
		class_num_for_killstreaks = class_num;
		iscustomclass = 1;
		pixendevent();
	}
	else
	{
		pixbeginevent( "default class" );
		assert( isdefined( self.pers["class"] ), "Player during spawn and loadout got no class!" );
		class_num = level.classtoclassnum[class];
		self.class_num = class_num;
		pixendevent();
	}

	knifeweaponoptions = self calcweaponoptions( class_num, 2 );

	if ( !isitemrestricted( "knife" ) )
	{
		self giveweapon( "knife_mp", 0, knifeweaponoptions );
	}

	self.specialty = self getloadoutperks( class_num );

	for ( i = 0; i < self.specialty.size; i++ )
	{
		if ( isitemrestricted( self.specialty[i] ) )
		{
			arrayremoveindex( self.specialty, i );
			i--;
		}
	}

	self [[ GetFunction( "maps/mp/gametypes/_class", "register_perks" ) ]]();
	self setactionslot( 3, "altMode" );
	self setactionslot( 4, "" );
	self [[ GetFunction( "maps/mp/gametypes/_class", "givekillstreaks" ) ]]( class_num_for_killstreaks );
	spawnweapon = "";
	initialweaponcount = 0;

	if ( isdefined( self.pers["weapon"] ) && self.pers["weapon"] != "none" && ![[ GetFunction( "maps/mp/killstreaks/_killstreaks", "iskillstreakweapon" ) ]]( self.pers["weapon"] ) )
	{
		weapon = self.pers["weapon"];
	}
	else
	{
		weapon = self getloadoutweapon( class_num, "primary" );
		weapon = [[ GetFunction( "maps/mp/gametypes/_class", "removeduplicateattachments" ) ]]( weapon );

		if ( [[ GetFunction( "maps/mp/killstreaks/_killstreaks", "iskillstreakweapon" ) ]]( weapon ) )
		{
			weapon = "weapon_null_mp";
		}

		if ( isitemrestricted( strTok( weapon, "_" )[0] ) )
		{
			weapon = "weapon_null_mp";
		}
	}

	sidearm = self getloadoutweapon( class_num, "secondary" );
	sidearm = [[ GetFunction( "maps/mp/gametypes/_class", "removeduplicateattachments" ) ]]( sidearm );

	if ( [[ GetFunction( "maps/mp/killstreaks/_killstreaks", "iskillstreakweapon" ) ]]( sidearm ) )
	{
		sidearm = "weapon_null_mp";
	}

	if ( isitemrestricted( strTok( sidearm, "_" )[0] ) )
	{
		sidearm = "weapon_null_mp";
	}

	self.primaryweaponkill = 0;
	self.secondaryweaponkill = 0;

	if ( self isbonuscardactive( 2, self.class_num ) )
	{
		self.primaryloadoutweapon = weapon;
		self.primaryloadoutaltweapon = weaponaltweaponname( weapon );
		self.secondaryloadoutweapon = sidearm;
		self.secondaryloadoutaltweapon = weaponaltweaponname( sidearm );
	}
	else
	{
		if ( self isbonuscardactive( 0, self.class_num ) )
		{
			self.primaryloadoutweapon = weapon;
		}

		if ( self isbonuscardactive( 1, self.class_num ) )
		{
			self.secondaryloadoutweapon = sidearm;
		}
	}

	if ( sidearm != "weapon_null_mp" )
	{
		secondaryweaponoptions = self calcweaponoptions( class_num, 1 );
	}

	primaryweapon = weapon;

	if ( primaryweapon != "weapon_null_mp" )
	{
		primaryweaponoptions = self calcweaponoptions( class_num, 0 );
	}

	if ( sidearm != "" && sidearm != "weapon_null_mp" && sidearm != "weapon_null" )
	{
		sidearm = restrict_attachments( sidearm );

		self giveweapon( sidearm, 0, secondaryweaponoptions );

		if ( self hasperk( "specialty_extraammo" ) )
		{
			self givemaxammo( sidearm );
		}

		spawnweapon = sidearm;
		initialweaponcount++;
	}

	primarytokens = strtok( primaryweapon, "_" );
	self.pers["primaryWeapon"] = primarytokens[0];
/#
	println( "^5GiveWeapon( " + weapon + " ) -- weapon" );
#/

	if ( primaryweapon != "" && primaryweapon != "weapon_null_mp" && primaryweapon != "weapon_null" )
	{
		primaryweapon = restrict_attachments( primaryweapon );

		self giveweapon( primaryweapon, 0, primaryweaponoptions );

		if ( self hasperk( "specialty_extraammo" ) )
		{
			self givemaxammo( primaryweapon );
		}

		spawnweapon = primaryweapon;
		initialweaponcount++;
	}

	if ( initialweaponcount < 2 )
	{
		knife = "knife_held_mp";

		if ( isitemrestricted( "knife_held" ) )
		{
			knife = "weapon_null_mp";
		}

		if ( knife != "weapon_null_mp" )
		{
			self giveweapon( knife, 0, knifeweaponoptions );
		}

		if ( initialweaponcount == 0 )
		{
			spawnweapon = knife;
		}
	}

	if ( !isdefined( self.spawnweapon ) && isdefined( self.pers["spawnWeapon"] ) )
	{
		self.spawnweapon = self.pers["spawnWeapon"];
	}

	if ( isdefined( self.spawnweapon ) && doesweaponreplacespawnweapon( self.spawnweapon, spawnweapon ) && !self.pers["changed_class"] )
	{
		spawnweapon = self.spawnweapon;
	}

	self.pers["changed_class"] = 0;
	assert( spawnweapon != "" );
	self.spawnweapon = spawnweapon;
	self.pers["spawnWeapon"] = self.spawnweapon;
	self setspawnweapon( spawnweapon );
	grenadetypeprimary = self getloadoutitemref( class_num, "primarygrenade" );

	if ( isitemrestricted( grenadetypeprimary ) )
	{
		grenadetypeprimary = "";
	}

	if ( [[ GetFunction( "maps/mp/killstreaks/_killstreaks", "iskillstreakweapon" ) ]]( grenadetypeprimary + "_mp" ) )
	{
		grenadetypeprimary = "";
	}

	grenadetypesecondary = self getloadoutitemref( class_num, "specialgrenade" );

	if ( isitemrestricted( grenadetypesecondary ) )
	{
		grenadetypesecondary = "";
	}

	if ( [[ GetFunction( "maps/mp/killstreaks/_killstreaks", "iskillstreakweapon" ) ]]( grenadetypesecondary + "_mp" ) )
	{
		grenadetypesecondary = "";
	}

	if ( grenadetypeprimary != "" && grenadetypeprimary != "weapon_null_mp" && [[ GetFunction( "maps/mp/gametypes/_class", "isequipmentallowed" ) ]]( grenadetypeprimary ) )
	{
		grenadetypeprimary += "_mp";
		primarygrenadecount = self getloadoutitem( class_num, "primarygrenadecount" );
	}

	if ( grenadetypesecondary != "" && grenadetypesecondary != "weapon_null_mp" && [[ GetFunction( "maps/mp/gametypes/_class", "isequipmentallowed" ) ]]( grenadetypesecondary ) )
	{
		grenadetypesecondary += "_mp";
		grenadesecondarycount = self getloadoutitem( class_num, "specialgrenadecount" );
	}

	if ( !( grenadetypeprimary != "" && grenadetypeprimary != "weapon_null_mp" && [[ GetFunction( "maps/mp/gametypes/_class", "isequipmentallowed" ) ]]( grenadetypeprimary ) ) )
	{
		if ( grenadetypesecondary != level.weapons["frag"] )
		{
			grenadetypeprimary = level.weapons["frag"];
		}
		else
		{
			grenadetypeprimary = level.weapons["flash"];
		}
	}

/#
	println( "^5GiveWeapon( " + grenadetypeprimary + " ) -- grenadeTypePrimary" );
#/
	self giveweapon( grenadetypeprimary );
	self setweaponammoclip( grenadetypeprimary, primarygrenadecount );
	self switchtooffhand( grenadetypeprimary );
	self.grenadetypeprimary = grenadetypeprimary;
	self.grenadetypeprimarycount = primarygrenadecount;

	if ( self.grenadetypeprimarycount > 1 )
	{
		self dualgrenadesactive();
	}

	if ( grenadetypesecondary != "" && grenadetypesecondary != "weapon_null_mp" && [[ GetFunction( "maps/mp/gametypes/_class", "isequipmentallowed" ) ]]( grenadetypesecondary ) )
	{
		self setoffhandsecondaryclass( grenadetypesecondary );
/#
		println( "^5GiveWeapon( " + grenadetypesecondary + " ) -- grenadeTypeSecondary" );
#/
		self giveweapon( grenadetypesecondary );
		self setweaponammoclip( grenadetypesecondary, grenadesecondarycount );
		self.grenadetypesecondary = grenadetypesecondary;
		self.grenadetypesecondarycount = grenadesecondarycount;
	}

	self bbclasschoice( class_num, primaryweapon, sidearm );

	if ( !sessionmodeiszombiesgame() )
	{
		for ( i = 0; i < 3; i++ )
		{
			if ( level.loadoutkillstreaksenabled && isdefined( self.killstreak[i] ) && isdefined( level.killstreakindices[self.killstreak[i]] ) )
			{
				killstreaks[i] = level.killstreakindices[self.killstreak[i]];
				continue;
			}

			killstreaks[i] = 0;
		}

		self recordloadoutperksandkillstreaks( primaryweapon, sidearm, grenadetypeprimary, grenadetypesecondary, killstreaks[0], killstreaks[1], killstreaks[2] );
	}

	self [[ GetFunction( "maps/mp/teams/_teams", "set_player_model" ) ]]( team, weapon );
	self [[ GetFunction( "maps/mp/gametypes/_class", "initstaticweaponstime" ) ]]();
	self thread [[ GetFunction( "maps/mp/gametypes/_class", "initweaponattachments" ) ]]( spawnweapon );
	self setplayerrenderoptions( playerrenderoptions );

	if ( isdefined( self.movementspeedmodifier ) )
	{
		self setmovespeedscale( self.movementspeedmodifier * self getmovespeedscale() );
	}

	if ( isdefined( level.givecustomloadout ) )
	{
		spawnweapon = self [[ level.givecustomloadout ]]();

		if ( isdefined( spawnweapon ) )
		{
			self thread [[ GetFunction( "maps/mp/gametypes/_class", "initweaponattachments" ) ]]( spawnweapon );
		}
	}

	self [[ GetFunction( "maps/mp/gametypes/_class", "cac_selector" ) ]]();

	if ( !isdefined( self.firstspawn ) )
	{
		if ( isdefined( spawnweapon ) )
		{
			self initialweaponraise( spawnweapon );
		}
		else
		{
			self initialweaponraise( weapon );
		}
	}
	else
	{
		self seteverhadweaponall( 1 );
	}

	self.firstspawn = 0;
	pixendevent();
}
