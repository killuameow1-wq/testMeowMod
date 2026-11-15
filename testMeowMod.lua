--[[
    MeowMod — Master Rebuilder & Loader
    Восстанавливает обрезанный файл и запускает полную версию.
]]

-- 1. Скачиваем то, что осталось на GitHub (Part 1-10)
local MeowModURL = "https://cdn.jsdelivr.net/gh/killuameow1-wq/testMeowMod@main/testMeowMod.lua"
print("[Loader] Скачивание базы (Part 1-10)...")
local ok, baseCode = pcall(function() return game:HttpGet(MeowModURL) end)
if not ok or not baseCode or #baseCode < 100 then
    return error("[Loader] Ошибка скачивания базы.")
end
baseCode = baseCode:gsub("^%s+", ""):gsub("\xef\xbb\xbf", "")

-- 2. Дописываем остальные части (11-26)
local extraCode = [[

-- ═══════════════════════════════════════════════════════════
--  PART 11-14: WORLD, SKYBOX, CAMERA, CROSSHAIR
-- ═══════════════════════════════════════════════════════════

CreateToggle(Pages["World"], "Fullbright (Extended)", false, function(v)
    if v then
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.Brightness = 3
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
        if Atmosphere then Atmosphere.Density = 0 end
    else
        Lighting.Ambient = Color3.fromRGB(70,70,70)
        Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 1000
        if Atmosphere then Atmosphere.Density = 0.3 end
    end
end)

local CH_Line1 = Drawing.new("Line")
local CH_Line2 = Drawing.new("Line")
local CH_Line3 = Drawing.new("Line")
local CH_Line4 = Drawing.new("Line")
local CrosshairEnabled = false
local CrosshairSize = 10

local function UpdateCrosshair()
    if not CrosshairEnabled then
        CH_Line1.Visible = false CH_Line2.Visible = false CH_Line3.Visible = false CH_Line4.Visible = false
        return
    end
    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    local gap, len = 4, CrosshairSize
    CH_Line1.From = Vector2.new(cx, cy - gap) CH_Line1.To = Vector2.new(cx, cy - gap - len) CH_Line1.Color = Color3.new(1,1,1) CH_Line1.Visible = true
    CH_Line2.From = Vector2.new(cx, cy + gap) CH_Line2.To = Vector2.new(cx, cy + gap + len) CH_Line2.Color = Color3.new(1,1,1) CH_Line2.Visible = true
    CH_Line3.From = Vector2.new(cx - gap, cy) CH_Line3.To = Vector2.new(cx - gap - len, cy) CH_Line3.Color = Color3.new(1,1,1) CH_Line3.Visible = true
    CH_Line4.From = Vector2.new(cx + gap, cy) CH_Line4.To = Vector2.new(cx + gap + len, cy) CH_Line4.Color = Color3.new(1,1,1) CH_Line4.Visible = true
end

CreateToggle(Pages["Visuals"], "Custom Crosshair", false, function(v) CrosshairEnabled = v end)
CreateSlider(Pages["Visuals"], "Crosshair Size", 5, 30, 10, function(v) CrosshairSize = v end)

-- ═══════════════════════════════════════════════════════════
--  PART 15-16: WAR TYCOON, LOOT FARM, AUTO BUILD
-- ═══════════════════════════════════════════════════════════

local LootFarmActive = false
local LootFarmConn = nil
local LootType = "Crate"

local function StartLootFarm()
    if LootFarmActive then return end
    LootFarmActive = true
    LootFarmConn = task.spawn(function()
        while LootFarmActive do
            local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if myHrp then
                local best, bestD = nil, math.huge
                for _, inst in ipairs(WS:GetDescendants()) do
                    if inst.Name:lower():find(LootType:lower()) and inst:IsA("BasePart") then
                        local d = (myHrp.Position - inst.Position).Magnitude
                        if d < bestD then bestD = d best = inst end
                    end
                end
                if best and SafeTP then SafeTP(best.Position + Vector3.new(0, 2, 0)) end
            end
            task.wait(1)
        end
    end)
end

local function StopLootFarm()
    LootFarmActive = false
    if LootFarmConn then pcall(function() task.cancel(LootFarmConn) end) LootFarmConn = nil end
end

CreateToggle(Pages["Misc"], "Auto-Farm: Crates", false, function(v)
    if v then LootType = "Crate" StopLootFarm() StartLootFarm() else StopLootFarm() end
end)

CreateToggle(Pages["Misc"], "Auto-Farm: Airdrops", false, function(v)
    if v then LootType = "Airdrop" StopLootFarm() StartLootFarm() else StopLootFarm() end
end)

local AutoBuildActive = false
CreateToggle(Pages["Misc"], "Auto-Build Base", false, function(v)
    AutoBuildActive = v
    task.spawn(function()
        local vu = game:GetService("VirtualUser")
        while AutoBuildActive do
            for _, gui in ipairs(PG:GetDescendants()) do
                if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                    local txt = gui:IsA("TextButton") and gui.Text:lower() or ""
                    if txt:find("build") or txt:find("buy") or txt:find("upgrade") then
                        pcall(function()
                            vu:CaptureController()
                            vu:ClickButton1(gui.AbsolutePosition + (gui.AbsoluteSize / 2))
                        end)
                        task.wait(0.1)
                    end
                end
            end
            task.wait(1)
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════
--  PART 17-20: MISC, SPY, PROFILES
-- ═══════════════════════════════════════════════════════════

CreateToggle(Pages["Misc"], "Anti-Ragdoll", false, function(v)
    if v then
        MM.AntiRag = RunService.Heartbeat:Connect(function()
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum:GetState() == Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    else
        if MM.AntiRag then MM.AntiRag:Disconnect() MM.AntiRag = nil end
    end
end)

local RemoteSpyActive = false
CreateToggle(Pages["Misc"], "Remote Spy (Console)", false, function(v)
    RemoteSpyActive = v
    if v and not MM.SpyHooked then
        MM.SpyHooked = true
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if RemoteSpyActive and (method == "FireServer" or method == "InvokeServer") then
                print("[RemoteSpy] " .. method .. " -> " .. tostring(self))
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

CreateButton(Pages["Players"], "Profile: Nearest", function()
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
    if best then
        print("👤 PROFILE: " .. best.Name .. " | UID: " .. best.UserId .. " | Age: " .. best.AccountAge)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  PART 24-26: TARGET NUKE, LAUNCH, SPECTATE
-- ═══════════════════════════════════════════════════════════

local function AddTargetTab()
    if TabButtons["Target"] then return end
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 40)
    Btn.Position = UDim2.new(0, 10, 0, 70 + (9 * 45))
    Btn.BackgroundColor3 = T.Sidebar Btn.BackgroundTransparency = 1
    Btn.Text = "  🎯   Target" Btn.TextColor3 = T.SubText
    Btn.Font = Enum.Font.GothamMedium Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.AutoButtonColor = false Btn.BorderSizePixel = 0
    Btn.Parent = Sidebar Corner(Btn, 8)
    TabButtons["Target"] = Btn

    local Page = Instance.new("ScrollingFrame")
    Page.Name = "Target" Page.Size = UDim2.new(1, -200, 1, -120) 
    Page.Position = UDim2.new(0, 190, 0, 110)
    Page.BackgroundTransparency = 1 Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollBarThickness = 3
    Page.BorderSizePixel = 0 Page.Parent = Main
    local L = Instance.new("UIListLayout", Page)
    L.Padding = UDim.new(0, 10) Pages["Target"] = Page
    Btn.MouseButton1Click:Connect(function() SelectTab("Target") end)
end
AddTargetTab()

local TargetSystem = { Subject = nil, LastExplode = 0, AutoNuke = false, NukeDelay = 1.5 }

local function CreateNuke(pos)
    local ex = Instance.new("Explosion")
    ex.Position = pos
    ex.BlastRadius = 35
    ex.BlastPressure = 1000000
    ex.DestroyJointRadiusPercent = 1
    ex.Parent = workspace
end

local function StartSpectate(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    TargetSystem.Subject = targetPlayer
    local hum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        Camera.CameraSubject = hum
        Camera.CameraType = Enum.CameraType.Custom
    end
end

task.defer(function()
    task.wait(0.5)
    local page = Pages["Target"]
    if not page then return end

    local btnSpectate = Instance.new("TextButton")
    btnSpectate.Size = UDim2.new(1, 0, 0, 46)
    btnSpectate.BackgroundColor3 = T.Accent
    btnSpectate.Text = "👁 Spectate Nearest"
    btnSpectate.TextColor3 = Color3.new(1,1,1)
    btnSpectate.Font = Enum.Font.GothamBold
    btnSpectate.Parent = page Corner(btnSpectate, 8)
    btnSpectate.MouseButton1Click:Connect(function()
        local target = GetClosestTarget(9999, 99999)
        if target and target.Parent then StartSpectate(target.Parent) end
    end)

    local btnNuke = Instance.new("TextButton")
    btnNuke.Size = UDim2.new(1, 0, 0, 46)
    btnNuke.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    btnNuke.Text = "☢ Nuke Target Now"
    btnNuke.TextColor3 = Color3.new(1,1,1)
    btnNuke.Font = Enum.Font.GothamBold
    btnNuke.Parent = page Corner(btnNuke, 8)
    btnNuke.MouseButton1Click:Connect(function()
        if TargetSystem.Subject and TargetSystem.Subject.Character then
            local hrp = TargetSystem.Subject.Character:FindFirstChild("HumanoidRootPart")
            if hrp then CreateNuke(hrp.Position) end
        end
    end)

    local toggleAuto = Instance.new("TextButton")
    toggleAuto.Size = UDim2.new(1, 0, 0, 46)
    toggleAuto.BackgroundColor3 = T.Surface
    toggleAuto.Text = "Auto-Nuke (1.5s)"
    toggleAuto.TextColor3 = T.Text
    toggleAuto.Font = Enum.Font.GothamBold
    toggleAuto.Parent = page Corner(toggleAuto, 8)
    toggleAuto.MouseButton1Click:Connect(function()
        TargetSystem.AutoNuke = not TargetSystem.AutoNuke
        toggleAuto.BackgroundColor3 = TargetSystem.AutoNuke and Color3.fromRGB(0, 200, 0) or T.Surface
    end)

    local btnLaunch = Instance.new("TextButton")
    btnLaunch.Size = UDim2.new(1, 0, 0, 46)
    btnLaunch.BackgroundColor3 = Color3.fromRGB(30, 100, 200)
    btnLaunch.Text = "🚀 Launch Target"
    btnLaunch.TextColor3 = Color3.new(1,1,1)
    btnLaunch.Font = Enum.Font.GothamBold
    btnLaunch.Parent = page Corner(btnLaunch, 8)
    btnLaunch.MouseButton1Click:Connect(function()
        if TargetSystem.Subject and TargetSystem.Subject.Character then
            local hrp = TargetSystem.Subject.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.new(0, 1000, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(math.random(-99,99), math.random(-99,99), math.random(-99,99))
                for _, v in pairs(TargetSystem.Subject.Character:GetDescendants()) do
                    if v:IsA("Motor6D") then v:Destroy() end
                end
            end
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    if TargetSystem.AutoNuke and TargetSystem.Subject and TargetSystem.Subject.Character then
        local now = tick()
        if now - TargetSystem.LastExplode > TargetSystem.NukeDelay then
            TargetSystem.LastExplode = now
            local hrp = TargetSystem.Subject.Character:FindFirstChild("HumanoidRootPart")
            if hrp then CreateNuke(hrp.Position) end
        end
    end
end)

RunService:BindToRenderStep("MeowRenderFix", Enum.RenderPriority.Camera.Value + 3, function()
    UpdateCrosshair()
end)

print("[MeowUI] Part 26 Loaded — Target Tab, Nuke, Launch ready.")
]]

-- 3. Склеиваем и запускаем
local finalCode = baseCode .. "\n" .. extraCode
print("[Loader] Склейка завершена. Очистка локалов...")

-- Снимаем лимит регистров (убираем local)
finalCode = finalCode:gsub("\nlocal%s+([%a_][%w_]*)%s*=", "\n%1 =")
finalCode = finalCode:gsub("\nlocal%s+([%a_][%w_]*)%s*,", "\n%1,")

print("[Loader] Компиляция...")
local fn, err = loadstring(finalCode, "@MeowMod_Master")
if not fn then
    return error("[Loader] Ошибка компиляции: " .. tostring(err))
end

print("[Loader] Запуск...")
local success, runErr = pcall(fn)
if not success then
    warn("[Loader] Ошибка выполнения: " .. tostring(runErr))
else
    print("[Loader] MeowMod полностью загружен! Идём воевать.")
end
