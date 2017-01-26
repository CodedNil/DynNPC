local NPCs = {
	["Police Commissioner"] = {
		Model = "models/taggart/police01/male_02.mdl",
		Animation = "ArmsSide",
		Dynamic = false,
		Sounds = {
			Hi = "vo/npc/male01/hi01.wav",
			Ok = "vo/npc/male01/ok01.wav",
			Cancel = "vo/npc/male01/busy02.wav"
		},
		Options = {
			{
				Name = "Enlist in the police",
				Select = function(Plr)
					Plr:changeTeam(TEAM_POLICE, true, true)
				end,
				Requirement = function(Plr)
					return Plr:Team() ~= TEAM_POLICE
				end
			},
			{
				Name = "Become a SWAT",
				Select = function(Plr)
					Plr:changeTeam(TEAM_SWAT, true, true)
				end,
				Requirement = function(Plr)
					return Plr:Team() ~= TEAM_SWAT
				end
			},
			{
				Name = "Quit job",
				Select = function(Plr)
					Plr:changeTeam(TEAM_CITIZEN, true, true)
				end,
				Requirement = function(Plr)
					return Plr:Team() == TEAM_POLICE or Plr:Team() == TEAM_SWAT
				end
			}
		}
	},
	["Junkie"] = {
		Model = "models/player/group03/male_03.mdl",
		Animation = "Scared",
		Dynamic = true,
		ShouldRelocate = function(self)
			for _, Plr in pairs(player.GetAll()) do
				if Plr:isCP() and Plr:EyePos():Distance(self:EyePos()) <= 160 then
					return CurTime() - self.LastRelocate > 10, 60
				end
			end
			return CurTime() - self.LastRelocate > 240
		end,
		Sounds = {
			Hi = "vo/eli_lab/eli_greeting.wav",
			Ok = "vo/eli_lab/al_ugh.wav",
			Cancel = "vo/eli_lab/al_wasted01.wav",
			Run = "vo/npc/male01/strider_run.wav"
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
	},
	["Hospital Director"] = {
		Model = "models/taggart/police02/male_02.mdl",
		Animation = "ArmsCrossed",
		Dynamic = false,
		Sounds = {
			Hi = "vo/npc/male01/hi01.wav",
			Ok = "vo/npc/male01/ok01.wav",
			Cancel = "vo/npc/male01/busy02.wav"
		},
		Options = {
			{
				Name = "Become a paramedic",
				Select = function(Plr)
					Plr:changeTeam(TEAM_PARAMEDIC, true, true)
				end,
				Requirement = function(Plr)
					return Plr:Team() ~= TEAM_PARAMEDIC
				end
			},
			{
				Name = "Get healed",
				Select = function(Plr)
					Plr:SetHealth(Plr:GetMaxHealth())
				end,
				Requirement = function(Plr)
					for _, v in pairs(player.GetAll()) do
						if v:Team() == TEAM_PARAMEDIC then
							return false
						end
					end
					return true
				end
			}

		}
	}
}

for _, v in pairs(file.Find("dynnpcs/*.lua", "LUA")) do
	include("dynnpcs/"..v)
end

local DynNPC = {}
function DynNPC:RegisterNPC(Name, Tbl)
	NPCs[Name] = Tbl
	NPCs[Name].Options = NPCs[Name].Options or {}
	if Tbl.Jobs then
	end
end

local Animations = {
	Standing = "idle_all_01",
	Angry = "idle_all_angry",
	Scared = "idle_all_scared",
	Cower = "idle_all_cower",
	ArmsCrossed = "pose_standing_01",
	ArmsSide = "pose_standing_02",
	ThumbsUp = "pose_standing_04",
	Fist = "idle_fist"
}

local DynNPCs = {}

for _, v in pairs(ents.FindByClass("dyn_npc")) do
	v:Remove()
end

if not file.IsDir("codenil", "DATA") then
	file.CreateDir("codenil", "DATA")
end
if not file.IsDir("codenil/dynnpc/" .. game.GetMap():lower(), "DATA") then
	file.CreateDir("codenil/dynnpc/" .. game.GetMap():lower(), "DATA")
end
if not file.Exists("codenil/dynnpc/" .. game.GetMap():lower() .. "/npcpos.txt", "DATA" ) then
	file.Write("codenil/dynnpc/" .. game.GetMap():lower() .. "/npcpos.txt", "", "DATA")
end
local Data = util.JSONToTable(file.Read("codenil/dynnpc/" .. game.GetMap():lower() .. "/npcpos.txt", "DATA")) or {}

local function UpdateData()
	file.Write("codenil/dynnpc/" .. game.GetMap():lower() .. "/npcpos.txt", util.TableToJSON(Data, false), "DATA")
end
for i, v in pairs(NPCs) do
	if not Data[i] then
		Data[i] = {default = {Vector(0, 0, 0), Angle(0, 0, 0)}}
	end
end

local EntityDebounces = {}

local function AddNPC(i, PosKey, Key)
	local New = ents.Create("dyn_npc")
	New:SetModel(NPCs[i].Model)
	New.Dynamic = NPCs[i].Dynamic
	New.ShouldRelocate = NPCs[i].ShouldRelocate
	New:SetPos(PosKey[1])
	New:SetAngles(PosKey[2])
	New:SetNWAngle("OrigAngles", PosKey[2])
	New:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	New:DropToFloor()
	New:SetCollisionGroup(COLLISION_GROUP_NONE)
	New:Spawn()
	New:PhysWake()
	New:Activate()
	New:ResetSequence(New:LookupSequence(Animations[NPCs[i].Animation]) or 1)

	function New:Relocate(NewPos)
		if IsValid(self) then
			self.Hiding = false
			self:SetPos(NewPos[1])
			self:SetAngles(NewPos[2])
			self:SetNWAngle("OrigAngles", NewPos[2])
			self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			self:DropToFloor()
			self:SetCollisionGroup(COLLISION_GROUP_NONE)
			self.LastRelocate = CurTime()
		end
	end

	function New:Think()
		GAMEMODE:MouthMoveAnimation(self)
		if not self.Hiding and self.Dynamic then
			local Should, HideTime = self:ShouldRelocate()
			local NPosKey = table.Random(Data[i])
			if Should and NPosKey then
				if HideTime then
					self.Hiding = true
					self:Speak(0.7, NPCs[i].Sounds.Run)
					self:SetPos(Vector(0, 0, -99999))
					timer.Simple(HideTime, function()
						self:Relocate(NPosKey)
					end)
				else
					self:Relocate(NPosKey)
				end
			end
		end
	end

	function New:AcceptInput(InputName, Plr)
		if IsValid(Plr) and Plr:IsPlayer() and not EntityDebounces[Plr] then
			EntityDebounces[Plr] = true
			timer.Simple(1, function() EntityDebounces[Plr] = nil end)
			local Tbl = {}
			for _, v in pairs(NPCs[i].Options) do
				if v.Requirement(Plr) then
					Tbl[#Tbl + 1] = v.Name
				end
			end
			self:Speak(0.5, NPCs[i].Sounds.Hi)
			net.Start("DynNPCMenu")
				net.WriteString(i)
				net.WriteEntity(New)
				net.WriteTable(Tbl)
			net.Send(Plr)
		end
	end

	if NPCs[i].Dynamic then
		DynNPCs[i] = New
	else
		DynNPCs[i] = DynNPCs[i] or {}
		DynNPCs[i][Key] = New
	end

	return New
end

local function RemoveInvalidNPCS()
	for i, v in pairs(DynNPCs) do
		if type(v) == "table" then
			for e, x in pairs(v) do
				if not IsValid(x) then
					DynNPCs[i][x] = nil
				elseif not Data[i][e] and IsValid(x) then
					x:Remove()
					DynNPCs[i][x] = nil
				end
			end
		else
			if not IsValid(v) then
				DynNPCs[i] = nil
			elseif not Data[i] and IsValid(v) then
				v:Remove()
				DynNPCs[i] = nil
			end
		end
	end
end

local function SetNPCPos(Ent, Pos, Ang)
	Ent:SetPos(Pos)
	Ent:SetAngles(Ang)
	Ent:SetNWAngle("OrigAngles", Ang)
	Ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	Ent:DropToFloor()
	Ent:SetCollisionGroup(COLLISION_GROUP_NONE)
	Ent.LastRelocate = CurTime()
end

local function RefreshNPC(Key)
	RemoveInvalidNPCS()
	if type(DynNPCs[Key]) == "table" then
		for i, v in pairs(Data[Key]) do
			local Ent = DynNPCs[Key][i]
			local PosKey = Data[Key][i]
			print(i, Key, Ent)
			if not IsValid(Ent) then
				Ent = AddNPC(Key, v, PosKey)
			end
			if PosKey then
				SetNPCPos(Ent, PosKey[1], PosKey[2])
			end
		end
	else
		local PosKey = table.Random(Data[Key])
		if PosKey then
			SetNPCPos(DynNPCs[Key], PosKey[1], PosKey[2])
		end
	end
end

util.AddNetworkString("DynNPCMenu")
local function Load()
	for i, v in pairs(Data) do
		if not NPCs[i] then
			Data[i] = nil
			return
		end
		if NPCs[i].Dynamic then
			local Key = table.GetKeys(v)[1]
			AddNPC(i, v[Key], Key)
		else
			for e, PosKey in pairs(v) do
				AddNPC(i, PosKey, e)
			end
		end
	end

	net.Receive("DynNPCMenu", function(Len, Plr)
		local EntName = net.ReadString()
		local Ent = net.ReadEntity()
		local String = net.ReadString()
		if IsValid(Ent) then
			if String == "Cancel" then
				Ent:Speak(1.7, NPCs[EntName].Sounds.Cancel)
			else
				Ent:Speak(0.5, NPCs[EntName].Sounds.Ok)
			end
		end
		for _, v in pairs(NPCs[EntName].Options) do
			if String == v.Name then
				v.Select(Plr)
			end
		end
	end)

	local function LookupString(String)
		for i, v in pairs(NPCs) do
			if i:lower():gsub(" ", "") == String:lower():gsub(" ", "") then
				return i
			end
		end
	end

	concommand.Add("setnpcpos", function(Plr, Cmd, Args)
		if IsValid(Plr) and Plr:IsAdmin() and #Args >= 1 and #Args <= 2 and LookupString(Args[1]) then
			local Key = Args[2]
			if not Key or #Key > 0 then
				local EntName = LookupString(Args[1])
				Data[EntName][Key or "default"] = {Plr:GetPos(), Plr:GetAngles()}
				UpdateData()

				RefreshNPC(EntName)
			end
		elseif IsValid(Plr) and Plr:IsAdmin() then
			Plr:PrintMessage(HUD_PRINTCONSOLE, "Invalid args")
		end
	end)

	concommand.Add("removenpcpos", function(Plr, Cmd, Args) -- dont allow 0 positions, recreate a default one, dont allow no default either
		if IsValid(Plr) and Plr:IsAdmin() and #Args == 2 and LookupString(Args[1]) then
			local EntName = LookupString(Args[1])
			local Key = Args[2]
			if Key == "default" then
				Plr:PrintMessage(HUD_PRINTCONSOLE, "Cannot remove the default position, change its position instead")
			elseif Key and Data[EntName][Key] then
				Data[EntName][Key] = nil
				UpdateData()

				RefreshNPC(EntName)
			end
		elseif IsValid(Plr) and Plr:IsAdmin() then
			Plr:PrintMessage(HUD_PRINTCONSOLE, "Invalid args")
		end
	end)

	concommand.Add("getnpcpos", function(Plr, Cmd, Args)
		if IsValid(Plr) and Plr:IsAdmin() and #Args == 1 and LookupString(Args[1]) then
			local EntName = LookupString(Args[1])
			for i, v in pairs(Data[EntName]) do
				Plr:PrintMessage(HUD_PRINTCONSOLE, EntName .. "   Key: " .. i .. "   Pos: " .. tostring(v[1]) .. "   Ang: " .. tostring(v[2]))
			end
		elseif IsValid(Plr) and Plr:IsAdmin() then
			Plr:PrintMessage(HUD_PRINTCONSOLE, "Invalid args")
		end
	end)

	concommand.Add("refreshnpcpos", function(Plr, Cmd, Args)
		if IsValid(Plr) and Plr:IsAdmin() and #Args >= 1 and #Args <= 2 and LookupString(Args[1]) then
			local EntName = LookupString(Args[1])
			RefreshNPC(EntName)
		elseif IsValid(Plr) and Plr:IsAdmin() then
			Plr:PrintMessage(HUD_PRINTCONSOLE, "Invalid args")
		end
	end)
end


local Loaded = false
hook.Add("InitPostEntity", "DynNPCPostEntity", function()
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
