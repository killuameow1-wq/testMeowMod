--[[
    MeowMod V4.2 — Adaptive Mobile UI
    - UIScale под размер экрана
    - Max size = 92% ширины / 85% высоты
    - Минимализм: тонкие линии, акцентная полоска
    - Две кнопки: свернуть / полная выгрузка
]]

if getgenv().MeowModUnload then pcall(getgenv().MeowModUnload) end
if getgenv()._MeowModGui then pcall(function() getgenv()._MeowModGui:Destroy() end) end
do
    local lp = game:GetService("Players").LocalPlayer
    local old = lp and lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("MeowMod")
    if old then old:Destroy() end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Http = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local LP = Players.LocalPlayer
local Camera = WS.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

-- ═══════════════ CONFIG ═══════════════
local CONFIG_PATH = "MeowMod_V4.json"
local function HasFS() return typeof(writefile) == "function" and typeof(readfile) == "function" end

local DefaultConfig = {
    SilentAim=false, FOVPercent=25, MaxDistance=5000,
    StrictFOV=true, ShowFOV=true, PredictionMultiplier=1.0,
    Headshot=false, WallCheck=false, TeamFilter="all", Bypass=true,
    ESP=false, ESP_Line=false, ESP_Box=false, ESP_Name=false,
    ESP_Dist=false, ESP_HP=false, ESP_Skeleton=false,
    ESP_Offscreen=false, ESP_DistBar=false, ESP_Chams=false,
    V_ESP=false, V_ESP_Box=false, V_ESP_Name=false, V_ESP_Dist=false, V_ESP_MaxDist=5000,
    HitboxExpander=false, HitboxSize=6,
    Crosshair=false, CH_Size=12,
    TP_PlayerOffset=5, TP_SafeDrop=4, TP_DropToGround=true,
    SpeedOn=false, SpeedValue=16,
    FlyOn=false, FlySpeed=50,
    Noclip=false, InfJump=false,
    JumpPowerOn=false, JumpPower=50,
    Fullbright=false, FogOff=false, ClockTime=12, Gravity=196.2,
    AntiAFK=false, FPSCap=240,
    ColorNeon=Color3.fromRGB(0, 240, 255),
    ColorBg=Color3.fromRGB(10, 10, 14),
    ColorPanel=Color3.fromRGB(18, 18, 24),
    ColorVehicle=Color3.fromRGB(255, 165, 0),
    ColorSilent=Color3.fromRGB(180, 0, 255),
}
local Config = {}
for k, v in pairs(DefaultConfig) do Config[k] = v end

local function SerializeConfig()
    local t = {}
    for k, v in pairs(Config) do
        if typeof(v) == "Color3" then t[k] = {"__c3", v.R, v.G, v.B}
        elseif type(v) == "boolean" or type(v) == "number" or type(v) == "string" then t[k] = v end
    end
    return t
end
local function DeserializeConfig(t)
    for k, v in pairs(t) do
        if type(v) == "table" and v[1] == "__c3" then Config[k] = Color3.new(v[2], v[3], v[4])
        elseif type(v) == "boolean" or type(v) == "number" or type(v) == "string" then Config[k] = v end
    end
end
local function LoadConfig()
    if not HasFS() then return end
    local ok, data = pcall(function()
        if not isfile(CONFIG_PATH) then return nil end
        return readfile(CONFIG_PATH)
    end)
    if not ok or not data or data == "" then return end
    local ok2, parsed = pcall(function() return Http:JSONDecode(data) end)
    if ok2 and parsed then DeserializeConfig(parsed) end
end
local function SaveConfig()
    if not HasFS() then return false end
    return pcall(function() writefile(CONFIG_PATH, Http:JSONEncode(SerializeConfig())) end)
end
LoadConfig()

-- ═══════════════ STATE ═══════════════
local Connections, Drawings = {}, {}
local function AddConn(c) table.insert(Connections, c) end
local function AddDraw(d) table.insert(Drawings, d) end

local MM = {Version = "4.2.0", Modules = {}}
function MM.Register(n, m) MM.Modules[n] = m end
function MM.Get(n) return MM.Modules[n] end

-- ═══════════════ ADAPTIVE SIZING ═══════════════
local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(375, 812)
local screenW = viewport.X
local screenH = viewport.Y

-- Окно: max 92% ширины, max 85% высоты, но не больше 360x560
local BASE_W = 340
local BASE_H = 520
local maxW = math.min(screenW * 0.92, 360)
local maxH = math.min(screenH * 0.85, 560)
local winW = math.min(BASE_W, maxW)
local winH = math.min(BASE_H, maxH)

-- UIScale для мелких экранов
local scaleFactor = math.min(winW / BASE_W, winH / BASE_H, 1)

-- Слушаем смену размера экрана
local function RecalcSize()
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(375, 812)
    maxW = math.min(vp.X * 0.92, 360)
    maxH = math.min(vp.Y * 0.85, 560)
    winW = math.min(BASE_W, maxW)
    winH = math.min(BASE_H, maxH)
    scaleFactor = math.min(winW / BASE_W, winH / BASE_H, 1)
end

-- ═══════════════ GUI ROOT ═══════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeowMod"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PG
getgenv()._MeowModGui = ScreenGui

-- ═══════════════ THEME (minimal dark) ═══════════════
local THEME = {
    Bg        = Color3.fromRGB(16, 17, 22),
    Surface   = Color3.fromRGB(22, 24, 30),
    SurfaceHi = Color3.fromRGB(28, 31, 39),
    Border    = Color3.fromRGB(38, 42, 52),
    Accent    = Config.ColorNeon,
    AccentDim = Color3.fromRGB(0, 170, 190),
    Text      = Color3.fromRGB(230, 234, 242),
    SubText   = Color3.fromRGB(140, 148, 165),
    Muted     = Color3.fromRGB(90, 98, 115),
    Track     = Color3.fromRGB(40, 45, 58),
    Danger    = Color3.fromRGB(255, 90, 110),
    Warn      = Color3.fromRGB(255, 190, 70),
    Success   = Color3.fromRGB(80, 220, 140),
}

local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = inst
    return c
end
local function stroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.Border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.4
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

-- ═══════════════ MAIN WINDOW (adaptive) ═══════════════
local isOpen = false
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.Size = UDim2.new(0, winW, 0, winH)
Main.BackgroundColor3 = THEME.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui
corner(Main, 14)
stroke(Main, THEME.Border, 1, 0.3)

local MainScale = Instance.new("UIScale")
MainScale.Scale = scaleFactor
MainScale.Parent = Main

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 54)
Header.BackgroundColor3 = THEME.Surface
Header.BorderSizePixel = 0
Header.Active = true
Header.Parent = Main
corner(Header, 14)

-- Акцентная полоска слева
local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(0, 3, 0, 24)
AccentBar.Position = UDim2.new(0, 14, 0.5, -12)
AccentBar.BackgroundColor3 = THEME.Accent
AccentBar.BorderSizePixel = 0
AccentBar.Parent = Header
corner(AccentBar, 2)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -180, 0, 22)
TitleLabel.Position = UDim2.new(0, 26, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "MEOW"
TitleLabel.TextColor3 = THEME.Text
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 17
TitleLabel.Parent = Header

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Size = UDim2.new(1, -180, 0, 14)
SubtitleLabel.Position = UDim2.new(0, 26, 0, 30)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text = "v4.2 · adaptive"
SubtitleLabel.TextColor3 = THEME.Muted
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.Font = Enum.Font.GothamMedium
SubtitleLabel.TextSize = 11
SubtitleLabel.Parent = Header

-- Кнопка закрыть (свернуть)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -76, 0.5, -16)
CloseBtn.BackgroundColor3 = THEME.SurfaceHi
CloseBtn.Text = "×"
CloseBtn.TextColor3 = THEME.Text
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.AutoButtonColor = false
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
corner(CloseBtn, 8)
stroke(CloseBtn, THEME.Border, 1, 0.4)

-- Кнопка полной выгрузки
local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Size = UDim2.new(0, 32, 0, 32)
UnloadBtn.Position = UDim2.new(1, -40, 0.5, -16)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 38)
UnloadBtn.Text = "⏻"
UnloadBtn.TextColor3 = THEME.Danger
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.TextSize = 16
UnloadBtn.AutoButtonColor = false
UnloadBtn.BorderSizePixel = 0
UnloadBtn.Parent = Header
corner(UnloadBtn, 8)
stroke(UnloadBtn, THEME.Danger, 1, 0.5)

-- Drag на тач
local dragStart, startPos = nil, nil
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart = inp.Position
        startPos = Main.Position
    end
end)
UIS.InputChanged:Connect(function(inp)
    if dragStart and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = inp.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart = nil; startPos = nil
    end
end)

-- ═══════════════ TAB BAR ═══════════════
local TabBar = Instance.new("ScrollingFrame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -20, 0, 36)
TabBar.Position = UDim2.new(0, 10, 0, 62)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 0
TabBar.ScrollingDirection = Enum.ScrollingDirection.X
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
TabBar.Parent = Main
local TL = Instance.new("UIListLayout", TabBar)
TL.FillDirection = Enum.FillDirection.Horizontal
TL.Padding = UDim.new(0, 6)
TL.SortOrder = Enum.SortOrder.LayoutOrder
TL.VerticalAlignment = Enum.VerticalAlignment.Center

-- Тонкая линия под табами
local TabDivider = Instance.new("Frame")
TabDivider.Size = UDim2.new(1, -20, 0, 1)
TabDivider.Position = UDim2.new(0, 10, 0, 104)
TabDivider.BackgroundColor3 = THEME.Border
TabDivider.BorderSizePixel = 0
TabDivider.Parent = Main

local Pages = {}
local TabButtons = {}
local function SelectTab(name)
    for n, p in pairs(Pages) do p.Visible = (n == name) end
    for n, b in pairs(TabButtons) do
        if n == name then
            b.BackgroundColor3 = THEME.Accent
            b.TextColor3 = THEME.Bg
            b.Font = Enum.Font.GothamBold
        else
            b.BackgroundColor3 = THEME.SurfaceHi
            b.TextColor3 = THEME.SubText
            b.Font = Enum.Font.GothamMedium
        end
    end
end
local function CreateTab(name, order)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 0, 0, 32)
    Btn.AutomaticSize = Enum.AutomaticSize.X
    Btn.BackgroundColor3 = THEME.SurfaceHi
    Btn.Text = "  " .. name .. "  "
    Btn.TextColor3 = THEME.SubText
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 12
    Btn.LayoutOrder = order
    Btn.AutoButtonColor = false
    Btn.BorderSizePixel = 0
    Btn.Parent = TabBar
    corner(Btn, 8)
    TabButtons[name] = Btn

    local Page = Instance.new("ScrollingFrame")
    Page.Name = name
    Page.Size = UDim2.new(1, -20, 1, -120)
    Page.Position = UDim2.new(0, 10, 0, 112)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = THEME.Accent
    Page.ScrollBarImageTransparency = 0.4
    Page.BorderSizePixel = 0
    Page.Parent = Main
    local L = Instance.new("UIListLayout", Page)
    L.Padding = UDim.new(0, 6)
    L.SortOrder = Enum.SortOrder.LayoutOrder
    Pages[name] = Page

    Btn.MouseButton1Click:Connect(function() SelectTab(name) end)
end

-- ═══════════════ WIDGETS (минимализм) ═══════════════
local SaveDebounce = 0
local function QueueSave()
    SaveDebounce = SaveDebounce + 1
    local myId = SaveDebounce
    task.delay(0.5, function() if myId == SaveDebounce then SaveConfig() end end)
end

local function CreateToggle(parent, name, def, cb, cfgKey)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 46)
    Btn.BackgroundColor3 = THEME.Surface
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Btn.BorderSizePixel = 0
    Btn.Parent = parent
    corner(Btn, 8)

    local TLbl = Instance.new("TextLabel")
    TLbl.Size = UDim2.new(1, -80, 1, 0)
    TLbl.Position = UDim2.new(0, 14, 0, 0)
    TLbl.BackgroundTransparency = 1
    TLbl.Text = name
    TLbl.TextColor3 = THEME.Text
    TLbl.TextXAlignment = Enum.TextXAlignment.Left
    TLbl.Font = Enum.Font.GothamMedium
    TLbl.TextSize = 13
    TLbl.Parent = Btn

    local Ind = Instance.new("Frame")
    Ind.Size = UDim2.new(0, 40, 0, 22)
    Ind.Position = UDim2.new(1, -54, 0.5, -11)
    Ind.BackgroundColor3 = def and THEME.Accent or THEME.Track
    Ind.BorderSizePixel = 0
    Ind.Parent = Btn
    corner(Ind, 11)

    local Circ = Instance.new("Frame")
    Circ.Size = UDim2.new(0, 16, 0, 16)
    Circ.Position = def and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    Circ.BackgroundColor3 = Color3.new(1, 1, 1)
    Circ.BorderSizePixel = 0
    Circ.Parent = Ind
    corner(Circ, 8)

    local State = def
    AddConn(Btn.MouseButton1Click:Connect(function()
        State = not State
        Ind.BackgroundColor3 = State and THEME.Accent or THEME.Track
        Circ.Position = State and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        if cfgKey then Config[cfgKey] = State end
        if cb then cb(State) end
        QueueSave()
    end))
    return Btn
end

local function CreateSlider(parent, name, mn, mx, def, cb, cfgKey)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, 0, 0, 60)
    F.BackgroundColor3 = THEME.Surface
    F.BorderSizePixel = 0
    F.Parent = parent
    corner(F, 8)

    local TLbl = Instance.new("TextLabel")
    TLbl.Size = UDim2.new(1, -80, 0, 20)
    TLbl.Position = UDim2.new(0, 14, 0, 6)
    TLbl.BackgroundTransparency = 1
    TLbl.Text = name
    TLbl.TextColor3 = THEME.Text
    TLbl.TextXAlignment = Enum.TextXAlignment.Left
    TLbl.Font = Enum.Font.GothamMedium
    TLbl.TextSize = 13
    TLbl.Parent = F

    local ValLbl = Instance.new("TextLabel")
    ValLbl.Size = UDim2.new(0, 50, 0, 20)
    ValLbl.Position = UDim2.new(1, -64, 0, 6)
    ValLbl.BackgroundTransparency = 1
    ValLbl.Text = tostring(def)
    ValLbl.TextColor3 = THEME.Accent
    ValLbl.Font = Enum.Font.GothamBold
    ValLbl.TextSize = 13
    ValLbl.Parent = F

    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(1, -28, 0, 4)
    Bg.Position = UDim2.new(0, 14, 0, 42)
    Bg.BackgroundColor3 = THEME.Track
    Bg.BorderSizePixel = 0
    Bg.Parent = F
    corner(Bg, 2)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((def - mn) / (mx - mn), 0, 1, 0)
    Fill.BackgroundColor3 = THEME.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Bg
    corner(Fill, 2)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.Position = UDim2.new((def - mn) / (mx - mn), -6, 0.5, -6)
    Knob.BackgroundColor3 = Color3.new(1, 1, 1)
    Knob.BorderSizePixel = 0
    Knob.Parent = Fill
    corner(Knob, 6)

    local Hit = Instance.new("TextButton")
    Hit.Size = UDim2.new(1, 0, 4, 0)
    Hit.Position = UDim2.new(0, 0, -1.5, 0)
    Hit.BackgroundTransparency = 1
    Hit.Text = ""
    Hit.Parent = Bg

    local dragging = false
    local function Update(input)
        local pos = math.clamp((input.Position.X - Bg.AbsolutePosition.X) / Bg.AbsoluteSize.X, 0, 1)
        local v = math.floor(mn + (mx - mn) * pos)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        Knob.Position = UDim2.new(pos, -6, 0.5, -6)
        ValLbl.Text = tostring(v)
        if cfgKey then Config[cfgKey] = v end
        if cb then cb(v) end
    end
    AddConn(Hit.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; Update(inp)
        end
    end))
    AddConn(UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            Update(inp)
        end
    end))
    AddConn(UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            if dragging then QueueSave() end
            dragging = false
        end
    end))
    return F
end

local function CreateButton(parent, name, cb, color)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 46)
    Btn.BackgroundColor3 = color or THEME.SurfaceHi
    Btn.Text = name
    Btn.TextColor3 = color and Color3.new(1, 1, 1) or THEME.Text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.AutoButtonColor = false
    Btn.BorderSizePixel = 0
    Btn.Parent = parent
    corner(Btn, 8)
    stroke(Btn, color or THEME.Border, 1, 0.5)
    Btn.MouseButton1Click:Connect(function()
        local old = Btn.BackgroundColor3
        Btn.BackgroundColor3 = THEME.Success
        task.wait(0.12)
        Btn.BackgroundColor3 = old
        if cb then cb() end
    end)
    return Btn
end

local function CreateCycle(parent, name, options, default, cb, cfgKey)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 46)
    Btn.BackgroundColor3 = THEME.Surface
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Btn.BorderSizePixel = 0
    Btn.Parent = parent
    corner(Btn, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -100, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.Parent = Btn

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 76, 0, 26)
    valLbl.Position = UDim2.new(1, -86, 0.5, -13)
    valLbl.BackgroundColor3 = THEME.SurfaceHi
    valLbl.Text = default
    valLbl.TextColor3 = THEME.Accent
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.BorderSizePixel = 0
    valLbl.Parent = Btn
    corner(valLbl, 6)

    local idx = 1
    for i, o in ipairs(options) do if o == default then idx = i break end end
    Btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        valLbl.Text = options[idx]
        if cfgKey then Config[cfgKey] = options[idx] end
        if cb then cb(options[idx]) end
        QueueSave()
    end)
    return Btn
end

-- ═══════════════ TAB CREATION ═══════════════
CreateTab("Combat", 1)
CreateTab("Visuals", 2)
CreateTab("Players", 3)
CreateTab("Movement", 4)
CreateTab("World", 5)
CreateTab("Vehicles", 6)
CreateTab("Teleport", 7)
CreateTab("Misc", 8)
CreateTab("Config", 9)

-- ═══════════════ FLOAT BUTTON (маленькая, с краю) ═══════════════
local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "FloatBtn"
FloatBtn.Size = UDim2.new(0, 44, 0, 44)
FloatBtn.Position = UDim2.new(0, 8, 0.5, -22)
FloatBtn.BackgroundColor3 = THEME.Surface
FloatBtn.Text = "≡"
FloatBtn.TextColor3 = THEME.Accent
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 20
FloatBtn.BorderSizePixel = 0
FloatBtn.Active = true
FloatBtn.Draggable = true
FloatBtn.Parent = ScreenGui
corner(FloatBtn, 22)
stroke(FloatBtn, THEME.Accent, 1.5, 0.4)

-- ═══════════════ OPEN / CLOSE / UNLOAD ═══════════════
local function OpenMenu()
    Main.Visible = true
    FloatBtn.Visible = false
    isOpen = true
end
local function CloseMenu()
    Main.Visible = false
    FloatBtn.Visible = true
    isOpen = false
end

FloatBtn.MouseButton1Click:Connect(OpenMenu)
CloseBtn.MouseButton1Click:Connect(CloseMenu)

local function FullUnload()
    if getgenv()._MeowModUnloading then return end
    getgenv()._MeowModUnloading = true
    pcall(SaveConfig)
    for _, c in pairs(Connections) do
        pcall(function() if typeof(c) == "RBXScriptConnection" then c:Disconnect() end end)
    end
    Connections = {}
    for _, name in ipairs({"MeowESP", "MeowVESP", "MeowLogic"}) do
        pcall(function() RunService:UnbindFromRenderStep(name) end)
    end
    for _, d in pairs(Drawings) do pcall(function() d:Remove() end) end
    Drawings = {}
    for _, p in pairs(Players:GetPlayers()) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
                hrp.CanCollide = true
            end)
        end
        local char = p.Character
        if char then
            local hl = char:FindFirstChild("MeowCham_" .. p.Name)
            if hl then pcall(function() hl:Destroy() end) end
        end
    end
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        mt.__namecall = newcclosure(nil)
        setreadonly(mt, true)
    end)
    pcall(function() ScreenGui:Destroy() end)
    if getgenv()._MeowModGui == ScreenGui then getgenv()._MeowModGui = nil end
    getgenv().MeowModUnload = nil
    getgenv()._MeowModUnloading = nil
end
getgenv().MeowModUnload = FullUnload
UnloadBtn.MouseButton1Click:Connect(FullUnload)

-- ═══════════════ MOVEMENT ═══════════════
local Fly = {active = false, conn = nil, speed = 50}
function Fly.Start()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    Fly.active = true
    Fly.conn = RunService.Heartbeat:Connect(function()
        if not Fly.active then return end
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then hrp.CFrame = hrp.CFrame + dir.Unit * Fly.speed * 0.1 end
    end)
end
function Fly.Stop() Fly.active = false if Fly.conn then Fly.conn:Disconnect() Fly.conn = nil end end

local Noclip = {active = false, conn = nil}
function Noclip.Start()
    Noclip.active = true
    Noclip.conn = RunService.Stepped:Connect(function()
        if not Noclip.active then return end
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end)
end
function Noclip.Stop() Noclip.active = false if Noclip.conn then Noclip.conn:Disconnect() Noclip.conn = nil end end

local InfJump = {active = false, conn = nil}
function InfJump.Start()
    InfJump.active = true
    InfJump.conn = UIS.JumpRequest:Connect(function()
        if not InfJump.active then return end
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end
function InfJump.Stop() InfJump.active = false if InfJump.conn then InfJump.conn:Disconnect() InfJump.conn = nil end end

local function ApplySpeed()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = Config.SpeedOn and Config.SpeedValue or 16 end
end
local function ApplyJumpPower()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.UseJumpPower = true end)
        hum.JumpPower = Config.JumpPowerOn and Config.JumpPower or 50
    end
end

-- ═══════════════ WORLD ═══════════════
local WorldState = {oldBright = nil, oldFogEnd = nil, oldGravity = nil}
local function ApplyFullbright()
    if Config.Fullbright then
        if not WorldState.oldBright then
            WorldState.oldBright = {Ambient = Lighting.Ambient, Outdoor = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness}
        end
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 3
    else
        if WorldState.oldBright then
            Lighting.Ambient = WorldState.oldBright.Ambient
            Lighting.OutdoorAmbient = WorldState.oldBright.Outdoor
            Lighting.Brightness = WorldState.oldBright.Brightness
            WorldState.oldBright = nil
        end
    end
end
local function ApplyFogOff()
    if Config.FogOff then
        if not WorldState.oldFogEnd then WorldState.oldFogEnd = Lighting.FogEnd end
        Lighting.FogEnd = 1e6
    else
        if WorldState.oldFogEnd then Lighting.FogEnd = WorldState.oldFogEnd WorldState.oldFogEnd = nil end
    end
end
local function ApplyClock() Lighting.ClockTime = Config.ClockTime end
local function ApplyGravity()
    if not WorldState.oldGravity then WorldState.oldGravity = WS.Gravity end
    WS.Gravity = Config.Gravity
end

-- ═══════════════ TELEPORT ═══════════════
local function GetGroundY(pos)
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LP.Character}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local hit = WS:Raycast(pos + Vector3.new(0, 500, 0), Vector3.new(0, -1000, 0), rp)
    if hit then return hit.Position.Y end
    return nil
end
local function SafeTeleport(pos, label)
    local c = LP.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local targetY = pos.Y
    if Config.TP_DropToGround then
        local groundY = GetGroundY(pos)
        if groundY then targetY = groundY + 3.5 end
    end
    hrp.CFrame = CFrame.new(Vector3.new(pos.X, targetY + (Config.TP_SafeDrop or 4), pos.Z))
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    return true
end

-- ═══════════════ UTIL ═══════════════
local function DistToColor(d)
    local t = math.clamp(d / 400, 0, 1)
    if d <= 100 then
        local k = d / 100
        return Color3.fromRGB(math.floor(255 - k * 55), math.floor(60 + k * 120), 60)
    end
    return Color3.fromRGB(math.floor(200 * (1 - t)), math.floor(180 + 75 * t), math.floor(60 + 80 * t))
end
local function PassesTeamFilter(p)
    if Config.TeamFilter == "all" then return true end
    local myTeam = LP.Team
    if not myTeam then return true end
    if Config.TeamFilter == "my" then return p.Team == myTeam end
    if Config.TeamFilter == "enemy" then return p.Team ~= myTeam end
    return true
end

-- ═══════════════ EXTENSION-01: AIM EXTENDED ═══════════════
local Hitscan = {}
function Hitscan.Visible(from, to, ignore)
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = ignore or {}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.IgnoreWater = true
    return workspace:Raycast(from, to - from, rp) == nil
end
function Hitscan.Closest(from, maxDist)
    local best, bestD = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local d = (from - head.Position).Magnitude
                if d < bestD and d <= (maxDist or math.huge) then bestD = d best = p end
            end
        end
    end
    return best, bestD
end

local Trajectory = {GRAVITY = 196.2}
function Trajectory.FallTime(verticalDist)
    if verticalDist <= 0 then return 0 end
    return math.sqrt(2 * verticalDist / Trajectory.GRAVITY)
end
function Trajectory.Intercept(part, projSpeed, from)
    if not part then return from end
    local dist = (part.Position - from).Magnitude
    if projSpeed <= 0 then return part.Position end
    local t = dist / projSpeed
    local vel = part.AssemblyLinearVelocity or Vector3.zero
    return part.Position + vel * t + Vector3.new(0, -0.5 * Trajectory.GRAVITY * t * t, 0)
end
function Trajectory.LeadDir(part, projSpeed, from)
    if not part then return Vector3.zero end
    return (Trajectory.Intercept(part, projSpeed, from) - from).Unit
end

local Smoothing = {factor = 0.5}
function Smoothing.Lerp(cur, tgt, factor)
    factor = factor or Smoothing.factor
    return cur + (tgt - cur) * factor
end
function Smoothing.Vector(cur, tgt, factor)
    factor = factor or Smoothing.factor
    return Vector3.new(
        cur.X + (tgt.X - cur.X) * factor,
        cur.Y + (tgt.Y - cur.Y) * factor,
        cur.Z + (tgt.Z - cur.Z) * factor
    )
end

local AimStats = {hits = 0, misses = 0, shots = 0, start = tick()}
function AimStats.Hit() AimStats.hits = AimStats.hits + 1 end
function AimStats.Miss() AimStats.misses = AimStats.misses + 1 end
function AimStats.Shot() AimStats.shots = AimStats.shots + 1 end
function AimStats.Accuracy()
    local total = AimStats.hits + AimStats.misses
    if total == 0 then return 0 end
    return AimStats.hits / total
end
function AimStats.Reset()
    AimStats.hits = 0; AimStats.misses = 0; AimStats.shots = 0; AimStats.start = tick()
end
function AimStats.Report()
    return {
        hits = AimStats.hits, misses = AimStats.misses, shots = AimStats.shots,
        accuracy = AimStats.Accuracy(), duration = tick() - AimStats.start,
    }
end

local Humanizer = {active = true, jitterScale = 0.1, delayMin = 0.01, delayMax = 0.05}
function Humanizer.Jitter(vec, scale)
    if not Humanizer.active then return vec end
    scale = scale or Humanizer.jitterScale
    return vec + Vector3.new(
        (math.random() - 0.5) * scale,
        (math.random() - 0.5) * scale,
        (math.random() - 0.5) * scale
    )
end
function Humanizer.Delay()
    return Humanizer.delayMin + math.random() * (Humanizer.delayMax - Humanizer.delayMin)
end
function Humanizer.SetJitter(v) Humanizer.jitterScale = v end
function Humanizer.SetDelayRange(mn, mx) Humanizer.delayMin = mn Humanizer.delayMax = mx end

local TriggerBot = {active = false, threshold = 30, lastFire = 0, cooldown = 0.05}
function TriggerBot.SetThreshold(v) TriggerBot.threshold = v end
function TriggerBot.SetCooldown(v) TriggerBot.cooldown = v end
function TriggerBot.Toggle(on) TriggerBot.active = on end
function TriggerBot.ShouldFire(target)
    if not TriggerBot.active or not target then return false end
    local now = tick()
    if now - TriggerBot.lastFire < TriggerBot.cooldown then return false end
    local head = target.Character and target.Character:FindFirstChild("Head")
    if not head then return false end
    local sp, on = Camera:WorldToViewportPoint(head.Position)
    if not on then return false end
    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    local d = math.sqrt((sp.X - cx) ^ 2 + (sp.Y - cy) ^ 2)
    if d <= TriggerBot.threshold then
        TriggerBot.lastFire = now
        return true
    end
    return false
end

local FOVShapes = {}
function FOVShapes.Circle(cx, cy, px, py, r) return math.sqrt((px - cx) ^ 2 + (py - cy) ^ 2) <= r end
function FOVShapes.Square(cx, cy, px, py, half) return math.abs(px - cx) <= half and math.abs(py - cy) <= half end
function FOVShapes.Triangle(cx, cy, px, py, size)
    local dx, dy = px - cx, py - cy
    if dy < -size or dy > size then return false end
    local half = size * (1 - (dy + size) / (2 * size))
    return math.abs(dx) <= half
end
function FOVShapes.Check(shape, cx, cy, px, py, a)
    if shape == "circle" then return FOVShapes.Circle(cx, cy, px, py, a or 100)
    elseif shape == "square" then return FOVShapes.Square(cx, cy, px, py, a or 100)
    elseif shape == "triangle" then return FOVShapes.Triangle(cx, cy, px, py, a or 100) end
    return false
end

local Targeting = {weights = {}}
function Targeting.SetWeight(k, v) Targeting.weights[k] = v end
function Targeting.GetWeight(k, d) return Targeting.weights[k] or d or 1 end
function Targeting.Score(player, myPos, myTeam, opts)
    opts = opts or {}
    local char = player.Character
    if not char then return -math.huge end
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not (head and hum and hrp and hum.Health > 0) then return -math.huge end
    if myTeam and player.Team == myTeam then return -math.huge end
    local d = (myPos - head.Position).Magnitude
    if d > (opts.maxDist or 5000) then return -math.huge end
    local score = (500 - d) * Targeting.GetWeight("dist", 1)
    local hp = hum.Health / math.max(hum.MaxHealth, 1)
    score = score + hp * 100 * Targeting.GetWeight("hp", 1)
    if opts.lastTarget == player then score = score + 40 * Targeting.GetWeight("hyst", 1) end
    local look = hrp.CFrame.LookVector
    local toMe = (myPos - hrp.Position).Unit
    if look:Dot(toMe) > 0.3 then score = score + 80 * Targeting.GetWeight("face", 1) end
    return score
end

-- ═══════════════ EXTENSION-01: ESP EXTENDED ═══════════════
local Tracers = {}
local tracerDraws = {}
function Tracers.Create(player)
    if tracerDraws[player] then return tracerDraws[player] end
    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Visible = false
    tracerDraws[player] = line
    return line
end
function Tracers.Remove(player)
    if tracerDraws[player] then pcall(function() tracerDraws[player]:Remove() end) tracerDraws[player] = nil end
end
function Tracers.Draw(player, from, to, color)
    local line = Tracers.Create(player)
    line.From = from; line.To = to; line.Color = color
    line.Visible = true
end
function Tracers.HideAll()
    for _, l in pairs(tracerDraws) do pcall(function() l.Visible = false end) end
end

local NametagExtras = {}
function NametagExtras.Weapon(player)
    local char = player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end
function NametagExtras.HealthColor(hum)
    if not hum or hum.MaxHealth <= 0 then return Color3.new(1, 1, 1) end
    local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
    return Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
end

local TeamDetect = {}
function TeamDetect.Same(p1, p2) return p1 and p2 and p1.Team and p1.Team == p2.Team end
function TeamDetect.Enemy(p1, p2)
    if not p1 or not p2 then return false end
    if not p1.Team or not p2.Team then return true end
    return p1.Team ~= p2.Team
end
function TeamDetect.Color(p, myTeam)
    if not p.Team or not myTeam then return Color3.fromRGB(200, 200, 200) end
    if p.Team == myTeam then return Color3.fromRGB(80, 200, 255) end
    return Color3.fromRGB(255, 80, 80)
end
function TeamDetect.Prefix(p, myTeam)
    if not p.Team or not myTeam then return "" end
    if p.Team == myTeam then return "[A] " end
    return "[E] "
end

local OffscreenArrows = {}
function OffscreenArrows.Pos(sp, vp, margin)
    margin = margin or 40
    local cx, cy = vp.X / 2, vp.Y / 2
    local dx, dy = sp.X - cx, sp.Y - cy
    if math.abs(dx) < 0.001 and math.abs(dy) < 0.001 then dx = 1 end
    local tx = (cx - margin) / math.max(math.abs(dx), 0.0001)
    local ty = (cy - margin) / math.max(math.abs(dy), 0.0001)
    local t = math.min(tx, ty)
    return Vector2.new(cx + dx * t, cy + dy * t)
end

local FacingArrows = {}
local facingDraws = {}
function FacingArrows.Create(player)
    if facingDraws[player] then return facingDraws[player] end
    local tri = Drawing.new("Triangle")
    tri.Filled = true
    tri.Visible = false
    facingDraws[player] = tri
    return tri
end
function FacingArrows.Remove(player)
    if facingDraws[player] then pcall(function() facingDraws[player]:Remove() end) facingDraws[player] = nil end
end
function FacingArrows.Draw(player, ox, oy, dx, dy, color)
    local tri = FacingArrows.Create(player)
    local len = 12
    tri.PointA = Vector2.new(ox + dx * len, oy + dy * len)
    tri.PointB = Vector2.new(ox - dy * 5, oy + dx * 5)
    tri.PointC = Vector2.new(ox + dy * 5, oy - dx * 5)
    tri.Color = color or Color3.new(1, 1, 1)
    tri.Visible = true
end
function FacingArrows.HideAll()
    for _, tri in pairs(facingDraws) do pcall(function() tri.Visible = false end) end
end

-- ═══════════════ EXTENSION-01: WAYPOINTS ═══════════════
local Waypoints = {list = {}, diskPath = "MeowV4_waypoints.json"}
function Waypoints.Add(name, pos)
    Waypoints.list[name] = {x = pos.X, y = pos.Y, z = pos.Z}
    return true
end
function Waypoints.Remove(name) Waypoints.list[name] = nil end
function Waypoints.Get(name)
    local w = Waypoints.list[name]
    if not w then return nil end
    return Vector3.new(w.x, w.y, w.z)
end
function Waypoints.All() return Waypoints.list end
function Waypoints.Goto(name)
    local pos = Waypoints.Get(name)
    if not pos then return false end
    SafeTeleport(pos, "wp:" .. name)
    return true
end
function Waypoints.Count()
    local n = 0 for _ in pairs(Waypoints.list) do n = n + 1 end
    return n
end
function Waypoints.SaveToDisk()
    if not HasFS() then return false end
    return pcall(function()
        writefile(Waypoints.diskPath, Http:JSONEncode(Waypoints.list))
    end)
end
function Waypoints.LoadFromDisk()
    if not HasFS() then return false end
    local ok, raw = pcall(function()
        if not isfile(Waypoints.diskPath) then return nil end
        return readfile(Waypoints.diskPath)
    end)
    if not ok or not raw or raw == "" then return false end
    local ok2, parsed = pcall(function() return Http:JSONDecode(raw) end)
    if ok2 and parsed then Waypoints.list = parsed return true end
    return false
end
Waypoints.LoadFromDisk()

-- ═══════════════ EXTENSION-01: WORLD SCAN ═══════════════
local WorldScan = {results = {}}
function WorldScan.FindByKeyword(keyword, root)
    root = root or WS
    local found = {}
    local kw = keyword:lower()
    for _, inst in ipairs(root:GetDescendants()) do
        if inst.Name:lower():find(kw, 1, true) then
            local pos = nil
            if inst:IsA("BasePart") then pos = inst.Position
            elseif inst:IsA("Model") and inst.PrimaryPart then pos = inst.PrimaryPart.Position end
            if pos then table.insert(found, {obj = inst, pos = pos, name = inst.Name}) end
        end
    end
    WorldScan.results = found
    return found
end
function WorldScan.Nearest(keyword)
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    local found = WorldScan.FindByKeyword(keyword)
    local best, bestD = nil, math.huge
    for _, item in ipairs(found) do
        local d = (myHrp.Position - item.pos).Magnitude
        if d < bestD then bestD = d best = item end
    end
    return best
end
function WorldScan.Count() return #WorldScan.results end

-- ═══════════════ EXTENSION-01: SPECTATE ═══════════════
local Spectate = {target = nil, oldSubject = nil}
function Spectate.Start(player)
    local cam = WS.CurrentCamera
    if not Spectate.oldSubject then Spectate.oldSubject = cam.CameraSubject end
    Spectate.target = player
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then cam.CameraSubject = hum end
end
function Spectate.Stop()
    local cam = WS.CurrentCamera
    if Spectate.oldSubject then cam.CameraSubject = Spectate.oldSubject end
    Spectate.target = nil
    Spectate.oldSubject = nil
end

-- ═══════════════ EXTENSION-01: PROFILER + LOGGER ═══════════════
local Profiler = {marks = {}, totals = {}}
function Profiler.Start(label) Profiler.marks[label] = tick() end
function Profiler.Stop(label)
    if not Profiler.marks[label] then return end
    local dt = tick() - Profiler.marks[label]
    Profiler.totals[label] = (Profiler.totals[label] or 0) + dt
    Profiler.marks[label] = nil
    return dt
end
function Profiler.Reset() Profiler.marks = {} Profiler.totals = {} end
function Profiler.Report() return Profiler.totals end

local Logger = {buffer = {}, max = 500}
function Logger.Write(cat, msg)
    table.insert(Logger.buffer, {t = tick(), cat = cat or "SYS", msg = tostring(msg)})
    if #Logger.buffer > Logger.max then table.remove(Logger.buffer, 1) end
    print(("[%s] %s"):format(cat or "SYS", msg))
end
function Logger.All() return Logger.buffer end
function Logger.Clear() Logger.buffer = {} end
function Logger.Filter(cat)
    local out = {}
    for _, e in ipairs(Logger.buffer) do
        if e.cat == cat then table.insert(out, e) end
    end
    return out
end

-- ═══════════════ EXTENSION-01: QUICK ACTIONS ═══════════════
local QuickActions = {}
function QuickActions.ToggleESP()
    Config.ESP = not Config.ESP
    Logger.Write("QUICK", "ESP " .. (Config.ESP and "on" or "off"))
end
function QuickActions.ToggleSilent()
    Config.SilentAim = not Config.SilentAim
    Logger.Write("QUICK", "Silent " .. (Config.SilentAim and "on" or "off"))
end
function QuickActions.ToggleNoclip()
    Config.Noclip = not Config.Noclip
    if Config.Noclip then Noclip.Start() else Noclip.Stop() end
    Logger.Write("QUICK", "Noclip " .. (Config.Noclip and "on" or "off"))
end
function QuickActions.ToggleFly()
    Config.FlyOn = not Config.FlyOn
    if Config.FlyOn then Fly.Start() else Fly.Stop() end
    Logger.Write("QUICK", "Fly " .. (Config.FlyOn and "on" or "off"))
end
function QuickActions.ToggleFullbright()
    Config.Fullbright = not Config.Fullbright
    ApplyFullbright()
    Logger.Write("QUICK", "Fullbright " .. (Config.Fullbright and "on" or "off"))
end

-- ═══════════════ EXTENSION-02: PRESETS ═══════════════
local Presets = {list = {}, diskPath = "MeowV4_presets.json"}
function Presets.Save(name)
    local snap = {}
    for k, v in pairs(Config) do
        if typeof(v) == "Color3" then snap[k] = {"__c3", v.R, v.G, v.B}
        elseif type(v) == "number" or type(v) == "boolean" or type(v) == "string" then snap[k] = v end
    end
    Presets.list[name] = snap
    return true
end
function Presets.Load(name)
    local snap = Presets.list[name]
    if not snap then return false end
    for k, v in pairs(snap) do
        if type(v) == "table" and v[1] == "__c3" then Config[k] = Color3.new(v[2], v[3], v[4])
        elseif type(v) == "number" or type(v) == "boolean" or type(v) == "string" then Config[k] = v end
    end
    return true
end
function Presets.Delete(name) Presets.list[name] = nil end
function Presets.All() return Presets.list end
function Presets.Count()
    local n = 0 for _ in pairs(Presets.list) do n = n + 1 end
    return n
end
function Presets.Names()
    local out = {}
    for name in pairs(Presets.list) do table.insert(out, name) end
    table.sort(out)
    return out
end
function Presets.SaveToDisk()
    if not HasFS() then return false end
    return pcall(function()
        writefile(Presets.diskPath, Http:JSONEncode(Presets.list))
    end)
end
function Presets.LoadFromDisk()
    if not HasFS() then return false end
    local ok, raw = pcall(function()
        if not isfile(Presets.diskPath) then return nil end
        return readfile(Presets.diskPath)
    end)
    if not ok or not raw or raw == "" then return false end
    local ok2, parsed = pcall(function() return Http:JSONDecode(raw) end)
    if ok2 and parsed then Presets.list = parsed return true end
    return false
end
Presets.LoadFromDisk()

-- ═══════════════ EXTENSION-02: COLOR PRESETS ═══════════════
local ColorPresets = {
    cyan = Color3.fromRGB(0, 240, 255),
    magenta = Color3.fromRGB(255, 0, 200),
    lime = Color3.fromRGB(140, 255, 0),
    orange = Color3.fromRGB(255, 140, 0),
    red = Color3.fromRGB(255, 60, 60),
    purple = Color3.fromRGB(180, 0, 255),
    white = Color3.fromRGB(255, 255, 255),
    pink = Color3.fromRGB(255, 105, 180),
    gold = Color3.fromRGB(255, 200, 0),
    emerald = Color3.fromRGB(0, 200, 120),
}
function ColorPresets.Apply(name)
    local c = ColorPresets[name]
    if not c then return false end
    THEME.Accent = c
    Config.ColorNeon = c
    Config.ColorSilent = c
    return true
end
function ColorPresets.List()
    local out = {}
    for name, _ in pairs(ColorPresets) do table.insert(out, name) end
    table.sort(out)
    return out
end

-- ═══════════════ EXTENSION-02: NOTIFICATIONS ═══════════════
local Notifications = {queue = {}, max = 5}
local notifContainer = Instance.new("Frame")
notifContainer.Name = "Notifs"
notifContainer.Size = UDim2.new(0, 260, 0, 400)
notifContainer.Position = UDim2.new(1, -270, 0, 10)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 50
notifContainer.Parent = ScreenGui
local nlist = Instance.new("UIListLayout", notifContainer)
nlist.Padding = UDim.new(0, 6)
nlist.VerticalAlignment = Enum.VerticalAlignment.Top
nlist.SortOrder = Enum.SortOrder.LayoutOrder

function Notifications.Push(title, message, color, duration)
    color = color or THEME.Accent
    duration = duration or 3
    local n = Instance.new("Frame")
    n.Size = UDim2.new(1, 0, 0, 52)
    n.BackgroundColor3 = THEME.Surface
    n.BackgroundTransparency = 0.05
    n.BorderSizePixel = 0
    n.ZIndex = 51
    n.Parent = notifContainer
    corner(n, 8)
    stroke(n, color, 1, 0.3)

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 1, -12)
    accentBar.Position = UDim2.new(0, 6, 0, 6)
    accentBar.BackgroundColor3 = color
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 52
    accentBar.Parent = n
    corner(accentBar, 2)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 20)
    titleLbl.Position = UDim2.new(0, 14, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = color
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 52
    titleLbl.Parent = n

    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size = UDim2.new(1, -20, 0, 20)
    msgLbl.Position = UDim2.new(0, 14, 0, 26)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = message
    msgLbl.TextColor3 = THEME.Text
    msgLbl.Font = Enum.Font.GothamMedium
    msgLbl.TextSize = 11
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.ZIndex = 52
    msgLbl.Parent = n

    n.Position = UDim2.new(1, 20, 0, 0)
    TweenService:Create(n, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    task.delay(duration, function()
        if n and n.Parent then
            TweenService:Create(n, TweenInfo.new(0.2), {
                Position = UDim2.new(1, 20, 0, 0),
                BackgroundTransparency = 1
            }):Play()
            task.wait(0.25)
            n:Destroy()
        end
    end)
end

-- ═══════════════ EXTENSION-02: TEXTBOX WIDGET ═══════════════
local function CreateTextbox(parent, name, placeholder, default, onChange)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 58)
    f.BackgroundColor3 = THEME.Surface
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 18)
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.SubText
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.Parent = f

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -28, 0, 26)
    box.Position = UDim2.new(0, 14, 0, 26)
    box.BackgroundColor3 = THEME.Bg
    box.BorderSizePixel = 0
    box.Text = default or ""
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = THEME.Muted
    box.TextColor3 = THEME.Text
    box.Font = Enum.Font.Code
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Parent = f
    corner(box, 6)
    stroke(box, THEME.Border, 1, 0.4)

    box.FocusLost:Connect(function() if onChange then onChange(box.Text) end end)
    return f, box
end

-- ═══════════════ EXTENSION-02: DROPDOWN WIDGET ═══════════════
local function CreateDropdown(parent, name, options, default, cb)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 46)
    container.BackgroundColor3 = THEME.Surface
    container.BorderSizePixel = 0
    container.ClipsDescendants = false
    container.Parent = parent
    corner(container, 8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = container

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.Parent = container

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 90, 0, 26)
    valLbl.Position = UDim2.new(1, -100, 0.5, -13)
    valLbl.BackgroundColor3 = THEME.SurfaceHi
    valLbl.Text = default
    valLbl.TextColor3 = THEME.Accent
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.BorderSizePixel = 0
    valLbl.Parent = container
    corner(valLbl, 6)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, #options * 34 + 4)
    list.Position = UDim2.new(0, 0, 1, 4)
    list.BackgroundColor3 = THEME.Surface
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 100
    list.Parent = container
    corner(list, 8)
    stroke(list, THEME.Border, 1, 0.3)

    local ll = Instance.new("UIListLayout", list)
    ll.Padding = UDim.new(0, 2)
    ll.SortOrder = Enum.SortOrder.LayoutOrder

    local current = default
    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, -8, 0, 30)
        optBtn.LayoutOrder = i
        optBtn.BackgroundColor3 = THEME.SurfaceHi
        optBtn.Text = opt
        optBtn.TextColor3 = THEME.Text
        optBtn.Font = Enum.Font.GothamMedium
        optBtn.TextSize = 12
        optBtn.AutoButtonColor = false
        optBtn.BorderSizePixel = 0
        optBtn.ZIndex = 101
        optBtn.Parent = list
        corner(optBtn, 6)
        optBtn.MouseButton1Click:Connect(function()
            current = opt
            valLbl.Text = opt
            list.Visible = false
            if cb then cb(opt) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
    end)
    return container, function() return current end
end

-- ═══════════════ EXTENSION-02: COLORPICKER WIDGET ═══════════════
local function CreateColorPicker(parent, name, default, onChange)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 46)
    btn.BackgroundColor3 = THEME.Surface
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = parent
    corner(btn, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.Parent = btn

    local sw = Instance.new("Frame")
    sw.Size = UDim2.new(0, 42, 0, 22)
    sw.Position = UDim2.new(1, -56, 0.5, -11)
    sw.BackgroundColor3 = default or THEME.Accent
    sw.BorderSizePixel = 0
    sw.Parent = btn
    corner(sw, 4)
    stroke(sw, Color3.new(1, 1, 1), 1, 0.5)

    local hue = 0
    btn.MouseButton1Click:Connect(function()
        hue = (hue + 0.17) % 1
        local c = Color3.fromHSV(hue, 0.85, 1)
        sw.BackgroundColor3 = c
        if onChange then onChange(c) end
    end)
    return btn
end

-- ═══════════════ EXTENSION-02: CONSOLE UI ═══════════════
local ConsoleUI = {}
function ConsoleUI.Open()
    local existing = ScreenGui:FindFirstChild("MeowConsole")
    if existing then existing:Destroy() end

    local frame = Instance.new("Frame")
    frame.Name = "MeowConsole"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Size = UDim2.new(0, math.min(screenW * 0.92, 440), 0, math.min(screenH * 0.7, 340))
    frame.BackgroundColor3 = THEME.Bg
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.ZIndex = 200
    frame.Parent = ScreenGui
    corner(frame, 12)
    stroke(frame, THEME.Border, 1, 0.2)

    local fs = Instance.new("UIScale")
    fs.Scale = math.min(1, frame.Size.X.Offset / 440)
    fs.Parent = frame

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = THEME.Surface
    header.BorderSizePixel = 0
    header.ZIndex = 201
    header.Parent = frame
    corner(header, 12)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "CONSOLE"
    title.TextColor3 = THEME.Accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 202
    title.Parent = header

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 26, 0, 26)
    close.Position = UDim2.new(1, -32, 0, 5)
    close.BackgroundColor3 = THEME.Danger
    close.Text = "×"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 16
    close.BorderSizePixel = 0
    close.ZIndex = 202
    close.Parent = header
    corner(close, 6)
    close.MouseButton1Click:Connect(function() frame:Destroy() end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -90)
    scroll.Position = UDim2.new(0, 10, 0, 44)
    scroll.BackgroundColor3 = THEME.Surface
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = THEME.Accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex = 201
    scroll.Parent = frame
    corner(scroll, 6)

    local list = Instance.new("UIListLayout", scroll)
    list.Padding = UDim.new(0, 2)

    local function appendRow(text, color)
        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, -10, 0, 16)
        row.BackgroundTransparency = 1
        row.Text = "  " .. text
        row.TextColor3 = color or THEME.Text
        row.Font = Enum.Font.Code
        row.TextSize = 11
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.ZIndex = 202
        row.Parent = scroll
    end

    for _, entry in ipairs(Logger.All()) do
        appendRow(("[" .. entry.cat .. "] " .. entry.msg))
    end

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -80, 0, 30)
    input.Position = UDim2.new(0, 10, 1, -38)
    input.BackgroundColor3 = THEME.Surface
    input.BorderSizePixel = 0
    input.PlaceholderText = "lua command..."
    input.PlaceholderColor3 = THEME.Muted
    input.TextColor3 = THEME.Text
    input.Font = Enum.Font.Code
    input.TextSize = 12
    input.Text = ""
    input.ClearTextOnFocus = false
    input.ZIndex = 202
    input.Parent = frame
    corner(input, 6)
    stroke(input, THEME.Border, 1, 0.4)

    local exec = Instance.new("TextButton")
    exec.Size = UDim2.new(0, 60, 0, 30)
    exec.Position = UDim2.new(1, -70, 1, -38)
    exec.BackgroundColor3 = THEME.Accent
    exec.Text = "RUN"
    exec.TextColor3 = THEME.Bg
    exec.Font = Enum.Font.GothamBold
    exec.TextSize = 12
    exec.BorderSizePixel = 0
    exec.ZIndex = 202
    exec.Parent = frame
    corner(exec, 6)

    local function runCmd()
        local cmd = input.Text
        input.Text = ""
        if cmd == "" then return end
        appendRow("> " .. cmd, THEME.Accent)
        Logger.Write("CMD", cmd)
        local fn = (loadstring or load)(cmd)
        if fn then
            local ok, err = pcall(fn)
            if not ok then
                appendRow("  ERR: " .. tostring(err), THEME.Danger)
                Logger.Write("ERR", tostring(err))
            end
        else
            appendRow("  loadstring unavailable", THEME.Danger)
        end
    end
    exec.MouseButton1Click:Connect(runCmd)
    input.FocusLost:Connect(function(enter) if enter then runCmd() end end)

    return frame
end

-- ═══════════════ EXTENSION-03: AUTOCLICKER ═══════════════
local AutoClick = {active = false, task = nil, delay = 0.05, button = 1}
function AutoClick.Start()
    if AutoClick.active then return end
    AutoClick.active = true
    AutoClick.task = task.spawn(function()
        while AutoClick.active do
            local vu = game:GetService("VirtualUser")
            pcall(function()
                vu:CaptureController()
                if AutoClick.button == 1 then
                    vu:ClickButton1(Vector2.new())
                else
                    vu:ClickButton2(Vector2.new())
                end
            end)
            task.wait(AutoClick.delay)
        end
    end)
end
function AutoClick.Stop()
    AutoClick.active = false
    if AutoClick.task then pcall(function() task.cancel(AutoClick.task) end) AutoClick.task = nil end
end
function AutoClick.SetDelay(d) AutoClick.delay = math.max(0.01, d) end
function AutoClick.SetButton(b) AutoClick.button = b end
function AutoClick.Toggle()
    if AutoClick.active then AutoClick.Stop() else AutoClick.Start() end
    return AutoClick.active
end

-- ═══════════════ EXTENSION-03: CHAT SPAM ═══════════════
local ChatSpam = {active = false, task = nil, message = "meow", delay = 1}
function ChatSpam.FindRemote()
    local re = game:GetService("ReplicatedStorage")
    local ev = re:FindFirstChild("DefaultChatSystemChatEvents")
    if ev then return ev:FindFirstChild("SayMessageRequest") end
    return nil
end
function ChatSpam.Start()
    if ChatSpam.active then return end
    local remote = ChatSpam.FindRemote()
    if not remote then return false end
    ChatSpam.active = true
    ChatSpam.task = task.spawn(function()
        while ChatSpam.active do
            pcall(function() remote:FireServer(ChatSpam.message, "All") end)
            task.wait(ChatSpam.delay)
        end
    end)
    return true
end
function ChatSpam.Stop()
    ChatSpam.active = false
    if ChatSpam.task then pcall(function() task.cancel(ChatSpam.task) end) ChatSpam.task = nil end
end
function ChatSpam.SetMessage(m) ChatSpam.message = m end
function ChatSpam.SetDelay(d) ChatSpam.delay = math.max(0.5, d) end

-- ═══════════════ EXTENSION-03: PING SPOOF ═══════════════
local PingSpoof = {active = false, fakeLatency = 0.05}
function PingSpoof.Enable() PingSpoof.active = true end
function PingSpoof.Disable() PingSpoof.active = false end
function PingSpoof.SetLatency(s) PingSpoof.fakeLatency = s end
function PingSpoof.Wrap(fn)
    return function(...)
        if PingSpoof.active then
            task.wait(PingSpoof.fakeLatency)
        end
        return fn(...)
    end
end

-- ═══════════════ EXTENSION-03: ANTI-AFK V2 ═══════════════
local AntiAFK = {active = false, conn = nil, idleMax = 20}
function AntiAFK.Start()
    if AntiAFK.active then return end
    AntiAFK.active = true
    AntiAFK.conn = RunService.Heartbeat:Connect(function()
        local vu = game:GetService("VirtualUser")
        pcall(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end)
end
function AntiAFK.Stop()
    AntiAFK.active = false
    if AntiAFK.conn then pcall(function() AntiAFK.conn:Disconnect() end) AntiAFK.conn = nil end
end
function AntiAFK.Toggle()
    if AntiAFK.active then AntiAFK.Stop() else AntiAFK.Start() end
    return AntiAFK.active
end

-- ═══════════════ EXTENSION-03: WORLD EXTENDED ═══════════════
local WorldExt = {
    oldState = {},
    barriersOff = false,
    fogOff = false,
    specular = 1.0,
    exposure = 0,
}

function WorldExt.DisableBarriers()
    WorldExt.barriersOff = true
    for _, inst in ipairs(WS:GetDescendants()) do
        if inst:IsA("BasePart") and inst.Name:lower():find("barrier") then
            pcall(function()
                inst.CanCollide = false
                inst.Transparency = 1
            end)
        end
    end
end
function WorldExt.RestoreBarriers()
    WorldExt.barriersOff = false
    for _, inst in ipairs(WS:GetDescendants()) do
        if inst:IsA("BasePart") and inst.Name:lower():find("barrier") then
            pcall(function()
                inst.CanCollide = true
                inst.Transparency = 0
            end)
        end
    end
end

function WorldExt.SetAmbient(color)
    if not WorldExt.oldState.ambient then
        WorldExt.oldState.ambient = Lighting.Ambient
    end
    Lighting.Ambient = color
end
function WorldExt.RestoreAmbient()
    if WorldExt.oldState.ambient then
        Lighting.Ambient = WorldExt.oldState.ambient
    end
end

function WorldExt.SetSpecular(v)
    pcall(function() Lighting.Specular = v end)
end
function WorldExt.SetExposure(v)
    pcall(function() Lighting.ExposureCompensation = v end)
end

function WorldExt.SetFogDensity(v)
    pcall(function() Lighting.FogEnd = v end)
end

function WorldExt.DisableShadows()
    for _, inst in ipairs(Lighting:GetDescendants()) do
        if inst:IsA("Sky") then
            pcall(function() inst.StarCount = 0 end)
        end
    end
    Lighting.GlobalShadows = false
end
function WorldExt.EnableShadows()
    Lighting.GlobalShadows = true
end

-- ═══════════════ EXTENSION-03: CAMERA EXTENDED ═══════════════
local CameraExt = {
    fovDefault = 70,
    fovCustom = 90,
    active = false,
}
function CameraExt.SetFOV(fov)
    CameraExt.active = true
    CameraExt.fovCustom = fov
    if Camera then
        pcall(function() Camera.FieldOfView = fov end)
    end
end
function CameraExt.ResetFOV()
    CameraExt.active = false
    if Camera then
        pcall(function() Camera.FieldOfView = CameraExt.fovDefault end)
    end
end
function CameraExt.FreeCamera(pos, lookAt)
    if not Camera then return end
    pcall(function()
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = CFrame.new(pos, lookAt or (pos + Vector3.new(0, 0, -10)))
    end)
end
function CameraExt.RestoreCamera()
    if not Camera then return end
    pcall(function()
        Camera.CameraType = Enum.CameraType.Custom
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then Camera.CameraSubject = hum end
    end)
end
function CameraExt.ZoomTo(player)
    local char = player.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    CameraExt.FreeCamera(head.Position + Vector3.new(0, 3, 8), head.Position)
end

-- ═══════════════ EXTENSION-03: FULLBRIGHT EXT ═══════════════
local FullbrightExt = {active = false, old = {}}
function FullbrightExt.On()
    if FullbrightExt.active then return end
    FullbrightExt.active = true
    local L = Lighting
    FullbrightExt.old = {
        ambient = L.Ambient,
        outdoor = L.OutdoorAmbient,
        brightness = L.Brightness,
        clockTime = L.ClockTime,
        exposure = L.ExposureCompensation,
        fogEnd = L.FogEnd,
        specular = L.Specular,
    }
    L.Ambient = Color3.new(1, 1, 1)
    L.OutdoorAmbient = Color3.new(1, 1, 1)
    L.Brightness = 3
    L.ClockTime = 12
    L.ExposureCompensation = 0.5
    L.FogEnd = 1e6
    L.Specular = 0
end
function FullbrightExt.Off()
    if not FullbrightExt.active then return end
    FullbrightExt.active = false
    local L = Lighting
    if FullbrightExt.old.ambient then L.Ambient = FullbrightExt.old.ambient end
    if FullbrightExt.old.outdoor then L.OutdoorAmbient = FullbrightExt.old.outdoor end
    if FullbrightExt.old.brightness then L.Brightness = FullbrightExt.old.brightness end
    if FullbrightExt.old.clockTime then L.ClockTime = FullbrightExt.old.clockTime end
    if FullbrightExt.old.exposure then L.ExposureCompensation = FullbrightExt.old.exposure end
    if FullbrightExt.old.fogEnd then L.FogEnd = FullbrightExt.old.fogEnd end
    if FullbrightExt.old.specular then L.Specular = FullbrightExt.old.specular end
end
function FullbrightExt.Toggle()
    if FullbrightExt.active then FullbrightExt.Off() else FullbrightExt.On() end
    return FullbrightExt.active
end

-- ═══════════════ EXTENSION-03: FPS UNLOCK + SHOW FPS ═══════════════
local FPSExt = {cap = 240, showFps = false, fpsLabel = nil, conn = nil, frames = 0, startTime = tick()}
function FPSExt.SetCap(cap)
    FPSExt.cap = cap
    pcall(function() setfpscap(cap) end)
end
function FPSExt.ShowFPS()
    if not FPSExt.fpsLabel then
        local lbl = Instance.new("TextLabel")
        lbl.Name = "MeowFPS"
        lbl.Size = UDim2.new(0, 100, 0, 22)
        lbl.Position = UDim2.new(0, 10, 0, 10)
        lbl.BackgroundColor3 = THEME.Surface
        lbl.BackgroundTransparency = 0.3
        lbl.TextColor3 = THEME.Accent
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.Text = "FPS: --"
        lbl.BorderSizePixel = 0
        lbl.ZIndex = 40
        lbl.Parent = ScreenGui
        corner(lbl, 6)
        FPSExt.fpsLabel = lbl
    end
    FPSExt.showFps = true
    FPSExt.conn = RunService.RenderStepped:Connect(function()
        FPSExt.frames = FPSExt.frames + 1
        local now = tick()
        if now - FPSExt.startTime >= 1 then
            if FPSExt.fpsLabel then
                FPSExt.fpsLabel.Text = string.format("FPS: %d", FPSExt.frames)
            end
            FPSExt.frames = 0
            FPSExt.startTime = now
        end
    end)
end
function FPSExt.HideFPS()
    FPSExt.showFps = false
    if FPSExt.conn then pcall(function() FPSExt.conn:Disconnect() end) FPSExt.conn = nil end
    if FPSExt.fpsLabel then FPSExt.fpsLabel:Destroy() FPSExt.fpsLabel = nil end
end

-- ═══════════════ EXTENSION-03: PING DISPLAY ═══════════════
local PingDisplay = {label = nil, conn = nil}
function PingDisplay.Show()
    if not PingDisplay.label then
        local lbl = Instance.new("TextLabel")
        lbl.Name = "MeowPing"
        lbl.Size = UDim2.new(0, 100, 0, 22)
        lbl.Position = UDim2.new(0, 10, 0, 36)
        lbl.BackgroundColor3 = THEME.Surface
        lbl.BackgroundTransparency = 0.3
        lbl.TextColor3 = THEME.Accent
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.Text = "Ping: --"
        lbl.BorderSizePixel = 0
        lbl.ZIndex = 40
        lbl.Parent = ScreenGui
        corner(lbl, 6)
        PingDisplay.label = lbl
    end
    PingDisplay.conn = RunService.Heartbeat:Connect(function()
        local ping = 0
        pcall(function()
            ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if PingDisplay.label then
            PingDisplay.label.Text = string.format("Ping: %dms", ping)
        end
    end)
end
function PingDisplay.Hide()
    if PingDisplay.conn then pcall(function() PingDisplay.conn:Disconnect() end) PingDisplay.conn = nil end
    if PingDisplay.label then PingDisplay.label:Destroy() PingDisplay.label = nil end
end

-- ═══════════════ EXTENSION-04: VEHICLE REGISTRY ═══════════════
local VehicleRegistry = {seats = {}, models = {}, conns = {}}
function VehicleRegistry.GetModel(seat)
    return seat:FindFirstAncestorOfClass("Model") or seat:FindFirstAncestorOfClass("Folder")
end
function VehicleRegistry.Anchor(model)
    if not model then return nil end
    if model.PrimaryPart then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end
function VehicleRegistry.Register(seat)
    if VehicleRegistry.seats[seat] then return end
    local model = VehicleRegistry.GetModel(seat)
    if model then
        VehicleRegistry.seats[seat] = model
        VehicleRegistry.models[model] = (VehicleRegistry.models[model] or 0) + 1
    end
end
function VehicleRegistry.Unregister(seat)
    local model = VehicleRegistry.seats[seat]
    VehicleRegistry.seats[seat] = nil
    if model and VehicleRegistry.models[model] then
        VehicleRegistry.models[model] = VehicleRegistry.models[model] - 1
        if VehicleRegistry.models[model] <= 0 then
            VehicleRegistry.models[model] = nil
        end
    end
end
function VehicleRegistry.Scan()
    for _, inst in ipairs(WS:GetDescendants()) do
        if inst:IsA("VehicleSeat") then VehicleRegistry.Register(inst) end
    end
end
function VehicleRegistry.Start()
    VehicleRegistry.Scan()
    table.insert(VehicleRegistry.conns, WS.DescendantAdded:Connect(function(inst)
        if inst:IsA("VehicleSeat") then VehicleRegistry.Register(inst) end
    end))
    table.insert(VehicleRegistry.conns, WS.DescendantRemoving:Connect(function(inst)
        if inst:IsA("VehicleSeat") then VehicleRegistry.Unregister(inst) end
    end))
end
function VehicleRegistry.Stop()
    for _, c in ipairs(VehicleRegistry.conns) do
        pcall(function() c:Disconnect() end)
    end
    VehicleRegistry.conns = {}
end
function VehicleRegistry.UniqueModels()
    local seen, list = {}, {}
    for _, model in pairs(VehicleRegistry.seats) do
        if model and model.Parent and not seen[model] then
            seen[model] = true
            table.insert(list, model)
        end
    end
    return list
end
VehicleRegistry.Start()

-- ═══════════════ EXTENSION-04: VEHICLE FINDER ═══════════════
local VehicleFinder = {}
function VehicleFinder.NearestToPlayer()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    local myPos = myHrp.Position
    local best, bestD = nil, math.huge
    for _, model in ipairs(VehicleRegistry.UniqueModels()) do
        local anchor = VehicleRegistry.Anchor(model)
        if anchor then
            local d = (myPos - anchor.Position).Magnitude
            if d < bestD then bestD = d best = model end
        end
    end
    return best, bestD
end
function VehicleFinder.ClosestToPos(pos)
    local best, bestD = nil, math.huge
    for _, model in ipairs(VehicleRegistry.UniqueModels()) do
        local anchor = VehicleRegistry.Anchor(model)
        if anchor then
            local d = (pos - anchor.Position).Magnitude
            if d < bestD then bestD = d best = model end
        end
    end
    return best, bestD
end
function VehicleFinder.ByName(name)
    local nameL = name:lower()
    for _, model in ipairs(VehicleRegistry.UniqueModels()) do
        if model.Name:lower():find(nameL, 1, true) then
            return model
        end
    end
    return nil
end
function VehicleFinder.All()
    return VehicleRegistry.UniqueModels()
end
function VehicleFinder.Count()
    return #VehicleRegistry.UniqueModels()
end
function VehicleFinder.FindEmpty()
    for _, model in ipairs(VehicleRegistry.UniqueModels()) do
        for _, inst in ipairs(model:GetDescendants()) do
            if inst:IsA("VehicleSeat") and not inst.Occupant then
                return model, inst
            end
        end
    end
    return nil
end

-- ═══════════════ EXTENSION-04: VEHICLE TRACKER ═══════════════
local VehicleTracker = {target = nil, active = false, conn = nil, oldCFrame = nil}
function VehicleTracker.Track(model)
    if not model then return end
    local anchor = VehicleRegistry.Anchor(model)
    if not anchor then return end
    VehicleTracker.target = model
    VehicleTracker.active = true
    VehicleTracker.oldCFrame = Camera.CFrame
    Camera.CameraType = Enum.CameraType.Scriptable

    if VehicleTracker.conn then
        pcall(function() VehicleTracker.conn:Disconnect() end)
    end

    VehicleTracker.conn = RunService.RenderStepped:Connect(function()
        if not VehicleTracker.active or not VehicleTracker.target then return end
        local a = VehicleRegistry.Anchor(VehicleTracker.target)
        if not a or not a.Parent then
            VehicleTracker.Stop()
            return
        end
        local targetCF = CFrame.new(a.Position + Vector3.new(0, 6, 10), a.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 0.15)
    end)
end
function VehicleTracker.Stop()
    VehicleTracker.active = false
    VehicleTracker.target = nil
    if VehicleTracker.conn then
        pcall(function() VehicleTracker.conn:Disconnect() end)
        VehicleTracker.conn = nil
    end
    pcall(function()
        Camera.CameraType = Enum.CameraType.Custom
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then Camera.CameraSubject = hum end
    end)
end

-- ═══════════════ EXTENSION-04: VEHICLE LOCK ═══════════════
local VehicleLock = {target = nil, active = false, conn = nil, offset = Vector3.new(0, 3, 5)}
function VehicleLock.Lock(model)
    if not model then return end
    local anchor = VehicleRegistry.Anchor(model)
    if not anchor then return end
    VehicleLock.target = model
    VehicleLock.active = true
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    VehicleLock.offset = myHrp.Position - anchor.Position

    if VehicleLock.conn then
        pcall(function() VehicleLock.conn:Disconnect() end)
    end

    VehicleLock.conn = RunService.Heartbeat:Connect(function()
        if not VehicleLock.active or not VehicleLock.target then return end
        local myH = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local a = VehicleRegistry.Anchor(VehicleLock.target)
        if not myH or not a or not a.Parent then
            VehicleLock.Stop()
            return
        end
        myH.CFrame = CFrame.new(a.Position + VehicleLock.offset)
        pcall(function()
            myH.AssemblyLinearVelocity = Vector3.zero
            myH.AssemblyAngularVelocity = Vector3.zero
        end)
    end)
end
function VehicleLock.Stop()
    VehicleLock.active = false
    VehicleLock.target = nil
    if VehicleLock.conn then
        pcall(function() VehicleLock.conn:Disconnect() end)
        VehicleLock.conn = nil
    end
end

-- ═══════════════ EXTENSION-04: SEAT STEALER ═══════════════
local SeatStealer = {}
function SeatStealer.Steal(seat)
    if not seat or not seat:IsA("VehicleSeat") then return false end
    local myChar = LP.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHum then return false end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return false end
    local ok = pcall(function()
        myHrp.CFrame = seat.CFrame + Vector3.new(0, 3, 0)
        seat:Sit(myHum)
    end)
    return ok
end
function SeatStealer.StealNearest()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    local myPos = myHrp.Position
    local best, bestD = nil, math.huge
    for seat, model in pairs(VehicleRegistry.seats) do
        if seat and seat.Parent then
            local d = (myPos - seat.Position).Magnitude
            if d < bestD then
                bestD = d
                best = seat
            end
        end
    end
    if best then
        SeatStealer.Steal(best)
        return best
    end
    return nil
end
function SeatStealer.ForceEject(seat)
    if not seat or not seat.Occupant then return false end
    pcall(function() seat.Occupant.Sit = false end)
    pcall(function()
        local hum = seat.Occupant
        if hum then hum.Jump = true end
    end)
    return true
end

-- ═══════════════ EXTENSION-04: VEHICLE BOOST ═══════════════
local VehicleBoost = {multiplier = 1, active = false, conn = nil}
function VehicleBoost.Start(mult)
    VehicleBoost.multiplier = mult or 1.5
    VehicleBoost.active = true
    if VehicleBoost.conn then
        pcall(function() VehicleBoost.conn:Disconnect() end)
    end
    VehicleBoost.conn = RunService.Heartbeat:Connect(function()
        if not VehicleBoost.active then return end
        local myChar = LP.Character
        local seat = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local vehicleSeat = seat and seat.SeatPart
        if vehicleSeat and vehicleSeat:IsA("VehicleSeat") then
            pcall(function()
                local baseSpeed = vehicleSeat.MaxSpeed or 50
                vehicleSeat.MaxSpeed = baseSpeed * VehicleBoost.multiplier
                local torque = vehicleSeat.Torque or 10
                vehicleSeat.Torque = torque * VehicleBoost.multiplier
            end)
        end
    end)
end
function VehicleBoost.Stop()
    VehicleBoost.active = false
    if VehicleBoost.conn then
        pcall(function() VehicleBoost.conn:Disconnect() end)
        VehicleBoost.conn = nil
    end
end

-- ═══════════════ EXTENSION-04: VEHICLE FLY ═══════════════
local VehicleFly = {active = false, conn = nil, speed = 100, vertical = 50}
function VehicleFly.Start()
    VehicleFly.active = true
    if VehicleFly.conn then
        pcall(function() VehicleFly.conn:Disconnect() end)
    end
    VehicleFly.conn = RunService.Heartbeat:Connect(function()
        if not VehicleFly.active then return end
        local myChar = LP.Character
        local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        if not seat then return end
        local vehicle = seat:FindFirstAncestorOfClass("Model") or seat:FindFirstAncestorOfClass("Folder")
        if not vehicle then return end
        local prim = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart", true)
        if not prim then return end
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then
            local newPos = prim.Position + dir.Unit * VehicleFly.speed * 0.1
            pcall(function()
                if vehicle.PrimaryPart then
                    vehicle:SetPrimaryPartCFrame(CFrame.new(newPos))
                else
                    vehicle:TranslateBy(dir.Unit * VehicleFly.speed * 0.1)
                end
            end)
        end
    end)
end
function VehicleFly.Stop()
    VehicleFly.active = false
    if VehicleFly.conn then
        pcall(function() VehicleFly.conn:Disconnect() end)
        VehicleFly.conn = nil
    end
end

-- ═══════════════ EXTENSION-04: VEHICLE LIST UI ═══════════════
local VehicleListUI = {list = {}, refreshConn = nil}
function VehicleListUI.Refresh(parent)
    for _, v in ipairs(parent:GetChildren()) do
        if v:IsA("TextButton") and v:GetAttribute("isVehBtn") then v:Destroy() end
    end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local myPos = myHrp.Position
    local models = VehicleRegistry.UniqueModels()
    table.sort(models, function(a, b)
        local aa = VehicleRegistry.Anchor(a)
        local bb = VehicleRegistry.Anchor(b)
        if not aa or not bb then return false end
        return (myPos - aa.Position).Magnitude < (myPos - bb.Position).Magnitude
    end)
    for _, model in ipairs(models) do
        local anchor = VehicleRegistry.Anchor(model)
        if anchor then
            local d = math.floor((myPos - anchor.Position).Magnitude)
            local btn = Instance.new("TextButton")
            btn:SetAttribute("isVehBtn", true)
            btn.Size = UDim2.new(1, 0, 0, 44)
            btn.BackgroundColor3 = THEME.Surface
            btn.Text = "  " .. model.Name .. "   " .. d .. "m"
            btn.TextColor3 = THEME.Text
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 12
            btn.BorderSizePixel = 0
            btn.Parent = parent
            corner(btn, 8)
            btn.MouseButton1Click:Connect(function()
                local a = VehicleRegistry.Anchor(model)
                if a then SafeTeleport(a.Position + Vector3.new(0, 6, 0), "vehicle") end
            end)
        end
    end
end
function VehicleListUI.StartAutoRefresh(parent, interval)
    interval = interval or 3
    if VehicleListUI.refreshConn then
        pcall(function() task.cancel(VehicleListUI.refreshConn) end)
    end
    VehicleListUI.refreshConn = task.spawn(function()
        while parent and parent.Parent do
            VehicleListUI.Refresh(parent)
            task.wait(interval)
        end
    end)
end

-- ═══════════════ EXTENSION-05: PLAYER PROFILE ═══════════════
local PlayerProfile = {}
function PlayerProfile.Summary(player)
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not (hrp and hum and head) then return nil end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position or Vector3.zero
    return {
        name = player.Name,
        displayName = player.DisplayName,
        userId = player.UserId,
        accountAge = player.AccountAge,
        team = player.Team and player.Team.Name or "none",
        health = hum.Health,
        maxHealth = hum.MaxHealth,
        distance = math.floor((myPos - hrp.Position).Magnitude),
        position = hrp.Position,
        walkSpeed = hum.WalkSpeed,
        jumpPower = hum.JumpPower,
        sitting = hum.Sit,
        inVehicle = hum.SeatPart ~= nil,
    }
end
function PlayerProfile.Format(profile)
    if not profile then return "no data" end
    return string.format(
        "%s | uid=%d | age=%dd | team=%s | hp=%d/%d | dist=%dm | spd=%.0f | %s",
        profile.displayName,
        profile.userId,
        profile.accountAge,
        profile.team,
        math.floor(profile.health),
        math.floor(profile.maxHealth),
        profile.distance,
        profile.walkSpeed,
        profile.inVehicle and "IN VEH" or (profile.sitting and "SITTING" or "ground")
    )
end

-- ═══════════════ EXTENSION-05: PLAYER VIEW ═══════════════
local PlayerView = {}
function PlayerView.Watch(player, distance)
    local char = player.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return false end
    distance = distance or 8
    local cam = WS.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.new(head.Position + Vector3.new(0, 3, distance), head.Position)
    return true
end
function PlayerView.Follow(player)
    if PlayerView.conn then
        pcall(function() PlayerView.conn:Disconnect() end)
    end
    PlayerView.target = player
    PlayerView.conn = RunService.RenderStepped:Connect(function()
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        if not head then
            PlayerView.Stop()
            return
        end
        local cam = WS.CurrentCamera
        if cam.CameraType ~= Enum.CameraType.Scriptable then
            cam.CameraType = Enum.CameraType.Scriptable
        end
        local targetCF = CFrame.new(head.Position + Vector3.new(0, 3, 8), head.Position)
        cam.CFrame = cam.CFrame:Lerp(targetCF, 0.15)
    end)
    return true
end
function PlayerView.Stop()
    if PlayerView.conn then
        pcall(function() PlayerView.conn:Disconnect() end)
        PlayerView.conn = nil
    end
    PlayerView.target = nil
    pcall(function()
        local cam = WS.CurrentCamera
        cam.CameraType = Enum.CameraType.Custom
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then cam.CameraSubject = hum end
    end)
end

-- ═══════════════ EXTENSION-05: PLAYER HIDE ═══════════════
local PlayerHide = {hidden = {}}
function PlayerHide.Hide(player)
    local char = player.Character
    if not char then return end
    PlayerHide.hidden[player] = {}
    for _, inst in ipairs(char:GetDescendants()) do
        if inst:IsA("BasePart") then
            PlayerHide.hidden[player][inst] = inst.LocalTransparencyModifier
            inst.LocalTransparencyModifier = 1
        elseif inst:IsA("Decal") or inst:IsA("Texture") then
            PlayerHide.hidden[player][inst] = inst.Transparency
            inst.Transparency = 1
        end
    end
end
function PlayerHide.Show(player)
    if not PlayerHide.hidden[player] then return end
    local char = player.Character
    if char then
        for inst, val in pairs(PlayerHide.hidden[player]) do
            pcall(function()
                if inst.Parent then
                    if inst:IsA("BasePart") then
                        inst.LocalTransparencyModifier = val
                    elseif inst:IsA("Decal") or inst:IsA("Texture") then
                        inst.Transparency = val
                    end
                end
            end)
        end
    end
    PlayerHide.hidden[player] = nil
end
function PlayerHide.Toggle(player)
    if PlayerHide.hidden[player] then
        PlayerHide.Show(player)
        return false
    else
        PlayerHide.Hide(player)
        return true
    end
end

-- ═══════════════ EXTENSION-05: FORCE SIT ═══════════════
local ForceSit = {}
function ForceSit.ForceSit(player)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.Sit = true end)
        return true
    end
    return false
end
function ForceSit.Unsit(player)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.Sit = false end)
        return true
    end
    return false
end
function ForceSit.Freeze(player)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if ForceSit._frozen[player] then return false end
    ForceSit._frozen[player] = {cframe = hrp.CFrame, conn = RunService.Heartbeat:Connect(function()
        if hrp.Parent then
            hrp.CFrame = ForceSit._frozen[player].cframe
        end
    end)}
    return true
end
function ForceSit.Unfreeze(player)
    local data = ForceSit._frozen[player]
    if not data then return false end
    pcall(function() data.conn:Disconnect() end)
    ForceSit._frozen[player] = nil
    return true
end
ForceSit._frozen = {}

-- ═══════════════ EXTENSION-05: CAGE ═══════════════
local PlayerCage = {cages = {}}
function PlayerCage.Create(player)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    PlayerCage.Remove(player)
    local cage = Instance.new("Model")
    cage.Name = "MeowCage_" .. player.Name
    for _, data in ipairs({
        {size = Vector3.new(8, 0.5, 8), pos = Vector3.new(0, -2.75, 0)},
        {size = Vector3.new(8, 0.5, 8), pos = Vector3.new(0, 2.75, 0)},
        {size = Vector3.new(0.5, 6, 8), pos = Vector3.new(-3.75, 0, 0)},
        {size = Vector3.new(0.5, 6, 8), pos = Vector3.new(3.75, 0, 0)},
        {size = Vector3.new(8, 6, 0.5), pos = Vector3.new(0, 0, -3.75)},
        {size = Vector3.new(8, 6, 0.5), pos = Vector3.new(0, 0, 3.75)},
    }) do
        local part = Instance.new("Part")
        part.Size = data.size
        part.Position = hrp.Position + data.pos
        part.Anchored = true
        part.CanCollide = true
        part.Material = Enum.Material.Neon
        part.Color = THEME.Accent
        part.Transparency = 0.5
        part.Parent = cage
    end
    cage.Parent = WS
    PlayerCage.cages[player] = cage
    return true
end
function PlayerCage.Remove(player)
    if PlayerCage.cages[player] then
        pcall(function() PlayerCage.cages[player]:Destroy() end)
        PlayerCage.cages[player] = nil
    end
end
function PlayerCage.RemoveAll()
    for player, cage in pairs(PlayerCage.cages) do
        pcall(function() cage:Destroy() end)
        PlayerCage.cages[player] = nil
    end
end

-- ═══════════════ EXTENSION-05: ORBIT ═══════════════
local PlayerOrbit = {active = false, target = nil, conn = nil, radius = 10, speed = 1.5, height = 3}
function PlayerOrbit.Start(player)
    if PlayerOrbit.conn then
        pcall(function() PlayerOrbit.conn:Disconnect() end)
    end
    PlayerOrbit.target = player
    PlayerOrbit.active = true
    local angle = 0
    PlayerOrbit.conn = RunService.Heartbeat:Connect(function()
        if not PlayerOrbit.active then return end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not (hrp and myHrp) then
            PlayerOrbit.Stop()
            return
        end
        angle = angle + PlayerOrbit.speed * 0.1
        local offset = Vector3.new(
            math.cos(angle) * PlayerOrbit.radius,
            PlayerOrbit.height,
            math.sin(angle) * PlayerOrbit.radius
        )
        myHrp.CFrame = CFrame.new(hrp.Position + offset, hrp.Position)
        pcall(function()
            myHrp.AssemblyLinearVelocity = Vector3.zero
            myHrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end)
end
function PlayerOrbit.Stop()
    PlayerOrbit.active = false
    PlayerOrbit.target = nil
    if PlayerOrbit.conn then
        pcall(function() PlayerOrbit.conn:Disconnect() end)
        PlayerOrbit.conn = nil
    end
end

-- ═══════════════ EXTENSION-05: SPECTATE EXT ═══════════════
local SpectateExt = {history = {}, currentIdx = 0, target = nil, conn = nil}
function SpectateExt.AddHistory(player)
    for i, p in ipairs(SpectateExt.history) do
        if p == player then
            table.remove(SpectateExt.history, i)
            break
        end
    end
    table.insert(SpectateExt.history, player)
    SpectateExt.currentIdx = #SpectateExt.history
end
function SpectateExt.Next()
    if #SpectateExt.history == 0 then return nil end
    SpectateExt.currentIdx = SpectateExt.currentIdx + 1
    if SpectateExt.currentIdx > #SpectateExt.history then
        SpectateExt.currentIdx = 1
    end
    local p = SpectateExt.history[SpectateExt.currentIdx]
    if p then PlayerView.Follow(p) end
    return p
end
function SpectateExt.Prev()
    if #SpectateExt.history == 0 then return nil end
    SpectateExt.currentIdx = SpectateExt.currentIdx - 1
    if SpectateExt.currentIdx < 1 then
        SpectateExt.currentIdx = #SpectateExt.history
    end
    local p = SpectateExt.history[SpectateExt.currentIdx]
    if p then PlayerView.Follow(p) end
    return p
end

-- ═══════════════ EXTENSION-05: FOLLOW SELECTED ═══════════════
local PlayerFollow = {target = nil, distance = 15, active = false, conn = nil}
function PlayerFollow.Start(player)
    PlayerFollow.target = player
    PlayerFollow.active = true
    if PlayerFollow.conn then
        pcall(function() PlayerFollow.conn:Disconnect() end)
    end
    PlayerFollow.conn = RunService.Heartbeat:Connect(function()
        if not PlayerFollow.active then return end
        local char = player.Character
        local targetHrp = char and char:FindFirstChild("HumanoidRootPart")
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not (targetHrp and myHrp) then
            PlayerFollow.Stop()
            return
        end
        local offset = (myHrp.Position - targetHrp.Position)
        if offset.Magnitude > PlayerFollow.distance then
            local newPos = targetHrp.Position + offset.Unit * PlayerFollow.distance
            myHrp.CFrame = CFrame.new(newPos)
        end
    end)
end
function PlayerFollow.Stop()
    PlayerFollow.active = false
    PlayerFollow.target = nil
    if PlayerFollow.conn then
        pcall(function() PlayerFollow.conn:Disconnect() end)
        PlayerFollow.conn = nil
    end
end

-- ═══════════════ EXTENSION-06: BYPASS EXTENDED ═══════════════
local BypassExt = {
    active = true,
    jitterScale = 0.1,
    randomDelay = true,
    antiKick = false,
}
function BypassExt.JitterVector(v)
    if not BypassExt.active then return v end
    local s = BypassExt.jitterScale
    return v + Vector3.new(
        (math.random() - 0.5) * s,
        (math.random() - 0.5) * s,
        (math.random() - 0.5) * s
    )
end
function BypassExt.JitterCFrame(cf)
    if not BypassExt.active then return cf end
    local s = BypassExt.jitterScale * 0.01
    return cf * CFrame.Angles(
        (math.random() - 0.5) * s,
        (math.random() - 0.5) * s,
        (math.random() - 0.5) * s
    )
end
function BypassExt.RandomDelay()
    if not BypassExt.randomDelay then return end
    task.wait(math.random() * 0.01 + 0.001)
end
function BypassExt.SetJitter(v) BypassExt.jitterScale = v end
function BypassExt.Toggle() BypassExt.active = not BypassExt.active return BypassExt.active end

-- ═══════════════ EXTENSION-06: VIRTUAL POSITION ═══════════════
local VirtualPos = {active = false, offset = Vector3.zero, conn = nil}
function VirtualPos.Start(offset)
    if not LP.Character then return end
    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    VirtualPos.offset = offset or Vector3.zero
    VirtualPos.baseCFrame = hrp.CFrame
    VirtualPos.active = true
    if VirtualPos.conn then
        pcall(function() VirtualPos.conn:Disconnect() end)
    end
    VirtualPos.conn = RunService.Heartbeat:Connect(function()
        if not VirtualPos.active then return end
        local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not h then return end
        h.CFrame = VirtualPos.baseCFrame + VirtualPos.offset
    end)
end
function VirtualPos.Stop()
    VirtualPos.active = false
    if VirtualPos.conn then
        pcall(function() VirtualPos.conn:Disconnect() end)
        VirtualPos.conn = nil
    end
end
function VirtualPos.SetOffset(offset)
    VirtualPos.offset = offset
end

-- ═══════════════ EXTENSION-06: TELEPORT EXTENDED ═══════════════
local TPExt = {history = {}, maxHistory = 20}
function TPExt.Record()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    table.insert(TPExt.history, hrp.CFrame)
    if #TPExt.history > TPExt.maxHistory then
        table.remove(TPExt.history, 1)
    end
end
function TPExt.Back()
    if #TPExt.history == 0 then return false end
    local prev = table.remove(TPExt.history)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp and prev then
        hrp.CFrame = prev
        return true
    end
    return false
end
function TPExt.Forward(distance)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dir = Camera.CFrame.LookVector
    TPExt.Record()
    hrp.CFrame = CFrame.new(hrp.Position + dir * (distance or 50))
end
function TPExt.Up(distance)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    TPExt.Record()
    hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, distance or 50, 0))
end
function TPExt.Behind(player)
    local targetHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return false end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return false end
    TPExt.Record()
    local offset = -targetHrp.CFrame.LookVector * 5 + Vector3.new(0, 3, 0)
    myHrp.CFrame = targetHrp.CFrame + offset
    return true
end
function TPExt.InFront(player)
    local targetHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return false end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return false end
    TPExt.Record()
    local offset = targetHrp.CFrame.LookVector * 5 + Vector3.new(0, 3, 0)
    myHrp.CFrame = targetHrp.CFrame + offset
    return true
end
function TPExt.ToCoords(x, y, z)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    TPExt.Record()
    hrp.CFrame = CFrame.new(x, y, z)
    return true
end
function TPExt.GetCurrentCoords()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local p = hrp.Position
    return {x = math.floor(p.X), y = math.floor(p.Y), z = math.floor(p.Z)}
end

-- ═══════════════ EXTENSION-06: ANTI-DETECT ═══════════════
local AntiDetect = {
    active = false,
    checkInterval = 1,
    lastCheck = 0,
    suspiciousFlags = 0,
}
function AntiDetect.Monitor()
    if not AntiDetect.active then return end
    local now = tick()
    if now - AntiDetect.lastCheck < AntiDetect.checkInterval then return end
    AntiDetect.lastCheck = now
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    -- check for teleport moves that exceeded expected
    if AntiDetect.lastPos then
        local delta = (hrp.Position - AntiDetect.lastPos).Magnitude
        if delta > 500 then
            AntiDetect.suspiciousFlags = AntiDetect.suspiciousFlags + 1
            Logger.Write("ANTIDET", "flag: teleport delta " .. math.floor(delta))
        end
    end
    AntiDetect.lastPos = hrp.Position
end
function AntiDetect.Start()
    AntiDetect.active = true
    AntiDetect.suspiciousFlags = 0
    AntiDetect.lastCheck = tick()
    Logger.Write("ANTIDET", "monitor on")
end
function AntiDetect.Stop()
    AntiDetect.active = false
    Logger.Write("ANTIDET", "monitor off")
end
function AntiDetect.Report()
    return {
        active = AntiDetect.active,
        flags = AntiDetect.suspiciousFlags,
        uptime = AntiDetect.active and (tick() - AntiDetect.lastCheck) or 0,
    }
end

-- ═══════════════ EXTENSION-06: REMOTE SPY ═══════════════
local RemoteSpy = {
    active = false,
    calls = {},
    maxCalls = 100,
    filter = nil,
    hookConn = nil,
}
function RemoteSpy.Hook()
    local oldNamecall
    pcall(function()
        local mt = getrawmetatable(game)
        oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if RemoteSpy.active and (method == "FireServer" or method == "InvokeServer") then
                local args = {...}
                local selfName = tostring(self)
                if not RemoteSpy.filter or selfName:find(RemoteSpy.filter, 1, true) then
                    table.insert(RemoteSpy.calls, {
                        time = tick(),
                        method = method,
                        remote = selfName,
                        args = args,
                    })
                    if #RemoteSpy.calls > RemoteSpy.maxCalls then
                        table.remove(RemoteSpy.calls, 1)
                    end
                    Logger.Write("SPY", method .. " " .. selfName)
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
    return oldNamecall
end
function RemoteSpy.Start()
    if RemoteSpy.active then return end
    RemoteSpy.active = true
    if not RemoteSpy._hooked then
        RemoteSpy.Hook()
        RemoteSpy._hooked = true
    end
    Logger.Write("SPY", "started")
end
function RemoteSpy.Stop()
    RemoteSpy.active = false
    Logger.Write("SPY", "stopped")
end
function RemoteSpy.SetFilter(str)
    RemoteSpy.filter = (str and str ~= "") and str or nil
end
function RemoteSpy.Dump()
    for _, call in ipairs(RemoteSpy.calls) do
        local argsStr = ""
        for i, a in ipairs(call.args) do
            if i > 1 then argsStr = argsStr .. ", " end
            argsStr = argsStr .. tostring(a)
        end
        Logger.Write("SPY", string.format("[%s] %s(%s)", call.method, call.remote, argsStr))
    end
end
function RemoteSpy.Clear()
    RemoteSpy.calls = {}
end

-- ═══════════════ EXTENSION-06: PACKET SENDER ═══════════════
local PacketSender = {}
function PacketSender.Send(remote, method, ...)
    if not remote then return false end
    local ok = pcall(function()
        if method == "FireServer" then
            remote:FireServer(...)
        elseif method == "InvokeServer" then
            remote:InvokeServer(...)
        end
    end)
    return ok
end
function PacketSender.FindRemote(path)
    local parts = {}
    for seg in path:gmatch("[^%.]+") do table.insert(parts, seg) end
    local current = game
    for _, seg in ipairs(parts) do
        if current then
            current = current:FindFirstChild(seg)
        end
    end
    return current
end

-- ═══════════════ EXTENSION-06: STABILITY / CRASH GUARD ═══════════════
local CrashGuard = {
    active = true,
    lastError = nil,
    errorCount = 0,
}
function CrashGuard.Wrap(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            CrashGuard.errorCount = CrashGuard.errorCount + 1
            CrashGuard.lastError = tostring(err)
            Logger.Write("CRASH", "error #" .. CrashGuard.errorCount .. ": " .. tostring(err))
        end
        return ok
    end
end
function CrashGuard.Report()
    return {
        active = CrashGuard.active,
        errors = CrashGuard.errorCount,
        last = CrashGuard.lastError or "none",
    }
end
function CrashGuard.Reset()
    CrashGuard.errorCount = 0
    CrashGuard.lastError = nil
end

-- ═══════════════ EXTENSION-06: QUEUE MANAGER ═══════════════
local QueueManager = {
    queue = {},
    running = false,
    interval = 0.1,
    taskRef = nil,
}
function QueueManager.Enqueue(fn)
    table.insert(QueueManager.queue, fn)
end
function QueueManager.Start()
    if QueueManager.running then return end
    QueueManager.running = true
    QueueManager.taskRef = task.spawn(function()
        while QueueManager.running do
            if #QueueManager.queue > 0 then
                local fn = table.remove(QueueManager.queue, 1)
                pcall(fn)
            else
                task.wait(QueueManager.interval)
            end
        end
    end)
end
function QueueManager.Stop()
    QueueManager.running = false
    if QueueManager.taskRef then
        pcall(function() task.cancel(QueueManager.taskRef) end)
        QueueManager.taskRef = nil
    end
end

-- ═══════════════ EXTENSION-06: SELF SNAPSHOT ═══════════════
local SelfSnapshot = {}
function SelfSnapshot.Capture()
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return nil end
    return {
        cframe = hrp.CFrame,
        velocity = hrp.AssemblyLinearVelocity,
        health = hum.Health,
        walkSpeed = hum.WalkSpeed,
        jumpPower = hum.JumpPower,
        gravity = WS.Gravity,
    }
end
function SelfSnapshot.Restore(snap)
    if not snap then return false end
    local char = LP.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum) then return false end
    pcall(function()
        hrp.CFrame = snap.cframe
        hrp.AssemblyLinearVelocity = snap.velocity
        hum.Health = snap.health
        hum.WalkSpeed = snap.walkSpeed
        hum.JumpPower = snap.jumpPower
    end)
    return true
end

-- ═══════════════ EXTENSION-07: LIGHTING EXTENDED ═══════════════
local LightingExt = {
    old = nil,
    bloom = nil,
    colorCorr = nil,
    blur = nil,
    sunRays = nil,
    atmosphere = nil,
}
function LightingExt.Snapshot()
    local L = Lighting
    LightingExt.old = {
        ambient = L.Ambient,
        outdoor = L.OutdoorAmbient,
        brightness = L.Brightness,
        clockTime = L.ClockTime,
        fogEnd = L.FogEnd,
        fogStart = L.FogStart,
        specular = L.Specular,
        exposure = L.ExposureCompensation,
        globalShadows = L.GlobalShadows,
        technology = L.Technology,
    }
end
function LightingExt.Restore()
    if not LightingExt.old then return end
    local L = Lighting
    local o = LightingExt.old
    pcall(function()
        if o.ambient then L.Ambient = o.ambient end
        if o.outdoor then L.OutdoorAmbient = o.outdoor end
        if o.brightness then L.Brightness = o.brightness end
        if o.clockTime then L.ClockTime = o.clockTime end
        if o.fogEnd then L.FogEnd = o.fogEnd end
        if o.fogStart then L.FogStart = o.fogStart end
        if o.specular then L.Specular = o.specular end
        if o.exposure then L.ExposureCompensation = o.exposure end
        if o.globalShadows ~= nil then L.GlobalShadows = o.globalShadows end
    end)
end

function LightingExt.SetBloom(intensity, size)
    if not LightingExt.bloom then
        LightingExt.bloom = Instance.new("BloomEffect")
        LightingExt.bloom.Name = "MeowBloom"
        LightingExt.bloom.Parent = Lighting
    end
    LightingExt.bloom.Enabled = true
    LightingExt.bloom.Intensity = intensity or 1
    LightingExt.bloom.Size = size or 24
    LightingExt.bloom.Threshold = 0.9
end
function LightingExt.ClearBloom()
    if LightingExt.bloom then
        pcall(function() LightingExt.bloom:Destroy() end)
        LightingExt.bloom = nil
    end
end

function LightingExt.SetColorCorrection(brightness, contrast, saturation, tint)
    if not LightingExt.colorCorr then
        LightingExt.colorCorr = Instance.new("ColorCorrectionEffect")
        LightingExt.colorCorr.Name = "MeowCC"
        LightingExt.colorCorr.Parent = Lighting
    end
    LightingExt.colorCorr.Enabled = true
    LightingExt.colorCorr.Brightness = brightness or 0
    LightingExt.colorCorr.Contrast = contrast or 0
    LightingExt.colorCorr.Saturation = saturation or 0
    if tint then LightingExt.colorCorr.TintColor = tint end
end
function LightingExt.ClearColorCorrection()
    if LightingExt.colorCorr then
        pcall(function() LightingExt.colorCorr:Destroy() end)
        LightingExt.colorCorr = nil
    end
end

function LightingExt.SetBlur(size)
    if not LightingExt.blur then
        LightingExt.blur = Instance.new("BlurEffect")
        LightingExt.blur.Name = "MeowBlur"
        LightingExt.blur.Parent = Lighting
    end
    LightingExt.blur.Enabled = true
    LightingExt.blur.Size = size or 8
end
function LightingExt.ClearBlur()
    if LightingExt.blur then
        pcall(function() LightingExt.blur:Destroy() end)
        LightingExt.blur = nil
    end
end

function LightingExt.SetSunRays(intensity, spread)
    if not LightingExt.sunRays then
        LightingExt.sunRays = Instance.new("SunRaysEffect")
        LightingExt.sunRays.Name = "MeowSunRays"
        LightingExt.sunRays.Parent = Lighting
    end
    LightingExt.sunRays.Enabled = true
    LightingExt.sunRays.Intensity = intensity or 0.1
    LightingExt.sunRays.Spread = spread or 1
end
function LightingExt.ClearSunRays()
    if LightingExt.sunRays then
        pcall(function() LightingExt.sunRays:Destroy() end)
        LightingExt.sunRays = nil
    end
end

function LightingExt.SetAtmosphere(density, offset, color, decay)
    if not LightingExt.atmosphere then
        LightingExt.atmosphere = Instance.new("Atmosphere")
        LightingExt.atmosphere.Name = "MeowAtmo"
        LightingExt.atmosphere.Parent = Lighting
    end
    LightingExt.atmosphere.Density = density or 0.3
    LightingExt.atmosphere.Offset = offset or 0.25
    LightingExt.atmosphere.Color = color or Color3.fromRGB(199, 199, 199)
    LightingExt.atmosphere.Decay = decay or Color3.fromRGB(106, 112, 125)
end
function LightingExt.ClearAtmosphere()
    if LightingExt.atmosphere then
        pcall(function() LightingExt.atmosphere:Destroy() end)
        LightingExt.atmosphere = nil
    end
end

function LightingExt.ClearAll()
    LightingExt.ClearBloom()
    LightingExt.ClearColorCorrection()
    LightingExt.ClearBlur()
    LightingExt.ClearSunRays()
    LightingExt.ClearAtmosphere()
end

-- ═══════════════ EXTENSION-07: SKY CONTROL ═══════════════
local SkyControl = {
    oldSky = nil,
    customSky = nil,
}
function SkyControl.SetSky(skyId)
    -- skyId = rbxassetid
    local L = Lighting
    if not SkyControl.oldSky then
        SkyControl.oldSky = L:FindFirstChildOfClass("Sky")
    end
    if SkyControl.customSky then
        pcall(function() SkyControl.customSky:Destroy() end)
    end
    local sky = Instance.new("Sky")
    sky.Name = "MeowSky"
    sky.SkyboxBk = skyId or "rbxassetid://159454299"
    sky.SkyboxDn = skyId or "rbxassetid://159454296"
    sky.SkyboxFt = skyId or "rbxassetid://159454293"
    sky.SkyboxLf = skyId or "rbxassetid://159454286"
    sky.SkyboxRt = skyId or "rbxassetid://159454300"
    sky.SkyboxUp = skyId or "rbxassetid://159454288"
    sky.Parent = L
    SkyControl.customSky = sky
end
function SkyControl.SetPreset(name)
    local presets = {
        night = "rbxassetid://1148468422",
        sunset = "rbxassetid://1148468405",
        space = "rbxassetid://592929521",
        pink = "rbxassetid://1148468409",
    }
    SkyControl.SetSky(presets[name])
end
function SkyControl.Restore()
    if SkyControl.customSky then
        pcall(function() SkyControl.customSky:Destroy() end)
        SkyControl.customSky = nil
    end
    if SkyControl.oldSky and not SkyControl.oldSky.Parent then
        pcall(function() SkyControl.oldSky.Parent = Lighting end)
    end
end

-- ═══════════════ EXTENSION-07: SCREEN FX ═══════════════
local ScreenFX = {
    active = false,
    effects = {},
}
function ScreenFX.AddColorTint(color, transparency)
    local frame = Instance.new("Frame")
    frame.Name = "MeowTint"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = color or Color3.fromRGB(255, 0, 100)
    frame.BackgroundTransparency = transparency or 0.7
    frame.BorderSizePixel = 0
    frame.ZIndex = 30
    frame.Parent = ScreenGui
    table.insert(ScreenFX.effects, frame)
    ScreenFX.active = true
    return frame
end
function ScreenFX.RemoveColorTint()
    for i = #ScreenFX.effects, 1, -1 do
        local e = ScreenFX.effects[i]
        if e.Name == "MeowTint" then
            pcall(function() e:Destroy() end)
            table.remove(ScreenFX.effects, i)
        end
    end
end
function ScreenFX.AddScanlines()
    local frame = Instance.new("Frame")
    frame.Name = "MeowScanlines"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ZIndex = 30
    frame.Parent = ScreenGui
    for i = 0, 100 do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, i / 100, 0)
        line.BackgroundColor3 = Color3.new(0, 0, 0)
        line.BackgroundTransparency = 0.9
        line.BorderSizePixel = 0
        line.ZIndex = 31
        line.Parent = frame
    end
    table.insert(ScreenFX.effects, frame)
    return frame
end
function ScreenFX.RemoveScanlines()
    for i = #ScreenFX.effects, 1, -1 do
        local e = ScreenFX.effects[i]
        if e.Name == "MeowScanlines" then
            pcall(function() e:Destroy() end)
            table.remove(ScreenFX.effects, i)
        end
    end
end
function ScreenFX.Clear()
    for _, e in ipairs(ScreenFX.effects) do
        pcall(function() e:Destroy() end)
    end
    ScreenFX.effects = {}
    ScreenFX.active = false
end

-- ═══════════════ EXTENSION-07: CUSTOM ESP STYLES ═══════════════
local ESPStyles = {
    current = "default",
    styles = {
        default = {box = true, name = true, dist = true},
        minimal = {box = false, name = true, dist = false},
        full = {box = true, name = true, dist = true, hp = true, skel = true},
        skeleton = {box = false, name = true, dist = true, skel = true},
    },
}
function ESPStyles.Apply(styleName)
    local style = ESPStyles.styles[styleName]
    if not style then return false end
    ESPStyles.current = styleName
    Config.ESP_Box = style.box or false
    Config.ESP_Name = style.name or false
    Config.ESP_Dist = style.dist or false
    Config.ESP_HP = style.hp or false
    Config.ESP_Skeleton = style.skel or false
    return true
end
function ESPStyles.List()
    local out = {}
    for name in pairs(ESPStyles.styles) do table.insert(out, name) end
    table.sort(out)
    return out
end

-- ═══════════════ EXTENSION-07: AMBIENT PARTICLES ═══════════════
local Particles = {
    emitters = {},
}
function Particles.CreateSnow(radius)
    radius = radius or 200
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "MeowSnow"
    emitter.Texture = "rbxassetid://1030759618"
    emitter.Rate = 50
    emitter.Lifetime = NumberRange.new(3, 6)
    emitter.Speed = NumberRange.new(1, 3)
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-45, 45)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0.1),
    })
    emitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
    emitter.EmissionDirection = Enum.NormalId.Top
    emitter.SpreadAngle = Vector2.new(15, 15)
    emitter.Parent = hrp

    local anchor = Instance.new("Attachment")
    anchor.Name = "MeowSnowAnchor"
    anchor.WorldPosition = hrp.Position + Vector3.new(0, 20, 0)
    anchor.Parent = WS.Terrain

    table.insert(Particles.emitters, emitter)
    return emitter
end
function Particles.ClearAll()
    for _, e in ipairs(Particles.emitters) do
        pcall(function() e:Destroy() end)
    end
    Particles.emitters = {}
end

-- ═══════════════ EXTENSION-07: TIMESCALE ═══════════════
local TimeScale = {
    current = 1,
    active = false,
}
function TimeScale.Set(scale)
    TimeScale.current = math.clamp(scale, 0.1, 5)
    pcall(function()
        local success = pcall(function()
            game:GetService("RunService").Heartbeat:Wait()
        end)
    end)
end
function TimeScale.Slowmo()
    TimeScale.Set(0.3)
    TimeScale.active = true
end
function TimeScale.Fastmo()
    TimeScale.Set(2.0)
    TimeScale.active = true
end
function TimeScale.Reset()
    TimeScale.Set(1)
    TimeScale.active = false
end

-- ═══════════════ EXTENSION-07: ZOOM CONTROLLER ═══════════════
local ZoomController = {
    baseFOV = 70,
    active = false,
}
function ZoomController.ZoomIn(amount)
    if not Camera then return end
    ZoomController.baseFOV = Camera.FieldOfView
    Camera.FieldOfView = math.max(10, Camera.FieldOfView - (amount or 30))
    ZoomController.active = true
end
function ZoomController.ZoomOut(amount)
    if not Camera then return end
    Camera.FieldOfView = math.min(120, Camera.FieldOfView + (amount or 30))
    ZoomController.active = true
end
function ZoomController.Reset()
    if not Camera then return end
    Camera.FieldOfView = ZoomController.baseFOV or 70
    ZoomController.active = false
end

-- ═══════════════ EXTENSION-08: KEYBIND MANAGER ═══════════════
local KeybindManager = {
    binds = {},
}
function KeybindManager.Register(name, key, cb, description)
    KeybindManager.binds[name] = {key = key, cb = cb, description = description or ""}
end
function KeybindManager.Unregister(name)
    KeybindManager.binds[name] = nil
end
function KeybindManager.Fire(key)
    for _, bind in pairs(KeybindManager.binds) do
        if bind.key == key then
            pcall(bind.cb)
        end
    end
end
function KeybindManager.StartListener()
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        KeybindManager.Fire(input.KeyCode.Name)
    end)
end
function KeybindManager.List()
    local out = {}
    for name, bind in pairs(KeybindManager.binds) do
        table.insert(out, string.format("%s [%s] %s", name, bind.key, bind.description))
    end
    table.sort(out)
    return out
end

-- ═══════════════ EXTENSION-08: STATS DASHBOARD ═══════════════
local StatsDashboard = {frame = nil, conn = nil, active = false}
function StatsDashboard.Build()
    if StatsDashboard.frame then return end
    local frame = Instance.new("Frame")
    frame.Name = "MeowDash"
    frame.Size = UDim2.new(0, 200, 0, 84)
    frame.Position = UDim2.new(0, 10, 0, 70)
    frame.BackgroundColor3 = THEME.Surface
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.ZIndex = 40
    frame.Parent = ScreenGui
    corner(frame, 8)
    stroke(frame, THEME.Accent, 1, 0.4)

    local txt = Instance.new("TextLabel")
    txt.Name = "Text"
    txt.Size = UDim2.new(1, -12, 1, -8)
    txt.Position = UDim2.new(0, 6, 0, 4)
    txt.BackgroundTransparency = 1
    txt.Text = "loading..."
    txt.TextColor3 = THEME.Accent
    txt.Font = Enum.Font.Code
    txt.TextSize = 11
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextYAlignment = Enum.TextYAlignment.Top
    txt.TextWrapped = true
    txt.ZIndex = 41
    txt.Parent = frame

    StatsDashboard.frame = frame
end
function StatsDashboard.Start()
    if StatsDashboard.active then return end
    StatsDashboard.Build()
    StatsDashboard.active = true
    local frames, startTime = 0, tick()
    StatsDashboard.conn = RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - startTime >= 0.5 then
            local fps = math.floor(frames / (now - startTime))
            frames = 0
            startTime = now
            local ping = 0
            pcall(function()
                ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            local moduleCount = 0
            for _ in pairs(MM.Modules) do moduleCount = moduleCount + 1 end
            if StatsDashboard.frame then
                local txt = StatsDashboard.frame:FindFirstChild("Text")
                if txt then
                    txt.Text = string.format(
                        "FPS: %d\nPing: %dms\nModules: %d\nUptime: %ds",
                        fps, ping, moduleCount, math.floor(now - (MM._startTime or now))
                    )
                end
            end
        end
    end)
end
function StatsDashboard.Stop()
    StatsDashboard.active = false
    if StatsDashboard.conn then
        pcall(function() StatsDashboard.conn:Disconnect() end)
        StatsDashboard.conn = nil
    end
    if StatsDashboard.frame then
        pcall(function() StatsDashboard.frame:Destroy() end)
        StatsDashboard.frame = nil
    end
end

-- ═══════════════ EXTENSION-08: HELP SCREEN ═══════════════
local HelpScreen = {}
function HelpScreen.Open()
    local existing = ScreenGui:FindFirstChild("MeowHelp")
    if existing then existing:Destroy() end

    local frame = Instance.new("Frame")
    frame.Name = "MeowHelp"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Size = UDim2.new(0, math.min(screenW * 0.92, 500), 0, math.min(screenH * 0.8, 460))
    frame.BackgroundColor3 = THEME.Bg
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.ZIndex = 220
    frame.Parent = ScreenGui
    corner(frame, 12)
    stroke(frame, THEME.Accent, 1.5, 0.3)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = THEME.Surface
    header.BorderSizePixel = 0
    header.ZIndex = 221
    header.Parent = frame
    corner(header, 12)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "MEOW V4 — HELP"
    title.TextColor3 = THEME.Accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 222
    title.Parent = header

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -38, 0, 6)
    close.BackgroundColor3 = THEME.Danger
    close.Text = "×"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 18
    close.BorderSizePixel = 0
    close.ZIndex = 222
    close.Parent = header
    corner(close, 6)
    close.MouseButton1Click:Connect(function() frame:Destroy() end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -60)
    scroll.Position = UDim2.new(0, 10, 0, 50)
    scroll.BackgroundColor3 = THEME.Surface
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = THEME.Accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex = 221
    scroll.Parent = frame
    corner(scroll, 6)

    local list = Instance.new("UIListLayout", scroll)
    list.Padding = UDim.new(0, 3)

    local function addLine(text, color)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  " .. text
        lbl.TextColor3 = color or THEME.Text
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextWrapped = true
        lbl.ZIndex = 222
        lbl.Parent = scroll
    end

    addLine("═══ COMBAT ═══", THEME.Accent)
    addLine("Silent Aim · Wall Check · Headshot")
    addLine("Trigger Bot · Humanizer · FOV Shapes")
    addLine("")
    addLine("═══ VISUALS ═══", THEME.Accent)
    addLine("ESP: box/name/dist/hp/skel/line/distbar/chams")
    addLine("Tracers · Facing · Offscreen · Styles")
    addLine("")
    addLine("═══ MOVEMENT ═══", THEME.Accent)
    addLine("Speed · Fly · Noclip · InfJump")
    addLine("JumpPower · VirtualPos")
    addLine("")
    addLine("═══ WORLD ═══", THEME.Accent)
    addLine("Fullbright · Fog · Clock · Gravity")
    addLine("Barriers · Shadows · Bloom · Blur")
    addLine("CC · SunRays · Atmosphere · Sky")
    addLine("ScreenFX · Particles · TimeScale · Zoom")
    addLine("")
    addLine("═══ VEHICLES ═══", THEME.Accent)
    addLine("ESP · Finder · Tracker · Lock")
    addLine("Seat Stealer · Boost · Fly")
    addLine("")
    addLine("═══ PLAYERS ═══", THEME.Accent)
    addLine("Target selector · Profile · View")
    addLine("Hide · Force Sit/Freeze · Cage")
    addLine("Orbit · Follow · Spectate Next/Prev")
    addLine("")
    addLine("═══ TELEPORT ═══", THEME.Accent)
    addLine("Nearest Enemy · Forward · Up · Back")
    addLine("Behind Target · In Front · XYZ coords")
    addLine("")
    addLine("═══ MISC ═══", THEME.Accent)
    addLine("AutoClicker · ChatSpam · PingSpoof")
    addLine("Anti-AFK · Remote Spy · Anti-Detect")
    addLine("Crash Guard · Console · Notifications")
    addLine("Stats Dashboard")
    addLine("")
    addLine("═══ CONFIG ═══", THEME.Accent)
    addLine("Presets · Theme Color · Custom Accent")
    addLine("Bypass Jitter · Save/Load · FULL UNLOAD")
    addLine("")
    addLine("═══ KEYBINDS (PC only) ═══", THEME.Accent)
    addLine("F1 toggle menu · F2 ESP · F3 Silent")
    addLine("F4 Noclip · F6 Help · F7 Quick Access")
    addLine("")
    addLine("═══ СОВЕТЫ ═══", THEME.Accent)
    addLine("1. Не включай всё сразу — лаги")
    addLine("2. Presets сохраняются на диск")
    addLine("3. Anti-Detect мониторит телепорты")
    addLine("4. FULL UNLOAD полностью выгружает")

    return frame
end

-- ═══════════════ EXTENSION-08: ABOUT SCREEN ═══════════════
local AboutScreen = {}
function AboutScreen.Open()
    local existing = ScreenGui:FindFirstChild("MeowAbout")
    if existing then existing:Destroy() end

    local frame = Instance.new("Frame")
    frame.Name = "MeowAbout"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Size = UDim2.new(0, math.min(screenW * 0.9, 320), 0, 280)
    frame.BackgroundColor3 = THEME.Bg
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.ZIndex = 220
    frame.Parent = ScreenGui
    corner(frame, 12)
    stroke(frame, THEME.Accent, 1.5, 0.3)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 46)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "MEOW"
    title.TextColor3 = THEME.Accent
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 36
    title.ZIndex = 221
    title.Parent = frame

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -20, 0, 20)
    subtitle.Position = UDim2.new(0, 10, 0, 58)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "v" .. MM.Version .. " · mobile heavy"
    subtitle.TextColor3 = THEME.SubText
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 13
    subtitle.ZIndex = 221
    subtitle.Parent = frame

    local moduleCount = 0
    for _ in pairs(MM.Modules) do moduleCount = moduleCount + 1 end
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -20, 0, 90)
    info.Position = UDim2.new(0, 10, 0, 90)
    info.BackgroundTransparency = 1
    info.Text = string.format(
        "Modules: %d\nUptime: %ds\nBuild: %s\nSource: github.com/killuameow1-wq",
        moduleCount,
        math.floor(tick() - (MM._startTime or tick())),
        MM.Version
    )
    info.TextColor3 = THEME.Text
    info.Font = Enum.Font.Code
    info.TextSize = 12
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.ZIndex = 221
    info.Parent = frame

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(1, -20, 0, 38)
    close.Position = UDim2.new(0, 10, 1, -48)
    close.BackgroundColor3 = THEME.Accent
    close.Text = "CLOSE"
    close.TextColor3 = THEME.Bg
    close.Font = Enum.Font.GothamBold
    close.TextSize = 13
    close.BorderSizePixel = 0
    close.ZIndex = 221
    close.Parent = frame
    corner(close, 8)
    close.MouseButton1Click:Connect(function() frame:Destroy() end)

    return frame
end

-- ═══════════════ EXTENSION-08: QUICK ACCESS PANEL ═══════════════
local QuickAccess = {frame = nil, active = false}
function QuickAccess.Build()
    if QuickAccess.frame then return end

    local frame = Instance.new("Frame")
    frame.Name = "MeowQuick"
    frame.Size = UDim2.new(0, 220, 0, 60)
    frame.Position = UDim2.new(1, -230, 0, 70)
    frame.BackgroundColor3 = THEME.Surface
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.ZIndex = 45
    frame.Parent = ScreenGui
    corner(frame, 10)
    stroke(frame, THEME.Accent, 1, 0.3)

    local list = Instance.new("UIListLayout", frame)
    list.FillDirection = Enum.FillDirection.Horizontal
    list.Padding = UDim.new(0, 4)
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local function makeQuickBtn(text, cb)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 40)
        btn.BackgroundColor3 = THEME.SurfaceHi
        btn.Text = text
        btn.TextColor3 = THEME.Accent
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.ZIndex = 46
        btn.Parent = frame
        corner(btn, 20)
        stroke(btn, THEME.Border, 1, 0.4)
        btn.MouseButton1Click:Connect(function()
            btn.BackgroundColor3 = THEME.Success
            task.wait(0.1)
            btn.BackgroundColor3 = THEME.SurfaceHi
            pcall(cb)
        end)
        return btn
    end

    makeQuickBtn("E", function()
        Config.ESP = not Config.ESP
    end)
    makeQuickBtn("S", function()
        Config.SilentAim = not Config.SilentAim
    end)
    makeQuickBtn("N", function()
        Config.Noclip = not Config.Noclip
        if Config.Noclip then Noclip.Start() else Noclip.Stop() end
    end)
    makeQuickBtn("F", function()
        Config.FlyOn = not Config.FlyOn
        if Config.FlyOn then Fly.Start() else Fly.Stop() end
    end)

    QuickAccess.frame = frame
end
function QuickAccess.Show()
    QuickAccess.Build()
    if QuickAccess.frame then QuickAccess.frame.Visible = true end
    QuickAccess.active = true
end
function QuickAccess.Hide()
    if QuickAccess.frame then QuickAccess.frame.Visible = false end
    QuickAccess.active = false
end
function QuickAccess.Toggle()
    if QuickAccess.active then QuickAccess.Hide() else QuickAccess.Show() end
    return QuickAccess.active
end

-- ═══════════════ EXTENSION-08: VERSION CHECK ═══════════════
local VersionCheck = {
    remoteUrl = "https://raw.githubusercontent.com/killuameow1-wq/testMeowMod/refs/heads/main/version.txt",
    localVersion = MM.Version,
}
function VersionCheck.Check()
    local ok, response = pcall(function()
        return game:HttpGet(VersionCheck.remoteUrl)
    end)
    if not ok or not response then
        Notifications.Push("Update", "check failed", THEME.Warn)
        return false
    end
    local remote = response:gsub("%s+", "")
    if remote ~= VersionCheck.localVersion then
        Notifications.Push("Update", "new: " .. remote, THEME.Accent, 6)
        Logger.Write("UPD", "remote=" .. remote .. " local=" .. VersionCheck.localVersion)
        return remote
    end
    Notifications.Push("Update", "up to date", THEME.Success)
    return true
end

-- ═══════════════ EXTENSION-08: KEYBINDS REGISTRATION ═══════════════
KeybindManager.Register("Toggle Menu", "F1", function()
    if Main.Visible then CloseMenu() else OpenMenu() end
end, "toggle UI")
KeybindManager.Register("Toggle ESP", "F2", function()
    Config.ESP = not Config.ESP
    Notifications.Push("Keybind", "ESP " .. (Config.ESP and "on" or "off"), THEME.Accent)
end, "ESP toggle")
KeybindManager.Register("Toggle Silent", "F3", function()
    Config.SilentAim = not Config.SilentAim
    Notifications.Push("Keybind", "Silent " .. (Config.SilentAim and "on" or "off"), THEME.Accent)
end, "Silent toggle")
KeybindManager.Register("Toggle Noclip", "F4", function()
    Config.Noclip = not Config.Noclip
    if Config.Noclip then Noclip.Start() else Noclip.Stop() end
    Notifications.Push("Keybind", "Noclip " .. (Config.Noclip and "on" or "off"), THEME.Accent)
end, "Noclip toggle")
KeybindManager.Register("Help", "F6", function()
    HelpScreen.Open()
end, "help screen")
KeybindManager.Register("Quick Access", "F7", function()
    QuickAccess.Toggle()
end, "quick buttons")
KeybindManager.StartListener()

-- ═══════════════ EXTENSION-09: AIM CURVES ═══════════════
local AimCurves = {
    current = "linear",
    curves = {},
}
function AimCurves.Define(name, fn)
    AimCurves.curves[name] = fn
end
AimCurves.Define("linear", function(t) return t end)
AimCurves.Define("ease_in", function(t) return t * t end)
AimCurves.Define("ease_out", function(t) return 1 - (1 - t) ^ 2 end)
AimCurves.Define("ease_in_out", function(t)
    if t < 0.5 then return 2 * t * t end
    return 1 - (-2 * t + 2) ^ 2 / 2
end)
AimCurves.Define("smooth_step", function(t) return t * t * (3 - 2 * t) end)
AimCurves.Define("ease_out_cubic", function(t) return 1 - (1 - t) ^ 3 end)
AimCurves.Define("ease_out_quart", function(t) return 1 - (1 - t) ^ 4 end)
AimCurves.Define("ease_out_expo", function(t)
    if t == 1 then return 1 end
    return 1 - 2 ^ (-10 * t)
end)
function AimCurves.Apply(t, name)
    name = name or AimCurves.current
    local fn = AimCurves.curves[name]
    if not fn then fn = AimCurves.curves.linear end
    return fn(math.clamp(t, 0, 1))
end
function AimCurves.List()
    local out = {}
    for name in pairs(AimCurves.curves) do table.insert(out, name) end
    table.sort(out)
    return out
end

-- ═══════════════ EXTENSION-09: AIM ZONES ═══════════════
local AimZones = {
    zones = {
        head = {priority = 100, offset = Vector3.new(0, 0, 0)},
        upper_torso = {priority = 70, offset = Vector3.new(0, 0.5, 0)},
        lower_torso = {priority = 50, offset = Vector3.new(0, -0.5, 0)},
        legs = {priority = 20, offset = Vector3.new(0, -2, 0)},
    },
    currentPriority = "head",
}
function AimZones.GetBoneName(priority)
    local map = {
        head = "Head",
        upper_torso = "UpperTorso",
        lower_torso = "LowerTorso",
        legs = "LeftUpperLeg",
    }
    return map[priority] or "Head"
end
function AimZones.GetTargetPosition(char, priority)
    if not char then return nil end
    local boneName = AimZones.GetBoneName(priority)
    local part = char:FindFirstChild(boneName)
    if part then return part.Position end
    local head = char:FindFirstChild("Head")
    return head and head.Position or nil
end
function AimZones.SetPriority(p) AimZones.currentPriority = p end
function AimZones.List()
    local out = {}
    for name, _ in pairs(AimZones.zones) do table.insert(out, name) end
    table.sort(out)
    return out
end

-- ═══════════════ EXTENSION-09: HITBOX RESOLVER ═══════════════
local HitboxResolver = {
    mode = "head",
    detectVanity = false,
}
function HitboxResolver.Resolve(char)
    if not char then return nil end
    if HitboxResolver.mode == "head" then
        return char:FindFirstChild("Head")
    elseif HitboxResolver.mode == "closest" then
        local camPos = Camera.CFrame.Position
        local best, bestD = nil, math.huge
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local d = (camPos - part.Position).Magnitude
                if d < bestD then bestD = d best = part end
            end
        end
        return best
    elseif HitboxResolver.mode == "torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    elseif HitboxResolver.mode == "center" then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        return hrp
    elseif HitboxResolver.mode == "zone" then
        return AimZones.GetTargetPosition(char, AimZones.currentPriority)
    end
    return char:FindFirstChild("Head")
end
function HitboxResolver.SetMode(m) HitboxResolver.mode = m end
function HitboxResolver.List()
    return {"head", "closest", "torso", "center", "zone"}
end

-- ═══════════════ EXTENSION-09: PREDICTION PROFILES ═══════════════
local PredictionProfiles = {
    profiles = {
        none = {multiplier = 0, gravity = 0},
        low = {multiplier = 0.5, gravity = 0.3},
        medium = {multiplier = 1.0, gravity = 0.6},
        high = {multiplier = 1.5, gravity = 1.0},
        extreme = {multiplier = 2.0, gravity = 1.5},
    },
    current = "medium",
}
function PredictionProfiles.Get(name)
    return PredictionProfiles.profiles[name or PredictionProfiles.current]
end
function PredictionProfiles.Set(name)
    if PredictionProfiles.profiles[name] then
        PredictionProfiles.current = name
        return true
    end
    return false
end
function PredictionProfiles.List()
    local out = {}
    for name in pairs(PredictionProfiles.profiles) do table.insert(out, name) end
    table.sort(out)
    return out
end
function PredictionProfiles.Predict(targetPart, ping)
    local prof = PredictionProfiles.Get()
    if not targetPart or prof.multiplier <= 0 then return targetPart and targetPart.Position end
    local vel = targetPart.AssemblyLinearVelocity or Vector3.zero
    local t = (ping or 0.1) * prof.multiplier
    local pos = targetPart.Position + vel * t
    if prof.gravity > 0 then
        pos = pos + Vector3.new(0, -0.5 * 196.2 * prof.gravity * t * t, 0)
    end
    return pos
end

-- ═══════════════ EXTENSION-09: AIM ASSIST MODES ═══════════════
local AimAssist = {
    mode = "snap",
    snapStrength = 1.0,
    trackingSpeed = 0.15,
    currentTarget = nil,
    currentPos = nil,
}
function AimAssist.SetMode(m) AimAssist.mode = m end
function AimAssist.SetTrackingSpeed(s) AimAssist.trackingSpeed = math.clamp(s, 0.01, 1) end
function AimAssist.Update(targetPos)
    if not targetPos then AimAssist.currentPos = nil return end
    if AimAssist.mode == "snap" then
        AimAssist.currentPos = targetPos
    elseif AimAssist.mode == "track" then
        if not AimAssist.currentPos then AimAssist.currentPos = targetPos
        else
            AimAssist.currentPos = AimAssist.currentPos:Lerp(targetPos, AimAssist.trackingSpeed)
        end
    elseif AimAssist.mode == "curve" then
        if not AimAssist.currentPos then AimAssist.currentPos = targetPos
        else
            local t = AimAssist.trackingSpeed
            local curved = AimCurves.Apply(t, "ease_out_quint")
            AimAssist.currentPos = AimAssist.currentPos:Lerp(targetPos, curved)
        end
    end
end
function AimAssist.Get() return AimAssist.currentPos end
function AimAssist.Reset() AimAssist.currentPos = nil end
function AimAssist.List()
    return {"snap", "track", "curve"}
end

-- ═══════════════ EXTENSION-09: SPREAD COMPENSATION ═══════════════
local SpreadComp = {
    enabled = false,
    currentSpread = 0,
    lastFireTime = 0,
    fireInterval = 0.1,
}
function SpreadComp.Enable() SpreadComp.enabled = true end
function SpreadComp.Disable() SpreadComp.enabled = false end
function SpreadComp.RegisterShot()
    local now = tick()
    if now - SpreadComp.lastFireTime < SpreadComp.fireInterval then
        SpreadComp.currentSpread = math.min(SpreadComp.currentSpread + 0.01, 0.1)
    else
        SpreadComp.currentSpread = 0
    end
    SpreadComp.lastFireTime = now
end
function SpreadComp.GetOffset()
    if not SpreadComp.enabled or SpreadComp.currentSpread == 0 then return Vector3.zero end
    return Vector3.new(
        (math.random() - 0.5) * SpreadComp.currentSpread,
        (math.random() - 0.5) * SpreadComp.currentSpread,
        0
    )
end

-- ═══════════════ EXTENSION-09: RECOIL CONTROL ═══════════════
local RecoilControl = {
    enabled = false,
    strength = 0.5,
    verticalPattern = {},
    horizontalPattern = {},
    shotIndex = 0,
}
function RecoilControl.Enable() RecoilControl.enabled = true end
function RecoilControl.Disable() RecoilControl.enabled = false end
function RecoilControl.RegisterShot()
    RecoilControl.shotIndex = RecoilControl.shotIndex + 1
    local v = 0.01 * RecoilControl.strength * RecoilControl.shotIndex
    local h = (math.random() - 0.5) * 0.005 * RecoilControl.strength
    table.insert(RecoilControl.verticalPattern, v)
    table.insert(RecoilControl.horizontalPattern, h)
end
function RecoilControl.Reset()
    RecoilControl.shotIndex = 0
    RecoilControl.verticalPattern = {}
    RecoilControl.horizontalPattern = {}
end
function RecoilControl.GetCompensation()
    if not RecoilControl.enabled then return Vector2.zero end
    local v = 0
    local h = 0
    for i, val in ipairs(RecoilControl.verticalPattern) do
        v = v - val
    end
    for i, val in ipairs(RecoilControl.horizontalPattern) do
        h = h - val
    end
    return Vector2.new(h, v)
end

-- ═══════════════ EXTENSION-09: TARGET PRIORITY ═══════════════
local TargetPriority = {
    mode = "distance",
    weights = {
        distance = 1.0,
        health = 0.5,
        threat = 0.8,
        facing = 0.6,
        visibility = 1.2,
    },
}
function TargetPriority.SetMode(m) TargetPriority.mode = m end
function TargetPriority.Score(player, myPos, myTeam)
    local char = player.Character
    if not char then return -math.huge end
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not (head and hum and hrp and hum.Health > 0) then return -math.huge end
    if myTeam and player.Team == myTeam then return -math.huge end
    local dist = (myPos - head.Position).Magnitude
    if TargetPriority.mode == "distance" then
        return 500 - dist
    elseif TargetPriority.mode == "health" then
        local hp = hum.Health / math.max(hum.MaxHealth, 1)
        return (1 - hp) * 100
    elseif TargetPriority.mode == "facing" then
        local look = hrp.CFrame.LookVector
        local toMe = (myPos - hrp.Position).Unit
        return look:Dot(toMe) * 100
    elseif TargetPriority.mode == "threat" then
        local hp = hum.Health / math.max(hum.MaxHealth, 1)
        local look = hrp.CFrame.LookVector
        local toMe = (myPos - hrp.Position).Unit
        local facing = look:Dot(toMe)
        return (facing * 0.5 + 0.5) * hp * 100 - dist * 0.1
    elseif TargetPriority.mode == "mixed" then
        local hp = hum.Health / math.max(hum.MaxHealth, 1)
        local look = hrp.CFrame.LookVector
        local toMe = (myPos - hrp.Position).Unit
        local facing = (look:Dot(toMe) + 1) * 0.5
        return (500 - dist) * TargetPriority.weights.distance +
               hp * 100 * TargetPriority.weights.health +
               facing * 100 * TargetPriority.weights.facing
    end
    return 500 - dist
end
function TargetPriority.Best(players, myPos, myTeam)
    local best, bestScore = nil, -math.huge
    for _, p in ipairs(players) do
        if p ~= LP then
            local score = TargetPriority.Score(p, myPos, myTeam)
            if score > bestScore then bestScore = score best = p end
        end
    end
    return best, bestScore
end
function TargetPriority.List()
    return {"distance", "health", "facing", "threat", "mixed"}
end

-- ═══════════════ EXTENSION-09: AIM SMOOTHING PROFILES ═══════════════
local SmoothProfiles = {
    profiles = {
        instant = {factor = 1.0, curve = "linear"},
        fast = {factor = 0.7, curve = "ease_out"},
        medium = {factor = 0.4, curve = "ease_in_out"},
        slow = {factor = 0.2, curve = "ease_out_cubic"},
        smooth = {factor = 0.1, curve = "smooth_step"},
    },
    current = "medium",
}
function SmoothProfiles.Get(name)
    return SmoothProfiles.profiles[name or SmoothProfiles.current]
end
function SmoothProfiles.Set(name)
    if SmoothProfiles.profiles[name] then
        SmoothProfiles.current = name
        Smoothing.factor = SmoothProfiles.profiles[name].factor
        return true
    end
    return false
end
function SmoothProfiles.Apply(current, target)
    local prof = SmoothProfiles.Get()
    local t = AimCurves.Apply(prof.factor, prof.curve)
    return current + (target - current) * t
end
function SmoothProfiles.List()
    local out = {}
    for name in pairs(SmoothProfiles.profiles) do table.insert(out, name) end
    table.sort(out)
    return out
end

-- ═══════════════ EXTENSION-09: VELOCITY SMOOTHING ═══════════════
local VelocitySmoothing = {
    enabled = false,
    window = 5,
    history = {},
}
function VelocitySmoothing.Enable() VelocitySmoothing.enabled = true end
function VelocitySmoothing.Disable() VelocitySmoothing.enabled = false VelocitySmoothing.history = {} end
function VelocitySmoothing.Record(part)
    if not VelocitySmoothing.enabled or not part then return end
    table.insert(VelocitySmoothing.history, {pos = part.Position, t = tick()})
    if #VelocitySmoothing.history > VelocitySmoothing.window then
        table.remove(VelocitySmoothing.history, 1)
    end
end
function VelocitySmoothing.GetVelocity(part)
    if not VelocitySmoothing.enabled or #VelocitySmoothing.history < 2 then
        return part and part.AssemblyLinearVelocity or Vector3.zero
    end
    local first = VelocitySmoothing.history[1]
    local last = VelocitySmoothing.history[#VelocitySmoothing.history]
    local dt = last.t - first.t
    if dt <= 0 then return Vector3.zero end
    return (last.pos - first.pos) / dt
end

-- ═══════════════ EXTENSION-09: LOCK HOLD ═══════════════
local LockHold = {
    active = false,
    target = nil,
    maxHold = 0.5,
    lastSeen = 0,
}
function LockHold.Enable() LockHold.active = true end
function LockHold.Disable() LockHold.active = false LockHold.target = nil end
function LockHold.Update(target)
    if target then
        LockHold.target = target
        LockHold.lastSeen = tick()
    elseif LockHold.target and tick() - LockHold.lastSeen > LockHold.maxHold then
        LockHold.target = nil
    end
end
function LockHold.Get() return LockHold.target end

-- ═══════════════ AIM ═══════════════
local AimState = {target = nil, silentActive = false, isShooting = false, lastSwitch = 0, switchCD = 0.25}
local function GetFovRadiusPx() return (Camera.ViewportSize.Y / 2) * (Config.FOVPercent / 100) end
local function IsInFov(worldPos)
    local sp, on = Camera:WorldToViewportPoint(worldPos)
    if not on or sp.Z < 0 then return false, 0 end
    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    local d = math.sqrt((sp.X - cx) ^ 2 + (sp.Y - cy) ^ 2)
    return d <= GetFovRadiusPx(), d
end
local function IsVisible(head)
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LP.Character, head.Parent}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    return WS:Raycast(Camera.CFrame.Position, head.Position - Camera.CFrame.Position, rp) == nil
end
local function GetTarget()
    local myChar = LP.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHrp or not myHum or myHum.Health <= 0 then return nil end
    local myPos = myHrp.Position
    local best, bestScore = nil, -math.huge
    local now = tick()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and PassesTeamFilter(p) then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if head and hum and hrp and hum.Health > 0 then
                local d3 = (myPos - head.Position).Magnitude
                if d3 <= Config.MaxDistance then
                    local inFov = IsInFov(head.Position)
                    if inFov then
                        local score = 500 - d3
                        local hp = hum.Health / math.max(hum.MaxHealth, 1)
                        score = score - (1 - hp) * 50
                        if Config.WallCheck and not IsVisible(head) then score = score - 200 end
                        if now - AimState.lastSwitch < AimState.switchCD then score = score + 40 end
                        if score > bestScore then bestScore = score best = head end
                    end
                end
            end
        end
    end
    if best then AimState.lastSwitch = now end
    return best
end

pcall(function()
    local mt = getrawmetatable(game)
    local oldNC = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        if AimState.silentActive and AimState.target and AimState.target.Parent then
            local m = getnamecallmethod()
            local args = {...}
            local off = Vector3.new((math.random() - 0.5) * 0.1, (math.random() - 0.5) * 0.1, (math.random() - 0.5) * 0.1)
            local tPos = AimState.target.Position + off
            if m == "Raycast" and typeof(args[1]) == "Vector3" then
                args[2] = tPos - args[1]
                return oldNC(self, unpack(args))
            elseif (m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList") and typeof(args[1]) == "Ray" then
                args[1] = Ray.new(args[1].Origin, tPos - args[1].Origin)
                return oldNC(self, unpack(args))
            end
        end
        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
end)

AddConn(UIS.InputBegan:Connect(function(inp, gp)
    if not gp and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
        AimState.isShooting = true
    end
end))
AddConn(UIS.InputEnded:Connect(function(inp, gp)
    if not gp and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
        AimState.isShooting = false
    end
end))

-- ═══════════════ ESP ═══════════════
local ESPDraws = {}
local BONE_PAIRS = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local function CreateESPDraws(player)
    if ESPDraws[player] then return ESPDraws[player] end
    local ok, t = pcall(function()
        local tbl = {
            Line = Drawing.new("Line"), Box = Drawing.new("Square"),
            NameBg = Drawing.new("Square"), Name = Drawing.new("Text"),
            Dist = Drawing.new("Text"), HpBg = Drawing.new("Square"),
            HpBar = Drawing.new("Square"), HpText = Drawing.new("Text"),
            OffArrow = Drawing.new("Triangle"),
            DistBarBg = Drawing.new("Square"), DistBarFg = Drawing.new("Square"),
            Bones = {},
        }
        tbl.Line.Thickness = 1; tbl.Box.Thickness = 1
        tbl.Name.Size = 13; tbl.Name.Center = true; tbl.Name.Outline = true
        tbl.Dist.Size = 12; tbl.Dist.Center = true; tbl.Dist.Outline = true
        tbl.HpBg.Filled = true; tbl.HpBg.Color = Color3.new(0, 0, 0)
        tbl.HpBar.Filled = true
        tbl.HpText.Size = 10; tbl.HpText.Center = true; tbl.HpText.Outline = true
        tbl.NameBg.Filled = true; tbl.NameBg.Color = Color3.fromRGB(15, 15, 22); tbl.NameBg.Transparency = 0.7
        tbl.OffArrow.Filled = true
        tbl.DistBarBg.Filled = true; tbl.DistBarFg.Filled = true
        for i = 1, #BONE_PAIRS do
            tbl.Bones[i] = Drawing.new("Line"); tbl.Bones[i].Thickness = 1
        end
        return tbl
    end)
    if not ok or not t then return nil end
    ESPDraws[player] = t
    return t
end
local function RemoveESPDraws(player)
    if not ESPDraws[player] then return end
    for k, v in pairs(ESPDraws[player]) do
        if k == "Bones" then for _, b in ipairs(v) do pcall(function() b:Remove() end) end
        else pcall(function() v:Remove() end) end
    end
    ESPDraws[player] = nil
end
AddConn(Players.PlayerRemoving:Connect(RemoveESPDraws))

local function ForceHide(d)
    if not d then return end
    for _, k in ipairs({"Line","Box","NameBg","Name","Dist","HpBg","HpBar","HpText","OffArrow","DistBarBg","DistBarFg"}) do
        if d[k] then d[k].Visible = false end
    end
    if d.Bones then for _, b in pairs(d.Bones) do pcall(function() b.Visible = false end) end end
end
local function GetScreenBox(char)
    local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
    if ok and cf and size then
        local tS, tOn = Camera:WorldToViewportPoint(cf.Position + Vector3.new(0, size.Y / 2, 0))
        local bS, bOn = Camera:WorldToViewportPoint(cf.Position - Vector3.new(0, size.Y / 2, 0))
        local lS, lOn = Camera:WorldToViewportPoint(cf.Position - Vector3.new(size.X / 2, 0, 0))
        local rS, rOn = Camera:WorldToViewportPoint(cf.Position + Vector3.new(size.X / 2, 0, 0))
        if tOn and bOn and lOn and rOn then
            local w = math.abs(rS.X - lS.X)
            local h = math.abs(bS.Y - tS.Y)
            if w > 0 and h > 0 and w < 800 and h < 800 then
                return {x = lS.X, y = tS.Y, w = w, h = h}
            end
        end
    end
    return nil
end
local function OffscreenArrowPos(sp, margin)
    local vp = Camera.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local dx, dy = sp.X - cx, sp.Y - cy
    if math.abs(dx) < 0.001 and math.abs(dy) < 0.001 then dx = 1 end
    local tx = (cx - margin) / math.max(math.abs(dx), 0.0001)
    local ty = (cy - margin) / math.max(math.abs(dy), 0.0001)
    local t = math.min(tx, ty)
    return Vector2.new(cx + dx * t, cy + dy * t)
end

local CH1 = Drawing.new("Line"); local CH2 = Drawing.new("Line")
CH1.Thickness = 2; CH2.Thickness = 2
CH1.Color = Config.ColorNeon; CH2.Color = Config.ColorNeon
AddDraw(CH1); AddDraw(CH2)

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.Transparency = 0.8
FOVCircle.Color = Config.ColorSilent; FOVCircle.Filled = false
AddDraw(FOVCircle)

local function RenderESP()
    if not Config.ESP then
        for _, d in pairs(ESPDraws) do ForceHide(d) end
        CH1.Visible = false; CH2.Visible = false; FOVCircle.Visible = false
        return
    end
    if Config.Crosshair then
        local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
        local sz = Config.CH_Size
        CH1.From = Vector2.new(cx - sz, cy); CH1.To = Vector2.new(cx + sz, cy); CH1.Visible = true
        CH2.From = Vector2.new(cx, cy - sz); CH2.To = Vector2.new(cx, cy + sz); CH2.Visible = true
    else CH1.Visible = false; CH2.Visible = false end
    local myChar = LP.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local playerAlive = myHum and myHum.Health > 0
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local d = ESPDraws[p]
            if not playerAlive then if d then ForceHide(d) end
            else
                local char = p.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local head = char and char:FindFirstChild("Head")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not (char and hrp and head and hum and hum.Health > 0 and PassesTeamFilter(p)) then
                    if d then ForceHide(d) end
                else
                    local d3 = myPos and (myPos - hrp.Position).Magnitude or 0
                    if d3 > Config.MaxDistance then if d then ForceHide(d) end
                    else
                        local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        if not d then d = CreateESPDraws(p) end
                        if d then
                            local isEnemy = LP.Team and p.Team and p.Team ~= LP.Team
                            local color = (LP.Team and p.Team) and (isEnemy and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 200, 255)) or DistToColor(d3)
                            if not onScreen and Config.ESP_Offscreen then
                                local arrPos = OffscreenArrowPos(sp, 40)
                                local dir = (Vector2.new(sp.X, sp.Y) - arrPos).Unit
                                local perp = Vector2.new(-dir.Y, dir.X)
                                d.OffArrow.PointA = arrPos + dir * 14
                                d.OffArrow.PointB = arrPos - dir * 8 + perp * 10
                                d.OffArrow.PointC = arrPos - dir * 8 - perp * 10
                                d.OffArrow.Color = color
                                ForceHide(d); d.OffArrow.Visible = true
                            elseif not onScreen then ForceHide(d)
                            else
                                d.OffArrow.Visible = false
                                local box = GetScreenBox(char)
                                local x, y, w, h
                                if box then x, y, w, h = box.x, box.y, box.w, box.h
                                else
                                    h = math.clamp(8000 / math.max(d3, 1), 20, 500)
                                    w = h / 2; x = sp.X - w / 2; y = sp.Y - h / 2
                                end
                                d.Box.Visible = Config.ESP_Box
                                if d.Box.Visible then
                                    d.Box.Size = Vector2.new(w, h)
                                    d.Box.Position = Vector2.new(x, y)
                                    d.Box.Color = color
                                end
                                d.Line.Visible = Config.ESP_Line
                                if d.Line.Visible then
                                    d.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                    d.Line.To = Vector2.new(sp.X, sp.Y)
                                    d.Line.Color = color
                                end
                                d.Name.Visible = Config.ESP_Name
                                d.NameBg.Visible = Config.ESP_Name
                                if d.Name.Visible then
                                    local prefix = ""
                                    if LP.Team and p.Team then prefix = isEnemy and "[E] " or "[A] " end
                                    d.Name.Text = prefix .. p.Name
                                    d.Name.Position = Vector2.new(x + w / 2, y - 18)
                                    d.Name.Color = color
                                    local tw = #(prefix .. p.Name) * 7
                                    d.NameBg.Size = Vector2.new(tw + 12, 18)
                                    d.NameBg.Position = Vector2.new(x + w / 2 - (tw + 12) / 2, y - 19)
                                end
                                d.Dist.Visible = Config.ESP_Dist
                                if d.Dist.Visible then
                                    d.Dist.Text = tostring(math.floor(d3)) .. "m"
                                    d.Dist.Position = Vector2.new(x + w / 2, y + h + 2)
                                    d.Dist.Color = color
                                end
                                d.HpBg.Visible = Config.ESP_HP
                                d.HpBar.Visible = Config.ESP_HP
                                d.HpText.Visible = Config.ESP_HP
                                if d.HpBar.Visible and hum.MaxHealth > 0 then
                                    local hpP = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                    local hpColor = Color3.fromRGB(255 * (1 - hpP), 255 * hpP, 0)
                                    d.HpBg.Size = Vector2.new(4, h); d.HpBg.Position = Vector2.new(x - 8, y)
                                    d.HpBar.Size = Vector2.new(4, h * hpP); d.HpBar.Position = Vector2.new(x - 8, y + h * (1 - hpP))
                                    d.HpBar.Color = hpColor
                                    d.HpText.Text = tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth))
                                    d.HpText.Position = Vector2.new(x - 10, y - 15); d.HpText.Color = hpColor
                                end
                                for i, pair in ipairs(BONE_PAIRS) do
                                    local a = char:FindFirstChild(pair[1]); local b = char:FindFirstChild(pair[2])
                                    local bone = d.Bones[i]
                                    if Config.ESP_Skeleton and a and b then
                                        local pa, onA = Camera:WorldToViewportPoint(a.Position)
                                        local pb, onB = Camera:WorldToViewportPoint(b.Position)
                                        if onA and onB then
                                            bone.From = Vector2.new(pa.X, pa.Y); bone.To = Vector2.new(pb.X, pb.Y)
                                            bone.Color = color; bone.Visible = true
                                        else bone.Visible = false end
                                    else bone.Visible = false end
                                end
                                if Config.ESP_DistBar then
                                    local frac = math.clamp(1 - d3 / Config.MaxDistance, 0, 1)
                                    d.DistBarBg.Visible = true; d.DistBarBg.Size = Vector2.new(w, 3)
                                    d.DistBarBg.Position = Vector2.new(x, y + h + 18); d.DistBarBg.Color = Color3.fromRGB(30, 30, 40)
                                    d.DistBarFg.Visible = true; d.DistBarFg.Size = Vector2.new(w * frac, 3)
                                    d.DistBarFg.Position = Vector2.new(x, y + h + 18); d.DistBarFg.Color = color
                                else d.DistBarBg.Visible = false; d.DistBarFg.Visible = false end
                                if Config.ESP_Chams then
                                    local hl = char:FindFirstChild("MeowCham_" .. p.Name)
                                    if not hl then
                                        hl = Instance.new("Highlight")
                                        hl.Name = "MeowCham_" .. p.Name
                                        hl.FillColor = color; hl.OutlineColor = Color3.new(1, 1, 1)
                                        hl.FillTransparency = 0.5; hl.OutlineTransparency = 0.2
                                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = char
                                    end
                                else
                                    local hl = char:FindFirstChild("MeowCham_" .. p.Name)
                                    if hl then hl:Destroy() end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function ApplyHitbox()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if Config.HitboxExpander then
                    hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    hrp.Transparency = 0.7; hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2, 2, 1); hrp.Transparency = 1; hrp.CanCollide = true
                end
            end
        end
    end
end

local function RenderLogic()
    if Config.SilentAim and AimState.isShooting then
        AimState.target = GetTarget(); AimState.silentActive = AimState.target ~= nil
        if AimState.target then
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            FOVCircle.Radius = GetFovRadiusPx()
            FOVCircle.Visible = Config.ShowFOV
            FOVCircle.Color = Config.ColorSilent
        else FOVCircle.Visible = false end
    else
        AimState.silentActive = false; AimState.target = nil; FOVCircle.Visible = false
    end
    ApplyHitbox()
end

RunService:BindToRenderStep("MeowESP", Enum.RenderPriority.Camera.Value + 1, RenderESP)
RunService:BindToRenderStep("MeowLogic", Enum.RenderPriority.Camera.Value + 3, RenderLogic)

-- ═══════════════ PLAYER LIST ═══════════════
local PL = Instance.new("UIListLayout", Pages["Players"])
PL.Padding = UDim.new(0, 6)
local function UpdatePlayerList()
    for _, v in pairs(Pages["Players"]:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and PassesTeamFilter(p) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
                local Btn = Instance.new("TextButton")
                Btn.Size = UDim2.new(1, 0, 0, 46)
                Btn.BackgroundColor3 = THEME.Surface
                Btn.Text = "  " .. p.Name .. "     " .. d .. "m"
                Btn.TextColor3 = DistToColor(d)
                Btn.TextXAlignment = Enum.TextXAlignment.Left
                Btn.Font = Enum.Font.GothamMedium
                Btn.TextSize = 13
                Btn.BorderSizePixel = 0
                Btn.Parent = Pages["Players"]
                corner(Btn, 8)
                Btn.MouseButton1Click:Connect(function()
                    if hrp then SafeTeleport(hrp.Position + Vector3.new(Config.TP_PlayerOffset, 3, Config.TP_PlayerOffset), "player") end
                end)
            end
        end
    end
end
task.spawn(function() while task.wait(2) do UpdatePlayerList() end end)

-- ═══════════════ UI — COMBAT ═══════════════
CreateToggle(Pages["Combat"], "Silent Aim", Config.SilentAim, nil, "SilentAim")
CreateToggle(Pages["Combat"], "Strict FOV", Config.StrictFOV, nil, "StrictFOV")
CreateToggle(Pages["Combat"], "Show FOV Circle", Config.ShowFOV, nil, "ShowFOV")
CreateToggle(Pages["Combat"], "Headshot", Config.Headshot, nil, "Headshot")
CreateToggle(Pages["Combat"], "Wall Check", Config.WallCheck, nil, "WallCheck")
CreateToggle(Pages["Combat"], "Bypass v15", Config.Bypass, nil, "Bypass")
CreateSlider(Pages["Combat"], "FOV %", 5, 100, Config.FOVPercent, nil, "FOVPercent")
CreateSlider(Pages["Combat"], "Max Dist", 500, 5000, Config.MaxDistance, nil, "MaxDistance")
CreateSlider(Pages["Combat"], "Prediction x10", 5, 30, math.floor(Config.PredictionMultiplier * 10), function(v) Config.PredictionMultiplier = v / 10 end)

-- ═══════════════ UI — VISUALS ═══════════════
CreateToggle(Pages["Visuals"], "ESP Master", Config.ESP, nil, "ESP")
CreateToggle(Pages["Visuals"], " - Line", Config.ESP_Line, nil, "ESP_Line")
CreateToggle(Pages["Visuals"], " - Box", Config.ESP_Box, nil, "ESP_Box")
CreateToggle(Pages["Visuals"], " - Name", Config.ESP_Name, nil, "ESP_Name")
CreateToggle(Pages["Visuals"], " - Dist", Config.ESP_Dist, nil, "ESP_Dist")
CreateToggle(Pages["Visuals"], " - HP", Config.ESP_HP, nil, "ESP_HP")
CreateToggle(Pages["Visuals"], " - Skeleton", Config.ESP_Skeleton, nil, "ESP_Skeleton")
CreateToggle(Pages["Visuals"], " - Offscreen", Config.ESP_Offscreen, nil, "ESP_Offscreen")
CreateToggle(Pages["Visuals"], " - Dist Bar", Config.ESP_DistBar, nil, "ESP_DistBar")
CreateToggle(Pages["Visuals"], " - Chams", Config.ESP_Chams, nil, "ESP_Chams")
CreateCycle(Pages["Visuals"], "Team Filter", {"all", "enemy", "my"}, Config.TeamFilter, nil, "TeamFilter")
CreateToggle(Pages["Visuals"], "Hitbox Expander", Config.HitboxExpander, function(v) Config.HitboxExpander = v end, "HitboxExpander")
CreateSlider(Pages["Visuals"], "Hitbox Size", 2, 20, Config.HitboxSize, nil, "HitboxSize")
CreateToggle(Pages["Visuals"], "Crosshair", Config.Crosshair, nil, "Crosshair")
CreateSlider(Pages["Visuals"], "CH Size", 5, 30, Config.CH_Size, nil, "CH_Size")

-- ═══════════════ UI — MOVEMENT ═══════════════
CreateToggle(Pages["Movement"], "Speed Hack", Config.SpeedOn, function(v) Config.SpeedOn = v ApplySpeed() end, "SpeedOn")
CreateSlider(Pages["Movement"], "Speed Value", 16, 200, Config.SpeedValue, function(v) if Config.SpeedOn then ApplySpeed() end end, "SpeedValue")
CreateToggle(Pages["Movement"], "Fly", Config.FlyOn, function(v) Config.FlyOn = v if v then Fly.Start() else Fly.Stop() end end, "FlyOn")
CreateSlider(Pages["Movement"], "Fly Speed", 1, 500, Config.FlySpeed, function(v) Fly.speed = v end, "FlySpeed")
CreateToggle(Pages["Movement"], "Noclip", Config.Noclip, function(v) Config.Noclip = v if v then Noclip.Start() else Noclip.Stop() end end, "Noclip")
CreateToggle(Pages["Movement"], "Infinite Jump", Config.InfJump, function(v) Config.InfJump = v if v then InfJump.Start() else InfJump.Stop() end end, "InfJump")
CreateToggle(Pages["Movement"], "Jump Power On", Config.JumpPowerOn, function(v) Config.JumpPowerOn = v ApplyJumpPower() end, "JumpPowerOn")
CreateSlider(Pages["Movement"], "Jump Power", 50, 500, Config.JumpPower, function(v) if Config.JumpPowerOn then ApplyJumpPower() end end, "JumpPower")

-- ═══════════════ UI — WORLD ═══════════════
CreateToggle(Pages["World"], "Fullbright", Config.Fullbright, function(v) Config.Fullbright = v ApplyFullbright() end, "Fullbright")
CreateToggle(Pages["World"], "Fog Off", Config.FogOff, function(v) Config.FogOff = v ApplyFogOff() end, "FogOff")
CreateSlider(Pages["World"], "Clock Time", 0, 24, Config.ClockTime, function(v) Config.ClockTime = v ApplyClock() end, "ClockTime")
CreateSlider(Pages["World"], "Gravity", 50, 500, Config.Gravity, function(v) Config.Gravity = v ApplyGravity() end, "Gravity")

-- ═══════════════ VEHICLES ═══════════════
local VehicleESP = {}
local VehicleSeats = {}
local function GetVehicleModel(seat) return seat:FindFirstAncestorOfClass("Model") or seat:FindFirstAncestorOfClass("Folder") end
local function ModelAnchor(model)
    if model.PrimaryPart then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end
local function RegisterSeat(seat)
    if VehicleSeats[seat] then return end
    local model = GetVehicleModel(seat)
    if model then VehicleSeats[seat] = model end
end
for _, inst in ipairs(WS:GetDescendants()) do
    if inst:IsA("VehicleSeat") then RegisterSeat(inst) end
end
AddConn(WS.DescendantAdded:Connect(function(inst) if inst:IsA("VehicleSeat") then RegisterSeat(inst) end end))

local function CreateVehicleDraw(model)
    if VehicleESP[model] then return VehicleESP[model] end
    local ok, t = pcall(function() return {Box = Drawing.new("Square"), Name = Drawing.new("Text"), Dist = Drawing.new("Text")} end)
    if not ok or not t then return nil end
    t.Box.Thickness = 1
    t.Name.Size = 13; t.Name.Center = true; t.Name.Outline = true
    t.Dist.Size = 12; t.Dist.Center = true; t.Dist.Outline = true
    VehicleESP[model] = t
    return t
end

local function RenderVehicleESP()
    if not Config.V_ESP then
        for model, d in pairs(VehicleESP) do
            if d.Box then pcall(function() d.Box.Visible = false end) end
            if d.Name then pcall(function() d.Name.Visible = false end) end
            if d.Dist then pcall(function() d.Dist.Visible = false end) end
        end
        return
    end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position
    if not myPos then return end
    local seen = {}
    for _, model in pairs(VehicleSeats) do
        if model and model.Parent and not seen[model] then
            seen[model] = true
            local anchor = ModelAnchor(model)
            if anchor then
                local d = CreateVehicleDraw(model)
                if d then
                    local pos = anchor.Position
                    local d3 = (myPos - pos).Magnitude
                    if d3 > Config.V_ESP_MaxDist then
                        d.Box.Visible = false; d.Name.Visible = false; d.Dist.Visible = false
                    else
                        local sp, onScreen = Camera:WorldToViewportPoint(pos)
                        if not onScreen then d.Box.Visible = false; d.Name.Visible = false; d.Dist.Visible = false
                        else
                            local s = math.clamp(8000 / math.max(d3, 1), 24, 300)
                            d.Box.Visible = Config.V_ESP_Box
                            if d.Box.Visible then
                                d.Box.Size = Vector2.new(s, s)
                                d.Box.Position = Vector2.new(sp.X - s / 2, sp.Y - s / 2)
                                d.Box.Color = Config.ColorVehicle
                            end
                            d.Name.Visible = Config.V_ESP_Name
                            if d.Name.Visible then
                                d.Name.Text = model.Name
                                d.Name.Position = Vector2.new(sp.X, sp.Y - s / 2 - 18)
                                d.Name.Color = Config.ColorVehicle
                            end
                            d.Dist.Visible = Config.V_ESP_Dist
                            if d.Dist.Visible then
                                d.Dist.Text = tostring(math.floor(d3)) .. "m"
                                d.Dist.Position = Vector2.new(sp.X, sp.Y + s / 2 + 2)
                                d.Dist.Color = Config.ColorVehicle
                            end
                        end
                    end
                end
            end
        end
    end
end
RunService:BindToRenderStep("MeowVESP", Enum.RenderPriority.Camera.Value + 2, RenderVehicleESP)

CreateToggle(Pages["Vehicles"], "Vehicle ESP", Config.V_ESP, nil, "V_ESP")
CreateToggle(Pages["Vehicles"], " - Box", Config.V_ESP_Box, nil, "V_ESP_Box")
CreateToggle(Pages["Vehicles"], " - Name", Config.V_ESP_Name, nil, "V_ESP_Name")
CreateToggle(Pages["Vehicles"], " - Dist", Config.V_ESP_Dist, nil, "V_ESP_Dist")
CreateSlider(Pages["Vehicles"], "Veh Max Dist", 100, 10000, Config.V_ESP_MaxDist, nil, "V_ESP_MaxDist")

-- ═══════════════ UI — TELEPORT ═══════════════
CreateToggle(Pages["Teleport"], "Drop to ground", Config.TP_DropToGround, nil, "TP_DropToGround")
CreateSlider(Pages["Teleport"], "Safe drop", 1, 20, Config.TP_SafeDrop, nil, "TP_SafeDrop")
CreateButton(Pages["Teleport"], "TP Nearest Enemy", function()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local best, bestD = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and PassesTeamFilter(p) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (myHrp.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d best = hrp end
            end
        end
    end
    if best then SafeTeleport(best.Position + Vector3.new(0, 3, 0), "nearest enemy") end
end)

-- ═══════════════ UI — MISC ═══════════════
CreateToggle(Pages["Misc"], "Anti-AFK", Config.AntiAFK, function(v) Config.AntiAFK = v end, "AntiAFK")
CreateSlider(Pages["Misc"], "FPS Cap", 30, 1000, Config.FPSCap, function(v) pcall(function() setfpscap(v) end) end, "FPSCap")
CreateButton(Pages["Misc"], "Rejoin Server", function()
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
end)

-- ═══════════════ UI — CONFIG ═══════════════
CreateButton(Pages["Config"], "Save Config", function() SaveConfig() end)
CreateButton(Pages["Config"], "Load Config", function() LoadConfig() end)
CreateButton(Pages["Config"], "Quick: ESP On/Off", function() Config.ESP = not Config.ESP end)
CreateButton(Pages["Config"], "Quick: Silent On/Off", function() Config.SilentAim = not Config.SilentAim end)
CreateButton(Pages["Config"], "Quick: Noclip On/Off", function()
    Config.Noclip = not Config.Noclip
    if Config.Noclip then Noclip.Start() else Noclip.Stop() end
end)
CreateButton(Pages["Config"], "Quick: Fly On/Off", function()
    Config.FlyOn = not Config.FlyOn
    if Config.FlyOn then Fly.Start() else Fly.Stop() end
end)
CreateButton(Pages["Config"], "FULL UNLOAD", function() FullUnload() end, Color3.fromRGB(160, 40, 60))

-- ═══════════════ RESIZE LISTENER ═══════════════
local function ApplyAdaptive()
    RecalcSize()
    Main.Size = UDim2.new(0, winW, 0, winH)
    MainScale.Scale = scaleFactor
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyAdaptive)

-- ═══════════════ EXTENSION-01: UI EXTENSIONS ═══════════════

-- Combat tab
CreateToggle(Pages["Combat"], "Trigger Bot v2", false, function(v) TriggerBot.Toggle(v) end)
CreateSlider(Pages["Combat"], "Trigger Threshold", 5, 100, 30, function(v) TriggerBot.SetThreshold(v) end)
CreateSlider(Pages["Combat"], "Humanizer Jitter x100", 1, 100, 10, function(v) Humanizer.SetJitter(v / 100) end)
CreateToggle(Pages["Combat"], "Humanizer Active", true, function(v) Humanizer.active = v end)
CreateCycle(Pages["Combat"], "FOV Shape", {"circle", "square", "triangle"}, "circle", function(v) end)

-- Visuals tab
CreateToggle(Pages["Visuals"], " - Tracers", false, function(v)
    Config.ESP_Tracers = v
end)
CreateToggle(Pages["Visuals"], " - Facing Arrows", false, function(v)
    Config.ESP_Facing = v
end)

-- Misc tab: waypoints
CreateButton(Pages["Misc"], "WP: Save Current Pos", function()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local name = "wp_" .. tostring(Waypoints.Count() + 1)
        Waypoints.Add(name, hrp.Position)
        Waypoints.SaveToDisk()
        Logger.Write("WP", "saved " .. name)
    end
end)
CreateButton(Pages["Misc"], "WP: List", function()
    for name, w in pairs(Waypoints.All()) do
        Logger.Write("WP", string.format("%s @ (%.0f, %.0f, %.0f)", name, w.x, w.y, w.z))
    end
end)
CreateButton(Pages["Misc"], "WP: Save to Disk", function()
    if Waypoints.SaveToDisk() then Logger.Write("WP", "saved to disk") end
end)
CreateButton(Pages["Misc"], "WP: Clear All", function()
    Waypoints.list = {}
    Waypoints.SaveToDisk()
    Logger.Write("WP", "cleared")
end)

-- Misc tab: scan
CreateButton(Pages["Misc"], "Scan: find airdrops", function()
    local found = WorldScan.FindByKeyword("airdrop")
    Logger.Write("SCAN", "airdrops: " .. tostring(#found))
    for _, item in ipairs(found) do
        Logger.Write("SCAN", item.name .. " @ " .. tostring(item.pos))
    end
end)
CreateButton(Pages["Misc"], "Scan: find crates", function()
    local found = WorldScan.FindByKeyword("crate")
    Logger.Write("SCAN", "crates: " .. tostring(#found))
end)
CreateButton(Pages["Misc"], "TP to nearest airdrop", function()
    local best = WorldScan.Nearest("airdrop")
    if best then SafeTeleport(best.pos, "airdrop") end
end)

-- Misc tab: spectate
CreateButton(Pages["Misc"], "Spectate: Nearest Enemy", function()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local best, bestD = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and PassesTeamFilter(p) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (myHrp.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d best = p end
            end
        end
    end
    if best then Spectate.Start(best) end
end)
CreateButton(Pages["Misc"], "Spectate: Stop", function()
    Spectate.Stop()
end)

-- Misc tab: profiler
CreateButton(Pages["Misc"], "Profiler: report", function()
    local report = Profiler.Report()
    for k, v in pairs(report) do
        Logger.Write("PROF", k .. " = " .. string.format("%.3f", v))
    end
end)

-- Misc tab: aim stats
CreateButton(Pages["Misc"], "Aim: stats", function()
    local r = AimStats.Report()
    Logger.Write("AIM", string.format("hits=%d misses=%d acc=%.0f%%", r.hits, r.misses, r.accuracy * 100))
end)
CreateButton(Pages["Misc"], "Aim: reset stats", function()
    AimStats.Reset()
    Logger.Write("AIM", "stats reset")
end)

-- Config tab: quick actions
CreateButton(Pages["Config"], "Q: ESP", function() QuickActions.ToggleESP() end)
CreateButton(Pages["Config"], "Q: Silent", function() QuickActions.ToggleSilent() end)
CreateButton(Pages["Config"], "Q: Noclip", function() QuickActions.ToggleNoclip() end)
CreateButton(Pages["Config"], "Q: Fly", function() QuickActions.ToggleFly() end)
CreateButton(Pages["Config"], "Q: Fullbright", function() QuickActions.ToggleFullbright() end)

-- ═══════════════ EXTENSION-01: EXPORTS ═══════════════
MM.Register("Hitscan", Hitscan)
MM.Register("Trajectory", Trajectory)
MM.Register("Smoothing", Smoothing)
MM.Register("AimStats", AimStats)
MM.Register("Humanizer", Humanizer)
MM.Register("TriggerBot", TriggerBot)
MM.Register("FOVShapes", FOVShapes)
MM.Register("Targeting", Targeting)
MM.Register("Tracers", Tracers)
MM.Register("NametagExtras", NametagExtras)
MM.Register("TeamDetect", TeamDetect)
MM.Register("OffscreenArrows", OffscreenArrows)
MM.Register("FacingArrows", FacingArrows)
MM.Register("Waypoints", Waypoints)
MM.Register("WorldScan", WorldScan)
MM.Register("Spectate", Spectate)
MM.Register("Profiler", Profiler)
MM.Register("Logger", Logger)
MM.Register("QuickActions", QuickActions)

-- ═══════════════ EXTENSION-02: UI — PRESETS ═══════════════
local presetNameBox
do
    local f, box = CreateTextbox(Pages["Config"], "Preset Name", "my preset", "", function(v) end)
    presetNameBox = box
end

CreateButton(Pages["Config"], "Preset: Save Current", function()
    local name = presetNameBox.Text
    if name == "" then
        name = "preset_" .. tostring(Presets.Count() + 1)
    end
    Presets.Save(name)
    Presets.SaveToDisk()
    Notifications.Push("Preset", "saved: " .. name, THEME.Accent)
    Logger.Write("PRESET", "saved " .. name)
end)

CreateButton(Pages["Config"], "Preset: Export All", function()
    if Presets.SaveToDisk() then
        Notifications.Push("Presets", tostring(Presets.Count()) .. " written to disk", THEME.Success)
    end
end)

-- Dropdown загрузки пресета
local function refreshPresetDropdown()
    local names = Presets.Names()
    if #names == 0 then names = {"(empty)"} end
    local c, getV = CreateDropdown(Pages["Config"], "Load Preset", names, names[1], function(v)
        if v == "(empty)" then return end
        if Presets.Load(v) then
            Notifications.Push("Preset", "loaded: " .. v, THEME.Success)
            Logger.Write("PRESET", "loaded " .. v)
        end
    end)
    return c
end
refreshPresetDropdown()

CreateButton(Pages["Config"], "Preset: Delete All", function()
    Presets.list = {}
    Presets.SaveToDisk()
    Notifications.Push("Presets", "cleared all", THEME.Warn)
end)

-- ═══════════════ EXTENSION-02: UI — COLORPICKER ═══════════════
CreateDropdown(Pages["Config"], "Theme Color", ColorPresets.List(), "cyan", function(v)
    if ColorPresets.Apply(v) then
        Notifications.Push("Theme", "color: " .. v, ColorPresets[v])
        Logger.Write("THEME", "set " .. v)
    end
end)

CreateColorPicker(Pages["Config"], "Custom Accent", THEME.Accent, function(c)
    THEME.Accent = c
    Config.ColorNeon = c
    Notifications.Push("Theme", "custom accent applied", c)
end)

-- ═══════════════ EXTENSION-02: UI — CONSOLE ═══════════════
CreateButton(Pages["Misc"], "Open Console", function()
    ConsoleUI.Open()
end)

CreateButton(Pages["Misc"], "Console: Clear Log", function()
    Logger.Clear()
    Notifications.Push("Log", "cleared", THEME.Success)
end)

CreateButton(Pages["Misc"], "Notification Test", function()
    Notifications.Push("Test", "all systems online", THEME.Accent)
end)

-- ═══════════════ EXTENSION-02: EXPORTS ═══════════════
MM.Register("Presets", Presets)
MM.Register("ColorPresets", ColorPresets)
MM.Register("Notifications", Notifications)
MM.Register("ConsoleUI", ConsoleUI)
MM.Register("CreateTextbox", CreateTextbox)
MM.Register("CreateDropdown", CreateDropdown)
MM.Register("CreateColorPicker", CreateColorPicker)

-- ═══════════════ EXTENSION-03: UI — AUTOCLICKER ═══════════════
CreateToggle(Pages["Misc"], "AutoClicker", false, function(v)
    if v then AutoClick.Start() else AutoClick.Stop() end
end)
CreateSlider(Pages["Misc"], "AC Delay ms", 10, 500, 50, function(v) AutoClick.SetDelay(v / 1000) end)
CreateCycle(Pages["Misc"], "AC Button", {"LMB", "RMB"}, "LMB", function(v)
    AutoClick.SetButton(v == "LMB" and 1 or 2)
end)

-- ═══════════════ EXTENSION-03: UI — CHAT SPAM ═══════════════
local chatMsgBox
do
    local _, box = CreateTextbox(Pages["Misc"], "Chat Message", "meow", "meow", function(v) ChatSpam.SetMessage(v) end)
    chatMsgBox = box
end
CreateToggle(Pages["Misc"], "Chat Spam", false, function(v)
    ChatSpam.SetMessage(chatMsgBox.Text)
    if v then ChatSpam.Start() else ChatSpam.Stop() end
end)
CreateSlider(Pages["Misc"], "Chat Delay 0.1s", 5, 100, 10, function(v) ChatSpam.SetDelay(v / 10) end)

-- ═══════════════ EXTENSION-03: UI — PING SPOOF ═══════════════
CreateToggle(Pages["Misc"], "Ping Spoof", false, function(v)
    if v then PingSpoof.Enable() else PingSpoof.Disable() end
end)
CreateSlider(Pages["Misc"], "Fake Latency ms", 10, 500, 50, function(v) PingSpoof.SetLatency(v / 1000) end)

-- ═══════════════ EXTENSION-03: UI — ANTI-AFK V2 ═══════════════
CreateButton(Pages["Misc"], "AntiAFK v2: Toggle", function()
    local on = AntiAFK.Toggle()
    Notifications.Push("AntiAFK", on and "on" or "off", on and THEME.Success or THEME.Warn)
end)

-- ═══════════════ EXTENSION-03: UI — WORLD EXTENDED ═══════════════
CreateButton(Pages["World"], "Barriers: Off", function()
    WorldExt.DisableBarriers()
    Notifications.Push("World", "barriers disabled", THEME.Success)
end)
CreateButton(Pages["World"], "Barriers: Restore", function()
    WorldExt.RestoreBarriers()
    Notifications.Push("World", "barriers restored", THEME.Warn)
end)
CreateButton(Pages["World"], "Shadows: Off", function()
    WorldExt.DisableShadows()
    Notifications.Push("World", "shadows off", THEME.Success)
end)
CreateButton(Pages["World"], "Shadows: On", function()
    WorldExt.EnableShadows()
    Notifications.Push("World", "shadows on", THEME.Warn)
end)
CreateSlider(Pages["World"], "Exposure x100", 0, 100, 0, function(v) WorldExt.SetExposure(v / 100 - 0.5) end)
CreateSlider(Pages["World"], "Specular x100", 0, 100, 50, function(v) WorldExt.SetSpecular(v / 100) end)

-- ═══════════════ EXTENSION-03: UI — FULLBRIGHT EXT ═══════════════
CreateButton(Pages["World"], "Fullbright EXT: Toggle", function()
    local on = FullbrightExt.Toggle()
    Notifications.Push("Fullbright", on and "on" or "off", on and THEME.Success or THEME.Warn)
end)

-- ═══════════════ EXTENSION-03: UI — CAMERA ═══════════════
CreateSlider(Pages["World"], "Camera FOV", 50, 120, 70, function(v) CameraExt.SetFOV(v) end)
CreateButton(Pages["World"], "Camera: Reset FOV", function()
    CameraExt.ResetFOV()
    Notifications.Push("Camera", "fov reset", THEME.Success)
end)
CreateButton(Pages["World"], "Camera: Spectate Nearest", function()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local best, bestD = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and PassesTeamFilter(p) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (myHrp.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d best = p end
            end
        end
    end
    if best then
        CameraExt.ZoomTo(best)
        Notifications.Push("Camera", "spectating " .. best.Name, THEME.Accent)
    end
end)
CreateButton(Pages["World"], "Camera: Restore", function()
    CameraExt.RestoreCamera()
    Notifications.Push("Camera", "restored", THEME.Success)
end)

-- ═══════════════ EXTENSION-03: UI — FPS/PING ═══════════════
CreateSlider(Pages["Misc"], "FPS Cap v2", 30, 1000, 240, function(v) FPSExt.SetCap(v) end)
CreateToggle(Pages["Misc"], "Show FPS", false, function(v)
    if v then FPSExt.ShowFPS() else FPSExt.HideFPS() end
end)
CreateToggle(Pages["Misc"], "Show Ping", false, function(v)
    if v then PingDisplay.Show() else PingDisplay.Hide() end
end)

-- ═══════════════ EXTENSION-03: EXPORTS ═══════════════
MM.Register("AutoClick", AutoClick)
MM.Register("ChatSpam", ChatSpam)
MM.Register("PingSpoof", PingSpoof)
MM.Register("AntiAFK", AntiAFK)
MM.Register("WorldExt", WorldExt)
MM.Register("CameraExt", CameraExt)
MM.Register("FullbrightExt", FullbrightExt)
MM.Register("FPSExt", FPSExt)
MM.Register("PingDisplay", PingDisplay)

-- ═══════════════ EXTENSION-04: UI — VEHICLE EXTRAS ═══════════════

-- Finder
CreateButton(Pages["Vehicles"], "Finder: Nearest Vehicle", function()
    local model, dist = VehicleFinder.NearestToPlayer()
    if model then
        Notifications.Push("Vehicle", "nearest: " .. model.Name .. " (" .. math.floor(dist) .. "m)", THEME.Accent)
    else
        Notifications.Push("Vehicle", "no vehicles found", THEME.Warn)
    end
end)
CreateButton(Pages["Vehicles"], "Finder: Count", function()
    Notifications.Push("Vehicle", tostring(VehicleFinder.Count()) .. " tracked", THEME.Accent)
end)
CreateButton(Pages["Vehicles"], "Finder: Empty Seat", function()
    local model, seat = VehicleFinder.FindEmpty()
    if model then
        Notifications.Push("Vehicle", "empty: " .. model.Name, THEME.Success)
        SeatStealer.Steal(seat)
    else
        Notifications.Push("Vehicle", "no empty vehicles", THEME.Warn)
    end
end)

-- Tracker
CreateButton(Pages["Vehicles"], "Tracker: Lock Nearest", function()
    local model = VehicleFinder.NearestToPlayer()
    if model then
        VehicleTracker.Track(model)
        Notifications.Push("Tracker", "tracking " .. model.Name, THEME.Accent)
    end
end)
CreateButton(Pages["Vehicles"], "Tracker: Stop", function()
    VehicleTracker.Stop()
    Notifications.Push("Tracker", "stopped", THEME.Warn)
end)

-- Lock
CreateButton(Pages["Vehicles"], "Lock: Nearest", function()
    local model = VehicleFinder.NearestToPlayer()
    if model then
        VehicleLock.Lock(model)
        Notifications.Push("Lock", "locked to " .. model.Name, THEME.Accent)
    end
end)
CreateButton(Pages["Vehicles"], "Lock: Stop", function()
    VehicleLock.Stop()
    Notifications.Push("Lock", "released", THEME.Warn)
end)

-- Seat
CreateButton(Pages["Vehicles"], "Seat: Steal Nearest", function()
    local seat = SeatStealer.StealNearest()
    if seat then
        Notifications.Push("Seat", "stolen", THEME.Success)
    else
        Notifications.Push("Seat", "no seat found", THEME.Warn)
    end
end)

-- Boost
CreateSlider(Pages["Vehicles"], "Boost x10", 10, 50, 15, function(v)
    VehicleBoost.multiplier = v / 10
end)
CreateToggle(Pages["Vehicles"], "Vehicle Boost", false, function(v)
    if v then VehicleBoost.Start(VehicleBoost.multiplier or 1.5) else VehicleBoost.Stop() end
end)

-- Fly
CreateToggle(Pages["Vehicles"], "Vehicle Fly", false, function(v)
    if v then VehicleFly.Start() else VehicleFly.Stop() end
end)
CreateSlider(Pages["Vehicles"], "Veh Fly Speed", 10, 500, 100, function(v)
    VehicleFly.speed = v
end)

-- Live list
CreateButton(Pages["Vehicles"], "Refresh Vehicle List", function()
    VehicleListUI.Refresh(Pages["Vehicles"])
    Notifications.Push("Vehicle", "list refreshed", THEME.Accent)
end)

-- Auto-refresh list
VehicleListUI.StartAutoRefresh(Pages["Vehicles"], 4)

-- ═══════════════ EXTENSION-04: EXPORTS ═══════════════
MM.Register("VehicleRegistry", VehicleRegistry)
MM.Register("VehicleFinder", VehicleFinder)
MM.Register("VehicleTracker", VehicleTracker)
MM.Register("VehicleLock", VehicleLock)
MM.Register("SeatStealer", SeatStealer)
MM.Register("VehicleBoost", VehicleBoost)
MM.Register("VehicleFly", VehicleFly)
MM.Register("VehicleListUI", VehicleListUI)

-- ═══════════════ EXTENSION-05: UI — PLAYER TOOLS ═══════════════

-- селектор цели (dropdown по никам игроков)
local function currentPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(list, p.Name) end
    end
    if #list == 0 then list = {"(none)"} end
    return list
end

local selectedPlayerName = nil
do
    local _, getV = CreateDropdown(Pages["Players"], "Target Player", currentPlayerList(), "(none)", function(v)
        selectedPlayerName = v
        Notifications.Push("Player", "selected: " .. v, THEME.Accent)
    end)
end

local function resolvePlayer()
    if not selectedPlayerName then return nil end
    return Players:FindFirstChild(selectedPlayerName)
end

-- Profile
CreateButton(Pages["Players"], "Profile: Show Summary", function()
    local p = resolvePlayer()
    if not p then Notifications.Push("Profile", "no target", THEME.Warn) return end
    local summary = PlayerProfile.Summary(p)
    Logger.Write("PROFILE", PlayerProfile.Format(summary))
    Notifications.Push("Profile", PlayerProfile.Format(summary), THEME.Accent)
end)

-- View
CreateButton(Pages["Players"], "View: Zoom To Target", function()
    local p = resolvePlayer()
    if not p then Notifications.Push("View", "no target", THEME.Warn) return end
    if PlayerView.Watch(p, 10) then
        Notifications.Push("View", "zoomed to " .. p.Name, THEME.Accent)
    end
end)
CreateButton(Pages["Players"], "View: Follow Target", function()
    local p = resolvePlayer()
    if not p then Notifications.Push("View", "no target", THEME.Warn) return end
    if PlayerView.Follow(p) then
        SpectateExt.AddHistory(p)
        Notifications.Push("View", "following " .. p.Name, THEME.Accent)
    end
end)
CreateButton(Pages["Players"], "View: Stop", function()
    PlayerView.Stop()
    Notifications.Push("View", "stopped", THEME.Warn)
end)

-- Spectate history
CreateButton(Pages["Players"], "Spectate: Next", function()
    local p = SpectateExt.Next()
    if p then Notifications.Push("Spectate", "-> " .. p.Name, THEME.Accent) end
end)
CreateButton(Pages["Players"], "Spectate: Prev", function()
    local p = SpectateExt.Prev()
    if p then Notifications.Push("Spectate", "<- " .. p.Name, THEME.Accent) end
end)

-- Hide
CreateButton(Pages["Players"], "Hide: Toggle Target", function()
    local p = resolvePlayer()
    if not p then Notifications.Push("Hide", "no target", THEME.Warn) return end
    local hidden = PlayerHide.Toggle(p)
    Notifications.Push("Hide", (hidden and "hidden " or "shown ") .. p.Name, hidden and THEME.Success or THEME.Warn)
end)

-- Force sit
CreateButton(Pages["Players"], "Force: Sit Target", function()
    local p = resolvePlayer()
    if not p then return end
    if ForceSit.ForceSit(p) then
        Notifications.Push("Force", "sitting " .. p.Name, THEME.Success)
    end
end)
CreateButton(Pages["Players"], "Force: Unsit Target", function()
    local p = resolvePlayer()
    if not p then return end
    if ForceSit.Unsit(p) then
        Notifications.Push("Force", "unsit " .. p.Name, THEME.Accent)
    end
end)
CreateButton(Pages["Players"], "Force: Freeze Target", function()
    local p = resolvePlayer()
    if not p then return end
    if ForceSit.Freeze(p) then
        Notifications.Push("Force", "frozen " .. p.Name, THEME.Success)
    end
end)
CreateButton(Pages["Players"], "Force: Unfreeze Target", function()
    local p = resolvePlayer()
    if not p then return end
    if ForceSit.Unfreeze(p) then
        Notifications.Push("Force", "unfrozen " .. p.Name, THEME.Accent)
    end
end)

-- Cage
CreateButton(Pages["Players"], "Cage: Target", function()
    local p = resolvePlayer()
    if not p then return end
    if PlayerCage.Create(p) then
        Notifications.Push("Cage", "caged " .. p.Name, THEME.Success)
    end
end)
CreateButton(Pages["Players"], "Cage: Remove All", function()
    PlayerCage.RemoveAll()
    Notifications.Push("Cage", "all removed", THEME.Warn)
end)

-- Orbit
CreateButton(Pages["Players"], "Orbit: Target", function()
    local p = resolvePlayer()
    if not p then return end
    PlayerOrbit.Start(p)
    Notifications.Push("Orbit", "orbiting " .. p.Name, THEME.Accent)
end)
CreateButton(Pages["Players"], "Orbit: Stop", function()
    PlayerOrbit.Stop()
    Notifications.Push("Orbit", "stopped", THEME.Warn)
end)
CreateSlider(Pages["Players"], "Orbit Radius", 3, 30, 10, function(v) PlayerOrbit.radius = v end)
CreateSlider(Pages["Players"], "Orbit Speed x10", 5, 50, 15, function(v) PlayerOrbit.speed = v / 10 end)

-- Follow
CreateButton(Pages["Players"], "Follow: Target", function()
    local p = resolvePlayer()
    if not p then return end
    PlayerFollow.Start(p)
    Notifications.Push("Follow", "following " .. p.Name, THEME.Accent)
end)
CreateButton(Pages["Players"], "Follow: Stop", function()
    PlayerFollow.Stop()
    Notifications.Push("Follow", "stopped", THEME.Warn)
end)
CreateSlider(Pages["Players"], "Follow Dist", 5, 50, 15, function(v) PlayerFollow.distance = v end)

-- ═══════════════ EXTENSION-05: EXPORTS ═══════════════
MM.Register("PlayerProfile", PlayerProfile)
MM.Register("PlayerView", PlayerView)
MM.Register("PlayerHide", PlayerHide)
MM.Register("ForceSit", ForceSit)
MM.Register("PlayerCage", PlayerCage)
MM.Register("PlayerOrbit", PlayerOrbit)
MM.Register("SpectateExt", SpectateExt)
MM.Register("PlayerFollow", PlayerFollow)

-- ═══════════════ EXTENSION-06: UI — EXPLOIT ═══════════════

-- Anti-detect
CreateToggle(Pages["Misc"], "Anti-Detect Monitor", false, function(v)
    if v then AntiDetect.Start() else AntiDetect.Stop() end
end)
CreateButton(Pages["Misc"], "Anti-Detect: Report", function()
    local r = AntiDetect.Report()
    Logger.Write("ANTIDET", string.format("active=%s flags=%d", tostring(r.active), r.flags))
    Notifications.Push("AntiDetect", "flags: " .. tostring(r.flags), r.flags > 0 and THEME.Warn or THEME.Success)
end)

-- Crash guard
CreateButton(Pages["Misc"], "Crash Guard: Report", function()
    local r = CrashGuard.Report()
    Logger.Write("CRASH", string.format("errors=%d last=%s", r.errors, tostring(r.last)))
    Notifications.Push("CrashGuard", "errors: " .. tostring(r.errors), THEME.Accent)
end)
CreateButton(Pages["Misc"], "Crash Guard: Reset", function()
    CrashGuard.Reset()
    Notifications.Push("CrashGuard", "reset", THEME.Success)
end)

-- Remote spy
CreateToggle(Pages["Misc"], "Remote Spy", false, function(v)
    if v then RemoteSpy.Start() else RemoteSpy.Stop() end
end)
local remoteSpyFilterBox
do
    local _, box = CreateTextbox(Pages["Misc"], "Spy Filter", "keyword", "", function(v)
        RemoteSpy.SetFilter(v)
    end)
    remoteSpyFilterBox = box
end
CreateButton(Pages["Misc"], "Spy: Dump Calls", function()
    RemoteSpy.Dump()
    Notifications.Push("Spy", tostring(#RemoteSpy.calls) .. " calls logged", THEME.Accent)
end)
CreateButton(Pages["Misc"], "Spy: Clear", function()
    RemoteSpy.Clear()
    Notifications.Push("Spy", "cleared", THEME.Warn)
end)

-- Teleport extended
CreateButton(Pages["Teleport"], "TP: Forward 50", function()
    TPExt.Forward(50)
    Notifications.Push("TP", "forward", THEME.Accent)
end)
CreateButton(Pages["Teleport"], "TP: Up 100", function()
    TPExt.Up(100)
    Notifications.Push("TP", "up", THEME.Accent)
end)
CreateButton(Pages["Teleport"], "TP: Back (undo)", function()
    if TPExt.Back() then
        Notifications.Push("TP", "back", THEME.Success)
    else
        Notifications.Push("TP", "no history", THEME.Warn)
    end
end)

-- TP to target from Players tab
CreateButton(Pages["Teleport"], "TP: Behind Target", function()
    local p = selectedPlayerName and Players:FindFirstChild(selectedPlayerName)
    if not p then Notifications.Push("TP", "no target", THEME.Warn) return end
    if TPExt.Behind(p) then
        Notifications.Push("TP", "behind " .. p.Name, THEME.Success)
    end
end)
CreateButton(Pages["Teleport"], "TP: In Front of Target", function()
    local p = selectedPlayerName and Players:FindFirstChild(selectedPlayerName)
    if not p then Notifications.Push("TP", "no target", THEME.Warn) return end
    if TPExt.InFront(p) then
        Notifications.Push("TP", "in front " .. p.Name, THEME.Success)
    end
end)

-- TP by coordinates
local coordsXBox, coordsYBox, coordsZBox
do
    local _, box = CreateTextbox(Pages["Teleport"], "X", "0", "0", function(v) coordsXBox = v end)
    coordsXBox = box
end
do
    local _, box = CreateTextbox(Pages["Teleport"], "Y", "0", "0", function(v) coordsYBox = v end)
    coordsYBox = box
end
do
    local _, box = CreateTextbox(Pages["Teleport"], "Z", "0", "0", function(v) coordsZBox = v end)
    coordsZBox = box
end
CreateButton(Pages["Teleport"], "TP: To Coordinates", function()
    local x = tonumber(coordsXBox.Text) or 0
    local y = tonumber(coordsYBox.Text) or 0
    local z = tonumber(coordsZBox.Text) or 0
    if TPExt.ToCoords(x, y, z) then
        Notifications.Push("TP", string.format("to (%.0f, %.0f, %.0f)", x, y, z), THEME.Success)
    end
end)
CreateButton(Pages["Teleport"], "TP: Current Coords -> Box", function()
    local coords = TPExt.GetCurrentCoords()
    if coords then
        coordsXBox.Text = tostring(coords.x)
        coordsYBox.Text = tostring(coords.y)
        coordsZBox.Text = tostring(coords.z)
        Notifications.Push("TP", string.format("saved (%.0f, %.0f, %.0f)", coords.x, coords.y, coords.z), THEME.Accent)
    end
end)

-- Virtual pos
CreateToggle(Pages["Movement"], "Virtual Position", false, function(v)
    if v then VirtualPos.Start(Vector3.new(0, 5, 0)) else VirtualPos.Stop() end
end)
CreateSlider(Pages["Movement"], "VPos Height", 0, 50, 5, function(v)
    if VirtualPos.active then VirtualPos.SetOffset(Vector3.new(0, v, 0)) end
end)

-- Bypass toggle
CreateToggle(Pages["Config"], "Bypass Jitter", true, function(v) BypassExt.active = v end)
CreateSlider(Pages["Config"], "Bypass Jitter x100", 1, 100, 10, function(v) BypassExt.SetJitter(v / 100) end)

-- ═══════════════ EXTENSION-06: EXPORTS ═══════════════
MM.Register("BypassExt", BypassExt)
MM.Register("VirtualPos", VirtualPos)
MM.Register("TPExt", TPExt)
MM.Register("AntiDetect", AntiDetect)
MM.Register("RemoteSpy", RemoteSpy)
MM.Register("PacketSender", PacketSender)
MM.Register("CrashGuard", CrashGuard)
MM.Register("QueueManager", QueueManager)
MM.Register("SelfSnapshot", SelfSnapshot)

-- ═══════════════ EXTENSION-07: UI — LIGHTING/FX ═══════════════

-- Snapshot
CreateButton(Pages["World"], "Lighting: Snapshot State", function()
    LightingExt.Snapshot()
    Notifications.Push("Lighting", "snapshot saved", THEME.Success)
end)
CreateButton(Pages["World"], "Lighting: Restore", function()
    LightingExt.Restore()
    Notifications.Push("Lighting", "restored", THEME.Accent)
end)

-- Bloom
CreateSlider(Pages["World"], "Bloom Intensity x10", 0, 30, 10, function(v)
    if v > 0 then LightingExt.SetBloom(v / 10, 24) else LightingExt.ClearBloom() end
end)
CreateButton(Pages["World"], "Bloom: Clear", function()
    LightingExt.ClearBloom()
    Notifications.Push("Lighting", "bloom cleared", THEME.Warn)
end)

-- Color correction
CreateSlider(Pages["World"], "CC Brightness x100", -50, 50, 0, function(v)
    if not LightingExt.colorCorr then
        LightingExt.SetColorCorrection(v / 100, 0, 0)
    else
        LightingExt.colorCorr.Brightness = v / 100
    end
end)
CreateSlider(Pages["World"], "CC Contrast x100", -50, 50, 0, function(v)
    if not LightingExt.colorCorr then
        LightingExt.SetColorCorrection(0, v / 100, 0)
    else
        LightingExt.colorCorr.Contrast = v / 100
    end
end)
CreateSlider(Pages["World"], "CC Saturation x100", -50, 100, 0, function(v)
    if not LightingExt.colorCorr then
        LightingExt.SetColorCorrection(0, 0, v / 100)
    else
        LightingExt.colorCorr.Saturation = v / 100
    end
end)
CreateButton(Pages["World"], "CC: Clear", function()
    LightingExt.ClearColorCorrection()
    Notifications.Push("Lighting", "cc cleared", THEME.Warn)
end)

-- Blur
CreateSlider(Pages["World"], "Blur Size", 0, 30, 0, function(v)
    if v > 0 then LightingExt.SetBlur(v) else LightingExt.ClearBlur() end
end)
CreateButton(Pages["World"], "Blur: Clear", function()
    LightingExt.ClearBlur()
    Notifications.Push("Lighting", "blur cleared", THEME.Warn)
end)

-- Sun rays
CreateSlider(Pages["World"], "SunRays x100", 0, 100, 0, function(v)
    if v > 0 then LightingExt.SetSunRays(v / 100, 1) else LightingExt.ClearSunRays() end
end)
CreateButton(Pages["World"], "SunRays: Clear", function()
    LightingExt.ClearSunRays()
    Notifications.Push("Lighting", "sunrays cleared", THEME.Warn)
end)

-- Atmosphere
CreateSlider(Pages["World"], "Atmo Density x100", 0, 100, 30, function(v)
    LightingExt.SetAtmosphere(v / 100, 0.25)
end)
CreateButton(Pages["World"], "Atmo: Clear", function()
    LightingExt.ClearAtmosphere()
    Notifications.Push("Lighting", "atmo cleared", THEME.Warn)
end)

-- Clear all
CreateButton(Pages["World"], "Lighting: Clear ALL FX", function()
    LightingExt.ClearAll()
    Notifications.Push("Lighting", "all effects cleared", THEME.Success)
end)

-- Sky
CreateButton(Pages["World"], "Sky: Night", function()
    SkyControl.SetPreset("night")
    Notifications.Push("Sky", "night", THEME.Accent)
end)
CreateButton(Pages["World"], "Sky: Sunset", function()
    SkyControl.SetPreset("sunset")
    Notifications.Push("Sky", "sunset", THEME.Accent)
end)
CreateButton(Pages["World"], "Sky: Space", function()
    SkyControl.SetPreset("space")
    Notifications.Push("Sky", "space", THEME.Accent)
end)
CreateButton(Pages["World"], "Sky: Pink", function()
    SkyControl.SetPreset("pink")
    Notifications.Push("Sky", "pink", THEME.Accent)
end)
CreateButton(Pages["World"], "Sky: Restore", function()
    SkyControl.Restore()
    Notifications.Push("Sky", "restored", THEME.Accent)
end)

-- Screen FX
CreateButton(Pages["World"], "FX: Red Tint", function()
    ScreenFX.AddColorTint(Color3.fromRGB(255, 30, 60), 0.75)
    Notifications.Push("FX", "red tint", THEME.Accent)
end)
CreateButton(Pages["World"], "FX: Green Tint", function()
    ScreenFX.AddColorTint(Color3.fromRGB(0, 200, 100), 0.75)
    Notifications.Push("FX", "green tint", THEME.Accent)
end)
CreateButton(Pages["World"], "FX: Scanlines", function()
    ScreenFX.AddScanlines()
    Notifications.Push("FX", "scanlines", THEME.Accent)
end)
CreateButton(Pages["World"], "FX: Clear All", function()
    ScreenFX.Clear()
    Notifications.Push("FX", "cleared", THEME.Warn)
end)

-- Particles
CreateButton(Pages["World"], "FX: Snow Particles", function()
    if Particles.CreateSnow() then
        Notifications.Push("FX", "snow on", THEME.Accent)
    end
end)
CreateButton(Pages["World"], "FX: Clear Particles", function()
    Particles.ClearAll()
    Notifications.Push("FX", "particles cleared", THEME.Warn)
end)

-- Time scale
CreateButton(Pages["World"], "Time: Slowmo 0.3x", function()
    TimeScale.Slowmo()
    Notifications.Push("Time", "slowmo", THEME.Accent)
end)
CreateButton(Pages["World"], "Time: Fastmo 2x", function()
    TimeScale.Fastmo()
    Notifications.Push("Time", "fastmo", THEME.Accent)
end)
CreateButton(Pages["World"], "Time: Reset", function()
    TimeScale.Reset()
    Notifications.Push("Time", "normal", THEME.Success)
end)

-- Zoom
CreateButton(Pages["World"], "Zoom: In", function()
    ZoomController.ZoomIn(30)
    Notifications.Push("Zoom", "in", THEME.Accent)
end)
CreateButton(Pages["World"], "Zoom: Out", function()
    ZoomController.ZoomOut(30)
    Notifications.Push("Zoom", "out", THEME.Accent)
end)
CreateButton(Pages["World"], "Zoom: Reset", function()
    ZoomController.Reset()
    Notifications.Push("Zoom", "reset", THEME.Success)
end)

-- ESP Style presets
CreateDropdown(Pages["Visuals"], "ESP Style", ESPStyles.List(), "default", function(v)
    if ESPStyles.Apply(v) then
        Notifications.Push("ESP", "style: " .. v, THEME.Accent)
    end
end)

-- ═══════════════ EXTENSION-07: EXPORTS ═══════════════
MM.Register("LightingExt", LightingExt)
MM.Register("SkyControl", SkyControl)
MM.Register("ScreenFX", ScreenFX)
MM.Register("ESPStyles", ESPStyles)
MM.Register("Particles", Particles)
MM.Register("TimeScale", TimeScale)
MM.Register("ZoomController", ZoomController)

-- ═══════════════ EXTENSION-08: UI — FINAL POLISH ═══════════════

MM._startTime = tick()

-- Config tab — help / about / quick / update / keybinds
CreateButton(Pages["Config"], "Help Screen", function()
    HelpScreen.Open()
end)
CreateButton(Pages["Config"], "About", function()
    AboutScreen.Open()
end)
CreateButton(Pages["Config"], "Show Quick Access", function()
    QuickAccess.Show()
    Notifications.Push("Quick", "shown", THEME.Success)
end)
CreateButton(Pages["Config"], "Hide Quick Access", function()
    QuickAccess.Hide()
    Notifications.Push("Quick", "hidden", THEME.Warn)
end)
CreateButton(Pages["Config"], "Check Update", function()
    VersionCheck.Check()
end)
CreateButton(Pages["Config"], "List Keybinds", function()
    for _, line in ipairs(KeybindManager.List()) do
        Logger.Write("KEY", line)
    end
    Notifications.Push("Keybinds", "logged to console", THEME.Accent)
end)

-- Misc — stats dashboard
CreateToggle(Pages["Misc"], "Stats Dashboard", false, function(v)
    if v then StatsDashboard.Start() else StatsDashboard.Stop() end
end)

-- ═══════════════ EXTENSION-08: EXPORTS ═══════════════
MM.Register("KeybindManager", KeybindManager)
MM.Register("StatsDashboard", StatsDashboard)
MM.Register("HelpScreen", HelpScreen)
MM.Register("AboutScreen", AboutScreen)
MM.Register("QuickAccess", QuickAccess)
MM.Register("VersionCheck", VersionCheck)

-- ═══════════════ EXTENSION-09: UI — ADVANCED AIM ═══════════════

-- Aim curves
CreateDropdown(Pages["Combat"], "Aim Curve", AimCurves.List(), "linear", function(v)
    AimCurves.current = v
    Notifications.Push("Aim", "curve: " .. v, THEME.Accent)
end)

-- Aim zones
CreateDropdown(Pages["Combat"], "Aim Zone", AimZones.List(), "head", function(v)
    AimZones.SetPriority(v)
    Notifications.Push("Aim", "zone: " .. v, THEME.Accent)
end)

-- Hitbox resolver
CreateDropdown(Pages["Combat"], "Hitbox Mode", HitboxResolver.List(), "head", function(v)
    HitboxResolver.SetMode(v)
    Notifications.Push("Aim", "hitbox: " .. v, THEME.Accent)
end)

-- Prediction profiles
CreateDropdown(Pages["Combat"], "Prediction", PredictionProfiles.List(), "medium", function(v)
    PredictionProfiles.Set(v)
    Notifications.Push("Aim", "prediction: " .. v, THEME.Accent)
end)

-- Aim assist
CreateDropdown(Pages["Combat"], "Assist Mode", AimAssist.List(), "snap", function(v)
    AimAssist.SetMode(v)
    Notifications.Push("Aim", "assist: " .. v, THEME.Accent)
end)
CreateSlider(Pages["Combat"], "Track Speed x100", 1, 100, 15, function(v)
    AimAssist.SetTrackingSpeed(v / 100)
end)

-- Spread compensation
CreateToggle(Pages["Combat"], "Spread Compensation", false, function(v)
    if v then SpreadComp.Enable() else SpreadComp.Disable() end
end)

-- Recoil control
CreateToggle(Pages["Combat"], "Recoil Control", false, function(v)
    if v then RecoilControl.Enable() else RecoilControl.Disable() end
end)
CreateSlider(Pages["Combat"], "Recoil Strength x100", 10, 200, 50, function(v)
    RecoilControl.strength = v / 100
end)
CreateButton(Pages["Combat"], "Recoil: Reset Pattern", function()
    RecoilControl.Reset()
    Notifications.Push("Recoil", "reset", THEME.Accent)
end)

-- Target priority
CreateDropdown(Pages["Combat"], "Target Priority", TargetPriority.List(), "distance", function(v)
    TargetPriority.SetMode(v)
    Notifications.Push("Aim", "priority: " .. v, THEME.Accent)
end)

-- Smooth profiles
CreateDropdown(Pages["Combat"], "Smooth Profile", SmoothProfiles.List(), "medium", function(v)
    SmoothProfiles.Set(v)
    Notifications.Push("Aim", "smooth: " .. v, THEME.Accent)
end)

-- Velocity smoothing
CreateToggle(Pages["Combat"], "Velocity Smoothing", false, function(v)
    if v then VelocitySmoothing.Enable() else VelocitySmoothing.Disable() end
end)
CreateSlider(Pages["Combat"], "Velocity Window", 2, 15, 5, function(v)
    VelocitySmoothing.window = v
end)

-- Lock hold
CreateToggle(Pages["Combat"], "Lock Hold", false, function(v)
    if v then LockHold.Enable() else LockHold.Disable() end
end)
CreateSlider(Pages["Combat"], "Lock Hold ms", 100, 1000, 500, function(v)
    LockHold.maxHold = v / 1000
end)

-- ═══════════════ EXTENSION-09: EXPORTS ═══════════════
MM.Register("AimCurves", AimCurves)
MM.Register("AimZones", AimZones)
MM.Register("HitboxResolver", HitboxResolver)
MM.Register("PredictionProfiles", PredictionProfiles)
MM.Register("AimAssist", AimAssist)
MM.Register("SpreadComp", SpreadComp)
MM.Register("RecoilControl", RecoilControl)
MM.Register("TargetPriority", TargetPriority)
MM.Register("SmoothProfiles", SmoothProfiles)
MM.Register("VelocitySmoothing", VelocitySmoothing)
MM.Register("LockHold", LockHold)

-- ═══════════════ BOOT ═══════════════
task.spawn(function()
    task.wait(0.1)
    SelectTab("Combat")
end)
OpenMenu()

MM.Register("Config", Config)
MM.Register("Fly", Fly)
MM.Register("Noclip", Noclip)
MM.Register("InfJump", InfJump)
MM.Register("SafeTeleport", SafeTeleport)
getgenv().MeowV4 = MM

print("[MeowV4] loaded — modules: " .. tostring((function() local n = 0 for _ in pairs(MM.Modules) do n = n + 1 end return n end)()))
