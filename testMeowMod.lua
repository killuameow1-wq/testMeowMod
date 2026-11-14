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
