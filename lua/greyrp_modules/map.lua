local Data = {}

hook.Add("SetupPlayerVisibility", "MapRender", function(Plr)
	if Data[Plr] then
		AddOriginToPVS(Data[Plr])
	end
end)

util.AddNetworkString("MapPositionData")
net.Receive("MapPositionData", function(Len, Plr)
	Data[Plr] = net.ReadVector()
end)
