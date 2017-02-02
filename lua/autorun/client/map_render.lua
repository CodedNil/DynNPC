local MinZoom, MaxZoom = 500, 2000
local RenderingMap = false

GreyRP = GreyRP or {}
GreyRP.PanelData = GreyRP.PanelData or {}
GreyRP.MapWaypoints = {}
timer.Create("MapWaypointUpdate", 1, 0, function()
	GreyRP.MapWaypoints = {}
	hook.Run("GetMapWaypoints")
end)

function GreyRP:SetupMapPanel(sx, sy, sz, Id)
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)

	self.LastUpdate = 0

	if Id then
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
	end

	function self:GetVector()
		return Vector(self.TransY, self.TransX, 1600)
	end

	function self:SetTrans(x, y)
		self.TransX = x
		self.TransY = y
		if Id then
			Id.x, Id.y = self.TransX, self.TransY
		end
	end

	function self:Paint(w, h)
		if RealTime() - self.LastUpdate > 0.1 then
			net.Start("MapPositionData")
				net.WriteVector(self:GetVector())
			net.SendToServer()
			self.LastUpdate = RealTime()
		end
		local x, y = self:LocalToScreen()
		local OldW, OldH = ScrW(), ScrH()
		render.SetViewPort(x, y, w, h)
			render.Clear(0, 0, 0, 0)
			cam.Start2D()
				RenderingMap = true
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
					drawhud = false,
					drawviewmodel = false
				})
				RenderingMap = false

			cam.End2D()
		render.SetViewPort(0, 0, OldW, OldH)

		surface.SetDrawColor(255, 255, 255, 255)
		--surface.DrawRect(w / 2 - 3, h / 2 - 3, 6, 6)
		for _, v in pairs(GreyRP.MapWaypoints) do
			local Size = 100 * 1 / (self.Zoom / 1000)
			local tx, ty = (self.TransX - v[2].y) / self.Zoom * 500, (self.TransY - v[2].x) / self.Zoom * 500
			surface.DrawRect(w / 2 - Size / 2 + tx, h / 2 - Size / 2 + ty, Size, Size)
		end
		draw.DrawText("TransX: " .. self.TransX .. " TransY: " .. self.TransY .. " Zoom: " .. self.Zoom, "DermaDefault", 50, 50, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
	end

	function self:OnMouseWheeled(Delta)
		self.Zoom = math.Clamp(self.Zoom - Delta * 20, MinZoom, MaxZoom)
		if Id then
			Id.z = self.Zoom
		end
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
local function OpenMenu()
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
	GreyRP.SetupMapPanel(Panel, EyePos().y, EyePos().x, (MinZoom + MaxZoom) / 2, "map_menu")
end

concommand.Add("greymap_open", function()
	OpenMenu()
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
