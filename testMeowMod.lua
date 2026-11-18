-- Война Магнат | KizmoTek Studio | Delta (Android) | v3 | ollie
-- Multi-layer silent aim bypass + advanced ESP + smooth teleport + FOV ring

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============ CONFIG ============
local Cfg = {
    Aim = {
        Enabled=true, FOV=150, TeamCheck=true, FriendCheck=true, WallCheck=false,
        HitPart="Head", Predict=true, PredictStrength=0.165, PredictMax=0.35,
        Resolver=true, Jitter=0.08, PingComp=true,
        FireDelayMin=0.008, FireDelayMax=0.022, AutoFire=false, AutoFireRate=0.12,
        MagicBullet=true, Humanize=true, CurveStrength=0.02,
        Bypass={IndexHook=true, CFrameSpoof=true, MethodScramble=true, CameraJitter=true},
    },
    ESP = {
        Enabled=true, Box=true, Name=true, Distance=true, Health=true, HealthBar=true,
        Tracer=true, TracerOrigin="Bottom", Skeleton=false, Chams=false, Arrow=false,
        OffscreenArrow=true, GradientBox=true, Glow=true, TeamColor=true, DistanceFade=true,
        MaxDistance=2500, BoxColor=Color3.fromRGB(60,255,60), TextColor=Color3.fromRGB(255,255,255),
        TracerColor=Color3.fromRGB(255,60,60), ChamsColor=Color3.fromRGB(255,80,80),
        ChamsTransparency=0.35, ArrowColor=Color3.fromRGB(255,200,40),
    },
    FOV = { Enabled=true, Color=Color3.fromRGB(120,220,140), Thickness=1.5, Filled=false },
    Teleport = {
        Target=nil, Offset=Vector3.new(0,0,3), Smooth=true, SmoothTime=0.25,
        SafeLand=true, Behind=true, Cooldown=1.2,
    },
    Misc = { AntiFling=true, AntiVoid=true, NoClip=false, FPSBoost=false },
}

-- ============ STATE ============
local Running=true
local Conns={}
local ESPCache={}
local Tracks={}
local HookActive=false
local OrigNamecall, OrigIndex=nil
local LastShot=0
local LastAuto=0
local LastTP=0
local Locked=nil
local CachedTarget=nil

local function log(...) print("[WT v3]", ...) end
local function addConn(c) table.insert(Conns,c) return c end
local function now() return tick() end

-- ============ HELPERS ============
local function getChar(p) return p and p.Character end
local function getHum(p) local c=getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP(p) local c=getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end

local function getPing()
    local ok, p = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if ok and p then return p/1000 end
    return 0.05
end

local function isEnemy(p)
    if p==LP then return false end
    local h=getHum(p); if not h or h.Health<=0 then return false end
    if Cfg.Aim.TeamCheck and p.Team and LP.Team and p.Team==LP.Team then return false end
    if Cfg.Aim.FriendCheck then
        local ok,r=pcall(function() return LP:IsFriendsWith(p.UserId) end)
        if ok and r then return false end
    end
    return true
end

local function getHitPart(p, prefer)
    local c=getChar(p); if not c then return nil end
    return c:FindFirstChild(prefer or Cfg.Aim.HitPart) or c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
end

-- ============ TRACKER ============
addConn(RunService.Heartbeat:Connect(function()
    if not Running then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            local hrp=getHRP(p); local t=Tracks[p] or {hist={}}
            if hrp then
                local n=now()
                if t.last then
                    local dt=n-t.last
                    if dt>0.001 then t.vel=(hrp.Position-t.pos)/dt end
                end
                t.pos=hrp.Position; t.last=n
                table.insert(t.hist,{pos=hrp.Position,t=n})
                if #t.hist>12 then table.remove(t.hist,1) end
            end
            Tracks[p]=t
        end
    end
    for p in pairs(Tracks) do if not p.Parent then Tracks[p]=nil end end
end))

local function predictPos(p, part)
    local t=Tracks[p]; local base=part.Position
    if not Cfg.Aim.Predict or not t or not t.vel then return base end
    local hrp=getHRP(p)
    local dist = hrp and (Camera.CFrame.Position - hrp.Position).Magnitude or 100
    local ping = Cfg.Aim.PingComp and getPing() or 0.05
    local baseT = Cfg.Aim.PredictStrength * (dist/100)
    local travel = math.clamp(baseT + ping, 0, Cfg.Aim.PredictMax)
    local pred = base + t.vel * travel
    if Cfg.Aim.Resolver and #(t.hist or {})>=4 then
        local hist=t.hist; local avgV=Vector3.new()
        for i=2,#hist do
            local dt=hist[i].t-hist[i-1].t
            if dt>0.001 then avgV += (hist[i].pos-hist[i-1].pos)/dt end
        end
        avgV = avgV/(#hist-1)
        local var=(t.vel-avgV).Magnitude
        if var>50 then pred = base + avgV*travel*0.5 + t.vel*travel*0.5 end
    end
    return pred
end

local function jitter(v)
    local j=Cfg.Aim.Jitter
    return v + Vector3.new((math.random()-0.5)*j,(math.random()-0.5)*j,(math.random()-0.5)*j)
end

-- ============ TARGET ============
local function screenDist(part)
    local sp,on=Camera:WorldToViewportPoint(part.Position)
    if not on then return math.huge end
    local vp=Camera.ViewportSize; local c=Vector2.new(vp.X/2,vp.Y/2)
    return (Vector2.new(sp.X,sp.Y)-c).Magnitude
end

local function rayVisible(from,to)
    local p=RaycastParams.new()
    p.FilterType=Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances={LP.Character,Camera}
    return Workspace:Raycast(from,to-from,p)==nil
end

local function findTarget()
    if Locked and Locked.Parent and isEnemy(Locked) then return Locked end
    local best,bestD=nil,math.huge; local cp=Camera.CFrame.Position
    for _,p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local part=getHitPart(p)
            if part then
                local d=screenDist(part)
                if d<Cfg.Aim.FOV and d<bestD then
                    if Cfg.Aim.WallCheck then
                        if rayVisible(cp,part.Position) then best,bestD=p,d end
                    else best,bestD=p,d end
                end
            end
        end
    end
    return best
end

-- ============ FIRING ============
local lastTouch=0
addConn(UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        lastTouch=now()
    end
end))

local function isFiring()
    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return true end
    if UIS:IsMouseButtonPressed(Enum.UserInputType.Touch) then return true end
    if now()-lastTouch<0.15 then return true end
    return false
end

-- ============ SILENT AIM (MULTI-LAYER) ============
local function humanizeDir(dir)
    if not Cfg.Aim.Humanize then return dir end
    local s=Cfg.Aim.CurveStrength
    return dir + Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5)*s
end

local function buildRayArgs(method,args)
    if not Cfg.Aim.Enabled or not CachedTarget then return args end
    local part=getHitPart(CachedTarget); if not part then return args end
    local aimPos = jitter(predictPos(CachedTarget, part))

    -- Layer: CFrame spoof — сдвигаем origin на случайный малый вектор
    if Cfg.Aim.Bypass.CFrameSpoof and method=="Raycast" then
        local o=args[1]
        if typeof(o)=="Vector3" then
            args[1] = o + Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5)*0.02
        end
    end

    if method=="Raycast" then
        local origin=args[1]
        local dir=aimPos-origin
        if dir.Magnitude<0.05 then return args end
        args[2]=humanizeDir(dir)
        if Cfg.Aim.MagicBullet and typeof(args[4])=="RaycastParams" then
            pcall(function()
                args[4].FilterType=Enum.RaycastFilterType.Exclude
                args[4].FilterDescendantsInstances={LP.Character,Camera,CachedTarget.Character}
            end)
        end
        return args
    elseif method=="FindPartOnRay" or method=="FindPartOnRayWithIgnoreList" or method=="FindPartOnRayWithWhitelist" then
        local ray=args[1]
        if typeof(ray)=="Ray" then
            local d=aimPos-ray.Origin
            if d.Magnitude<0.05 then return args end
            args[1]=Ray.new(ray.Origin, humanizeDir(d))
        end
        return args
    end
    return args
end

local function installHook()
    if HookActive then return end
    local ok,err=pcall(function()
        OrigNamecall = hookmetamethod(game,"__namecall",newcclosure(function(self,...)
            if not Running or not Cfg.Aim.Enabled or not CachedTarget then return OrigNamecall(self,...) end
            local m=getnamecallmethod()
            if not (m=="Raycast" or m=="FindPartOnRay" or m=="FindPartOnRayWithIgnoreList" or m=="FindPartOnRayWithWhitelist") then
                return OrigNamecall(self,...)
            end
            if not isFiring() then return OrigNamecall(self,...) end
            local t=now()
            local delay=Cfg.Aim.FireDelayMin + math.random()*(Cfg.Aim.FireDelayMax-Cfg.Aim.FireDelayMin)
            if t-LastShot<delay then return OrigNamecall(self,...) end
            LastShot=t
            local args={...}
            args=buildRayArgs(m,args)
            return OrigNamecall(self, unpack(args))
        end))
    end)
    if ok then HookActive=true; log("namecall hook installed")
    else log("hook fail:",err) end

    -- Layer: __index hook — защита от чтения флагов античитом
    if Cfg.Aim.Bypass.IndexHook then
        local ok2=pcall(function()
            OrigIndex = hookmetamethod(game,"__index",newcclosure(function(self,key)
                if key=="Name" and self==LP.Character then return "LocalPlayer" end
                return OrigIndex(self,key)
            end))
        end)
        if ok2 then log("index hook installed") else log("index hook skipped") end
    end
end

local function removeHook()
    if not HookActive then return end
    pcall(function() hookmetamethod(game,"__namecall",OrigNamecall) end)
    if OrigIndex then pcall(function() hookmetamethod(game,"__index",OrigIndex) end) end
    HookActive=false
    log("hooks removed")
end

-- ============ RENDER LOOP ============
addConn(RunService.RenderStepped:Connect(function()
    if not Running then return end
    CachedTarget = Cfg.Aim.Enabled and findTarget() or nil
    if Cfg.Aim.AutoFire and CachedTarget and now()-LastAuto>=Cfg.Aim.AutoFireRate then
        LastAuto=now()
        pcall(function()
            local vim=game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(0,0,0,true,game,0)
            task.wait(0.01)
            vim:SendMouseButtonEvent(0,0,0,false,game,0)
        end)
    end
end))

-- ============ FOV RING ============
local FovCircle = Drawing.new("Circle")
FovCircle.Thickness = Cfg.FOV.Thickness
FovCircle.Color = Cfg.FOV.Color
FovCircle.Filled = false
FovCircle.NumSides = 64
FovCircle.Transparency = 0.6
FovCircle.Visible = false
addConn(RunService.RenderStepped:Connect(function()
    if not Running then return end
    local vp = Camera.ViewportSize
    FovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
    FovCircle.Radius = Cfg.Aim.FOV
    FovCircle.Color = Cfg.FOV.Color
    FovCircle.Thickness = Cfg.FOV.Thickness
    FovCircle.Filled = Cfg.FOV.Filled
    FovCircle.Visible = Cfg.FOV.Enabled and Cfg.Aim.Enabled
end))

-- ============ ESP ============
local function newD(class,props)
    local d=Drawing.new(class); for k,v in pairs(props) do d[k]=v end; return d
end

local function teamColorOf(p)
    if not Cfg.ESP.TeamColor then return Cfg.ESP.BoxColor end
    if p.Team then
        pcall(function() return p.Team.TeamColor.Color end)
        return p.Team and p.Team.TeamColor.Color or Cfg.ESP.BoxColor
    end
    return Cfg.ESP.BoxColor
end

local function mkEntry()
    return {
        box=newD("Square",{Thickness=1,Filled=false,Color=Cfg.ESP.BoxColor,Visible=false}),
        boxGlow=newD("Square",{Thickness=4,Filled=false,Color=Cfg.ESP.BoxColor,Transparency=0.7,Visible=false}),
        gradientTop=newD("Square",{Thickness=1,Filled=false,Color=Cfg.ESP.BoxColor,Visible=false}),
        name=newD("Text",{Size=14,Center=true,Outline=true,Color=Cfg.ESP.TextColor,Visible=false}),
        dist=newD("Text",{Size=12,Center=true,Outline=true,Color=Cfg.ESP.TextColor,Visible=false}),
        health=newD("Square",{Thickness=2,Filled=true,Color=Color3.fromRGB(60,255,60),Visible=false}),
        healthBg=newD("Square",{Thickness=1,Filled=true,Color=Color3.fromRGB(30,30,30),Visible=false}),
        tracer=newD("Line",{Thickness=1,Color=Cfg.ESP.TracerColor,Visible=false}),
        arrow=newD("Triangle",{Thickness=1,Filled=true,Color=Cfg.ESP.ArrowColor,Visible=false}),
        offArrow=newD("Triangle",{Thickness=1,Filled=true,Color=Cfg.ESP.ArrowColor,Visible=false}),
        skeleton={for i=1,10 do newD("Line",{Thickness=1,Color=Cfg.ESP.TextColor,Visible=false}) end},
    }
end

local function destroyEntry(e)
    for k,d in pairs(e) do
        if k=="skeleton" then for _,s in ipairs(d) do pcall(s.Remove,s) end
        elseif typeof(d)=="Instance" and d.Remove then pcall(d.Remove,d) end
    end
end

local function ensureEntry(p) ESPCache[p]=ESPCache[p] or mkEntry(); return ESPCache[p] end

local function hideAll(e)
    for k,d in pairs(e) do
        if k=="skeleton" then for _,s in ipairs(d) do s.Visible=false end
        else d.Visible=false end
    end
end

addConn(Players.PlayerRemoving:Connect(function(p)
    if ESPCache[p] then destroyEntry(ESPCache[p]); ESPCache[p]=nil end
    Tracks[p]=nil
    if Cfg.Teleport.Target==p then Cfg.Teleport.Target=nil end
end))

local ChamsInstances={}
local function setChams(p,on)
    local c=getChar(p)
    if not c then if ChamsInstances[p] then ChamsInstances[p]:Destroy(); ChamsInstances[p]=nil end return end
    if on then
        if not ChamsInstances[p] then
            local h=Instance.new("Highlight")
            h.Name="WTChams"; h.FillColor=Cfg.ESP.ChamsColor
            h.FillTransparency=Cfg.ESP.ChamsTransparency
            h.OutlineColor=Cfg.ESP.ChamsColor
            h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent=c; ChamsInstances[p]=h
        else
            ChamsInstances[p].FillColor=Cfg.ESP.ChamsColor
            ChamsInstances[p].FillTransparency=Cfg.ESP.ChamsTransparency
        end
    else
        if ChamsInstances[p] then pcall(function() ChamsInstances[p]:Destroy() end); ChamsInstances[p]=nil end
    end
end

addConn(RunService.RenderStepped:Connect(function()
    if not Running then return end
    if not Cfg.ESP.Enabled then
        for _,e in pairs(ESPCache) do hideAll(e) end
        for p in pairs(ChamsInstances) do setChams(p,false) end
        return
    end
    local vp=Camera.ViewportSize
    for _,p in ipairs(Players:GetPlayers()) do
        local e=ensureEntry(p)
        if p==LP then hideAll(e) continue end
        local c=getChar(p)
        local hrp=c and c:FindFirstChild("HumanoidRootPart")
        local hum=c and c:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health<=0 then hideAll(e); setChams(p,false) continue end
        local sp,onScreen=Camera:WorldToViewportPoint(hrp.Position)
        local dist=(Camera.CFrame.Position-hrp.Position).Magnitude
        local inRange = dist<=Cfg.ESP.MaxDistance
        local boxColor = teamColorOf(p)
        local alpha = 1
        if Cfg.ESP.DistanceFade then alpha = math.clamp(1-dist/Cfg.ESP.MaxDistance, 0.15, 1) end

        if onScreen and inRange then
            local height=2500/sp.Z; local width=2000/sp.Z
            local pos=Vector2.new(sp.X-width/2, sp.Y-height/2)

            if Cfg.ESP.Box then
                e.box.Size=Vector2.new(width,height); e.box.Position=pos
                e.box.Color=boxColor; e.box.Transparency=alpha*0.1; e.box.Visible=true
            else e.box.Visible=false end

            if Cfg.ESP.Glow then
                e.boxGlow.Size=Vector2.new(width+4,height+4); e.boxGlow.Position=pos-Vector2.new(2,2)
                e.boxGlow.Color=boxColor; e.boxGlow.Transparency=alpha*0.75; e.boxGlow.Visible=true
            else e.boxGlow.Visible=false end

            if Cfg.ESP.GradientBox then
                e.gradientTop.Size=Vector2.new(width,2); e.gradientTop.Position=pos
                e.gradientTop.Color=boxColor; e.gradientTop.Transparency=alpha*0.4; e.gradientTop.Visible=true
            else e.gradientTop.Visible=false end

            if Cfg.ESP.Name then
                e.name.Text=p.Name; e.name.Position=Vector2.new(sp.X,pos.Y-16)
                e.name.Color=Cfg.ESP.TextColor; e.name.Transparency=alpha; e.name.Visible=true
            else e.name.Visible=false end

            if Cfg.ESP.Distance then
                e.dist.Text="["..math.floor(dist).."m]"
                e.dist.Position=Vector2.new(sp.X,pos.Y-2)
                e.dist.Color=Cfg.ESP.TextColor; e.dist.Transparency=alpha; e.dist.Visible=true
            else e.dist.Visible=false end

            if Cfg.ESP.Health then
                local pct=hum.Health/math.max(hum.MaxHealth,1)
                local h=height*pct
                if Cfg.ESP.HealthBar then
                    e.healthBg.Size=Vector2.new(4,height); e.healthBg.Position=Vector2.new(pos.X-7,pos.Y)
                    e.healthBg.Color=Color3.fromRGB(20,20,20); e.healthBg.Visible=true
                else e.healthBg.Visible=false end
                e.health.Size=Vector2.new(3,h); e.health.Position=Vector2.new(pos.X-6,pos.Y+(height-h))
                e.health.Color=Color3.fromRGB(255*(1-pct),255*pct,0); e.health.Visible=true
            else e.health.Visible=false; e.healthBg.Visible=false end

            if Cfg.ESP.Tracer then
                local o
                if Cfg.ESP.TracerOrigin=="Top" then o=Vector2.new(vp.X/2,0)
                elseif Cfg.ESP.TracerOrigin=="Bottom" then o=Vector2.new(vp.X/2,vp.Y)
                elseif Cfg.ESP.TracerOrigin=="Left" then o=Vector2.new(0,vp.Y/2)
                else o=Vector2.new(vp.X,vp.Y/2) end
                e.tracer.From=o; e.tracer.To=Vector2.new(sp.X,pos.Y+height)
                e.tracer.Color=Cfg.ESP.TracerColor; e.tracer.Transparency=alpha; e.tracer.Visible=true
            else e.tracer.Visible=false end

            if Cfg.ESP.Arrow then
                e.arrow.Color=Cfg.ESP.ArrowColor; e.arrow.Visible=true
                local tx,ty=sp.X,pos.Y-22
                e.arrow.PointA=Vector2.new(tx,ty)
                e.arrow.PointB=Vector2.new(tx-6,ty-10)
                e.arrow.PointC=Vector2.new(tx+6,ty-10)
            else e.arrow.Visible=false end
            e.offArrow.Visible=false

            if Cfg.ESP.Skeleton and c then
                local pairsList={
                    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
                    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
                    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
                    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
                    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},
                }
                local segs={}
                for _,pr in ipairs(pairsList) do
                    local a=c:FindFirstChild(pr[1]); local b=c:FindFirstChild(pr[2])
                    if a and b then
                        local sa,onA=Camera:WorldToViewportPoint(a.Position)
                        local sb,onB=Camera:WorldToViewportPoint(b.Position)
                        if onA and onB then table.insert(segs,{Vector2.new(sa.X,sa.Y),Vector2.new(sb.X,sb.Y)}) end
                    end
                end
                for i=1,10 do
                    if i<=#segs then
                        e.skeleton[i].From=segs[i][1]; e.skeleton[i].To=segs[i][2]
                        e.skeleton[i].Color=boxColor; e.skeleton[i].Visible=true
                    else e.skeleton[i].Visible=false end
                end
            else for _,s in ipairs(e.skeleton) do s.Visible=false end end
        else
            -- offscreen arrow
            for k,d in pairs(e) do
                if k=="skeleton" then for _,s in ipairs(d) do s.Visible=false end
                else d.Visible=false end
            end
            if Cfg.ESP.OffscreenArrow and inRange then
                local dir3=(hrp.Position-Camera.CFrame.Position)
                if dir3.Magnitude>0.01 then
                    local dir=dir3.Unit
                    local camLook=Camera.CFrame.LookVector
                    local camRight=Camera.CFrame.RightVector
                    local camUp=Camera.CFrame.UpVector
                    local projRight=dir:Dot(camRight)
                    local projUp=dir:Dot(camUp)
                    local projFwd=dir:Dot(camLook)
                    local screenAng=math.atan2(projUp,projRight)
                    local cx,cy=vp.X/2,vp.Y/2
                    local rad=math.min(vp.X,vp.Y)*0.42
                    local ox=cx+math.cos(screenAng)*rad
                    local oy=cy+math.sin(screenAng)*rad
                    if projFwd<0 then ox=cx-math.cos(screenAng)*rad; oy=cy-math.sin(screenAng)*rad end
                    e.offArrow.Color=boxColor; e.offArrow.Visible=true
                    e.offArrow.PointA=Vector2.new(ox+math.cos(screenAng)*10,oy+math.sin(screenAng)*10)
                    e.offArrow.PointB=Vector2.new(ox+math.cos(screenAng+2.4)*7,oy+math.sin(screenAng+2.4)*7)
                    e.offArrow.PointC=Vector2.new(ox+math.cos(screenAng-2.4)*7,oy+math.sin(screenAng-2.4)*7)
                end
            end
        end

        if Cfg.ESP.Chams and Cfg.ESP.Enabled then setChams(p,true) else setChams(p,false) end
    end
    for p in pairs(ChamsInstances) do
        if not Cfg.ESP.Enabled or not Cfg.ESP.Chams then setChams(p,false) end
    end
end))

-- ============ TELEPORT ============
local function tpTo(pos, smooth)
    local hrp=getHRP(LP); if not hrp then return end
    if Cfg.Teleport.SafeLand then
        -- проверяем поверхность под целевой точкой
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances={LP.Character}
        local r=Workspace:Raycast(pos+Vector3.new(0,10,0), Vector3.new(0,-200,0), params)
        if r then pos = r.Position + Vector3.new(0,3,0) end
    end
    if smooth and Cfg.Teleport.Smooth then
        local from=hrp.CFrame
        local to=CFrame.new(pos+Vector3.new(0,3,0))
        local tween=TweenService:Create(hrp, TweenInfo.new(Cfg.Teleport.SmoothTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame=to})
        tween:Play()
    else
        hrp.CFrame = CFrame.new(pos+Vector3.new(0,3,0))
    end
end

local function tpToPlayer(p)
    if not p or not p.Character then return false end
    if now()-LastTP<Cfg.Teleport.Cooldown then return false end
    LastTP=now()
    local hrp=p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local pos=hrp.Position
    if Cfg.Teleport.Behind then
        -- позиция за спиной цели (по LookVector цели)
        pos = pos - hrp.CFrame.LookVector * 3
    end
    tpTo(pos, true)
    log("TP ->", p.Name)
    return true
end

-- ============ MISC ============
if Cfg.Misc.AntiFling then
    addConn(RunService.Heartbeat:Connect(function()
        if not Running then return end
        local hrp=getHRP(LP); if not hrp then return end
        local v=hrp.AssemblyLinearVelocity
        if v.Magnitude>500 then hrp.AssemblyLinearVelocity=Vector3.new() end
    end))
end

if Cfg.Misc.AntiVoid then
    addConn(RunService.Heartbeat:Connect(function()
        if not Running then return end
        local hrp=getHRP(LP); if not hrp then return end
        if hrp.Position.Y<-100 then hrp.CFrame=CFrame.new(0,50,0) end
    end))
end

if Cfg.Misc.NoClip then
    addConn(RunService.Stepped:Connect(function()
        if not Running then return end
        local c=LP.Character; if not c then return end
        for _,v in ipairs(c:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide=false end
        end
    end))
end

if Cfg.Misc.FPSBoost then
    pcall(function()
        settings().Rendering.QualityLevel=Enum.QualityLevel.Level01
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled=false end
        end
        Lighting.GlobalShadows=false; Lighting.FogEnd=9e9
    end)
end

-- ============ UI ============
local oldGui=CoreGui:FindFirstChild("WarTycoonUI"); if oldGui then oldGui:Destroy() end
local SG=Instance.new("ScreenGui"); SG.Name="WarTycoonUI"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.Parent=CoreGui

local Main=Instance.new("Frame")
Main.Size=UDim2.fromOffset(600,420); Main.Position=UDim2.new(0.5,-300,0.5,-210)
Main.BackgroundColor3=Color3.fromRGB(14,14,18); Main.BorderSizePixel=0
Main.Active=true; Main.Draggable=true; Main.Parent=SG
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,10)
local Stroke=Instance.new("UIStroke",Main); Stroke.Color=Color3.fromRGB(60,200,100); Stroke.Thickness=1

local TitleBar=Instance.new("Frame")
TitleBar.Size=UDim2.new(1,0,0,38); TitleBar.BackgroundColor3=Color3.fromRGB(24,24,30)
TitleBar.BorderSizePixel=0; TitleBar.Parent=Main
Instance.new("UICorner",TitleBar).CornerRadius=UDim.new(0,10)

local TitleLbl=Instance.new("TextLabel")
TitleLbl.Size=UDim2.new(1,-140,1,0); TitleLbl.Position=UDim2.fromOffset(14,0)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="WarTycoon v3  |  ollie"
TitleLbl.TextColor3=Color3.fromRGB(220,220,230); TitleLbl.Font=Enum.Font.GothamBold
TitleLbl.TextSize=14; TitleLbl.TextXAlignment=Enum.TextXAlignment.Left; TitleLbl.Parent=TitleBar

local function mkTbBtn(text,x,w,color)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromOffset(w,26); b.Position=UDim2.fromOffset(x,6)
    b.BackgroundColor3=color or Color3.fromRGB(46,46,56)
    b.Text=text; b.TextColor3=Color3.fromRGB(230,230,240)
    b.Font=Enum.Font.GothamBold; b.TextSize=12; b.BorderSizePixel=0; b.Parent=TitleBar
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
    return b
end
local MinBtn=mkTbBtn("—",600-112,28)
local UnloadBtn=mkTbBtn("Unload",600-78,42)
local CloseBtn=mkTbBtn("X",600-30,24,Color3.fromRGB(180,40,40))

local Content=Instance.new("Frame")
Content.Size=UDim2.new(1,-20,1,-52); Content.Position=UDim2.fromOffset(10,46)
Content.BackgroundTransparency=1; Content.Parent=Main

-- tabs
local TabBar=Instance.new("Frame")
TabBar.Size=UDim2.new(1,0,0,30); TabBar.BackgroundTransparency=1; TabBar.Parent=Content
local function mkTab(text,x)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromOffset(108,28); b.Position=UDim2.fromOffset(x,0)
    b.BackgroundColor3=Color3.fromRGB(34,34,44); b.Text=text
    b.TextColor3=Color3.fromRGB(220,220,230); b.Font=Enum.Font.GothamBold
    b.TextSize=12; b.BorderSizePixel=0; b.Parent=TabBar
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end
local tAim=mkTab("Aim",0)
local tESP=mkTab("ESP",112)
local tTP=mkTab("Teleport",224)
local tMisc=mkTab("Misc",336)

local Pages={}
local function mkPage()
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,1,-34); f.Position=UDim2.fromOffset(0,34)
    f.BackgroundTransparency=1; f.Parent=Content; f.Visible=false
    return f
end
Pages.Aim=mkPage(); Pages.ESP=mkPage(); Pages.TP=mkPage(); Pages.Misc=mkPage()
local TabButtons={Aim=tAim,ESP=tESP,TP=tTP,Misc=tMisc}
local function selectTab(name)
    for k,p in pairs(Pages) do p.Visible=(k==name) end
    for k,b in pairs(TabButtons) do
        b.BackgroundColor3=(k==name) and Color3.fromRGB(40,140,70) or Color3.fromRGB(34,34,44)
    end
end
tAim.MouseButton1Click:Connect(function() selectTab("Aim") end)
tESP.MouseButton1Click:Connect(function() selectTab("ESP") end)
tTP.MouseButton1Click:Connect(function() selectTab("Teleport") end)
tMisc.MouseButton1Click:Connect(function() selectTab("Misc") end)
selectTab("Aim")

-- builders
local function mkToggle(parent,label,get,set,x,y)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromOffset(184,26); b.Position=UDim2.fromOffset(x,y)
    b.BackgroundColor3=Color3.fromRGB(36,36,46); b.TextColor3=Color3.fromRGB(230,230,240)
    b.Font=Enum.Font.Gotham; b.TextSize=12; b.BorderSizePixel=0; b.Parent=parent
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
    local function ref()
        local v=get(); b.Text=label..": "..(v and "ON" or "OFF")
        b.BackgroundColor3=v and Color3.fromRGB(40,120,60) or Color3.fromRGB(60,40,40)
    end
    b.MouseButton1Click:Connect(function() set(not get()); ref() end); ref()
    return b
end

local function mkSlider(parent,label,x,y,minV,maxV,get,set,isFloat)
    local holder=Instance.new("Frame"); holder.Size=UDim2.fromOffset(285,30)
    holder.Position=UDim2.fromOffset(x,y); holder.BackgroundTransparency=1; holder.Parent=parent
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,0,13)
    lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.fromRGB(220,220,230)
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=label..": "..tostring(get()); lbl.Parent=holder
    local bar=Instance.new("Frame"); bar.Size=UDim2.new(1,0,0,7); bar.Position=UDim2.fromOffset(0,16)
    bar.BackgroundColor3=Color3.fromRGB(36,36,46); bar.BorderSizePixel=0; bar.Parent=holder
    Instance.new("UICorner",bar).CornerRadius=UDim.new(0,3)
    local fill=Instance.new("Frame"); fill.Size=UDim2.new((get()-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(120,220,140); fill.BorderSizePixel=0; fill.Parent=bar
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,3)
    local drag=false
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local rel=math.clamp((i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
            local v=minV+(maxV-minV)*rel
            if not isFloat then v=math.floor(v) end
            set(v); fill.Size=UDim2.new(rel,0,1,0); lbl.Text=label..": "..tostring(v)
        end
    end)
    return holder
end

local function mkDropdown(parent,label,options,get,set,x,y)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.fromOffset(285,26); btn.Position=UDim2.fromOffset(x,y)
    btn.BackgroundColor3=Color3.fromRGB(44,44,54); btn.TextColor3=Color3.fromRGB(230,230,240)
    btn.Font=Enum.Font.Gotham; btn.TextSize=12; btn.BorderSizePixel=0; btn.Parent=parent
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
    btn.Text=label..": "..tostring(get())
    local dd=Instance.new("ScrollingFrame")
    dd.Size=UDim2.fromOffset(285,120); dd.Position=UDim2.fromOffset(x,y+28)
    dd.BackgroundColor3=Color3.fromRGB(22,22,28); dd.BorderSizePixel=0
    dd.Visible=false; dd.ScrollBarThickness=4
    dd.CanvasSize=UDim2.new(0,0,0,#options*26); dd.Parent=parent
    Instance.new("UICorner",dd).CornerRadius=UDim.new(0,4)
    for i,opt in ipairs(options) do
        local ob=Instance.new("TextButton")
        ob.Size=UDim2.new(1,-4,0,24); ob.Position=UDim2.fromOffset(2,(i-1)*26)
        ob.BackgroundColor3=Color3.fromRGB(38,38,48); ob.Text=tostring(opt)
        ob.TextColor3=Color3.fromRGB(220,220,230); ob.Font=Enum.Font.Gotham
        ob.TextSize=12; ob.BorderSizePixel=0; ob.Parent=dd
        Instance.new("UICorner",ob).CornerRadius=UDim.new(0,3)
        ob.MouseButton1Click:Connect(function() set(opt); btn.Text=label..": "..tostring(opt); dd.Visible=false end)
    end
    btn.MouseButton1Click:Connect(function() dd.Visible=not dd.Visible end)
    return btn
end

-- AIM page
local A=Pages.Aim
mkToggle(A,"Silent Aim",function() return Cfg.Aim.Enabled end,function(v) Cfg.Aim.Enabled=v end,0,0)
mkToggle(A,"Team Check",function() return Cfg.Aim.TeamCheck end,function(v) Cfg.Aim.TeamCheck=v end,192,0)
mkToggle(A,"Friend Check",function() return Cfg.Aim.FriendCheck end,function(v) Cfg.Aim.FriendCheck=v end,384,0)
mkToggle(A,"Wall Check",function() return Cfg.Aim.WallCheck end,function(v) Cfg.Aim.WallCheck=v end,0,32)
mkToggle(A,"Predict",function() return Cfg.Aim.Predict end,function(v) Cfg.Aim.Predict=v end,192,32)
mkToggle(A,"Resolver",function() return Cfg.Aim.Resolver end,function(v) Cfg.Aim.Resolver=v end,384,32)
mkToggle(A,"Ping Comp",function() return Cfg.Aim.PingComp end,function(v) Cfg.Aim.PingComp=v end,0,64)
mkToggle(A,"Magic Bullet",function() return Cfg.Aim.MagicBullet end,function(v) Cfg.Aim.MagicBullet=v end,192,64)
mkToggle(A,"Humanize",function() return Cfg.Aim.Humanize end,function(v) Cfg.Aim.Humanize=v end,384,64)
mkToggle(A,"Auto Fire",function() return Cfg.Aim.AutoFire end,function(v) Cfg.Aim.AutoFire=v end,0,96)
mkToggle(A,"Idx Bypass",function() return Cfg.Aim.Bypass.IndexHook end,function(v) Cfg.Aim.Bypass.IndexHook=v end,192,96)
mkToggle(A,"CFrame Spoof",function() return Cfg.Aim.Bypass.CFrameSpoof end,function(v) Cfg.Aim.Bypass.CFrameSpoof=v end,384,96)
mkToggle(A,"FOV Ring",function() return Cfg.FOV.Enabled end,function(v) Cfg.FOV.Enabled=v end,0,128)
mkToggle(A,"FOV Fill",function() return Cfg.FOV.Filled end,function(v) Cfg.FOV.Filled=v end,192,128)
mkSlider(A,"FOV Radius",0,162,10,600,function() return Cfg.Aim.FOV end,function(v) Cfg.Aim.FOV=v end)
mkSlider(A,"Predict Str",300,162,0,1,function() return Cfg.Aim.PredictStrength end,function(v) Cfg.Aim.PredictStrength=v end,true)
mkSlider(A,"Jitter",0,196,0,0.5,function() return Cfg.Aim.Jitter end,function(v) Cfg.Aim.Jitter=v end,true)
mkSlider(A,"AutoRate",300,196,0.02,0.5,function() return Cfg.Aim.AutoFireRate end,function(v) Cfg.Aim.AutoFireRate=v end,true)
mkDropdown(A,"Hit Part",{"Head","HumanoidRootPart","Torso","UpperTorso"},function() return Cfg.Aim.HitPart end,function(v) Cfg.Aim.HitPart=v end,0,230)

-- ESP page
local E=Pages.ESP
mkToggle(E,"ESP",function() return Cfg.ESP.Enabled end,function(v) Cfg.ESP.Enabled=v end,0,0)
mkToggle(E,"Box",function() return Cfg.ESP.Box end,function(v) Cfg.ESP.Box=v end,192,0)
mkToggle(E,"Gradient",function() return Cfg.ESP.GradientBox end,function(v) Cfg.ESP.GradientBox=v end,384,0)
mkToggle(E,"Glow",function() return Cfg.ESP.Glow end,function(v) Cfg.ESP.Glow=v end,0,32)
mkToggle(E,"Name",function() return Cfg.ESP.Name end,function(v) Cfg.ESP.Name=v end,192,32)
mkToggle(E,"Distance",function() return Cfg.ESP.Distance end,function(v) Cfg.ESP.Distance=v end,384,32)
mkToggle(E,"Health",function() return Cfg.ESP.Health end,function(v) Cfg.ESP.Health=v end,0,64)
mkToggle(E,"HealthBar",function() return Cfg.ESP.HealthBar end,function(v) Cfg.ESP.HealthBar=v end,192,64)
mkToggle(E,"Skeleton",function() return Cfg.ESP.Skeleton end,function(v) Cfg.ESP.Skeleton=v end,384,64)
mkToggle(E,"Chams",function() return Cfg.ESP.Chams end,function(v) Cfg.ESP.Chams=v end,0,96)
mkToggle(E,"Tracer",function() return Cfg.ESP.Tracer end,function(v) Cfg.ESP.Tracer=v end,192,96)
mkToggle(E,"Arrow",function() return Cfg.ESP.Arrow end,function(v) Cfg.ESP.Arrow=v end,384,96)
mkToggle(E,"Offscreen",function() return Cfg.ESP.OffscreenArrow end,function(v) Cfg.ESP.OffscreenArrow=v end,0,128)
mkToggle(E,"Team Color",function() return Cfg.ESP.TeamColor end,function(v) Cfg.ESP.TeamColor=v end,192,128)
mkToggle(E,"Dist Fade",function() return Cfg.ESP.DistanceFade end,function(v) Cfg.ESP.DistanceFade=v end,384,128)
mkSlider(E,"Max Dist",0,162,200,5000,function() return Cfg.ESP.MaxDistance end,function(v) Cfg.ESP.MaxDistance=v end)
mkDropdown(E,"Tracer Origin",{"Top","Bottom","Left","Right"},function() return Cfg.ESP.TracerOrigin end,function(v) Cfg.ESP.TracerOrigin=v end,0,200)

-- TELEPORT page
local T=Pages.TP
local TpBtn=Instance.new("TextButton")
TpBtn.Size=UDim2.fromOffset(285,30); TpBtn.Position=UDim2.fromOffset(0,0)
TpBtn.BackgroundColor3=Color3.fromRGB(50,80,130); TpBtn.TextColor3=Color3.fromRGB(230,230,240)
TpBtn.Font=Enum.Font.GothamBold; TpBtn.TextSize=13; TpBtn.BorderSizePixel=0; TpBtn.Parent=T
Instance.new("UICorner",TpBtn).CornerRadius=UDim.new(0,5)
TpBtn.Text="Select Target"

local SearchBox=Instance.new("TextBox")
SearchBox.Size=UDim2.fromOffset(285,26); SearchBox.Position=UDim2.fromOffset(0,36)
SearchBox.BackgroundColor3=Color3.fromRGB(36,36,46); SearchBox.TextColor3=Color3.fromRGB(220,220,230)
SearchBox.PlaceholderText="Search player..."; SearchBox.PlaceholderColor3=Color3.fromRGB(120,120,130)
SearchBox.Font=Enum.Font.Gotham; SearchBox.TextSize=12; SearchBox.BorderSizePixel=0; SearchBox.Parent=T
Instance.new("UICorner",SearchBox).CornerRadius=UDim.new(0,4)

local TPdd=Instance.new("ScrollingFrame")
TPdd.Size=UDim2.fromOffset(285,215); TPdd.Position=UDim2.fromOffset(0,68)
TPdd.BackgroundColor3=Color3.fromRGB(22,22,28); TPdd.BorderSizePixel=0
TPdd.ScrollBarThickness=4; TPdd.CanvasSize=UDim2.new(0,0,0,0)
TPdd.AutomaticCanvasSize=Enum.AutomaticSize.Y; TPdd.Parent=T
Instance.new("UICorner",TPdd).CornerRadius=UDim.new(0,4)

local tpButtons={}
local function refreshTP()
    for _,c in ipairs(TPdd:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    tpButtons={}
    local q=SearchBox.Text:lower()
    local list={}
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(list,p) end end
    table.sort(list,function(a,b) return a.Name<b.Name end)
    for i,p in ipairs(list) do
        if q=="" or p.Name:lower():find(q,1,true) then
            local hrp=getHRP(p)
            local dist = hrp and math.floor((hrp.Position-LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.HumanoidRootPart.Position or Vector3.new()).Magnitude) or 0
            local isFriend = false
            pcall(function() isFriend = LP:IsFriendsWith(p.UserId) end)
            local b=Instance.new("TextButton")
            b.Size=UDim2.new(1,-4,0,26); b.Position=UDim2.fromOffset(2,(i-1)*28)
            b.BackgroundColor3=isFriend and Color3.fromRGB(40,60,40) or Color3.fromRGB(38,38,48)
            b.Text=p.Name.."  ["..dist.."m]"..(isFriend and "  ♥" or "")
            b.TextColor3=Color3.fromRGB(220,220,230); b.Font=Enum.Font.Gotham
            b.TextSize=12; b.BorderSizePixel=0; b.Parent=TPdd
            Instance.new("UICorner",b).CornerRadius=UDim.new(0,3)
            b.MouseButton1Click:Connect(function()
                Cfg.Teleport.Target=p; TpBtn.Text="TP: "..p.Name
                TpBtn.BackgroundColor3=Color3.fromRGB(40,120,60)
                tpToPlayer(p)
            end)
        end
    end
end
refreshTP()
SearchBox:GetPropertyChangedSignal("Text"):Connect(refreshTP)
Players.PlayerAdded:Connect(function() task.wait(1) refreshTP() end)
Players.PlayerRemoving:Connect(function() task.wait(0.1) refreshTP() end)

mkToggle(T,"Smooth TP",function() return Cfg.Teleport.Smooth end,function(v) Cfg.Teleport.Smooth=v end,0,290)
mkToggle(T,"Safe Land",function() return Cfg.Teleport.SafeLand end,function(v) Cfg.Teleport.SafeLand=v end,192,290)
mkToggle(T,"Behind Target",function() return Cfg.Teleport.Behind end,function(v) Cfg.Teleport.Behind=v end,0,322)
mkSlider(T,"Smooth Time",0,356,0.05,1,function() return Cfg.Teleport.SmoothTime end,function(v) Cfg.Teleport.SmoothTime=v end,true)

-- MISC page
local M=Pages.Misc
mkToggle(M,"Anti Fling",function() return Cfg.Misc.AntiFling end,function(v) Cfg.Misc.AntiFling=v end,0,0)
mkToggle(M,"Anti Void",function() return Cfg.Misc.AntiVoid end,function(v) Cfg.Misc.AntiVoid=v end,192,0)
mkToggle(M,"NoClip",function() return Cfg.Misc.NoClip end,function(v) Cfg.Misc.NoClip=v end,384,0)
mkToggle(M,"FPS Boost",function() return Cfg.Misc.FPSBoost end,function(v) Cfg.Misc.FPSBoost=v end,0,32)

-- UI buttons
local minimized=false
MinBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    Main.Size = minimized and UDim2.fromOffset(600,38) or UDim2.fromOffset(600,420)
    Content.Visible = not minimized
end)

local function unloadAll()
    Running=false
    removeHook()
    pcall(function() FovCircle:Remove() end)
    for _,c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
    for _,e in pairs(ESPCache) do destroyEntry(e) end
    for p in pairs(ChamsInstances) do setChams(p,false) end
    SG:Destroy()
    log("unloaded")
end
UnloadBtn.MouseButton1Click:Connect(unloadAll)
CloseBtn.MouseButton1Click:Connect(function() pcall(unloadAll) end)

installHook()
log("WarTycoon v3 loaded")
