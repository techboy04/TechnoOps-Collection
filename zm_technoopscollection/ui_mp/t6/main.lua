require("T6.CoDBase")
require("T6.BonusCardButton")
require("T6.LiveNotification")
require("T6.SwitchLobbies")
require("T6.MainMenu")
require("T6.NumbersBackground")
require("T6.Options")
require("T6.Menus.Barracks")
require("T6.Menus.ClanTag")
require("T6.Menus.ConfirmLeavePopup")
require("T6.Menus.PrivateLocalGameLobby")
require("T6.Menus.PublicGameLobby")
require("T6.Menus.PrivateOnlineGameLobby")
require("T6.Menus.SplitscreenGameLobby")
require("T6.Menus.TheaterLobby")
require("T6.PlayerMatchPartyLobby")
require("T6.GameLobby")
require("T6.matchmaking")
if CoD.isZombie == true then
	require("T6.Zombie.BaseZombie")
	require("T6.Zombie.GameGlobeZombie")
	require("T6.Zombie.GameMapZombie")
	require("T6.Zombie.GameMoonZombie")
	require("T6.Zombie.GameRockZombie")
	require("T6.Zombie.NoLeavePopupZombie")
	require("T6.Zombie.SelectDifficultyLevelPopupZombie")
	require("T6.Zombie.SelectStartLocZombie")
	require("T6.Zombie.SelectMapZombie")
else
	require("T6.Menus.CAC")
	require("T6.Menus.CACChooseClass")
	require("T6.Menus.CACCamoMenu")
	require("T6.Menus.CACEditClass")
	require("T6.Menus.CACGrenadesAndEquipment")
	require("T6.Menus.CACKnifeMenu")
	require("T6.Menus.CACPerks")
	require("T6.Menus.CACRemoveItem")
	require("T6.Menus.CACReticles")
	require("T6.Menus.CACRewardsPopup")
	require("T6.Menus.CACSelectClass")
	require("T6.Menus.CACWeapons")
	require("T6.Menus.ChangeGameModePopup")
	require("T6.Menus.ChangeMapPopup")
	require("T6.Menus.LeagueGameLobby")
	require("T6.Menus.LeaguePlayPartyLobby")
	require("T6.Menus.ConfirmPurchasePopup")
	require("T6.Menus.ConfirmPrestigeUnlock")
	require("T6.Menus.ConfirmWeaponPrestige")
	require("T6.Menus.RemoveReward")
	require("T6.CACAttachmentsButton")
	require("T6.CACGridSelectionMenu")
	require("T6.CACPerksButton")
	require("T6.CACWeaponButton")
	require("T6.ClassButton")
	require("T6.Menus.CACAttachmentsMenu")
	require("T6.Menus.CACGrenades")
	require("T6.Menus.CACUtility")
	require("T6.Menus.CheckClasses")
end
if (CoD.isWIIU or CoD.isPC) and CoD.isWIIU then
	require("T6.Drc.DrcBase")
	require("T6.Drc.DrcPopup")
	require("T6.Drc.DrcMakePrimaryPopup")
	require("T6.WiiUSystemServices")
end
local f0_local0 = function (f1_arg0, f1_arg1)
	profiler.stop()
	DebugPrint("Profiler stopped.")
end

local f0_local1 = function (f2_arg0, f2_arg1)
	if f2_arg1.key == 115 then
		if f2_arg0.safeAreaOverlay.toggled then
			f2_arg0.safeAreaOverlay.toggled = false
			f2_arg0.safeAreaOverlay:close()
		else
			f2_arg0.safeAreaOverlay.toggled = true
			f2_arg0:addElement(f2_arg0.safeAreaOverlay)
		end
	elseif f2_arg1.key == 116 then
		f2_arg0:addElement(LUI.UITimer.new(1000, "profiler_stop", true))
		DebugPrint("Profiler started.")
		profiler.start("test.prof")
	end
	f2_arg0:dispatchEventToChildren(f2_arg1)
end

local f0_local2 = function (f3_arg0, f3_arg1)
	local f3_local0 = 500
	if CoD.isZombie == true then
		f3_local0 = 1
	end
	Engine.PlaySound("cac_globe_draw")
	f3_arg0:beginAnimation("wireframe_in", f3_local0)
	f3_arg0:setShaderVector(0, 1, 0, 0, 0)
end

local f0_local3 = function (f4_arg0, f4_arg1)
	local f4_local0 = 1000
	if CoD.isZombie == true then
		f4_local0 = 1
	end
	f4_arg0:beginAnimation("map_in", f4_local0)
	f4_arg0:setShaderVector(0, 2, 2, 0, 0)
end

function ShowGlobe()
	if not CoD.globe then
		return 
	elseif not CoD.globe.shown then
		CoD.globe.shown = true
		CoD.globe:beginAnimation("globe_ready", 1)
	end
end

function HideGlobe()
	if not CoD.globe then
		return 
	elseif CoD.globe.shown then
		CoD.globe.shown = nil
		if CoD.isZombie == true then
			CoD.GameGlobeZombie.MoveToOrigin()
		else
			CoD.globe:setShaderVector(0, 0, 0, 0, 0)
		end
	end
end

CoD.InviteAccepted = function (f7_arg0, f7_arg1)
	Engine.Exec(f7_arg1.controller, "setclientbeingusedandprimary")
	Engine.ExecNow(f7_arg1.controller, "initiatedemonwareconnect")
	local f7_local0 = f7_arg0:openPopup("popup_connectingdw", f7_arg1.controller)
	f7_local0.inviteAccepted = true
	f7_local0.callingMenu = f7_arg0
end

local f0_local4 = function (f8_arg0, f8_arg1, f8_arg2, f8_arg3)
	local f8_local0 = f8_arg1 .. "_preload"
	f8_arg0[f8_local0] = LUI.UITimer.new(250, f8_local0, false)
	f8_arg0:addElement(f8_arg0[f8_local0])
	f8_arg0:registerEventHandler(f8_local0, function (f11_arg0, f11_arg1)
		local f11_local0 = f8_arg1 .. "_preload"
		local f11_local1 = f8_arg2 .. "_preload"
		if f11_arg0[f11_local1] == nil then
			f11_arg0[f11_local1] = LUI.UIStreamedImage.new()
			f11_arg0[f11_local1]:setAlpha(0)
			f11_arg0:addElement(f11_arg0[f11_local1])
			f11_arg0[f11_local1]:registerEventHandler("streamed_image_ready", function (Sender, Event)
				if f8_arg3 ~= nil then
					f8_arg3(Sender, Event)
				end
				f8_arg0[f8_local0]:close()
			end)
			f11_arg0[f11_local0] = LUI.UIStreamedImage.new()
			f11_arg0[f11_local0]:setAlpha(0)
			f11_arg0:addElement(f11_arg0[f11_local0])
		end
		f11_arg0[f11_local1]:setImage(RegisterMaterial(f8_arg2))
		f11_arg0[f11_local1]:setupUIStreamedImage(0)
		f11_arg0[f11_local0]:setImage(RegisterMaterial(f8_arg1))
		f11_arg0[f11_local0]:setupUIStreamedImage(0)
	end)
	f8_arg0:processEvent({
		name = f8_local0
	})
end

CoD.InitArchiveDvars = function()
	if UIExpression.DvarString(nil, "enable_custom_subtitles") == "" then
		Engine.Exec(nil, "seta enable_custom_subtitles 1")
	end
	if UIExpression.DvarString(nil, "enable_permaperks") == "" then
		Engine.Exec(nil, "seta enable_permaperks 0")
	end
	if UIExpression.DvarString(nil, "enable_rampage") == "" then
		Engine.Exec(nil, "seta enable_rampage 1")
	end
	if UIExpression.DvarString(nil, "rampage_max_round") == "" then
		Engine.Exec(nil, "seta rampage_max_round 20")
	end
	if UIExpression.DvarString(nil, "enable_compass") == "" then
		Engine.Exec(nil, "seta enable_compass 1")
	end
	if UIExpression.DvarString(nil, "enable_direction") == "" then
		Engine.Exec(nil, "seta enable_direction 1")
	end
	if UIExpression.DvarString(nil, "enable_zone") == "" then
		Engine.Exec(nil, "seta enable_zone 1")
	end
	if UIExpression.DvarString(nil, "enable_angle") == "" then
		Engine.Exec(nil, "seta enable_angle 1")
	end
	if UIExpression.DvarString(nil, "enable_notifier") == "" then
		Engine.Exec(nil, "seta enable_notifier 1")
	end
	if UIExpression.DvarString(nil, "enable_bonuspoints") == "" then
		Engine.Exec(nil, "seta enable_bonuspoints 1")
	end
	if UIExpression.DvarString(nil, "bonuspoints_points") == "" then
		Engine.Exec(nil, "seta bonuspoints_points 100")
	end
	if UIExpression.DvarString(nil, "enable_usefulnuke") == "" then
		Engine.Exec(nil, "seta enable_usefulnuke 1")
	end
	if UIExpression.DvarString(nil, "usefulnuke_points") == "" then
		Engine.Exec(nil, "seta usefulnuke_points 60")
	end
	if UIExpression.DvarString(nil, "enable_bo4ammo") == "" then
		Engine.Exec(nil, "seta enable_bo4ammo 1")
	end
	if UIExpression.DvarString(nil, "enable_transitpower") == "" then
		Engine.Exec(nil, "seta enable_transitpower 1")
	end
	if UIExpression.DvarString(nil, "enable_transitmisc") == "" then
		Engine.Exec(nil, "seta enable_transitmisc 1")
	end
	if UIExpression.DvarString(nil, "tranzit_place_dinerhatch") == "" then
		Engine.Exec(nil, "seta tranzit_place_dinerhatch 1")
	end
	if UIExpression.DvarString(nil, "tranzit_tedd_tracker") == "" then
		Engine.Exec(nil, "seta tranzit_tedd_tracker 1")
	end
	if UIExpression.DvarString(nil, "enable_lavadamage") == "" then
		Engine.Exec(nil, "seta enable_lavadamage 1")
	end
	if UIExpression.DvarString(nil, "solo_tombstone") == "" then
		Engine.Exec(nil, "seta solo_tombstone 1")
	end
	if UIExpression.DvarString(nil, "enable_earlyspawn") == "" then
		Engine.Exec(nil, "seta enable_earlyspawn 1")
	end
	if UIExpression.DvarString(nil, "enable_weaponanimation") == "" then
		Engine.Exec(nil, "seta enable_weaponanimation 1")
	end
	if UIExpression.DvarString(nil, "perk_limit") == "" or UIExpression.DvarInt(nil, "perk_limit") <= 10 then
		Engine.Exec(nil, "seta perk_limit 9")
	end
	if UIExpression.DvarString(nil, "enable_fasttravel") == "" then
		Engine.Exec(nil, "seta enable_fasttravel 1")
	end
	if UIExpression.DvarString(nil, "fasttravel_price") == "" then
		Engine.Exec(nil, "seta fasttravel_price 1500")
	end
	if UIExpression.DvarString(nil, "fasttravel_activateonpower") == "" then
		Engine.Exec(nil, "seta fasttravel_activateonpower 0")
	end
	if UIExpression.DvarString(nil, "enable_healthbar") == "" then
		Engine.Exec(nil, "seta enable_healthbar 1")
	end
	if UIExpression.DvarString(nil, "health_bar_look") == "" then
		Engine.Exec(nil, "seta health_bar_look 0")
	end
	if UIExpression.DvarString(nil, "enable_zombiecount") == "" then
		Engine.Exec(nil, "seta enable_zombiecount 1")
	end
	if UIExpression.DvarString(nil, "enable_exfil") == "" then
		Engine.Exec(nil, "seta enable_exfil 1")
	end
	if UIExpression.DvarString(nil, "enable_debug") == "" then
		Engine.Exec(nil, "seta enable_debug 0")
	end
	if UIExpression.DvarString(nil, "enable_instantpap") == "" then
		Engine.Exec(nil, "seta enable_instantpap 1")
	end
	if UIExpression.DvarString(nil, "enable_vghudanim") == "" then
		Engine.Exec(nil, "seta enable_vghudanim 1")
	end
	if UIExpression.DvarString(nil, "enable_secretmusicsurvival") == "" then
		Engine.Exec(nil, "seta enable_secretmusicsurvival 1")
	end
	if UIExpression.DvarString(nil, "enable_hitmarker") == "" then
		Engine.Exec(nil, "seta enable_hitmarker 1")
	end
	if UIExpression.DvarString(nil, "enable_upgradedperks") == "" then
		Engine.Exec(nil, "seta enable_upgradedperks 1")
	end
	if UIExpression.DvarString(nil, "enable_globalatm") == "" then
		Engine.Exec(nil, "seta enable_globalatm 1")
	end
	if UIExpression.DvarString(nil, "enable_origins_mud") == "" then
		Engine.Exec(nil, "seta enable_origins_mud 0")
	end
	if UIExpression.DvarString(nil, "cinematic_mode") == "" then
		Engine.Exec(nil, "seta cinematic_mode 0")
	end
	if UIExpression.DvarString(nil, "hide_HUD") == "" then
		Engine.Exec(nil, "seta hide_HUD 0")
	end
	if UIExpression.DvarString(nil, "enable_directorscut") == "" then
		Engine.Exec(nil, "seta enable_directorscut 0")
	end
	if UIExpression.DvarString(nil, "enable_infected") == "" then
		Engine.Exec(nil, "seta enable_infected 0")
	end
	if UIExpression.DvarString(nil, "infected_start_round") == "" then
		Engine.Exec(nil, "seta infected_start_round 15")
	end
	if UIExpression.DvarString(nil, "infected_infect_chance") == "" then
		Engine.Exec(nil, "seta infected_infect_chance 60")
	end
	if UIExpression.DvarString(nil, "enable_grabbablestarter") == "" then
		Engine.Exec(nil, "seta enable_grabbablestarter 1")
	end
	if UIExpression.DvarString(nil, "infected_infect_timer") == "" then
		Engine.Exec(nil, "seta infected_infect_timer 30")
	end
	if UIExpression.DvarString(nil, "infected_infect_decrease") == "" then
		Engine.Exec(nil, "seta infected_infect_decrease 5")
	end
	if UIExpression.DvarString(nil, "infected_cure_price") == "" then
		Engine.Exec(nil, "seta infected_cure_price 1500")
	end
	if UIExpression.DvarString(nil, "enable_timenextround") == "" then
		Engine.Exec(nil, "seta enable_timenextround 1")
	end
	if UIExpression.DvarString(nil, "enable_ladderintown") == "" then
		Engine.Exec(nil, "seta enable_ladderintown 1")
	end
	if UIExpression.DvarString(nil, "enable_match_timer") == "" then
		Engine.Exec(nil, "seta enable_match_timer 1")
	end
	if UIExpression.DvarString(nil, "enable_bleedout_bar") == "" then
		Engine.Exec(nil, "seta enable_bleedout_bar 1")
	end
	if UIExpression.DvarString(nil, "enable_timebetweenround") == "" then
		Engine.Exec(nil, "seta enable_timebetweenround 1")
	end
	if UIExpression.DvarString(nil, "use_customtimebetween") == "" then
		Engine.Exec(nil, "seta use_customtimebetween 0")
	end
	if UIExpression.DvarString(nil, "timebetween_rounds") == "" then
		Engine.Exec(nil, "seta timebetween_rounds 10")
	end
	if UIExpression.DvarString(nil, "wallweapon_in_town") == "" then
		Engine.Exec(nil, "seta wallweapon_in_town 1")
	end
	if UIExpression.DvarString(nil, "enable_recapturerounds") == "" then
		Engine.Exec(nil, "seta enable_recapturerounds 0")
	end
	if UIExpression.DvarString(nil, "enable_originsfootchanges") == "" then
		Engine.Exec(nil, "seta enable_originsfootchanges 1")
	end
	if UIExpression.DvarString(nil, "enable_samanthaintro") == "" then
		Engine.Exec(nil, "seta enable_samanthaintro 0")
	end
	if UIExpression.DvarString(nil, "afterlife_doesnt_down") == "" then
		Engine.Exec(nil, "seta afterlife_doesnt_down 1")
	end
	if UIExpression.DvarString(nil, "nuketown_perks_mode") == "" then
		Engine.Exec(nil, "seta nuketown_perks_mode 2")
	end
	if UIExpression.DvarString(nil, "power_activates_buildables") == "" then
		Engine.Exec(nil, "seta power_activates_buildables 1")
	end
	if UIExpression.DvarString(nil, "do_whoosh") == "" then
		Engine.Exec(nil, "seta do_whoosh 0")
	end
	if UIExpression.DvarString(nil, "hitmarker_type") == "" then
		Engine.Exec(nil, "seta hitmarker_type 0")
	end
	if UIExpression.DvarString(nil, "hit_sound") == "" then
		Engine.Exec(nil, "seta hit_sound 0")
	end
	if UIExpression.DvarString(nil, "kill_sound") == "" then
		Engine.Exec(nil, "seta kill_sound 0")
	end
	if UIExpression.DvarString(nil, "enable_all_weapons") == "" then
		Engine.Exec(nil, "seta enable_all_weapons 1")
	end
	if UIExpression.DvarString(nil, "gamemode") == "" then
		Engine.Exec(nil, "seta gamemode 0")
	end
	if UIExpression.DvarString(nil, "gungame_ladder") == "" then
		Engine.Exec(nil, "seta gungame_ladder 1")
	end
	if UIExpression.DvarString(nil, "experimental_trial") == "" then
		Engine.Exec(nil, "seta experimental_trial 0")
	end
	if UIExpression.DvarString(nil, "experimental_aat") == "" then
		Engine.Exec(nil, "seta experimental_aat 0")
	end
	if UIExpression.DvarString(nil, "zm_bots_count") == "" then
		Engine.Exec(nil, "seta zm_bots_count 0")
	end
	if UIExpression.DvarString(nil, "stats_completed_quest_1") == "" then
		Engine.Exec(nil, "seta stats_completed_quest_1 0")
	end
	if UIExpression.DvarString(nil, "stats_completed_quest_2") == "" then
		Engine.Exec(nil, "seta stats_completed_quest_2 0")
	end
	if UIExpression.DvarString(nil, "enable_mod_vox") == "" then
		Engine.Exec(nil, "seta enable_mod_vox 1")
	end
	if UIExpression.DvarString(nil, "deadlight_rules") == "" then
		Engine.Exec(nil, "seta deadlight_rules 0")
	end
	if UIExpression.DvarString(nil, "deadlight_voice") == "" then
		Engine.Exec(nil, "seta deadlight_voice 1")
	end
	if UIExpression.DvarString(nil, "exfil_music") == "" then
		Engine.Exec(nil, "seta exfil_music 0")
	end
	if UIExpression.DvarString(nil, "sharpshooter_duration") == "" then
		Engine.Exec(nil, "seta sharpshooter_duration 45")
	end
	if UIExpression.DvarString(nil, "play_minigame_music") == "" then
		Engine.Exec(nil, "seta play_minigame_music 1")
	end
	if UIExpression.DvarString(nil, "planeparts_per_player") == "" then
		Engine.Exec(nil, "seta planeparts_per_player 1")
	end
	if UIExpression.DvarString(nil, "enable_9lives") == "" then
		Engine.Exec(nil, "seta enable_9lives 0")
	end
	if UIExpression.DvarString(nil, "continue_game_after_quest") == "" then
		Engine.Exec(nil, "seta continue_game_after_quest 1")
	end
	if UIExpression.DvarString(nil, "notify_players_actions") == "" then
		Engine.Exec(nil, "seta notify_players_actions 1")
	end
	if UIExpression.DvarString(nil, "guided_mode") == "" then
		Engine.Exec(nil, "seta guided_mode 0")
	end
	if UIExpression.DvarString(nil, "experimental_settings") == "" then
		Engine.Exec(nil, "seta experimental_settings 0")
	end
	if UIExpression.DvarString(nil, "tranzit_alpha_round_end") == "" then
		Engine.Exec(nil, "seta tranzit_alpha_round_end 1")
	end
	if UIExpression.DvarString(nil, "do_revived_sound") == "" then
		Engine.Exec(nil, "seta do_revived_sound 0")
	end
	if UIExpression.DvarString(nil, "endgame_restart_map") == "" then
		Engine.Exec(nil, "seta endgame_restart_map 0")
	end	
end

LUI.createMenu.main = function()
	CoD.InitArchiveDvars()

	local f11_local0 = UIExpression.GetMaxControllerCount()
	for self = 0, f11_local0 - 1, 1 do
		Engine.LockInput(self, true)
		Engine.SetUIActive(self, true)
	end
	LUI.roots.UIRootFull:addElement(CoD.SetupSafeAreaOverlay())
	local self = LUI.UIElement.new({
		leftAnchor = true,
		rightAnchor = true,
		left = 0,
		right = 0,
		topAnchor = true,
		bottomAnchor = true,
		top = 0,
		bottom = 0,
	})
	self.name = "Main"
	if CoD.useMouse == true then
		CoD.Mouse.RegisterMaterials()
	end
	if not CoD.isZombie then
		local f11_local2 = 1280
		local f11_local3 = 400
		local f11_local4 = LUI.UIImage.new()
		f11_local4:setLeftRight(false, false, -f11_local2, f11_local2)
		f11_local4:setTopBottom(false, false, f11_local3 - f11_local2, f11_local3 + f11_local2)
		f11_local4:setXRot(-80)
		f11_local4:setImage(RegisterMaterial("ui_holotable_grid"))
		self:addElement(f11_local4)
		local f11_local5 = LUI.UIImage.new()
		f11_local5:setLeftRight(false, false, -f11_local2, f11_local2)
		f11_local5:setTopBottom(false, false, f11_local3 - f11_local2, f11_local3 + f11_local2)
		f11_local5:setXRot(-80)
		f11_local5:setImage(RegisterMaterial("ui_holotable_grid3"))
		f11_local5:setRGB(0.5, 0.5, 0.5)
		self:addElement(f11_local5)
		local f11_local6 = -32
		local f11_local7 = LUI.UIImage.new()
		f11_local7:setLeftRight(false, false, -f11_local2, f11_local2)
		f11_local7:setTopBottom(false, false, f11_local3 - f11_local2 + f11_local6, f11_local3 + f11_local2 + f11_local6)
		f11_local7:setXRot(-80)
		f11_local7:setImage(RegisterMaterial("ui_holotable_grid2"))
		self:addElement(f11_local7)
	end
	local f11_local2 = nil
	if CoD.isZombie == true then
		f11_local2 = RegisterMaterial("lui_bkg_zm")
	else
		f11_local2 = RegisterMaterial("lui_bkg")
	end
	local f11_local3 = nil
	if CoD.isZombie == true then
		self:addElement(LUI.UIImage.new({
			leftAnchor = true,
			rightAnchor = true,
			left = 0,
			right = 0,
			topAnchor = true,
			bottomAnchor = true,
			top = 0,
			bottom = 0,
			alpha = 1,
			red = 0,
			green = 0,
			blue = 0,
		}))
		f11_local3 = LUI.UIStreamedImage.new({
			leftAnchor = true,
			rightAnchor = true,
			left = 0,
			right = 0,
			topAnchor = true,
			bottomAnchor = true,
			top = 0,
			bottom = 0,
			material = f11_local2,
		})
		f11_local3:setupUIStreamedImage(0)
		if not CoD.isPC then
			f0_local4(self, "menu_zm_nuked_map", "menu_zm_nuked_map_blur", function(f12_arg0, f12_arg1)
				CoD.GameMapZombie.BlurredImages.menu_zm_nuked_map_blur = true
			end)
			f0_local4(self, "menu_zm_highrise_map", "menu_zm_highrise_map_blur", function(f13_arg0, f13_arg1)
				CoD.GameMapZombie.BlurredImages.menu_zm_highrise_map_blur = true
			end)
			f0_local4(self, "menu_zm_prison_map", "menu_zm_prison_map_blur", function(f14_arg0, f14_arg1)
				CoD.GameMapZombie.BlurredImages.menu_zm_prison_map_blur = true
			end)
			f0_local4(self, "menu_zm_buried_map", "menu_zm_buried_map_blur", function(f15_arg0, f15_arg1)
				CoD.GameMapZombie.BlurredImages.menu_zm_buried_map_blur = true
			end)
		end
	else
		f11_local3 = LUI.UIImage.new({
			leftAnchor = true,
			rightAnchor = true,
			left = 0,
			right = 0,
			topAnchor = true,
			bottomAnchor = true,
			top = 0,
			bottom = 0,
			material = f11_local2,
		})
	end
	self:addElement(f11_local3)
	local f11_local4 = -810
	local f11_local5 = 460
	local f11_local6 = 720
	local f11_local7 = nil
	if CoD.isZombie == true then
		f11_local7 = RegisterMaterial("ui_globe_zm")
	else
		f11_local7 = RegisterMaterial("ui_globe")
	end
	local f11_local8 = LUI.UIElement.new()
	f11_local8:setLeftRight(false, false, f11_local4, f11_local4 + f11_local6)
	f11_local8:setTopBottom(false, false, f11_local5 - f11_local6, f11_local5)
	f11_local8:setImage(f11_local7)
	f11_local8:setAlpha(1)
	f11_local8:setShaderVector(0, 0, 0, 0, 0)
	f11_local8:setupGlobe()
	f11_local8:registerEventHandler("transition_complete_globe_ready", f0_local2)
	f11_local8:registerEventHandler("transition_complete_wireframe_in", f0_local3)
	CoD.globe = f11_local8
	local f11_local9, f11_local10 = nil
	if CoD.isZombie == true then
		f11_local9 = LUI.UIElement.new()
		self:addElement(f11_local9)
		f11_local10 = LUI.UIImage.new()
		self:addElement(f11_local10)
	end
	self:addElement(f11_local8)
	if CoD.isZombie == true then
		CoD.GameGlobeZombie.Init(f11_local8)
		CoD.GameMapZombie.Init(f11_local3, f11_local2)
		local f11_local11 = LUI.UIElement.new()
		self:addElement(f11_local11)
		local f11_local12 = LUI.UIElement.new()
		self:addElement(f11_local12)
		CoD.GameRockZombie.Init(f11_local12, f11_local9)
		local f11_local13 = LUI.UIImage.new()
		self:addElement(f11_local13)
		CoD.GameMoonZombie.Init(f11_local13, f11_local11, f11_local10)
		local f11_local14 = LUI.UIElement.new()
		self:addElement(f11_local14)
		CoD.Fog.Init(f11_local14)
	end
	if CoD.isMultiplayer then
		local f11_local11 = LUI.UIImage.new()
		f11_local11:setLeftRight(true, true, 0, 0)
		f11_local11:setTopBottom(true, true, 0, 0)
		f11_local11:setRGB(0, 0, 0)
		f11_local11:setAlpha(0.15)
		self:addElement(f11_local11)
	end
	self:addElement(LUI.createMenu.BlackMenu())
	self:registerEventHandler("keydown", f0_local1)
	self:registerEventHandler("profiler_stop", f0_local0)
	self:registerEventHandler("live_notification", CoD.LiveNotifications.NotifyMessage)
	Engine.PlayMenuMusic("mus_mp_frontend")
	Engine.Exec(nil, "checkforinvites")
	return self
end

LUI.createMenu.BlackMenu = function (f10_arg0)
	local f10_local0 = CoD.Menu.New("BlackMenu")
	local f10_local1 = LUI.UIImage.new()
	f10_local1:setLeftRight(false, false, -640, 640)
	f10_local1:setTopBottom(false, false, -360, 360)
	f10_local1:setRGB(0, 0, 0)
	f10_local0:addElement(f10_local1)
	f10_local0:registerEventHandler("open_menu", CoD.Lobby.OpenMenu)
	f10_local0:registerEventHandler("invite_accepted", CoD.inviteAccepted)
	return f10_local0
end

DisableGlobals()
Engine.StopEditingPresetClass()
