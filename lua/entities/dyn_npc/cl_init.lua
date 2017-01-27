include("shared.lua")

function ENT:Initialize()
	self.AutomaticFrameAdvance = true
	self.Rotation = 90
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	if LocalPlayer():EyePos():Distance(self:EyePos()) <= 1000 then
		local OrigAngles = self:GetNWAngle("OrigAngles")
		local FoundPlayer = false
		for _, Plr in pairs(player.GetAll()) do
			local Pos = WorldToLocal(self:EyePos(), OrigAngles, Plr:EyePos(), OrigAngles)
			if Plr:EyePos():Distance(self:EyePos()) <= 160 and Pos.x < -20 then
				self.Rotation = math.Approach(self.Rotation, (Plr:GetPos() - self:GetPos()):Angle().y, 1)
				FoundPlayer = true
				break
			end
		end
		if not FoundPlayer then
			self.Rotation = math.Approach(self.Rotation, OrigAngles.y, 1)
		end
		self:SetAngles(Angle(0, (self.Rotation - OrigAngles.y) * 0.4 + OrigAngles.y, 0))
		self:ManipulateBoneAngles(self:LookupBone("ValveBiped.Bip01_Spine"), Angle(0, 0, (self.Rotation - OrigAngles.y) * 0.3))
		self:ManipulateBoneAngles(self:LookupBone("ValveBiped.Bip01_Head1"), Angle(0, 0, (self.Rotation - OrigAngles.y) * 0.3))
	end
end
