local Scale = 1.5

LocalPropertyName = LocalPropertyName or "Default"
local LocalPropertyList = {}

net.Receive("PropertiesDevNet", function(Len, Plr)
	local Type = net.ReadString()
	if Type == "" then
		LocalPropertyList = net.ReadTable()
	else
		LocalPropertyList[Type] = net.ReadTable()
	end
end)

net.Start("PropertiesDevNet")
	net.WriteString("GetData")
net.SendToServer()

timer.Simple(1, function()
	if #table.GetKeys(LocalPropertyList) == 0 then
		net.Start("PropertiesDevNet")
			net.WriteString("GetData")
		net.SendToServer()
	end
end)

local RenderCameras = {}
hook.Add("SetupPlayerVisibility", "PropertiesRenderCameras", function()
	for _, v in pairs(RenderCameras) do
		AddOriginToPVS(v)
	end
end)

PropertyRTTextures = PropertyRTTextures or {}
local function GetRTTexture(Key)
	if not PropertyRTTextures[Key] then
		CreateMaterial("proprt_" .. Key, "UnlitGeneric", {
			["$model"] = 1,
			["$surfaceprop"] = "glass",
		})
		PropertyRTTextures[Key] = GetRenderTarget("proprt_" .. Key, 1280, 720, false)
	end
	return PropertyRTTextures[Key]
end

local CurMenuProperty
net.Receive("PropertiesMenuNet", function(Len, Plr)
	local Tbl = table.ClearKeys(LocalPropertyList, true)
	table.SortByMember(Tbl, "Price", true)
	if not CurMenuProperty then
		for _, v in pairs(Tbl) do
			if not v.IsBusiness and (string.EndsWith(v.__key, "_0") or not string.find(v.__key, "_", #v.__key - 3)) then
				CurMenuProperty = v.__key
				break
			end
		end
	end

	local Frame = vgui.Create("DFrame")
	Frame:SetSize(ScrW() * 0.7, ScrH() * 0.8)
	Frame:SetTitle("")
	Frame:Center()
	Frame:ShowCloseButton(true)
	Frame:DockPadding(0, 0, 0, 0)
	Frame:SetDraggable(false)
	Frame:MakePopup()
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame.btnClose:SetZPos(100)
	Frame.btnClose.Paint = function(self, w, h)
		draw.RoundedBoxEx(8, 0, 2, w, 16, Color(220, 80, 80), false, true, true, false)
	end
	function Frame:Paint(w, h) end

	local BottomFrame = vgui.Create("Panel", Frame)
	BottomFrame:SetHeight(ScrH() * 0.2)
	BottomFrame:Dock(BOTTOM)
	BottomFrame:DockMargin(0, 20, 0, 0)
	BottomFrame:DockPadding(15, 35, 15, 15)
	function BottomFrame:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 0, w, 20, Color(32, 178, 170, 255), false, true, false, false)
		draw.RoundedBoxEx(8, 0, 20, w, h - 20, Color(245, 245, 245, 255), false, false, true, false)
	end
	local BuyButton = vgui.Create("Button", BottomFrame)
	BuyButton:SetWide(ScrW() * 0.1)
	BuyButton:Dock(LEFT)
	BuyButton:SetFont("DYNNPC_FONT_LARGE")
	BuyButton:SetText("BUY")
	function BuyButton:DoClick()
		net.Start("PropertiesMenuNet")
			net.WriteString("Buy")
			net.WriteString(CurMenuProperty)
		net.SendToServer()
	end
	function BuyButton:Paint(w, h)
		self:SetTextColor(self.Hovered and Color(80, 80, 80, 255) or Color(255, 255, 255, 255))
		surface.SetDrawColor(self.Hovered and Color(155, 242, 236, 255) or Color(74, 211, 202, 255))
		surface.DrawRect(0, 0, w, h)
	end
	local SellButton = vgui.Create("Button", BottomFrame)
	SellButton:SetWide(ScrW() * 0.1)
	SellButton:Dock(LEFT)
	SellButton:DockMargin(15, 0, 0, 0)
	SellButton:SetFont("DYNNPC_FONT_LARGE")
	SellButton:SetText("SELL")
	function SellButton:DoClick()
		net.Start("PropertiesMenuNet")
			net.WriteString("Sell")
			net.WriteString(CurMenuProperty)
		net.SendToServer()
	end
	function SellButton:Paint(w, h)
		self:SetTextColor(self.Hovered and Color(80, 80, 80, 255) or Color(255, 255, 255, 255))
		surface.SetDrawColor(self.Hovered and Color(155, 242, 236, 255) or Color(74, 211, 202, 255))
		surface.DrawRect(0, 0, w, h)
	end

	local PictureFrame = vgui.Create("Panel", Frame)
	PictureFrame:SetWidth(ScrW() * 0.5 - 20)
	PictureFrame:Dock(RIGHT)
	PictureFrame:DockMargin(20, 0, 0, 0)
	PictureFrame:DockPadding(15, 35, 15, 15)
	function PictureFrame:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 0, w, 20, Color(32, 178, 170, 255), false, true, false, false)
		draw.RoundedBoxEx(8, 0, 20, w, h - 20, Color(245, 245, 245, 255), false, false, true, false)
	end

	local PictureBox = vgui.Create("DHorizontalScroller", PictureFrame)
	PictureBox:SetTall(ScrH() * 0.42)
	PictureBox:Dock(TOP)
	local PictureBoxI = 1
	function PictureBox:Paint(w, h)
		if #LocalPropertyList[CurMenuProperty].Cameras == 0 then
			return
		end
		if CurMenuProperty and LocalPropertyList[CurMenuProperty] then -- TODO Check if not owned or self owned
			local x, y = self:LocalToScreen()
			h = (#LocalPropertyList[CurMenuProperty].Cameras <= 1) and h * 1.429 - 70 or h - 15
			render.DrawTextureToScreenRect(GetRTTexture(CurMenuProperty .. PictureBoxI), x, y, w, h)
		end
	end

	local PictureScroll = vgui.Create("DHorizontalScroller", PictureFrame)
	PictureScroll:Dock(FILL)
	PictureScroll:SetOverlap(-15)
	function PictureScroll.btnLeft:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(200, 200, 200, 255))
	end
	function PictureScroll.btnLeft:AlignBottom()
		self:SetWide(15)
		self:DockMargin(10, 10, 10, 10)
		self:Dock(LEFT)
	end
	function PictureScroll.btnRight:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(200, 200, 200, 255))
	end
	function PictureScroll.btnRight:AlignBottom()
		self:SetWide(15)
		self:DockMargin(10, 10, 10, 10)
		self:Dock(RIGHT)
	end
	function PictureScroll:RefreshList()
		for _, v in pairs(self.Panels) do
			v:Remove()
		end
		self.Panels = {}
		if not CurMenuProperty or not LocalPropertyList[CurMenuProperty] then
			return
		end
		RenderCameras = {}
		for i, v in pairs(LocalPropertyList[CurMenuProperty].Cameras) do
			RenderCameras[#RenderCameras + 1] = v[1]
			local New = vgui.Create("DButton")
			New.LastRender = 0
			New:SetText("")
			New:NoClipping(true)
			function New:Paint(w, h)
				local x, y = self:LocalToScreen()
				local RTTex = GetRTTexture(CurMenuProperty .. i)

				if RealTime() - New.LastRender > 1 then
					local OldRT = render.GetRenderTarget()
					local OldW, OldH = ScrW(), ScrH()

					render.SetRenderTarget(RTTex)
						render.SetViewPort(x, y, w, h)
							IN_CAM = true
								WAS_IN_CAM = false
									render.RenderView({
										x = 0,
										y = 0,
										w = OldW,
										h = OldH,
										aspectratio = OldW / OldH,
										origin = v[1],
										angles = v[2],
										drawhud = false,
										drawviewmodel = false
									})
								WAS_IN_CAM = true
							IN_CAM = false
						render.SetViewPort(0, 0, OldW, OldH)
					render.SetRenderTarget(OldRT)
				 	New.LastRender = RealTime()
				end

				if #LocalPropertyList[CurMenuProperty].Cameras > 1 then
					local px, py = PictureScroll:LocalToScreen()
					local pw, ph = PictureScroll:GetSize()
					x, y = self:GetPos()
					w, h = self:GetSize()
					render.SetScissorRect(px, py, px + pw, py + ph, true)
						render.DrawTextureToScreenRect(RTTex, px + x - PictureScroll.OffsetX, py + y, w, h)
					render.SetScissorRect(0, 0, 0, 0, false)
				end
			end
			function New:ApplySchemeSettings()
				self:SetWide(self:GetTall() * 1.777)
			end
			function New:DoClick()
				PictureBoxI = i
			end
			PictureScroll:AddPanel(New)
		end
	end
	PictureScroll:RefreshList()

	local PropertySheet = vgui.Create("DPropertySheet", Frame)
	PropertySheet:SetWidth(ScrW() * 0.2)
	PropertySheet:Dock(LEFT)
	function PropertySheet:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 0, w, 20, Color(32, 178, 170, 255), false, true, false, false)
		draw.RoundedBoxEx(8, 0, 20, w, h - 20, Color(245, 245, 245, 255), false, false, true, false)
	end

	local HousesPanel = vgui.Create("Panel", PropertySheet)
	function HousesPanel:Paint(w, h) end
	local HousesScroll = vgui.Create("DScrollPanel", HousesPanel)
	HousesScroll:Dock(FILL)
	local Sheet = PropertySheet:AddSheet("Houses", HousesPanel)
	function Sheet.Tab:Paint(w, h)
		self.m_colText = self:IsActive() and Color(74, 211, 202, 255) or Color(255, 255, 255, 255)
		surface.SetDrawColor(self:IsActive() and Color(245, 245, 245, 255) or (self.Hovered and Color(108, 216, 209, 255) or Color(74, 211, 202, 255)))
		surface.DrawRect(0, 0, w, h)
	end

	local BusinessesPanel = vgui.Create("Panel", PropertySheet)
	function BusinessesPanel:Paint(w, h) end
	local BusinessesScroll = vgui.Create("DScrollPanel", BusinessesPanel)
	BusinessesScroll:Dock(FILL)
	Sheet = PropertySheet:AddSheet("Businesses", BusinessesPanel)
	function Sheet.Tab:Paint(w, h)
		self.m_colText = self:IsActive() and Color(74, 211, 202, 255) or Color(255, 255, 255, 255)
		surface.SetDrawColor(self:IsActive() and Color(245, 245, 245, 255) or (self.Hovered and Color(108, 216, 209, 255) or Color(74, 211, 202, 255)))
		surface.DrawRect(0, 0, w, h)
	end

	for _, v in pairs(Tbl) do
		local Start = string.find(v.__key, "_", #v.__key - 3)
		if not string.EndsWith(v.__key, "_0") and Start then
			continue
		end
		local New = vgui.Create("DButton", v.IsBusiness and BusinessesScroll or HousesScroll)
		New:Dock(TOP)
		New:DockMargin(0, 6 * Scale, 0, 0)
		New:SetTall(30 * Scale)
		New:SetFont("DYNNPC_FONT_MEDIUM")
		New:SetTextColor(Color(255, 255, 255, 255))
		local NewTitle = (Start and v.__key:sub(1, Start - 1) or v.__key):gsub(" ", "")
		NewTitle = NewTitle:gsub("[A-Z]", " %1"):Trim()
		surface.SetFont("DYNNPC_FONT_MEDIUM")
		local sws = surface.GetTextSize(" ")
		New:SetText(NewTitle .. ":" .. string.rep(" ", (50 * sws - surface.GetTextSize(NewTitle)) / sws) .. "Price: $" .. v.Price)
		function New:Paint(w, h)
			self:SetTextColor(CurMenuProperty == v.__key and Color(80, 80, 80, 255) or Color(255, 255, 255, 255))
			surface.SetDrawColor(CurMenuProperty == v.__key and Color(155, 242, 236, 255) or Color(74, 211, 202, 255))
			surface.DrawRect(0, 0, w, h)
		end
		function New:DoClick()
			CurMenuProperty = v.__key
			PictureScroll:RefreshList()
			PictureBoxI = 1
		end
	end
end)

local function VerifyLocalPropertyList()
	LocalPropertyList[LocalPropertyName] = LocalPropertyList[LocalPropertyName] or {Price = 100, IsBusiness = false, Doors = {}, Cameras = {}}
end

local Menu
local function OpenMenu()
	if Menu and IsValid(Menu) then
		Menu:Remove()
	end
	local Tbl = {"Name", "Price", "IsBusiness", "AddDoor", "ClearDoors", "AddCamera", "ClearCameras", "Remove"}

	Menu = vgui.Create("DFrame")
	Menu:SetSize(200 * Scale, 100)
	Menu:SetTitle("PropertyDev")
	Menu:ShowCloseButton(true)
	Menu:SetDraggable(true)
	Menu:MakePopup()
	Menu.lblTitle:SetFont("DYNNPC_FONT_LARGE")
	function Menu:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 0, w, 24, Color(32, 178, 170, 255), false, true, false, false)
		draw.RoundedBoxEx(8, 0, 24, w, h - 24, Color(245, 245, 245, 255), false, false, true, false)
	end

	local Buttons = {}

	for i, v in pairs(Tbl) do
		local New = vgui.Create((v == "Name" or v == "Price") and "DTextEntry" or v == "IsBusiness" and "DCheckBoxLabel" or "DButton", Menu)
		New:Dock(TOP)
		New:DockMargin(6 * Scale, 6 * Scale, 6 * Scale, i == #Tbl and 6 * Scale or 0)
		New:SetTall(30 * Scale)
		New:SetFont("DYNNPC_FONT_MEDIUM")
		New:SetTextColor(Color(80, 80, 80, 255))
		New:SetText(v == "Name" and LocalPropertyName or v)
		function New:ResetValue()
			if v == "Price" then
				self:SetText(LocalPropertyList[LocalPropertyName] and LocalPropertyList[LocalPropertyName].Price or 100)
			elseif v == "IsBusiness" then
				self:SetValue(LocalPropertyList[LocalPropertyName] and LocalPropertyList[LocalPropertyName].IsBusiness or false)
			end
		end
		New:ResetValue()
		Buttons[#Buttons + 1] = New

		if v == "Name" or v == "Price"  then
			function New:OnEnter()
				if v == "Name" then
					if self:GetText() ~= "" then
						LocalPropertyName = self:GetText()
					else
						self:SetText(LocalPropertyName)
					end
					for _, x in pairs(Buttons) do
						x:ResetValue()
					end
				else
					local CaretPos = self:GetCaretPos()
					self:SetText(Format("%i", math.min(math.max(tonumber(self:GetText()) or 0, 1), 1000000)))
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
		elseif v == "IsBusiness" then
			function New:OnChange(Value)
				VerifyLocalPropertyList()
				LocalPropertyList[LocalPropertyName].IsBusiness = Value
				net.Start("PropertiesDevNet")
					net.WriteString(v)
					net.WriteString(LocalPropertyName)
					net.WriteBool(Value)
				net.SendToServer()
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
					if IsValid(Ent) and Ent:isDoor() and not table.HasValue(LocalPropertyList[LocalPropertyName].Doors, Ent) then
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
	Menu:InvalidateLayout(true)
	Menu:SizeToChildren(false, true)
	Menu:SetTall(Menu:GetTall() + 10)
	Menu:CenterVertical()
	Menu:CenterHorizontal(0.9)
end

concommand.Add("propertydevmode", function()
	OpenMenu()
end)

hook.Add("HUDPaint", "PropertyInfoHud", function()
	if IsValid(Menu) then
		local Houses = {}
		local Businesses = {}
		for i, v in pairs(LocalPropertyList) do
			if v.IsBusiness then
				Businesses[#Businesses + 1] = i
			else
				Houses[#Houses + 1] = i
			end
		end
		table.SortByMember(Houses, 1, true)
		table.SortByMember(Businesses, 1, true)

		local MaxX = 0
		surface.SetFont("DermaDefault")
		local n = 0
		for _, v in pairs(Houses) do
			n = n + 1
			MaxX = math.max(surface.GetTextSize(v), MaxX)
		end
		draw.RoundedBox(0, ScrW() - 30 - MaxX, 25, MaxX + 20, n * 20 + 5, Color(0, 0, 0, 255))
		n = 0
		for _, v in pairs(Houses) do
			n = n + 1
			draw.DrawText(v, "DermaDefault", ScrW() - 20, 10 + n * 20, Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT)
		end

		MaxX = 0
		surface.SetFont("DermaDefault")
		n = 0
		for _, v in pairs(Businesses) do
			n = n + 1
			MaxX = math.max(surface.GetTextSize(v), MaxX)
		end
		draw.RoundedBox(0, ScrW() - 230 - MaxX, 25, MaxX + 20, n * 20 + 5, Color(0, 0, 0, 255))
		n = 0
		for _, v in pairs(Businesses) do
			n = n + 1
			draw.DrawText(v, "DermaDefault", ScrW() - 220, 10 + n * 20, Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT)
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
		if #Doors > 0 or #Cameras > 0 then
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
