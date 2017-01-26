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
