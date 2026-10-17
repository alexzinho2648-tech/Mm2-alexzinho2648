-- Aura MM2 - Versão otimizada (sem travar)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ⚠️ COLE AQUI O NOME DO REMOTE DE TIRO (se souber)
local SHOOT_REMOTE_NAME = "COLE_AQUI"

local espEnabled = true
local espObjects = {}
local espConns = {}
local grabEnabled = false
local grabConn = nil
local shootEnabled = false
local shootConn = nil
local killAllEnabled = false
local killAllConn = nil
local flyEnabled = false
local flyBodyVel = nil
local flyBodyGyro = nil
local flyConn = nil
local antiFlingEnabled = false
local antiFlingConn = nil

-- Caches para evitar lag
local cachedShootRemote = nil
local lastGrabCheck = 0
local lastShootCheck = 0
local lastRoleCheck = {}

pcall(function()
    local old = CoreGui:FindFirstChild("AuraMM2")
    if old then old:Destroy() end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AuraMM2"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

-- ===== BOTÃO FLUTUANTE (faca) =====
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 55, 0, 55)
floatBtn.Position = UDim2.new(0, 20, 0.5, -27)
floatBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
floatBtn.BorderSizePixel = 0
floatBtn.Text = "🔪"
floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 28
floatBtn.Visible = false
floatBtn.Parent = screenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(0, 12)
floatCorner.Parent = floatBtn

local fDrag, fDragIn, fDragStart, fStart
floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        fDrag = true; fDragStart = input.Position; fStart = floatBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then fDrag = false end
        end)
    end
end)
floatBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then fDragIn = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == fDragIn and fDrag then
        local d = input.Position - fDragStart
        floatBtn.Position = UDim2.new(fStart.X.Scale, fStart.X.Offset + d.X, fStart.Y.Scale, fStart.Y.Offset + d.Y)
    end
end)

-- ===== CÍRCULO DE GRAB =====
local grabCircle = Instance.new("TextButton")
grabCircle.Size = UDim2.new(0, 90, 0, 90)
grabCircle.Position = UDim2.new(0, 20, 0, 200)
grabCircle.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
grabCircle.BorderSizePixel = 0
grabCircle.Text = "GRAB"
grabCircle.TextColor3 = Color3.fromRGB(255, 255, 255)
grabCircle.Font = Enum.Font.GothamBold
grabCircle.TextSize = 14
grabCircle.Visible = false
grabCircle.Active = true
grabCircle.Parent = screenGui

local grabCircleCorner = Instance.new("UICorner")
grabCircleCorner.CornerRadius = UDim.new(1, 0)
grabCircleCorner.Parent = grabCircle

local grabStroke = Instance.new("UIStroke")
grabStroke.Color = Color3.fromRGB(255, 255, 255)
grabStroke.Thickness = 2
grabStroke.Transparency = 0.3
grabStroke.Parent = grabCircle

local gcDrag, gcDragIn, gcDragStart, gcStart
grabCircle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        gcDrag = true; gcDragStart = input.Position; gcStart = grabCircle.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then gcDrag = false end
        end)
    end
end)
grabCircle.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then gcDragIn = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == gcDragIn and gcDrag then
        local d = input.Position - gcDragStart
        grabCircle.Position = UDim2.new(gcStart.X.Scale, gcStart.X.Offset + d.X, gcStart.Y.Scale, gcStart.Y.Offset + d.Y)
    end
end)

-- ===== AVISO DE SHOOT =====
local shootNotice = Instance.new("Frame")
shootNotice.Size = UDim2.new(0, 200, 0, 60)
shootNotice.Position = UDim2.new(0.5, -100, 0, 100)
shootNotice.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
shootNotice.BorderSizePixel = 0
shootNotice.Visible = false
shootNotice.Active = true
shootNotice.Parent = screenGui

local snCorner = Instance.new("UICorner")
snCorner.CornerRadius = UDim.new(0, 10)
snCorner.Parent = shootNotice

local snStroke = Instance.new("UIStroke")
snStroke.Color = Color3.fromRGB(255, 255, 255)
snStroke.Thickness = 2
snStroke.Parent = shootNotice

local snLabel = Instance.new("TextLabel")
snLabel.Size = UDim2.new(1, 0, 1, 0)
snLabel.BackgroundTransparency = 1
snLabel.Text = "🎯 ATIRANDO NO MURDER"
snLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
snLabel.Font = Enum.Font.GothamBold
snLabel.TextSize = 16
snLabel.Parent = shootNotice

local snDrag, snDragIn, snDragStart, snStart
shootNotice.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        snDrag = true; snDragStart = input.Position; snStart = shootNotice.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then snDrag = false end
        end)
    end
end)
shootNotice.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then snDragIn = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == snDragIn and snDrag then
        local d = input.Position - snDragStart
        shootNotice.Position = UDim2.new(snStart.X.Scale, snStart.X.Offset + d.X, snStart.Y.Scale, snStart.Y.Offset + d.Y)
    end
end)

-- ===== FRAME PRINCIPAL =====
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 420)
mainFrame.Position = UDim2.new(0, 20, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Active = false
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "🔪 Aura MM2"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = mainFrame

local drag, dragIn, dragStart, startP
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = true; dragStart = input.Position; startP = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then drag = false end
        end)
    end
end)
title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragIn = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragIn and drag then
        local d = input.Position - dragStart
        mainFrame.Position = UDim2.new(startP.X.Scale, startP.X.Offset + d.X, startP.Y.Scale, startP.Y.Offset + d.Y)
    end
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -33, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- ===== ABAS =====
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(0.9, 0, 0, 35)
tabBar.Position = UDim2.new(0.05, 0, 0, 38)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local tabNames = {"Inocente", "Xerife", "Assassino", "Universal"}
local tabButtons = {}
local tabFrames = {}

for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.23, 0, 1, 0)
    btn.Position = UDim2.new((i-1) * 0.255, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.Parent = tabBar
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn
    tabButtons[name] = btn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.9, 0, 0, 290)
    frame.Position = UDim2.new(0.05, 0, 0, 80)
    frame.BackgroundTransparency = 1
    frame.Visible = (name == "Universal")
    frame.Parent = mainFrame
    tabFrames[name] = frame
end

-- ===== DETECÇÃO DE PAPEL (LEVE) =====
local function getRole(plr)
    local char = plr.Character
    if not char then return "Innocent" end
    local backpack = plr:FindFirstChild("Backpack")
    local hasKnife, hasGun = false, false
    local function check(c)
        if not c then return end
        for _, t in pairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("knife") then hasKnife = true
                elseif n:find("gun") or n:find("revolver") then hasGun = true end
            end
        end
    end
    check(backpack); check(char)
    if hasKnife then return "Murderer" end
    if hasGun then return "Sheriff" end
    return "Innocent"
end

local function findMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and getRole(p) == "Murderer" then return p end
    end
    return nil
end

-- ===== ESP (ATUALIZA A CADA 0.5s) =====
local function createESP(plr)
    if plr == player then return end
    local char = plr.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 180, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = hrp
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextStrokeTransparency = 0
    label.Parent = billboard
    local hl = Instance.new("Highlight")
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.Parent = char
    espObjects[plr] = {billboard = billboard, label = label, hl = hl, lastCheck = 0}

    local conn = RunService.Heartbeat:Connect(function()
        if not espEnabled then return end
        local o = espObjects[plr]
        if not o then return end
        local now = tick()
        if now - o.lastCheck < 0.5 then return end
        o.lastCheck = now
        local role = getRole(plr)
        if role == "Murderer" then
            label.Text = plr.Name .. " [MURDER]"
            label.TextColor3 = Color3.fromRGB(255, 60, 60)
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.fromRGB(255, 0, 0)
        elseif role == "Sheriff" then
            label.Text = plr.Name .. " [SHERIFF]"
            label.TextColor3 = Color3.fromRGB(60, 150, 255)
            hl.FillColor = Color3.fromRGB(0, 100, 255)
            hl.OutlineColor = Color3.fromRGB(0, 100, 255)
        else
            label.Text = plr.Name
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            hl.FillColor = Color3.fromRGB(200, 200, 200)
            hl.OutlineColor = Color3.fromRGB(200, 200, 200)
        end
    end)
    table.insert(espConns, conn)
end

local function removeESP(plr)
    local o = espObjects[plr]
    if o then
        pcall(function() o.billboard:Destroy() end)
        pcall(function() o.hl:Destroy() end)
        espObjects[plr] = nil
    end
end

local function setupESP()
    for _, p in pairs(Players:GetPlayers()) do createESP(p) end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(1); if espEnabled then createESP(p) end end)
end)
Players.PlayerRemoving:Connect(removeESP)

-- ===== GRAB GUN (COM THROTTLE 0.5s) =====
local function tryGrab()
    local now = tick()
    if now - lastGrabCheck < 0.5 then return end
    lastGrabCheck = now
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            local n = obj.Name:lower()
            if n:find("gun") or n:find("revolver") then
                pcall(function()
                    local handle = obj:FindFirstChild("Handle")
                    if handle then
                        obj.Parent = player.Backpack
                        handle.CFrame = hrp.CFrame
                    end
                end)
                break
            end
        end
    end
end

local function startGrab()
    if grabConn then return end
    grabCircle.Visible = true
    grabConn = RunService.Heartbeat:Connect(function() if grabEnabled then tryGrab() end end)
end

local function stopGrab()
    if grabConn then grabConn:Disconnect(); grabConn = nil end
    grabCircle.Visible = false
end

-- ===== SHOOT MURDER (SEM AIMBOT, LIMITADO) =====
local function startShoot()
    if shootConn then return end
    shootNotice.Visible = true
    cachedShootRemote = nil
    shootConn = RunService.RenderStepped:Connect(function()
        local now = tick()
        if now - lastShootCheck < 0.15 then return end
        lastShootCheck = now

        local m = findMurderer()
        if not m then return end
        local mc = m.Character
        if not mc then return end
        local mh = mc:FindFirstChild("HumanoidRootPart")
        if not mh then return end

        local gun = nil
        local function findGun(c)
            if not c then return end
            for _, t in pairs(c:GetChildren()) do
                if t:IsA("Tool") then
                    local n = t.Name:lower()
                    if n:find("gun") or n:find("revolver") then gun = t; return end
                end
            end
        end
        findGun(player:FindFirstChild("Backpack"))
        findGun(player.Character)
        if not gun then return end

        if not cachedShootRemote and SHOOT_REMOTE_NAME ~= "COLE_AQUI" then
            for _, obj in pairs(game:GetDescendants()) do
                if obj:IsA("RemoteEvent") and obj.Name == SHOOT_REMOTE_NAME then
                    cachedShootRemote = obj
                    break
                end
            end
        end

        if cachedShootRemote then
            pcall(function() cachedShootRemote:FireServer(mh.Position, mh) end)
        else
            pcall(function() gun:Activate() end)
        end
    end)
end

local function stopShoot()
    if shootConn then shootConn:Disconnect(); shootConn = nil end
    shootNotice.Visible = false
end

-- ===== KILL ALL =====
local function startKillAll()
    if killAllConn then return end
    killAllConn = RunService.Heartbeat:Connect(function()
        if not killAllEnabled then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum.Health = 0 end) end
            end
        end
    end)
end

-- ===== FLY =====
local function startFly()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand = true
    for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.P = 9e4
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp
    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBodyVel.Velocity = Vector3.zero
    flyBodyVel.Parent = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        local md = hum.MoveDirection
        local fd = Vector3.zero
        if md.Magnitude > 0 then fd = md.Unit * md.Magnitude end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then fd += Vector3.new(0,1,0) end
        if fd.Magnitude > 0 then
            flyBodyGyro.CFrame = cam.CFrame
            flyBodyVel.Velocity = fd.Unit * 60
        else
            flyBodyVel.Velocity = Vector3.zero
        end
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end
    end
end

-- ===== ANTI-FLING =====
local function startAntiFling()
    if antiFlingConn then return end
    antiFlingConn = RunService.Heartbeat:Connect(function()
        if not antiFlingEnabled then return end
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, v in pairs(hrp:GetChildren()) do
            if v:IsA("BodyAngularVelocity") or v:IsA("BodyVelocity") then
                if v.Name ~= "AuraFlyVel" then pcall(function() v:Destroy() end) end
            end
        end
    end)
end

-- ===== POPULAR ABAS =====
local infFrame = tabFrames["Inocente"]
local grabBtn = Instance.new("TextButton")
grabBtn.Size = UDim2.new(0.9, 0, 0, 45)
grabBtn.Position = UDim2.new(0.05, 0, 0, 10)
grabBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
grabBtn.Text = "Pegar Arma: OFF"
grabBtn.TextColor3 = Color3.fromRGB(255,255,255)
grabBtn.Font = Enum.Font.GothamBold
grabBtn.TextSize = 14
grabBtn.Parent = infFrame
local gc = Instance.new("UICorner"); gc.CornerRadius = UDim.new(0,8); gc.Parent = grabBtn

local infInfo = Instance.new("TextLabel")
infInfo.Size = UDim2.new(0.9, 0, 0, 60)
infInfo.Position = UDim2.new(0.05, 0, 0, 65)
infInfo.BackgroundTransparency = 1
infInfo.Text = "Pega a arma do Xerife\nde longe automaticamente"
infInfo.TextColor3 = Color3.fromRGB(150,150,150)
infInfo.Font = Enum.Font.Gotham
infInfo.TextSize = 11
infInfo.TextWrapped = true
infInfo.Parent = infFrame

grabBtn.MouseButton1Click:Connect(function()
    grabEnabled = not grabEnabled
    if grabEnabled then
        grabBtn.Text = "Pegar Arma: ON"
        grabBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        startGrab()
    else
        grabBtn.Text = "Pegar Arma: OFF"
        grabBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        stopGrab()
    end
end)

local shFrame = tabFrames["Xerife"]
local shootBtn = Instance.new("TextButton")
shootBtn.Size = UDim2.new(0.9, 0, 0, 100)
shootBtn.Position = UDim2.new(0.05, 0, 0, 10)
shootBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
shootBtn.Text = "🎯 ATIRAR NO MURDER\nOFF"
shootBtn.TextColor3 = Color3.fromRGB(255,255,255)
shootBtn.Font = Enum.lua
