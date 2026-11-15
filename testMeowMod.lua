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

-- ═══════════════════════════════════════════════════════════
--  PART 2: AIMBOT & ESP
-- ═══════════════════════════════════════════════════════════

-- 1. SILENT AIM (Хук на метатейбл)
local oldNamecall = nil
local function HookSilent()
    if oldNamecall then return end
    pcall(function()
        local mt = getrawmetatable(game)
        oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            if Config.SilentAim and MM.SilentTarget and MM.SilentTarget.Parent then
                local method = getnamecallmethod()
                if method == "Raycast" or method == "FindPartOnRay" then
                    local args = {...}
                    local headPos = MM.SilentTarget.Position
                    if method == "Raycast" then
                        args[2] = (headPos - args[1]).Unit * (headPos - args[1]).Magnitude
                        return oldNamecall(self, unpack(args))
                    elseif method == "FindPartOnRay" then
                        args[1] = Ray.new(args[1].Origin, headPos - args[1].Origin)
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
end
HookSilent()

-- 2. ЛОГИКА ПОИСКА ЦЕЛИ
function MM.GetClosestTarget(fov, maxDist)
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
                            bestDist = d2
                            best = tHead
                        end
                    end
                end
            end
        end
    end
    return best
end

-- 3. ВИЗУАЛЬНЫЙ АИМ (Assist)
local VisualAiming = false
local VisualAimTarget = nil

MM.SetVisualAiming = function(state) VisualAiming = state end

local AimFOVCircle = Drawing.new("Circle")
AimFOVCircle.Thickness = 1.5
AimFOVCircle.Filled = false
AimFOVCircle.Visible = false
table.insert(MM.Drawings, AimFOVCircle)

local function AimUpdate()
    -- Silent Aim
    if Config.SilentAim then
        MM.SilentTarget = MM.GetClosestTarget(Config.SilentFOV, Config.SilentMaxDist)
        if MM.SilentTarget then
            AimFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            AimFOVCircle.Radius = Config.SilentFOV
            AimFOVCircle.Color = Color3.fromRGB(180, 0, 255)
            AimFOVCircle.Visible = true
        elseif not VisualAiming and not Config.ShowAimFOV then
            AimFOVCircle.Visible = false
        end
    else
        MM.SilentTarget = nil
    end

    -- Visual Aim
    if Config.Aim and VisualAiming then
        if VisualAimTarget then
            local hum = VisualAimTarget.Parent and VisualAimTarget.Parent:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then VisualAimTarget = nil
            else
                local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
                local sp, on = Camera:WorldToViewportPoint(VisualAimTarget.Position)
                if on then
                    local d2 = math.sqrt((sp.X - cx)^2 + (sp.Y - cy)^2)
                    if d2 > Config.AimFOV then VisualAimTarget = nil end
                else VisualAimTarget = nil end
            end
        end
        if not VisualAimTarget then 
            VisualAimTarget = MM.GetClosestTarget(Config.AimFOV, Config.AimMaxDist) 
        end
        
        if VisualAimTarget then
            local targetCF = CFrame.new(Camera.CFrame.Position, VisualAimTarget.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, Config.AimSmooth)
        end
        
        if not Config.SilentAim and not Config.ShowAimFOV then
            AimFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            AimFOVCircle.Radius = Config.AimFOV
            AimFOVCircle.Color = Color3.fromRGB(0, 240, 255)
            AimFOVCircle.Visible = true
        end
    else
        VisualAimTarget = nil
        if not Config.SilentAim and not Config.ShowAimFOV then AimFOVCircle.Visible = false end
    end
    
    -- Show Aim FOV (Visual check for config)
    if Config.ShowAimFOV and not Config.SilentAim and not VisualAiming then
        AimFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        AimFOVCircle.Radius = Config.AimFOV
        AimFOVCircle.Color = Color3.fromRGB(0, 240, 255)
        AimFOVCircle.Visible = true
    end
end

RunService:BindToRenderStep("MeowAim", Enum.RenderPriority.Camera.Value + 2, AimUpdate)

-- 4. ESP (Игроки)
local ESPDraws = {}
local function CreateESPDraws(player)
    if ESPDraws[player] then return ESPDraws[player] end
    local ok, t = pcall(function()
        return { Box = Drawing.new("Square"), Name = Drawing.new("Text"), Dist = Drawing.new("Text") }
    end)
    if not ok or not t then return nil end
    
    t.Box.Thickness = 1
    t.Box.Color = Color3.fromRGB(0, 240, 255)
    t.Name.Size = 13; t.Name.Center = true; t.Name.Outline = true
    t.Name.Color = Color3.fromRGB(255, 255, 255)
    t.Dist.Size = 12; t.Dist.Center = true; t.Dist.Outline = true
    t.Dist.Color = Color3.fromRGB(180, 180, 180)
    
    table.insert(MM.Drawings, t.Box)
    table.insert(MM.Drawings, t.Name)
    table.insert(MM.Drawings, t.Dist)
    
    ESPDraws[player] = t
    return t
end

local function HideESP(d)
    if not d then return end
    d.Box.Visible = false
    d.Name.Visible = false
    d.Dist.Visible = false
end

local function RemoveESP(player)
    if not ESPDraws[player] then return end
    local d = ESPDraws[player]
    pcall(function() d.Box:Remove() end)
    pcall(function() d.Name:Remove() end)
    pcall(function() d.Dist:Remove() end)
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
            local w = math.abs(rS.X - lS.X) 
            local h = math.abs(bS.Y - tS.Y)
            if w > 0 and h > 0 and w < 800 and h < 800 then 
                return {x = lS.X, y = tS.Y, w = w, h = h} 
            end
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
            local h = math.abs(fS.Y - hS.Y) 
            local w = h * 0.5
            if h > 0 and w > 0 then 
                return {x = hS.X - w / 2, y = hS.Y, w = w, h = h} 
            end
        end
    end
    return nil
end

local function RenderESP()
    if not Config.ESP then
        for _, d in pairs(ESPDraws) do HideESP(d) end
        return
    end
    
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local char = p.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local d = ESPDraws[p]
            
            if not (char and hrp and hum and hum.Health > 0) then 
                if d then HideESP(d) end
            else
                local d3 = myPos and (myPos - hrp.Position).Magnitude or 0
                if d3 > Config.ESP_MaxDist then 
                    if d then HideESP(d) end
                else
                    local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if not onScreen then 
                        if d then HideESP(d) end
                    else
                        if not d then d = CreateESPDraws(p) end
                        if d then
                            local box = GetPlayerBox(char)
                            local x, y, w, h
                            if box then 
                                x, y, w, h = box.x, box.y, box.w, box.h
                            else 
                                h = math.clamp(8000 / math.max(d3, 1), 20, 500) 
                                w = h / 2 
                                x = sp.X - w / 2 
                                y = sp.Y - h / 2 
                            end
                            
                            d.Box.Visible = Config.ESP_Box
                            if d.Box.Visible then 
                                d.Box.Size = Vector2.new(w, h) 
                                d.Box.Position = Vector2.new(x, y) 
                            end
                            
                            d.Name.Visible = Config.ESP_Name
                            if d.Name.Visible then 
                                d.Name.Text = p.Name 
                                d.Name.Position = Vector2.new(x + w / 2, y - 18) 
                            end
                            
                            d.Dist.Visible = Config.ESP_Dist
                            if d.Dist.Visible then 
                                d.Dist.Text = tostring(math.floor(d3)) .. "m" 
                                d.Dist.Position = Vector2.new(x + w / 2, y + h + 2) 
                            end
                        end
                    end
                end
            end
        end
    end
end

-- 5. ESP (Машины)
local VehicleDraws = {}
local VehicleSeats = {}

local function GetVehicleModel(seat) 
    return seat:FindFirstAncestorOfClass("Model") or seat:FindFirstAncestorOfClass("Folder") 
end
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
WS.DescendantAdded:Connect(function(inst) 
    if inst:IsA("VehicleSeat") then RegisterSeat(inst) end 
end)

local function CreateVehicleDraw(model)
    if VehicleDraws[model] then return VehicleDraws[model] end
    local ok, t = pcall(function() 
        return {Box = Drawing.new("Square"), Name = Drawing.new("Text"), Dist = Drawing.new("Text")} 
    end)
    if not ok or not t then return nil end
    
    t.Box.Thickness = 1
    t.Box.Color = Color3.fromRGB(255, 165, 0)
    t.Name.Size = 13; t.Name.Center = true; t.Name.Outline = true
    t.Name.Color = Color3.fromRGB(255, 200, 0)
    t.Dist.Size = 12; t.Dist.Center = true; t.Dist.Outline = true
    t.Dist.Color = Color3.fromRGB(255, 200, 0)
    
    table.insert(MM.Drawings, t.Box)
    table.insert(MM.Drawings, t.Name)
    table.insert(MM.Drawings, t.Dist)
    
    VehicleDraws[model] = t
    return t
end

local function RenderVehicleESP()
    if not Config.V_ESP then 
        for model, d in pairs(VehicleDraws) do 
            d.Box.Visible = false; d.Name.Visible = false; d.Dist.Visible = false 
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
                        local sp, on = Camera:WorldToViewportPoint(pos)
                        if not on then 
                            d.Box.Visible = false; d.Name.Visible = false; d.Dist.Visible = false
                        else
                            local sz = math.clamp(8000 / math.max(d3, 1), 24, 300)
                            d.Box.Visible = Config.V_ESP_Box
                            if d.Box.Visible then 
                                d.Box.Size = Vector2.new(sz, sz) 
                                d.Box.Position = Vector2.new(sp.X - sz / 2, sp.Y - sz / 2) 
                            end
                            
                            d.Name.Visible = Config.V_ESP_Name
                            if d.Name.Visible then 
                                d.Name.Text = model.Name 
                                d.Name.Position = Vector2.new(sp.X, sp.Y - sz / 2 - 18) 
                            end
                            
                            d.Dist.Visible = Config.V_ESP_Dist
                            if d.Dist.Visible then 
                                d.Dist.Text = tostring(math.floor(d3)) .. "m" 
                                d.Dist.Position = Vector2.new(sp.X, sp.Y + sz / 2 + 2) 
                            end
                        end
                    end
                end
            end
        end
    end
end

RunService:BindToRenderStep("MeowESP", Enum.RenderPriority.Camera.Value + 1, RenderESP)
RunService:BindToRenderStep("MeowVESP", Enum.RenderPriority.Camera.Value + 4, RenderVehicleESP)

-- ═══════════════════════════════════════════════════════════
--  UI BINDINGS (Aim & ESP)
-- ═══════════════════════════════════════════════════════════

-- Aim Tab
CreateToggle(Pages["Aim"], "Visual Aim (Assist)", "Aim", nil)
CreateSlider(Pages["Aim"], "Aim FOV (px)", 50, 500, "AimFOV", nil)
CreateSlider(Pages["Aim"], "Aim Smooth x100", 1, 100, "AimSmooth", function(v) Config.AimSmooth = v / 100 end)
CreateSlider(Pages["Aim"], "Aim Max Dist", 100, 3000, "AimMaxDist", nil)
CreateToggle(Pages["Aim"], "Show Aim FOV", "ShowAimFOV", nil)

CreateToggle(Pages["Aim"], "Silent Aim (hits head)", "SilentAim", nil)
CreateSlider(Pages["Aim"], "Silent FOV (px)", 50, 500, "SilentFOV", nil)
CreateSlider(Pages["Aim"], "Silent Max Dist", 100, 3000, "SilentMaxDist", nil)

-- ESP Tab
CreateToggle(Pages["ESP"], "ESP Master (Players)", "ESP", nil)
CreateToggle(Pages["ESP"], " - Box", "ESP_Box", nil)
CreateToggle(Pages["ESP"], " - Name", "ESP_Name", nil)
CreateToggle(Pages["ESP"], " - Distance", "ESP_Dist", nil)
CreateSlider(Pages["ESP"], "Player Max Dist", 100, 5000, "ESP_MaxDist", nil)

CreateToggle(Pages["ESP"], "Vehicle ESP Master", "V_ESP", nil)
CreateToggle(Pages["ESP"], " - Box", "V_ESP_Box", nil)
CreateToggle(Pages["ESP"], " - Name", "V_ESP_Name", nil)
CreateToggle(Pages["ESP"], " - Distance", "V_ESP_Dist", nil)
CreateSlider(Pages["ESP"], "Vehicle Max Dist", 100, 5000, "V_ESP_MaxDist", nil)

print("[MeowMod] Part 2 Loaded — Aim & ESP ready.")

-- ═══════════════════════════════════════════════════════════
--  PART 3: MOVEMENT, FLY JOYSTICK, AIM BUTTON
-- ═══════════════════════════════════════════════════════════

-- 1. БАЗОВЫЕ ФУНКЦИИ ДВИЖЕНИЯ
local function ApplySpeed()
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then 
        hum.WalkSpeed = Config.SpeedOn and Config.SpeedValue or 16 
    end
end

local function ApplyJumpPower()
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.UseJumpPower = true end)
        hum.JumpPower = Config.JumpPowerOn and Config.JumpPowerValue or 50
    end
end

-- Infinite Jump
local InfJumpConn = nil
local function ApplyInfJump()
    if Config.InfJump then
        if not InfJumpConn then
            InfJumpConn = UIS.JumpRequest:Connect(function()
                local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then 
                    hum:ChangeState(Enum.HumanoidStateType.Jumping) 
                end
            end)
        end
    else
        if InfJumpConn then InfJumpConn:Disconnect() InfJumpConn = nil end
    end
end

-- Noclip
local NoclipConn = nil
local function ApplyNoclip()
    if Config.Noclip then
        if not NoclipConn then
            NoclipConn = RunService.Stepped:Connect(function()
                local char = LP.Character
                if char then 
                    for _, p in ipairs(char:GetDescendants()) do 
                        if p:IsA("BasePart") and p.CanCollide then 
                            p.CanCollide = false 
                        end 
                    end 
                end
            end)
        end
    else
        if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
    end
end

table.insert(MM.Connections, { 
    Disconnect = function() 
        if InfJumpConn then InfJumpConn:Disconnect() end 
        if NoclipConn then NoclipConn:Disconnect() end 
    end 
})

-- Применяем при респавне
LP.CharacterAdded:Connect(function()
    task.wait(1)
    ApplySpeed()
    ApplyJumpPower()
end)

-- 2. FLY (Полёт с анти-падением)
local FlyState = { dir = Vector3.zero, up = 0 }
local FlyConn, FlyBodyVel, FlyGyro, FlyAntiFallConn = nil, nil, nil, nil
local FlyJoyUI = nil

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
            FlyGyro.P = 10000
            FlyGyro.D = 500
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
                
                if dir.Magnitude > 0 then 
                    moveVel = (Camera.CFrame.LookVector * dir.Z + Camera.CFrame.RightVector * dir.X).Unit * Config.FlySpeed 
                end
                if FlyState.up ~= 0 then 
                    moveVel = moveVel + Vector3.new(0, FlyState.up * Config.FlySpeed, 0) 
                end
                
                FlyBodyVel.Velocity = moveVel
            end)
        end
        
        if not FlyAntiFallConn then
            FlyAntiFallConn = RunService.Stepped:Connect(function()
                if not Config.Fly then return end
                local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = hum.MaxHealth end
                local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if h and h.Position.Y < -500 then 
                    h.CFrame = CFrame.new(0, 50, 0) 
                end
            end)
        end
    else
        if FlyBodyVel then pcall(function() FlyBodyVel:Destroy() end) FlyBodyVel = nil end
        if FlyGyro then pcall(function() FlyGyro:Destroy() end) FlyGyro = nil end
        if FlyConn then FlyConn:Disconnect() FlyConn = nil end
        if FlyAntiFallConn then FlyAntiFallConn:Disconnect() FlyAntiFallConn = nil end
        
        if hum then
            hum.PlatformStand = false
            if hrp then 
                hrp.CustomPhysicalProperties = nil
                hrp.CanCollide = true 
            end
        end
    end
end

table.insert(MM.Connections, { 
    Disconnect = function() 
        if FlyBodyVel then FlyBodyVel:Destroy() end 
        if FlyGyro then FlyGyro:Destroy() end 
        if FlyConn then FlyConn:Disconnect() end 
        if FlyAntiFallConn then FlyAntiFallConn:Disconnect() end 
    end 
})

-- 3. МОБИЛЬНЫЙ ДЖОЙСТИК ДЛЯ ПОЛЁТА
local function BuildFlyJoystick(show)
    if show then
        if FlyJoyUI and FlyJoyUI.container then 
            FlyJoyUI.container.Visible = true 
            return 
        end
        
        local container = Instance.new("Frame")
        container.Name = "FlyJoy" 
        container.Size = UDim2.new(0, 200, 0, 200)
        container.Position = UDim2.new(1, -220, 0.5, -100) 
        container.BackgroundTransparency = 1
        container.ZIndex = 100 
        container.Parent = ScreenGui
        
        FlyJoyUI = {container = container}
        
        local function makeBtn(text, pos, cb)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 60, 0, 60) 
            b.Position = pos
            b.BackgroundColor3 = THEME.Surface 
            b.BackgroundTransparency = 0.2
            b.Text = text 
            b.TextColor3 = THEME.Accent 
            b.Font = Enum.Font.GothamBold
            b.TextSize = 20 
            b.BorderSizePixel = 0 
            b.ZIndex = 101 
            b.Parent = container
            corner(b, 12) 
            stroke(b, THEME.Accent, 1, 0.5)
            
            b.MouseButton1Down:Connect(function() cb(true) end)
            b.MouseButton1Up:Connect(function() cb(false) end)
            b.MouseLeave:Connect(function() cb(false) end)
            return b
        end
        
        makeBtn("W", UDim2.new(0, 70, 0, 0), function(on) FlyState.dir = Vector3.new(FlyState.dir.X, FlyState.dir.Y, on and 1 or 0) end)
        makeBtn("S", UDim2.new(0, 70, 0, 140), function(on) FlyState.dir = Vector3.new(FlyState.dir.X, FlyState.dir.Y, on and -1 or 0) end)
        makeBtn("A", UDim2.new(0, 0, 0, 70), function(on) FlyState.dir = Vector3.new(on and -1 or 0, FlyState.dir.Y, FlyState.dir.Z) end)
        makeBtn("D", UDim2.new(0, 140, 0, 70), function(on) FlyState.dir = Vector3.new(on and 1 or 0, FlyState.dir.Y, FlyState.dir.Z) end)
        makeBtn("↑", UDim2.new(0, 70, 0, 70), function(on) FlyState.up = on and 1 or 0 end)
        
        local down = Instance.new("TextButton")
        down.Size = UDim2.new(0, 60, 0, 60) 
        down.Position = UDim2.new(0, 200, 0, 70)
        down.BackgroundColor3 = THEME.Surface 
        down.BackgroundTransparency = 0.2
        down.Text = "↓" 
        down.TextColor3 = THEME.Accent 
        down.Font = Enum.Font.GothamBold
        down.TextSize = 20 
        down.BorderSizePixel = 0 
        down.ZIndex = 101 
        down.Parent = container
        corner(down, 12) 
        stroke(down, THEME.Accent, 1, 0.5)
        
        down.MouseButton1Down:Connect(function() FlyState.up = -1 end)
        down.MouseButton1Up:Connect(function() FlyState.up = 0 end)
        down.MouseLeave:Connect(function() FlyState.up = 0 end)
    else
        if FlyJoyUI and FlyJoyUI.container then 
            FlyJoyUI.container.Visible = false 
        end
    end
end

-- 4. UI BINDINGS (Movement)
CreateToggle(Pages["Movement"], "Speed Hack", "SpeedOn", function() ApplySpeed() end)
CreateSlider(Pages["Movement"], "Speed Value", 16, 200, "SpeedValue", function() 
    if Config.SpeedOn then ApplySpeed() end 
end)

CreateToggle(Pages["Movement"], "Jump Power On", "JumpPowerOn", function() ApplyJumpPower() end)
CreateSlider(Pages["Movement"], "Jump Power", 50, 500, "JumpPowerValue", function() 
    if Config.JumpPowerOn then ApplyJumpPower() end 
end)

CreateToggle(Pages["Movement"], "Infinite Jump", "InfJump", function(v) 
    ApplyInfJump() 
end)

CreateToggle(Pages["Movement"], "Noclip", "Noclip", function(v) 
    ApplyNoclip() 
end)

CreateToggle(Pages["Movement"], "Fly (mobile joystick)", "Fly", function(v)
    ApplyFly()
    BuildFlyJoystick(v)
end)
CreateSlider(Pages["Movement"], "Fly Speed", 1, 500, "FlySpeed", nil)

-- 5. ЭКРАННАЯ КНОПКА AIM (Для визуального аима)
local AimBtn = Instance.new("TextButton")
AimBtn.Size = UDim2.new(0, 60, 0, 60)
AimBtn.Position = UDim2.new(1, -80, 0.7, 0)
AimBtn.BackgroundColor3 = THEME.Surface
AimBtn.BackgroundTransparency = 0.2
AimBtn.Text = "AIM"
AimBtn.TextColor3 = THEME.Accent
AimBtn.Font = Enum.Font.GothamBold
AimBtn.TextSize = 16
AimBtn.BorderSizePixel = 0
AimBtn.ZIndex = 101
AimBtn.Parent = ScreenGui
corner(AimBtn, 30) 
stroke(AimBtn, THEME.Accent, 1.5, 0.4)

AimBtn.MouseButton1Down:Connect(function() MM.SetVisualAiming(true) end)
AimBtn.MouseButton1Up:Connect(function() MM.SetVisualAiming(false) end)
AimBtn.MouseLeave:Connect(function() MM.SetVisualAiming(false) end)

-- Применяем настройки при старте
ApplySpeed()
ApplyJumpPower()

print("[MeowMod] Part 3 Loaded — Movement, Fly Joystick, Aim Button ready.")
