DynNPC:RegisterNPC("Realtor", {
	Model = "SuitsClosedTie",
	Animation = "Standing",
	Dynamic = false,
	Sounds = {
		Hi = "vo/npc/male01/hi01.wav",
		Ok = "vo/npc/male01/ok01.wav",
		Cancel = "vo/npc/male01/busy02.wav"
	},
	CustomNetFunc = "PropertiesMenuNet"
})

if not file.Exists("codenil/dynnpc/" .. game.GetMap():lower() .. "/properties.txt", "DATA" ) then
	file.Write("codenil/dynnpc/" .. game.GetMap():lower() .. "/properties.txt", "", "DATA")
end
local Data = util.JSONToTable(file.Read("codenil/dynnpc/" .. game.GetMap():lower() .. "/properties.txt", "DATA")) or {}

local BackupData
local function UpdateData()
	if BackupData then
		file.Write("codenil/dynnpc/" .. game.GetMap():lower() .. "/backups/properties" .. os.date(",%d,%m,%Y,%H", os.time()) .. ".txt", util.TableToJSON(BackupData, false), "DATA")
	end
	BackupData = Data
	file.Write("codenil/dynnpc/" .. game.GetMap():lower() .. "/properties.txt", util.TableToJSON(Data, false), "DATA")
end

hook.Add("SetupPlayerVisibility", "PropertiesRenderCameras", function()
	for _, v in pairs(Data) do
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
	if not Data[PropertyName] then
		return
	end
	if Type == "Buy" then
		for _, v in pairs(Data[PropertyName].Doors) do
			OwnDoor(Plr, DarkRP.doorIndexToEnt(v))
		end
	elseif Type == "Sell" then
		for _, v in pairs(Data[PropertyName].Doors) do
			DisownDoor(Plr, DarkRP.doorIndexToEnt(v))
		end
	end
end)

local function DoorIDtoPropertyName(DoorID)
	for i, v in pairs(Data) do
		if table.HasValue(v.Doors, DoorID) then
			return i
		end
	end
end

hook.Add("getDoorCost", "PropertiesGetDoorCost", function(Plr, Ent)
	local DoorID = Ent:doorIndex()
	if DoorIDtoPropertyName(DoorID) then
		return 0
	end
end)

hook.Add("playerBuyDoor", "PropertiesBuyDoor", function(Plr, Ent, Custom)
	local DoorID = Ent:doorIndex()
	if DoorIDtoPropertyName(DoorID) then
		return Custom or false, "You must buy this door from a realtor!"
	end
end)

hook.Add("playerSellDoor", "PropertiesSellDoor", function(Plr, Ent, Custom)
	local DoorID = Ent:doorIndex()
	if DoorIDtoPropertyName(DoorID) then
		return Custom or false, "You must sell this door from a realtor!"
	end
end)

hook.Add("hideSellDoorMessage", "PropertiesHideSellMessage", function(Plr, Ent)
	local DoorID = Ent:doorIndex()
	if DoorIDtoPropertyName(DoorID) then
		return true
	end
end)

util.AddNetworkString("PropertiesDevNet")
net.Receive("PropertiesDevNet", function(Len, Plr)
	local Type = net.ReadString()
	if Type == "GetData" then
		local Tbl = table.Copy(Data)
		for _, v in pairs(Tbl) do
			local NewDoors = {}
			for _, x in pairs(v.Doors) do
				NewDoors[#NewDoors + 1] = DarkRP.doorIndexToEnt(x)
			end
			v.Doors = NewDoors
		end
		net.Start("PropertiesDevNet")
			net.WriteString("")
			net.WriteTable(Tbl)
		net.Send(Plr)
		return
	end
	local PropertyName = net.ReadString()
	Data[PropertyName] = Data[PropertyName] or {Price = 100, IsBusiness = false, Doors = {}, Cameras = {}}
	if Type == "Price" then
		Data[PropertyName].Price = net.ReadDouble()
	elseif Type == "IsBusiness" then
		Data[PropertyName].IsBusiness = net.ReadBool()
	elseif Type == "AddDoor" then
		local Door = net.ReadEntity()
		if Door:doorIndex() then
			table.insert(Data[PropertyName].Doors, Door:doorIndex())
		end
	elseif Type == "ClearDoors" then
		Data[PropertyName].Doors = {}
	elseif Type == "AddCamera" then
		table.insert(Data[PropertyName].Cameras, {net.ReadVector(), net.ReadAngle()})
	elseif Type == "ClearCameras" then
		Data[PropertyName].Cameras = {}
	elseif Type == "Remove" then
		Data[PropertyName] = nil
	end
	for _, v in pairs(player.GetAll()) do
		if v ~= Plr then
			local Tbl = table.Copy(Data[PropertyName])
			local NewDoors = {}
			for _, x in pairs(Tbl.Doors) do
				NewDoors[#NewDoors + 1] = DarkRP.doorIndexToEnt(x)
			end
			Tbl.Doors = NewDoors
			net.Start("PropertiesDevNet")
				net.WriteString(PropertyName)
				net.WriteTable(Tbl)
			net.Send(v)
		end
	end
	UpdateData()
end)
