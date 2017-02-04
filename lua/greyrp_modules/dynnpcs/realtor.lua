DynNPC:RegisterNPC("Realtor", {
	Model = "SuitsClosedTie",
	Animation = "Standing",
	CustomNetFunc = "PropertiesMenuNet"
})

hook.Add("SetupPlayerVisibility", "PropertiesRenderCameras", function()
	for i, v in pairs(GlobalProperties) do
		if v.Cameras[1] then
			AddOriginToPVS(v.Cameras[1][1])
		end
	end
end)

local function OwnDoor(Plr, Ent)
	Ent:keysOwn(Plr)
	hook.Call("playerBoughtDoor", GAMEMODE, Plr, Ent, 0)
end

local function DisownDoor(Plr, Ent)
	Ent:keysUnOwn(Plr)
	Ent:setKeysTitle()
	hook.Call("playerKeysSold", GAMEMODE, Plr, Ent, 0)
end

util.AddNetworkString("PropertiesMenuNet")
net.Receive("PropertiesMenuNet", function(Len, Plr)
	local Type = net.ReadString()
	local PropertyName = net.ReadString()
	if not GlobalProperties[PropertyName] then
		return
	end
	if Type == "Buy" then
		for _, v in pairs(GlobalProperties[PropertyName].Doors) do
			OwnDoor(Plr, v)
		end
	elseif Type == "Sell" then
		for _, v in pairs(GlobalProperties[PropertyName].Doors) do
			DisownDoor(Plr, v)
		end
	end
end)

local function DoorToPropertyName(Door)
	for i, v in pairs(GlobalProperties) do
		for _, x in pairs(v.Doors) do
			if Door == x then
				return i
			end
		end
	end
end

hook.Add("getDoorCost", "PropertiesGetDoorCost", function(Plr, Ent)
	if DoorToPropertyName(Ent) then
		return 0
	end
end)

hook.Add("playerBuyDoor", "PropertiesBuyDoor", function(Plr, Ent, Custom)
	if DoorToPropertyName(Ent) then
		return Custom or false, "You must buy this door from a realtor!"
	end
end)

hook.Add("playerSellDoor", "PropertiesSellDoor", function(Plr, Ent, Custom)
	if DoorToPropertyName(Ent) then
		return Custom or false, "You must sell this door from a realtor!"
	end
end)

hook.Add("hideSellDoorMessage", "PropertiesHideSellMessage", function(Plr, Ent)
	if DoorIDtoPropertyName(Ent) then
		return true
	end
end)
