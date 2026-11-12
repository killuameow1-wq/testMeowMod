-- // MEOWMOD | V1.8 // Full replace of V1.7. Fixes only, no new features.
-- Fixes: prediction + target score weight + real switch cooldown + cached aim pos
--        tp double offset + capture team check + real TP_Delay
--        bypass human hit-rate + mt nil guard + namecall restore on unload
--        lazy bones + LocalAlive state + mobile offscreen margin + config dead keys

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CollSvc = game:GetService("CollectionService")
local Http = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Camera = WS.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

-- ═══════════════ CONFIG ═══════════════
local CONFIG_PATH = "MeowMod_V1.json"
local function HasFS() return typeof(writefile) == "function" and typeof(readfile) == "function" end

local DefaultConfig = {
    SilentAim = false,
    FOV = 260, MaxDistance = 5000,
    StrictFOV = true,
    PredictionMultiplier = 1.0,
    Headshot = false, WallCheck = false,
    TeamFilter = "all",
    Bypass = false,
    ESP = false, ESP_Line = false, ESP_Box = false,
    ESP_Name = false, ESP_Dist = false, ESP_HP = false,
    ESP_Skeleton = false, ESP_Offscreen = false, ESP_DistBar = false,
    V_ESP = false, V_ESP_Box = false, V_ESP_Name = false, V_ESP_Dist = false,
    V_ESP_MaxDist = 5000,
    HitboxExpander = false, HitboxSize = 6,
    Crosshair = false, CH_Size = 12,
    TP_PlayerOffset = 5, TP_SafeDrop = 2,
    TP_DropToGround = true,
    TP_Delay = 0.15,
    ColorNeon = Color3.fromRGB(0, 240, 255),
    ColorBg = Color3.fromRGB(10, 10, 14),
    ColorPanel = Color3.fromRGB(18, 18, 24),
    ColorVehicle = Color3.fromRGB(255, 165, 0),
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

-- ═══════════════ LOGGER ═══════════════
local ErrorLogs = {}
local LogBox = nil
local LogFilter = "all"
local LogCounters = {}
local LogChipLabels = {}
local LOG_COLORS = {
    AIM = Color3.fromRGB(255,100,100), ESP = Color3.fromRGB(100,200,255),
    VEH = Color3.fromRGB(255,165,0), AI = Color3.fromRGB(180,120,255),
    TP = Color3.fromRGB(120,255,180), CONFIG = Color3.fromRGB(0,240,200),
    SYS = Color3.fromRGB(255,200,50),
}
local function LogColor(cat) return LOG_COLORS[cat] or Color3.fromRGB(200,200,200) end

local function LogError(msg, cat)
    cat = cat or "SYS"
    local line = "["..os.date("%H:%M:%S").."] ["..cat.."] "..tostring(msg)
    table.insert(ErrorLogs, {text = line, cat = cat})
    while #ErrorLogs > 400 do table.remove(ErrorLogs, 1) end
    LogCounters[cat] = (LogCounters[cat] or 0) + 1
    if LogChipLabels[cat] then LogChipLabels[cat].Text = cat..": "..LogCounters[cat] end
    if LogBox then
        pcall(function()
            if LogFilter ~= "all" and LogFilter ~= cat then return end
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1,0,0,18); tl.BackgroundTransparency = 1
            tl.Text = line; tl.TextSize = 11
            tl.TextXAlignment = Enum.TextXAlignment.Left
            tl.Font = Enum.Font.Code
            tl.TextColor3 = LogColor(cat)
            tl.Parent = LogBox
        end)
    end
end

local function RebuildLogs()
    if not LogBox then return end
    for _, v in pairs(LogBox:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    for _, e in ipairs(ErrorLogs) do
        if LogFilter == "all" or LogFilter == e.cat then
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1,0,0,18); tl.BackgroundTransparency = 1
            tl.Text = e.text; tl.TextSize = 11
            tl.TextXAlignment = Enum.TextXAlignment.Left
            tl.Font = Enum.Font.Code
            tl.TextColor3 = LogColor(e.cat)
            tl.Parent = LogBox
        end
    end
end

if PG:FindFirstChild("MeowMod") then PG.MeowMod:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeowMod"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PG

local Connections, Drawings = {}, {}
local function AddConn(c) table.insert(Connections, c) end
local function AddDraw(d) table.insert(Drawings, d) end

-- ═══════════════ UI ═══════════════
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 720, 0, 560)
Main.Position = UDim2.new(0.5, -360, 0.5, -280)
Main.BackgroundColor3 = Config.ColorBg
Main.BackgroundTransparency = 0.02
Main.BorderSizePixel = 0
Main.Active = true; Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
local MS = Instance.new("UIStroke", Main)
MS.Color = Config.ColorNeon; MS.Thickness = 2; MS.Transparency = 0.2

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 64)
Header.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
Header.BackgroundTransparency = 0.05
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -300, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "MEOW | V1.8"
TitleLabel.TextColor3 = Config.ColorNeon
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 19
TitleLabel.Parent = Header

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 120, 0, 34)
StatusLabel.Position = UDim2.new(1, -210, 0, 15)
StatusLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
StatusLabel.BackgroundTransparency = 0.4
StatusLabel.Text = "AI: READY"
StatusLabel.TextColor3 = Color3.fromRGB(120,120,120)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 12
StatusLabel.Parent = Header
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 8)

local PerfLabel = Instance.new("TextLabel")
PerfLabel.Size = UDim2.new(0, 100, 0, 34)
PerfLabel.Position = UDim2.new(1, -320, 0, 15)
PerfLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
PerfLabel.BackgroundTransparency = 0.4
PerfLabel.Text = "FPS: --"
PerfLabel.TextColor3 = Color3.fromRGB(180,180,180)
PerfLabel.Font = Enum.Font.GothamBold
PerfLabel.TextSize = 12
PerfLabel.Parent = Header
Instance.new("UICorner", PerfLabel).CornerRadius = UDim.new(0, 8)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 34, 0, 34)
CloseBtn.Position = UDim2.new(1, -44, 0, 15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseBtn.Text = "×"; CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 18
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 34, 0, 34)
MinBtn.Position = UDim2.new(1, -86, 0, 15)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
MinBtn.Text = "-"; MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 18
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -40, 0, 40)
TabBar.Position = UDim2.new(0, 20, 0, 74)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main
local TL = Instance.new("UIListLayout", TabBar)
TL.FillDirection = Enum.FillDirection.Horizontal
TL.Padding = UDim.new(0, 8)
TL.SortOrder = Enum.SortOrder.LayoutOrder

local Pages = {}
local function CreateTab(name, order)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 96, 1, 0)
    Btn.BackgroundColor3 = Color3.fromRGB(25,25,38)
    Btn.BackgroundTransparency = 0.15
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(160,160,170)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.LayoutOrder = order
    Btn.AutoButtonColor = false
    Btn.Parent = TabBar
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    local Ind = Instance.new("Frame")
    Ind.Size = UDim2.new(0.6, 0, 0, 3)
    Ind.Position = UDim2.new(0.2, 0, 1, -3)
    Ind.BackgroundColor3 = Config.ColorNeon
    Ind.Visible = false
    Ind.BorderSizePixel = 0
    Ind.Parent = Btn
    Instance.new("UICorner", Ind).CornerRadius = UDim.new(1, 0)

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, -40, 1, -140)
    Page.Position = UDim2.new(0, 20, 0, 124)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Config.ColorNeon
    Page.Parent = Main
    local L = Instance.new("UIListLayout", Page)
    L.Padding = UDim.new(0, 8)
    L.SortOrder = Enum.SortOrder.LayoutOrder
    Pages[name] = Page

    Btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        for _, b in pairs(TabBar:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = Color3.fromRGB(25,25,38)
                b.BackgroundTransparency = 0.15
                b.TextColor3 = Color3.fromRGB(160,160,170)
                local ind = b:FindFirstChildOfClass("Frame")
                if ind then ind.Visible = false end
            end
        end
        Page.Visible = true
        Btn.BackgroundColor3 = Config.ColorNeon
        Btn.BackgroundTransparency = 0
        Btn.TextColor3 = Color3.fromRGB(0,0,0)
        Ind.Visible = true
    end)
end

local SaveDebounce = 0
local function QueueSave()
    SaveDebounce = SaveDebounce + 1
    local myId = SaveDebounce
    task.delay(0.5, function() if myId == SaveDebounce then SaveConfig() end end)
end

local function CreateToggle(parent, name, def, cb, cfgKey)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 44)
    Btn.BackgroundColor3 = Config.ColorPanel
    Btn.BackgroundTransparency = 0.35
    Btn.Text = ""; Btn.AutoButtonColor = false
    Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke", Btn)
    st.Color = Color3.fromRGB(45,45,60); st.Thickness = 1; st.Transparency = 0.4
    local TLbl = Instance.new("TextLabel")
    TLbl.Size = UDim2.new(1, -80, 1, 0)
    TLbl.Position = UDim2.new(0, 16, 0, 0)
    TLbl.BackgroundTransparency = 1
    TLbl.Text = name
    TLbl.TextColor3 = Color3.fromRGB(225,225,230)
    TLbl.TextXAlignment = Enum.TextXAlignment.Left
    TLbl.Font = Enum.Font.GothamMedium
    TLbl.TextSize = 13
    TLbl.Parent = Btn
    local Ind = Instance.new("Frame")
    Ind.Size = UDim2.new(0, 40, 0, 22)
    Ind.Position = UDim2.new(1, -54, 0.5, -11)
    Ind.BackgroundColor3 = def and Config.ColorNeon or Color3.fromRGB(55,55,70)
    Ind.Parent = Btn
    Instance.new("UICorner", Ind).CornerRadius = UDim.new(1, 0)
    local Circ = Instance.new("Frame")
    Circ.Size = UDim2.new(0, 18, 0, 18)
    Circ.Position = def and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    Circ.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Circ.Parent = Ind
    Instance.new("UICorner", Circ).CornerRadius = UDim.new(1, 0)
    local State = def
    AddConn(Btn.MouseButton1Click:Connect(function()
        State = not State
        TweenService:Create(Ind, TweenInfo.new(0.15), {
            BackgroundColor3 = State and Config.ColorNeon or Color3.fromRGB(55,55,70)
        }):Play()
        TweenService:Create(Circ, TweenInfo.new(0.15), {
            Position = State and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        }):Play()
        if cfgKey then Config[cfgKey] = State end
        if cb then cb(State) end
        QueueSave()
    end))
end

local function CreateSlider(parent, name, mn, mx, def, cb, cfgKey)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, 0, 0, 54)
    F.BackgroundColor3 = Config.ColorPanel
    F.BackgroundTransparency = 0.35
    F.Parent = parent
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)
    local TLbl = Instance.new("TextLabel")
    TLbl.Size = UDim2.new(1, -30, 0, 22)
    TLbl.Position = UDim2.new(0, 16, 0, 6)
    TLbl.BackgroundTransparency = 1
    TLbl.Text = name..": "..tostring(def)
    TLbl.TextColor3 = Color3.fromRGB(225,225,230)
    TLbl.TextXAlignment = Enum.TextXAlignment.Left
    TLbl.Font = Enum.Font.GothamMedium
    TLbl.TextSize = 13
    TLbl.Parent = F
    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(1, -30, 0, 6)
    Bg.Position = UDim2.new(0, 16, 0, 36)
    Bg.BackgroundColor3 = Color3.fromRGB(40,40,50)
    Bg.Parent = F
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((def-mn)/(mx-mn), 0, 1, 0)
    Fill.BackgroundColor3 = Config.ColorNeon
    Fill.Parent = Bg
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    local Hit = Instance.new("TextButton")
    Hit.Size = UDim2.new(1, 0, 4, 0)
    Hit.Position = UDim2.new(0, 0, -1.5, 0)
    Hit.BackgroundTransparency = 1
    Hit.Text = ""
    Hit.Parent = Bg
    local dragging = false
    local function Update(input)
        local pos = math.clamp((input.Position.X - Bg.AbsolutePosition.X)/Bg.AbsoluteSize.X, 0, 1)
        local v = math.floor(mn + (mx-mn)*pos)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        TLbl.Text = name..": "..tostring(v)
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
end

local function CreateButton(parent, name, cb)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 44)
    Btn.BackgroundColor3 = Color3.fromRGB(30,30,45)
    Btn.Text = name; Btn.TextColor3 = Config.ColorNeon
    Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13
    Btn.AutoButtonColor = false
    Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)
    Btn.MouseButton1Click:Connect(function()
        Btn.BackgroundColor3 = Color3.fromRGB(0,255,150)
        task.wait(0.2)
        Btn.BackgroundColor3 = Color3.fromRGB(30,30,45)
        if cb then cb() end
    end)
end

local function CreateCycle(parent, name, options, default, cb, cfgKey)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 44)
    Btn.BackgroundColor3 = Color3.fromRGB(30,30,45)
    Btn.Text = name..": "..default
    Btn.TextColor3 = Config.ColorNeon
    Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13
    Btn.AutoButtonColor = false
    Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)
    local idx = 1
    for i, o in ipairs(options) do if o == default then idx = i break end end
    Btn.MouseButton1Click:Connect(function()
        idx = idx + 1; if idx > #options then idx = 1 end
        Btn.Text = name..": "..options[idx]
        if cfgKey then Config[cfgKey] = options[idx] end
        if cb then cb(options[idx]) end
        QueueSave()
    end)
end

CreateTab("Combat", 1); CreateTab("Visuals", 2); CreateTab("Players", 3)
CreateTab("Vehicles", 4); CreateTab("Teleport", 5); CreateTab("Logs", 6)
task.spawn(function()
    task.wait(0.1)
    for _, b in pairs(TabBar:GetChildren()) do
        if b:IsA("TextButton") and b.Text == "Combat" then
            Pages["Combat"].Visible = true
            b.BackgroundColor3 = Config.ColorNeon
            b.BackgroundTransparency = 0
            b.TextColor3 = Color3.fromRGB(0,0,0)
            local ind = b:FindFirstChildOfClass("Frame")
            if ind then ind.Visible = true end
        end
    end
end)

-- ═══════════════ TELEPORT v8 — ground-safe, single offset, team-aware capture ═══════════════
local function GetGroundY(pos, excludeChar)
    local rp = RaycastParams.new()
    local filter = {}
    if excludeChar then table.insert(filter, excludeChar) end
    rp.FilterDescendantsInstances = filter
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local hit = WS:Raycast(pos + Vector3.new(0, 500, 0), Vector3.new(0, -1000, 0), rp)
    if hit then return hit.Position.Y end
    return nil
end

local function SafeTeleport(pos, label)
    local c = LP.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then LogError("No HRP", "TP"); return false end

    local targetY = pos.Y
    if Config.TP_DropToGround then
        local groundY = GetGroundY(pos, c)
        if groundY then
            targetY = groundY
        end
    end

    local drop = Config.TP_SafeDrop or 2
    local finalPos = Vector3.new(pos.X, targetY + drop, pos.Z)

    hrp.CFrame = CFrame.new(finalPos)
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    if Config.TP_Delay and Config.TP_Delay > 0 then
        task.wait(Config.TP_Delay)
    end
    LogError("TP -> "..label.." (Y "..math.floor(targetY + drop)..")", "TP")
    return true
end

local function TPBase()
    local myTeam = LP.Team and LP.Team.Name:lower() or ""
    local myColor = LP.TeamColor and LP.TeamColor.Color or nil
    local best, bestDist = nil, math.huge
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position or Vector3.zero
    for _, o in pairs(WS:GetDescendants()) do
        if o:IsA("SpawnLocation") and o.Enabled then
            local matches = false
            if myColor and o.BrickColor.Color == myColor then matches = true end
            if not matches and myTeam ~= "" then
                local path = o:GetFullName():lower()
                if path:find(myTeam) then matches = true end
            end
            if not matches and o.Neutral and myTeam == "" then matches = true end
            if matches then
                local d = (myPos - o.Position).Magnitude
                if d < bestDist then bestDist = d; best = {pos = o.Position, name = o:GetFullName()} end
            end
        end
    end
    if best then return SafeTeleport(best.pos, "Base(spawn) -> "..best.name) end
    local bestName, bestNameY = nil, -math.huge
    for _, o in pairs(WS:GetDescendants()) do
        if o and (o:IsA("BasePart") or o:IsA("Model")) then
            local n = o.Name:lower()
            if n:find("base") or n:find("spawn") or n:find("barracks") or n:find("hq") then
                local path = o:GetFullName():lower()
                local bad = path:find("oil") or path:find("storage") or path:find("tank")
                    or path:find("shop") or path:find("menu") or path:find("exchang")
                    or path:find("airdrop") or path:find("cargo") or path:find("helicopter") or path:find("heli")
                if not bad and myTeam ~= "" then
                    if path:find("red") and not myTeam:find("red") then bad = true end
                    if path:find("blue") and not myTeam:find("blue") then bad = true end
                    if path:find("green") and not myTeam:find("green") then bad = true end
                    if path:find("yellow") and not myTeam:find("yellow") then bad = true end
                end
                if not bad then
                    local p
                    if o:IsA("BasePart") then p = o.Position
                    else
                        local pr = o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")
                        if pr then p = pr.Position end
                    end
                    if p and p.Y > bestNameY then bestNameY = p.Y; bestName = {pos = p, name = path} end
                end
            end
        end
    end
    if bestName then return SafeTeleport(bestName.pos, "Base(name) -> "..bestName.name) end
    LogError("Base not found (team="..myTeam..")", "TP")
    return false
end

local function TPAirdrop()
    local function FindFirst(keyword)
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local myPos = myHrp and myHrp.Position or Vector3.zero
        local best, bestScore = nil, -math.huge
        for _, o in pairs(WS:GetDescendants()) do
            if o and (o:IsA("BasePart") or o:IsA("Model")) then
                local n = o.Name:lower()
                if n:find(keyword) then
                    local path = o:GetFullName():lower()
                    local bad = path:find("menu") or path:find("exchang") or path:find("shop")
                        or path:find("oil") or path:find("storage") or path:find("tank")
                        or path:find("base") or path:find("spawn") or path:find("barracks")
                        or path:find("table") or path:find("chair") or path:find("trade")
                        or path:find("npc")
                    if not bad then
                        local p
                        if o:IsA("BasePart") then p = o.Position
                        else
                            local pr = o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")
                            if pr then p = pr.Position end
                        end
                        if p then
                            local score = 100
                            if n == keyword then score = score + 200 end
                            score = score + math.clamp(p.Y * 0.1, 0, 300)
                            score = score - math.clamp((myPos - p).Magnitude * 0.05, 0, 100)
                            if score > bestScore then bestScore = score; best = {pos = p, name = path} end
                        end
                    end
                end
            end
        end
        return best
    end
    local best = FindFirst("airdrop")
    if best then return SafeTeleport(best.pos, "Airdrop(airdrop) -> "..best.name) end
    best = FindFirst("crate")
    if best then return SafeTeleport(best.pos, "Airdrop(crate) -> "..best.name) end
    best = FindFirst("parachute")
    if best then return SafeTeleport(best.pos, "Airdrop(parachute) -> "..best.name) end
    LogError("Airdrop not found", "TP")
    return false
end

local function TPCrashedUAV()
    local best, bestScore = nil, -math.huge
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position or Vector3.zero
    local keywords = {"uav","drone","crashed","wreck","recon","predator","reaper"}
    for _, o in pairs(WS:GetDescendants()) do
        if o and (o:IsA("BasePart") or o:IsA("Model")) then
            local n = o.Name:lower()
            local matched = false
            for _, kw in ipairs(keywords) do
                if n:find(kw) then matched = true; break end
            end
            if matched then
                local path = o:GetFullName():lower()
                local bad = path:find("spawn") or path:find("pad") or path:find("hangar")
                    or path:find("base") or path:find("deploy") or path:find("launcher")
                    or path:find("enemyuav") or path:find("airstrike")
                if not bad then
                    local p
                    if o:IsA("BasePart") then p = o.Position
                    else
                        local pr = o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")
                        if pr then p = pr.Position end
                    end
                    if p then
                        local score = 100
                        if n:find("crashed") then score = score + 300 end
                        if n:find("wreck") then score = score + 300 end
                        if n:find("uav") then score = score + 100 end
                        if n:find("drone") then score = score + 100 end
                        if math.abs(p.Y - myPos.Y) < 50 then score = score + 50 end
                        score = score - math.clamp((myPos - p).Magnitude * 0.05, 0, 100)
                        if score > bestScore then bestScore = score; best = {pos = p, name = path} end
                    end
                end
            end
        end
    end
    if best then return SafeTeleport(best.pos, "UAV(crashed) -> "..best.name) end
    LogError("Crashed UAV not found", "TP")
    return false
end

local function TPCapture()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return false end
    local myPos = myHrp.Position
    local myTeam = LP.Team and LP.Team.Name:lower() or ""
    local best, bestScore = nil, -math.huge
    for _, o in pairs(WS:GetDescendants()) do
        if o and o:IsA("BasePart") then
            local n = o.Name:lower()
            local path = o:GetFullName():lower()
            if n:find("flag") then
                if o.Position.Y > myPos.Y + 3 then
                    local bad = path:find("spawn") or path:find("barracks")
                        or path:find("oil") or path:find("storage") or path:find("tank")
                        or path:find("menu") or path:find("exchang") or path:find("shop")
                    -- enemy base flag: reject if path mentions an enemy team name
                    if not bad and myTeam ~= "" then
                        local teams = {"red","blue","green","yellow"}
                        for _, tn in ipairs(teams) do
                            if path:find(tn) and not myTeam:find(tn) then bad = true; break end
                        end
                    end
                    if not bad then
                        local score = 500
                        if path:find("capture") then score = score + 200 end
                        if path:find("zone") then score = score + 150 end
                        if path:find("control") then score = score + 100 end
                        if score > bestScore then bestScore = score; best = {pos = o.Position, name = path} end
                    end
                end
            end
        end
    end
    if best then return SafeTeleport(best.pos, "Capture -> "..best.name) end
    LogError("Capture flag not found", "TP")
    return false
end

-- ═══════════════ UI CONTROLS ═══════════════
CreateToggle(Pages["Combat"], "Silent Aim", Config.SilentAim, nil, "SilentAim")
CreateToggle(Pages["Combat"], "Strict FOV", Config.StrictFOV, nil, "StrictFOV")
CreateToggle(Pages["Combat"], "Headshot", Config.Headshot, nil, "Headshot")
CreateToggle(Pages["Combat"], "Wall Check", Config.WallCheck, nil, "WallCheck")
CreateToggle(Pages["Combat"], "Bypass v14", Config.Bypass, nil, "Bypass")
CreateSlider(Pages["Combat"], "FOV", 50, 800, Config.FOV, nil, "FOV")
CreateSlider(Pages["Combat"], "Max Dist", 500, 5000, Config.MaxDistance, nil, "MaxDistance")
CreateSlider(Pages["Combat"], "Prediction x10", 5, 30, math.floor(Config.PredictionMultiplier*10), function(v) Config.PredictionMultiplier = v/10 end)

CreateToggle(Pages["Visuals"], "ESP", Config.ESP, nil, "ESP")
CreateToggle(Pages["Visuals"], " - Line", Config.ESP_Line, nil, "ESP_Line")
CreateToggle(Pages["Visuals"], " - Box", Config.ESP_Box, nil, "ESP_Box")
CreateToggle(Pages["Visuals"], " - Name", Config.ESP_Name, nil, "ESP_Name")
CreateToggle(Pages["Visuals"], " - Dist", Config.ESP_Dist, nil, "ESP_Dist")
CreateToggle(Pages["Visuals"], " - HP", Config.ESP_HP, nil, "ESP_HP")
CreateToggle(Pages["Visuals"], " - Skeleton", Config.ESP_Skeleton, nil, "ESP_Skeleton")
CreateToggle(Pages["Visuals"], " - Offscreen", Config.ESP_Offscreen, nil, "ESP_Offscreen")
CreateToggle(Pages["Visuals"], " - Dist Bar", Config.ESP_DistBar, nil, "ESP_DistBar")
CreateCycle(Pages["Visuals"], "Team Filter", {"all", "enemy", "my"}, Config.TeamFilter, nil, "TeamFilter")
CreateToggle(Pages["Visuals"], "Hitbox Expander", Config.HitboxExpander, function(v)
    Config.HitboxExpander = v
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = Vector3.new(2,2,1); hrp.Transparency = 1; hrp.CanCollide = true
            end
        end
    end
end, "HitboxExpander")
CreateSlider(Pages["Visuals"], "Hitbox Size", 2, 20, Config.HitboxSize, nil, "HitboxSize")
CreateToggle(Pages["Visuals"], "Crosshair", Config.Crosshair, nil, "Crosshair")
CreateSlider(Pages["Visuals"], "CH Size", 5, 30, Config.CH_Size, nil, "CH_Size")

CreateToggle(Pages["Vehicles"], "Vehicle ESP", Config.V_ESP, function(v)
    Config.V_ESP = v
    if not v then
        for model, d in pairs(VehicleESP) do
            if d.Box then pcall(function() d.Box.Visible = false end) end
            if d.Name then pcall(function() d.Name.Visible = false end) end
            if d.Dist then pcall(function() d.Dist.Visible = false end) end
        end
    end
end, "V_ESP")
CreateToggle(Pages["Vehicles"], " - Box", Config.V_ESP_Box, nil, "V_ESP_Box")
CreateToggle(Pages["Vehicles"], " - Name", Config.V_ESP_Name, nil, "V_ESP_Name")
CreateToggle(Pages["Vehicles"], " - Dist", Config.V_ESP_Dist, nil, "V_ESP_Dist")
CreateSlider(Pages["Vehicles"], "Veh Max Dist", 100, 10000, Config.V_ESP_MaxDist, nil, "V_ESP_MaxDist")

CreateToggle(Pages["Teleport"], "Drop to ground (safe)", Config.TP_DropToGround, nil, "TP_DropToGround")
CreateSlider(Pages["Teleport"], "Safe drop", 1, 20, Config.TP_SafeDrop, nil, "TP_SafeDrop")
CreateSlider(Pages["Teleport"], "TP delay x100", 0, 50, math.floor(Config.TP_Delay*100), function(v) Config.TP_Delay = v/100 end)
CreateButton(Pages["Teleport"], "TP Base", TPBase)
CreateButton(Pages["Teleport"], "TP Airdrop", TPAirdrop)
CreateButton(Pages["Teleport"], "TP Crashed UAV", TPCrashedUAV)
CreateButton(Pages["Teleport"], "TP Capture Point", TPCapture)
CreateButton(Pages["Teleport"], "TP Nearest Enemy", function()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local best, bestD = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local isEnemy = LP.Team and p.Team and p.Team ~= LP.Team
                if isEnemy or not LP.Team then
                    local d = (myHrp.Position - hrp.Position).Magnitude
                    if d < bestD then bestD = d; best = hrp end
                end
            end
        end
    end
    if best then SafeTeleport(best.Position + Vector3.new(0, 3, 0), "nearest enemy @ "..math.floor(bestD).."m")
    else LogError("No enemy", "TP") end
end)

-- ═══════════════ UTIL ═══════════════
local function DistToColor(d)
    local t = math.clamp(d/400, 0, 1)
    if d <= 100 then
        local k = d/100
        return Color3.fromRGB(math.floor(255-k*55), math.floor(60+k*120), 60)
    end
    return Color3.fromRGB(math.floor(200*(1-t)), math.floor(180+75*t), math.floor(60+80*t))
end
local function PassesTeamFilter(p)
    if Config.TeamFilter == "all" then return true end
    local myTeam = LP.Team
    if not myTeam then return true end
    if Config.TeamFilter == "my" then return p.Team == myTeam end
    if Config.TeamFilter == "enemy" then return p.Team ~= myTeam end
    return true
end

-- ═══════════════ PLAYER LIST ═══════════════
local PL = Instance.new("UIListLayout", Pages["Players"])
PL.Padding = UDim.new(0, 6)
local function UpdatePlayerList()
    for _, v in pairs(Pages["Players"]:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and PassesTeamFilter(p) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
                local Btn = Instance.new("TextButton")
                Btn.Size = UDim2.new(1, 0, 0, 36)
                Btn.BackgroundColor3 = Config.ColorPanel
                Btn.BackgroundTransparency = 0.3
                Btn.Text = "  "..p.Name.."  ["..d.."m]"
                Btn.TextColor3 = DistToColor(d)
                Btn.TextXAlignment = Enum.TextXAlignment.Left
                Btn.Font = Enum.Font.GothamMedium
                Btn.TextSize = 13
                Btn.Parent = Pages["Players"]
                Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
                Btn.MouseButton1Click:Connect(function()
                    if hrp then
                        SafeTeleport(hrp.Position + Vector3.new(Config.TP_PlayerOffset, 3, Config.TP_PlayerOffset),
                            "player "..p.Name)
                    end
                end)
            end
        end
    end
end
task.spawn(function() while task.wait(2) do UpdatePlayerList() end end)

-- ═══════════════ VEHICLES ═══════════════
local VehicleSeats = {}
local VehicleESP = {}
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
local function UnregisterSeat(seat) VehicleSeats[seat] = nil end
local function ScanAllVehicles()
    pcall(function()
        for _, inst in ipairs(CollSvc:GetTagged("VehicleSeat")) do
            if inst:IsA("VehicleSeat") then RegisterSeat(inst) end
        end
    end)
    for _, inst in ipairs(WS:GetDescendants()) do
        if inst:IsA("VehicleSeat") then RegisterSeat(inst) end
    end
end
ScanAllVehicles()
AddConn(WS.DescendantAdded:Connect(function(inst)
    if inst:IsA("VehicleSeat") then RegisterSeat(inst) end
end))
AddConn(WS.DescendantRemoving:Connect(function(inst)
    if inst:IsA("VehicleSeat") then UnregisterSeat(inst) end
end))
task.spawn(function() while task.wait(5) do if Config.V_ESP then pcall(ScanAllVehicles) end end end)

local function CollectUniqueModels()
    local seen, list = {}, {}
    for _, model in pairs(VehicleSeats) do
        if model and model.Parent and not seen[model] then
            seen[model] = true
            table.insert(list, model)
        end
    end
    return list
end

local VL = Instance.new("UIListLayout", Pages["Vehicles"])
VL.Padding = UDim.new(0, 6)
local function UpdateVehicleList()
    for _, v in pairs(Pages["Vehicles"]:GetChildren()) do
        if v:IsA("TextButton") and v:GetAttribute("isVeh") then v:Destroy() end
    end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local models = CollectUniqueModels()
    table.sort(models, function(a, b)
        local pa = ModelAnchor(a); local pb = ModelAnchor(b)
        if not pa or not pb then return false end
        return (myHrp.Position - pa.Position).Magnitude < (myHrp.Position - pb.Position).Magnitude
    end)
    for _, model in ipairs(models) do
        local anchor = ModelAnchor(model)
        if anchor then
            local d = math.floor((myHrp.Position - anchor.Position).Magnitude)
            local Btn = Instance.new("TextButton")
            Btn:SetAttribute("isVeh", true)
            Btn.Size = UDim2.new(1, 0, 0, 36)
            Btn.BackgroundColor3 = Config.ColorPanel
            Btn.BackgroundTransparency = 0.3
            Btn.Text = "  "..model.Name.."  ["..d.."m]"
            Btn.TextColor3 = DistToColor(d)
            Btn.TextXAlignment = Enum.TextXAlignment.Left
            Btn.Font = Enum.Font.GothamMedium
            Btn.TextSize = 13
            Btn.Parent = Pages["Vehicles"]
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
            Btn.MouseButton1Click:Connect(function()
                if anchor and anchor.Parent then
                    SafeTeleport(anchor.Position + Vector3.new(0, 6, 0), "vehicle "..model.Name)
                end
            end)
        end
    end
end
task.spawn(function() while task.wait(3) do UpdateVehicleList() end end)

-- ═══════════════ LOGS CHIPS ═══════════════
local ChipsBar = Instance.new("Frame")
ChipsBar.Size = UDim2.new(1, 0, 0, 32)
ChipsBar.BackgroundTransparency = 1
ChipsBar.Parent = Pages["Logs"]
local ChipsLayout = Instance.new("UIListLayout", ChipsBar)
ChipsLayout.FillDirection = Enum.FillDirection.Horizontal
ChipsLayout.Padding = UDim.new(0, 4)
ChipsLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function MakeChip(cat, order)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 66, 1, 0)
    Btn.BackgroundColor3 = Color3.fromRGB(30,30,45)
    Btn.Text = cat..": 0"
    Btn.TextColor3 = LogColor(cat)
    Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 11
    Btn.AutoButtonColor = false
    Btn.LayoutOrder = order
    Btn.Parent = ChipsBar
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    LogChipLabels[cat] = Btn
    Btn.MouseButton1Click:Connect(function()
        LogFilter = (LogFilter == cat) and "all" or cat
        RebuildLogs()
        for _, c in pairs(LogChipLabels) do c.BackgroundColor3 = Color3.fromRGB(30,30,45) end
        if LogFilter ~= "all" and LogChipLabels[LogFilter] then
            LogChipLabels[LogFilter].BackgroundColor3 = Color3.fromRGB(0,100,120)
        end
    end)
end
MakeChip("AIM", 1); MakeChip("ESP", 2); MakeChip("AI", 3)
MakeChip("TP", 4); MakeChip("CONFIG", 5); MakeChip("SYS", 6)

LogBox = Instance.new("ScrollingFrame")
LogBox.Size = UDim2.new(1, 0, 1, -80)
LogBox.Position = UDim2.new(0, 0, 0, 38)
LogBox.BackgroundTransparency = 1
LogBox.CanvasSize = UDim2.new(0, 0, 0, 0)
LogBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogBox.ScrollBarThickness = 2
LogBox.ScrollBarImageColor3 = Config.ColorNeon
LogBox.Parent = Pages["Logs"]
Instance.new("UIListLayout", LogBox).Padding = UDim.new(0, 4)

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(1, 0, 0, 35)
CopyBtn.Position = UDim2.new(0, 0, 1, -35)
CopyBtn.BackgroundColor3 = Color3.fromRGB(0,200,100)
CopyBtn.Text = "Copy Logs"; CopyBtn.TextColor3 = Color3.fromRGB(255,255,255)
CopyBtn.Font = Enum.Font.GothamBold; CopyBtn.TextSize = 13
CopyBtn.Parent = Pages["Logs"]
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 8)
CopyBtn.MouseButton1Click:Connect(function()
    local parts = {}
    for _, e in ipairs(ErrorLogs) do
        if LogFilter == "all" or LogFilter == e.cat then
            table.insert(parts, e.text)
        end
    end
    if setclipboard then
        setclipboard(table.concat(parts, "\n"))
        CopyBtn.Text = "Copied!"
        task.wait(1); CopyBtn.Text = "Copy Logs"
    end
end)

-- ═══════════════ UNLOAD ═══════════════
-- Saved namecall state for clean restore on unload
local __saved_mt = nil
local __saved_nc = nil

local function RestoreNamecall()
    if __saved_mt and __saved_nc then
        pcall(function()
            setreadonly(__saved_mt, false)
            __saved_mt.__namecall = __saved_nc
            setreadonly(__saved_mt, true)
        end)
        __saved_mt = nil
        __saved_nc = nil
    end
end

local function Unload()
    for _, c in pairs(Connections) do
        if typeof(c) == "RBXScriptConnection" then pcall(function() c:Disconnect() end) end
    end
    for _, d in pairs(Drawings) do pcall(function() d:Remove() end) end
    for _, p in pairs(Players:GetPlayers()) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Size = Vector3.new(2,2,1); hrp.Transparency = 1; hrp.CanCollide = true
        end
    end
    RestoreNamecall()
    pcall(function()
        RunService:UnbindFromRenderStep("MeowESP")
        RunService:UnbindFromRenderStep("MeowLogic")
    end)
    ScreenGui:Destroy()
    Connections = {}
    Drawings = {}
end
AddConn(CloseBtn.MouseButton1Click:Connect(Unload))

local min = false
AddConn(MinBtn.MouseButton1Click:Connect(function()
    min = not min
    Main.Size = min and UDim2.new(0,720,0,64) or UDim2.new(0,720,0,560)
    for _, v in pairs(Main:GetChildren()) do
        if v:IsA("ScrollingFrame") or v == TabBar then
            v.Visible = not min
        end
    end
end))

-- ═══════════════ CROSSHAIR ═══════════════
local CH1 = Drawing.new("Line")
local CH2 = Drawing.new("Line")
CH1.Thickness = 2; CH2.Thickness = 2
CH1.Color = Config.ColorNeon; CH2.Color = Config.ColorNeon
AddDraw(CH1); AddDraw(CH2)

-- ═══════════════ ESP ═══════════════
local ESP = {}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.Transparency = 0.8
FOVCircle.Color = Config.ColorNeon; FOVCircle.Filled = false
AddDraw(FOVCircle)

local BONE_PAIRS = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local function ForceHide(d)
    if not d then return end
    if d.Line then d.Line.Visible = false end
    if d.Box then d.Box.Visible = false end
    if d.NameBg then d.NameBg.Visible = false end
    if d.Name then d.Name.Visible = false end
    if d.Dist then d.Dist.Visible = false end
    if d.HpBg then d.HpBg.Visible = false end
    if d.HpBar then d.HpBar.Visible = false end
    if d.OffArrow then d.OffArrow.Visible = false end
    if d.DistBarBg then d.DistBarBg.Visible = false end
    if d.DistBarFg then d.DistBarFg.Visible = false end
    if d.Bones then for _, b in pairs(d.Bones) do pcall(function() b.Visible = false end) end end
end

local ESP_FAILS = {}

-- lazy bone creation: only when skeleton is enabled
local function EnsureBones(d)
    if d.BonesReady then return end
    for i = 1, #BONE_PAIRS do
        local ok, b = pcall(function() return Drawing.new("Line") end)
        if ok and b then
            b.Thickness = 1
            AddDraw(b)
            d.Bones[i] = b
        end
    end
    d.BonesReady = true
end

local function CreateDraw(player)
    if ESP[player] then return ESP[player] end
    local ok, tbl = pcall(function()
        local t = {
            Line = Drawing.new("Line"), Box = Drawing.new("Square"),
            NameBg = Drawing.new("Square"), Name = Drawing.new("Text"),
            Dist = Drawing.new("Text"), HpBg = Drawing.new("Square"),
            HpBar = Drawing.new("Square"), OffArrow = Drawing.new("Triangle"),
            DistBarBg = Drawing.new("Square"), DistBarFg = Drawing.new("Square"),
            Bones = {}, BonesReady = false,
        }
        return t
    end)
    if not ok or not tbl then
        ESP_FAILS[player] = (ESP_FAILS[player] or 0) + 1
        if ESP_FAILS[player] == 1 then LogError("CreateDraw fail "..tostring(player), "ESP") end
        return nil
    end
    tbl.Line.Thickness = 1; tbl.Box.Thickness = 1
    tbl.NameBg.Filled = true; tbl.NameBg.Color = Color3.fromRGB(15,15,22); tbl.NameBg.Transparency = 0.7
    tbl.Name.Size = 13; tbl.Name.Center = true; tbl.Name.Outline = true
    tbl.Dist.Size = 12; tbl.Dist.Center = true; tbl.Dist.Outline = true
    tbl.HpBg.Filled = true; tbl.HpBg.Color = Color3.fromRGB(0,0,0)
    tbl.HpBar.Filled = true; tbl.OffArrow.Filled = true
    tbl.DistBarBg.Filled = true; tbl.DistBarFg.Filled = true
    for k, v in pairs(tbl) do if k ~= "Bones" and k ~= "BonesReady" then AddDraw(v) end end
    ESP[player] = tbl
    return tbl
end
local function RemoveDraw(player)
    if ESP[player] then
        for k, v in pairs(ESP[player]) do
            if k == "Bones" then
                for _, b in pairs(v) do pcall(function() b:Remove() end) end
            elseif k ~= "BonesReady" then
                pcall(function() v:Remove() end)
            end
        end
        ESP[player] = nil
    end
end
AddConn(Players.PlayerRemoving:Connect(RemoveDraw))

local function OffscreenArrowPos(sp, margin)
    local vp = Camera.ViewportSize
    local cx, cy = vp.X/2, vp.Y/2
    local dx, dy = sp.X - cx, sp.Y - cy
    if math.abs(dx) < 0.001 and math.abs(dy) < 0.001 then dx = 1 end
    local tx = (cx - margin) / math.max(math.abs(dx), 0.0001)
    local ty = (cy - margin) / math.max(math.abs(dy), 0.0001)
    local t = math.min(tx, ty)
    return Vector2.new(cx + dx*t, cy + dy*t)
end

local function GetScreenBox(char, hrp)
    local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
    if ok and cf and size then
        local tS, tOn = Camera:WorldToViewportPoint(cf.Position + Vector3.new(0, size.Y/2, 0))
        local bS, bOn = Camera:WorldToViewportPoint(cf.Position - Vector3.new(0, size.Y/2, 0))
        local lS, lOn = Camera:WorldToViewportPoint(cf.Position - Vector3.new(size.X/2, 0, 0))
        local rS, rOn = Camera:WorldToViewportPoint(cf.Position + Vector3.new(size.X/2, 0, 0))
        if tOn and bOn and lOn and rOn then
            local w = math.abs(rS.X - lS.X)
            local h = math.abs(bS.Y - tS.Y)
            if w > 0 and h > 0 and w < 800 and h < 800 then
                return {x = lS.X, y = tS.Y, w = w, h = h}
            end
        end
    end
    local head = char:FindFirstChild("Head")
    local lLeg = char:FindFirstChild("LeftFoot") or char:FindFirstChild("LeftLowerLeg")
    if head and lLeg then
        local hS, hOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local fS, fOn = Camera:WorldToViewportPoint(lLeg.Position - Vector3.new(0, 0.5, 0))
        if hOn and fOn then
            local h = math.abs(fS.Y - hS.Y)
            local lSh = char:FindFirstChild("LeftUpperArm")
            local rSh = char:FindFirstChild("RightUpperArm")
            local w
            if lSh and rSh then
                local lS2 = Camera:WorldToViewportPoint(lSh.Position)
                local rS2 = Camera:WorldToViewportPoint(rSh.Position)
                w = math.abs(rS2.X - lS2.X) * 1.6
            else w = h * 0.5 end
            if h > 0 and w > 0 then return {x = hS.X - w/2, y = hS.Y, w = w, h = h} end
        end
    end
    return nil
end

local LocalAlive = false
local LocalDeadLogged = false

local function RenderESP()
    if not Config.ESP then
        for _, d in pairs(ESP) do ForceHide(d) end
        CH1.Visible = false; CH2.Visible = false
        FOVCircle.Visible = false
        return
    end

    if Config.Crosshair then
        local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
        local sz = Config.CH_Size
        CH1.From = Vector2.new(cx-sz, cy); CH1.To = Vector2.new(cx+sz, cy); CH1.Visible = true
        CH2.From = Vector2.new(cx, cy-sz); CH2.To = Vector2.new(cx, cy+sz); CH2.Visible = true
    else
        CH1.Visible = false; CH2.Visible = false
    end

    local myChar = LP.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myHrp and myHrp.Position

    -- mobile-aware offscreen margin
    local vp = Camera.ViewportSize
    local offMargin = (vp.X < 800 and 70) or 40

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local ok, err = pcall(function()
                local d = ESP[p]
                if not LocalAlive then
                    if d then ForceHide(d) end; return
                end
                local char = p.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local head = char and char:FindFirstChild("Head")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not (char and hrp and head and hum and hum.Health > 0 and PassesTeamFilter(p)) then
                    if d then ForceHide(d) end; return
                end
                local d3 = myPos and (myPos - hrp.Position).Magnitude or 0
                if d3 > Config.MaxDistance then
                    if d then ForceHide(d) end; return
                end
                local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if not d then d = CreateDraw(p); if not d then return end end

                local isEnemy = LP.Team and p.Team and p.Team ~= LP.Team
                local color
                if LP.Team and p.Team then
                    color = isEnemy and Color3.fromRGB(255,80,80) or Color3.fromRGB(80,200,255)
                else color = DistToColor(d3) end

                if not onScreen and Config.ESP_Offscreen then
                    local arrPos = OffscreenArrowPos(sp, offMargin)
                    local dir = (Vector2.new(sp.X, sp.Y) - arrPos).Unit
                    local perp = Vector2.new(-dir.Y, dir.X)
                    d.OffArrow.PointA = arrPos + dir*14
                    d.OffArrow.PointB = arrPos - dir*8 + perp*10
                    d.OffArrow.PointC = arrPos - dir*8 - perp*10
                    d.OffArrow.Color = color
                    d.OffArrow.Visible = true
                    if d.Line then d.Line.Visible = false end
                    if d.Box then d.Box.Visible = false end
                    if d.Name then d.Name.Visible = false end
                    if d.NameBg then d.NameBg.Visible = false end
                    if d.Dist then d.Dist.Visible = false end
                    if d.HpBg then d.HpBg.Visible = false end
                    if d.HpBar then d.HpBar.Visible = false end
                    if d.DistBarBg then d.DistBarBg.Visible = false end
                    if d.DistBarFg then d.DistBarFg.Visible = false end
                    for _, b in pairs(d.Bones) do b.Visible = false end
                    return
                else d.OffArrow.Visible = false end

                if not onScreen then ForceHide(d); return end

                local box = GetScreenBox(char, hrp)
                local x, y, w, h
                if box then x, y, w, h = box.x, box.y, box.w, box.h
                else
                    h = math.clamp(8000 / math.max(d3, 1), 20, 500)
                    w = h / 2
                    x = sp.X - w/2
                    y = sp.Y - h/2
                end

                d.Box.Visible = Config.ESP_Box
                if d.Box.Visible then
                    d.Box.Size = Vector2.new(w, h)
                    d.Box.Position = Vector2.new(x, y)
                    d.Box.Color = color
                end
                d.Line.Visible = Config.ESP_Line
                if d.Line.Visible then
                    d.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    d.Line.To = Vector2.new(sp.X, sp.Y)
                    d.Line.Color = color
                end
                d.Name.Visible = Config.ESP_Name
                d.NameBg.Visible = Config.ESP_Name
                if d.Name.Visible then
                    local prefix = ""
                    if LP.Team and p.Team then
                        prefix = isEnemy and "[E] " or "[A] "
                    end
                    d.Name.Text = prefix..p.Name
                    d.Name.Position = Vector2.new(x + w/2, y-18)
                    d.Name.Color = color
                    local tw = #(prefix..p.Name)*7
                    d.NameBg.Size = Vector2.new(tw+12, 18)
                    d.NameBg.Position = Vector2.new(x + w/2 - (tw+12)/2, y-19)
                end
                d.Dist.Visible = Config.ESP_Dist
                if d.Dist.Visible then
                    d.Dist.Text = tostring(math.floor(d3)).."m"
                    d.Dist.Position = Vector2.new(x + w/2, y+h+2)
                    d.Dist.Color = color
                end
                d.HpBg.Visible = Config.ESP_HP
                d.HpBar.Visible = Config.ESP_HP
                if d.HpBar.Visible and hum.MaxHealth > 0 then
                    local hpP = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
                    d.HpBg.Size = Vector2.new(3, h); d.HpBg.Position = Vector2.new(x-6, y)
                    d.HpBar.Size = Vector2.new(3, h*hpP); d.HpBar.Position = Vector2.new(x-6, y+h*(1-hpP))
                    d.HpBar.Color = Color3.fromRGB(255*(1-hpP), 255*hpP, 0)
                end
                if Config.ESP_Skeleton then
                    EnsureBones(d)
                    for i, pair in ipairs(BONE_PAIRS) do
                        local a = char:FindFirstChild(pair[1])
                        local b = char:FindFirstChild(pair[2])
                        local bone = d.Bones[i]
                        if bone and a and b then
                            local pa, onA = Camera:WorldToViewportPoint(a.Position)
                            local pb, onB = Camera:WorldToViewportPoint(b.Position)
                            if onA and onB then
                                bone.From = Vector2.new(pa.X, pa.Y)
                                bone.To = Vector2.new(pb.X, pb.Y)
                                bone.Color = color
                                bone.Visible = true
                            else bone.Visible = false end
                        elseif bone then bone.Visible = false end
                    end
                else
                    for _, bone in pairs(d.Bones) do bone.Visible = false end
                end
                if Config.ESP_DistBar then
                    local frac = math.clamp(1 - d3/Config.MaxDistance, 0, 1)
                    d.DistBarBg.Visible = true
                    d.DistBarBg.Size = Vector2.new(w, 3)
                    d.DistBarBg.Position = Vector2.new(x, y+h+18)
                    d.DistBarBg.Color = Color3.fromRGB(30,30,40)
                    d.DistBarFg.Visible = true
                    d.DistBarFg.Size = Vector2.new(w*frac, 3)
                    d.DistBarFg.Position = Vector2.new(x, y+h+18)
                    d.DistBarFg.Color = color
                else
                    d.DistBarBg.Visible = false
                    d.DistBarFg.Visible = false
                end
            end)
            if not ok then LogError("ESP "..tostring(p)..": "..tostring(err), "ESP") end
        end
    end
end

-- ═══════════════ VEHICLE ESP ═══════════════
local function CreateVehicleDraw(model)
    if VehicleESP[model] then return VehicleESP[model] end
    local ok, tbl = pcall(function()
        return {
            Box = Drawing.new("Square"), Name = Drawing.new("Text"), Dist = Drawing.new("Text"),
        }
    end)
    if not ok or not tbl then return nil end
    tbl.Box.Thickness = 1
    tbl.Name.Size = 13; tbl.Name.Center = true; tbl.Name.Outline = true
    tbl.Dist.Size = 12; tbl.Dist.Center = true; tbl.Dist.Outline = true
    for _, v in pairs(tbl) do AddDraw(v) end
    VehicleESP[model] = tbl
    return tbl
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
    local alive = {}
    for _, model in ipairs(CollectUniqueModels()) do
        local ok, err = pcall(function()
            if not model.Parent then return end
            local anchor = ModelAnchor(model)
            if not anchor then return end
            alive[model] = true
            local d = CreateVehicleDraw(model)
            if not d then return end
            local pos = anchor.Position
            local d3 = myPos and (myPos - pos).Magnitude or 0
            if d3 > (Config.V_ESP_MaxDist or 5000) then
                for _, v in pairs(d) do v.Visible = false end; return
            end
            local sp, onScreen = Camera:WorldToViewportPoint(pos)
            if not onScreen then
                for _, v in pairs(d) do v.Visible = false end; return
            end
            local extOk, ext = pcall(function() return model:GetExtentsSize() end)
            local w, h
            if extOk and ext then
                local szSp = Camera:WorldToViewportPoint(pos + ext/2)
                w = math.clamp(math.abs(szSp.X - sp.X)*2, 22, 600)
                h = math.clamp(math.abs(szSp.Y - sp.Y)*2, 22, 600)
            else
                local s = math.clamp(8000/math.max(d3,1), 24, 300)
                w, h = s, s
            end
            d.Box.Visible = Config.V_ESP_Box
            if d.Box.Visible then
                d.Box.Size = Vector2.new(w, h)
                d.Box.Position = Vector2.new(sp.X - w/2, sp.Y - h/2)
                d.Box.Color = Config.ColorVehicle
            end
            d.Name.Visible = Config.V_ESP_Name
            if d.Name.Visible then
                d.Name.Text = model.Name
                d.Name.Position = Vector2.new(sp.X, sp.Y - h/2 - 18)
                d.Name.Color = Config.ColorVehicle
            end
            d.Dist.Visible = Config.V_ESP_Dist
            if d.Dist.Visible then
                d.Dist.Text = tostring(math.floor(d3)).."m"
                d.Dist.Position = Vector2.new(sp.X, sp.Y + h/2 + 2)
                d.Dist.Color = Config.ColorVehicle
            end
        end)
        if not ok then LogError("Veh "..tostring(model)..": "..tostring(err), "VEH") end
    end
    for model, d in pairs(VehicleESP) do
        if not alive[model] then
            for _, v in pairs(d) do pcall(function() v:Remove() end) end
            VehicleESP[model] = nil
        end
    end
end

-- ═══════════════ SILENT AIM v14 + BYPASS v14 ═══════════════
local ForcedTarget = nil
local LastSwitch = 0
local SwitchCD = 0.25
local LastAimPos = nil

local function IsVisible(head)
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LP.Character, head.Parent}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local camPos = Camera.CFrame.Position
    -- if camera sits inside the head, push it back a bit for a sane ray
    if (camPos - head.Position).Magnitude < 1.5 then
        camPos = Camera.CFrame.Position - Camera.CFrame.LookVector * 2
    end
    return WS:Raycast(camPos, head.Position - camPos, rp) == nil
end

local function PredictPos(head, hrp)
    local mult = Config.PredictionMultiplier or 1.0
    if mult <= 1.0 then return head.Position end
    local vel = Vector3.zero
    pcall(function() vel = hrp.AssemblyLinearVelocity end)
    local dt = (head.Position - Camera.CFrame.Position).Magnitude / 1000
    return head.Position + vel * (dt * mult)
end

local function IsInFov(head, mPos, currentFov)
    local sp, on = Camera:WorldToViewportPoint(head.Position)
    if not on then return nil end
    local d2 = (Vector2.new(sp.X, sp.Y) - mPos).Magnitude
    if Config.StrictFOV then
        if d2 > currentFov then return nil end
    else
        if d2 > currentFov and (head.Position - Camera.CFrame.Position).Magnitude > 150 then return nil end
    end
    return {distPx = d2, sp = sp}
end

local function GetTarget()
    if ForcedTarget then
        local ch = ForcedTarget.Character
        local head = ch and ch:FindFirstChild("Head")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if head and hum and hrp and hum.Health > 0 then
            local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if myHrp and (myHrp.Position - head.Position).Magnitude <= Config.MaxDistance then
                return head, hrp
            end
        end
        ForcedTarget = nil
        LogError("Locked target lost", "AI")
    end

    local mPos = UIS:GetMouseLocation()
    local myChar = LP.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHrp or not myHum or myHum.Health <= 0 then return nil end
    local myPos = myHrp.Position

    local fov = Config.FOV
    local best, bestHrp, bestScore = nil, nil, -math.huge
    local now = tick()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and PassesTeamFilter(p) then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if head and hum and hrp and hum.Health > 0 then
                local d3 = (myPos - head.Position).Magnitude
                if d3 <= Config.MaxDistance then
                    local fovCheck = IsInFov(head, mPos, fov)
                    if fovCheck then
                        local hp = hum.MaxHealth > 0 and (hum.Health/hum.MaxHealth) or 1
                        local visible = (not Config.WallCheck) or IsVisible(head)
                        local fovFrac = 1 - math.clamp(fovCheck.distPx / fov, 0, 1)
                        local score = 0
                        score = score + (500 - d3) * 0.4
                        score = score + fovFrac * 400
                        if visible then score = score + 100 end
                        score = score - (1 - hp) * 50
                        local look = hrp.CFrame.LookVector
                        local toMe = (myPos - hrp.Position).Unit
                        if look:Dot(toMe) > 0.3 then score = score + 300 end
                        if now - LastSwitch < SwitchCD and LockHysteresis > 0 then
                            score = score + 50
                        end
                        if score > bestScore then bestScore = score; best = head; bestHrp = hrp end
                    end
                end
            end
        end
    end
    if best then
        LockHysteresis = 1
        if not ForcedTarget or ForcedTarget ~= best.Parent then
            LastSwitch = now
        end
    else
        LockHysteresis = 0
    end
    return best, bestHrp
end

local isShooting = false
local silentTarget = nil
local silentHrp = nil
local silentActive = false

AddConn(UIS.InputBegan:Connect(function(inp, gp)
    if not gp and (inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch) then isShooting = true end
end))
AddConn(UIS.InputEnded:Connect(function(inp, gp)
    if not gp and (inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch) then isShooting = false end
end))

-- save namecall for clean restore; guard against nil metatable
pcall(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    local oldNC = mt.__namecall
    __saved_mt = mt
    __saved_nc = oldNC
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        if silentActive and silentTarget and silentTarget.Parent then
            local m = getnamecallmethod()
            if m == "Raycast" then
                local a = {...}
                if typeof(a[1]) == "Vector3" then
                    local tPos = silentTarget.Position
                    -- Bypass v14: human hit-rate — occasionally aim at torso, small jitter
                    if Config.Bypass then
                        local r = math.random()
                        if not Config.Headshot and r < 0.55 then
                            local ch = silentTarget.Parent
                            local torso = ch and (ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"))
                            if torso then tPos = torso.Position end
                        end
                        tPos = tPos + Vector3.new(
                            (math.random() - 0.5) * 0.08,
                            (math.random() - 0.5) * 0.08,
                            (math.random() - 0.5) * 0.08
                        )
                    end
                    a[2] = tPos - a[1]
                end
                return oldNC(self, unpack(a))
            elseif m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList" then
                local a = {...}
                if typeof(a[1]) == "Ray" then
                    local tPos = silentTarget.Position
                    if Config.Bypass then
                        local r = math.random()
                        if not Config.Headshot and r < 0.55 then
                            local ch = silentTarget.Parent
                            local torso = ch and (ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"))
                            if torso then tPos = torso.Position end
                        end
                        tPos = tPos + Vector3.new(
                            (math.random() - 0.5) * 0.08,
                            (math.random() - 0.5) * 0.08,
                            (math.random() - 0.5) * 0.08
                        )
                    end
                    a[1] = Ray.new(a[1].Origin, tPos - a[1].Origin)
                end
                return oldNC(self, unpack(a))
            end
        end
        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
end)

-- ═══════════════ FPS ═══════════════
local Frames = 0
local LastFpsUpdate = tick()
local function UpdateFps()
    Frames = Frames + 1
    local now = tick()
    if now - LastFpsUpdate >= 1 then
        if PerfLabel then PerfLabel.Text = "FPS: "..Frames end
        Frames = 0; LastFpsUpdate = now
    end
end

-- ═══════════════ LOGIC TICK ═══════════════
local function TickLogic(dt)
    UpdateFps()

    -- central source of truth for local alive state
    local myChar = LP.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    LocalAlive = myHum ~= nil and myHum.Health > 0

    if not LocalAlive then
        for _, d in pairs(ESP) do ForceHide(d) end
        for _, d in pairs(VehicleESP) do for _, v in pairs(d) do v.Visible = false end end
        CH1.Visible = false; CH2.Visible = false; FOVCircle.Visible = false
        StatusLabel.Text = "AI: DEAD"; StatusLabel.TextColor3 = Color3.fromRGB(255,0,0)
        return
    end

    if Config.SilentAim and isShooting then
        local tgt, hrp = GetTarget()
        silentTarget = tgt
        silentHrp = hrp
        silentActive = tgt ~= nil
        -- cache position so late ticks don't read a destroyed part
        if tgt and tgt.Parent then
            LastAimPos = tgt.Position
        end
    else
        silentTarget = nil; silentHrp = nil; silentActive = false
    end

    if Config.HitboxExpander then
        for _, p in pairs(Players:GetPlayers()) do
            pcall(function()
                local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    hrp.Transparency = 0.7; hrp.CanCollide = false; hrp.Massless = true
                end
            end)
        end
    end

    if Config.SilentAim and isShooting and silentTarget then
        StatusLabel.Text = "AI: SILENT"
        StatusLabel.TextColor3 = Color3.fromRGB(255,80,80)
    else
        StatusLabel.Text = "AI: STANDBY"
        StatusLabel.TextColor3 = Color3.fromRGB(120,120,120)
    end
end

-- ═══════════════ RENDER BINDING ═══════════════
local function RenderTick()
    RenderESP()
    RenderVehicleESP()
end

pcall(function()
    RunService:BindToRenderStep("MeowESP", Enum.RenderPriority.Camera.Value - 1, RenderTick)
end)
pcall(function()
    RunService:BindToRenderStep("MeowLogic", Enum.RenderPriority.Camera.Value - 2, function(dt) TickLogic(dt) end)
end)
