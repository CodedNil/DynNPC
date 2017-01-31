local Data = {}

hook.Add("SetupPlayerVisibility", "PropertiesRenderCameras", function()
	for _, v in pairs(player.GetAll()) do
		if Data[v] then
			AddOriginToPVS(Data[v])
		end
	end
end)

util.AddNetworkString("MapPositionData")
net.Receive("MapPositionData", function(Len, Plr)
	Data[Plr] = net.ReadVector()
end)
