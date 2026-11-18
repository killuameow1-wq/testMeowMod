-- Война Магнат | KizmoTek Studio | Delta Executor (Android)
-- v2: SilentAim (resolver+predict+bypass layers) + ESP (chams/skeleton/arrow) + Teleport + Extras

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============ CONFIG ============
local Cfg = {
    Aim = {
        Enabled = true, FOV = 150, TeamCheck = true, FriendCheck = true,
        WallCheck = false, HitPart = "Head", SmoothAim = 0, -- 0 = pure silent
        Predict = true, PredictStrength = 0.165, PredictMax = 0.35,
        Resolver = true, Jitter = 0.08, PingComp = true,
        FireDelayMin = 0.008, FireDelayMax = 0.022,
        AutoFire = false, AutoFireRate = 0.12,
        MagicBullet = true, -- raycast through walls (via ray params)
        HumanizeAim = true, -- tiny curve, not instant straight
    },
    ESP = {
        Enabled = true, Box = true, Name = true, Distance = true, Health = true,
        Tracer = true, TracerOrigin = "Bottom", Skeleton = false, Chams = false,
        Arrow = false, MaxDistance = 2500, BoxColor = Color3.fromRGB(60, 255, 60),
        TextColor = Color3.fromRGB(255, 255, 255), TracerColor = Color3.fromRGB(255, 60, 60),
        ChamsColor = Color3.fromRGB(255, 80, 80), ChamsTransparency = 0.35,
        ArrowColor = Color3.fromRGB(255, 200, 40),
    },
    Teleport = { Target = nil, Offset = Vector3.new(0, 0, 3) },
    Misc = {
        AntiFling = true, AntiVoid = true, NoClip = false,
        FPSBoost = false, CameraLock = false,
    },
}

-- ============ STATE ============
local Running = true
local Conns = {}
local ESPCache = {}
local Tracks = {} -- [Player] = {pos=Vector3, vel=Vector3, last=tick, hist={}}
local HookActive = false
local OrigNamecall = nil
local LastShot = 0
local LastAuto = 0
local Locked = nil -- manual aim lock

local function log(...) print("[WT v2]", ...) end
local function addConn(c) table.insert(Conns, c) return c end
local function now() return tick() end

-- ============ HELPERS ============
local function getChar(p) return p and p.Character end
local function getHum(p) local c = getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP(p) local c = getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end

local function getPing()
    local ok, ping = pcall(function()
        local s = Stats.Network.ServerStatsItem["Data Ping"]
        return s:GetValue()
    end)
    if ok and ping then return ping / 1000 end
    return 0.05
end

local function isEnemy(p)
    if p == LP then return false end
    local hum = getHum(p); if not hum or hum.Health <= 0 then return false end
    if Cfg.Aim.TeamCheck and p.Team and LP.Team and p.Team == LP.Team then return false end
    if Cfg.Aim.FriendCheck then
        local ok, r = pcall(function() return LP:IsFriendsWith(p.UserId) end)
        if ok and r then return false end
    end
    return true
end

local function getHitPart(p, prefer)
    local c = getChar(p); if not c then return nil end
    return c:FindFirstChild(prefer or Cfg.Aim.HitPart)
        or c:FindFirstChild("Head")
        or c:FindFirstChild("HumanoidRootPart")
end

-- ============ TRACKER (velocity + history) ============
addConn(RunService.Heartbeat:Connect(function()
    if not Running then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local hrp = getHRP(p)
            local t = Tracks[p] or { hist = {} }
            if hrp then
                local n = now()
                if t.last then
                    local dt = n - t.last
                    if dt > 0.001 then
                        t.vel = (hrp.Position - t.pos) / dt
                    end
                end
                t.pos = hrp.Position
                t.last = n
                table.insert(t.hist, {pos = hrp.Position, t = n})
                if #t.hist > 12 then table.remove(t.hist, 1) end
            end
            Tracks[p] = t
        end
    end
    if not Players:FindFirstChild(LP.Name) then return end
    -- prune
    for p in pairs(Tracks) do
        if not p.Parent then Tracks[p] = nil end
    end
end))

local function predictPos(p, part)
    local t = Tracks[p]
    local base = part.Position
    if not Cfg.Aim.Predict or not t or not t.vel then return base end
    local hrp = getHRP(p)
    local dist = hrp and (Camera.CFrame.Position - hrp.Position).Magnitude or 100
    local ping = Cfg.Aim.PingComp and getPing() or 0.05
    local baseT = Cfg.Aim.PredictStrength * (dist / 100)
    local travel = math.clamp(baseT + ping, 0, Cfg.Aim.PredictMax)
    local pred = base + t.vel * travel
    -- resolver: если last hist показал нестабильность, слегка усредняем
    if Cfg.Aim.Resolver and #(t.hist or {}) >= 4 then
        local hist = t.hist
        local avgV = Vector3.new()
        for i = 2, #hist do
            local dt = hist[i].t - hist[i-1].t
            if dt > 0.001 then avgV += (hist[i].pos - hist[i-1].pos) / dt end
        end
        avgV = avgV / (#hist - 1)
        local var = (t.vel - avgV).Magnitude
        if var > 50 then
            pred = base + avgV * travel * 0.5 + t.vel * travel * 0.5
        end
    end
    return pred
end

local function jitter(v)
    local j = Cfg.Aim.Jitter
    return v + Vector3.new((math.random()-0.5)*j, (math.random()-0.5)*j, (math.random()-0.5)*j)
end

-- ============ TARGET SELECTION ============
local function screenDist(part)
    local sp, on = Camera:WorldToViewportPoint(part.Position)
    if not on then return math.huge end
    local vp = Camera.ViewportSize
    local c = Vector2.new(vp.X/2, vp.Y/2)
    return (Vector2.new(sp.X, sp.Y) - c).Magnitude
end

local function rayVisible(from, to)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character, Camera }
    local r = Workspace:Raycast(from, to - from, params)
    return r == nil
end

local function findTarget()
    if Locked and Locked.Parent and isEnemy(Locked) then return Locked end
    local best, bestD = nil, math.huge
    local camPos = Camera.CFrame.Position
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local part = getHitPart(p)
            if part then
                local d = screenDist(part)
                if d < Cfg.Aim.FOV and d < bestD then
                    if Cfg.Aim.WallCheck then
                        if rayVisible(camPos, part.Position) then best, bestD = p, d end
                    else
                        best, bestD = p, d
                    end
                end
            end
        end
    end
    return best
end

-- ============ FIRING STATE ============
local lastTouchFire = 0
addConn(UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        lastTouchFire = now()
    end
end))

local function isFiring()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return true end
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.Touch) then return true end
    if now() - lastTouchFire < 0.15 then return true end
    return false
end

-- ============ SILENT AIM HOOK ============
local function buildRayArgs(self, method, args)
    if not Cfg.Aim.Enabled then return args end
    local target = CachedTarget
    if not target then return args end
    local part = getHitPart(target); if not part then return args end
    local aimPos = jitter(predictPos(target, part))
    if method == "Raycast" then
        local origin = args[1]
        local dir = aimPos - origin
        if dir.Magnitude < 0.05 then return args end
        args[2] = dir
        -- magic bullet: расширяем RaycastParams исключения — убираем всё кроме цели
        if Cfg.Aim.MagicBullet and typeof(args[4]) == "RaycastParams" then
            local ok = pcall(function()
                args[4].FilterType = Enum.RaycastFilterType.Exclude
                args[4].FilterDescendantsInstances = { LP.Character, Camera, target.Character }
            end)
        end
        if Cfg.Aim.HumanizeAim then
            -- микро-изгиб: интерполируем направление с небольшим боковым сдвигом
            local side = Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5) * 0.02
            args[2] = dir + side
        end
        return args
    elseif method == "FindPartOnRay" then
        local ray = args[1]
        if typeof(ray) == "Ray" then
            local d = aimPos - ray.Origin
            if d.Magnitude < 0.05 then return args end
            args[1] = Ray.new(ray.Origin, d)
        end
        return args
    elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
        local ray = args[1]
        if typeof(ray) == "Ray" then
            local d = aimPos - ray.Origin
            if d.Magnitude < 0.05 then return args end
            args[1] = Ray.new(ray.Origin, d)
        end
        return args
    end
    return args
end

local function installHook()
    if HookActive then return end
    local ok, err = pcall(function()
        OrigNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if not Running or not Cfg.Aim.Enabled or not CachedTarget then
                return OrigNamecall(self, ...)
            end
            local method = getnamecallmethod()
            if not (method == "Raycast" or method == "FindPartOnRay"
                or method == "FindPartOnRayWithIgnoreList"
                or method == "FindPartOnRayWithWhitelist") then
                return OrigNamecall(self, ...)
            end
            if not isFiring() then return OrigNamecall(self, ...) end
            local t = now()
            local delay = Cfg.Aim.FireDelayMin + math.random() * (Cfg.Aim.FireDelayMax - Cfg.Aim.FireDelayMin)
            if t - LastShot < delay then return OrigNamecall(self, ...) end
            LastShot = t
            local args = {...}
            args = buildRayArgs(self, method, args)
            log("SILENT", method, "->", CachedTarget.Name)
            return OrigNamecall(self, unpack(args))
        end))
    end)
    if ok then HookActive = true; log("hook installed (newcclosure)")
    else log("hook failed:", err) end
end

local function removeHook()
    if not HookActive or not OrigNamecall then return end
    pcall(function() hookmetamethod(game, "__namecall", OrigNamecall) end)
    HookActive = false
    log("hook removed")
end

-- ============ RENDER LOOP ============
local CachedTarget = nil
addConn(RunService.RenderStepped:Connect(function()
    if not Running then return end
    CachedTarget = Cfg.Aim.Enabled and findTarget() or nil
    -- auto fire
    if Cfg.Aim.AutoFire and CachedTarget and now() - LastAuto >= Cfg.Aim.AutoFireRate then
        LastAuto = now()
        local ok = pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.01)
            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
end))

-- ============ ESP DRAWING ============
local function newD(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function mkEntry()
    return {
        box = newD("Square", {Thickness=1, Filled=false, Color=Cfg.ESP.BoxColor, Visible=false}),
        name = newD("Text", {Size=14, Center=true, Outline=true, Color=Cfg.ESP.TextColor, Visible=false}),
        dist = newD("Text", {Size=12, Center=true, Outline=true, Color=Cfg.ESP.TextColor, Visible=false}),
        health = newD("Square", {Thickness=2, Filled=true, Color=Color3.fromRGB(60,255,60), Visible=false}),
        tracer = newD("Line", {Thickness=1, Color=Cfg.ESP.TracerColor, Visible=false}),
        arrow = newD("Triangle", {Thickness=1, Filled=true, Color=Cfg.ESP.ArrowColor, Visible=false}),
        skeleton = { -- 4 line segments
            newD("Line",{Thickness=1,Color=Cfg.ESP.TextColor,Visible=false}),
            newD("Line",{Thickness=1,Color=Cfg.ESP.TextColor,Visible=false}),
            newD("Line",{Thickness=1,Color=Cfg.ESP.TextColor,Visible=false}),
            newD("Line",{Thickness=1,Color=Cfg.ESP.TextColor,Visible=false}),
            newD("Line",{Thickness=1,Color=Cfg.ESP.TextColor,Visible=false}),
        },
    }
end

local function destroyEntry(e)
    for k, d in pairs(e) do
        if k == "skeleton" then
            for _, s in ipairs(d) do pcall(s.Remove, s) end
        elseif typeof(d) == "Instance" and d.Remove then pcall(d.Remove, d) end
    end
end

local function ensureEntry(p)
    ESPCache[p] = ESPCache[p] or mkEntry()
    return ESPCache[p]
end

local function hideAll(e)
    e.box.Visible = false; e.name.Visible = false; e.dist.Visible = false
    e.health.Visible = false; e.tracer.Visible = false; e.arrow.Visible = false
    for _, s in ipairs(e.skeleton) do s.Visible = false end
end

addConn(Players.PlayerRemoving:Connect(function(p)
    if ESPCache[p] then destroyEntry(ESPCache[p]); ESPCache[p] = nil end
    Tracks[p] = nil
    if Cfg.Teleport.Target == p then Cfg.Teleport.Target = nil end
end))

-- Chams highlight (Highlight instance)
local ChamsInstances = {}
local function setChams(p, on)
    local c = getChar(p)
    if not c then if ChamsInstances[p] then ChamsInstances[p]:Destroy(); ChamsInstances[p]=nil end return end
    if on then
        if not ChamsInstances[p] then
            local h = Instance.new("Highlight")
            h.Name = "WTChams"
            h.FillColor = Cfg.ESP.ChamsColor
            h.FillTransparency = Cfg.ESP.ChamsTransparency
            h.OutlineColor = Cfg.ESP.ChamsColor
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = c
            ChamsInstances[p] = h
        else
            ChamsInstances[p].FillColor = Cfg.ESP.ChamsColor
            ChamsInstances[p].FillTransparency = Cfg.ESP.ChamsTransparency
        end
    else
        if ChamsInstances[p] then pcall(function() ChamsInstances[p]:Destroy() end); ChamsInstances[p] = nil end
    end
end

-- Skeleton lookup
local skeletonParts = {"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","RightUpperArm","RightLowerArm","LeftUpperLeg","LeftLowerLeg","RightUpperLeg","RightLowerLeg"}

addConn(RunService.RenderStepped:Connect(function()
    if not Running then return end
    if not Cfg.ESP.Enabled then
        for _, e in pairs(ESPCache) do hideAll(e) end
        for p in pairs(ChamsInstances) do setChams(p, false) end
        return
    end
    local vp = Camera.ViewportSize
    for _, p in ipairs(Players:GetPlayers()) do
        local e = ensureEntry(p)
        if p == LP then hideAll(e) continue end
        local c = getChar(p)
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then hideAll(e); setChams(p,false) continue end
        local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
        if not onScreen or dist > Cfg.ESP.MaxDistance then hideAll(e); setChams(p,false) continue end

        local height = 2500 / sp.Z
        local width = 2000 / sp.Z
        local pos = Vector2.new(sp.X - width/2, sp.Y - height/2)

        if Cfg.ESP.Box then
            e.box.Size = Vector2.new(width, height); e.box.Position = pos
            e.box.Color = Cfg.ESP.BoxColor; e.box.Visible = true
        else e.box.Visible = false end

        if Cfg.ESP.Name then
            e.name.Text = p.Name
            e.name.Position = Vector2.new(sp.X, pos.Y - 16)
            e.name.Color = Cfg.ESP.TextColor; e.name.Visible = true
        else e.name.Visible = false end

        if Cfg.ESP.Distance then
            e.dist.Text = "["..math.floor(dist).."m]"
            e.dist.Position = Vector2.new(sp.X, pos.Y - 2)
            e.dist.Color = Cfg.ESP.TextColor; e.dist.Visible = true
        else e.dist.Visible = false end

        if Cfg.ESP.Health then
            local pct = hum.Health / math.max(hum.MaxHealth,1)
            local h = height * pct
            e.health.Size = Vector2.new(3, h)
            e.health.Position = Vector2.new(pos.X - 5, pos.Y + (height - h))
            e.health.Color = Color3.fromRGB(255*(1-pct), 255*pct, 0)
            e.health.Visible = true
        else e.health.Visible = false end

        if Cfg.ESP.Tracer then
            local o
            if Cfg.ESP.TracerOrigin=="Top" then o=Vector2.new(vp.X/2,0)
            elseif Cfg.ESP.TracerOrigin=="Bottom" then o=Vector2.new(vp.X/2,vp.Y)
            elseif Cfg.ESP.TracerOrigin=="Left" then o=Vector2.new(0,vp.Y/2)
            else o=Vector2.new(vp.X,vp.Y/2) end
            e.tracer.From = o; e.tracer.To = Vector2.new(sp.X, pos.Y+height)
            e.tracer.Color = Cfg.ESP.TracerColor; e.tracer.Visible = true
        else e.tracer.Visible = false end

        if Cfg.ESP.Arrow then
            e.arrow.Color = Cfg.ESP.ArrowColor; e.arrow.Visible = true
            local tx, ty = sp.X, pos.Y - 22
            e.arrow.PointA = Vector2.new(tx, ty)
            e.arrow.PointB = Vector2.new(tx - 6, ty - 10)
            e.arrow.PointC = Vector2.new(tx + 6, ty - 10)
        else e.arrow.Visible = false end

        if Cfg.ESP.Skeleton and c then
            for i = 1, 5 do e.skeleton[i].Visible = false end
            local pairs_ = {
                {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
                {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
                {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
                {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
                {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},
            }
            local segs = {}
            for _, pr in ipairs(pairs_) do
                local a = c:FindFirstChild(pr[1]); local b = c:FindFirstChild(pr[2])
                if a and b then
                    local sa, onA = Camera:WorldToViewportPoint(a.Position)
                    local sb, onB = Camera:WorldToViewportPoint(b.Position)
                    if onA and onB then table.insert(segs, {Vector2.new(sa.X,sa.Y), Vector2.new(sb.X,sb.Y)}) end
                end
            end
            for i = 1, math.min(#segs, #e.skeleton) do
                e.skeleton[i].From = segs[i][1]; e.skeleton[i].To = segs[i][2]
                e.skeleton[i].Color = Cfg.ESP.BoxColor; e.skeleton[i].Visible = true
            end
        else
            for _, s in ipairs(e.skeleton) do s.Visible = false end
        end

        if Cfg.ESP.Chams then setChams(p, true) else setChams(p, false) end
    end
    -- чистим chams для игроков без ESP
    for p in pairs(ChamsInstances) do
        if not Cfg.ESP.Enabled or not Cfg.ESP.Chams then setChams(p, false) end
    end
end))

-- ============ TELEPORT ============
local function tpTo(pos)
    local hrp = getHRP(LP); if not hrp then return end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
end

local function tpToPlayer(p)
    if not p or not p.Character then return false end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    tpTo(hrp.Position + Cfg.Teleport.Offset)
    log("TP ->", p.Name)
    return true
end

-- ============ MISC ============
-- Anti-fling: следим за скоростью HRP
if Cfg.Misc.AntiFling then
    addConn(RunService.Heartbeat:Connect(function()
        if not Running then return end
        local hrp = getHRP(LP); if not hrp then return end
        local v = hrp.AssemblyLinearVelocity
        if v.Magnitude > 500 then
            hrp.AssemblyLinearVelocity = Vector3.new()
        end
    end))
end

-- Anti-void: телепорт наверх если падаем ниже -100
if Cfg.Misc.AntiVoid then
    addConn(RunService.Heartbeat:Connect(function()
        if not Running then return end
        local hrp = getHRP(LP); if not hrp then return end
        if hrp.Position.Y < -100 then
            hrp.CFrame = CFrame.new(0, 50, 0)
            log("AntiVoid triggered")
        end
    end))
end

-- NoClip
if Cfg.Misc.NoClip then
    addConn(RunService.Stepped:Connect(function()
        if not Running then return end
        local c = LP.Character; if not c then return end
        for _, v in ipairs(c:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end))
end

-- FPS Boost (понижаем качество графики)
if Cfg.Misc.FPSBoost then
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
    end)
end

-- ============ UI (600x420) ============
local oldGui = CoreGui:FindFirstChild("WarTycoonUI"); if oldGui then oldGui:Destroy() end
local SG = Instance.new("ScreenGui"); SG.Name="WarTycoonUI"; SG.ResetOnSpawn=false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; SG.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(600, 420); Main.Position = UDim2.new(0.5,-300,0.5,-210)
Main.BackgroundColor3 = Color3.fromRGB(16,16,20); Main.BorderSizePixel=0
Main.Active = true; Main.Draggable = true; Main.Parent = SG
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,8)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,36); TitleBar.BackgroundColor3 = Color3.fromRGB(26,26,32)
TitleBar.BorderSizePixel=0; TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,8)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1,-120,1,0); TitleLbl.Position = UDim2.fromOffset(12,0)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="WarTycoon v2 | ollie"
TitleLbl.TextColor3 = Color3.fromRGB(220,220,230); TitleLbl.Font=Enum.Font.GothamBold
TitleLbl.TextSize=14; TitleLbl.TextXAlignment=Enum.TextXAlignment.Left; TitleLbl.Parent = TitleBar

local function mkTitleBtn(text, x, w, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(w, 24); b.Position = UDim2.fromOffset(x, 6)
    b.BackgroundColor3 = color or Color3.fromRGB(46,46,56)
    b.Text = text; b.TextColor3 = Color3.fromRGB(230,230,240)
    b.Font = Enum.Font.GothamBold; b.TextSize=12; b.BorderSizePixel=0; b.Parent = TitleBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
    return b
end

local MinBtn = mkTitleBtn("—", 600-104, 28)
local UnloadBtn = mkTitleBtn("Unload", 600-72, 38)
local CloseBtn = mkTitleBtn("X", 600-28, 22, Color3.fromRGB(180,40,40))

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-20,1,-50); Content.Position = UDim2.fromOffset(10,44)
Content.BackgroundTransparency=1; Content.Parent = Main

-- tabs
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1,0,0,28); TabBar.BackgroundTransparency=1; TabBar.Parent = Content
local function mkTab(text, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(100, 26); b.Position = UDim2.fromOffset(x,0)
    b.BackgroundColor3 = Color3.fromRGB(36,36,46); b.Text=text
    b.TextColor3 = Color3.fromRGB(220,220,230); b.Font=Enum.Font.GothamBold
    b.TextSize=12; b.BorderSizePixel=0; b.Parent = TabBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
    return b
end
local tAim = mkTab("Aim", 0)
local tESP = mkTab("ESP", 104)
local tTP = mkTab("Teleport", 208)
local tMisc = mkTab("Misc", 312)

local Pages = {}
local function mkPage(y)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,1,-32); f.Position = UDim2.fromOffset(0, y)
    f.BackgroundTransparency=1; f.Parent = Content; f.Visible = false
    return f
end
Pages.Aim = mkPage(32); Pages.ESP = mkPage(32); Pages.TP = mkPage(32); Pages.Misc = mkPage(32)
local TabButtons = { Aim = tAim, ESP = tESP, TP = tTP, Misc = tMisc }
local function selectTab(name)
    for k, p in pairs(Pages) do p.Visible = (k==name) end
    for k, b in pairs(TabButtons) do
        b.BackgroundColor3 = (k==name) and Color3.fromRGB(40,120,60) or Color3.fromRGB(36,36,46)
    end
end
tAim.MouseButton1Click:Connect(function() selectTab("Aim") end)
tESP.MouseButton1Click:Connect(function() selectTab("ESP") end)
tTP.MouseButton1Click:Connect(function() selectTab("Teleport") end)
tMisc.MouseButton1Click:Connect(function() selectTab("Misc") end)
selectTab("Aim")

-- UI builders
local function mkToggle(parent, label, get, set, x, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(180, 26); b.Position = UDim2.fromOffset(x, y)
    b.BackgroundColor3 = Color3.fromRGB(38,38,48); b.TextColor3=Color3.fromRGB(230,230,240)
    b.Font=Enum.Font.Gotham; b.TextSize=12; b.BorderSizePixel=0; b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
    local function ref()
        local v = get(); b.Text = label..": "..(v and "ON" or "OFF")
        b.BackgroundColor3 = v and Color3.fromRGB(40,120,60) or Color3.fromRGB(60,40,40)
    end
    b.MouseButton1Click:Connect(function() set(not get()); ref() end); ref()
    return b
end

local function mkSlider(parent, label, x, y, minV, maxV, get, set, isFloat)
    local holder = Instance.new("Frame"); holder.Size=UDim2.fromOffset(280,28)
    holder.Position=UDim2.fromOffset(x,y); holder.BackgroundTransparency=1; holder.Parent=parent
    local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,0,12)
    lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.fromRGB(220,220,230)
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text = label..": "..tostring(get()); lbl.Parent=holder
    local bar = Instance.new("Frame"); bar.Size=UDim2.new(1,0,0,6); bar.Position=UDim2.fromOffset(0,16)
    bar.BackgroundColor3=Color3.fromRGB(40,40,50); bar.BorderSizePixel=0; bar.Parent=holder
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,3)
    local fill = Instance.new("Frame"); fill.Size=UDim2.new((get()-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(120,220,140); fill.BorderSizePixel=0; fill.Parent=bar
    local drag=false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
            local v = minV + (maxV-minV)*rel
            if not isFloat then v = math.floor(v) end
            set(v); fill.Size=UDim2.new(rel,0,1,0); lbl.Text = label..": "..tostring(v)
        end
    end)
    return holder
end

local function mkDropdown(parent, label, options, get, set, x, y)
    local btn = Instance.new("TextButton")
    btn.Size=UDim2.fromOffset(280,26); btn.Position=UDim2.fromOffset(x,y)
    btn.BackgroundColor3=Color3.fromRGB(46,46,56); btn.TextColor3=Color3.fromRGB(230,230,240)
    btn.Font=Enum.Font.Gotham; btn.TextSize=12; btn.BorderSizePixel=0; btn.Parent=parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    btn.Text = label..": "..tostring(get())
    local dd = Instance.new("ScrollingFrame")
    dd.Size=UDim2.fromOffset(280,120); dd.Position=UDim2.fromOffset(x,y+28)
    dd.BackgroundColor3=Color3.fromRGB(26,26,32); dd.BorderSizePixel=0
    dd.Visible=false; dd.ScrollBarThickness=4
    dd.CanvasSize=UDim2.new(0,0,0,#options*26); dd.Parent=parent
    Instance.new("UICorner", dd).CornerRadius = UDim.new(0,4)
    for i,opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size=UDim2.new(1,-4,0,24); ob.Position=UDim2.fromOffset(2,(i-1)*26)
        ob.BackgroundColor3=Color3.fromRGB(40,40,50); ob.Text=tostring(opt)
        ob.TextColor3=Color3.fromRGB(220,220,230); ob.Font=Enum.Font.Gotham
        ob.TextSize=12; ob.BorderSizePixel=0; ob.Parent=dd
        Instance.new("UICorner", ob).CornerRadius = UDim.new(0,3)
        ob.MouseButton1Click:Connect(function()
            set(opt); btn.Text = label..": "..tostring(opt); dd.Visible=false
        end)
    end
    btn.MouseButton1Click:Connect(function() dd.Visible = not dd.Visible end)
    return btn
end

-- AIM page
local A = Pages.Aim
mkToggle(A, "Silent Aim", function() return Cfg.Aim.Enabled end, function(v) Cfg.Aim.Enabled = v end, 0, 0)
mkToggle(A, "Team Check", function() return Cfg.Aim.TeamCheck end, function(v) Cfg.Aim.TeamCheck = v end, 190, 0)
mkToggle(A, "Friend Check", function() return Cfg.Aim.FriendCheck end, function(v) Cfg.Aim.FriendCheck = v end, 380, 0)
mkToggle(A, "Wall Check", function() return Cfg.Aim.WallCheck end, function(v) Cfg.Aim.WallCheck = v end, 0, 32)
mkToggle(A, "Predict", function() return Cfg.Aim.Predict end, function(v) Cfg.Aim.Predict = v end, 190, 32)
mkToggle(A, "Resolver", function() return Cfg.Aim.Resolver end, function(v) Cfg.Aim.Resolver = v end, 380, 32)
mkToggle(A, "Ping Comp", function() return Cfg.Aim.PingComp end, function(v) Cfg.Aim.PingComp = v end, 0, 64)
mkToggle(A, "Magic Bullet", function() return Cfg.Aim.MagicBullet end, function(v) Cfg.Aim.MagicBullet = v end, 190, 64)
mkToggle(A, "Humanize", function() return Cfg.Aim.HumanizeAim end, function(v) Cfg.Aim.HumanizeAim = v end, 380, 64)
mkToggle(A, "Auto Fire", function() return Cfg.Aim.AutoFire end, function(v) Cfg.Aim.AutoFire = v end, 0, 96)
mkSlider(A, "FOV", 0, 130, 10, 600, function() return Cfg.Aim.FOV end, function(v) Cfg.Aim.FOV = v end)
mkSlider(A, "Predict Str", 300, 130, 0, 1, function() return Cfg.Aim.PredictStrength end, function(v) Cfg.Aim.PredictStrength = v end, true)
mkSlider(A, "Jitter", 0, 166, 0, 0.5, function() return Cfg.Aim.Jitter end, function(v) Cfg.Aim.Jitter = v end, true)
mkSlider(A, "AutoRate", 300, 166, 0.02, 0.5, function() return Cfg.Aim.AutoFireRate end, function(v) Cfg.Aim.AutoFireRate = v end, true)
mkDropdown(A, "Hit Part", {"Head","HumanoidRootPart","Torso","UpperTorso"}, function() return Cfg.Aim.HitPart end, function(v) Cfg.Aim.HitPart = v end, 0, 200)

-- ESP page
local E = Pages.ESP
mkToggle(E, "ESP", function() return Cfg.ESP.Enabled end, function(v) Cfg.ESP.Enabled = v end, 0, 0)
mkToggle(E, "Box", function() return Cfg.ESP.Box end, function(v) Cfg.ESP.Box = v end, 190, 0)
mkToggle(E, "Name", function() return Cfg.ESP.Name end, function(v) Cfg.ESP.Name = v end, 380, 0)
mkToggle(E, "Distance", function() return Cfg.ESP.Distance end, function(v) Cfg.ESP.Distance = v end, 0, 32)
mkToggle(E, "Health", function() return Cfg.ESP.Health end, function(v) Cfg.ESP.Health = v end, 190, 32)
mkToggle(E, "Tracer", function() return Cfg.ESP.Tracer end, function(v) Cfg.ESP.Tracer = v end, 380, 32)
mkToggle(E, "Skeleton", function() return Cfg.ESP.Skeleton end, function(v) Cfg.ESP.Skeleton = v end, 0, 64)
mkToggle(E, "Chams", function() return Cfg.ESP.Chams end, function(v) Cfg.ESP.Chams = v end, 190, 64)
mkToggle(E, "Arrow", function() return Cfg.ESP.Arrow end, function(v) Cfg.ESP.Arrow = v end, 380, 64)
mkSlider(E, "Max Dist", 0, 100, 200, 5000, function() return Cfg.ESP.MaxDistance end, function(v) Cfg.ESP.MaxDistance = v end)
mkDropdown(E, "Tracer Origin", {"Top","Bottom","Left","Right"}, function() return Cfg.ESP.TracerOrigin end, function(v) Cfg.ESP.TracerOrigin = v end, 0, 140)

-- TELEPORT page
local T = Pages.TP
local TpBtn = Instance.new("TextButton")
TpBtn.Size=UDim2.fromOffset(280,30); TpBtn.Position=UDim2.fromOffset(0,0)
TpBtn.BackgroundColor3=Color3.fromRGB(60,60,80); TpBtn.TextColor3=Color3.fromRGB(230,230,240)
TpBtn.Font=Enum.Font.GothamBold; TpBtn.TextSize=13; TpBtn.BorderSizePixel=0; TpBtn.Parent=T
Instance.new("UICorner", TpBtn).CornerRadius = UDim.new(0,4)
TpBtn.Text = "Select Player to Teleport"
local TPdd = Instance.new("ScrollingFrame")
TPdd.Size=UDim2.fromOffset(280,260); TPdd.Position=UDim2.fromOffset(0,36)
TPdd.BackgroundColor3=Color3.fromRGB(26,26,32); TPdd.BorderSizePixel=0
TPdd.ScrollBarThickness=4; TPdd.CanvasSize=UDim2.new(0,0,0,0)
TPdd.AutomaticCanvasSize=Enum.AutomaticSize.Y; TPdd.Parent=T
Instance.new("UICorner", TPdd).CornerRadius = UDim.new(0,4)
local function refreshTP()
    for _,c in ipairs(TPdd:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for i,p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local b = Instance.new("TextButton")
            b.Size=UDim2.new(1,-4,0,26); b.Position=UDim2.fromOffset(2,(i-1)*28)
            b.BackgroundColor3=Color3.fromRGB(40,40,50); b.Text=p.Name
            b.TextColor3=Color3.fromRGB(220,220,230); b.Font=Enum.Font.Gotham
            b.TextSize=12; b.BorderSizePixel=0; b.Parent=TPdd
            Instance.new("UICorner", b).CornerRadius = UDim.new(0,3)
            b.MouseButton1Click:Connect(function()
                Cfg.Teleport.Target = p; TpBtn.Text = "TP: "..p.Name
            end)
        end
    end
end
refreshTP()
TpBtn.MouseButton1Click:Connect(function()
    refreshTP()
    if Cfg.Teleport.Target then tpToPlayer(Cfg.Teleport.Target) end
end)
Players.PlayerAdded:Connect(function() task.wait(1) refreshTP() end)
Players.PlayerRemoving:Connect(function() task.wait(0.1) refreshTP() end)

local LockBtn = Instance.new("TextButton")
LockBtn.Size=UDim2.fromOffset(280,30); LockBtn.Position=UDim2.fromOffset(0,310)
LockBtn.BackgroundColor3=Color3.fromRGB(60,60,80); LockBtn.TextColor3=Color3.fromRGB(230,230,240)
LockBtn.Font=Enum.Font.GothamBold; LockBtn.TextSize=12; LockBtn.BorderSizePixel=0; LockBtn.Parent=T
Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(0,4)
LockBtn.Text = "Lock Aim on Selected"
LockBtn.MouseButton1Click:Connect(function()
    if Cfg.Teleport.Target then
        Locked = Cfg.Teleport.Target; LockBtn.Text = "Locked: "..Locked.Name
        LockBtn.BackgroundColor3 = Color3.fromRGB(40,120,60)
    else
        Locked = nil; LockBtn.Text = "Lock Aim on Selected"; LockBtn.BackgroundColor3 = Color3.fromRGB(60,60,80)
    end
end)

-- MISC page
local M = Pages.Misc
mkToggle(M, "Anti Fling", function() return Cfg.Misc.AntiFling end, function(v) Cfg.Misc.AntiFling = v end, 0, 0)
mkToggle(M, "Anti Void", function() return Cfg.Misc.AntiVoid end, function(v) Cfg.Misc.AntiVoid = v end, 190, 0)
mkToggle(M, "NoClip", function() return Cfg.Misc.NoClip end, function(v) Cfg.Misc.NoClip = v end, 380, 0)
mkToggle(M, "FPS Boost", function() return Cfg.Misc.FPSBoost end, function(v) Cfg.Misc.FPSBoost = v end, 0, 32)

-- UI buttons
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Main.Size = minimized and UDim2.fromOffset(600,36) or UDim2.fromOffset(600,420)
    Content.Visible = not minimized
end)

local function unloadAll()
    Running = false
    removeHook()
    for _,c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
    for _,e in pairs(ESPCache) do destroyEntry(e) end
    for p in pairs(ChamsInstances) do setChams(p,false) end
    SG:Destroy()
    log("unloaded")
end
UnloadBtn.MouseButton1Click:Connect(unloadAll)
CloseBtn.MouseButton1Click:Connect(function() pcall(unloadAll) end)

installHook()
log("WarTycoon v2 loaded")
