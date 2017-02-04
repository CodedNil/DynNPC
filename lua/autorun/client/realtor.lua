local RenderCameras = {}
hook.Add("SetupPlayerVisibility", "PropertiesRenderCameras", function()
	for _, v in pairs(RenderCameras) do
		AddOriginToPVS(v)
	end
end)

hook.Add("GetMapWaypoints", "PropertiesMapWaypoints", function()
	for i, v in pairs(Properties.GetAll()) do
		local AvgPos
		for _, x in pairs(v.Doors) do
			if IsValid(x) then
				AvgPos = not AvgPos and x:GetPos() or (AvgPos + x:GetPos()) / 2
			end
		end
		if AvgPos then
			GreyRP.MapWaypoints[#GreyRP.MapWaypoints + 1] = {i, AvgPos}
		end
	end
end)

PropertyRTMaterials = PropertyRTMaterials or {}
PropertyRTTextures = PropertyRTTextures or {}
local LastRenders = {}
local inhook = false
local function GetRTTexture(Key, Origin, Angles, w, h)
	if not PropertyRTTextures[Key] then
		PropertyRTTextures[Key] = GetRenderTargetEx("propertyrt_" .. Key, 2048, 2048,
		RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(0x0004, 0x0008), CREATERENDERTARGETFLAGS_UNFILTERABLE_OK, IMAGE_FORMAT_RGBA8888)
		PropertyRTMaterials[Key] = CreateMaterial("propertyrt_" .. Key, "UnlitGeneric", {
			["$ignorez"] = 1,
			["$vertexcolor"] = 1,
			["$nolod"] = 0,
			["$basetexture"] = PropertyRTTextures[Key]:GetName()
		})
	end
	if RealTime() - (LastRenders[Key] or 0) > 60 and not inhook then
		local OldRT = render.GetRenderTarget()
		render.SetRenderTarget(PropertyRTTextures[Key])
			inhook = true
				render.RenderView({
					origin = Origin,
					angles = Angles,
					x = 0,
					y = 0,
					w = ScrW(),
					h = ScrH(),
					aspectratio = 2
				})
			inhook = false
		render.SetRenderTarget(OldRT)
		LastRenders[Key] = RealTime()
	end
	return PropertyRTTextures[Key]
end

local function ValidRealtorProperty(Props, PropertyIndex)
	if not Props[PropertyIndex] then
		return false
	end
	if not Props[PropertyIndex].Cameras[1] then
		return false
	end
	if Props[PropertyIndex].Container then
		return false
	end
	if Props[PropertyIndex].Price == 0 and Props[PropertyIndex].Rent == 0 then
		return false
	end
	return true
end

local PropertyDescriptionCache = {}
local function GetPropertyDescription(PropertyIndex, w)
	local Cache = PropertyDescriptionCache[PropertyIndex]
	local CheckSum = GlobalPropertiesCheckSum[PropretyIndex]
	if Cache and Cache[2] == CheckSum then
		return Cache[1]
	end
	local Text = "This property is amazing hi this is awesome text. Forever and ever and ever and ever and ever until the end of time itself! It's ok to be jelly mcmartion it's a beautiful system worth being jelly about."
	local TextSplit = string.Explode(" ", Text)
	local TextSegments = {{}}
	local CurLen = 0
	surface.SetFont("RealtorPosterFontSmall")
	local SpaceSize = surface.GetTextSize(" ")
	for _, g in pairs(TextSplit) do
		local Size = surface.GetTextSize(g) + SpaceSize
		if CurLen + Size <= w then
			CurLen = CurLen + Size
		else
			CurLen = Size
			TextSegments[#TextSegments + 1] = {}
		end
		table.insert(TextSegments[#TextSegments], g)
	end
	PropertyDescriptionCache[PropertyIndex] = {TextSegments, CheckSum}
	return TextSegments
end

surface.CreateFont("RealtorPosterFont", {
	font = "Trebuchet",
	size = 28,
	weight = 500,
	antialias = true
})
surface.CreateFont("RealtorPosterFontSmall", {
	font = "Trebuchet",
	size = 16,
	weight = 1000,
	antialias = true
})

local function DrawPropertySheet(PropertyIndex, Prop, Pos, Ang, TextRender)
	local Origin, Angles = Prop.Cameras[1][1], Prop.Cameras[1][2]
	local Scale = 0.05 * 0.9
	local RTKey = tostring(PropertyIndex)
	if TextRender then
		GetRTTexture(RTKey, Origin, Angles)
	end
	cam.Start3D2D(Pos, Ang, Scale * 0.8)
		local x, y, w, h = -17.5 / Scale / 2, -25 / Scale / 2, 17.5 / Scale, 25 / Scale
		surface.SetDrawColor(140, 140, 140, 255)
		surface.DrawRect(x, y, w, h)

		local m = w * 0.06
		local m2 = w * 0.02
		local t = 24
		local cy = y
		x = x + m
		w = w - m * 2

		cy = cy + m
		surface.SetDrawColor(50, 100, 50, 255)
		surface.DrawRect(x, cy, w, h * 0.08)
		if TextRender then
			surface.SetFont("RealtorPosterFont")
			surface.SetTextColor(255, 255, 255, 255)
			EfficientText(Prop.Name, x + w / 2, cy + h * 0.04, true)
		end

		cy = cy + h * 0.08 + m2
		surface.SetDrawColor(140, 140, 140, 255)
		surface.SetMaterial(PropertyRTMaterials[RTKey])
		surface.DrawTexturedRect(x, cy, w, h * 0.4)

		cy = cy + h * 0.4 + m2
		surface.SetDrawColor(50, 100, 50, 255)
		surface.DrawRect(x, cy, w, h * 0.08)
		if TextRender then
			local IsContainer = false
			for _, g in pairs(Properties.GetAll()) do
				if g.Container == PropertyIndex then
					IsContainer = true
					break
				end
			end
			EfficientText(IsContainer and "Apartments" or (Prop.Price > 0 or Prop.Rent > 0) and (Prop.Business and "Business" or "House"), x + w / 2, cy + h * 0.04, true)
		end

		cy = cy + h * 0.08 + m2
		if TextRender then
			surface.SetFont("RealtorPosterFontSmall")
			surface.SetTextColor(0, 0, 0, 255)
			for _, g in pairs(GetPropertyDescription(PropertyIndex, w)) do
				EfficientText(table.concat(g, " "), x, cy)
				cy = cy + t
			end
		end

		cy = y + h * 0.92 - m
		surface.SetDrawColor(50, 100, 50, 255)
		surface.DrawRect(x, cy, w, h * 0.08)
		if TextRender then
			surface.SetFont("RealtorPosterFont")
			surface.SetTextColor(255, 255, 255, 255)
			EfficientText((Prop.Price > 0 and "Price: " .. DarkRP.formatMoney(Prop.Price) .. (Prop.Rent > 0 and "  " or "") or "") .. (Prop.Rent > 0 and "Rent: " .. DarkRP.formatMoney(Prop.Rent) or ""), x + w / 2, cy + h * 0.04, true)
		end
	cam.End3D2D()
end

hook.Add("PostDrawTranslucentRenderables", "RealtorDrawWorld", function()
	local Property = Properties.GetByName("Realtor")
	if not Property then
		return
	end
	local Props = Properties.GetAll()
	render.SetColorMaterial()
	local TravelDistance = 0
	local PropertyIndex = 1
	for _, v in pairs(Property.Nodes or {}) do
		local Render = v[1]:ToScreen().visible and EyePos():Distance(v[1]) < 2000
		local TextRender = EyePos():Distance(v[1]) < 500
		for a = 1, 5 do
			for b = 1, 4 do
				if not ValidRealtorProperty(Props, PropertyIndex) then
					TravelDistance = 0
					repeat
						TravelDistance = TravelDistance + 1
						PropertyIndex = PropertyIndex + 1
					until ValidRealtorProperty(Props, PropertyIndex) or TravelDistance == 20
					if not ValidRealtorProperty(Props, PropertyIndex) then
						continue
					end
				end
				if not Render then
					PropertyIndex = PropertyIndex + 1
					return
				end
				local Prop = Props[PropertyIndex]
				local Ang = v[2]:Angle()
				local Pos = v[1] + Ang:Right() * (a - 3) * 15 + -Ang:Up() * (b - 2.5) * 21
				Ang:RotateAroundAxis(Ang:Forward(), 90)
				Ang:RotateAroundAxis(Ang:Right(), 90)

				DrawPropertySheet(PropertyIndex, Prop, Pos, Ang, TextRender)
				PropertyIndex = PropertyIndex + 1
			end
		end
	end
end)

--[[local CurMenuProperty
net.Receive("PropertiesMenuNet", function(Len, Plr)
	local Tbl = table.ClearKeys(Properties.GetAll(), true)
	table.SortByMember(Tbl, "Price", true)
	if not CurMenuProperty then
		for _, v in pairs(Tbl) do
			if not v.IsBusiness and (string.EndsWith(v.Name, "_0") or not string.find(v.Name, "_", #v.Name - 3)) then
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
		if #GlobalProperties[CurMenuProperty].Cameras == 0 then
			return
		end
		if CurMenuProperty and GlobalProperties[CurMenuProperty] then -- TODO Check if not owned or self owned
			local x, y = self:LocalToScreen()
			h = (#GlobalProperties[CurMenuProperty].Cameras <= 1) and h * 1.429 - 70 or h - 15
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
		if not CurMenuProperty or not GlobalProperties[CurMenuProperty] then
			return
		end
		RenderCameras = {}
		for i, v in pairs(GlobalProperties[CurMenuProperty].Cameras) do
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

				if #GlobalProperties[CurMenuProperty].Cameras > 1 then
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
		local Start = string.find(v.Name, "_", #v.Name - 3)
		if not string.EndsWith(v.Name, "_0") and Start then
			continue
		end
		local New = vgui.Create("DButton", v.IsBusiness and BusinessesScroll or HousesScroll)
		New:Dock(TOP)
		New:DockMargin(0, 9, 0, 0)
		New:SetTall(45)
		New:SetFont("DYNNPC_FONT_MEDIUM")
		New:SetTextColor(Color(255, 255, 255, 255))
		local NewTitle = (Start and v.Name:sub(1, Start - 1) or v.Name):gsub(" ", "")
		NewTitle = NewTitle:gsub("[A-Z]", " %1"):Trim()
		surface.SetFont("DYNNPC_FONT_MEDIUM")
		local sws = surface.GetTextSize(" ")
		New:SetText(NewTitle .. ":" .. string.rep(" ", (50 * sws - surface.GetTextSize(NewTitle)) / sws) .. "Price: $" .. v.Price)
		function New:Paint(w, h)
			self:SetTextColor(CurMenuProperty == v.Name and Color(80, 80, 80, 255) or Color(255, 255, 255, 255))
			surface.SetDrawColor(CurMenuProperty == v.Name and Color(155, 242, 236, 255) or Color(74, 211, 202, 255))
			surface.DrawRect(0, 0, w, h)
		end
		function New:DoClick()
			CurMenuProperty = v.__key
			PictureScroll:RefreshList()
			PictureBoxI = 1
		end
	end
end)]]
