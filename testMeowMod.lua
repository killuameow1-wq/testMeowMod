--[[
    ╔══════════════════════════════════════════════════════════╗
    ║  MeowMod FINAL — Ultimate Release (1 MB Build)           ║
    ║  Part 1: Core, Config, UI Base, Widgets                  ║
    ╚══════════════════════════════════════════════════════════╝
]]

if getgenv().MeowV4 and getgenv().MeowV4.Unload then 
    pcall(getgenv().MeowV4.Unload) 
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Http = game:GetService("HttpService")
local WS = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local Camera = WS.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

do
    local old = PG:FindFirstChild("MeowMod")
    if old then old:Destroy() end
end

local MM = {
    Version = "4.0.0-final",
    Modules = {},
    Drawings = {},
    Connections = {},
}
getgenv().MeowV4 = MM

-- ═══════════════════════════════════════════════════════════
--  CONFIG SYSTEM
-- ═══════════════════════════════════════════════════════════

local CONFIG_PATH = "MeowMod_Final.json"
local function HasFS() return typeof(writefile) == "function" and typeof(readfile) == "function" end

local Config = {
    -- UI
    UI_Scale = 1.0,
    
    -- Aim
    SilentAim = false, SilentFOV = 150, SilentMaxDist = 1000,
    Aim = false, AimFOV = 150, AimSmooth = 0.3, AimMaxDist = 1000,
    ShowAimFOV = false,
    
    -- ESP
    ESP = false, ESP_Box = true, ESP_Name = true, ESP_Dist = true, ESP_MaxDist = 2000,
    V_ESP = false, V_ESP_Box = true, V_ESP_Name = true, V_ESP_Dist = true, V_ESP_MaxDist = 2000,
    
    -- Movement
    SpeedOn = false, SpeedValue = 25, JumpPowerOn = false, JumpPowerValue = 50,
    InfJump = false, Fly = false, FlySpeed = 50, Noclip = false,
    
    -- Visuals
    Crosshair = false, CH_Size = 10, Fullbright = false, CameraFOV = 70,
    World_FogOff = false, World_Time = 12, World_Gravity = 196.2,
    FreeCam = false, FreeCam_Speed = 50, MaxFOV = 70,
    Bloom = false, BloomInt = 1, Blur = false, BlurSize = 8,
    
    -- Misc
    Misc_AntiAFK = false, Misc_FPSCap = 240, ShowFPS = false, ShowPing = false,
    AutoClicker = false, AC_Delay = 50,
    ChatSpam = false, ChatSpam_Msg = "meow", ChatSpam_Delay = 1,
    AutoFarm = false, SoundSpam = false, SoundSpam_Id = "rbxassetid://131961136",
    MusicId = "rbxassetid://131961136", MusicPlaying = false,
    
    -- Teleport
    TP_SafeDrop = 3,
}

local function LoadConfig()
    if not HasFS() then return end
    local ok, data = pcall(function() 
        if isfile(CONFIG_PATH) then return readfile(CONFIG_PATH) end 
    end)
    if ok and data and data ~= "" then
        local ok2, parsed = pcall(function() return Http:JSONDecode(data) end)
        if ok2 and parsed then 
            for k, v in pairs(parsed) do 
                if Config[k] ~= nil then Config[k] = v end 
            end
        end
    end
end

local function SaveConfig()
    if not HasFS() then return false end
    local t = {}
    for k, v in pairs(Config) do 
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then 
            t[k] = v 
        end 
    end
    return pcall(function() 
        writefile(CONFIG_PATH, Http:JSONEncode(t)) 
    end)
end

LoadConfig()

-- ═══════════════════════════════════════════════════════════
--  ADAPTIVE SIZING
-- ═══════════════════════════════════════════════════════════

local vp = WS.CurrentCamera and WS.CurrentCamera.ViewportSize or Vector2.new(375, 812)
local BASE_W, BASE_H = 340, 520
local winW = math.min(BASE_W, vp.X * 0.92)
local winH = math.min(BASE_H, vp.Y * 0.85)
local scaleFactor = math.min(winW / BASE_W, winH / BASE_H, 1)

-- ═══════════════════════════════════════════════════════════
--  THEME
-- ═══════════════════════════════════════════════════════════

local THEME = {
    Bg = Color3.fromRGB(16, 17, 22), 
    Surface = Color3.fromRGB(22, 24, 30),
    SurfaceHi = Color3.fromRGB(28, 31, 39), 
    Border = Color3.fromRGB(38, 42, 52),
    Accent = Color3.fromRGB(0, 240, 255), 
    Text = Color3.fromRGB(230, 234, 242),
    SubText = Color3.fromRGB(140, 148, 165), 
    Muted = Color3.fromRGB(90, 98, 115),
    Danger = Color3.fromRGB(255, 90, 110), 
    Success = Color3.fromRGB(80, 220, 140),
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
    s.Parent = inst 
    return s
end

-- ═══════════════════════════════════════════════════════════
--  GUI ROOT
-- ═══════════════════════════════════════════════════════════

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeowMod" 
ScreenGui.ResetOnSpawn = false 
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999 
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling 
ScreenGui.Parent = PG

local Main = Instance.new("Frame")
Main.AnchorPoint = Vector2.new(0.5, 0.5) 
Main.Position = UDim2.new(0.5, 0, 0.5, 0) 
Main.Size = UDim2.new(0, winW, 0, winH)
Main.BackgroundColor3 = THEME.Bg 
Main.BorderSizePixel = 0 
Main.Active = true 
Main.Visible = true
Main.ClipsDescendants = true 
Main.Parent = ScreenGui 
corner(Main, 14) 
stroke(Main, THEME.Border, 1, 0.3)

local MainScale = Instance.new("UIScale") 
MainScale.Scale = scaleFactor 
MainScale.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 54) 
Header.BackgroundColor3 = THEME.Surface
Header.BorderSizePixel = 0 
Header.Active = true 
Header.Parent = Main 
corner(Header, 14)

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
SubtitleLabel.Text = "FINAL · 1MB"
SubtitleLabel.TextColor3 = THEME.Muted 
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.Font = Enum.Font.GothamMedium 
SubtitleLabel.TextSize = 11 
SubtitleLabel.Parent = Header

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
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragStart = nil 
        startPos = nil
    end
end)

-- ═══════════════════════════════════════════════════════════
--  TABS
-- ═══════════════════════════════════════════════════════════

local TabBar = Instance.new("ScrollingFrame")
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
TL.VerticalAlignment = Enum.VerticalAlignment.Center

local Pages = {}
local TabButtons = {}

local function SelectTab(name)
    for n, p in pairs(Pages) do 
        p.Visible = (n == name) 
    end
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
    Page.BorderSizePixel = 0 
    Page.Parent = Main
    local L = Instance.new("UIListLayout", Page) 
    L.Padding = UDim.new(0, 6)
    Pages[name] = Page

    Btn.MouseButton1Click:Connect(function() SelectTab(name) end)
end

CreateTab("Aim", 1)
CreateTab("ESP", 2)
CreateTab("Visuals", 3)
CreateTab("Movement", 4)
CreateTab("Vehicles", 5)
CreateTab("Teleport", 6)
CreateTab("Players", 7)
CreateTab("World", 8)
CreateTab("Misc", 9)
CreateTab("Config", 10)

-- ═══════════════════════════════════════════════════════════
--  UI WIDGETS
-- ═══════════════════════════════════════════════════════════

local function CreateToggle(parent, name, cfgKey, cb)
    local def = Config[cfgKey]
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 46) 
    Btn.BackgroundColor3 = THEME.Surface
    Btn.Text = "" 
    Btn.AutoButtonColor = false 
    Btn.BorderSizePixel = 0 
    Btn.Parent = parent 
    corner(Btn, 8)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0) 
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1 
    lbl.Text = name 
    lbl.TextColor3 = THEME.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left 
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13 
    lbl.Parent = Btn
    
    local Ind = Instance.new("Frame")
    Ind.Size = UDim2.new(0, 40, 0, 22) 
    Ind.Position = UDim2.new(1, -54, 0.5, -11)
    Ind.BackgroundColor3 = def and THEME.Accent or Color3.fromRGB(55, 55, 70) 
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
    
    local state = def
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Ind.BackgroundColor3 = state and THEME.Accent or Color3.fromRGB(55, 55, 70)
        Circ.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        Config[cfgKey] = state
        if cb then cb(state) end
        SaveConfig()
    end)
    return Btn
end

local function CreateSlider(parent, name, mn, mx, cfgKey, cb)
    local def = Config[cfgKey]
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, 0, 0, 60) 
    F.BackgroundColor3 = THEME.Surface
    F.BorderSizePixel = 0 
    F.Parent = parent 
    corner(F, 8)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 0, 20) 
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1 
    lbl.Text = name 
    lbl.TextColor3 = THEME.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left 
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13 
    lbl.Parent = F
    
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
    Bg.BackgroundColor3 = Color3.fromRGB(40, 45, 58) 
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
        Config[cfgKey] = v
        if cb then cb(v) end
    end
    Hit.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true 
            Update(inp)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            Update(inp)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            if dragging then SaveConfig() end
            dragging = false
        end
    end)
    return F
end

local function CreateButton(parent, name, cb, color)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 46) 
    Btn.BackgroundColor3 = color or THEME.SurfaceHi
    Btn.Text = name 
    Btn.TextColor3 = color and Color3.new(1,1,1) or THEME.Text 
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

local function CreateTextbox(parent, name, placeholder, cfgKey, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 60) 
    f.BackgroundColor3 = THEME.Surface
    f.BorderSizePixel = 0 
    f.Parent = parent 
    corner(f, 8)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20) 
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1 
    lbl.Text = name 
    lbl.TextColor3 = THEME.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left 
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13 
    lbl.Parent = f
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -28, 0, 26) 
    box.Position = UDim2.new(0, 14, 0, 26)
    box.BackgroundColor3 = Color3.fromRGB(12, 12, 18) 
    box.BorderSizePixel = 0
    box.Text = tostring(Config[cfgKey] or "")
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = THEME.Muted
    box.TextColor3 = THEME.Text
    box.Font = Enum.Font.Code
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Parent = f
    corner(box, 6)
    box.FocusLost:Connect(function() 
        Config[cfgKey] = box.Text
        if cb then cb(box.Text) end
        SaveConfig()
    end)
    return f
end

-- ═══════════════════════════════════════════════════════════
--  FLOAT BUTTON
-- ═══════════════════════════════════════════════════════════

local FloatBtn = Instance.new("TextButton")
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
FloatBtn.Visible = false 
FloatBtn.Parent = ScreenGui
corner(FloatBtn, 22) 
stroke(FloatBtn, THEME.Accent, 1.5, 0.4)

local function OpenMenu() 
    Main.Visible = true 
    FloatBtn.Visible = false 
end
local function CloseMenu() 
    Main.Visible = false 
    FloatBtn.Visible = true 
end
FloatBtn.MouseButton1Click:Connect(OpenMenu)
CloseBtn.MouseButton1Click:Connect(CloseMenu)

-- ═══════════════════════════════════════════════════════════
--  UNLOAD SYSTEM
-- ═══════════════════════════════════════════════════════════

local function FullUnload()
    pcall(SaveConfig)
    for _, c in pairs(MM.Connections) do
        pcall(function() c:Disconnect() end)
    end
    for _, d in pairs(MM.Drawings) do
        pcall(function() d:Remove() end)
    end
    pcall(function() RunService:UnbindFromRenderStep("MeowESP") end)
    pcall(function() RunService:UnbindFromRenderStep("MeowAim") end)
    pcall(function() RunService:UnbindFromRenderStep("MeowCH") end)
    pcall(function() RunService:UnbindFromRenderStep("MeowVESP") end)
    pcall(function() ScreenGui:Destroy() end)
    if getgenv().MeowV4 == MM then getgenv().MeowV4 = nil end
    print("[MeowMod] Unloaded successfully.")
end
MM.Unload = FullUnload
getgenv().MeowModUnload = FullUnload
UnloadBtn.MouseButton1Click:Connect(FullUnload)

task.spawn(function() 
    task.wait(0.1) 
    SelectTab("Aim") 
end)

print("[MeowMod] Part 1 Loaded — Base, Config, UI ready.")
