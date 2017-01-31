GreyRP = {}

timer.Simple(0.1, function()
	for _, v in pairs(file.Find("greyrp_modules/client/*.lua", "LUA")) do
		include("greyrp_modules/client/" .. v)
	end
end)
