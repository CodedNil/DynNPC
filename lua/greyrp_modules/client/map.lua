local MinZoom, MaxZoom = 0.6, 4

GreyRP = GreyRP or {}

function GreyRP:SetupMapPanel()
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)

	self.TransX, self.TransY = 0, 0
	self.Zoom = 1

	function self:OnMouseWheeled(Delta)
		if input.IsControlDown() then
			self.Zoom = math.Clamp(self.Zoom + Delta / 4, MinZoom, MaxZoom)
		else
			self.TransY = self.TransY + Delta * 20
		end
	end

	function self:OnCursorMoved(x, y)
		if self.MiddleDown then
			if self.LastMX and self.LastMY then
				self.TransX = self:GetTransX() + x - self.LastMX
				self.TransY = self:GetTransY() + y - self.LastMY
			end
			self.LastMX = x
			self.LastMY = y
		end
	end

	function self:OnMousePressed(Code)
		if Code == MOUSE_MIDDLE then
			self.MiddleDown = true
			self:SetCursor("hand")
		end
	end

	function self:OnMouseReleased(Code)
		if Code == MOUSE_MIDDLE then
			self.MiddleDown = false
			self:SetCursor("none")
			self.LastMX = nil
			self.LastMY = nil
		end
	end

	function self:OnCursorExited()
		if self.MiddleDown then
			self.MiddleDown = false
			self:SetCursor("none")
			self.LastMX = nil
			self.LastMY = nil
		end
	end
end

local Menu
local function OpenMenu()
	if Menu and IsValid(Menu) then
		Menu:Remove()
	end

	Menu = vgui.Create("DFrame")
	Menu:SetSize(1000, 1000)
	Menu:SetTitle("Map")
	Menu:ShowCloseButton(true)
	Menu:SetDraggable(true)
	Menu:MakePopup()
	Menu.lblTitle:SetFont("DYNNPC_FONT_LARGE")
	function Menu:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 0, w, 24, Color(32, 178, 170, 255), false, true, false, false)
		draw.RoundedBoxEx(8, 0, 24, w, h - 24, Color(245, 245, 245, 255), false, false, true, false)
	end

	local Panel = vgui.Create("Panel", Menu)
	Panel:Dock(FILL)
	GreyRP.SetupMapPanel(Panel)
end

concommand.Add("greymap_open", function()
	OpenMenu()
end)


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
end
