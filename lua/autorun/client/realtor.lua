hook.Add("GetMapWaypoints", "PropertiesMapWaypoints", function()
	for i, v in pairs(Properties.GetAll()) do
		if v.Container then
			continue
		end
		local IsContainer = Properties.IsContainer(i)
		local Text = IsContainer and "Apartments" or v.Warehouse and "Warehouse" or v.Business and "Business" or "House"
		if Text then
			local Icon = IsContainer and "house_link" or v.Warehouse and "lorry_flatbed" or v.Business and "building" or "house"
			local Col = IsContainer and Color(255, 140, 70) or v.Business and Color(140, 70, 30) or v.Business and Color(50, 140, 255) or Color(50, 220, 50)
			local NewStart, NewEnd = Vector(v.Start), Vector(v.End)
			OrderVectors(NewStart, NewEnd)
			GreyRP.MapWaypoints[#GreyRP.MapWaypoints + 1] = {i, NewStart, NewEnd, Icon, Col, {{v.Name, 120}, {Text, 110}}}
		end
	end
end)

PropertyRTMaterials = PropertyRTMaterials or {}
PropertyRTTextures = PropertyRTTextures or {}
local PropertyRTRendered = {}
local inhook = false
local function GetRTTexture(Key, Origin, Angles, w, h)
	if not PropertyRTTextures[Key] then
		PropertyRTTextures[Key] = GetRenderTargetEx("propertyrt_" .. Key .. SysTime(), 2048, 2048,
		RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(4, 8), CREATERENDERTARGETFLAGS_UNFILTERABLE_OK, IMAGE_FORMAT_RGB888)
		PropertyRTMaterials[Key] = CreateMaterial("propertyrt_" .. Key .. SysTime(), "UnlitGeneric", {
			["$ignorez"] = 1,
			["$vertexcolor"] = 1,
			["$vertexalpha"] = 1,
			["$nolod"] = 0,
			["$basetexture"] = PropertyRTTextures[Key]:GetName()
		})
	end
	if not PropertyRTRendered[Key] and not inhook then
		local OldRT = render.GetRenderTarget()
		render.SetRenderTarget(PropertyRTTextures[Key])
			inhook = true
				render.ClearDepth()
				render.Clear(0, 0, 0, 255)
				local PlrDraws = {}
				for _, v in pairs(player.GetAll()) do
					if not v:GetNoDraw() then
						PlrDraws[#PlrDraws + 1] = v
						v:SetNoDraw(true)
					end
				end
				render.RenderView({
					origin = Origin,
					angles = Angles,
					x = 0,
					y = 0,
					w = ScrW(),
					h = ScrH(),
					aspectratio = 2
				})
				for _, v in pairs(PlrDraws) do
					v:SetNoDraw(false)
				end
			inhook = false
		render.SetRenderTarget(OldRT)
		PropertyRTRendered[Key] = true
	end
	return PropertyRTMaterials[Key]
end

local function ValidRealtorProperty(Props, Index)
	if not Props[Index] then
		return false
	end
	if not Props[Index].Cameras[1] then
		return false
	end
	if Props[Index].Container then
		return false
	end
	if Props[Index].Price == 0 and Props[Index].Rent == 0 then
		return false
	end
	return true
end

local Descriptions = {
	Houses = {
		"This FLOORS floored property is AREA square feet. It has ROOMS rooms. It's in a REGIONPRICE and REGIONOCCUPANCY neighbourhood. It has GARAGES."
	},
	Apartments = {
		"Text"
	},
	Businesses = {
		"Text"
	}
}

local PropertyDataTypes = {"FLOORS", "AREA"}
local function GetPropertyData(Index, Key)
	local Prop = Properties.Get(Index)
	if Key == "FLOORS" then
		return math.Round(math.abs(Prop.Start.z - Prop.End.z) / 160)
	elseif Key == "AREA" then
		return string.Comma(math.Round(Properties.GetSquareFootage(Index), -2))
	end
end

PropertyDescriptionCache = {} --PropertyDescriptionCache or {}
local function GetPropertyDescription(Index, w)
	local Key = Index .. "," .. w
	local Cache = PropertyDescriptionCache[Key]
	local CheckSum = GlobalPropertiesCheckSum[Key]
	if Cache and Cache[2] == CheckSum then
		return Cache[1]
	end
	local Text = Descriptions.Houses[1]
	for _, v in pairs(PropertyDataTypes) do
		if string.find(Text, v) then
			Text = string.gsub(Text, v, GetPropertyData(Index, v))
		end
	end
	local TextSplit = string.Explode(" ", Text)
	local TextSegments = {{}}
	local CurLen = 0
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
	PropertyDescriptionCache[Index] = {TextSegments, CheckSum}
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

surface.CreateFont("RealtorFont", {
	font = "Trebuchet",
	size = 34,
	weight = 500,
	antialias = true
})
surface.CreateFont("RealtorFontSmall", {
	font = "Trebuchet",
	size = 26,
	weight = 500,
	antialias = true
})

local function DrawPropertySheet(Index, RTKey, TextRender, x, y, w, h, Light)
	local Prop = Properties.Get(Index)
	if Light then
		surface.SetDrawColor(245, 245, 245, 255)
	else
		surface.SetDrawColor(140, 140, 140, 255)
	end
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
		EfficientText(Properties.IsContainer(Index) and "Apartments" or Prop.Warehouse and "Warehouse" or Prop.Business and "Business" or "House", x + w / 2, cy + h * 0.04, true)
	end

	cy = cy + h * 0.08 + m2
	if TextRender then
		surface.SetFont("RealtorPosterFontSmall")
		surface.SetTextColor(0, 0, 0, 255)
		for _, g in pairs(GetPropertyDescription(Index, w)) do
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
end

hook.Add("PostDrawTranslucentRenderables", "RealtorDrawWorld", function()
	local Property = Properties.GetByName("Realtor")
	if not Property then
		return
	end
	local Props = Properties.GetAll()
	render.SetColorMaterial()
	local TravelDistance = 0
	local Index = 1
	for _, v in pairs(Property.Nodes or {}) do
		local Render = v[1]:ToScreen().visible and EyePos():Distance(v[1]) < 2000
		local TextRender = EyePos():Distance(v[1]) < 500
		local Ang = v[2]:Angle()
		Ang:RotateAroundAxis(Ang:Forward(), 90)
		Ang:RotateAroundAxis(Ang:Right(), 90)
		for a = 1, 5 do
			for b = 1, 4 do
				if not ValidRealtorProperty(Props, Index) then
					TravelDistance = 0
					repeat
						TravelDistance = TravelDistance + 1
						Index = Index + 1
					until ValidRealtorProperty(Props, Index) or TravelDistance == 20
					if not ValidRealtorProperty(Props, Index) then
						continue
					end
				end
				if not Render then
					Index = Index + 1
					return
				end
				local Prop = Props[Index]
				local Pos = v[1] + v[2]:Angle():Right() * (a - 3) * 15 + -v[2]:Angle():Up() * (b - 2.5) * 21

				local RTKey = tostring(Index) .. "," .. 1
				GetRTTexture(RTKey, Prop.Cameras[1][1], Prop.Cameras[1][2])
				local Scale = 0.05 * 0.9
				cam.Start3D2D(Pos, Ang, Scale * 0.8)
					local x, y, w, h = -17.5 / Scale / 2, -25 / Scale / 2, 17.5 / Scale, 25 / Scale
					if WorldToLocal(LocalPlayer():EyePos(), Ang, Pos, Ang).z > 0 then
						DrawPropertySheet(Index, RTKey, TextRender, x, y, w, h)
					else
						surface.SetDrawColor(140, 140, 140, 255)
						surface.DrawRect(x, y, w, h)
					end
				cam.End3D2D()
				Index = Index + 1
			end
		end
	end
end)

local MatBlurScreen = Material("pp/blurscreen")
local function DrawBackgroundBlur(Panel, StartTime)
	local Fraction = math.Clamp((SysTime() - StartTime) / 1, 0, 1)
	local x, y = Panel:LocalToScreen(0, 0)
	DisableClipping( true )
	surface.SetMaterial(MatBlurScreen)
	surface.SetDrawColor(255, 255, 255, 255)
	for i = 0.33, 1, 0.33 do
		MatBlurScreen:SetFloat("$blur", Fraction * 5 * i)
		MatBlurScreen:Recompute()
		if render then
			render.UpdateScreenEffectTexture()
		end
		surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
	end
	surface.SetDrawColor(80, 80, 80, 60 * Fraction)
	surface.DrawRect(x * -1, y * -1, ScrW(), ScrH())
	DisableClipping(false)
end

function ReplacementOpenMenu(self,  pControlOpener)
	if pControlOpener and pControlOpener == self.TextEntry then
		return
	end
	if #self.Choices == 0 then
		return
	end
	if IsValid(self.Menu) then
		self.Menu:Remove()
		self.Menu = nil
	end
	self.Menu = DermaMenu(false, self)
	for k, v in pairs(self.Choices) do
		self.Menu:AddOption(v, function() self:ChooseOption(v, k) end)
	end
	local x, y = self:LocalToScreen(0, self:GetTall())
	self.Menu:SetMinimumWidth(self:GetWide())
	self.Menu:SetMaxHeight(300)
	self.Menu:Open(x, y, false, self)
end

local CurMenuProperty
net.Receive("PropertiesMenuNet", function(Len, Plr)
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(ScrW() * 0.7, ScrH() * 0.8)
	Frame:SetTitle("")
	Frame:Center()
	Frame:SetDraggable(false)
	Frame:DockPadding(0, 35, 0, 0)
	Frame:MakePopup()
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame.btnClose:SetZPos(100)
	function Frame.btnClose:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 2, w, 16, Color(220, 80, 80), false, true, true, false)
	end
	function Frame:Paint(w, h)
		DrawBackgroundBlur(self, self.m_fCreateTime)
		draw.RoundedBoxEx(8, 0, 0, w, 20, Color(32, 178, 170, 255), false, true, false, false)
		draw.RoundedBox(0, 5, 20, w - 10, h - 20, Color(50, 50, 50, 200))
	end
	local Header = vgui.Create("Panel", Frame)
	Header:SetHeight(80)
	Header:Dock(TOP)
	Header:DockPadding(4, 4, 4, 4)
	function Header:Paint(w, h)
		draw.RoundedBoxEx(0, 0, 0, w, h, Color(230, 120, 50, 255))
	end
	local HeaderImage = vgui.Create("DImage", Header)
	HeaderImage:SetWide(220)
	HeaderImage:Dock(LEFT)
	HeaderImage:SetImage("ocrp/quarantine1")

	local CurrentHeader = "Rent"

	local function ReSearch() end

	local ForRent = vgui.Create("DButton", Header)
	ForRent:SetWide(150)
	ForRent:Dock(LEFT)
	ForRent:SetTextColor(Color(255, 255, 255, 255))
	ForRent:SetText("For Rent")
	ForRent:SetFont("RealtorPosterFont")
	ForRent:NoClipping(true)
	function ForRent:Paint(w, h)
		if CurrentHeader == "Rent" then
			surface.SetDrawColor(245, 245, 245, 255)
			surface.DrawRect(10, 0, w - 20, h + 4)
			self:SetTextColor(Color(80, 80, 80, 255))
		else
			self:SetTextColor(Color(255, 255, 255, 255))
		end
	end
	function ForRent:DoClick()
		CurrentHeader = "Rent"
		ReSearch()
	end
	local ForSale = vgui.Create("DButton", Header)
	ForSale:SetWide(150)
	ForSale:Dock(LEFT)
	ForSale:SetTextColor(Color(255, 255, 255, 255))
	ForSale:SetText("For Sale")
	ForSale:SetFont("RealtorPosterFont")
	ForSale:NoClipping(true)
	function ForSale:Paint(w, h)
		if CurrentHeader == "Sale" then
			surface.SetDrawColor(245, 245, 245, 255)
			surface.DrawRect(10, 0, w - 20, h + 4)
			self:SetTextColor(Color(80, 80, 80, 255))
		else
			self:SetTextColor(Color(255, 255, 255, 255))
		end
	end
	function ForSale:DoClick()
		CurrentHeader = "Sale"
		ReSearch()
	end
	local Business = vgui.Create("DButton", Header)
	Business:SetWide(150)
	Business:Dock(LEFT)
	Business:SetTextColor(Color(255, 255, 255, 255))
	Business:SetText("Businesses")
	Business:SetFont("RealtorPosterFont")
	Business:NoClipping(true)
	function Business:Paint(w, h)
		if CurrentHeader == "Business" then
			surface.SetDrawColor(245, 245, 245, 255)
			surface.DrawRect(10, 0, w - 20, h + 4)
			self:SetTextColor(Color(80, 80, 80, 255))
		else
			self:SetTextColor(Color(255, 255, 255, 255))
		end
	end
	function Business:DoClick()
		CurrentHeader = "Business"
		ReSearch()
	end
	local Warehouse = vgui.Create("DButton", Header)
	Warehouse:SetWide(150)
	Warehouse:Dock(LEFT)
	Warehouse:SetTextColor(Color(255, 255, 255, 255))
	Warehouse:SetText("Warehouses")
	Warehouse:SetFont("RealtorPosterFont")
	Warehouse:NoClipping(true)
	function Warehouse:Paint(w, h)
		if CurrentHeader == "Warehouse" then
			surface.SetDrawColor(245, 245, 245, 255)
			surface.DrawRect(10, 0, w - 20, h + 4)
			self:SetTextColor(Color(80, 80, 80, 255))
		else
			self:SetTextColor(Color(255, 255, 255, 255))
		end
	end
	function Warehouse:DoClick()
		CurrentHeader = "Warehouse"
		ReSearch()
	end
	local Owned = vgui.Create("DButton", Header)
	Owned:SetWide(150)
	Owned:Dock(LEFT)
	Owned:SetTextColor(Color(255, 255, 255, 255))
	Owned:SetText("Owned")
	Owned:SetFont("RealtorPosterFont")
	Owned:NoClipping(true)
	function Owned:Paint(w, h)
		if CurrentHeader == "Owned" then
			surface.SetDrawColor(245, 245, 245, 255)
			surface.DrawRect(10, 0, w - 20, h + 4)
			self:SetTextColor(Color(80, 80, 80, 255))
		else
			self:SetTextColor(Color(255, 255, 255, 255))
		end
	end
	function Owned:DoClick()
		CurrentHeader = "Owned"
		ReSearch()
	end

	local SearchTerms = {}
	local SearchOptions = vgui.Create("Panel", Frame)
	SearchOptions:SetHeight(80)
	SearchOptions:Dock(TOP)
	SearchOptions:DockPadding(4, 4, 4, 4)
	function SearchOptions:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(245, 245, 245, 255))
	end
	SearchOptions:InvalidateLayout(true)
	local function AddSearchOption(Key, Icon, Values)
		local Panel = vgui.Create("Panel", SearchOptions)
		Panel:SetWide((ScrW() * 0.7 - 8) / 8)
		Panel:Dock(LEFT)
		Panel:DockPadding(10, 10, 10, 10)
		local Text = vgui.Create("DLabel", Panel)
		Text:SetFont("RealtorPosterFontSmall")
		Text:SetTextColor(Color(80, 80, 80, 255))
		Text:SetText(Key)
		Text:SetTall(20)
		Text:Dock(TOP)
		Text:SetContentAlignment(5)
		local Image = vgui.Create("DImage", Panel)
		Image:SetImage("icon16/" .. Icon .. ".png")
		Image:SetWide(42)
		Image:Dock(LEFT)
		Image:SetImageColor(Color(0, 0, 0, 120))
		function Image:Paint(w, h)
			draw.RoundedBoxEx(6, 0, 0, w, h, Color(190, 190, 190, 255), true, false, true, false)
			draw.RoundedBoxEx(4, 1, 1, w - 2, h - 2, Color(235, 235, 235, 255), true, false, true, false)
			self:PaintAt(12, 8, w - 24, h - 16)
		end
		local Combo = vgui.Create("DComboBox", Panel)
		Combo:Dock(FILL)
		Combo:SetValue(Values[1])
		Combo:SetSortItems(false)
		Combo.OpenMenu = ReplacementOpenMenu
		for i, v in pairs(Values) do
			Combo:AddChoice(v)
		end
		function Combo:Paint(w, h)
			draw.RoundedBoxEx(6, 0, 0, w, h, Color(190, 190, 190, 255), false, true, false, true)
			draw.RoundedBoxEx(4, 1, 1, w - 2, h - 2, Color(245, 245, 245, 255), false, true, false, true)
		end
		SearchTerms[Key] = Values[1]
		function Combo:OnSelect(Index, Value)
			SearchTerms[Key] = Value
			ReSearch()
		end
	end
	local Prices = {}
	local Cur, Rise = 0, 10000
	for i = 1, 90 do
		Cur = Cur + Rise
		Prices[#Prices + 1] = DarkRP.formatMoney(Cur)
		if Cur == 250000 then
			Rise = Rise * 2.5
		elseif Cur == 500000 then
			Rise = Rise * 2
		elseif Cur == 1000000 then
			Rise = Rise * 2
		elseif Cur == 2500000 then
			Rise = Rise * 2.5
		elseif Cur == 5000000 then
			Rise = Rise * 2
		end
	end
	AddSearchOption("Min price", "money_dollar", {"No min", unpack(Prices)})
	AddSearchOption("Max price", "money_dollar", {"No max", unpack(Prices)})
	AddSearchOption("Property type", "building", {"Any", "Houses", "Apartments"})
	AddSearchOption("Size", "shape_group", {"Any", "Small", "Medium", "Large"})

	local List = vgui.Create("DScrollPanel", Frame)
	List:Dock(FILL)
	List:DockMargin(0, 15, 0, 0)
	List:DockPadding(4, 4, 4, 4)
	function List:Paint(w, h)
		draw.RoundedBoxEx(8, 4, 0, w - 8, h, Color(200, 200, 200, 255), false, false, true, false)
	end
	local SBar = List:GetVBar()
	function SBar:Paint(w, h)
		draw.RoundedBox(0, w * 0.2, 0, w * 0.6, h, Color(50, 50, 50, 200))
	end
	function SBar.btnUp:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(150, 150, 150, 255))
	end
	function SBar.btnDown:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(150, 150, 150, 255))
	end
	function SBar.btnGrip:Paint(w, h)
		draw.RoundedBox(0, w * 0.1, 0, w * 0.8, h, Color(150, 150, 150, 255))
	end

	local function GetSearchTerm(Key, Default)
		if Key == "MinPrice" then
			return tonumber(string.gsub(SearchTerms["Min price"], "%D", ""), 10) or Default
		elseif Key == "MaxPrice" then
			return tonumber(string.gsub(SearchTerms["Max price"], "%D", ""), 10) or Default
		elseif Key == "Size" then
			return SearchTerms["Size"] or Default
		elseif Key == "PropertyType" then
			return SearchTerms["Property type"] or Default
		end
	end

	local OTbl = table.ClearKeys(Properties.GetAll(), true)
	table.SortByMember(OTbl, "Price", true)
	local Tbl = {}
	for i, v in pairs(OTbl) do
		if ValidRealtorProperty(Properties.GetAll(), v.__key) then
			Tbl[#Tbl + 1] = v
		end
		if not CurMenuProperty and not v.IsBusiness and Properties.IsContainer(i) and not v.Container then
			CurMenuProperty = v.__key
			break
		end
	end
	function ReSearch()
		List:Clear()
		if CurrentHeader == "Rent" or CurrentHeader == "Warehouse" then
			table.SortByMember(Tbl, "Rent", true)
		end
		for i, v in pairs(Tbl) do
			if CurrentHeader == "Rent" then
				if v.Business or v.Warehouse or v.Rent == 0 or v.Rent < GetSearchTerm("MinPrice", 0) or v.Rent > GetSearchTerm("MaxPrice", math.huge) then
					continue
				end
			elseif CurrentHeader == "Sale" then
				if v.Business or v.Warehouse or v.Price == 0 or v.Price < GetSearchTerm("MinPrice", 0) or v.Price > GetSearchTerm("MaxPrice", math.huge) then
					continue
				end
			elseif CurrentHeader == "Business" then
				if not v.Business then
					continue
				end
			elseif CurrentHeader == "Warehouse" then
				if not v.Warehouse then
					continue
				end
			elseif CurrentHeader == "Owned" then
				continue
			end
			local Contained = Properties.GetContained(v.__key)
			local Size = GetSearchTerm("Size", "Any")
			local SqrFeet = Properties.GetSquareFootage(Contained or v.__key)
			if Size == "Small" and SqrFeet > 2000 or Size == "Medium" and SqrFeet > 3500 or Size == "Large" and SqrFeet > 4500 then
				continue
			end
			local Type = GetSearchTerm("PropertyType", "Any")
			if Type == "Houses" and Contained or Type == "Apartments" and not Contained then
				continue
			end

			local RTKey = tostring(v.__key) .. "," .. 1
			GetRTTexture(RTKey, v.Cameras[1][1], v.Cameras[1][2])
			local New = vgui.Create("Panel", List)
			New:SetTall(300)
			New:DockMargin(0, 0, 0, 15)
			New:Dock(TOP)
			New:SetMouseInputEnabled(true)
			New.OldTextureKey = 0
			New.TextureKey = 1
			New.FadeStart = 0
			New.Current = 0

			function New:DrawButton(x, y, sx, sy, Text, MX, MY)
				surface.DrawTexturedRect(x, y, sx, sy)
				EfficientText(Text, x + sx / 2, y + sy / 2, true)
				if MX > x and MX < x + sx and MY > y and MY < y + sy then
					self.Button = Text
					self:SetCursor("hand")
					return true
				end
				return false
			end

			local Price = (CurrentHeader == "Sale" or CurrentHeader == "Business") and DarkRP.formatMoney(v.Price) or DarkRP.formatMoney(v.Rent) .. " per month, down payment of " .. DarkRP.formatMoney(v.Rent / 2)
			function New:Paint(w, h)
				surface.SetDrawColor(245, 245, 245, 255)
				surface.DrawRect(0, 0, w, h)

				surface.SetDrawColor(230, 120, 50, 255)
				surface.DrawRect(0, h * 0.7 - 2, h * 1.1, h * 0.3 + 2)

				surface.SetDrawColor(255, 255, 255, 255)
				if SysTime() - self.FadeStart < 0.3 then
					local Fraction = math.Clamp((SysTime() - self.FadeStart) / 0.3, 0, 1)
					surface.SetMaterial(GetRTTexture(tostring(v.__key) .. "," .. self.OldTextureKey, unpack(v.Cameras[self.OldTextureKey])))
					surface.DrawTexturedRect(2, 2, h * 1.1 - 4, h * 0.7 - 6)
					surface.SetDrawColor(255, 255, 255, 255 * Fraction)
					surface.SetMaterial(GetRTTexture(tostring(v.__key) .. "," .. self.TextureKey, unpack(v.Cameras[self.TextureKey])))
					surface.DrawTexturedRect(2, 2, h * 1.1 - 4, h * 0.7 - 6)
				else
					surface.SetMaterial(GetRTTexture(tostring(v.__key) .. "," .. self.TextureKey, unpack(v.Cameras[self.TextureKey])))
					surface.DrawTexturedRect(2, 2, h * 1.1 - 4, h * 0.7 - 6)
				end
				surface.SetDrawColor(255, 255, 255, 255)
				local MX, MY = self:LocalCursorPos()
				local sx, sy = self:LocalToScreen()
				render.SetScissorRect(sx + 2, sy, sx + h * 1.1 - 2, sy + h, true)
				local MouseX = MX / (h * 1.1)
				if not self.Camera then
					self.Camera = math.min(-#v.Cameras * h * 0.2 + h * 0.55, 0)
				end
				if MouseX >= 0 and MouseX <= 1 and MY > h * 0.7 and MY < h then
					self.Camera = math.Clamp(self.Camera + (MouseX - 0.5) * 15, math.min(-#v.Cameras * h * 0.2 + h * 0.55, 0), math.max(#v.Cameras * h * 0.2 - h * 0.55 + 2, 0))
				end
				self.Button = nil
				self.Current = 0
				for x, y in pairs(v.Cameras) do
					local px, py = h * 0.15 + (x - #v.Cameras / 2) * h * 0.4 - self.Camera, h * 0.7
					surface.SetMaterial(GetRTTexture(tostring(v.__key) .. "," .. x, y[1], y[2]))
					surface.DrawTexturedRect(px + 2, py, h * 0.4 - 2, h * 0.3 - 2)
					if MX < h * 1.1 and MX > px and MX < px + h * 0.4 and MY > py and MY < py + h * 0.3 then
						self.Current = x
						self.Button = "Camera"
						self:SetCursor("hand")
					end
				end
				render.SetScissorRect(0, 0, 0, 0, false)

				surface.SetFont("RealtorFont")
				surface.SetTextColor(245, 245, 245, 255)

				surface.SetDrawColor(230, 120, 50, 255)
				draw.NoTexture()
				self:DrawButton(h * 1.15, h * 0.7 - 2, w * 0.2, h * 0.3 + 2, "Buy", MX, MY)
				local Success = self:DrawButton(h * 1.2 + w * 0.2, h * 0.7 - 2, w * 0.2, h * 0.3 + 2, "Show on map", MX, MY)
				if Success then
					self.Current = x
				end

				if not self.Button then
					self:SetCursor("none")
				end

				surface.SetTextColor(150, 0, 0, 255)
				EfficientText(Price, h * 1.15, 15)

				surface.SetFont("RealtorFontSmall")
				surface.SetTextColor(80, 80, 80, 255)
				local wi = w - h * 1.2
				for f, g in pairs(GetPropertyDescription(v.__key, wi)) do
					EfficientText(table.concat(g, " "), h * 1.15, 40 + f * 26)
				end
			end
			function New:OnMouseReleased(Code)
				if Code == MOUSE_LEFT then
					if self.Button == "Camera" and self.Current ~= 0 then
						self.OldTextureKey = self.TextureKey
						self.TextureKey = self.Current
						self.FadeStart = SysTime()
					elseif self.Button == "Show on map" then
						LocalPlayer():ConCommand("greymap_open " .. (v.Start.x + v.End.x) / 2 .. " " .. (v.Start.y + v.End.y) / 2)
					elseif self.Button == "Buy" then
						Derma_Query("Really buy this property for " .. Price:gsub("month, down ", "month with an immediate ") .. "?", "Purchase confirmation", "Yes", function() end, "No")
					end
				end
			end
		end
	end
	ReSearch()
end)
--[[
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

				if SysTime() - New.LastRender > 1 then
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
				 	New.LastRender = SysTime()
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
	end]]
