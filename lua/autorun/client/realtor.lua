local Scale = 1.5

LocalPropertyName = LocalPropertyName or "Default"
local LocalPropertyList = {}

net.Receive("PropertiesDevNet", function(Len, Plr)
	LocalPropertyList = net.ReadTable()
end)

net.Start("PropertiesDevNet")
	net.WriteString("GetData")
net.SendToServer()

local function VerifyLocalPropertyList()
	LocalPropertyList[LocalPropertyName] = LocalPropertyList[LocalPropertyName] or {Price = 100, Doors = {}, Cameras = {}}
end

local Menu
local function OpenMenu()
	if Menu and IsValid(Menu) then
		Menu:Remove()
	end
	local Tbl = {"Name", "Price", "AddDoor", "ClearDoors", "AddCamera", "ClearCameras", "Remove"}

	local Height = 36 * #Tbl * Scale + 40
	Menu = vgui.Create("DFrame")
	Menu:SetSize(200 * Scale, Height)
	Menu:SetTitle("PropertyDev")
	Menu:SetPos(ScrW() * 0.9 - 100 * Scale, ScrH() * 0.6 - Height / 2)
	Menu:ShowCloseButton(true)
	Menu:SetDraggable(false)
	Menu:MakePopup()
	Menu.lblTitle:SetFont("DYNNPC_FONT_LARGE")
	function Menu:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 0, w, 24, Color(32, 178, 170, 255), false, true, false, false)
		draw.RoundedBoxEx(8, 0, 24, w, h - 24, Color(245, 245, 245, 255), false, false, true, false)
	end

	for i, v in pairs(Tbl) do
		local New = vgui.Create((i == 1 or i == 2) and "DTextEntry" or "DButton", Menu)
		New:Dock(TOP)
		New:DockMargin(6 * Scale, 6 * Scale, 6 * Scale, i == #Tbl and 6 * Scale or 0)
		New:SetTall(30 * Scale)
		New:SetFont("DYNNPC_FONT_MEDIUM")
		New:SetTextColor(Color(80, 80, 80, 255))
		New:SetText(i == 1 and LocalPropertyName or i == 2 and 100 or v)

		if v == "Name" or v == "Price"  then
			function New:OnEnter()
				if v == "Name" then
					if self:GetText() ~= "" then
						LocalPropertyName = self:GetText()
					else
						self:SetText(LocalPropertyName)
					end
				else
					local CaretPos = self:GetCaretPos()
					self:SetText(Format("%i", math.min(math.max(tonumber(self:GetText()) or 0, 20), 10000)))
					self:SetCaretPos(CaretPos)
					VerifyLocalPropertyList()
					LocalPropertyList[LocalPropertyName].Price = tonumber(self:GetText())
					net.Start("PropertiesDevNet")
						net.WriteString("Price")
						net.WriteString(LocalPropertyName)
						net.WriteDouble(tonumber(self:GetText()))
					net.SendToServer()
				end
			end
		else
			function New:DoClick()
				if v == "ClearDoors" or v == "ClearCameras" or v == "Remove" then
					VerifyLocalPropertyList()
					if v == "ClearDoors" then
						LocalPropertyList[LocalPropertyName].Doors = {}
					elseif v == "ClearCameras" then
						LocalPropertyList[LocalPropertyName].Cameras = {}
					elseif v == "Remove" then
						LocalPropertyList[LocalPropertyName] = nil
					end
					net.Start("PropertiesDevNet")
						net.WriteString(v)
						net.WriteString(LocalPropertyName)
					net.SendToServer()
				elseif v == "AddDoor" then
					local Ent = LocalPlayer():GetEyeTrace().Entity
					if IsValid(Ent) and Ent:isDoor() then
						VerifyLocalPropertyList()
						table.insert(LocalPropertyList[LocalPropertyName].Doors, Ent)
						net.Start("PropertiesDevNet")
							net.WriteString(v)
							net.WriteString(LocalPropertyName)
							net.WriteEntity(Ent)
						net.SendToServer()
					end
				elseif v == "AddCamera" then
					VerifyLocalPropertyList()
					table.insert(LocalPropertyList[LocalPropertyName].Cameras, {LocalPlayer():EyePos(), LocalPlayer():EyeAngles()})
					net.Start("PropertiesDevNet")
						net.WriteString(v)
						net.WriteString(LocalPropertyName)
						net.WriteVector(LocalPlayer():EyePos())
						net.WriteAngle(LocalPlayer():EyeAngles())
					net.SendToServer()
				end
			end
		end
	end
end

hook.Add("HUDPaint", "PropertyInfoHud", function()
	if IsValid(Menu) then
		local MaxX = 0
		surface.SetFont("DermaDefault")
		local t = 0
		for i, _ in pairs(LocalPropertyList) do
			t = t + 1
			MaxX = math.max(surface.GetTextSize(i), MaxX)
		end
		draw.RoundedBox(0, ScrW() - 30 - MaxX, 25, MaxX + 20, t * 20 + 5, Color(0, 0, 0, 255))
		local n = 0
		for i, _ in pairs(LocalPropertyList) do
			n = n + 1
			draw.DrawText(i, "DermaDefault", ScrW() - 20, 10 + n * 20, Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT)
		end
	end
end)

local CameraModels = {}
local CameraKey = 1

local function GetCameraModel(i)
	if not CameraModels[i] then
		CameraModels[i] = ClientsideModel("models/dav0r/camera.mdl", RENDERGROUP_OPAQUE)
		CameraModels[i]:SetModelScale(2)
	end
	return CameraModels[i]
end

local BlankCam = {}
function BlankCam:IsValid()
	return true
end
function BlankCam:DrawModel()
	render.Model({model = "models/dav0r/camera.mdl", pos = self.Pos, angle = self.Ang}, GetCameraModel(CameraKey))
	CameraKey = CameraKey + 1
end

local BlankCamList = {}

hook.Add("HUDPaint", "PropertyInfo3dHud", function()
	if IsValid(Menu) then
		local Doors, Cameras = {}, {}
		if LocalPropertyList[LocalPropertyName] then
			for _, v in pairs(LocalPropertyList[LocalPropertyName].Doors) do
				if IsValid(v) then
					Doors[#Doors + 1] = v
				end
			end
			for i, v in pairs(LocalPropertyList[LocalPropertyName].Cameras) do
				local Key = LocalPropertyName .. i
				if not BlankCamList[Key] then
					BlankCamList[Key] = table.Copy(BlankCam)
				end
				BlankCamList[Key].Pos = v[1]
				BlankCamList[Key].Ang = v[2]
				Cameras[#Cameras + 1] = BlankCamList[Key]
			end
		end
		if #Doors > 0 then
			CameraKey = 1
			halo.Add(Doors, Color(255, 255, 255, 255), 5, 5, 3, true, true)
			halo.Add(Cameras, Color(255, 255, 255, 255), 5, 5, 3, true, true)
			local MinS, MaxS = Vector(math.huge, math.huge, math.huge), Vector(-math.huge, -math.huge, -math.huge)
			cam.Start3D()
				for _, v in pairs(Doors) do
					v:DrawModel()

					local Pos = v:GetPos()
					MinS.x = math.min(Pos.x, MinS.x)
					MinS.y = math.min(Pos.y, MinS.y)
					MinS.z = math.min(Pos.z, MinS.z)

					MaxS.x = math.max(Pos.x, MaxS.x)
					MaxS.y = math.max(Pos.y, MaxS.y)
					MaxS.z = math.max(Pos.z, MaxS.z)
				end
				for i, v in pairs(Cameras) do
					v:DrawModel()

					local Pos = v.Pos
					MinS.x = math.min(Pos.x, MinS.x)
					MinS.y = math.min(Pos.y, MinS.y)
					MinS.z = math.min(Pos.z, MinS.z)

					MaxS.x = math.max(Pos.x, MaxS.x)
					MaxS.y = math.max(Pos.y, MaxS.y)
					MaxS.z = math.max(Pos.z, MaxS.z)
				end
				local Center = (MaxS + MinS) / 2
				render.DrawWireframeBox(Center, Angle(0, 0, 0), MaxS - Center + Vector(100, 100, 100), MinS - Center - Vector(100, 100, 100), Color(255, 255, 255, 255), false)
			cam.End3D()
		end
	end
end)

concommand.Add("propertydevmode", function()
	OpenMenu()
end)
