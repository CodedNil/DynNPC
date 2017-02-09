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
					NewDoors[#NewDoors + 1] = ents.GetMapCreatedEntity(x)
				end
				v.Doors = NewDoors
			end
		end
		return Tbl
	end
	return {}
end

local function RoundVector(Vec)
	return Vector(math.Round(Vec.x), math.Round(Vec.y), math.Round(Vec.z))
end

local function RoundAngle(Ang)
	return Angle(math.Round(Ang.p), math.Round(Ang.y), math.Round(Ang.r))
end

local function LoopRound(v)
	for i, x in pairs(v) do
		if type(x) == "Vector" then
			v[i] = RoundVector(x)
		elseif type(x) == "Angle" then
			v[i] = RoundAngle(x)
		elseif type(x) == "table" then
			LoopRound(x)
		end
	end
end

function GreyRP.SetData(Name, Data)
	local Tbl = table.Copy(Data)
	if Name == "property" then
		for _, v in pairs(Tbl) do
			LoopRound(v)
			local NewDoors = {}
			for _, x in pairs(v.Doors) do
				if IsValid(x) then
					NewDoors[#NewDoors + 1] = x:MapCreationID()
				end
			end
			v.Doors = NewDoors
		end
	end
	local SData = von.serialize(Tbl)
	file.Write("greyrp/" .. game.GetMap():lower() .. "/" .. Name .. ".txt", SData, "DATA")
	file.Write("greyrp/" .. game.GetMap():lower() .. "/backups/" .. Name .. os.date(",%d,%m,%Y,%H", os.time()) .. ".txt", SData, "DATA")
end

local function Load()
	for _, v in pairs(file.Find("greyrp_modules/*.lua", "LUA")) do
		include("greyrp_modules/" .. v)
	end
end

local Loaded = false
hook.Add("InitPostEntity", "GreyRPPostEntity", function()
	if not Loaded then
		Loaded = true
		Load()
	end
end)
timer.Simple(2, function()
	if not Loaded then
		Loaded = true
		Load()
	end
end)
