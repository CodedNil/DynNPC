if not file.IsDir("greyrp", "DATA") then
	file.CreateDir("greyrp", "DATA")
end
if not file.IsDir("greyrp/" .. game.GetMap():lower(), "DATA") then
	file.CreateDir("greyrp/" .. game.GetMap():lower(), "DATA")
end
if not file.IsDir("greyrp/" .. game.GetMap():lower() .. "/backups", "DATA") then
	file.CreateDir("greyrp/" .. game.GetMap():lower() .. "/backups", "DATA")
end

GreyRP = {}

function GreyRP.ConvertFromOld(Name)
	if file.Exists("codenil/dynnpc/" .. game.GetMap():lower() .. "/" .. Name .. ".txt", "DATA") then
		local Text = file.Read("codenil/dynnpc/" .. game.GetMap():lower() .. "/" .. Name .. ".txt", "DATA")
		file.Write("greyrp/" .. game.GetMap():lower() .. "/" .. Name .. ".txt", von.serialize(util.JSONToTable(Text)), "DATA")
		file.Delete("codenil/dynnpc/" .. game.GetMap():lower() .. "/" .. Name .. ".txt")
	end
end

function GreyRP.GetData(Name)
	--GreyRP.ConvertFromOld(Name)
	if file.Exists("greyrp/" .. game.GetMap():lower() .. "/" .. Name .. ".txt", "DATA") then
		local Text = file.Read("greyrp/" .. game.GetMap():lower() .. "/" .. Name .. ".txt", "DATA")
		local Tbl = von.deserialize(Text)
		if Name == "property" then
			for i, v in pairs(Tbl) do
				local NewDoors = {}
				for _, x in pairs(v.Doors) do
					NewDoors[#NewDoors + 1] = DarkRP.doorIndexToEnt(x)
				end
				v.Doors = NewDoors
			end
		end
		return Tbl
	end
	return {}
end

function GreyRP.SetData(Name, Data)
	local Tbl = table.Copy(Data)
	for _, v in pairs(Tbl) do
		local NewDoors = {}
		for _, x in pairs(v.Doors) do
			NewDoors[#NewDoors + 1] = x:doorIndex()
		end
		v.Doors = NewDoors
	end
	local SData = von.serialize(Tbl)
	file.Write("greyrp/" .. game.GetMap():lower() .. "/" .. Name .. ".txt", SData, "DATA")
	file.Write("greyrp/" .. game.GetMap():lower() .. "/backups/" .. Name .. os.date(",%d,%m,%Y,%H", os.time()) .. ".txt", SData, "DATA")
end

timer.Simple(0.1, function()
	for _, v in pairs(file.Find("greyrp_modules/*.lua", "LUA")) do
		include("greyrp_modules/" .. v)
	end
end)
