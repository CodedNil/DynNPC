surface.CreateFont("DYNNPC_FONT_LARGE", {
	font = "Roboto",
	size = 18,
	weight = 200,
	antialias = true
})

surface.CreateFont("DYNNPC_FONT_MEDIUM", {
	font = "Roboto",
	size = 16,
	weight = 200,
	antialias = true
})

local Scale = 1.5

local Menu
net.Receive("DynNPCMenu", function()
	if Menu and IsValid(Menu) then
		Menu:Remove()
	end
	local Name, Ent, Tbl = net.ReadString(), net.ReadEntity(), net.ReadTable()
	Tbl[#Tbl + 1] = "Cancel"

	local Height = 36 * #Tbl * Scale + 40
	Menu = vgui.Create("DFrame")
	Menu:SetSize(400 * Scale, Height)
	Menu:SetTitle(Name)
	Menu:SetPos(0, ScrH() * 0.6 - Height / 2)
	Menu:CenterHorizontal()
	Menu:ShowCloseButton(false)
	Menu:SetDraggable(false)
	Menu:MakePopup()
	Menu.lblTitle:SetFont("DYNNPC_FONT_LARGE")
	function Menu:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 0, w, 24, Color(32, 178, 170, 255), false, true, false, false)
		draw.RoundedBoxEx(8, 0, 24, w, h - 24, Color(245, 245, 245, 255), false, false, true, false)
	end

	for i, v in pairs(Tbl) do
		local New = vgui.Create("DButton", Menu)
		New:Dock(TOP)
		New:DockMargin(6 * Scale, 6 * Scale, 6 * Scale, i == #Tbl and 6 * Scale or 0)
		New:SetTall(30 * Scale)
		New:SetFont("DYNNPC_FONT_MEDIUM")
		New:SetTextColor(Color(80, 80, 80, 255))
		New:SetText(v)
		function New:Paint(w, h)
			draw.RoundedBoxEx(8, 0, 0, w, h, Color(120, 120, 120, 255), false, i == 1, i == #Tbl, false)
			draw.RoundedBoxEx(8, 1, 1, w - 2, h - 2, Color(225, 225, 225, 255), false, i == 1, i == #Tbl, false)
		end
		function New:DoClick()
			net.Start("DynNPCMenu")
				net.WriteString(Name)
				net.WriteEntity(Ent)
				net.WriteString(v)
			net.SendToServer()
			Menu:Close()
		end
	end
end)
