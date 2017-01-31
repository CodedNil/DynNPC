DynNPC:RegisterNPC("Junkie", {
	Model = "Thug",
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
