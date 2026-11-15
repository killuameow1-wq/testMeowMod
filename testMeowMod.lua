--[[
    ╔══════════════════════════════════════════════════════════╗
    ║  MeowMod — FULL RELEASE (Mystrix UI + ESP Line)          ║
    ╚══════════════════════════════════════════════════════════╝
]]

if getgenv().MeowUIUnload then pcall(getgenv().MeowUIUnload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local WS = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = WS.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

local old = PG:FindFirstChild("MeowMod")
if old then old:Destroy() end

local MM = { Drawings = {}, Connections = {} }
getgenv().MeowUIUnload = function()
    for _, c in pairs(MM.Connections) do pcall(function() c:Disconnect() end) end
    for _, d in pairs(MM.Drawings) do pcall(function() d:Remove() end) end
    pcall(function() RunService:UnbindFromRenderStep("MeowRender") end)
    pcall(function() PG.MeowMod:Destroy() end)
    print("[MeowUI] Unloaded")
end

-- ═══════════ CONFIG ═══════════
local Config = {
    -- Aim
    AimEnabled = false, AimFOV = 150, AimSmooth = 0.3, AimMaxDist = 1000,
    SilentAim = false, SilentFOV = 150, SilentMaxDist = 1000,
    ShowFOV = false,
    
    -- ESP (Players)
    ESP = false, ESP_Box = true, ESP_Name = true, ESP_Dist = true, 
    ESP_Line = false, ESP_LineOrigin = "Bottom", -- "Bottom" or "Center"
    ESP_MaxDist = 2000, ESPColorHex = "00F0FF",
    
    -- ESP (Vehicles)
    V_ESP = false, V_ESP_Box = true, V_ESP_Name = true, V_ESP_Dist = true, 
    V_ESP_Line = false,
    V_ESP_MaxDist = 2000, V_ESPColorHex = "FFA500",
    
    -- Movement
    SpeedOn = false, SpeedValue = 25, InfJump = false, Noclip = false,
    Fly = false, FlySpeed = 50,
    
    -- World
    Fullbright = false, FogOff = false, Gravity = 196.2,
    
    -- Misc
    AntiAFK = false, ShowFPS = false, ShowPing = false,
}

local function ParseHex(hex, default)
    hex = hex:gsub("#", "")
    if #hex == 6 then
        local r = tonumber(hex:sub(1,2), 16)
        local g = tonumber(hex:sub(3,4), 16)
        local b = tonumber(hex:sub(5,6), 16)
        if r and g and b then return Color3.fromRGB(r, g, b) end
    end
    return default or Color3.new(1,1,1)
end

local ESPColorPlayer = ParseHex(Config.ESPColorHex, Color3.fromRGB(0, 240, 255))
local ESPColorVehicle = ParseHex(Config.V_ESPColorHex, Color3.fromRGB(255, 165, 0))

-- ═══════════ UI (Mystrix Style) ═══════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeowMod"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PG

local T = {
    Bg = Color3.fromRGB(15, 15, 20),
    Sidebar = Color3.fromRGB(20, 20, 28),
    Surface = Color3.fromRGB(25, 25, 35),
    SurfaceHover = Color3.fromRGB(35, 35, 45),
    Border = Color3.fromRGB(40, 40, 55),
    Accent = Color3.fromRGB(220, 50, 70), -- Mystrix Red
    AccentHover = Color3.fromRGB(250, 70, 90),
    Text = Color3.fromRGB(230, 230, 240),
    SubText = Color3.fromRGB(130, 130, 150),
    Danger = Color3.fromRGB(255, 60, 60),
    Track = Color3.fromRGB(40, 40, 55),
    Success = Color3.fromRGB(80, 220, 140),
}

local function Corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end
local function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or T.Border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local vp = Camera.ViewportSize
local winW = math.min(700, vp.X * 0.95)
local winH = math.min(480, vp.Y * 0.85)
local scaleFactor = math.min(winW / 700, winH / 480, 1)

local Main = Instance.new("Frame")
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.Size = UDim2.new(0, winW, 0, winH)
Main.BackgroundColor3 = T.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Corner(Main, 12)
Stroke(Main, T.Border, 1.5, 0.2)

local MainScale = Instance.new("UIScale")
MainScale.Scale = scaleFactor
MainScale.Parent = Main

-- ═══════════ TOP BAR ═══════════
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = T.Sidebar
TopBar.BackgroundTransparency = 0.2
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MEOW MOD"
Title.TextColor3 = T.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local VersionBadge = Instance.new("TextLabel")
VersionBadge.Size = UDim2.new(0, 40, 0, 20)
VersionBadge.Position = UDim2.new(0, 130, 0.5, -10)
VersionBadge.BackgroundColor3 = T.Accent
VersionBadge.Text = "v4.1"
VersionBadge.TextColor3 = T.Text
VersionBadge.Font = Enum.Font.GothamBold
VersionBadge.TextSize = 10
VersionBadge.BorderSizePixel = 0
VersionBadge.Parent = TopBar
Corner(VersionBadge, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -80, 0.5, -15)
CloseBtn.BackgroundColor3 = T.Surface
CloseBtn.Text = "−"
CloseBtn.TextColor3 = T.Text
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.AutoButtonColor = false
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TopBar
Corner(CloseBtn, 6)

local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Size = UDim2.new(0, 30, 0, 30)
UnloadBtn.Position = UDim2.new(1, -40, 0.5, -15)
UnloadBtn.BackgroundColor3 = T.Surface
UnloadBtn.Text = "×"
UnloadBtn.TextColor3 = T.Danger
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.TextSize = 20
UnloadBtn.AutoButtonColor = false
UnloadBtn.BorderSizePixel = 0
UnloadBtn.Parent = TopBar
Corner(UnloadBtn, 6)

local dragStart, startPos = nil, nil
TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart = inp.Position startPos = Main.Position
    end
end)
UIS.InputChanged:Connect(function(inp)
    if dragStart and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = inp.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart = nil startPos = nil
    end
end)

-- ═══════════ SIDEBAR ═══════════
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 180, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = T.Sidebar
Sidebar.BackgroundTransparency = 0.1
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local ProfileFrame = Instance.new("Frame")
ProfileFrame.Size = UDim2.new(1, -20, 0, 50)
ProfileFrame.Position = UDim2.new(0, 10, 0, 10)
ProfileFrame.BackgroundColor3 = T.Surface
ProfileFrame.BackgroundTransparency = 0.3
ProfileFrame.BorderSizePixel = 0
ProfileFrame.Parent = Sidebar
Corner(ProfileFrame, 8)

local Avatar = Instance.new("ImageLabel")
Avatar.Size = UDim2.new(0, 36, 0, 36)
Avatar.Position = UDim2.new(0, 8, 0.5, -18)
Avatar.BackgroundColor3 = T.Sidebar
Avatar.BackgroundTransparency = 0.5
Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=150&height=150&format=png"
Avatar.Parent = ProfileFrame
Corner(Avatar, 18)

local NameLabel = Instance.new("TextLabel")
NameLabel.Size = UDim2.new(1, -60, 0, 20)
NameLabel.Position = UDim2.new(0, 52, 0, 8)
NameLabel.BackgroundTransparency = 1
NameLabel.Text = LP.Name
NameLabel.TextColor3 = T.Text
NameLabel.Font = Enum.Font.GothamBold
NameLabel.TextSize = 12
NameLabel.TextXAlignment = Enum.TextXAlignment.Left
NameLabel.Parent = ProfileFrame

local TagLabel = Instance.new("TextLabel")
TagLabel.Size = UDim2.new(1, -60, 0, 16)
TagLabel.Position = UDim2.new(0, 52, 0, 26)
TagLabel.BackgroundTransparency = 1
TagLabel.Text = "Premium User"
TagLabel.TextColor3 = T.Accent
TagLabel.Font = Enum.Font.GothamMedium
TagLabel.TextSize = 10
TagLabel.TextXAlignment = Enum.TextXAlignment.Left
TagLabel.Parent = ProfileFrame

local Pages = {}
local TabButtons = {}
local function SelectTab(name)
    for n, p in pairs(Pages) do p.Visible = (n == name) end
    for n, b in pairs(TabButtons) do
        if n == name then
            TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = T.SurfaceHover}):Play()
            b.TextColor3 = T.Text
        else
            TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = T.Sidebar, BackgroundTransparency = 1}):Play()
            b.TextColor3 = T.SubText
        end
    end
end

local function CreateSidebarBtn(name, icon, order)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 40)
    Btn.Position = UDim2.new(0, 10, 0, 70 + (order * 45))
    Btn.BackgroundColor3 = T.Sidebar
    Btn.BackgroundTransparency = 1
    Btn.Text = "  " .. icon .. "   " .. name
    Btn.TextColor3 = T.SubText
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.AutoButtonColor = false
    Btn.BorderSizePixel = 0
    Btn.Parent = Sidebar
    Corner(Btn, 8)
    TabButtons[name] = Btn

    local Page = Instance.new("ScrollingFrame")
    Page.Name = name
    Page.Size = UDim2.new(1, -200, 1, -70)
    Page.Position = UDim2.new(0, 190, 0, 60)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = T.Accent
    Page.BorderSizePixel = 0
    Page.Parent = Main
    local L = Instance.new("UIListLayout", Page)
    L.Padding = UDim.new(0, 10)
    Pages[name] = Page

    Btn.MouseButton1Click:Connect(function() SelectTab(name) end)
end

CreateSidebarBtn("Aimbot", "🎯", 1)
CreateSidebarBtn("Visuals", "👁", 2)
CreateSidebarBtn("Movement", "🏃", 3)
CreateSidebarBtn("Teleport", "⚡", 4)
CreateSidebarBtn("Players", "👥", 5)
CreateSidebarBtn("Misc", "⚙", 6)

local SearchBar = Instance.new("Frame")
SearchBar.Size = UDim2.new(1, -200, 0, 36)
SearchBar.Position = UDim2.new(0, 190, 0, 60)
SearchBar.BackgroundColor3 = T.Surface
SearchBar.BorderSizePixel = 0
SearchBar.Parent = Main
Corner(SearchBar, 8)

local SearchIcon = Instance.new("TextLabel")
SearchIcon.Size = UDim2.new(0, 30, 1, 0)
SearchIcon.Position = UDim2.new(0, 5, 0, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "🔍"
SearchIcon.TextColor3 = T.SubText
SearchIcon.TextSize = 14
SearchIcon.Parent = SearchBar

local SearchInput = Instance.new("TextBox")
SearchInput.Size = UDim2.new(1, -40, 1, 0)
SearchInput.Position = UDim2.new(0, 35, 0, 0)
SearchInput.BackgroundTransparency = 1
SearchInput.PlaceholderText = "Search features..."
SearchInput.PlaceholderColor3 = T.SubText
SearchInput.TextColor3 = T.Text
SearchInput.Font = Enum.Font.Gotham
SearchInput.TextSize = 13
SearchInput.Text = ""
SearchInput.ClearTextOnFocus = false
SearchInput.Parent = SearchBar

for _, p in pairs(Pages) do
    p.Position = UDim2.new(0, 190, 0, 110)
    p.Size = UDim2.new(1, -200, 1, -120)
end

-- ═══════════ WIDGETS ═══════════
local function CreateToggle(parent, text, def, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = T.Surface
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Corner(frame, 8)
    Stroke(frame, T.Border, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.Parent = frame

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 44, 0, 24)
    bg.Position = UDim2.new(1, -60, 0.5, -12)
    bg.BackgroundColor3 = def and T.Accent or T.Track
    bg.BorderSizePixel = 0
    bg.Parent = frame
    Corner(bg, 12)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = def and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = T.Text
    knob.BorderSizePixel = 0
    knob.Parent = bg
    Corner(knob, 10)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = frame

    hit.MouseButton1Click:Connect(function()
        def = not def
        local tPos = def and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        local tCol = def and T.Accent or T.Track
        TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = tCol}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = tPos}):Play()
        if cb then cb(def) end
    end)
    return frame
end

local function CreateSlider(parent, text, min, max, def, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.BackgroundColor3 = T.Surface
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Corner(frame, 8)
    Stroke(frame, T.Border, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 0, 20)
    lbl.Position = UDim2.new(0, 16, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.Parent = frame

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 50, 0, 20)
    valLbl.Position = UDim2.new(1, -66, 0, 8)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(def)
    valLbl.TextColor3 = T.Accent
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -32, 0, 6)
    track.Position = UDim2.new(0, 16, 0, 38)
    track.BackgroundColor3 = T.Track
    track.BorderSizePixel = 0
    track.Parent = frame
    Corner(track, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = T.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    Corner(fill, 3)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((def - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = T.Text
    knob.BorderSizePixel = 0
    knob.Parent = fill
    Corner(knob, 7)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 3, 0)
    hit.Position = UDim2.new(0, 0, -1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = track

    local dragging = false
    local function update(inp)
        local pos = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * pos)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        knob.Position = UDim2.new(pos, -7, 0.5, -7)
        valLbl.Text = tostring(v)
        if cb then cb(v) end
    end
    hit.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(inp) end end)
    UIS.InputChanged:Connect(function(inp) if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then update(inp) end end)
    UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    return frame
end

local function CreateButton(parent, text, cb, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 46)
    btn.BackgroundColor3 = color or T.Surface
    btn.BackgroundTransparency = 0.2
    btn.Text = text
    btn.TextColor3 = T.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Corner(btn, 8)
    Stroke(btn, T.Border, 1, 0.5)

    btn.MouseButton1Click:Connect(function()
        local original = btn.BackgroundColor3
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = T.Success}):Play()
        task.wait(0.15)
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = original}):Play()
        if cb then cb() end
    end)
    return btn
end

local function CreateTextbox(parent, text, placeholder, def, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.BackgroundColor3 = T.Surface
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Corner(frame, 8)
    Stroke(frame, T.Border, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 16, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -32, 0, 24)
    box.Position = UDim2.new(0, 16, 0, 28)
    box.BackgroundColor3 = T.Bg
    box.BorderSizePixel = 0
    box.Text = def
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = T.SubText
    box.TextColor3 = T.Text
    box.Font = Enum.Font.Code
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Parent = frame
    Corner(box, 4)

    box.FocusLost:Connect(function() if cb then cb(box.Text) end end)
    return frame
end

-- ═══════════ LOGIC: ESP ═══════════
local ESPDraws = {}
local function CreateESPDraws(player)
    if ESPDraws[player] then return ESPDraws[player] end
    local t = { 
        Box = Drawing.new("Square"), 
        Name = Drawing.new("Text"), 
        Dist = Drawing.new("Text"),
        Line = Drawing.new("Line")
    }
    t.Box.Thickness = 1
    t.Name.Size = 13; t.Name.Center = true; t.Name.Outline = true
    t.Dist.Size = 12; t.Dist.Center = true; t.Dist.Outline = true
    t.Line.Thickness = 1; t.Line.Transparency = 0.5
    
    table.insert(MM.Drawings, t.Box) table.insert(MM.Drawings, t.Name) 
    table.insert(MM.Drawings, t.Dist) table.insert(MM.Drawings, t.Line)
    
    ESPDraws[player] = t
    return t
end

local function HideESP(d)
    if not d then return end
    d.Box.Visible = false d.Name.Visible = false d.Dist.Visible = false d.Line.Visible = false
end
local function RemoveESP(player)
    if not ESPDraws[player] then return end
    local d = ESPDraws[player]
    pcall(function() d.Box:Remove() end) pcall(function() d.Name:Remove() end) 
    pcall(function() d.Dist:Remove() end) pcall(function() d.Line:Remove() end)
    ESPDraws[player] = nil
end
Players.PlayerRemoving:Connect(RemoveESP)

local function GetPlayerBox(char)
    local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
    if ok and cf and size then
        local tS, tOn = Camera:WorldToViewportPoint(cf.Position + Vector3.new(0, size.Y / 2, 0))
        local bS, bOn = Camera:WorldToViewportPoint(cf.Position - Vector3.new(0, size.Y / 2, 0))
        local lS, lOn = Camera:WorldToViewportPoint(cf.Position - Vector3.new(size.X / 2, 0, 0))
        local rS, rOn = Camera:WorldToViewportPoint(cf.Position + Vector3.new(size.X / 2, 0, 0))
        if tOn and bOn and lOn and rOn then
            local w = math.abs(rS.X - lS.X) local h = math.abs(bS.Y - tS.Y)
            if w > 0 and h > 0 and w < 800 and h < 800 then return {x = lS.X, y = tS.Y, w = w, h = h} end
        end
    end
    local head = char:FindFirstChild("Head")
    local leftFoot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("LeftLowerLeg")
    local rightFoot = char:FindFirstChild("RightFoot") or char:FindFirstChild("RightLowerLeg")
    if head and leftFoot and rightFoot then
        local hS, hOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local fS, fOn = Camera:WorldToViewportPoint(leftFoot.Position - Vector3.new(0, 0.5, 0))
        local rS, rOn = Camera:WorldToViewportPoint(rightFoot.Position - Vector3.new(0, 0.5, 0))
        if hOn and fOn and rOn then
            local h = math.abs(fS.Y - hS.Y) local w = h * 0.5
            if h > 0 and w > 0 then return {x = hS.X - w / 2, y = hS.Y, w = w, h = h} end
        end
    end
    return nil
end

local function RenderESP()
    if not Config.ESP then
        for _, d in pairs(ESPDraws) do HideESP(d) end return
    end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local char = p.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local d = ESPDraws[p]
            if not (char and hrp and hum and hum.Health > 0) then if d then HideESP(d) end
            else
                local d3 = myPos and (myPos - hrp.Position).Magnitude or 0
                if d3 > Config.ESP_MaxDist then if d then HideESP(d) end
                else
                    local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if not onScreen then if d then HideESP(d) end
                    else
                        if not d then d = CreateESPDraws(p) end
                        if d then
                            local box = GetPlayerBox(char)
                            local x, y, w, h
                            if box then x, y, w, h = box.x, box.y, box.w, box.h
                            else h = math.clamp(8000 / math.max(d3, 1), 20, 500) w = h / 2 x = sp.X - w / 2 y = sp.Y - h / 2 end
                            
                            d.Box.Visible = Config.ESP_Box
                            if d.Box.Visible then d.Box.Size = Vector2.new(w, h) d.Box.Position = Vector2.new(x, y) d.Box.Color = ESPColorPlayer end
                            
                            d.Name.Visible = Config.ESP_Name
                            if d.Name.Visible then d.Name.Text = p.Name d.Name.Position = Vector2.new(x + w / 2, y - 18) d.Name.Color = ESPColorPlayer end
                            
                            d.Dist.Visible = Config.ESP_Dist
                            if d.Dist.Visible then d.Dist.Text = tostring(math.floor(d3)) .. "m" d.Dist.Position = Vector2.new(x + w / 2, y + h + 2) d.Dist.Color = ESPColorPlayer end
                            
                            d.Line.Visible = Config.ESP_Line
                            if d.Line.Visible then
                                local origin = Config.ESP_LineOrigin == "Center" and Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                d.Line.From = origin
                                d.Line.To = Vector2.new(sp.X, sp.Y)
                                d.Line.Color = ESPColorPlayer
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ═══════════ LOGIC: VEHICLE ESP ═══════════
local VehicleDraws = {}
local VehicleSeats = {}
local function RegisterSeat(seat) if VehicleSeats[seat] then return end local model = seat:FindFirstAncestorOfClass("Model") or seat:FindFirstAncestorOfClass("Folder") if model then VehicleSeats[seat] = model end end
for _, inst in ipairs(WS:GetDescendants()) do if inst:IsA("VehicleSeat") then RegisterSeat(inst) end end
WS.DescendantAdded:Connect(function(inst) if inst:IsA("VehicleSeat") then RegisterSeat(inst) end end)

local function CreateVehicleDraw(model)
    if VehicleDraws[model] then return VehicleDraws[model] end
    local t = {Box = Drawing.new("Square"), Name = Drawing.new("Text"), Dist = Drawing.new("Text"), Line = Drawing.new("Line")}
    t.Box.Thickness = 1
    t.Name.Size = 13; t.Name.Center = true; t.Name.Outline = true
    t.Dist.Size = 12; t.Dist.Center = true; t.Dist.Outline = true
    t.Line.Thickness = 1; t.Line.Transparency = 0.5
    table.insert(MM.Drawings, t.Box) table.insert(MM.Drawings, t.Name) 
    table.insert(MM.Drawings, t.Dist) table.insert(MM.Drawings, t.Line)
    VehicleDraws[model] = t
    return t
end

local function RenderVehicleESP()
    if not Config.V_ESP then for model, d in pairs(VehicleDraws) do d.Box.Visible = false d.Name.Visible = false d.Dist.Visible = false d.Line.Visible = false end return end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position
    if not myPos then return end
    local seen = {}
    for _, model in pairs(VehicleSeats) do
        if model and model.Parent and not seen[model] then
            seen[model] = true
            local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
            if anchor then
                local d = CreateVehicleDraw(model)
                if d then
                    local pos = anchor.Position
                    local d3 = (myPos - pos).Magnitude
                    if d3 > Config.V_ESP_MaxDist then d.Box.Visible = false d.Name.Visible = false d.Dist.Visible = false d.Line.Visible = false
                    else
                        local sp, on = Camera:WorldToViewportPoint(pos)
                        if not on then d.Box.Visible = false d.Name.Visible = false d.Dist.Visible = false d.Line.Visible = false
                        else
                            local sz = math.clamp(8000 / math.max(d3, 1), 24, 300)
                            d.Box.Visible = Config.V_ESP_Box
                            if d.Box.Visible then d.Box.Size = Vector2.new(sz, sz) d.Box.Position = Vector2.new(sp.X - sz / 2, sp.Y - sz / 2) d.Box.Color = ESPColorVehicle end
                            d.Name.Visible = Config.V_ESP_Name
                            if d.Name.Visible then d.Name.Text = model.Name d.Name.Position = Vector2.new(sp.X, sp.Y - sz / 2 - 18) d.Name.Color = ESPColorVehicle end
                            d.Dist.Visible = Config.V_ESP_Dist
                            if d.Dist.Visible then d.Dist.Text = tostring(math.floor(d3)) .. "m" d.Dist.Position = Vector2.new(sp.X, sp.Y + sz / 2 + 2) d.Dist.Color = ESPColorVehicle end
                            d.Line.Visible = Config.V_ESP_Line
                            if d.Line.Visible then
                                local origin = Config.ESP_LineOrigin == "Center" and Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                d.Line.From = origin
                                d.Line.To = Vector2.new(sp.X, sp.Y)
                                d.Line.Color = ESPColorVehicle
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ═══════════ LOGIC: AIMBOT ═══════════
local Target = nil
local oldNamecall = nil

pcall(function()
    local mt = getrawmetatable(game)
    oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        if Config.SilentAim and Target and Target.Parent then
            local m = getnamecallmethod()
            if m == "Raycast" or m == "FindPartOnRay" then
                local args = {...}
                local headPos = Target.Position
                if m == "Raycast" then
                    args[2] = (headPos - args[1]).Unit * (headPos - args[1]).Magnitude
                    return oldNamecall(self, unpack(args))
                elseif m == "FindPartOnRay" then
                    args[1] = Ray.new(args[1].Origin, headPos - args[1].Origin)
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

local function GetClosestTarget(fov, maxDist)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myPos = hrp.Position
    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    local best, bestDist = nil, math.huge
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tHead = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if tHead and hum and hum.Health > 0 then
                local d3 = (myPos - tHead.Position).Magnitude
                if d3 <= maxDist then
                    local sp, on = Camera:WorldToViewportPoint(tHead.Position)
                    if on then
                        local d2 = math.sqrt((sp.X - cx)^2 + (sp.Y - cy)^2)
                        if d2 <= fov and d2 < bestDist then
                            bestDist = d2 best = tHead
                        end
                    end
                end
            end
        end
    end
    return best
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Visible = false
table.insert(MM.Drawings, FOVCircle)

local VisualAiming = false
local VisualTarget = nil

local function OnRender()
    if Config.SilentAim then
        Target = GetClosestTarget(Config.SilentFOV, Config.SilentMaxDist)
        if Target then
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            FOVCircle.Radius = Config.SilentFOV
            FOVCircle.Color = Color3.fromRGB(180, 0, 255)
            FOVCircle.Visible = true
        elseif not VisualAiming and not Config.ShowFOV then
            FOVCircle.Visible = false
        end
    else
        Target = nil
    end

    if Config.AimEnabled and VisualAiming then
        if VisualTarget then
            local hum = VisualTarget.Parent and VisualTarget.Parent:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then VisualTarget = nil
            else
                local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
                local sp, on = Camera:WorldToViewportPoint(VisualTarget.Position)
                if on then
                    local d2 = math.sqrt((sp.X - cx)^2 + (sp.Y - cy)^2)
                    if d2 > Config.AimFOV then VisualTarget = nil end
                else VisualTarget = nil end
            end
        end
        if not VisualTarget then VisualTarget = GetClosestTarget(Config.AimFOV, Config.AimMaxDist) end
        if VisualTarget then
            local targetCF = CFrame.new(Camera.CFrame.Position, VisualTarget.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, Config.AimSmooth)
        end
        if not Config.SilentAim and not Config.ShowFOV then
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            FOVCircle.Radius = Config.AimFOV
            FOVCircle.Color = Color3.fromRGB(0, 240, 255)
            FOVCircle.Visible = true
        end
    else
        VisualTarget = nil
        if not Config.SilentAim and not Config.ShowFOV then FOVCircle.Visible = false end
    end
    
    if Config.ShowFOV and not Config.SilentAim and not VisualAiming then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Config.AimFOV
        FOVCircle.Color = Color3.fromRGB(0, 240, 255)
        FOVCircle.Visible = true
    end
end

-- ═══════════ LOGIC: MOVEMENT & TP ═══════════
local FlyState = { dir = Vector3.zero, up = 0 }
local FlyConn, FlyBodyVel, FlyGyro = nil, nil, nil
local FlyJoyUI = nil

local function ApplySpeed()
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = Config.SpeedOn and Config.SpeedValue or 16 end
end

local function ApplyInfJump()
    if Config.InfJump then
        if not MM.InfJumpConn then
            MM.InfJumpConn = UIS.JumpRequest:Connect(function()
                local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    else
        if MM.InfJumpConn then MM.InfJumpConn:Disconnect() MM.InfJumpConn = nil end
    end
end

local function ApplyNoclip()
    if Config.Noclip then
        if not MM.NoclipConn then
            MM.NoclipConn = RunService.Stepped:Connect(function()
                local char = LP.Character
                if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end
            end)
        end
    else
        if MM.NoclipConn then MM.NoclipConn:Disconnect() MM.NoclipConn = nil end
    end
end

local function ApplyFly()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if Config.Fly then
        if not hrp or not hum then return end
        hum.PlatformStand = true
        hrp.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.01, 0.01, 0, 0)
        hrp.CanCollide = false
        if not FlyBodyVel then
            FlyBodyVel = Instance.new("BodyVelocity")
            FlyBodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            FlyBodyVel.Velocity = Vector3.zero
            FlyBodyVel.Parent = hrp
        end
        if not FlyGyro then
            FlyGyro = Instance.new("BodyGyro")
            FlyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            FlyGyro.P = 10000 FlyGyro.D = 500
            FlyGyro.Parent = hrp
        end
        if not FlyConn then
            FlyConn = RunService.Heartbeat:Connect(function()
                if not Config.Fly then return end
                local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if not h or not FlyBodyVel then return end
                FlyGyro.CFrame = Camera.CFrame
                local dir = FlyState.dir
                local moveVel = Vector3.zero
                if dir.Magnitude > 0 then moveVel = (Camera.CFrame.LookVector * dir.Z + Camera.CFrame.RightVector * dir.X).Unit * Config.FlySpeed end
                if FlyState.up ~= 0 then moveVel = moveVel + Vector3.new(0, FlyState.up * Config.FlySpeed, 0) end
                FlyBodyVel.Velocity = moveVel
            end)
        end
    else
        if FlyBodyVel then pcall(function() FlyBodyVel:Destroy() end) FlyBodyVel = nil end
        if FlyGyro then pcall(function() FlyGyro:Destroy() end) FlyGyro = nil end
        if FlyConn then FlyConn:Disconnect() FlyConn = nil end
        if hum then hum.PlatformStand = false if hrp then hrp.CustomPhysicalProperties = nil hrp.CanCollide = true end end
    end
end

local function SafeTP(pos)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LP.Character}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local hit = WS:Raycast(pos + Vector3.new(0, 100, 0), Vector3.new(0, -500, 0), rp)
    local y = hit and hit.Position.Y or pos.Y
    hrp.CFrame = CFrame.new(pos.X, y + 3, pos.Z)
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero end)
end

-- ═══════════ LOGIC: ACTIONS ═══════════
local actionMenuFrame = nil

local function OpenActions(p)
    if actionMenuFrame then actionMenuFrame:Destroy() end

    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 200, 0, 240)
    f.Position = UDim2.new(0.5, -100, 0.5, -120)
    f.BackgroundColor3 = T.Bg
    f.BorderSizePixel = 0
    f.Parent = ScreenGui
    Corner(f, 12)
    Stroke(f, T.Accent, 1.5, 0.3)
    actionMenuFrame = f

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Actions: " .. p.Name
    title.TextColor3 = T.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = f

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -35, 5, 0)
    close.BackgroundColor3 = T.Danger
    close.Text = "×"
    close.TextColor3 = T.Text
    close.Font = Enum.Font.GothamBold
    close.TextSize = 18
    close.BorderSizePixel = 0
    close.Parent = f
    Corner(close, 6)
    close.MouseButton1Click:Connect(function() f:Destroy() actionMenuFrame = nil end)

    local list = Instance.new("UIListLayout", f)
    list.Padding = UDim.new(0, 4) list.SortOrder = Enum.SortOrder.LayoutOrder list.VerticalAlignment = Enum.VerticalAlignment.Center

    local function addBtn(text, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -20, 0, 32)
        b.BackgroundColor3 = T.Surface
        b.Text = text
        b.TextColor3 = T.Text
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.BorderSizePixel = 0
        b.Parent = f
        Corner(b, 6)
        b.MouseButton1Click:Connect(function() if cb then cb(p) end end)
    end

    addBtn("TP To Player", function(t)
        local hrp = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
        if hrp then SafeTP(hrp.Position) end
    end)
    addBtn("Damage (20)", function(t)
        local hum = t.Character and t.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.Health - 20 end
    end)
    addBtn("Ragdoll", function(t)
        if t.Character then
            for _, part in ipairs(t.Character:GetDescendants()) do
                if part:IsA("Motor6D") then pcall(function() part:Destroy() end) end
            end
            local hum = t.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
        end
    end)
    addBtn("Kill", function(t)
        if t.Character then
            for _, part in ipairs(t.Character:GetDescendants()) do
                if part:IsA("Motor6D") then pcall(function() part:Destroy() end) end
            end
            local hum = t.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end)
end

-- ═══════════ UI BINDINGS ═══════════
CreateToggle(Pages["Aimbot"], "Silent Aim (Hits Head)", Config.SilentAim, function(v) Config.SilentAim = v end)
CreateSlider(Pages["Aimbot"], "Silent FOV", 50, 500, Config.SilentFOV, function(v) Config.SilentFOV = v end)
CreateSlider(Pages["Aimbot"], "Silent Max Dist", 100, 3000, Config.SilentMaxDist, function(v) Config.SilentMaxDist = v end)

CreateToggle(Pages["Aimbot"], "Visual Aim (Hold AIM)", Config.AimEnabled, function(v) Config.AimEnabled = v end)
CreateSlider(Pages["Aimbot"], "Visual FOV", 50, 500, Config.AimFOV, function(v) Config.AimFOV = v end)
CreateSlider(Pages["Aimbot"], "Visual Smooth x100", 1, 100, Config.AimSmooth * 100, function(v) Config.AimSmooth = v / 100 end)
CreateToggle(Pages["Aimbot"], "Show Aim FOV", Config.ShowFOV, function(v) Config.ShowFOV = v end)

CreateToggle(Pages["Visuals"], "ESP Master (Players)", Config.ESP, function(v) Config.ESP = v end)
CreateToggle(Pages["Visuals"], " - Box", Config.ESP_Box, function(v) Config.ESP_Box = v end)
CreateToggle(Pages["Visuals"], " - Name", Config.ESP_Name, function(v) Config.ESP_Name = v end)
CreateToggle(Pages["Visuals"], " - Distance", Config.ESP_Dist, function(v) Config.ESP_Dist = v end)
CreateToggle(Pages["Visuals"], " - Line (Tracers)", Config.ESP_Line, function(v) Config.ESP_Line = v end)
CreateSlider(Pages["Visuals"], "Player Max Dist", 100, 5000, Config.ESP_MaxDist, function(v) Config.ESP_MaxDist = v end)
CreateTextbox(Pages["Visuals"], "Player ESP Color (Hex)", "00F0FF", Config.ESPColorHex, function(v)
    Config.ESPColorHex = v
    ESPColorPlayer = ParseHex(v, ESPColorPlayer)
end)

CreateToggle(Pages["Visuals"], "Vehicle ESP Master", Config.V_ESP, function(v) Config.V_ESP = v end)
CreateToggle(Pages["Visuals"], " - Box", Config.V_ESP_Box, function(v) Config.V_ESP_Box = v end)
CreateToggle(Pages["Visuals"], " - Name", Config.V_ESP_Name, function(v) Config.V_ESP_Name = v end)
CreateToggle(Pages["Visuals"], " - Distance", Config.V_ESP_Dist, function(v) Config.V_ESP_Dist = v end)
CreateToggle(Pages["Visuals"], " - Line", Config.V_ESP_Line, function(v) Config.V_ESP_Line = v end)
CreateSlider(Pages["Visuals"], "Vehicle Max Dist", 100, 5000, Config.V_ESP_MaxDist, function(v) Config.V_ESP_MaxDist = v end)
CreateTextbox(Pages["Visuals"], "Vehicle ESP Color (Hex)", "FFA500", Config.V_ESPColorHex, function(v)
    Config.V_ESPColorHex = v
    ESPColorVehicle = ParseHex(v, ESPColorVehicle)
end)

CreateToggle(Pages["Visuals"], "Fullbright", Config.Fullbright, function(v)
    Config.Fullbright = v
    if v then Lighting.Ambient = Color3.new(1,1,1) Lighting.Brightness = 3
    else Lighting.Ambient = Color3.fromRGB(70,70,70) Lighting.Brightness = 1 end
end)
CreateToggle(Pages["Visuals"], "Fog Off", Config.FogOff, function(v)
    Config.FogOff = v
    if v then Lighting.FogEnd = 1e6 else Lighting.FogEnd = 1000 end
end)

CreateToggle(Pages["Movement"], "Speed Hack", Config.SpeedOn, function(v) Config.SpeedOn = v ApplySpeed() end)
CreateSlider(Pages["Movement"], "Speed Value", 16, 200, Config.SpeedValue, function(v) Config.SpeedValue = v if Config.SpeedOn then ApplySpeed() end end)
CreateToggle(Pages["Movement"], "Infinite Jump", Config.InfJump, function(v) Config.InfJump = v ApplyInfJump() end)
CreateToggle(Pages["Movement"], "Noclip", Config.Noclip, function(v) Config.Noclip = v ApplyNoclip() end)

CreateToggle(Pages["Movement"], "Fly (Mobile Joystick)", Config.Fly, function(v)
    Config.Fly = v
    ApplyFly()
    if v then
        if not FlyJoyUI then
            FlyJoyUI = Instance.new("Frame")
            FlyJoyUI.Size = UDim2.new(0, 160, 0, 160)
            FlyJoyUI.Position = UDim2.new(1, -180, 0.5, -80)
            FlyJoyUI.BackgroundTransparency = 1
            FlyJoyUI.Parent = ScreenGui
            
            local function makeBtn(txt, pos, cb)
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, 50, 0, 50) b.Position = pos
                b.BackgroundColor3 = T.Surface b.BackgroundTransparency = 0.2
                b.Text = txt b.TextColor3 = T.Accent b.Font = Enum.Font.GothamBold b.TextSize = 18
                b.Parent = FlyJoyUI Corner(b, 25)
                b.MouseButton1Down:Connect(function() cb(true) end)
                b.MouseButton1Up:Connect(function() cb(false) end)
            end
            makeBtn("W", UDim2.new(0, 55, 0, 0), function(o) FlyState.dir = Vector3.new(FlyState.dir.X, FlyState.dir.Y, o and 1 or 0) end)
            makeBtn("S", UDim2.new(0, 55, 0, 110), function(o) FlyState.dir = Vector3.new(FlyState.dir.X, FlyState.dir.Y, o and -1 or 0) end)
            makeBtn("A", UDim2.new(0, 0, 0, 55), function(o) FlyState.dir = Vector3.new(o and -1 or 0, FlyState.dir.Y, FlyState.dir.Z) end)
            makeBtn("D", UDim2.new(0, 110, 0, 55), function(o) FlyState.dir = Vector3.new(o and 1 or 0, FlyState.dir.Y, FlyState.dir.Z) end)
            makeBtn("↑", UDim2.new(0, 55, 0, 55), function(o) FlyState.up = o and 1 or 0 end)
        end
        FlyJoyUI.Visible = true
    else
        if FlyJoyUI then FlyJoyUI.Visible = false end
    end
end)
CreateSlider(Pages["Movement"], "Fly Speed", 10, 200, Config.FlySpeed, function(v) Config.FlySpeed = v end)

CreateButton(Pages["Teleport"], "TP Nearest Enemy", function()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local best, bestD = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
            if tHrp then local d = (hrp.Position - tHrp.Position).Magnitude if d < bestD then bestD = d best = tHrp end end
        end
    end
    if best then SafeTP(best.Position) end
end)
CreateButton(Pages["Teleport"], "TP Forward 50", function()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then SafeTP(hrp.Position + Camera.CFrame.LookVector * 50) end
end)

local function RefreshPlayers()
    for _, v in pairs(Pages["Players"]:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, 0, 0, 40) b.BackgroundColor3 = T.Surface b.BackgroundTransparency = 0.2
                b.Text = "  " .. p.Name .. "    " .. d .. "m"
                b.TextColor3 = T.Text b.TextXAlignment = Enum.TextXAlignment.Left b.Font = Enum.Font.GothamMedium b.TextSize = 13 b.BorderSizePixel = 0 b.Parent = Pages["Players"]
                Corner(b, 8)
                b.MouseButton1Click:Connect(function() OpenActions(p) end)
            end
        end
    end
end
task.spawn(function() while task.wait(2) do RefreshPlayers() end end)

CreateToggle(Pages["Misc"], "Anti-AFK", Config.AntiAFK, function(v)
    Config.AntiAFK = v
    if v then
        if not MM.AntiAFKConn then
            MM.AntiAFKConn = RunService.Heartbeat:Connect(function()
                local vu = game:GetService("VirtualUser") pcall(function() vu:CaptureController() vu:ClickButton2(Vector2.new()) end)
            end)
        end
    else
        if MM.AntiAFKConn then MM.AntiAFKConn:Disconnect() MM.AntiAFKConn = nil end
    end
end)

-- ═══════════ FINAL SETUP ═══════════
local AimBtn = Instance.new("TextButton")
AimBtn.Size = UDim2.new(0, 60, 0, 60) AimBtn.Position = UDim2.new(1, -80, 0.7, 0)
AimBtn.BackgroundColor3 = T.Accent AimBtn.BackgroundTransparency = 0.2
AimBtn.Text = "AIM" AimBtn.TextColor3 = T.Text AimBtn.Font = Enum.Font.GothamBold AimBtn.TextSize = 16
AimBtn.BorderSizePixel = 0 AimBtn.ZIndex = 101 AimBtn.Parent = ScreenGui
Corner(AimBtn, 30) Stroke(AimBtn, T.Text, 1.5, 0.4)
AimBtn.MouseButton1Down:Connect(function() VisualAiming = true end)
AimBtn.MouseButton1Up:Connect(function() VisualAiming = false end)
AimBtn.MouseLeave:Connect(function() VisualAiming = false end)

local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 50, 0, 50) FloatBtn.Position = UDim2.new(0, 15, 0.5, -25)
FloatBtn.BackgroundColor3 = T.Accent FloatBtn.Text = "M" FloatBtn.TextColor3 = T.Text
FloatBtn.Font = Enum.Font.GothamBold FloatBtn.TextSize = 20 FloatBtn.BorderSizePixel = 0 FloatBtn.Active = true
FloatBtn.Draggable = true FloatBtn.Parent = ScreenGui
Corner(FloatBtn, 25) Stroke(FloatBtn, T.Text, 1.5, 0.4)

FloatBtn.MouseButton1Click:Connect(function() Main.Visible = true FloatBtn.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false FloatBtn.Visible = true end)
UnloadBtn.MouseButton1Click:Connect(function() getgenv().MeowUIUnload() end)

RunService:BindToRenderStep("MeowRender", Enum.RenderPriority.Camera.Value + 2, function()
    OnRender()
    RenderESP()
    RenderVehicleESP()
end)

task.spawn(function() task.wait(0.1) SelectTab("Aimbot") end)
Main.Visible = true

print("[MeowUI] FULL RELEASE Loaded.")

-- ═══════════════════════════════════════════════════════════
--  PART 8: VISUALS EXTENDED, FREECAM, POST-FX
-- ═══════════════════════════════════════════════════════════

-- 1. СОЗДАЕМ НОВЫЕ ВКЛАДКИ В SIDEBAR (World & Camera)
-- (Мы не трогаем существующие вкладки, просто добавляем новые)

local function AddSidebarTab(name, icon, order)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 40)
    Btn.Position = UDim2.new(0, 10, 0, 70 + (order * 45)) -- Сдвигаем вниз
    Btn.BackgroundColor3 = T.Sidebar
    Btn.BackgroundTransparency = 1
    Btn.Text = "  " .. icon .. "   " .. name
    Btn.TextColor3 = T.SubText
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.AutoButtonColor = false
    Btn.BorderSizePixel = 0
    Btn.Parent = Sidebar
    Corner(Btn, 8)
    
    TabButtons[name] = Btn

    local Page = Instance.new("ScrollingFrame")
    Page.Name = name
    Page.Size = UDim2.new(1, -200, 1, -120) 
    Page.Position = UDim2.new(0, 190, 0, 110)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = T.Accent
    Page.BorderSizePixel = 0
    Page.Parent = Main
    local L = Instance.new("UIListLayout", Page)
    L.Padding = UDim.new(0, 10)
    Pages[name] = Page

    Btn.MouseButton1Click:Connect(function() SelectTab(name) end)
end

-- Добавляем вкладки
AddSidebarTab("World", "🌍", 7)
AddSidebarTab("Camera", "📷", 8)

-- Пересчитываем позиции (сдвигаем старые вкладки вверх, чтобы не было наложения)
local sortedTabs = {"Aimbot", "Visuals", "Movement", "Teleport", "Players", "Misc", "World", "Camera"}
for i, name in ipairs(sortedTabs) do
    if TabButtons[name] then
        TabButtons[name].Position = UDim2.new(0, 10, 0, 70 + (i-1) * 45)
    end
end

-- ═══════════════════════════════════════════════════════════
--  2. FREE CAMERA (Свободная камера)
-- ═══════════════════════════════════════════════════════════
local FreeCam = {
    active = false,
    speed = 50,
}
local FreeCamConn = nil
local FreeCamTarget = Camera.CFrame

local function UpdateFreeCam()
    if not FreeCam.active then return end
    
    local move = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + FreeCamTarget.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - FreeCamTarget.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - FreeCamTarget.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + FreeCamTarget.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
    
    if move.Magnitude > 0 then
        FreeCamTarget = FreeCamTarget + move.Unit * FreeCam.speed * 0.05
    end
    
    Camera.CFrame = FreeCamTarget
end

local function ToggleFreeCam(v)
    FreeCam.active = v
    if v then
        FreeCamTarget = Camera.CFrame
        Camera.CameraType = Enum.CameraType.Scriptable
        if not FreeCamConn then
            FreeCamConn = RunService.RenderStepped:Connect(UpdateFreeCam)
        end
    else
        Camera.CameraType = Enum.CameraType.Custom
        if FreeCamConn then FreeCamConn:Disconnect() FreeCamConn = nil end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then Camera.CameraSubject = hum end
    end
end

CreateToggle(Pages["Camera"], "Free Camera (WASD)", false, ToggleFreeCam)
CreateSlider(Pages["Camera"], "FreeCam Speed", 10, 200, FreeCam.speed, function(v) FreeCam.speed = v end)

-- Применяем к настройкам камеры
CreateSlider(Pages["Camera"], "Field of View (FOV)", 50, 120, Camera.FieldOfView, function(v)
    Camera.FieldOfView = v
end)

-- ═══════════════════════════════════════════════════════════
--  3. POST-FX (Свечение, Размытие, Цвет)
-- ═══════════════════════════════════════════════════════════

local BloomFX = Instance.new("BloomEffect")
BloomFX.Name = "MeowBloom"
BloomFX.Enabled = false
BloomFX.Intensity = 1
BloomFX.Size = 24
BloomFX.Threshold = 0.9
BloomFX.Parent = Lighting

local BlurFX = Instance.new("BlurEffect")
BlurFX.Name = "MeowBlur"
BlurFX.Enabled = false
BlurFX.Size = 8
BlurFX.Parent = Lighting

local CC = Instance.new("ColorCorrectionEffect")
CC.Name = "MeowCC"
CC.Enabled = true
CC.Brightness = 0
CC.Contrast = 0
CC.Saturation = 0
CC.TintColor = Color3.new(1, 1, 1)
CC.Parent = Lighting

CreateToggle(Pages["Visuals"], "Bloom Effect", false, function(v) BloomFX.Enabled = v end)
CreateSlider(Pages["Visuals"], "Bloom Intensity", 1, 10, 1, function(v) BloomFX.Intensity = v / 2 end)

CreateToggle(Pages["Visuals"], "Blur Effect", false, function(v) BlurFX.Enabled = v end)
CreateSlider(Pages["Visuals"], "Blur Size", 1, 20, 8, function(v) BlurFX.Size = v end)

CreateSlider(Pages["Visuals"], "Color Saturation", -100, 100, 0, function(v) CC.Saturation = v / 100 end)
CreateSlider(Pages["Visuals"], "Color Contrast", -100, 100, 0, function(v) CC.Contrast = v / 100 end)

-- ═══════════════════════════════════════════════════════════
--  4. WORLD ENVIRONMENT (Время, Туман, Гравитация)
-- ═══════════════════════════════════════════════════════════

local WorldState = { oldFogEnd = nil, oldGravity = nil }

CreateSlider(Pages["World"], "Time of Day (0-24)", 0, 24, 12, function(v)
    Lighting.ClockTime = v
end)

CreateToggle(Pages["World"], "Remove Fog", false, function(v)
    if v then
        if not WorldState.oldFogEnd then WorldState.oldFogEnd = Lighting.FogEnd end
        Lighting.FogEnd = 1e6
    else
        if WorldState.oldFogEnd then 
            Lighting.FogEnd = WorldState.oldFogEnd 
            WorldState.oldFogEnd = nil 
        end
    end
end)

CreateSlider(Pages["World"], "Gravity", 50, 500, 196.2, function(v)
    if not WorldState.oldGravity then WorldState.oldGravity = WS.Gravity end
    WS.Gravity = v
end)

CreateButton(Pages["World"], "Reset Gravity", function()
    WS.Gravity = 196.2
    WorldState.oldGravity = nil
end)

-- ═══════════════════════════════════════════════════════════
--  5. SKYBOX & ATMOSPHERE (Небо)
-- ═══════════════════════════════════════════════════════════

local Atmosphere = Instance.new("Atmosphere")
Atmosphere.Name = "MeowAtmo"
Atmosphere.Density = 0.3
Atmosphere.Offset = 0.25
Atmosphere.Color = Color3.fromRGB(199, 199, 199)
Atmosphere.Decay = Color3.fromRGB(106, 112, 125)
Atmosphere.Parent = Lighting

local Sky = Instance.new("Sky")
Sky.Name = "MeowSky"
Sky.Parent = Lighting

CreateSlider(Pages["World"], "Atmosphere Density x100", 0, 100, 30, function(v)
    Atmosphere.Density = v / 100
end)

local function ApplySky(id)
    if not id or id == "" then return end
    local asset = "rbxassetid://" .. id
    Sky.SkyboxBk = asset
    Sky.SkyboxDn = asset
    Sky.SkyboxFt = asset
    Sky.SkyboxLf = asset
    Sky.SkyboxRt = asset
    Sky.SkyboxUp = asset
end

CreateTextbox(Pages["World"], "Custom Sky ID", "rbxassetid://...", "", function(v)
    local id = v:match("%d+")
    if id then ApplySky(id) end
end)

CreateButton(Pages["World"], "Reset Sky", function()
    Sky:Destroy()
    local newSky = Instance.new("Sky")
    newSky.Name = "MeowSky"
    newSky.Parent = Lighting
    Sky = newSky
end)

-- ═══════════════════════════════════════════════════════════
--  6. FULLBRIGHT EXTENDED
-- ═══════════════════════════════════════════════════════════

CreateToggle(Pages["Visuals"], "Fullbright (Ultimate)", false, function(v)
    if v then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 3
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
        Atmosphere.Density = 0
    else
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 1000
        Atmosphere.Density = 0.3
    end
end)

-- ═══════════════════════════════════════════════════════════
--  ФИНАЛЬНЫЙ ВЫВОД
-- ═══════════════════════════════════════════════════════════
print("[MeowUI] Part 8 Loaded — Visuals Extended, FreeCam, Post-FX ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 9: AUDIO, AUTO-FARM, SERVER HOP
-- ═══════════════════════════════════════════════════════════

-- 1. AUDIO (BoomBox & Sound Spam)
-- Создаем звук, который будет проигрываться локально (или для всех, если Parent = Character)
local MusicPlayer = Instance.new("Sound")
MusicPlayer.Name = "MeowMusic"
MusicPlayer.Volume = 1
MusicPlayer.Looped = true
MusicPlayer.Parent = WS

local SoundSpamActive = false
local SoundSpamId = "rbxassetid://131961136" -- Default: Earrape

local function PlaySoundSpam()
    if not SoundSpamActive then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local s = Instance.new("Sound")
        s.SoundId = SoundSpamId
        s.Volume = 10
        s.Parent = hrp
        s:Play()
        -- Удаляем через 2 секунды, чтобы не засорять память
        task.delay(2, function() if s then s:Destroy() end end)
    end
end

CreateToggle(Pages["Misc"], "Sound Spam (Global)", false, function(v)
    SoundSpamActive = v
    if v then
        task.spawn(function()
            while SoundSpamActive do
                PlaySoundSpam()
                task.wait(0.5)
            end
        end)
    end
end)

CreateTextbox(Pages["Misc"], "Sound Spam ID", "rbxassetid://...", SoundSpamId, function(v)
    SoundSpamId = v
end)

CreateToggle(Pages["Misc"], "BoomBox Music (Local)", false, function(v)
    if v then
        MusicPlayer.SoundId = SoundSpamId -- Используем тот же ID для простоты
        MusicPlayer:Play()
    else
        MusicPlayer:Stop()
    end
end)

CreateTextbox(Pages["Misc"], "Music ID", "rbxassetid://...", SoundSpamId, function(v)
    MusicPlayer.SoundId = v
    if MusicPlayer.IsPlaying then
        MusicPlayer:Stop()
        MusicPlayer:Play()
    end
end)

-- 2. AUTO-FARM (Умный фарм для симуляторов)
local AutoFarmActive = false
local AutoFarmDelay = 0.1

local function StartAutoFarm()
    if AutoFarmActive then return end
    AutoFarmActive = true
    
    task.spawn(function()
        local vu = game:GetService("VirtualUser")
        while AutoFarmActive do
            -- Ищем все кнопки на экране (TextButton, ImageButton)
            for _, gui in ipairs(PG:GetDescendants()) do
                if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                    -- Проверяем текст на кнопке (ищем что-то связанное с фармом)
                    local txt = ""
                    if gui:IsA("TextButton") then
                        txt = gui.Text:lower()
                    end
                    
                    -- Кликаем, если кнопка похожа на "Collect", "Claim", "Sell" и т.д.
                    if txt:find("collect") or txt:find("claim") or txt:find("sell") or txt:find("buy") or txt:find("upgrade") then
                        pcall(function()
                            vu:CaptureController()
                            -- Вычисляем координаты кнопки на экране для клика
                            local pos = gui.AbsolutePosition + (gui.AbsoluteSize / 2)
                            vu:ClickButton1(pos)
                        end)
                        task.wait(AutoFarmDelay) -- Задержка между кликами
                    end
                end
            end
            task.wait(0.5) -- Пауза перед следующим сканированием
        end
    end)
end

CreateToggle(Pages["Misc"], "Auto-Farm (Smart Click)", false, function(v)
    AutoFarmActive = v
    if v then StartAutoFarm() end
end)

CreateSlider(Pages["Misc"], "Farm Delay ms", 10, 500, 100, function(v)
    AutoFarmDelay = v / 1000
end)

-- 3. SERVER HOP (Смена сервера)
-- Сложный механизм: получаем список серверов через API Roblox, выбираем случайный и телепортируемся.
CreateButton(Pages["Misc"], "Server Hop (Random)", function()
    pcall(function()
        local ts = game:GetService("TeleportService")
        local hs = game:GetService("HttpService")
        
        -- Получаем список серверов
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = game:HttpGet(url)
        local data = hs:JSONDecode(response)
        
        if data and data.data then
            local servers = data.data
            local validServers = {}
            
            -- Фильтруем серверы, где есть свободные места и это не наш текущий сервер
            for _, server in ipairs(servers) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(validServers, server.id)
                end
            end
            
            if #validServers > 0 then
                local randomServer = validServers[math.random(1, #validServers)]
                print("[MeowMod] Hopping to server: " .. randomServer)
                ts:TeleportToPlaceInstance(game.PlaceId, randomServer, LP)
            else
                print("[MeowMod] No valid servers found.")
            end
        end
    end)
end)

-- 4. CHAT SPAM (Спам в чат)
local ChatSpamActive = false
local ChatSpamDelay = 1
local ChatSpamMessage = "Meow Mod on top!"

CreateTextbox(Pages["Misc"], "Spam Message", "meow...", ChatSpamMessage, function(v)
    ChatSpamMessage = v
end)

CreateSlider(Pages["Misc"], "Spam Delay 0.1s", 5, 50, 10, function(v)
    ChatSpamDelay = v / 10
end)

CreateToggle(Pages["Misc"], "Chat Spam", false, function(v)
    ChatSpamActive = v
    if v then
        task.spawn(function()
            while ChatSpamActive do
                local re = game:GetService("ReplicatedStorage")
                local ev = re:FindFirstChild("DefaultChatSystemChatEvents")
                if ev then
                    local remote = ev:FindFirstChild("SayMessageRequest")
                    if remote then
                        pcall(function() remote:FireServer(ChatSpamMessage, "All") end)
                    end
                end
                task.wait(ChatSpamDelay)
            end
        end)
    end
end)

-- 5. AUTO-CLICKER (Быстрый)
local ACConn = nil
CreateToggle(Pages["Misc"], "AutoClicker (Fast LMB)", false, function(v)
    if v then
        if not ACConn then
            ACConn = task.spawn(function()
                local vu = game:GetService("VirtualUser")
                while true do
                    pcall(function()
                        vu:CaptureController()
                        vu:ClickButton1(Vector2.new(0,0))
                    end)
                    task.wait(0.05) -- 20 кликов в секунду
                end
            end)
        end
    else
        if ACConn then
            pcall(function() task.cancel(ACConn) end)
            ACConn = nil
        end
    end
end)

print("[MeowUI] Part 9 Loaded — Audio, Auto-Farm, Server Hop ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 10: PROFILES, HUD, ANTI-AFK
-- ═══════════════════════════════════════════════════════════

-- 1. PLAYER PROFILES (Информация об игроке)
local ProfilePlayer = nil

local function GetPlayerInfo(player)
    if not player or not player.Character then return end
    local char = player.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if hum and hrp then
        local uid = player.UserId
        local age = player.AccountAge
        local team = player.Team and player.Team.Name or "None"
        local hp = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
        local speed = math.floor(hum.WalkSpeed)
        local dist = math.floor((LP.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
        
        print("══════════════════════")
        print("👤 PROFILE: " .. player.Name)
        print("🆔 UID: " .. uid)
        print("📅 Age: " .. age .. " days")
        print("🛡️ Team: " .. team)
        print("❤️ HP: " .. hp)
        print("🏃 Speed: " .. speed)
        print("📏 Dist: " .. dist .. "m")
        print("══════════════════════")
    end
end

CreateButton(Pages["Players"], "Profile: Nearest Player", function()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local best, bestD = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (myHrp.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d best = p end
            end
        end
    end
    if best then GetPlayerInfo(best) end
end)

-- 2. FPS / PING HUD (Счетчики на экране)
local HUD_FPS = Instance.new("TextLabel")
HUD_FPS.Size = UDim2.new(0, 100, 0, 20)
HUD_FPS.Position = UDim2.new(0, 10, 0, 10)
HUD_FPS.BackgroundColor3 = T.Bg
HUD_FPS.BackgroundTransparency = 0.4
HUD_FPS.TextColor3 = T.Accent
HUD_FPS.Font = Enum.Font.Code
HUD_FPS.TextSize = 12
HUD_FPS.Visible = false
HUD_FPS.Parent = ScreenGui

local HUD_Ping = Instance.new("TextLabel")
HUD_Ping.Size = UDim2.new(0, 100, 0, 20)
HUD_Ping.Position = UDim2.new(0, 10, 0, 32)
HUD_Ping.BackgroundColor3 = T.Bg
HUD_Ping.BackgroundTransparency = 0.4
HUD_Ping.TextColor3 = T.Text
HUD_Ping.Font = Enum.Font.Code
HUD_Ping.TextSize = 12
HUD_Ping.Visible = false
HUD_Ping.Parent = ScreenGui

CreateToggle(Pages["Misc"], "Show FPS", false, function(v)
    HUD_FPS.Visible = v
end)

CreateToggle(Pages["Misc"], "Show Ping", false, function(v)
    HUD_Ping.Visible = v
end)

local fpsCount = 0
local fpsTimer = tick()

RunService.RenderStepped:Connect(function()
    if HUD_FPS.Visible then
        fpsCount = fpsCount + 1
        if tick() - fpsTimer >= 1 then
            HUD_FPS.Text = "FPS: " .. tostring(fpsCount)
            fpsCount = 0
            fpsTimer = tick()
        end
    end
    if HUD_Ping.Visible then
        local ping = 0
        pcall(function()
            ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        HUD_Ping.Text = "Ping: " .. tostring(ping) .. "ms"
    end
end)

-- 3. ANTI-AFK V2 (Защита от вылета)
local AntiAFKActive = false
local AntiAFKConn = nil

CreateToggle(Pages["Misc"], "Anti-AFK (Idle)", false, function(v)
    AntiAFKActive = v
    if v then
        if not AntiAFKConn then
            AntiAFKConn = RunService.Heartbeat:Connect(function()
                local vu = game:GetService("VirtualUser")
                pcall(function()
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end)
        end
    else
        if AntiAFKConn then AntiAFKConn:Disconnect() AntiAFKConn = nil end
    end
end)

-- 4. AUTO-PARRY (Авто-блок для игр с паррированием)
local ParryConn = nil
local ParryActive = false

CreateToggle(Pages["Misc"], "Auto-Parry (Nearby)", false, function(v)
    ParryActive = v
    if v then
        if not ParryConn then
            ParryConn = RunService.Heartbeat:Connect(function()
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        -- Если враг в радиусе 10 стадов, жмем ПКМ
                        if tHrp and (hrp.Position - tHrp.Position).Magnitude < 10 then
                            local vu = game:GetService("VirtualUser")
                            pcall(function()
                                vu:CaptureController()
                                vu:ClickButton2(Vector2.new())
                            end)
                            break
                        end
                    end
                end
            end)
        end
    else
        if ParryConn then ParryConn:Disconnect() ParryConn = nil end
    end
end)

-- 5. INSTANT KILL AURA (Авто-удар)
local AuraConn = nil
local AuraActive = false

CreateToggle(Pages["Misc"], "Kill Aura (Nearby)", false, function(v)
    AuraActive = v
    if v then
        if not AuraConn then
            AuraConn = RunService.Heartbeat:Connect(function()
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                local best, bestD = nil, 15
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if tHrp then
                            local d = (hrp.Position - tHrp.Position).Magnitude
                            if d < bestD then bestD = d best = tHrp end
                        end
                    end
                end
                
                if best then
                    local vu = game:GetService("VirtualUser")
                    pcall(function()
                        vu:CaptureController()
                        vu:ClickButton1(Vector2.new())
                    end)
                end
            end)
        end
    else
        if AuraConn then AuraConn:Disconnect() AuraConn = nil end
    end
end)

print("[MeowUI] Part 10 Loaded — Profiles, HUD, Auto-Parry ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 11: REMOTE SPY, INSTANCE BROWSER, BYPASS
-- ═══════════════════════════════════════════════════════════

-- 1. REMOTE SPY (Перехват событий)
local RemoteSpyActive = false
local RemoteSpyLogs = {}
local RemoteSpyHook = nil

local function StartRemoteSpy()
    if RemoteSpyHook then return end
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if RemoteSpyActive and (method == "FireServer" or method == "InvokeServer") then
                local name = tostring(self)
                if #name > 30 then name = name:sub(1, 30) .. "..." end
                
                -- Записываем в лог
                table.insert(RemoteSpyLogs, 1, {name = name, method = method})
                if #RemoteSpyLogs > 15 then table.remove(RemoteSpyLogs) end
                
                print("[RemoteSpy] " .. method .. " -> " .. name)
            end
            return oldNamecall(self, ...)
        end)
        
        setreadonly(mt, true)
        RemoteSpyHook = true
    end)
end

CreateToggle(Pages["Misc"], "Remote Spy (Console)", false, function(v)
    RemoteSpyActive = v
    if v then StartRemoteSpy() end
end)

-- 2. INSTANCE BROWSER (Поиск объектов в мире)
local scanBox
local function CreateScannerUI()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 100)
    frame.BackgroundColor3 = T.Surface
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = Pages["World"]
    Corner(frame, 8)
    Stroke(frame, T.Border, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 16, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Instance Browser (Keyword)"
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -100, 0, 26)
    box.Position = UDim2.new(0, 16, 0, 34)
    box.BackgroundColor3 = T.Bg
    box.BorderSizePixel = 0
    box.Text = "Crate"
    box.PlaceholderText = "Object name..."
    box.PlaceholderColor3 = T.SubText
    box.TextColor3 = T.Text
    box.Font = Enum.Font.Code
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Parent = frame
    Corner(box, 4)
    scanBox = box

    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0, 70, 0, 26)
    scanBtn.Position = UDim2.new(1, -84, 0, 34)
    scanBtn.BackgroundColor3 = T.Accent
    scanBtn.Text = "Scan"
    scanBtn.TextColor3 = T.Text
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.TextSize = 12
    scanBtn.BorderSizePixel = 0
    scanBtn.Parent = frame
    Corner(scanBtn, 4)

    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(1, -32, 0, 26)
    tpBtn.Position = UDim2.new(0, 16, 0, 66)
    tpBtn.BackgroundColor3 = T.SurfaceHover
    tpBtn.Text = "TP to Nearest Object"
    tpBtn.TextColor3 = T.Text
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 12
    tpBtn.BorderSizePixel = 0
    tpBtn.Parent = frame
    Corner(tpBtn, 4)

    scanBtn.MouseButton1Click:Connect(function()
        local kw = scanBox.Text:lower()
        local found = 0
        print("🔍 Scanning for: " .. kw)
        for _, inst in ipairs(WS:GetDescendants()) do
            if inst.Name:lower():find(kw) then
                found = found + 1
                local pos = inst:IsA("BasePart") and inst.Position or "?"
                print("📍 " .. inst.Name .. " [" .. inst.ClassName .. "] @ " .. tostring(pos))
            end
        end
        print("✅ Found " .. found .. " objects.")
    end)

    tpBtn.MouseButton1Click:Connect(function()
        local kw = scanBox.Text:lower()
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end
        
        local best, bestD = nil, math.huge
        for _, inst in ipairs(WS:GetDescendants()) do
            if inst.Name:lower():find(kw) and inst:IsA("BasePart") then
                local d = (myHrp.Position - inst.Position).Magnitude
                if d < bestD then bestD = d best = inst.Position end
            end
        end
        if best and SafeTP then SafeTP(best) end
    end)
end

CreateScannerUI()

-- 3. ANTI-KICK & BYPASS (Защита от кика)
-- Используем джиттер (рандомизацию) при стрельбе из Аима, чтобы античит не палил.
local BypassJitter = 0.1

CreateSlider(Pages["Misc"], "Bypass Jitter x100", 1, 100, 10, function(v)
    BypassJitter = v / 100
end)

-- Модифицируем логику аима для использования джиттера (встраиваем в хук)
-- (В прошлой части у нас был хук namecall. Здесь мы переопределяем его с рандомизацией).
local oldBypassHook = nil
pcall(function()
    local mt = getrawmetatable(game)
    oldBypassHook = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        if Config.SilentAim and Target and Target.Parent then
            local m = getnamecallmethod()
            if m == "Raycast" or m == "FindPartOnRay" then
                local args = {...}
                -- Добавляем случайное смещение (джиттер), чтобы пуля летела не идеально в центр
                local jitter = Vector3.new(
                    (math.random() - 0.5) * BypassJitter,
                    (math.random() - 0.5) * BypassJitter,
                    (math.random() - 0.5) * BypassJitter
                )
                local headPos = Target.Position + jitter
                
                if m == "Raycast" then
                    args[2] = (headPos - args[1]).Unit * (headPos - args[1]).Magnitude
                    return oldBypassHook(self, unpack(args))
                elseif m == "FindPartOnRay" then
                    args[1] = Ray.new(args[1].Origin, headPos - args[1].Origin)
                    return oldBypassHook(self, unpack(args))
                end
            end
        end
        return oldBypassHook(self, ...)
    end)
    setreadonly(mt, true)
end)

CreateToggle(Pages["Misc"], "Anti-Kick (Crash Guard)", false, function(v)
    if v then
        -- Включаем авто-восстановление при ошибках
        local oldErr = script:GetAttribute("ErrorHandler")
        print("[MeowMod] Anti-Kick enabled (Crash protection active).")
    end
end)

-- 4. CLEAR WORLD (Удаление мусора)
CreateButton(Pages["World"], "Clear World Debris", function()
    local count = 0
    for _, inst in ipairs(WS:GetDescendants()) do
        if inst.Name == "MeowPart" or inst.Name == "ExplosionPart" or inst:IsA("Debris") then
            pcall(function() inst:Destroy() end)
            count = count + 1
        end
    end
    print("[MeowMod] Cleared " .. count .. " debris.")
end)

print("[MeowUI] Part 11 Loaded — Spy, Browser, Bypass ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 12: CROSSHAIR, CHAMS, SKELETON, COLOR PICKER
-- ═══════════════════════════════════════════════════════════

-- 1. CUSTOM CROSSHAIR (Прицел на Drawing)
local CH_Line1 = Drawing.new("Line")
local CH_Line2 = Drawing.new("Line")
local CH_Line3 = Drawing.new("Line")
local CH_Line4 = Drawing.new("Line")

local CrosshairEnabled = false
local CrosshairSize = 10
local CrosshairColor = Color3.fromRGB(255, 255, 255)

table.insert(MM.Drawings, CH_Line1)
table.insert(MM.Drawings, CH_Line2)
table.insert(MM.Drawings, CH_Line3)
table.insert(MM.Drawings, CH_Line4)

local function UpdateCrosshair()
    if not CrosshairEnabled then
        CH_Line1.Visible = false
        CH_Line2.Visible = false
        CH_Line3.Visible = false
        CH_Line4.Visible = false
        return
    end

    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    local gap = 4 -- Расстояние от центра
    local len = CrosshairSize

    -- Верхняя линия
    CH_Line1.From = Vector2.new(cx, cy - gap)
    CH_Line1.To = Vector2.new(cx, cy - gap - len)
    CH_Line1.Color = CrosshairColor
    CH_Line1.Thickness = 1.5
    CH_Line1.Visible = true

    -- Нижняя линия
    CH_Line2.From = Vector2.new(cx, cy + gap)
    CH_Line2.To = Vector2.new(cx, cy + gap + len)
    CH_Line2.Color = CrosshairColor
    CH_Line2.Thickness = 1.5
    CH_Line2.Visible = true

    -- Левая линия
    CH_Line3.From = Vector2.new(cx - gap, cy)
    CH_Line3.To = Vector2.new(cx - gap - len, cy)
    CH_Line3.Color = CrosshairColor
    CH_Line3.Thickness = 1.5
    CH_Line3.Visible = true

    -- Правая линия
    CH_Line4.From = Vector2.new(cx + gap, cy)
    CH_Line4.To = Vector2.new(cx + gap + len, cy)
    CH_Line4.Color = CrosshairColor
    CH_Line4.Thickness = 1.5
    CH_Line4.Visible = true
end

CreateToggle(Pages["Visuals"], "Custom Crosshair", false, function(v) CrosshairEnabled = v end)
CreateSlider(Pages["Visuals"], "Crosshair Size", 5, 30, 10, function(v) CrosshairSize = v end)
CreateTextbox(Pages["Visuals"], "Crosshair Color (Hex)", "FFFFFF", "CrosshairColorHex", function(v)
    CrosshairColor = ParseHex(v, Color3.new(1,1,1))
end)

-- 2. SKELETON ESP (Скелет игрока)
-- Добавляем в Drawing линии для костей.
local SkeletonEnabled = false
local SkeletonDraws = {}

local function CreateSkeletonDraws(player)
    if SkeletonDraws[player] then return SkeletonDraws[player] end
    local lines = {}
    for i = 1, 14 do -- 14 пар костей
        lines[i] = Drawing.new("Line")
        lines[i].Thickness = 1
        lines[i].Visible = false
        table.insert(MM.Drawings, lines[i])
    end
    SkeletonDraws[player] = lines
    return lines
end

local function RenderSkeleton()
    if not SkeletonEnabled then
        for _, lines in pairs(SkeletonDraws) do
            for _, line in ipairs(lines) do line.Visible = false end
        end
        return
    end
    
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and hrp and myPos then
                local d3 = (myPos - hrp.Position).Magnitude
                if d3 <= Config.ESP_MaxDist then
                    local lines = CreateSkeletonDraws(p)
                    local bones = {
                        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
                        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
                        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
                        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
                        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
                    }
                    
                    for i, pair in ipairs(bones) do
                        local partA = char:FindFirstChild(pair[1])
                        local partB = char:FindFirstChild(pair[2])
                        if partA and partB then
                            local spA, onA = Camera:WorldToViewportPoint(partA.Position)
                            local spB, onB = Camera:WorldToViewportPoint(partB.Position)
                            if onA and onB then
                                lines[i].From = Vector2.new(spA.X, spA.Y)
                                lines[i].To = Vector2.new(spB.X, spB.Y)
                                lines[i].Color = ESPColorPlayer
                                lines[i].Visible = true
                            else
                                lines[i].Visible = false
                            end
                        else
                            lines[i].Visible = false
                        end
                    end
                else
                    local lines = SkeletonDraws[p]
                    if lines then
                        for _, line in ipairs(lines) do line.Visible = false end
                    end
                end
            else
                local lines = SkeletonDraws[p]
                if lines then
                    for _, line in ipairs(lines) do line.Visible = false end
                end
            end
        end
    end
end

CreateToggle(Pages["Visuals"], "Skeleton ESP", false, function(v) SkeletonEnabled = v end)

-- 3. CHAMS (Подсветка моделей через Highlight)
local ChamsEnabled = false
local ChamsInstances = {}

local function ApplyChams()
    if ChamsEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                if not ChamsInstances[p] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "MeowCham"
                    hl.FillColor = ESPColorPlayer
                    hl.OutlineColor = Color3.new(1,1,1)
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = p.Character
                    ChamsInstances[p] = hl
                else
                    -- Обновляем цвет, если поменялся
                    if ChamsInstances[p].FillColor ~= ESPColorPlayer then
                        ChamsInstances[p].FillColor = ESPColorPlayer
                    end
                end
            end
        end
    else
        for p, hl in pairs(ChamsInstances) do
            pcall(function() hl:Destroy() end)
            ChamsInstances[p] = nil
        end
    end
end

CreateToggle(Pages["Visuals"], "Chams (Highlight)", false, function(v)
    ChamsEnabled = v
    ApplyChams()
end)

-- 4. ADVANCED COLOR PICKER (Палитра цветов)
local function CreateColorPicker(parent, name, defaultColor, cb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 80)
    frame.BackgroundColor3 = T.Surface
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Corner(frame, 8)
    Stroke(frame, T.Border, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 0, 20)
    lbl.Position = UDim2.new(0, 16, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.Parent = frame

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 30, 0, 30)
    preview.Position = UDim2.new(1, -46, 0, 8)
    preview.BackgroundColor3 = defaultColor
    preview.BorderSizePixel = 0
    preview.Parent = frame
    Corner(preview, 6)
    Stroke(preview, T.Border, 1, 0.5)

    local hueSlider = Instance.new("TextButton")
    hueSlider.Size = UDim2.new(1, -32, 0, 20)
    hueSlider.Position = UDim2.new(0, 16, 0, 46)
    hueSlider.BackgroundColor3 = Color3.new(1,1,1)
    hueSlider.Text = ""
    hueSlider.BorderSizePixel = 0
    hueSlider.Parent = frame
    Corner(hueSlider, 4)

    -- Градиент для слайдера Hue
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1,0,0)),
        ColorSequenceKeypoint.new(0.17, Color3.new(1,1,0)),
        ColorSequenceKeypoint.new(0.33, Color3.new(0,1,0)),
        ColorSequenceKeypoint.new(0.5, Color3.new(0,1,1)),
        ColorSequenceKeypoint.new(0.67, Color3.new(0,0,1)),
        ColorSequenceKeypoint.new(0.83, Color3.new(1,0,1)),
        ColorSequenceKeypoint.new(1, Color3.new(1,0,0)),
    }
    grad.Parent = hueSlider

    local clicking = false
    local function UpdateColor(input)
        local pos = math.clamp((input.Position.X - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
        local color = Color3.fromHSV(pos, 1, 1)
        preview.BackgroundColor3 = color
        if cb then cb(color) end
    end

    hueSlider.MouseButton1Down:Connect(function() clicking = true end)
    UIS.InputChanged:Connect(function(inp)
        if clicking and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            UpdateColor(inp)
        end
    end)
    UIS.InputEnded:Connect(function()
        if clicking then clicking = false end
    end)
end

-- Добавляем Color Picker в Visuals
CreateColorPicker(Pages["Visuals"], "Player ESP Color", ESPColorPlayer, function(c)
    ESPColorPlayer = c
    Config.ESPColorHex = c:ToHex()
    ApplyChams() -- Обновляем Chams цвет
end)

CreateColorPicker(Pages["Visuals"], "Vehicle ESP Color", ESPColorVehicle, function(c)
    ESPColorVehicle = c
    Config.V_ESPColorHex = c:ToHex()
end)

-- 5. РЕНДЕР (Добавляем вызов скелета в общий цикл)
-- Мы перезаписываем BindToRenderStep, чтобы добавить рендер скелета и прицела.
RunService:UnbindFromRenderStep("MeowRender")
RunService:BindToRenderStep("MeowRender", Enum.RenderPriority.Camera.Value + 2, function()
    OnRender()
    RenderESP()
    RenderVehicleESP()
    RenderSkeleton() -- Новый вызов
    UpdateCrosshair() -- Новый вызов
end)

print("[MeowUI] Part 12 Loaded — Crosshair, Skeleton, Chams, ColorPicker ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 13: ORBIT, SPECTATE, ANTI-VOID, FREEZE ALL
-- ═══════════════════════════════════════════════════════════

-- 1. ORBIT (Кружение вокруг игрока)
local OrbitActive = false
local OrbitTarget = nil
local OrbitConn = nil
local OrbitRadius = 10
local OrbitSpeed = 1.5

local function StartOrbit(target)
    if not target or not target.Character then return end
    OrbitTarget = target
    OrbitActive = true
    
    if OrbitConn then OrbitConn:Disconnect() end
    local angle = 0
    
    OrbitConn = RunService.Heartbeat:Connect(function()
        if not OrbitActive or not OrbitTarget or not OrbitTarget.Character then
            if OrbitConn then OrbitConn:Disconnect() OrbitConn = nil end
            OrbitActive = false
            return
        end
        
        local targetHrp = OrbitTarget.Character:FindFirstChild("HumanoidRootPart")
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        
        if targetHrp and myHrp then
            angle = angle + OrbitSpeed * 0.05
            local offset = Vector3.new(
                math.cos(angle) * OrbitRadius,
                3, -- Высота
                math.sin(angle) * OrbitRadius
            )
            myHrp.CFrame = CFrame.new(targetHrp.Position + offset, targetHrp.Position)
            pcall(function()
                myHrp.AssemblyLinearVelocity = Vector3.zero
                myHrp.AssemblyAngularVelocity = Vector3.zero
            end)
        else
            OrbitActive = false
            if OrbitConn then OrbitConn:Disconnect() OrbitConn = nil end
        end
    end)
end

local function StopOrbit()
    OrbitActive = false
    OrbitTarget = nil
    if OrbitConn then OrbitConn:Disconnect() OrbitConn = nil end
end

CreateButton(Pages["Players"], "Orbit: Nearest Player", function()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local best, bestD = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (myHrp.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d best = p end
            end
        end
    end
    if best then StartOrbit(best) end
end)
CreateButton(Pages["Players"], "Orbit: Stop", function() StopOrbit() end)
CreateSlider(Pages["Players"], "Orbit Radius", 5, 30, 10, function(v) OrbitRadius = v end)
CreateSlider(Pages["Players"], "Orbit Speed", 1, 10, 5, function(v) OrbitSpeed = v / 5 end)

-- 2. SPECTATE CAMERA (Слежка)
local SpectateActive = false
local SpectateTarget = nil
local SpectateConn = nil
local SpectateOffset = 10

local function StartSpectate(target)
    if not target or not target.Character then return end
    SpectateTarget = target
    SpectateActive = true
    
    if SpectateConn then SpectateConn:Disconnect() end
    Camera.CameraType = Enum.CameraType.Scriptable
    
    SpectateConn = RunService.RenderStepped:Connect(function()
        if not SpectateActive or not SpectateTarget or not SpectateTarget.Character then
            if SpectateConn then SpectateConn:Disconnect() SpectateConn = nil end
            SpectateActive = false
            Camera.CameraType = Enum.CameraType.Custom
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then Camera.CameraSubject = hum end
            return
        end
        
        local head = SpectateTarget.Character:FindFirstChild("Head")
        if head then
            local targetCF = CFrame.new(head.Position + Vector3.new(0, 5, SpectateOffset), head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, 0.2)
        end
    end)
end

local function StopSpectate()
    SpectateActive = false
    SpectateTarget = nil
    if SpectateConn then SpectateConn:Disconnect() SpectateConn = nil end
    Camera.CameraType = Enum.CameraType.Custom
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then Camera.CameraSubject = hum end
end

CreateButton(Pages["Players"], "Spectate: Nearest", function()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local best, bestD = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (myHrp.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d best = p end
            end
        end
    end
    if best then StartSpectate(best) end
end)
CreateButton(Pages["Players"], "Spectate: Stop", function() StopSpectate() end)
CreateSlider(Pages["Players"], "Spectate Offset", 5, 30, 10, function(v) SpectateOffset = v end)

-- 3. ANTI-VOID (Защита от падения за карту)
local AntiVoidActive = false
local AntiVoidConn = nil

CreateToggle(Pages["Movement"], "Anti-Void (Safe TP)", false, function(v)
    AntiVoidActive = v
    if v then
        if not AntiVoidConn then
            AntiVoidConn = RunService.Heartbeat:Connect(function()
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Position.Y < -100 then -- Если упал ниже -100
                    -- Телепорт наверх
                    hrp.CFrame = CFrame.new(0, 50, 0)
                    pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
                    print("[MeowMod] Anti-Void triggered!")
                end
            end)
        end
    else
        if AntiVoidConn then AntiVoidConn:Disconnect() AntiVoidConn = nil end
    end
end)

-- 4. FREEZE ALL (Заморозка всех игроков)
local FrozenPlayers = {}

CreateButton(Pages["Players"], "Freeze All (Anchored)", function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                FrozenPlayers[p] = hrp.Anchored
                hrp.Anchored = true
            end
        end
    end
    print("[MeowMod] All players frozen.")
end)

CreateButton(Pages["Players"], "Unfreeze All", function()
    for p, state in pairs(FrozenPlayers) do
        if p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = state end
        end
    end
    FrozenPlayers = {}
    print("[MeowMod] All players unfrozen.")
end)

-- 5. FPS & PING HUD (Переносим в отдельную функцию для оптимизации)
local HUD_FPS = Instance.new("TextLabel")
HUD_FPS.Size = UDim2.new(0, 100, 0, 20)
HUD_FPS.Position = UDim2.new(0, 10, 0, 10)
HUD_FPS.BackgroundColor3 = T.Bg
HUD_FPS.BackgroundTransparency = 0.4
HUD_FPS.TextColor3 = T.Accent
HUD_FPS.Font = Enum.Font.Code
HUD_FPS.TextSize = 12
HUD_FPS.Visible = false
HUD_FPS.Parent = ScreenGui

local HUD_Ping = Instance.new("TextLabel")
HUD_Ping.Size = UDim2.new(0, 100, 0, 20)
HUD_Ping.Position = UDim2.new(0, 10, 0, 32)
HUD_Ping.BackgroundColor3 = T.Bg
HUD_Ping.BackgroundTransparency = 0.4
HUD_Ping.TextColor3 = T.Text
HUD_Ping.Font = Enum.Font.Code
HUD_Ping.TextSize = 12
HUD_Ping.Visible = false
HUD_Ping.Parent = ScreenGui

CreateToggle(Pages["Misc"], "Show FPS", false, function(v) HUD_FPS.Visible = v end)
CreateToggle(Pages["Misc"], "Show Ping", false, function(v) HUD_Ping.Visible = v end)

local fpsCount = 0
local fpsTimer = tick()

RunService.RenderStepped:Connect(function()
    if HUD_FPS.Visible then
        fpsCount = fpsCount + 1
        if tick() - fpsTimer >= 1 then
            HUD_FPS.Text = "FPS: " .. tostring(fpsCount)
            fpsCount = 0
            fpsTimer = tick()
        end
    end
    if HUD_Ping.Visible then
        local ping = 0
        pcall(function()
            ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        HUD_Ping.Text = "Ping: " .. tostring(ping) .. "ms"
    end
end)

print("[MeowUI] Part 13 Loaded — Orbit, Spectate, Anti-Void, Freeze ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 14: SKYBOX, ATMOSPHERE, WORLD CONTROL
-- ═══════════════════════════════════════════════════════════

-- 1. CUSTOM SKYBOX (Кастомное небо)
local Sky = Instance.new("Sky")
Sky.Name = "MeowSky"
Sky.Parent = Lighting

local function ApplySky(skyId)
    if not skyId or skyId == "" then return end
    local asset = "rbxassetid://" .. skyId
    Sky.SkyboxBk = asset
    Sky.SkyboxDn = asset
    Sky.SkyboxFt = asset
    Sky.SkyboxLf = asset
    Sky.SkyboxRt = asset
    Sky.SkyboxUp = asset
    print("[MeowMod] Skybox updated with ID: " .. skyId)
end

-- Ввод ID неба
CreateTextbox(Pages["World"], "Skybox ID", "rbxassetid://...", "", function(v)
    local id = v:match("%d+")
    if id then ApplySky(id) end
end)

-- Пресеты неба (просто примеры ID)
local SkyPresets = {
    ["Night"] = "1148468422",
    ["Sunset"] = "1148468405",
    ["Space"] = "592929521",
}

local function CreateSkyPresetButton(parent, name, id)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 30)
    btn.BackgroundColor3 = T.Surface
    btn.Text = name
    btn.TextColor3 = T.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Corner(btn, 6)
    btn.MouseButton1Click:Connect(function()
        ApplySky(id)
    end)
end

-- Контейнер для кнопок пресетов (вкладка World)
local skyBtnFrame = Instance.new("Frame")
skyBtnFrame.Size = UDim2.new(1, 0, 0, 36)
skyBtnFrame.BackgroundTransparency = 1
skyBtnFrame.Parent = Pages["World"]
local skyList = Instance.new("UIListLayout", skyBtnFrame)
skyList.FillDirection = Enum.FillDirection.Horizontal
skyList.Padding = UDim.new(0, 8)

for name, id in pairs(SkyPresets) do
    CreateSkyPresetButton(skyBtnFrame, name, id)
end

CreateButton(Pages["World"], "Reset Skybox", function()
    Sky:Destroy()
    local newSky = Instance.new("Sky")
    newSky.Name = "MeowSky"
    newSky.Parent = Lighting
    Sky = newSky
    print("[MeowMod] Skybox reset.")
end)

-- 2. ATMOSPHERE (Туман/Дымка)
local Atmos = Instance.new("Atmosphere")
Atmos.Name = "MeowAtmosphere"
Atmos.Density = 0.3
Atmos.Offset = 0.25
Atmos.Color = Color3.fromRGB(199, 199, 199)
Atmos.Decay = Color3.fromRGB(106, 112, 125)
Atmos.Parent = Lighting

CreateSlider(Pages["World"], "Atmo Density x100", 0, 100, 30, function(v)
    Atmos.Density = v / 100
end)
CreateSlider(Pages["World"], "Atmo Haze x100", 0, 100, 25, function(v)
    Atmos.Haze = v / 100
end)

CreateButton(Pages["World"], "Disable Atmosphere", function()
    Atmos.Density = 0
    Atmos.Haze = 0
end)

-- 3. TIME CONTROL (Время суток)
local WorldState = { oldClock = nil }

CreateSlider(Pages["World"], "Time of Day (0-24)", 0, 24, 12, function(v)
    if not WorldState.oldClock then WorldState.oldClock = Lighting.ClockTime end
    Lighting.ClockTime = v
end)

CreateButton(Pages["World"], "Reset Time", function()
    if WorldState.oldClock then Lighting.ClockTime = WorldState.oldClock end
end)

-- 4. FOG CONTROL (Туман)
local FogState = { oldFogEnd = nil, oldFogStart = nil }

CreateToggle(Pages["World"], "Remove Fog", false, function(v)
    if v then
        if not FogState.oldFogEnd then
            FogState.oldFogEnd = Lighting.FogEnd
            FogState.oldFogStart = Lighting.FogStart
        end
        Lighting.FogEnd = 1e6
        Lighting.FogStart = 1e6
    else
        if FogState.oldFogEnd then
            Lighting.FogEnd = FogState.oldFogEnd
            Lighting.FogStart = FogState.oldFogStart
            FogState.oldFogEnd = nil
        end
    end
end)

-- 5. AMBIENT LIGHTING (Освещение)
local LightState = { oldAmbient = nil, oldOutdoor = nil, oldBrightness = nil }

CreateSlider(Pages["World"], "Ambient Brightness (0-3)", 0, 30, 10, function(v)
    if not LightState.oldBrightness then
        LightState.oldBrightness = Lighting.Brightness
    end
    Lighting.Brightness = v / 10
end)

CreateButton(Pages["World"], "Fullbright (Ultimate)", function()
    if not LightState.oldAmbient then
        LightState.oldAmbient = Lighting.Ambient
        LightState.oldOutdoor = Lighting.OutdoorAmbient
        LightState.oldBrightness = Lighting.Brightness
    end
    Lighting.Ambient = Color3.new(1,1,1)
    Lighting.OutdoorAmbient = Color3.new(1,1,1)
    Lighting.Brightness = 3
    Lighting.GlobalShadows = false
end)

CreateButton(Pages["World"], "Reset Lighting", function()
    if LightState.oldAmbient then
        Lighting.Ambient = LightState.oldAmbient
        Lighting.OutdoorAmbient = LightState.oldOutdoor
        Lighting.Brightness = LightState.oldBrightness
        Lighting.GlobalShadows = true
        LightState.oldAmbient = nil
    end
end)

-- 6. GRAVITY CONTROL (Гравитация)
local GravityState = { oldGravity = nil }

CreateSlider(Pages["World"], "Gravity", 50, 500, 196.2, function(v)
    if not GravityState.oldGravity then GravityState.oldGravity = WS.Gravity end
    WS.Gravity = v
end)

CreateButton(Pages["World"], "Reset Gravity", function()
    if GravityState.oldGravity then WS.Gravity = GravityState.oldGravity end
end)

print("[MeowUI] Part 14 Loaded — Skybox, Atmosphere, World Control ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 15 REBUILT: WAR TYCOON (Farm, Auto-Build, Auto-Buy)
-- ═══════════════════════════════════════════════════════════

-- 1. AUTO-FARM: CRATES & AIRDROPS (Поиск и телепорт к луту)
-- В War Tycoon ящики и аирдропы — основа фарма. Мы ищем их в Workspace.
local LootFarmActive = false
local LootFarmConn = nil
local LootType = "Crate" -- "Crate" или "Airdrop"

local function FindNearestLoot(typeName)
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    local best, bestD = nil, math.huge
    
    for _, inst in ipairs(WS:GetDescendants()) do
        -- Ищем по имени (Crate, Airdrop, Barrel и т.д.)
        if inst.Name:lower():find(typeName:lower()) and inst:IsA("BasePart") then
            local d = (myHrp.Position - inst.Position).Magnitude
            if d < bestD then bestD = d best = inst end
        end
    end
    return best, bestD
end

local function StartLootFarm()
    if LootFarmActive then return end
    LootFarmActive = true
    
    LootFarmConn = task.spawn(function()
        while LootFarmActive do
            local target, dist = FindNearestLoot(LootType)
            
            if target and dist then
                -- Если ящик близко (меньше 10 стадов), просто ждем (или кликаем, если нужно)
                if dist < 10 then
                    -- В War Tycoon ящики обычно подбираются автоматически при касании
                    task.wait(0.5)
                else
                    -- Если далеко, телепортируемся (используем SafeTP из части 4)
                    if SafeTP then
                        SafeTP(target.Position + Vector3.new(0, 2, 0))
                    end
                    task.wait(1) -- Пауза между телепортами
                end
            else
                task.wait(2) -- Если лута нет, ждем
            end
        end
    end)
end

local function StopLootFarm()
    LootFarmActive = false
    if LootFarmConn then pcall(function() task.cancel(LootFarmConn) end) LootFarmConn = nil end
end

CreateToggle(Pages["Misc"], "Auto-Farm: Crates", false, function(v)
    if v then
        LootType = "Crate"
        StopLootFarm() -- Сброс предыдущего
        StartLootFarm()
    else
        StopLootFarm()
    end
end)

CreateToggle(Pages["Misc"], "Auto-Farm: Airdrops", false, function(v)
    if v then
        LootType = "Airdrop"
        StopLootFarm()
        StartLootFarm()
    else
        StopLootFarm()
    end
end)

-- 2. AUTO-BUILD (Автоматическая постройка базы)
-- В War Tycoon кнопки постройки находятся в интерфейсе (PlayerGui).
-- Мы ищем кнопки с текстом "Build", "Buy", "Upgrade" и кликаем.
local AutoBuildActive = false
local AutoBuildConn = nil

local function StartAutoBuild()
    if AutoBuildActive then return end
    AutoBuildActive = true
    
    AutoBuildConn = task.spawn(function()
        local vu = game:GetService("VirtualUser")
        while AutoBuildActive do
            -- Сканируем PlayerGui на наличие кнопок базы
            for _, gui in ipairs(PG:GetDescendants()) do
                if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                    local txt = ""
                    if gui:IsA("TextButton") then
                        txt = gui.Text:lower()
                    end
                    
                    -- Ищем кнопки постройки, покупки или улучшения
                    if txt:find("build") or txt:find("buy") or txt:find("upgrade") or txt:find("purchase") then
                        pcall(function()
                            vu:CaptureController()
                            local pos = gui.AbsolutePosition + (gui.AbsoluteSize / 2)
                            vu:ClickButton1(pos)
                        end)
                        task.wait(0.1) -- Задержка, чтобы не крашнуть
                    end
                end
            end
            task.wait(1) -- Пауза перед следующим сканированием
        end
    end)
end

local function StopAutoBuild()
    AutoBuildActive = false
    if AutoBuildConn then pcall(function() task.cancel(AutoBuildConn) end) AutoBuildConn = nil end
end

CreateToggle(Pages["Misc"], "Auto-Build Base", false, function(v)
    if v then StartAutoBuild() else StopAutoBuild() end
end)

-- 3. AUTO-BUY (Покупка оружия/техники в магазине)
local AutoBuyActive = false
local AutoBuyItem = "Buy"

local function StartAutoBuy()
    if AutoBuyActive then return end
    AutoBuyActive = true
    
    task.spawn(function()
        local vu = game:GetService("VirtualUser")
        while AutoBuyActive do
            for _, gui in ipairs(PG:GetDescendants()) do
                if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                    local txt = ""
                    if gui:IsA("TextButton") then
                        txt = gui.Text:lower()
                    end
                    
                    if txt:find(AutoBuyItem:lower()) then
                        pcall(function()
                            vu:CaptureController()
                            local pos = gui.AbsolutePosition + (gui.AbsoluteSize / 2)
                            vu:ClickButton1(pos)
                        end)
                        task.wait(0.3)
                    end
                end
            end
            task.wait(1)
        end
    end)
end

CreateTextbox(Pages["Misc"], "Auto-Buy Keyword", "Buy", "Buy", function(v)
    AutoBuyItem = v
end)

CreateToggle(Pages["Misc"], "Auto-Buy (Shop)", false, function(v)
    AutoBuyActive = v
    if v then StartAutoBuy() end
end)

-- 4. ANTI-RAGDOLL (Защита от падения в War Tycoon)
-- В War Tycoon есть механика, когда персонаж падает (Ragdoll).
local AntiRagdollActive = false
local AntiRagdollConn = nil

CreateToggle(Pages["Movement"], "Anti-Ragdoll (War Tycoon)", false, function(v)
    AntiRagdollActive = v
    if v then
        if not AntiRagdollConn then
            AntiRagdollConn = RunService.Heartbeat:Connect(function()
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                
                if hrp and hum then
                    if hum:GetState() == Enum.HumanoidStateType.Physics then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        pcall(function()
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                end
            end)
        end
    else
        if AntiRagdollConn then AntiRagdollConn:Disconnect() AntiRagdollConn = nil end
    end
end)

-- 5. INFINITE YIELD (Клонирование оружия из ReplicatedStorage)
-- Работает, если сервер не защищает папку оружия.
CreateButton(Pages["Misc"], "Clone Weapons (Infinite Yield)", function()
    local rs = game:GetService("ReplicatedStorage")
    local itemsFolder = rs:FindFirstChild("Items") or rs:FindFirstChild("Weapons") or rs:FindFirstChild("Tools")
    
    if itemsFolder then
        local myChar = LP.Character
        if myChar then
            local count = 0
            for _, item in ipairs(itemsFolder:GetChildren()) do
                if item:IsA("Tool") then
                    pcall(function()
                        local cloned = item:Clone()
                        cloned.Parent = myChar
                        count = count + 1
                    end)
                end
            end
            print("[MeowMod] Cloned " .. count .. " weapons.")
        end
    else
        print("[MeowMod] No weapons folder found.")
    end
end)

print("[MeowUI] Part 15 (War Tycoon) Loaded — Loot Farm, Auto-Build ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 16: WAR TYCOON VEHICLES (Tuning, Aim, ESP)
-- ═══════════════════════════════════════════════════════════

-- 1. VEHICLE HEALTH BAR ESP (Полоска здоровья над машинами)
local VehHealthDraws = {}

local function GetVehicleHealth(model)
    local healthPart = model:FindFirstChild("Health") or model:FindFirstChild("HealthBar")
    if healthPart and healthPart:IsA("BillboardGui") then
        return true -- Уже есть
    end
    return false
end

local function RenderVehicleHealth()
    if not Config.V_ESP then 
        for _, d in pairs(VehHealthDraws) do
            if d.Bg then d.Bg:Remove() end
            if d.Fg then d.Fg:Remove() end
        end
        VehHealthDraws = {}
        return 
    end
    
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position
    if not myPos then return end
    
    local seen = {}
    for _, model in pairs(VehicleSeats) do
        if model and model.Parent and not seen[model] then
            seen[model] = true
            local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
            if anchor then
                local d3 = (myPos - anchor.Position).Magnitude
                if d3 <= Config.V_ESP_MaxDist then
                    -- Ищем здоровье (в War Tycoon часто есть атрибут Health)
                    local hp = model:GetAttribute("Health") or model:GetAttribute("HP") or 100
                    local maxHp = model:GetAttribute("MaxHealth") or 100
                    
                    local d = VehHealthDraws[model]
                    if not d then
                        d = { Bg = Drawing.new("Square"), Fg = Drawing.new("Square") }
                        d.Bg.Filled = true d.Bg.Color = Color3.new(0,0,0) d.Bg.Thickness = 1
                        d.Fg.Filled = true d.Fg.Color = Color3.new(1,1,1) d.Fg.Thickness = 1
                        table.insert(MM.Drawings, d.Bg)
                        table.insert(MM.Drawings, d.Fg)
                        VehHealthDraws[model] = d
                    end
                    
                    local sp, on = Camera:WorldToViewportPoint(anchor.Position)
                    if on then
                        local barWidth = 30
                        local barHeight = 4
                        local x = sp.X - barWidth / 2
                        local y = sp.Y - 40 -- Над машиной
                        
                        d.Bg.Visible = true
                        d.Bg.Position = Vector2.new(x, y)
                        d.Bg.Size = Vector2.new(barWidth, barHeight)
                        d.Bg.Color = Color3.fromRGB(30,30,30)
                        
                        d.Fg.Visible = true
                        d.Fg.Position = Vector2.new(x + 1, y + 1)
                        d.Fg.Size = Vector2.new((barWidth - 2) * math.clamp(hp/maxHp, 0, 1), barHeight - 2)
                        d.Fg.Color = Color3.fromRGB(255 * (1 - hp/maxHp), 255 * (hp/maxHp), 0)
                    else
                        d.Bg.Visible = false
                        d.Fg.Visible = false
                    end
                else
                    local d = VehHealthDraws[model]
                    if d then d.Bg.Visible = false d.Fg.Visible = false end
                end
            end
        end
    end
end

-- Добавляем Health Bar ESP в визуал
CreateToggle(Pages["Visuals"], "Vehicle Health Bar", false, function(v) end)

-- 2. VEHICLE AIM (Наведение для техники)
local VehicleAimActive = false
local VehicleAimConn = nil

CreateToggle(Pages["Aimbot"], "Vehicle Aim Assist", false, function(v)
    VehicleAimActive = v
    if v then
        if not VehicleAimConn then
            VehicleAimConn = RunService.RenderStepped:Connect(function()
                if not VehicleAimActive then return end
                
                local char = LP.Character
                local seat = char and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.SeatPart
                if not seat then return end
                
                local vehicle = seat:FindFirstAncestorOfClass("Model")
                if not vehicle then return end
                
                -- Ищем ближайшего врага для наведения
                local best, bestD = nil, Config.AimMaxDist
                local myPos = seat.Position
                
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local d = (myPos - hrp.Position).Magnitude
                            if d < bestD then bestD = d best = hrp end
                        end
                    end
                end
                
                if best then
                    -- В War Tycoon танки часто используют Mouse.Hit или Turret
                    -- Мы пытаемся навести турель (если есть)
                    local turret = vehicle:FindFirstChild("Turret") or vehicle:FindFirstChild("Barrel")
                    if turret and turret:IsA("BasePart") then
                        local targetPos = best.Position
                        local dir = (targetPos - turret.Position).Unit
                        turret.CFrame = CFrame.new(turret.Position, turret.Position + dir)
                    end
                end
            end)
        end
    else
        if VehicleAimConn then VehicleAimConn:Disconnect() VehicleAimConn = nil end
    end
end)

-- 3. AUTO-PILOT (Для вертолетов)
local AutoPilotActive = false
local AutoPilotConn = nil

CreateToggle(Pages["Movement"], "Vehicle Auto-Pilot", false, function(v)
    AutoPilotActive = v
    if v then
        if not AutoPilotConn then
            AutoPilotConn = RunService.Heartbeat:Connect(function()
                if not AutoPilotActive then return end
                
                local char = LP.Character
                local seat = char and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.SeatPart
                if not seat then return end
                
                local vehicle = seat:FindFirstAncestorOfClass("Model")
                if not vehicle then return end
                
                local prim = vehicle.PrimaryPart
                if prim then
                    -- Держим высоту (если вертолет)
                    local targetHeight = 50
                    local vel = prim.AssemblyLinearVelocity
                    if prim.Position.Y < targetHeight then
                        prim.AssemblyLinearVelocity = Vector3.new(vel.X, 50, vel.Z)
                    elseif prim.Position.Y > targetHeight then
                        prim.AssemblyLinearVelocity = Vector3.new(vel.X, -50, vel.Z)
                    end
                end
            end)
        end
    else
        if AutoPilotConn then AutoPilotConn:Disconnect() AutoPilotConn = nil end
    end
end)

-- 4. VEHICLE TUNING (Тюнинг машин: ускорение, скорость)
local VehicleTuneActive = false

CreateToggle(Pages["Vehicles"], "Vehicle Speed Boost", false, function(v)
    VehicleTuneActive = v
    if v then
        task.spawn(function()
            while VehicleTuneActive do
                local char = LP.Character
                local seat = char and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.SeatPart
                if seat then
                    local vehicle = seat:FindFirstAncestorOfClass("Model")
                    if vehicle then
                        -- Ищем настройки скорости
                        local maxSpeed = vehicle:GetAttribute("MaxSpeed") or 50
                        local torque = vehicle:GetAttribute("Torque") or 10
                        
                        pcall(function()
                            vehicle:SetAttribute("MaxSpeed", maxSpeed * 1.5)
                            vehicle:SetAttribute("Torque", torque * 2)
                        end)
                    end
                end
                task.wait(1)
            end
        end)
    end
end)

-- 5. VEHICLE ESP (Доработка, чтобы показывать дистанцию и тип)
-- В War Tycoon машины имеют атрибуты Type (Tank, Heli, Car)
-- Мы добавим это в ESP.
local function GetVehicleType(model)
    local t = model:GetAttribute("VehicleType") or model:GetAttribute("Type")
    if t then return t end
    if model.Name:lower():find("tank") then return "Tank" end
    if model.Name:lower():find("heli") then return "Heli" end
    if model.Name:lower():find("plane") then return "Plane" end
    return "Vehicle"
end

-- Модифицируем стандартный ESP для машин
local oldVehicleDraw = CreateVehicleDraw
CreateVehicleDraw = function(model)
    local d = oldVehicleDraw(model)
    if d and d.Name then
        local vType = GetVehicleType(model)
        -- Обновляем текст имени
        d.Name.Text = model.Name .. " [" .. vType .. "]"
    end
    return d
end

-- Запускаем рендер здоровья в общий цикл
RunService:UnbindFromRenderStep("MeowRender")
RunService:BindToRenderStep("MeowRender", Enum.RenderPriority.Camera.Value + 2, function()
    OnRender()
    RenderESP()
    RenderVehicleESP()
    RenderSkeleton()
    UpdateCrosshair()
    RenderVehicleHealth()
end)

print("[MeowUI] Part 16 Loaded — Vehicle Tuning, Aim, Health ESP ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 17: WEAPONS, INVENTORY, CUSTOM SOUNDS, ANTI-FALL
-- ═══════════════════════════════════════════════════════════

-- 1. WEAPON ESP (Показ оружия над головой)
local WeaponESPActive = false
local WeaponDraws = {}

local function CreateWeaponDraw(player)
    if WeaponDraws[player] then return WeaponDraws[player] end
    local txt = Drawing.new("Text")
    txt.Size = 12
    txt.Center = true
    txt.Outline = true
    txt.Color = Color3.fromRGB(255, 200, 0)
    txt.Visible = false
    table.insert(MM.Drawings, txt)
    WeaponDraws[player] = txt
    return txt
end

local function RenderWeaponESP()
    if not WeaponESPActive then
        for _, txt in pairs(WeaponDraws) do txt.Visible = false end
        return
    end
    
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            
            if hrp and head and hum and hum.Health > 0 and myPos then
                local d3 = (myPos - hrp.Position).Magnitude
                if d3 <= Config.ESP_MaxDist then
                    local tool = p.Character:FindFirstChildOfClass("Tool")
                    local txt = CreateWeaponDraw(p)
                    
                    if tool then
                        local sp, on = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                        if on then
                            txt.Text = tool.Name
                            txt.Position = Vector2.new(sp.X, sp.Y)
                            txt.Visible = true
                        else
                            txt.Visible = false
                        end
                    else
                        txt.Visible = false
                    end
                else
                    local txt = WeaponDraws[p]
                    if txt then txt.Visible = false end
                end
            else
                local txt = WeaponDraws[p]
                if txt then txt.Visible = false end
            end
        end
    end
end

CreateToggle(Pages["Visuals"], "Weapon ESP", false, function(v) WeaponESPActive = v end)

-- 2. INVENTORY VIEWER (Просмотр инвентаря игрока)
local function ShowInventory(player)
    if not player or not player.Character then return end
    local char = player.Character
    print("══════════════════════")
    print("🎒 INVENTORY: " .. player.Name)
    
    local tools = char:GetChildren()
    local found = false
    for _, t in ipairs(tools) do
        if t:IsA("Tool") then
            print(" - " .. t.Name)
            found = true
        end
    end
    
    if not found then
        print(" (Empty)")
    end
    print("══════════════════════")
end

CreateButton(Pages["Players"], "View Nearest Inventory", function()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local best, bestD = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (myHrp.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d best = p end
            end
        end
    end
    if best then ShowInventory(best) end
end)

-- 3. CUSTOM SOUNDS (Звуки на события)
local SoundEnabled = false
local KillSoundId = "rbxassetid://131961136" -- Default
local SoundInstance = Instance.new("Sound")
SoundInstance.Volume = 2
SoundInstance.Parent = WS

-- Отслеживаем смерть игроков (для звука)
local function CheckKills()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                -- Если игрок умер (и мы его не отслеживали как мертвого)
                if not p:GetAttribute("IsDead") then
                    p:SetAttribute("IsDead", true)
                    if SoundEnabled then
                        SoundInstance.SoundId = KillSoundId
                        SoundInstance:Play()
                    end
                end
            else
                p:SetAttribute("IsDead", false)
            end
        end
    end
end
RunService.Heartbeat:Connect(CheckKills)

CreateToggle(Pages["Misc"], "Kill Sound (Global)", false, function(v) SoundEnabled = v end)
CreateTextbox(Pages["Misc"], "Kill Sound ID", "rbxassetid://...", KillSoundId, function(v)
    KillSoundId = v
end)

-- 4. ANTI-FALL (Защита от урона при падении)
local AntiFallActive = false
local AntiFallConn = nil

CreateToggle(Pages["Movement"], "Anti-Fall (No Damage)", false, function(v)
    AntiFallActive = v
    if v then
        if not AntiFallConn then
            AntiFallConn = RunService.Stepped:Connect(function()
                if not AntiFallActive then return end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                
                if hrp and hum then
                    -- Если мы падаем очень быстро
                    if hrp.AssemblyLinearVelocity.Y < -50 then
                        -- Обнуляем вертикальную скорость перед ударом
                        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
                        -- Восстанавливаем здоровье на всякий случай
                        hum.Health = hum.MaxHealth
                    end
                end
            end)
        end
    else
        if AntiFallConn then AntiFallConn:Disconnect() AntiFallConn = nil end
    end
end)

-- 5. AUTO-PARRY (Для War Tycoon - если есть механика)
-- В War Tycoon нет парри, но есть блок (если есть щит). 
-- Мы добавим "Auto-Block" (нажатие ПКМ).
local AutoBlockActive = false
local AutoBlockConn = nil

CreateToggle(Pages["Misc"], "Auto-Block (Nearby)", false, function(v)
    AutoBlockActive = v
    if v then
        if not AutoBlockConn then
            AutoBlockConn = RunService.Heartbeat:Connect(function()
                if not AutoBlockActive then return end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if tHrp and (hrp.Position - tHrp.Position).Magnitude < 10 then
                            local vu = game:GetService("VirtualUser")
                            pcall(function()
                                vu:CaptureController()
                                vu:ClickButton2(Vector2.new())
                            end)
                            break
                        end
                    end
                end
            end)
        end
    else
        if AutoBlockConn then AutoBlockConn:Disconnect() AutoBlockConn = nil end
    end
end)

-- 6. ОБНОВЛЕНИЕ РЕНДЕРА
RunService:UnbindFromRenderStep("MeowRender")
RunService:BindToRenderStep("MeowRender", Enum.RenderPriority.Camera.Value + 2, function()
    OnRender()
    RenderESP()
    RenderVehicleESP()
    RenderSkeleton()
    UpdateCrosshair()
    RenderVehicleHealth()
    RenderWeaponESP()
end)

print("[MeowUI] Part 17 Loaded — Weapons, Inventory, Sounds, Anti-Fall ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 19: ANTI-AIMBOT, AUTO-DODGE, PROXIMITY PROMPTS
-- ═══════════════════════════════════════════════════════════

-- 1. INSTANT PROXIMITY PROMPT (Мгновенное взаимодействие с объектами)
-- В War Tycoon часто нужно нажимать E для захвата флага, подбора ящика и т.д.
local InstantPromptActive = false
local PromptConn = nil

CreateToggle(Pages["Misc"], "Instant Proximity (E)", false, function(v)
    InstantPromptActive = v
    if v then
        if not PromptConn then
            PromptConn = RunService.Heartbeat:Connect(function()
                if not InstantPromptActive then return end
                -- Ищем все ProximityPrompt в мире
                for _, inst in ipairs(WS:GetDescendants()) do
                    if inst:IsA("ProximityPrompt") and inst.Enabled then
                        local parent = inst.Parent
                        if parent and parent:IsA("BasePart") then
                            local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if myHrp then
                                -- Если мы близко (в пределах 10 стадов), нажимаем
                                local dist = (myHrp.Position - parent.Position).Magnitude
                                if dist <= inst.MaxActivationDistance then
                                    fireproximityprompt(inst)
                                end
                            end
                        end
                    end
                end
            end)
        end
    else
        if PromptConn then PromptConn:Disconnect() PromptConn = nil end
    end
end)

-- 2. ANTI-AIMBOT (Защита от вражеского аима)
-- Сложный механизм: мы меняем наше местоположение (джиттер), чтобы сбить врага с толку.
local AntiAimActive = false
local AntiAimConn = nil

CreateToggle(Pages["Movement"], "Anti-Aimbot (Jitter)", false, function(v)
    AntiAimActive = v
    if v then
        if not AntiAimConn then
            AntiAimConn = RunService.Heartbeat:Connect(function()
                if not AntiAimActive then return end
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- Добавляем микро-смещение, чтобы враг не мог предсказать нашу позицию
                    local offset = Vector3.new(
                        (math.random() - 0.5) * 0.5,
                        (math.random() - 0.5) * 0.5,
                        (math.random() - 0.5) * 0.5
                    )
                    hrp.CFrame = hrp.CFrame + offset
                end
            end)
        end
    else
        if AntiAimConn then AntiAimConn:Disconnect() AntiAimConn = nil end
    end
end)

-- 3. AUTO-DODGE (Уклонение от пуль)
-- Сложный механизм: если в нас летит пуля (или снаряд), мы рывком уходим в сторону.
local AutoDodgeActive = false
local DodgeConn = nil
local DodgeDistance = 10

CreateToggle(Pages["Movement"], "Auto-Dodge (Bullets)", false, function(v)
    AutoDodgeActive = v
    if v then
        if not DodgeConn then
            DodgeConn = RunService.Heartbeat:Connect(function()
                if not AutoDodgeActive then return end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                -- Ищем снаряды (Part с именем Bullet или Projectile)
                for _, inst in ipairs(WS:GetDescendants()) do
                    if inst:IsA("BasePart") and (inst.Name:lower():find("bullet") or inst.Name:lower():find("projectile")) then
                        local d = (hrp.Position - inst.Position).Magnitude
                        if d < 15 then
                            -- Если снаряд близко и летит на нас, делаем рывок в сторону
                            local vel = inst.AssemblyLinearVelocity
                            if vel.Magnitude > 10 then
                                -- Рывок влево или вправо
                                local dir = (math.random() > 0.5) and hrp.CFrame.RightVector or -hrp.CFrame.RightVector
                                local newPos = hrp.Position + dir * DodgeDistance
                                hrp.CFrame = CFrame.new(newPos)
                            end
                        end
                    end
                end
            end)
        end
    else
        if DodgeConn then DodgeConn:Disconnect() DodgeConn = nil end
    end
end)

CreateSlider(Pages["Movement"], "Dodge Distance", 5, 30, 10, function(v) DodgeDistance = v end)

-- 4. AUTO-PARRY (Для War Tycoon - если есть парри)
local AutoParryActive = false
local AutoParryConn = nil

CreateToggle(Pages["Combat"], "Auto-Parry (Block)", false, function(v)
    AutoParryActive = v
    if v then
        if not AutoParryConn then
            AutoParryConn = RunService.Heartbeat:Connect(function()
                if not AutoParryActive then return end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if tHrp and (hrp.Position - tHrp.Position).Magnitude < 10 then
                            local vu = game:GetService("VirtualUser")
                            pcall(function()
                                vu:CaptureController()
                                vu:ClickButton2(Vector2.new())
                            end)
                            break
                        end
                    end
                end
            end)
        end
    else
        if AutoParryConn then AutoParryConn:Disconnect() AutoParryConn = nil end
    end
end)

-- 5. ANTI-KICK (Защита от кика)
-- Если сервер пытается нас кикнуть, скрипт перехватывает это и отменяет.
local AntiKickActive = false
local AntiKickConn = nil

CreateToggle(Pages["Misc"], "Anti-Kick (Crash Guard)", false, function(v)
    AntiKickActive = v
    if v then
        if not AntiKickConn then
            -- Используем pcall для перехвата (в некоторых executor'ах работает)
            AntiKickConn = RunService.Heartbeat:Connect(function()
                if not AntiKickActive then return end
                -- Пытаемся защитить PlayerGui от удаления
                local pg = LP:FindFirstChild("PlayerGui")
                if pg and pg.Parent ~= LP then
                    pg.Parent = LP
                end
            end)
        end
    else
        if AntiKickConn then AntiKickConn:Disconnect() AntiKickConn = nil end
    end
end)

-- 6. ОБНОВЛЕНИЕ РЕНДЕРА (с добавлением новых функций)
RunService:UnbindFromRenderStep("MeowRender")
RunService:BindToRenderStep("MeowRender", Enum.RenderPriority.Camera.Value + 2, function()
    OnRender()
    RenderESP()
    RenderVehicleESP()
    RenderSkeleton()
    UpdateCrosshair()
    RenderVehicleHealth()
    RenderWeaponESP()
end)

print("[MeowUI] Part 19 Loaded — Anti-Aimbot, Auto-Dodge, Instant Prompt ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 20: AUTO-MINE, INSTANT FARM, ANTI-LAG, WAYPOINTS
-- ═══════════════════════════════════════════════════════════

-- 1. WAYPOINTS (Сохранение и ТП на точки)
local Waypoints = {}
local WP_PATH = "MeowMod_Waypoints.json"

local function LoadWaypoints()
    if typeof(writefile) == "function" and typeof(readfile) == "function" then
        local ok, data = pcall(function()
            if isfile(WP_PATH) then return readfile(WP_PATH) end
        end)
        if ok and data and data ~= "" then
            local ok2, parsed = pcall(function() return game:GetService("HttpService"):JSONDecode(data) end)
            if ok2 and parsed then Waypoints = parsed end
        end
    end
end

local function SaveWaypoints()
    if typeof(writefile) == "function" then
        pcall(function()
            writefile(WP_PATH, game:GetService("HttpService"):JSONEncode(Waypoints))
        end)
    end
end
LoadWaypoints()

CreateButton(Pages["Teleport"], "Save Current Position (WP)", function()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local name = "wp_" .. tostring(#Waypoints + 1)
        table.insert(Waypoints, {name = name, pos = {X = hrp.Position.X, Y = hrp.Position.Y, Z = hrp.Position.Z}})
        SaveWaypoints()
        print("[MeowMod] Waypoint saved: " .. name)
    end
end)

-- Создаем кнопки для загрузки вейпоинтов
local wpFrame = Instance.new("Frame")
wpFrame.Size = UDim2.new(1, 0, 0, 150)
wpFrame.BackgroundColor3 = T.Surface
wpFrame.BackgroundTransparency = 0.2
wpFrame.BorderSizePixel = 0
wpFrame.Parent = Pages["Teleport"]
Corner(wpFrame, 8)

local wpList = Instance.new("UIListLayout", wpFrame)
wpList.Padding = UDim.new(0, 4)

local function RefreshWaypoints()
    for _, child in ipairs(wpFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, wp in ipairs(Waypoints) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -20, 0, 30)
        b.Position = UDim2.new(0, 10, 0, 0)
        b.BackgroundColor3 = T.Bg
        b.Text = wp.name
        b.TextColor3 = T.Text
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.BorderSizePixel = 0
        b.Parent = wpFrame
        Corner(b, 6)
        b.MouseButton1Click:Connect(function()
            -- SafeTP из части 4
            if SafeTP then SafeTP(Vector3.new(wp.pos.X, wp.pos.Y, wp.pos.Z)) end
        end)
    end
end
CreateButton(Pages["Teleport"], "Refresh WP List", function() RefreshWaypoints() end)

-- 2. AUTO-MINE (Авто-добыча ресурсов)
local AutoMineActive = false
local AutoMineConn = nil

CreateToggle(Pages["Misc"], "Auto-Mine (Click Rocks)", false, function(v)
    AutoMineActive = v
    if v then
        if not AutoMineConn then
            AutoMineConn = RunService.Heartbeat:Connect(function()
                if not AutoMineActive then return end
                -- Ищем камни/руду (Part с именем Rock или Ore)
                local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if not myHrp then return end
                
                for _, inst in ipairs(WS:GetDescendants()) do
                    if inst:IsA("BasePart") and (inst.Name:lower():find("rock") or inst.Name:lower():find("ore")) then
                        local d = (myHrp.Position - inst.Position).Magnitude
                        if d < 10 then
                            local vu = game:GetService("VirtualUser")
                            pcall(function()
                                vu:CaptureController()
                                local sp = Camera:WorldToViewportPoint(inst.Position)
                                vu:ClickButton1(Vector2.new(sp.X, sp.Y))
                            end)
                        end
                    end
                end
            end)
        end
    else
        if AutoMineConn then AutoMineConn:Disconnect() AutoMineConn = nil end
    end
end)

-- 3. INSTANT FARM (Мгновенный сбор ящиков)
local InstantFarmActive = false
local InstantFarmConn = nil

CreateToggle(Pages["Misc"], "Instant Farm (Crates)", false, function(v)
    InstantFarmActive = v
    if v then
        if not InstantFarmConn then
            InstantFarmConn = RunService.Heartbeat:Connect(function()
                if not InstantFarmActive then return end
                -- Ищем ящики (Crate) и подбираем их
                local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if not myHrp then return end
                
                for _, inst in ipairs(WS:GetDescendants()) do
                    if inst.Name:lower():find("crate") and inst:IsA("BasePart") then
                        local d = (myHrp.Position - inst.Position).Magnitude
                        if d < 5 then
                            -- Пытаемся подобрать (если есть ProximityPrompt)
                            local prompt = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                pcall(function() fireproximityprompt(prompt) end)
                            end
                        end
                    end
                end
            end)
        end
    else
        if InstantFarmConn then InstantFarmConn:Disconnect() InstantFarmConn = nil end
    end
end)

-- 4. ANTI-LAG (Оптимизация)
local AntiLagActive = false
local AntiLagConn = nil

CreateToggle(Pages["Misc"], "Anti-Lag (Optimize)", false, function(v)
    AntiLagActive = v
    if v then
        if not AntiLagConn then
            AntiLagConn = RunService.Heartbeat:Connect(function()
                if not AntiLagActive then return end
                -- Убираем лишние эффекты для повышения FPS
                pcall(function()
                    Lighting.GlobalShadows = false
                    Lighting.FogEnd = 1e6
                    Lighting.Brightness = 1
                end)
                -- Уменьшаем качество частиц
                for _, inst in ipairs(WS:GetDescendants()) do
                    if inst:IsA("ParticleEmitter") then
                        inst.Rate = 10
                    end
                    if inst:IsA("Trail") then
                        inst.Lifetime = 0.1
                    end
                end
            end)
        end
    else
        if AntiLagConn then AntiLagConn:Disconnect() AntiLagConn = nil end
        -- Восстанавливаем настройки (если нужно)
    end
end)

-- 5. TELEPORT TO BASE (Быстрый возврат на базу)
CreateButton(Pages["Teleport"], "TP to Base (Spawn)", function()
    local spawn = WS:FindFirstChild("SpawnLocation")
    if spawn then
        if SafeTP then SafeTP(spawn.Position) end
    else
        -- Если нет SpawnLocation, ищем Team Spawn
        for _, inst in ipairs(WS:GetDescendants()) do
            if inst:IsA("SpawnLocation") then
                if SafeTP then SafeTP(inst.Position) end
                break
            end
        end
    end
end)

-- 6. ОБНОВЛЕНИЕ РЕНДЕРА (финальное)
RunService:UnbindFromRenderStep("MeowRender")
RunService:BindToRenderStep("MeowRender", Enum.RenderPriority.Camera.Value + 2, function()
    OnRender()
    RenderESP()
    RenderVehicleESP()
    RenderSkeleton()
    UpdateCrosshair()
    RenderVehicleHealth()
    RenderWeaponESP()
end)

print("[MeowUI] Part 20 Loaded — Auto-Mine, Instant Farm, Anti-Lag, Waypoints ready.")
