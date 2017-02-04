TOOL.Category = "GreyRP"
TOOL.Name = "#tool.propertydev.name"

TOOL.ClientConVar["door_class"] = "prop_dynamic"

TOOL.Information = {
    {name = "left"},
    {name = "right"},
    {name = "reload"}
}

local PropertyDataFormat = {
    Name = "Unnamed",
    Price = 100,
    Rent = 0,
    Business = false,

    Start = Vector(),
    End = Vector(),

    Doors = {},
    Cameras = {},
    Nodes = {}
}

local PropertyDataFormatView = {
    "Name",
    "DETAILS",
    "Price",
    "Rent",
    "Business",
    "BUSINESS",
    "Job",
    "ADVANCED",
    "Start",
    "End"
}

if SERVER then
    util.AddNetworkString("PropertiesDev")
    GlobalProperties = GreyRP.GetData("property")
    local function UpdateData()
    	GreyRP.SetData("property", GlobalProperties)
    end

    for i, v in pairs(PropertyDataFormat) do
        for x, y in pairs(GlobalProperties) do
            if y[i] == nil or type(y[i]) ~= type(v) then
                if type(v) == "table" then
                    y[i] = table.Copy(v)
                else
                    y[i] = v
                end
            end
        end
    end
    for i, v in pairs(GlobalProperties) do
        for x, y in pairs(v) do
            if x ~= "Container" and PropertyDataFormat[x] == nil  then
                v[x] = nil
            end
        end
    end

    net.Receive("PropertiesDev", function(_, Plr)
    	local Type = net.ReadString()
    	if Type == "Get" then
    		net.Start("PropertiesDev")
    			net.WriteInt(0, 10)
    			net.WriteTable(GlobalProperties)
    		net.Send(Plr)
    		return
    	end
    	local Property = net.ReadInt(10)
        if Type == "Set" then
            local New = net.ReadTable()
            GlobalProperties[Property] = New
            for _, v in pairs(player.GetAll()) do
                if v ~= Plr then
                    net.Start("PropertiesDev")
                        net.WriteInt(Property + 800 , 10)
                        net.WriteTable(New)
                    net.Send(v)
                end
            end
        elseif Type == "Remove" then
            GlobalProperties[Property] = nil
            for _, v in pairs(player.GetAll()) do
                if v ~= Plr then
                    net.Start("PropertiesDev")
                        net.WriteInt(Property, 10)
                    net.Send(v)
                end
            end
        elseif Type == "Update" then
            local Var = net.ReadString()
            if Var == "Position" then
                local New = net.ReadTable()
                GlobalProperties[Property].Start, GlobalProperties[Property].End = New[1], New[2]
            	for _, v in pairs(player.GetAll()) do
            		if v ~= Plr then
                        net.Start("PropertiesDev")
                            net.WriteInt(Property, 10)
                            net.WriteString("Position")
                            net.WriteType(New)
                        net.Send(v)
                    end
                end
            else
                local New = net.ReadType()
                GlobalProperties[Property][Var] = New
            	for _, v in pairs(player.GetAll()) do
            		if v ~= Plr then
            			net.Start("PropertiesDev")
            				net.WriteInt(Property, 10)
            				net.WriteString(Var)
                            net.WriteType(New)
            			net.Send(v)
                    end
                end
            end
        end
        UpdateData()
    end)
end
if CLIENT then
    local function CheckNumericCustom(self, Val)
        return not string.find("1234567890", Val, 1, true)
    end

    local function GetSimilarEnt(Ent, Pos, Distance)
        for _, v in pairs(ents.FindInSphere(Pos, Distance)) do
            if v:GetClass() == Ent:GetClass() then
                return v
            end
        end
    end

    function EfficientText(Text, x, y, Center)
    	if Center then
    		local w, h = surface.GetTextSize(Text)
    		x = x - w / 2
    		y = y - h / 2
    	end
    	surface.SetTextPos(math.ceil(x), math.ceil(y))
    	surface.DrawText(Text)
    end

    local function MirrorPosition(Position, MirrorPos, MirrorOffset)
        local New = Vector(Position)
        if MirrorPos.x ~= 0 then
            New.x = MirrorPos.x - (New.x - MirrorPos.x)
        end
        if MirrorPos.y ~= 0 then
            New.y = MirrorPos.y - (New.y - MirrorPos.y)
        end
        if MirrorOffset then
            New = New + MirrorOffset
        end
        return New
    end

    local function GetPlanesIntersection(Planes)
        local x, y, z
        for _, v in pairs(Planes) do
            local Normal = Vector(math.Round(math.abs(v[2].x)), math.Round(math.abs(v[2].y)), math.Round(math.abs(v[2].z)))
            if Normal == Vector(1, 0, 0) then
                x = v[1].x
            elseif Normal == Vector(0, 1, 0) then
                y = v[1].y
            elseif Normal == Vector(0, 0, 1) then
                z = v[1].z
            end
        end
        return x, y, z
    end

    local Normals = {
        Front = Vector(0, -1, 0),
        Back = Vector(0, 1, 0),
        Left = Vector(-1, 0, 0),
        Right = Vector(1, 0, 0),
        Top = Vector(0, 0, 1),
        Bottom = Vector(0, 0, -1)
    }
    local function GetFaceNormals(Face)
        return Normals[Face]
    end
    local function GetFaceFromNormal(Normal)
        for i, v in pairs(Normals) do
            if v == Normal then
                return i
            end
        end
    end

    local function GetFaceSize(Face, Size)
        if Face == "Front" or Face == "Back" then
            return {Size.x, Size.z}
        elseif Face == "Left" or Face == "Right" then
            return {Size.y, Size.z}
        elseif Face == "Top" or Face == "Bottom" then
            return {Size.y, Size.x}
        end
    end

    local function Notify(Text, IsError)
        notification.AddLegacy(Text, IsError and NOTIFY_ERROR or NOTIFY_HINT, IsError and 4 or 2)
        surface.PlaySound("buttons/button15.wav")
    end

    hook.Add("CanTool", "FPP_CL_CanTool", function(ply, trace, tool)
        local PropertyToolGun = LocalPlayer().GetActiveWeapon and LocalPlayer():GetActiveWeapon().PrintName == "Tool Gun" and LocalPlayer():GetActiveWeapon():GetMode() == "propertydev"
        if not PropertyToolGun and IsValid(trace.Entity) and not FPP.canTouchEnt(trace.Entity, "Toolgun") then
            return false
        end
    end)

    GlobalProperties = {}
    GlobalPropertiesCheckSum = {}

    local Plr = LocalPlayer()

    net.Receive("PropertiesDev", function()
    	local Property = net.ReadInt(10)
        if Property == 0 then
            GlobalProperties = net.ReadTable()
            for i, _ in pairs(GlobalProperties) do
                GlobalPropertiesCheckSum[i] = 0
            end
        elseif Property > 800 then
    		GlobalProperties[Property - 800] = net.ReadTable()
            GlobalPropertiesCheckSum[Property - 800] = 0
    	else
    		GlobalProperties[Property][net.ReadString()] = net.ReadType()
            GlobalPropertiesCheckSum[Property] = GlobalPropertiesCheckSum [Property] + 1
    	end
    end)

    timer.Simple(0.5, function()
    	net.Start("PropertiesDev")
    		net.WriteString("Get")
    	net.SendToServer()
        Plr = LocalPlayer()
    end)

    Properties = {}

    function Properties.GetAll()
        return GlobalProperties
    end
    function Properties.Get(Property)
        return GlobalProperties[Property]
    end
    function Properties.GetByName(Name)
        for _, v in pairs(GlobalProperties) do
            if v.Name == Name then
                return v
            end
        end
    end
    function Properties.Exists(Property)
        return GlobalProperties[Property] ~= nil
    end
    function Properties.Add(Data)
        local Key = table.insert(GlobalProperties, Data)
        GlobalPropertiesCheckSum[Key] = 0
        net.Start("PropertiesDev")
            net.WriteString("Set")
            net.WriteInt(Key, 10)
            net.WriteTable(Data)
        net.SendToServer()
        return Key
    end
    function Properties.Remove(Property)
        if Plr.GetActiveWeapon and Plr:GetActiveWeapon().PrintName == "Tool Gun" and Plr:GetActiveWeapon():GetMode() == "propertydev" then
            local Tool = Plr:GetTool("propertydev")
            if Tool.SelectedProperty == Property then
                Tool.SelectedProperty = nil
            end
        end
        for i, v in pairs(Properties.GetAll()) do
            if v.Container == Property then
                Properties.UpdateVariable(v, "Container")
            end
        end
        net.Start("PropertiesDev")
            net.WriteString("Remove")
            net.WriteInt(Property, 10)
        net.SendToServer()
        GlobalProperties[Property] = nil
        GlobalPropertiesCheckSum[Property] = nil
    end

    function Properties.CheckContainer(Property)
        if not Properties.Exists(Property) then
            return
        end
        local LProp = GlobalProperties[Property]
        for i, v in pairs(Properties.GetAll()) do
            local Start, End = v.Start - Vector(5, 5, 5), v.End + Vector(5, 5, 5)
            OrderVectors(Start, End)
            if i ~= Property and not v.Business and LProp.Start:WithinAABox(Start, End) and LProp.End:WithinAABox(Start, End) then
                Properties.UpdateVariable(Property, "Container", i)
                return
            end
        end
        Properties.UpdateVariable(Property, "Container")
    end

    function Properties.UpdateVariable(Property, Var, New)
        if not Properties.Exists(Property) or Properties.GetVariable(Property, Var) == New then
            return
        end
        if Var == "Position" then
            GlobalProperties[Property].Start = New[1]
            GlobalProperties[Property].End = New[2]
            for i, _ in pairs(GlobalProperties) do
                Properties.CheckContainer(i)
            end
            net.Start("PropertiesDev")
                net.WriteString("Update")
                net.WriteInt(Property, 10)
                net.WriteString("Position")
                net.WriteTable(New)
            net.SendToServer()
        else
            GlobalProperties[Property][Var] = New
            net.Start("PropertiesDev")
                net.WriteString("Update")
                net.WriteInt(Property, 10)
                net.WriteString(Var)
                net.WriteType(New)
            net.SendToServer()
            if Var == "Start" or Var == "End" or Var == "Business" then
                for i, _ in pairs(GlobalProperties) do
                    Properties.CheckContainer(i)
                end
            end
        end
        GlobalPropertiesCheckSum[Property] = GlobalPropertiesCheckSum[Property] + 1
    end
    function Properties.GetVariable(Property, Var, Backup)
        if not GlobalProperties[Property] or GlobalProperties[Property][Var] == nil then
            return Backup
        end
        return GlobalProperties[Property][Var]
    end

    function Properties.UpdateTableVariable(Property, Var, Ind, New)
        if not GlobalProperties[Property] or GlobalProperties[Property][Var] == nil then
            return
        end
        local Tbl = table.Copy(GlobalProperties[Property][Var])
        Tbl[Ind] = New
        Properties.UpdateVariable(Property, Var, Tbl)
    end
    function Properties.InsertTableVariable(Property, Var, New)
        if not GlobalProperties[Property] or GlobalProperties[Property][Var] == nil then
            return
        end
        local Tbl = table.Copy(GlobalProperties[Property][Var])
        table.insert(Tbl, New)
        Properties.UpdateVariable(Property, Var, Tbl)
    end

    local Planes = {}
    local Face
    function TOOL:LeftClick(Trace)
        Plr = LocalPlayer()
        if not IsFirstTimePredicted() then
            return
        end
        if self.EditMode == "Select" then
            local TargetSelf = false
            local Closest, ClosestDist, ClosestPos, ClosestNormal
            for i, v in pairs(Properties.GetAll()) do
                local Pos = (v.Start + v.End) / 2
                local MinS = Vector(math.min(Pos.x - v.Start.x, Pos.x - v.End.x), math.min(Pos.y - v.Start.y, Pos.y - v.End.y), math.min(Pos.z - v.Start.z, Pos.z - v.End.z))
                local MaxS = Vector(math.max(Pos.x - v.Start.x, Pos.x - v.End.x), math.max(Pos.y - v.Start.y, Pos.y - v.End.y), math.max(Pos.z - v.Start.z, Pos.z - v.End.z))
                local HitPos, HitNormal = util.IntersectRayWithOBB(Trace.StartPos, Trace.Normal * 10000, Pos, Angle(), MinS, MaxS)
                if HitPos and (not Closest or (Trace.StartPos - HitPos):Length() < ClosestDist) then
                    if self.SelectedProperty == i then
                        TargetSelf = true
                    else
                        Closest, ClosestDist, ClosestPos, ClosestNormal = i, (Trace.StartPos - HitPos):Length(), HitPos, HitNormal
                    end
                end
            end
            if Closest and not util.TraceLine({start = Trace.StartPos, endpos = ClosestPos, filter = Plr}).Hit then
                self.SelectedProperty = Closest
                Plr:GetActiveWeapon():DoShootEffect(ClosestPos, ClosestNormal, nil, 1, IsFirstTimePredicted())
            elseif self.SelectedProperty and not TargetSelf then
                self.SelectedProperty = nil
                return true
            end
        elseif self.EditMode == "Add" then
            if Trace.Hit and not Trace.HitSky then
                Planes[#Planes + 1] = {Trace.HitPos, Trace.HitNormal}
                if #Planes ~= 6 then
                    return true
                end
                local SX, SY, SZ = GetPlanesIntersection({Planes[1], Planes[2], Planes[3]})
                local EX, EY, EZ = GetPlanesIntersection({Planes[4], Planes[5], Planes[6]})
                if not SX or not SY or not SZ or not EX or not EY or not EZ then
                    Notify("Box invalid", true)
                    Planes = {}
                    self.EditMode = "Select"
                    return false
                end
                local Start, End = Vector(SX, SY, SZ), Vector(EX, EY, EZ)
                OrderVectors(Start, End)
                if Start:Distance(End) < 10 then
                    Notify("Box too small", true)
                    Planes = {}
                    self.EditMode = "Select"
                    return false
                end
                for _, v in pairs(Properties.GetAll()) do
                    local NewStart, NewEnd = Vector(v.Start), Vector(v.End)
                    OrderVectors(NewStart, NewEnd)
                    if NewStart:Distance(Start) < 10 and NewEnd:Distance(End) < 10 then
                        Notify("Box already exists", true)
                        Planes = {}
                        self.EditMode = "Select"
                        return false
                    end
                end
                local Property = Properties.Add(table.Copy(PropertyDataFormat))
                Properties.UpdateVariable(Property, "Position", {Start, End})
                self.SelectedProperty = Property
                Notify("Property created", false)
                Planes = {}
                self.EditMode = "Select"
                return true
            end
        elseif self.EditMode == "Door" then
            if Trace.Entity and Trace.Entity:isDoor() and not table.HasValue(Properties.GetVariable(self.SelectedProperty, "Doors", {}), Trace.Entity) then
                Properties.InsertTableVariable(self.SelectedProperty, "Doors", Trace.Entity)
                return true
            end
        elseif self.EditMode == "Camera" then
            Properties.InsertTableVariable(self.SelectedProperty, "Cameras", {Trace.StartPos, Trace.Normal:Angle()})
            Plr:GetActiveWeapon():DoShootEffect(Trace.StartPos, Trace.Normal, nil, 1, IsFirstTimePredicted())
        elseif self.EditMode == "Expand" then
            if Properties.Exists(self.SelectedProperty) then
                local v = Properties.Get(self.SelectedProperty)
                local Pos = (v.Start + v.End) / 2
                local MinS = Vector(math.min(Pos.x - v.Start.x, Pos.x - v.End.x), math.min(Pos.y - v.Start.y, Pos.y - v.End.y), math.min(Pos.z - v.Start.z, Pos.z - v.End.z))
                local MaxS = Vector(math.max(Pos.x - v.Start.x, Pos.x - v.End.x), math.max(Pos.y - v.Start.y, Pos.y - v.End.y), math.max(Pos.z - v.Start.z, Pos.z - v.End.z))
                local HitPos, HitNormal = util.IntersectRayWithOBB(Trace.StartPos, Trace.Normal * 10000, Pos, Angle(), MinS, MaxS)
                local InBox = Trace.StartPos:WithinAABox(v.Start - Vector(20, 20, 20), v.End + Vector(20, 20, 20))
                if HitPos and not InBox then
                    Face = GetFaceFromNormal(HitNormal)
                    Plr:GetActiveWeapon():DoShootEffect(HitPos, HitNormal, nil, 1, IsFirstTimePredicted())
                    return false
                end
                local Menu = DermaMenu()
                for i, _ in pairs(Normals) do
                    Menu:AddOption(i, function()
                        Face = i
                    end)
                end
                Menu:AddOption("Close", function() end)
                Menu:Open()
                Menu:SetPos(gui.MousePos())
            end
        elseif self.EditMode == "Node" then
            if Properties.Exists(self.SelectedProperty) then
                local v = Properties.Get(self.SelectedProperty)
                local NewStart, NewEnd = Vector(v.Start), Vector(v.End)
                OrderVectors(NewStart, NewEnd)
                local InBox = Trace.HitPos:WithinAABox(NewStart, NewEnd)
                if InBox then
                    Properties.InsertTableVariable(self.SelectedProperty, "Nodes", {Trace.HitPos, Trace.HitNormal})
                    return true
                end
            end
        end
        return false
    end

    function TOOL:RightClick(Trace)
        if not IsFirstTimePredicted() then
            return
        end
        if self.EditMode == "Select" then
            local Menu = DermaMenu()
            for i, v in pairs(Properties.GetAll()) do
                Menu:AddOption(v.Name, function()
                    self.SelectedProperty = i
                end)
            end
            Menu:AddOption("Close", function() end)
            Menu:Open()
            Menu:SetPos(gui.MousePos())
        elseif self.EditMode == "Add" then
            self.EditMode = "Select"
            Planes = {}
            return true
        elseif self.EditMode == "Door" then
            if Trace.Entity and Trace.Entity:isDoor() and table.HasValue(Properties.GetVariable(self.SelectedProperty, "Doors", {}), Trace.Entity) then
                for i, v in pairs(Properties.GetVariable(self.SelectedProperty, "Doors")) do
                    if v == Trace.Entity then
                        Properties.UpdateTableVariable(self.SelectedProperty, "Doors", i, nil)
                    end
                end
                return true
            end
        elseif self.EditMode == "Camera" then
            local Closest, ClosestDist, ClosestPos, ClosestNormal
            for _, v in pairs(Properties.GetAll()) do
                for i, x in pairs(v.Cameras) do
                    local HitPos, HitNormal = util.IntersectRayWithOBB(Trace.StartPos, Trace.Normal * 10000, x[1], x[2], -Vector(15, 15, 15), Vector(15, 15, 15))
                    if HitPos and (not Closest or (Trace.StartPos - HitPos):Length() < ClosestDist) then
                        Closest, ClosestDist, ClosestPos, ClosestNormal = i, (Trace.StartPos - HitPos):Length(), HitPos, HitNormal
                    end
                end
            end
            if Closest and not util.TraceLine({start = Trace.StartPos, endpos = ClosestPos, filter = Plr}).Hit then
                for i, _ in pairs(Properties.GetVariable(self.SelectedProperty, "Cameras")) do
                    if i == Closest then
                        Properties.UpdateTableVariable(self.SelectedProperty, "Cameras", i, nil)
                    end
                end
                Plr:GetActiveWeapon():DoShootEffect(ClosestPos, ClosestNormal, nil, 1, IsFirstTimePredicted())
            end
        elseif self.EditMode == "Expand" then
            if Face and Properties.Exists(self.SelectedProperty) then
                local v = Properties.Get(self.SelectedProperty)
                local Pos = (v.Start + v.End) / 2
                local NewStart, NewEnd = Vector(v.Start), Vector(v.End)
                local MaxS = Vector(math.max(Pos.x - v.Start.x, Pos.x - v.End.x), math.max(Pos.y - v.Start.y, Pos.y - v.End.y), math.max(Pos.z - v.Start.z, Pos.z - v.End.z))
                local Normal = GetFaceNormals(Face)
                local Position = Pos + MaxS * Normal
                local Difference = Position * Normal - Trace.HitPos * Normal
                if Normal.x ~= 0 then
                    if math.Round(NewStart.x) == math.Round(Position.x) then
                        NewStart = NewStart - Difference * Normal.x
                    else
                        NewEnd = NewEnd - Difference * Normal.x
                    end
                elseif Normal.y ~= 0 then
                    if math.Round(NewStart.y) == math.Round(Position.y) then
                        NewStart = NewStart - Difference * Normal.y
                    else
                        NewEnd = NewEnd - Difference * Normal.y
                    end
                else
                    if math.Round(NewStart.z) == math.Round(Position.z) then
                        NewStart = NewStart - Difference * Normal.z
                    else
                        NewEnd = NewEnd - Difference * Normal.z
                    end
                end
                Properties.UpdateVariable(self.SelectedProperty, "Position", {NewStart, NewEnd})
                return true
            end
        elseif self.EditMode == "Node" then
            local Closest, ClosestDist, ClosestPos, ClosestNormal
            for _, v in pairs(Properties.GetAll()) do
                for i, x in pairs(v.Nodes) do
                    local HitPos, HitNormal = util.IntersectRayWithOBB(Trace.StartPos, Trace.Normal * 10000, x[1], x[2]:Angle(), -Vector(15, 15, 15), Vector(15, 15, 15))
                    if HitPos and (not Closest or (Trace.StartPos - HitPos):Length() < ClosestDist) then
                        Closest, ClosestDist, ClosestPos, ClosestNormal = i, (Trace.StartPos - HitPos):Length(), HitPos, HitNormal
                    end
                end
            end
            if Closest and not util.TraceLine({start = Trace.StartPos, endpos = ClosestPos, filter = Plr}).Hit then
                for i, _ in pairs(Properties.GetVariable(self.SelectedProperty, "Nodes")) do
                    if i == Closest then
                        Properties.UpdateTableVariable(self.SelectedProperty, "Nodes", i, nil)
                    end
                end
                Plr:GetActiveWeapon():DoShootEffect(ClosestPos, ClosestNormal, nil, 1, IsFirstTimePredicted())
            end
        end
        return false
    end

    function TOOL:Reload()
        if not IsFirstTimePredicted() or not Properties.Exists(self.SelectedProperty) then
            return
        end
        local StartSelection = self.SelectedProperty

        local Frame = vgui.Create("DFrame")
        Frame:SetSize(500, 700)
        Frame:Center()
        Frame:SetTitle("Editing property " .. Properties.GetVariable(StartSelection, "Name"))
        Frame:SetDraggable(true)
        Frame:MakePopup()

        local function DoCheck()
            if not Properties.Exists(StartSelection) or StartSelection ~= self.SelectedProperty then
                Frame:Remove()
            end
        end

        local PropertyPanel = vgui.Create("DProperties", Frame)
        PropertyPanel:Dock(FILL)

        local Container = Properties.GetVariable(StartSelection, "Container")
        local Stage = "Data"
        for _, v in pairs(PropertyDataFormatView) do
            if Container and (v == "Price" or v == "Rent" or v == "Business") then
                continue
            end
            if v:upper() == v then
                Stage = v:lower():gsub("^%l", string.upper)
                continue
            end
            local Type = type(PropertyDataFormat[v])
            local New = PropertyPanel:CreateRow(Stage, v)
            New:Setup(Type == "boolean" and "Boolean" or "Generic", {waitforenter = true})
            if Type == "string" then
                local Text1 = New:GetChildren()[2]:GetChildren()[1]:GetChildren()[1]
                function Text1:OnLoseFocus()
                    self:OnValueChange(self:GetText())
                end
            elseif Type  == "number" then
                local Text1 = New:GetChildren()[2]:GetChildren()[1]:GetChildren()[1]
                Text1:SetNumeric(true)
                Text1.CheckNumeric = CheckNumericCustom
                function Text1:OnValueChange(Val)
                    if self:GetText() == "" then
                        self:SetText(0)
                    end
                    self:GetParent():ValueChanged(Val)
                end
                function Text1:OnLoseFocus()
                    self:OnValueChange(self:GetText())
                end
            elseif Type  == "Vector" then
                local Panel = New:GetChildren()[2]:GetChildren()[1]
                local Text1 = Panel:GetChildren()[1]
                Text1:SetNumeric(true)
                Text1:SetWide(255 / 3)
                Text1:Dock(LEFT)
                Text1.CheckNumeric = CheckNumericCustom
                local Text2 = Panel:Add("DTextEntry")
                Text2:SetNumeric(true)
                Text2:Dock(FILL)
                Text2:SetPaintBackground(false)
                Text2.CheckNumeric = CheckNumericCustom
                local Text3 = Panel:Add("DTextEntry")
                Text3:SetNumeric(true)
                Text3:SetWide(255 / 3)
                Text3:Dock(RIGHT)
                Text3:SetPaintBackground(false)
                Text3.CheckNumeric = CheckNumericCustom

                function New:SetValue(Val)
                    Text1:SetValue(math.Round(Val.x))
                    Text2:SetValue(math.Round(Val.y))
                    Text3:SetValue(math.Round(Val.z))
                end
            end
            New:SetValue(Properties.GetVariable(StartSelection, v))
            if Type  == "Vector" then
                local Panel = New:GetChildren()[2]:GetChildren()[1]
                local Text1 = Panel:GetChildren()[1]
                local Text2 = Panel:GetChildren()[2]
                local Text3 = Panel:GetChildren()[3]

            	function Panel.IsEditing()
            		return Text1:IsEditing() or Text2:IsEditing() or Text3:IsEditing()
            	end

                function Panel:ValueChanged(x, y, z)
                    if Text1:GetText() == "" then
                        Text1:SetText(0)
                    end
                    if Text2:GetText() == "" then
                        Text2:SetText(0)
                    end
                    if Text3:GetText() == "" then
                        Text3:SetText(0)
                    end
                    self.m_pRow:DataChanged(Vector(x, y, z))
                end

            	function Text1.OnValueChange()
            		Panel:ValueChanged(Text1:GetValue(), Text2:GetValue(), Text3:GetValue())
            	end
            	function Text2.OnValueChange()
            		Panel:ValueChanged(Text1:GetValue(), Text2:GetValue(), Text3:GetValue())
            	end
            	function Text3.OnValueChange()
            		Panel:ValueChanged(Text1:GetValue(), Text2:GetValue(), Text3:GetValue())
            	end
                function Text1:OnLoseFocus()
                    self:OnValueChange(self:GetText())
                end
                function Text2:OnLoseFocus()
                    self:OnValueChange(self:GetText())
                end
                function Text3:OnLoseFocus()
                    self:OnValueChange(self:GetText())
                end
            end
            New.DataChanged = function(_, Val)
                DoCheck()
                if Type == "number" then
                    Val = tonumber(Val)
                elseif Type == "boolean" then
                    Val = tobool(Val)
                end
                Properties.UpdateVariable(StartSelection, v, Val)
                if v == "Name" then
                    Frame:SetTitle("Editing property " .. Val)
                end
            end
        end
        local RemoveButton = vgui.Create("DButton", Frame)
        RemoveButton:Dock(BOTTOM)
        RemoveButton:SetText("Remove")
        function RemoveButton:DoClick()
            DoCheck()
            Properties.Remove(StartSelection)
            Frame:Remove()
        end
        if Container then
            local MirrorOnParent = vgui.Create("DButton", Frame)
            MirrorOnParent:Dock(BOTTOM)
            MirrorOnParent:SetText("Mirror On Parent")

            function MirrorOnParent.DoClick()
                local ContainerProperty = Properties.Get(Container)
                if not ContainerProperty then
                    return
                end
                local OldProperty = Properties.Get(StartSelection)
                local ContainerPos = (ContainerProperty.Start + ContainerProperty.End) / 2
                local OldPos = (OldProperty.Start + OldProperty.End) / 2

                local MirrorPos
                local Offset = ContainerPos - OldPos
                if math.abs(math.abs(Offset.x) - math.abs(Offset.y)) < math.abs(Offset.x + Offset.y) * 0.2 then
                    MirrorPos = Vector(ContainerPos.x, ContainerPos.y, 0)
                elseif math.abs(Offset.x) >= math.abs(Offset.y) then
                    MirrorPos = Vector(ContainerPos.x, 0, 0)
                else
                    MirrorPos = Vector(0, ContainerPos.y, 0)
                end

                local MirrorOffset
                for i, v in pairs(OldProperty.Doors) do
                    local NewPos = MirrorPosition(v:GetPos(), MirrorPos)
                    local Ent = GetSimilarEnt(v, NewPos, 30)
                    if Ent then
                        MirrorOffset = MirrorOffset and ((MirrorOffset + Ent:GetPos() - NewPos) / 2) or Ent:GetPos() - NewPos
                    end
                end

                local NewStart = MirrorPosition(OldProperty.Start, MirrorPos, MirrorOffset)
                local NewEnd = MirrorPosition(OldProperty.End, MirrorPos, MirrorOffset)

                for _, v in pairs(Properties.GetAll()) do
                    if NewEnd == NewStart and v.End == NewEnd then
                        return
                    end
                end

                local Property = Properties.Add(table.Copy(PropertyDataFormat))
                local NewName = {}
                for i, v in pairs(string.Explode(" ", OldProperty.Name)) do
                    if tonumber(v) then
                        NewName[i] = tonumber(v) + 1
                    else
                        NewName[i] = v
                    end
                end
                Properties.UpdateVariable(Property, "Name", table.concat(NewName, " "))
                Properties.UpdateVariable(Property, "Position", {NewStart, NewEnd})
                Properties.UpdateVariable(Property, "Price", OldProperty.Price)
                Properties.UpdateVariable(Property, "Business", OldProperty.Business)

                local NewCameras = {}
                for i, v in pairs(OldProperty.Cameras) do
                    local NewPos = MirrorPosition(v[1], MirrorPos, MirrorOffset)
                    local NewAng = Angle(v[2])
                    if MirrorPos.x ~= 0 and MirrorPos.y ~= 0 then
                        NewAng:RotateAroundAxis(Vector(0, 0, 1), 180)
                    elseif MirrorPos.x ~= 0 then
                        NewAng:RotateAroundAxis(Vector(0, 0, 1), 180)
                        NewAng.y = -NewAng.y
                    else
                        NewAng.y = -NewAng.y
                    end
                    NewCameras[i] = {NewPos, NewAng}
                end
                Properties.UpdateVariable(Property, "Cameras", NewCameras)

                local NewDoors = {}
                for i, v in pairs(OldProperty.Doors) do
                    NewDoors[i] = GetSimilarEnt(v, MirrorPosition(v:GetPos(), MirrorPos, MirrorOffset), 10)
                end
                Properties.UpdateVariable(Property, "Doors", NewDoors)

                if self.SelectNewProperty then
                    self.SelectedProperty = Property
                    Planes = {}
                    self.EditMode = "Select"
                    Frame:Remove()
                end
            end

            local DuplicateUp = vgui.Create("DButton", Frame)
            DuplicateUp:Dock(BOTTOM)
            DuplicateUp:SetText("Duplicate 1 floor up")
            function DuplicateUp.DoClick()
                local OldProperty = Properties.Get(StartSelection)
                local UpHeight
                for i, v in pairs(OldProperty.Doors) do
                    local NewPos = v:GetPos() + Vector(0, 0, 140)
                    local Ent = GetSimilarEnt(v, NewPos, 30)
                    if Ent then
                        UpHeight = UpHeight and ((UpHeight + Ent:GetPos() - v:GetPos()) / 2) or Ent:GetPos() - v:GetPos()
                    end
                end
                if not UpHeight then
                    return
                end

                for _, v in pairs(Properties.GetAll()) do
                    if v.Start == OldProperty.Start + UpHeight and v.End == OldProperty.End + UpHeight then
                        return
                    end
                end
                local Property = Properties.Add(table.Copy(PropertyDataFormat))
                local NewName = {}
                for i, v in pairs(string.Explode(" ", OldProperty.Name)) do
                    if tonumber(v) then
                        NewName[i] = tonumber(v) + 2
                    else
                        NewName[i] = v
                    end
                end
                Properties.UpdateVariable(Property, "Name", table.concat(NewName, " "))
                Properties.UpdateVariable(Property, "Position", {OldProperty.Start + UpHeight, OldProperty.End + UpHeight})
                Properties.UpdateVariable(Property, "Price", OldProperty.Price)
                Properties.UpdateVariable(Property, "Business", OldProperty.Business)

                local NewCameras = {}
                for i, v in pairs(OldProperty.Cameras) do
                    NewCameras[i] = {v[1] + UpHeight, v[2]}
                end
                Properties.UpdateVariable(Property, "Cameras", NewCameras)

                local NewDoors = {}
                for i, v in pairs(OldProperty.Doors) do
                    NewDoors[i] = GetSimilarEnt(v, v:GetPos() + UpHeight, 10)
                end
                Properties.UpdateVariable(Property, "Doors", NewDoors)

                if self.SelectNewProperty then
                    self.SelectedProperty = Property
                    Planes = {}
                    self.EditMode = "Select"
                    Frame:Remove()
                end
            end

            self.SelectNewProperty = self.SelectNewProperty ~= nil and self.SelectNewProperty or true
            local CheckBox = vgui.Create("DCheckBoxLabel", Frame)
            CheckBox:Dock(BOTTOM)
            CheckBox:SetText("Select new")
            CheckBox:SetValue(self.SelectNewProperty)
            function CheckBox.OnChange(_, Val)
            	self.SelectNewProperty = Val
            end
        end
    end

    TOOL.Initialized = false
    function TOOL:Think()
        if not self.Initialized then
            self.Initialized = true
            self.EditMode = self.EditMode or "Select"
            concommand.Add("propertydevsetmode", function(Ply, Cmd, Args)
                if #Args == 1 then
                    if self.EditMode == "Add" then
                        Planes = {}
                    elseif self.EditMode == "Expand" then
                        Face = nil
                    end
                    if Args[1]:lower() == "select" then
                        self.EditMode = "Select"
                    elseif Args[1]:lower() == "add" then
                        self.EditMode = "Add"
                    elseif Args[1]:lower() == "door" then
                        self.EditMode = "Door"
                    elseif Args[1]:lower() == "camera" then
                        self.EditMode = "Camera"
                    elseif Args[1]:lower() == "expand" then
                        self.EditMode = "Expand"
                    elseif Args[1]:lower() == "node" then
                        self.EditMode = "Node"
                    end
                end
            end)
        end
    end

    function TOOL:DrawHUD()
        if self.EditMode == "Add" then
            draw.SimpleTextOutlined("Press left mouse to set position " .. (#Planes < 3 and 1 or 2) .. " plane " .. (#Planes % 3 + 1), "DermaLarge", ScrW() / 2, ScrH() * 0.7, Color(90, 200, 90, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))
            draw.SimpleTextOutlined("Right click to cancel", "DermaLarge", ScrW() / 2, ScrH() * 0.7 + 50, Color(90, 200, 90, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))
        end
    end

    function TOOL:DrawToolScreen(w, h)
    	surface.SetDrawColor(Color(20, 20, 20, 255))
        surface.DrawRect(0, 0, w, h)
    	draw.SimpleText("Property Dev", "DermaLarge", w / 2, h * 0.3, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    	draw.SimpleText("Mode: " .. self.EditMode, "DermaLarge", w / 2, h * 0.45, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    	draw.SimpleText("Selection:", "DermaLarge", w / 2, h * 0.6, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    	draw.SimpleText(self.SelectedProperty and Properties.GetVariable(self.SelectedProperty, "Name") or "None", "DermaLarge", w / 2, h * 0.7, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if Properties.Exists(self.SelectedProperty) then
            local Start, End = Properties.GetVariable(self.SelectedProperty, "Start"), Properties.GetVariable(self.SelectedProperty, "End")
            local Height = math.Round(math.abs(Start.z - End.z) / 160)
            local XFeet, YFeet = math.Round(math.abs(Start.x - End.x) / 16), math.Round(math.abs(Start.y - End.y) / 16)
        	draw.SimpleText(Height .. "   " .. XFeet * YFeet, "DermaLarge", w / 2, h * 0.85, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local CameraModels = {}
    local CameraKey = 1
    local function GetCameraModel(i)
    	if not CameraModels[i] then
    		CameraModels[i] = ClientsideModel("models/dav0r/camera.mdl", RENDERGROUP_OPAQUE)
    		CameraModels[i]:SetModelScale(2)
    	end
    	return CameraModels[i]
    end

    local WhiteMaterial = CreateMaterial("WhiteMaterial", "UnlitGeneric", {
    	["$basetexture"] = "models/debug/debugwhite",
    	["$ignorez"] = 1
    })
    hook.Add("PostDrawTranslucentRenderables", "PropertyDevDrawWorld", function()
        if not Plr.GetActiveWeapon or not Plr:GetActiveWeapon() or Plr:GetActiveWeapon().PrintName ~= "Tool Gun" or Plr:GetActiveWeapon():GetMode() ~= "propertydev" then
            return
        end
        local Tool = Plr:GetTool("propertydev")
        if Tool.EditMode == "Add" then
        	local tr = util.GetPlayerTrace(Plr)
        	tr.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS, CONTENTS_GRATE, CONTENTS_AUX)
        	local Trace = util.TraceLine(tr)
            local EPlanes = table.Copy(Planes)
            EPlanes[#EPlanes + 1] = {Trace.HitPos, Trace.HitNormal}
            for _, v in pairs(EPlanes) do
                local Text
                local Normal = Vector(math.Round(math.abs(v[2].x)), math.Round(math.abs(v[2].y)), math.Round(math.abs(v[2].z)))
                if Normal == Vector(1, 0, 0) then
                    Text = "X"
                elseif Normal == Vector(0, 1, 0) then
                    Text = "Y"
                elseif Normal == Vector(0, 0, 1) then
                    Text = "Z"
                end
                if Text then
                    local Col = Text == "X" and Color(255, 0, 0, 255) or Text == "Y" and Color(0, 255, 0, 255) or Color(0, 0, 255, 255)
                    render.SetColorMaterial()
                    render.DrawQuadEasy(v[1] + v[2] * 0.2, v[2], 30, 30, Color(Col.r * 0.8, Col.g * 0.8, Col.b * 0.8, 150), 0)
                    local Ang = v[2]:Angle()
                    Ang:RotateAroundAxis(Ang:Forward(), 90)
                    Ang:RotateAroundAxis(Ang:Right(), -90)
                    cam.Start3D2D(v[1] + v[2] * 0.2, Ang, 1)
                        draw.SimpleTextOutlined(Text, "DermaLarge", 0, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 150))
                    cam.End3D2D()
                end
            end
            for i = 1, 2 do
                local NewPlanes = (i == 2 and #EPlanes > 3 and {EPlanes[4], EPlanes[5], EPlanes[6]}) or (i == 1 and {EPlanes[1], EPlanes[2], EPlanes[3]})
                if not NewPlanes then
                    continue
                end
                local AX, AY, AZ
                for _, v in pairs(NewPlanes) do
                    if not AX then
                        AX, AY, AZ = v[1].x, v[1].y, v[1].z
                    else
                        AX, AY, AZ = (AX + v[1].x) / 2, (AY + v[1].y) / 2, (AZ + v[1].z) / 2
                    end
                end
                local LineLength = 1000
                local X, Y, Z = GetPlanesIntersection(NewPlanes)
                render.SetColorMaterial()
                cam.IgnoreZ(true)
                    if Y and Z then
                        render.DrawBeam(Vector(AX - LineLength, Y, Z), Vector(AX + LineLength, Y, Z), 2, 0, 0, Color(255, 0, 0, 255))
                    end
                    if X and Z then
                        render.DrawBeam(Vector(X, AY - LineLength, Z), Vector(X, AY + LineLength, Z), 2, 0, 0, Color(0, 255, 0, 255))
                    end
                    if X and Y then
                        render.DrawBeam(Vector(X, Y, AZ - LineLength), Vector(X, Y, AZ + LineLength), 2, 0, 1, Color(0, 0, 255, 255))
                    end
                cam.IgnoreZ(false)
            end
        end
        for i, v in pairs(Properties.GetAll()) do
            local SelfSelected = Tool.SelectedProperty == i
            local Pos = (v.Start + v.End) / 2
            if LocalPlayer():EyePos():Distance(Pos) > 6000 then
                continue
            end
            local MinS = Vector(math.min(Pos.x - v.Start.x, Pos.x - v.End.x), math.min(Pos.y - v.Start.y, Pos.y - v.End.y), math.min(Pos.z - v.Start.z, Pos.z - v.End.z))
            local MaxS = Vector(math.max(Pos.x - v.Start.x, Pos.x - v.End.x), math.max(Pos.y - v.Start.y, Pos.y - v.End.y), math.max(Pos.z - v.Start.z, Pos.z - v.End.z))
            render.SetColorMaterial()
            render.DrawWireframeBox(Pos, Angle(), MinS, MaxS, SelfSelected and Color(0, 150, 0, 150) or Color(255, 0, 0, 150), not SelfSelected)
            render.DrawBox(Pos, Angle(), MinS - Vector(0.5, 0.5, 0.5), MaxS + Vector(0.5, 0.5, 0.5), SelfSelected and Color(0, 150, 0, 100) or Color(255, 0, 0, 40), false)
            render.DrawBox(Pos, Angle(), MaxS - Vector(0.5, 0.5, 0.5), MinS + Vector(0.5, 0.5, 0.5), SelfSelected and Color(0, 150, 0, 60) or Color(255, 0, 0, 20), false)
            if not SelfSelected then
                continue
            end
            if Face then
                local Normal = GetFaceNormals(Face)
                local Position = Pos + MaxS * Normal
                local Size = GetFaceSize(Face, MaxS * 2)
                render.DrawQuadEasy(Position, Normal, Size[1], Size[2], Color(0, 0, 255, 150), 0)
                render.DrawQuadEasy(Position, -Normal, Size[1], Size[2], Color(0, 0, 255, 100), 0)
            end
            if #v.Nodes > 0 then
                render.SetColorMaterial()
                for _, x in pairs(v.Nodes) do
                    render.DrawQuadEasy(x[1], x[2], 30, 30, Color(255, 255, 255, 255), 0)
                    render.DrawQuadEasy(x[1], -x[2], 30, 30, Color(80, 80, 80, 255), 0)
                end
            end
            if #v.Doors > 0 then
                render.MaterialOverride(WhiteMaterial)
                render.SetBlend(0.3)
                for _, x in pairs(v.Doors) do
                    if not IsValid(x) then
                        continue
                    end
                    local NewStart, NewEnd = Vector(v.Start), Vector(v.End)
                    OrderVectors(NewStart, NewEnd)
                    local InBox = x:GetPos():WithinAABox(NewStart - Vector(20, 20, 20), NewEnd + Vector(20, 20, 20))
                    render.SetColorModulation(InBox and 0 or 1, 1, 0)
                    cam.Start3D()
                        x:DrawModel()
                    cam.End3D()
                    if not InBox then
                        render.DrawBeam(Pos + (Pos - x:GetPos()):GetNormal() * -math.min(v.Start:Distance(v.End), v.Start:Distance(x:GetPos())) * 0.3, x:GetPos(), 10, 0, 0, Color(255, 255, 0, 255))
                    end
                end
                render.SetColorModulation(1, 1, 1)
                render.SetBlend(1)
                render.MaterialOverride()
            end
            if #v.Cameras > 0 then
                CameraKey = 1
                render.SetBlend(0.3)
                render.MaterialOverride(WhiteMaterial)
                for _, x in pairs(v.Cameras) do
                    local NewStart, NewEnd = Vector(v.Start), Vector(v.End)
                    OrderVectors(NewStart, NewEnd)
                    local InBox = x[1]:WithinAABox(NewStart - Vector(20, 20, 20), NewEnd + Vector(20, 20, 20))
                    render.SetColorModulation(InBox and 0 or 1 or 1, 1, 0)
                	render.Model({model = "models/dav0r/camera.mdl", pos = x[1], angle = x[2]}, GetCameraModel(CameraKey))
                    if not InBox then
                        render.DrawBeam(Pos + (Pos - x[1]):GetNormal() * -math.min(v.Start:Distance(v.End), v.Start:Distance(x[1])) * 0.3, x[1], 10, 0, 0, Color(255, 255, 0, 255))
                    end
                	CameraKey = CameraKey + 1
                end
                render.SetColorModulation(1, 1, 1)
                render.SetBlend(1)
                render.MaterialOverride()
            end
        end
        cam.IgnoreZ(true)
            for i, v in pairs(Properties.GetAll()) do
                local SelfSelected = Tool.SelectedProperty == i
                local Pos = (v.Start + v.End) / 2
                if LocalPlayer():EyePos():Distance(Pos) > 2000 then
                    continue
                end
                local Ang = (LocalPlayer():EyePos() - Pos):Angle()
                Ang:RotateAroundAxis(Ang:Forward(), 90)
                Ang:RotateAroundAxis(Ang:Right(), 90)
                if (LocalPlayer():EyePos() - Pos):Dot(Ang:Up()) < 0 then
                    Ang:RotateAroundAxis(Ang:Right(), 180)
                end
                local IsContainer = false
                for _, x in pairs(Properties.GetAll()) do
                    if x.Container == i then
                        IsContainer = true
                        break
                    end
                end
                surface.SetFont("DermaLarge")
                cam.Start3D2D(Pos, Ang, v.Container and 0.4 or 0.7)
                    local _, Height = surface.GetTextSize("Text")
                    local Text = {
                        v.Name,
                        v.Container and Properties.GetVariable(v.Container, "Name", "nil") or (v.Price > 0 or v.Rent > 0) and (v.Price > 0 and "Price: " .. DarkRP.formatMoney(v.Price) .. (v.Rent > 0 and "  " or "") or "") .. (v.Rent > 0 and "Rent: " .. DarkRP.formatMoney(v.Rent) or "") or "Unownable",
                        IsContainer and "Apartment Building" or v.Container and "Apartment" or (v.Price > 0 or v.Rent > 0) and (v.Business and "Business" or "House") or nil
                    }
                    local Col = SelfSelected and Color(0, 255, 0, 255) or Color(255, 0, 0, 255)
        			surface.SetTextColor(Color(0, 0, 0, 255))
                    for x, y in pairs(Text) do
        			    EfficientText(y, -1, -1 + (x - 1) * Height - ((#Text - 1) * Height) / 2, true)
            		    EfficientText(y, 1, 1 + (x - 1) * Height - ((#Text - 1) * Height) / 2, true)
        			    EfficientText(y, -1, 1 + (x - 1) * Height - ((#Text - 1) * Height) / 2, true)
            		    EfficientText(y, 1, -1 + (x - 1) * Height - ((#Text - 1) * Height) / 2, true)
                    end
        			surface.SetTextColor(Col)
                    for x, y in pairs(Text) do
        			    EfficientText(y, 0, (x - 1) * Height - ((#Text - 1) * Height) / 2, true)
                    end
                cam.End3D2D()
            end
        cam.IgnoreZ(false)
    end)

    language.Add("tool.propertydev.name", "Property Dev")
    language.Add("tool.propertydev.desc", "Add, edit and remove properties")
    language.Add("tool.propertydev.left", "Run mode")
    language.Add("tool.propertydev.right", "Run mode secondary")
    language.Add("tool.propertydev.reload", "Edit properties of selection")
end

function TOOL.BuildCPanel(Panel)
    Panel:AddControl("Button", {
        Label = "Mode: Selection",
        Command = "propertydevsetmode select"
    })
    Panel:AddControl("Button", {
        Label = "Mode: Add",
        Command = "propertydevsetmode add"
    })
    Panel:AddControl("Button", {
        Label = "Mode: Door",
        Command = "propertydevsetmode door"
    })
    Panel:AddControl("Button", {
        Label = "Mode: Camera",
        Command = "propertydevsetmode camera"
    })
    Panel:AddControl("Button", {
        Label = "Mode: Expand",
        Command = "propertydevsetmode expand"
    })
    Panel:AddControl("Button", {
        Label = "Mode: Node",
        Command = "propertydevsetmode node"
    })
end
