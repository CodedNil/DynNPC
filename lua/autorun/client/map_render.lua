local MinZoom, MaxZoom = 500, 4000
local RenderingMap = false

GreyRP = GreyRP or {}
--GreyRP.PanelData = GreyRP.PanelData or {}
GreyRP.MapWaypoints = {}
timer.Create("MapWaypointUpdate", 1, 0, function()
	GreyRP.MapWaypoints = {}
	hook.Run("GetMapWaypoints")
end)

MapIconMaterials = MapIconMaterials or {}
MapFonts = {}

local function GetFont(Size, Weight)
	Size = math.Round(Size)
	if not MapFonts[Size] then
		MapFonts[Size] = true
		surface.CreateFont("MapFont" .. Size, {
			font = "Trebuchet",
			size = Size,
			weight = Weight
		})
	end
	return "MapFont" .. Size
end

function GreyRP:SetupMapPanel(sx, sy, sz, Id)
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)

	self.LastUpdate = 0

	--[[if Id then
		if GreyRP.PanelData[Id] then
			Id = GreyRP.PanelData[Id]
			self.TransX, self.TransY = Id.x, Id.y
			self.Zoom = Id.z
		else
			GreyRP.PanelData[Id] = {}
			Id = GreyRP.PanelData[Id]
			self.TransX, self.TransY = sx, sy
			self.Zoom = sz
		end
	else
		self.TransX, self.TransY = sx, sy
		self.Zoom = sz
	end]]
	self.TransX, self.TransY = sx, sy
	self.Zoom = sz

	function self:GetVector()
		return Vector(self.TransY, self.TransX, 1600)
	end

	function self:SetTrans(x, y)
		self.TransX = x
		self.TransY = y
		--if Id then
		--	Id.x, Id.y = self.TransX, self.TransY
		--end
	end

	function self:ChangeTrans(x, y)
		if x then
			self.TransX = self.TransX + x
			--if Id then
			--	Id.x = self.TransX
			--end
		end
		if y then
			self.TransY = self.TransY + y
			--if Id then
			--	Id.y = self.TransY
			--end
		end
	end

	function self:Paint(w, h)
		if RealTime() - self.LastUpdate > 0.5 then
			net.Start("MapPositionData")
				net.WriteVector(self:GetVector())
			net.SendToServer()
			self.LastUpdate = RealTime()
		end
		if not self.Dragging then
			if input.IsKeyDown(KEY_W) or input.IsKeyDown(KEY_UP) then
				self:ChangeTrans(nil, 20)
			end
			if input.IsKeyDown(KEY_S) or input.IsKeyDown(KEY_DOWN) then
				self:ChangeTrans(nil, -20)
			end
			if input.IsKeyDown(KEY_A) or input.IsKeyDown(KEY_LEFT) then
				self:ChangeTrans(20)
			end
			if input.IsKeyDown(KEY_D) or input.IsKeyDown(KEY_RIGHT) then
				self:ChangeTrans(-20)
			end
		end
		local x, y = self:LocalToScreen()
		local OldW, OldH = ScrW(), ScrH()
		render.SetViewPort(x, y, w, h)
			render.Clear(0, 0, 0, 0)
			cam.Start2D()
				RenderingMap = true
					local PlrDraws = {}
					for _, v in pairs(player.GetAll()) do
						if not v:GetNoDraw() then
							PlrDraws[#PlrDraws + 1] = v
							v:SetNoDraw(true)
						end
					end
					local OrthoAmount = self.Zoom
					render.RenderView({
						origin = self:GetVector(),
						angles = Angle(90, 0, 0),
						x = x,
						y = y,
						w = w,
						h = h,
						ortho = true,
						ortholeft = -OrthoAmount / 1000 * w,
						orthoright = OrthoAmount / 1000 * w,
						orthotop = -OrthoAmount / 1000 * h,
						orthobottom = OrthoAmount / 1000 * h,
						drawviewmodel = false
					})
					for _, v in pairs(PlrDraws) do
						v:SetNoDraw(false)
					end
				RenderingMap = false
			cam.End2D()
		render.SetViewPort(0, 0, OldW, OldH)

		for _, v in pairs(GreyRP.MapWaypoints) do
			local tx, ty = w / 2 + (self.TransX - v[2].y) / self.Zoom * 500, h / 2 + (self.TransY - v[2].x) / self.Zoom * 500
			local yx, yy = w / 2 + (self.TransX - v[3].y) / self.Zoom * 500, h / 2 + (self.TransY - v[3].x) / self.Zoom * 500
			if not MapIconMaterials[v[4]] then
				MapIconMaterials[v[4]] = Material("icon16/" .. v[4] .. ".png")
			end
			if gui.MouseX() < x + tx and gui.MouseX() > x + yx and gui.MouseY() < y + ty and gui.MouseY() > y + yy then
				surface.SetDrawColor(v[5].r, v[5].g, v[5].b, 200)
				surface.DrawRect(yx, yy, tx - yx, ty - yy)
				local Gap = 150 / self.Zoom * 500
				for e, g in pairs(v[6]) do
					draw.SimpleText(g[1], GetFont(g[2] / self.Zoom * 500, 1000), tx - (tx - yx) / 2, ty - (ty - yy) / 2 + Gap * (e - (#v[6] + 1) / 2), Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			else
				surface.SetDrawColor(v[5].r, v[5].g, v[5].b, 100)
				surface.DrawRect(yx, yy, tx - yx, ty - yy)
				surface.SetDrawColor(Color(255, 255, 255, 255))
				surface.SetMaterial(MapIconMaterials[v[4]])
				surface.DrawTexturedRectRotated((tx + yx) / 2, (ty + yy) / 2, 300 / self.Zoom * 500, 300 / self.Zoom * 500, 0)
			end
		end
		if not MapIconMaterials["arrow_up"] then
			MapIconMaterials["arrow_up"] = Material("icon16/arrow_up.png")
		end
		local PlrPos = LocalPlayer():EyePos()
		local tx, ty = w / 2 + (self.TransX - PlrPos.y) / self.Zoom * 500, h / 2 + (self.TransY - PlrPos.x) / self.Zoom * 500
		surface.SetDrawColor(255, 0, 0, 255)
		surface.SetMaterial(MapIconMaterials["arrow_up"])
		surface.DrawTexturedRectRotated(tx, ty, 50, 50, LocalPlayer():EyeAngles().y)
		draw.DrawText("TransX: " .. self.TransX .. " TransY: " .. self.TransY .. " Zoom: " .. self.Zoom, "DermaDefault", 50, 50, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
	end

	function self:OnMouseWheeled(Delta)
		self.Zoom = math.Clamp(self.Zoom - Delta * 50, MinZoom, MaxZoom)
		--if Id then
		--	Id.z = self.Zoom
		--end
	end

	function self:OnCursorMoved(x, y)
		if self.Dragging then
			if self.LastMX and self.LastMY then
				local Amount = self.Zoom / 500
				self:SetTrans(self.TransX + (x - self.LastMX) * Amount, self.TransY + (y - self.LastMY) * Amount)
			end
			self.LastMX = x
			self.LastMY = y
		end
	end

	function self:OnMousePressed(Code)
		if Code == MOUSE_LEFT or Code == MOUSE_MIDDLE then
			self.Dragging = true
			self:SetCursor("hand")
		end
	end

	function self:OnMouseReleased(Code)
		if Code == MOUSE_LEFT or Code == MOUSE_MIDDLE then
			self.Dragging = false
			self:SetCursor("none")
			self.LastMX = nil
			self.LastMY = nil
		end
	end

	function self:OnCursorExited()
		if self.Dragging then
			self.Dragging = false
			self:SetCursor("none")
			self.LastMX = nil
			self.LastMY = nil
		end
	end
end

hook.Add("PreDrawSkyBox", "MapRender", function()
	if RenderingMap then
		return true
	end
end)

hook.Add("ShouldDrawLocalPlayer", "MapRender", function()
	if RenderingMap then
		return true
	end
end)

local Menu
local function OpenMenu(x, y, z)
	if Menu and IsValid(Menu) then
		Menu:Remove()
	end

	Menu = vgui.Create("DFrame")
	Menu:SetSize(1000, 1000)
	Menu:Center()
	Menu:SetTitle("Map")
	Menu:ShowCloseButton(true)
	Menu:SetDraggable(true)
	Menu:SetSizable(true)
	Menu:MakePopup()
	Menu.lblTitle:SetFont("DYNNPC_FONT_LARGE")
	function Menu:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 0, w, 24, Color(32, 178, 170, 255), false, true, false, false)
		draw.RoundedBoxEx(8, 0, 24, w, h - 24, Color(245, 245, 245, 255), false, false, true, false)
	end

	local Panel = vgui.Create("Panel", Menu)
	Panel:Dock(FILL)
	GreyRP.SetupMapPanel(Panel, y or EyePos().y, x or EyePos().x, z or (MinZoom + MaxZoom) / 2, "map_menu")
end

concommand.Add("greymap_open", function(Plr, Cmd, Args)
	OpenMenu(unpack(Args))
end)

--[[
local PANEL = {}

PANEL.Items = {}

AccessorFunc(PANEL, "m_Zoom", "Zoom")
AccessorFunc(PANEL, "m_TransX", "TransX")
AccessorFunc(PANEL, "m_TransY", "TransY")

function PANEL:Init()
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self.m_Zoom = 1
	self.m_TransX = 0
	self.m_TransY = 0
	self:NoClipping(false)
end

function PANEL:UpdateItems()
	for i, v in pairs(self.Items) do
		if IsValid(v) then
			v:SetPos(v.TruePos[1] - v.TrueSize[1] * (self:GetZoom() - 1)/2 + self:GetTransX(), v.TruePos[2] - v.TrueSize[2] * (self:GetZoom() - 1)/2 + self:GetTransY())
			v:SetSize(v.TrueSize[1] * self:GetZoom(), v.TrueSize[2] * self:GetZoom())
			if v.TrueBorderWeight and v.TrueBorderWeight > 0 and not v:GetPage() then
				v.m_BorderWeight = v.TrueBorderWeight * self:GetZoom()
			end
		else
			self.Items[i] = nil
		end
	end
end

function PANEL:SetZoom(Zoom)
	self.m_Zoom = Zoom
	self:UpdateItems()
end

function PANEL:SetTransX(New)
	self.m_TransX = New
	self:UpdateItems()
end

function PANEL:SetTransY(New)
	self.m_TransY = New
	self:UpdateItems()
end

function PANEL:SetTrans(x, y)
	self.m_TransX = x
	self.m_TransY = y
	self:UpdateItems()
end

function PANEL:OnMouseWheeled(Delta)
	if input.IsControlDown() then
		self:SetZoom(math.Clamp(self:GetZoom() + Delta/4, MinZoom, MaxZoom))
	else
		self:SetTransY(self:GetTransY() + Delta * 20)
	end
end

function PANEL:OnCursorMoved(x, y)
	if self.MiddleDown then
		if self.LastMX and self.LastMY then
			self:SetTrans(self:GetTransX() + x - self.LastMX, self:GetTransY() + y - self.LastMY)
		end
		self.LastMX = x
		self.LastMY = y
	end
end

function PANEL:OnMousePressed(Code)
	if Code == MOUSE_MIDDLE then
		self.MiddleDown = true
		self:SetCursor("hand")
	end
end

function PANEL:OnMouseReleased(Code)
	if Code == MOUSE_MIDDLE then
		self.MiddleDown = false
		self:SetCursor("none")
		self.LastMX = nil
		self.LastMY = nil
	end
end

function PANEL:OnCursorExited()
	if self.MiddleDown then
		self.MiddleDown = false
		self:SetCursor("none")
		self.LastMX = nil
		self.LastMY = nil
	end
end

function PANEL:AddItem(Item)
	self.Items[Item:GetZPos()] = Item
	Item.TruePos = {Item:GetPos()}
	Item.TrueSize = {Item:GetSize()}
	Item.TrueBorderWeight = Item.TrueBorderWeight or Item.m_BorderWeight or 0
	function Item.Update()
		self:UpdateItems()
	end
	self:UpdateItems()
end

function PANEL:Paint(w, h)
	for i, v in SortedPairs(self.Items) do
		if IsValid(v) then
			local x, y = v:GetPos()
			local w, h = v:GetSize()
			v:Paint(x, y, w, h)
			if v:GetZPos() ~= i then
				self.Items[v:GetZPos()] = v
				self.Items[i] = nil
			end
		else
			self.Items[i] = nil
		end
	end
end]]
