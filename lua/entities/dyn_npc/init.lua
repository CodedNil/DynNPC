AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetSolid(SOLID_BBOX)
	self:PhysicsInit(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_NONE)
	self:DrawShadow(true)
	self:SetUseType(SIMPLE_USE)
	self.LastRelocate = CurTime()
	self.Hiding = false
	self.TotalSounds = 0
end

function ENT:PhysgunPickup(Plr)
	return false
end

function ENT:CanTool(Plr)
	return false
end

function ENT:IsSpeaking()
	return self.TotalSounds > 0
end

function ENT:VoiceVolume()
	return 0.1 + (1 + math.sin(CurTime() * 20)/2) * 0.3
end

function ENT:Speak(Time, SoundName)
	self:EmitSound(SoundName)
	self.TotalSounds = self.TotalSounds + 1
	timer.Simple(Time, function() if IsValid(self) then self.TotalSounds = self.TotalSounds - 1 end end)
end