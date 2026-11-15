--[[
    ╔══════════════════════════════════════════════════════════╗
    ║  MeowMod — FULL RELEASE (Mystrix UI)                     ║
    ╚══════════════════════════════════════════════════════════╝
]]

if getgenv().MeowUIUnload then pcall(getgenv().MeowUIUnload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Http = game:GetService("HttpService")
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
    
    -- ESP
    ESP = false, ESP_Box = true, ESP_Name = true, ESP_Dist = true, ESP_MaxDist = 2000,
    ESPColorHex = "00F0FF", -- Cyan
    
    V_ESP = false, V_ESP_Box = true, V_ESP_Name = true, V_ESP_Dist = true, V_ESP_MaxDist = 2000,
    V_ESPColorHex = "FFA500", -- Orange
    
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
    Accent = Color3.fromRGB(220, 50, 70),
    AccentHover = Color3.fromRGB(250, 70, 90),
    Text = Color3.fromRGB(230, 230, 240),
    SubText = Color3.fromRGB(130, 130, 150),
    Danger = Color3.fromRGB(255, 60, 60),
    Track = Color3.fromRGB(40, 40, 55),
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

-- TopBar
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
VersionBadge.Text = "v4.0"
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

-- Sidebar
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

-- Search bar
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
    btn.TextColor3 = color and T.Text or T.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Corner(btn, 8)
    Stroke(btn, T.Border, 1, 0.5)

    btn.MouseButton1Click:Connect(function()
        local original = btn.BackgroundColor3
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = T.Success or Color3.fromRGB(80,220,140)}):Play()
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

-- ═══════════ LOGIC: ESP ═══════════
local ESPDraws = {}
local function CreateESPDraws(player)
    if ESPDraws[player] then return ESPDraws[player] end
    local t = { Box = Drawing.new("Square"), Name = Drawing.new("Text"), Dist = Drawing.new("Text") }
    t.Box.Thickness = 1
    t.Name.Size = 13; t.Name.Center = true; t.Name.Outline = true
    t.Dist.Size = 12; t.Dist.Center = true; t.Dist.Outline = true
    table.insert(MM.Drawings, t.Box) table.insert(MM.Drawings, t.Name) table.insert(MM.Drawings, t.Dist)
    ESPDraws[player] = t
    return t
end

local function HideESP(d)
    if not d then return end
    d.Box.Visible = false d.Name.Visible = false d.Dist.Visible = false
end
local function RemoveESP(player)
    if not ESPDraws[player] then return end
    local d = ESPDraws[player]
    pcall(function() d.Box:Remove() end) pcall(function() d.Name:Remove() end) pcall(function() d.Dist:Remove() end)
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
                        end
                    end
                end
            end
        end
    end
end

-- Vehicle ESP
local VehicleDraws = {}
local VehicleSeats = {}
local function RegisterSeat(seat) if VehicleSeats[seat] then return end local model = seat:FindFirstAncestorOfClass("Model") or seat:FindFirstAncestorOfClass("Folder") if model then VehicleSeats[seat] = model end end
for _, inst in ipairs(WS:GetDescendants()) do if inst:IsA("VehicleSeat") then RegisterSeat(inst) end end
WS.DescendantAdded:Connect(function(inst) if inst:IsA("VehicleSeat") then RegisterSeat(inst) end end)

local function CreateVehicleDraw(model)
    if VehicleDraws[model] then return VehicleDraws[model] end
    local t = {Box = Drawing.new("Square"), Name = Drawing.new("Text"), Dist = Drawing.new("Text")}
    t.Box.Thickness = 1
    t.Name.Size = 13; t.Name.Center = true; t.Name.Outline = true
    t.Dist.Size = 12; t.Dist.Center = true; t.Dist.Outline = true
    table.insert(MM.Drawings, t.Box) table.insert(MM.Drawings, t.Name) table.insert(MM.Drawings, t.Dist)
    VehicleDraws[model] = t
    return t
end

local function RenderVehicleESP()
    if not Config.V_ESP then for model, d in pairs(VehicleDraws) do d.Box.Visible = false d.Name.Visible = false d.Dist.Visible = false end return end
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
                    if d3 > Config.V_ESP_MaxDist then d.Box.Visible = false d.Name.Visible = false d.Dist.Visible = false
                    else
                        local sp, on = Camera:WorldToViewportPoint(pos)
                        if not on then d.Box.Visible = false d.Name.Visible = false d.Dist.Visible = false
                        else
                            local sz = math.clamp(8000 / math.max(d3, 1), 24, 300)
                            d.Box.Visible = Config.V_ESP_Box
                            if d.Box.Visible then d.Box.Size = Vector2.new(sz, sz) d.Box.Position = Vector2.new(sp.X - sz / 2, sp.Y - sz / 2) d.Box.Color = ESPColorVehicle end
                            d.Name.Visible = Config.V_ESP_Name
                            if d.Name.Visible then d.Name.Text = model.Name d.Name.Position = Vector2.new(sp.X, sp.Y - sz / 2 - 18) d.Name.Color = ESPColorVehicle end
                            d.Dist.Visible = Config.V_ESP_Dist
                            if d.Dist.Visible then d.Dist.Text = tostring(math.floor(d3)) .. "m" d.Dist.Position = Vector2.new(sp.X, sp.Y + sz / 2 + 2) d.Dist.Color = ESPColorVehicle end
                        end
                    end
                end
            end
        end
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

-- ═══════════ LOGIC: PLAYER ACTIONS ═══════════
local selectedPlayer = nil
local actionMenuFrame = nil

local function OpenActions(p)
    selectedPlayer = p
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

-- ═══════════ UI BINDINGS (Заполняем страницы) ═══════════

-- Aimbot Tab
CreateToggle(Pages["Aimbot"], "Silent Aim (Hits Head)", Config.SilentAim, function(v) Config.SilentAim = v end)
CreateSlider(Pages["Aimbot"], "Silent FOV", 50, 500, Config.SilentFOV, function(v) Config.SilentFOV = v end)
CreateSlider(Pages["Aimbot"], "Silent Max Dist", 100, 3000, Config.SilentMaxDist, function(v) Config.SilentMaxDist = v end)

CreateToggle(Pages["Aimbot"], "Visual Aim (Hold AIM)", Config.AimEnabled, function(v) Config.AimEnabled = v end)
CreateSlider(Pages["Aimbot"], "Visual FOV", 50, 500, Config.AimFOV, function(v) Config.AimFOV = v end)
CreateSlider(Pages["Aimbot"], "Visual Smooth x100", 1, 100, Config.AimSmooth * 100, function(v) Config.AimSmooth = v / 100 end)
CreateToggle(Pages["Aimbot"], "Show Aim FOV", Config.ShowFOV, function(v) Config.ShowFOV = v end)

-- Visuals Tab
CreateToggle(Pages["Visuals"], "ESP Master (Players)", Config.ESP, function(v) Config.ESP = v end)
CreateToggle(Pages["Visuals"], " - Box", Config.ESP_Box, function(v) Config.ESP_Box = v end)
CreateToggle(Pages["Visuals"], " - Name", Config.ESP_Name, function(v) Config.ESP_Name = v end)
CreateToggle(Pages["Visuals"], " - Distance", Config.ESP_Dist, function(v) Config.ESP_Dist = v end)
CreateSlider(Pages["Visuals"], "Player Max Dist", 100, 5000, Config.ESP_MaxDist, function(v) Config.ESP_MaxDist = v end)
CreateTextbox(Pages["Visuals"], "Player ESP Color (Hex)", "00F0FF", Config.ESPColorHex, function(v)
    Config.ESPColorHex = v
    ESPColorPlayer = ParseHex(v, ESPColorPlayer)
end)

CreateToggle(Pages["Visuals"], "Vehicle ESP Master", Config.V_ESP, function(v) Config.V_ESP = v end)
CreateToggle(Pages["Visuals"], " - Box", Config.V_ESP_Box, function(v) Config.V_ESP_Box = v end)
CreateToggle(Pages["Visuals"], " - Name", Config.V_ESP_Name, function(v) Config.V_ESP_Name = v end)
CreateToggle(Pages["Visuals"], " - Distance", Config.V_ESP_Dist, function(v) Config.V_ESP_Dist = v end)
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

-- Movement Tab
CreateToggle(Pages["Movement"], "Speed Hack", Config.SpeedOn, function(v) Config.SpeedOn = v ApplySpeed() end)
CreateSlider(Pages["Movement"], "Speed Value", 16, 200, Config.SpeedValue, function(v) Config.SpeedValue = v if Config.SpeedOn then ApplySpeed() end end)
CreateToggle(Pages["Movement"], "Infinite Jump", Config.InfJump, function(v) Config.InfJump = v ApplyInfJump() end)
CreateToggle(Pages["Movement"], "Noclip", Config.Noclip, function(v) Config.Noclip = v ApplyNoclip() end)

CreateToggle(Pages["Movement"], "Fly (Mobile Joystick)", Config.Fly, function(v)
    Config.Fly = v
    ApplyFly()
    -- Показываем джойстик
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

-- Teleport Tab
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

-- Players Tab
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

-- Misc Tab
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

-- Экранная кнопка AIM
local AimBtn = Instance.new("TextButton")
AimBtn.Size = UDim2.new(0, 60, 0, 60) AimBtn.Position = UDim2.new(1, -80, 0.7, 0)
AimBtn.BackgroundColor3 = T.Accent AimBtn.BackgroundTransparency = 0.2
AimBtn.Text = "AIM" AimBtn.TextColor3 = T.Text AimBtn.Font = Enum.Font.GothamBold AimBtn.TextSize = 16
AimBtn.BorderSizePixel = 0 AimBtn.ZIndex = 101 AimBtn.Parent = ScreenGui
Corner(AimBtn, 30) Stroke(AimBtn, T.Text, 1.5, 0.4)
AimBtn.MouseButton1Down:Connect(function() VisualAiming = true end)
AimBtn.MouseButton1Up:Connect(function() VisualAiming = false end)
AimBtn.MouseLeave:Connect(function() VisualAiming = false end)

-- Float
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 50, 0, 50) FloatBtn.Position = UDim2.new(0, 15, 0.5, -25)
FloatBtn.BackgroundColor3 = T.Accent FloatBtn.Text = "M" FloatBtn.TextColor3 = T.Text
FloatBtn.Font = Enum.Font.GothamBold FloatBtn.TextSize = 20 FloatBtn.BorderSizePixel = 0 FloatBtn.Active = true
FloatBtn.Draggable = true FloatBtn.Parent = ScreenGui
Corner(FloatBtn, 25) Stroke(FloatBtn, T.Text, 1.5, 0.4)

FloatBtn.MouseButton1Click:Connect(function() Main.Visible = true FloatBtn.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false FloatBtn.Visible = true end)
UnloadBtn.MouseButton1Click:Connect(function() getgenv().MeowUIUnload() end)

-- Main Loop (Renders everything)
RunService:BindToRenderStep("MeowRender", Enum.RenderPriority.Camera.Value + 2, function()
    OnRender()
    RenderESP()
    RenderVehicleESP()
end)

task.spawn(function() task.wait(0.1) SelectTab("Aimbot") end)
Main.Visible = true

print("[MeowUI] FULL RELEASE Loaded.")
