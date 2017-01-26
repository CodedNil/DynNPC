DynNPC:RegisterNPC("Police Commissioner", {
	Model = "models/taggart/police01/male_02.mdl",
	Animation = "ArmsSide",
	Dynamic = false,
	Sounds = {
		Hi = "vo/npc/male01/hi01.wav",
		Ok = "vo/npc/male01/ok01.wav",
		Cancel = "vo/npc/male01/busy02.wav"
	},
	Jobs = {{"Enlist in the police", TEAM_POLICE}, {"Become a SWAT", TEAM_SWAT}}
})

DynNPC:RegisterNPC("Hospital Director", {
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
			Name = "Get healed $100",
			Select = function(Plr)
				if Plr:canAfford(100) then
					Plr:addMoney(-100)
					Plr:SetHealth(Plr:GetMaxHealth())
				end
			end,
			Requirement = function(Plr)
				for _, v in pairs(player.GetAll()) do
					if v:Team() == TEAM_PARAMEDIC then
						return false
					end
				end
				return Plr:canAfford(100) and Plr:Health() <= Plr:GetMaxHealth() * 0.9
			end
		}
	},
	Jobs = {{"Become a paramedic", TEAM_PARAMEDIC}}
})
