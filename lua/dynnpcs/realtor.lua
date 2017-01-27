DynNPC:RegisterNPC("Realtor", {
	Model = "models/player/Suits/male_07_closed_tie.mdl",
	Animation = "Standing",
	Dynamic = false,
	Sounds = {
		Hi = "vo/npc/male01/hi01.wav",
		Ok = "vo/npc/male01/ok01.wav",
		Cancel = "vo/npc/male01/busy02.wav"
	},
	Options = {
		{
			Name = "Sell me stuff",
			Select = function(Plr)
			end,
			Requirement = function(Plr)
				return true
			end
		}
	}
})

if not file.IsDir("codenil", "DATA") then
	file.CreateDir("codenil", "DATA")
end
if not file.IsDir("codenil/dynnpc/" .. game.GetMap():lower(), "DATA") then
	file.CreateDir("codenil/dynnpc/" .. game.GetMap():lower(), "DATA")
end
if not file.Exists("codenil/dynnpc/" .. game.GetMap():lower() .. "/properties.txt", "DATA" ) then
	file.Write("codenil/dynnpc/" .. game.GetMap():lower() .. "/properties.txt", "", "DATA")
end
local Data = util.JSONToTable(file.Read("codenil/dynnpc/" .. game.GetMap():lower() .. "/properties.txt", "DATA")) or {}

local function UpdateData()
	file.Write("codenil/dynnpc/" .. game.GetMap():lower() .. "/properties.txt", util.TableToJSON(Data, false), "DATA")
end

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
			net.WriteTable(Tbl)
		net.Broadcast()
		return
	end
	local PropertyName = net.ReadString()
	Data[PropertyName] = Data[PropertyName] or {Price = 100, Doors = {}, Cameras = {}}
	if Type == "Price" then
		Data[PropertyName].Price = net.ReadDouble()
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
	UpdateData()
end)
