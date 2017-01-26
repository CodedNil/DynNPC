DynNPC:RegisterNPC("Junkie", {
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
})
