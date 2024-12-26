require("T6.Menus.PrivateGameLobby")
CoD.PrivateOnlineGameLobby = {}
LUI.createMenu.PrivateOnlineGameLobby = function (f1_arg0)
	local f1_local0 = CoD.PrivateGameLobby.New("PrivateOnlineGameLobby", f1_arg0)
	if CoD.isMultiplayer then
		f1_local0:setPreviousMenu("MainLobby")
	end
	local f1_local1 = UIExpression.ToUpper(nil, Engine.Localize(getMapName() .. " / " .. getGameType()))
	f1_local0:addTitle(f1_local1)
	f1_local0.panelManager.panels.buttonPane.titleText = f1_local1
	return f1_local0
end

getMapName = function()
	if Dvar.ui_mapname:get() == "zm_transit" then
		if Dvar.ui_gametype:get() == "zstandard" and Dvar.ui_zm_mapstartlocation:get() == "transit" then
			return "Bus Depot"
		else
			return Dvar.ui_zm_mapstartlocation:get()
		end
	elseif Dvar.ui_mapname:get() == "zm_transit_dr" then
		return "Diner"
	elseif Dvar.ui_mapname:get() == "zm_prison" then
		return "Mob of the Dead"
	elseif Dvar.ui_mapname:get() == "zm_buried" then
		return "Buried"
	elseif Dvar.ui_mapname:get() == "zm_tomb" then
		return "Origins"
	elseif Dvar.ui_mapname:get() == "zm_highrise" then
		return "Die Rise"
	elseif Dvar.ui_mapname:get() == "zm_nuked" then
		return "Nuketown"
	end
end

getGameType = function()
	if Dvar.ui_gametype:get() == "zclassic" then
		return "Survival"
	elseif Dvar.ui_gametype:get() == "zstandard" then
		return "Survival"
	elseif Dvar.ui_gametype:get() == "zgrief" then
		return "Grief"
	elseif Dvar.ui_gametype:get() == "zcleansed" then
		return "Turned"
	end
end