-- =========================================================
-- SamMods Auto Defender · v6
-- Lista separada · Sem duplicar topbar · Intro épica
-- =========================================================

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Remotes     = ReplicatedStorage:WaitForChild("Remotes")

local HackEvent = Remotes:WaitForChild("HackEvent")
local MeleeHit  = Remotes:WaitForChild("MeleeHit")

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local TopbarPlus = require(Shared:WaitForChild("TopbarPlus"))

-- =========================================================
-- CORES
-- =========================================================
local CORES = {
    primaria   = Color3.fromRGB(0, 210, 255),
    secundaria = Color3.fromRGB(150, 90, 255),
    destaque   = Color3.fromRGB(255, 90, 200),
    fundo      = Color3.fromRGB(12, 11, 20),
    fundo2     = Color3.fromRGB(20, 18, 32),
    fundo3     = Color3.fromRGB(28, 25, 42),
    texto      = Color3.fromRGB(240, 242, 250),
    subtexto   = Color3.fromRGB(160, 165, 185),
    on         = Color3.fromRGB(70, 220, 140),
    idle       = Color3.fromRGB(255, 195, 70),
    off        = Color3.fromRGB(80, 82, 96),
    danger     = Color3.fromRGB(255, 90, 100),
}

local CONFIG = {
    ToolName        = "Baseball Bat",
    FollowOffset    = CFrame.new(0, 0, 3),
    AttemptDuration = 0.45,
    RetryDelay      = 0.55,
    EquipDelay      = 0.15,
    MeleeInterval   = 0.10,
    ToggleKey       = Enum.KeyCode.F6,
    ListToggleKey   = Enum.KeyCode.F7,
}

-- =========================================================
-- ESTADO GLOBAL (reuso)
-- =========================================================
_G.SamModsDefender = _G.SamModsDefender or {}
local STATE = _G.SamModsDefender

-- ⚡ DESTRÓI topbar antigo pra não duplicar
if STATE.icon then
    pcall(function() STATE.icon:destroy() end)
    STATE.icon = nil
end

-- ⚡ Destrói GUI antiga mas guarda posições
local oldGui = PlayerGui:FindFirstChild("SamModsAutoDefender")
if oldGui then
    local oldPanel = oldGui:FindFirstChild("Panel")
    if oldPanel then STATE.panelPos = oldPanel.Position end
    local oldList = oldGui:FindFirstChild("PlayersList")
    if oldList then STATE.listPos = oldList.Position end
    oldGui:Destroy()
end

local enabled          = STATE.enabled or false
local robberyActive    = false
local currentThief     = nil
local batAttemptedThisRobbery = false
local followConnection = nil
local defenseThread    = nil
local spectating       = nil
local spectateConn     = nil

-- =========================================================
-- HELPERS PERSONAGEM
-- =========================================================
local function getCharacter() return LocalPlayer.Character end
local function getRoot(player)
    local character = player and player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end
local function getHumanoid()
    local character = getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end
local function getBat()
    local character = getCharacter()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if character then
        local tool = character:FindFirstChild(CONFIG.ToolName)
        if tool and tool:IsA("Tool") then return tool end
    end
    if backpack then
        local tool = backpack:FindFirstChild(CONFIG.ToolName)
        if tool and tool:IsA("Tool") then return tool end
    end
end
local function equipBat()
    local humanoid = getHumanoid()
    local bat = getBat()
    if not humanoid or not bat then return false end
    if bat.Parent ~= getCharacter() then
        pcall(function() humanoid:EquipTool(bat) end)
        task.wait(CONFIG.EquipDelay)
    end
    local equipped = getCharacter() and getCharacter():FindFirstChild(CONFIG.ToolName)
    return equipped ~= nil and equipped:IsA("Tool")
end
local function unequipBat()
    local humanoid = getHumanoid()
    if humanoid then pcall(function() humanoid:UnequipTools() end) end
end
local function releaseFromThief()
    if followConnection then followConnection:Disconnect() followConnection = nil end
end
local function followThief(thief)
    releaseFromThief()
    local myRoot = getRoot(LocalPlayer)
    local thiefRoot = getRoot(thief)
    if not myRoot or not thiefRoot then return false end
    pcall(function() myRoot.CFrame = thiefRoot.CFrame * CONFIG.FollowOffset end)
    followConnection = RunService.Heartbeat:Connect(function()
        if not enabled or not robberyActive or currentThief ~= thief then
            releaseFromThief() return
        end
        local mine = getRoot(LocalPlayer)
        local target = getRoot(thief)
        if not mine or not target then releaseFromThief() return end
        pcall(function() mine.CFrame = target.CFrame * CONFIG.FollowOffset end)
    end)
    return true
end
local function fireMelee(thief)
    if not thief or not MeleeHit:IsA("RemoteEvent") then return false end
    return pcall(function() MeleeHit:FireServer(thief) end)
end
local function stopDefense(clearAttempt)
    releaseFromThief()
    currentThief = nil
    unequipBat()
    if clearAttempt then batAttemptedThisRobbery = false end
end
local function oneAttempt(thief)
    if not enabled or not robberyActive or not thief or batAttemptedThisRobbery then return end
    if thief.Parent ~= Players then return end
    if not getRoot(thief) then return end
    batAttemptedThisRobbery = true
    if not equipBat() then batAttemptedThisRobbery = false return end
    if not followThief(thief) then batAttemptedThisRobbery = false return end
    local started = os.clock()
    while enabled and robberyActive and currentThief == thief
        and (os.clock() - started) < CONFIG.AttemptDuration do
        if not getRoot(thief) then break end
        fireMelee(thief)
        task.wait(CONFIG.MeleeInterval)
    end
    releaseFromThief()
    unequipBat()
    updateUI()
end
local function startDefenseLoop()
    if defenseThread or not enabled or not robberyActive or not currentThief or batAttemptedThisRobbery then return end
    defenseThread = task.spawn(function()
        oneAttempt(currentThief)
        defenseThread = nil
        updateUI()
    end)
end
local function resolveThief(data)
    if typeof(data) ~= "table" then return nil end
    local ids = {
        tonumber(data.userId), tonumber(data.attackerUserId), tonumber(data.attackerId),
        tonumber(data.thiefUserId), tonumber(data.thiefId),
        tonumber(data.robberUserId), tonumber(data.robberId),
    }
    for _, id in ipairs(ids) do
        if id then
            local player = Players:GetPlayerByUserId(id)
            if player and player ~= LocalPlayer then return player end
        end
    end
    local names = { data.attackerName, data.thiefName, data.robberName, data.name }
    for _, name in ipairs(names) do
        if typeof(name) == "string" and name ~= "" then
            local player = Players:FindFirstChild(name)
            if player and player ~= LocalPlayer then return player end
        end
    end
end
local END_KINDS = {
    result = true, abort = true, ["end"] = true, ended = true,
    finish = true, finished = true, robbery_end = true, steal_end = true,
}

-- =========================================================
--  INTRO ÉPICA SAMMODS
-- =========================================================
local function playIntro()
    pcall(function()
        local old = PlayerGui:FindFirstChild("SamModsIntro")
        if old then old:Destroy() end
    end)

    local intro = Instance.new("ScreenGui")
    intro.Name           = "SamModsIntro"
    intro.ResetOnSpawn   = false
    intro.IgnoreGuiInset = true
    intro.DisplayOrder   = 9999
    intro.Parent         = PlayerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BorderSizePixel = 0
    bg.Parent = intro

    -- ============ FASE 1: MATRIX RAIN ============
    local matrix = Instance.new("Frame")
    matrix.Size = UDim2.fromScale(1, 1)
    matrix.BackgroundTransparency = 1
    matrix.Parent = bg

    local matrixConn
    local chars = {"S","A","M","M","O","D","S","0","1","2","3","4","5","6","7","8","9"}
    local drops = {}

    -- Cria colunas de matrix
    local numCols = math.floor(workspace.CurrentCamera.ViewportSize.X / 14)
    for i = 1, numCols do
        local column = Instance.new("Frame")
        column.BackgroundTransparency = 1
        column.Position = UDim2.fromOffset((i - 1) * 14, 0)
        column.Size = UDim2.fromOffset(14, workspace.CurrentCamera.ViewportSize.Y)
        column.Parent = matrix

        local colChars = {}
        local numRows = math.floor(workspace.CurrentCamera.ViewportSize.Y / 16)
        for j = 1, numRows do
            local c = Instance.new("TextLabel")
            c.BackgroundTransparency = 1
            c.Position = UDim2.fromOffset(0, (j - 1) * 16)
            c.Size = UDim2.fromOffset(14, 16)
            c.Font = Enum.Font.Code
            c.TextSize = 14
            c.Text = chars[math.random(1, #chars)]
            c.TextColor3 = CORES.primaria
            c.TextTransparency = 1
            c.Parent = column
            table.insert(colChars, c)
        end
        table.insert(drops, {
            chars = colChars,
            head = math.random(-30, 0),
            speed = math.random(18, 32) / 100,
            col = column
        })
    end

    matrixConn = RunService.RenderStepped:Connect(function(dt)
        for _, drop in ipairs(drops) do
            drop.head = drop.head + drop.speed * 60 * dt
            for idx, c in ipairs(drop.chars) do
                local dist = drop.head - idx
                if dist >= 0 and dist < 12 then
                    c.TextTransparency = 0.05 + dist * 0.08
                    c.TextColor3 = CORES.primaria
                elseif dist >= 12 and dist < 20 then
                    c.TextTransparency = 0.55 + (dist - 12) * 0.05
                    c.TextColor3 = CORES.primaria
                else
                    c.TextTransparency = 1
                end
                if math.random() < 0.02 then
                    c.Text = chars[math.random(1, #chars)]
                end
            end
            if drop.head > #drop.chars + 15 then
                drop.head = math.random(-40, -10)
                drop.speed = math.random(18, 32) / 100
            end
        end
    end)

    -- ============ FASE 2: GLITCH BARS ============
    task.spawn(function()
        task.wait(1.0)
        for i = 1, 8 do
            if not intro.Parent then return end
            local bar = Instance.new("Frame")
            bar.BackgroundColor3 = math.random() > 0.5 and CORES.primaria or CORES.secundaria
            bar.BackgroundTransparency = 0.7
            bar.BorderSizePixel = 0
            bar.Size = UDim2.new(1, 0, 0, math.random(3, 12))
            bar.Position = UDim2.new(0, 0, math.random(), 0)
            bar.ZIndex = 10
            bar.Parent = bg
            local finalY = bar.Position
            TweenService:Create(bar, TweenInfo.new(0.15), {
                Position = UDim2.new(finalY.X.Scale + math.random(-0.3, 0.3), 0, finalY.Y.Scale, 0),
                BackgroundTransparency = 1
            }):Play()
            task.delay(0.2, function() bar:Destroy() end)
            task.wait(0.08)
        end
    end)

    -- ============ FASE 3: HOLOGRAMA SAMMODS ============
    task.wait(1.4)

    local center = Instance.new("Frame")
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.Position = UDim2.fromScale(0.5, 0.5)
    center.Size = UDim2.fromOffset(560, 300)
    center.BackgroundTransparency = 1
    center.ZIndex = 20
    center.Parent = bg

    -- Glow atrás
    local glow = Instance.new("Frame")
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Position = UDim2.new(0.5, 0, 0, 60)
    glow.Size = UDim2.fromOffset(500, 160)
    glow.BackgroundColor3 = CORES.primaria
    glow.BackgroundTransparency = 1
    glow.BorderSizePixel = 0
    glow.ZIndex = 19
    glow.Parent = center
    Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)
    local gGrad = Instance.new("UIGradient")
    gGrad.Color = ColorSequence.new(CORES.primaria, CORES.secundaria)
    gGrad.Rotation = 45
    gGrad.Parent = glow

    -- Texto SAMMODS com reveal
    local titulo = Instance.new("TextLabel")
    titulo.AnchorPoint = Vector2.new(0.5, 0.5)
    titulo.Position = UDim2.new(0.5, 0, 0, 50)
    titulo.Size = UDim2.new(1, 0, 0, 62)
    titulo.BackgroundTransparency = 1
    titulo.Font = Enum.Font.GothamBlack
    titulo.TextSize = 58
    titulo.Text = "SAMMODS"
    titulo.TextColor3 = CORES.primaria
    titulo.TextTransparency = 1
    titulo.ZIndex = 21
    titulo.Parent = center

    local tg = Instance.new("UIGradient")
    tg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CORES.primaria),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, CORES.secundaria),
    })
    tg.Parent = titulo

    -- Scanline que passa pelo título
    local scanline = Instance.new("Frame")
    scanline.AnchorPoint = Vector2.new(0.5, 0.5)
    scanline.Position = UDim2.new(0.5, 0, 0, 20)
    scanline.Size = UDim2.new(1, 0, 0, 3)
    scanline.BackgroundColor3 = CORES.primaria
    scanline.BackgroundTransparency = 0.3
    scanline.BorderSizePixel = 0
    scanline.ZIndex = 22
    scanline.Parent = center

    -- Sombra
    local sombra = Instance.new("TextLabel")
    sombra.AnchorPoint = Vector2.new(0.5, 0.5)
    sombra.Position = UDim2.new(0.5, 0, 0, 53)
    sombra.Size = UDim2.new(1, 0, 0, 62)
    sombra.BackgroundTransparency = 1
    sombra.Font = Enum.Font.GothamBlack
    sombra.TextSize = 58
    sombra.Text = "SAMMODS"
    sombra.TextColor3 = CORES.secundaria
    sombra.TextTransparency = 1
    sombra.ZIndex = 20
    sombra.Parent = center

    -- Subtítulo
    local sub = Instance.new("TextLabel")
    sub.AnchorPoint = Vector2.new(0.5, 0.5)
    sub.Position = UDim2.new(0.5, 0, 0, 96)
    sub.Size = UDim2.new(1, 0, 0, 20)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.GothamBold
    sub.TextSize = 14
    sub.Text = "A U T O   D E F E N D E R"
    sub.TextColor3 = CORES.primaria
    sub.TextTransparency = 1
    sub.ZIndex = 21
    sub.Parent = center

    local badge = Instance.new("TextLabel")
    badge.AnchorPoint = Vector2.new(0.5, 0.5)
    badge.Position = UDim2.new(0.5, 0, 0, 124)
    badge.Size = UDim2.fromOffset(80, 18)
    badge.BackgroundColor3 = CORES.secundaria
    badge.BackgroundTransparency = 1
    badge.Font = Enum.Font.GothamBold
    badge.TextSize = 10
    badge.Text = "v6"
    badge.TextColor3 = Color3.new(1, 1, 1)
    badge.TextTransparency = 1
    badge.ZIndex = 21
    badge.Parent = center
    Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)

    -- Scanlines holográficas
    for i = 0, 40 do
        local line = Instance.new("Frame")
        line.BackgroundColor3 = CORES.primaria
        line.BackgroundTransparency = 0.92
        line.BorderSizePixel = 0
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, i / 40, 0)
        line.ZIndex = 18
        line.Parent = center
    end

    -- Barra de progresso
    local barBg = Instance.new("Frame")
    barBg.AnchorPoint = Vector2.new(0.5, 0.5)
    barBg.Position = UDim2.new(0.5, 0, 0, 200)
    barBg.Size = UDim2.fromOffset(400, 5)
    barBg.BackgroundColor3 = Color3.fromRGB(28, 24, 40)
    barBg.BackgroundTransparency = 1
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 21
    barBg.Parent = center
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = CORES.primaria
    barFill.BackgroundTransparency = 1
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
    local bfG = Instance.new("UIGradient")
    bfG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CORES.primaria),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, CORES.secundaria),
    })
    bfG.Parent = barFill

    local status = Instance.new("TextLabel")
    status.AnchorPoint = Vector2.new(0.5, 0.5)
    status.Position = UDim2.new(0.5, 0, 0, 226)
    status.Size = UDim2.new(1, 0, 0, 16)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Code
    status.TextSize = 12
    status.Text = "> inicializando kernel..."
    status.TextColor3 = CORES.primaria
    status.TextTransparency = 1
    status.ZIndex = 21
    status.Parent = center

    local rodape = Instance.new("TextLabel")
    rodape.AnchorPoint = Vector2.new(0.5, 1)
    rodape.Position = UDim2.new(0.5, 0, 1, -20)
    rodape.Size = UDim2.new(1, 0, 0, 14)
    rodape.BackgroundTransparency = 1
    rodape.Font = Enum.Font.Code
    rodape.TextSize = 11
    rodape.Text = "SamMods  ·  v6  ·  Auto Defender"
    rodape.TextColor3 = Color3.fromRGB(110, 115, 135)
    rodape.TextTransparency = 1
    rodape.ZIndex = 21
    rodape.Parent = bg

    -- Partículas ciano/roxo
    task.spawn(function()
        local rng = Random.new()
        while intro.Parent do
            task.wait(rng:NextNumber(0.08, 0.2))
            pcall(function()
                local p = Instance.new("Frame")
                local size = rng:NextInteger(2, 6)
                p.Size = UDim2.fromOffset(size, size)
                p.Position = UDim2.new(rng:NextNumber(), 0, 1.05, 0)
                p.BackgroundColor3 = rng:NextNumber() > 0.5 and CORES.primaria or CORES.secundaria
                p.BackgroundTransparency = 0.4
                p.BorderSizePixel = 0
                p.ZIndex = 15
                p.Parent = bg
                Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
                local tw = TweenService:Create(p,
                    TweenInfo.new(rng:NextNumber(3, 6), Enum.EasingStyle.Linear),
                    {
                        Position = UDim2.new(p.Position.X.Scale + rng:NextNumber(-0.06, 0.06), 0, -0.05, 0),
                        BackgroundTransparency = 1,
                    })
                tw:Play()
                tw.Completed:Connect(function() p:Destroy() end)
            end)
        end
    end)

    -- Fade in do holograma
    local FI = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(glow, FI, { BackgroundTransparency = 0.8 }):Play()
    TweenService:Create(titulo, FI, { TextTransparency = 0 }):Play()
    TweenService:Create(sombra, FI, { TextTransparency = 0.75 }):Play()
    TweenService:Create(sub, FI, { TextTransparency = 0 }):Play()
    TweenService:Create(badge, FI, { BackgroundTransparency = 0.2, TextTransparency = 0 }):Play()
    TweenService:Create(status, FI, { TextTransparency = 0 }):Play()
    TweenService:Create(rodape, FI, { TextTransparency = 0 }):Play()
    TweenService:Create(barBg, FI, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(barFill, FI, { TextTransparency = 0, BackgroundTransparency = 0 }):Play()

    -- Scanline animada pelo título
    task.spawn(function()
        while intro.Parent and bg.Parent do
            scanline.Position = UDim2.new(0.5, 0, 0, 20)
            TweenService:Create(scanline, TweenInfo.new(0.8), { Position = UDim2.new(0.5, 0, 0, 80) }):Play()
            task.wait(0.9)
        end
    end)

    -- Progresso com mensagens
    task.spawn(function()
        local steps = {
            { 0.15, "> inicializando kernel..." },
            { 0.35, "> carregando módulos SamMods..." },
            { 0.55, "> conectando ao servidor..." },
            { 0.75, "> montando interface..." },
            { 0.92, "> preparando defesa automática..." },
            { 1.00, "> pronto, chefe!" },
        }
        for _, step in ipairs(steps) do
            if not intro.Parent then return end
            TweenService:Create(barFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.new(step[1], 0, 1, 0) }):Play()
            TweenService:Create(status, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
            task.wait(0.2)
            status.Text = step[2]
            TweenService:Create(status, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
            task.wait(0.25)
        end
    end)

    task.wait(3.0)

    -- Fade out geral
    matrixConn:Disconnect()
    local FO = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(bg, FO, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(titulo, FO, { TextTransparency = 1 }):Play()
    TweenService:Create(sombra, FO, { TextTransparency = 1 }):Play()
    TweenService:Create(sub, FO, { TextTransparency = 1 }):Play()
    TweenService:Create(badge, FO, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
    TweenService:Create(status, FO, { TextTransparency = 1 }):Play()
    TweenService:Create(rodape, FO, { TextTransparency = 1 }):Play()
    TweenService:Create(barBg, FO, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(barFill, FO, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(glow, FO, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(scanline, FO, { BackgroundTransparency = 1 }):Play()

    for _, drop in ipairs(drops) do
        for _, c in ipairs(drop.chars) do
            TweenService:Create(c, FO, { TextTransparency = 1 }):Play()
        end
    end

    task.wait(0.8)
    if intro then intro:Destroy() end
end

task.spawn(playIntro)

-- =========================================================
--  HOOK HACKEVENT
-- =========================================================
HackEvent.OnClientEvent:Connect(function(data)
    if typeof(data) ~= "table" then return end
    local kind = tostring(data.kind or ""):lower()
    local action = tostring(data.action or ""):lower()
    local eventType = tostring(data.type or ""):lower()
    local role = tostring(data.role or ""):lower()
    if END_KINDS[kind] or END_KINDS[action] or END_KINDS[eventType] then
        robberyActive = false
        stopDefense(true)
        updateUI()
        return
    end
    if kind ~= "phase" then return end
    if role == "victim" then
        local thief = resolveThief(data)
        if not thief then return end
        if not robberyActive then batAttemptedThisRobbery = false end
        robberyActive = true
        currentThief = thief
        updateUI()
        if enabled then startDefenseLoop() end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player == currentThief then
        robberyActive = false
        stopDefense(true)
        updateUI()
    end
    if updatePlayerList then updatePlayerList() end
    if spectating == player then stopSpectate() end
end)

Players.PlayerAdded:Connect(function()
    if updatePlayerList then updatePlayerList() end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if enabled and robberyActive and currentThief then startDefenseLoop() end
end)

-- =========================================================
--  HELPERS UI
-- =========================================================
local function corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = inst
    return c
end
local function stroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or CORES.primaria
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end
local function gradient(inst, c1, c2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rotation or 100
    g.Parent = inst
    return g
end
local function tween(inst, props, time, style, dir)
    local t = TweenService:Create(inst,
        TweenInfo.new(time or 0.22, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props)
    t:Play()
    return t
end
local function makeDraggable(handle, target, stateKey)
    local dragging = false
    local dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            if stateKey then STATE[stateKey] = target.Position end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- =========================================================
--  GUI
-- =========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SamModsAutoDefender"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 60
gui.Parent = PlayerGui

-- =========================================================
--  PAINEL PRINCIPAL
-- =========================================================
local PANEL_W = 240
local COLLAPSED_H = 42
local EXPANDED_H = 180

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = STATE.panelPos or UDim2.new(1, -12, 0, 96)
panel.Size = UDim2.fromOffset(PANEL_W, COLLAPSED_H)
panel.BackgroundColor3 = CORES.fundo
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Parent = gui
corner(panel, 14)
stroke(panel, CORES.primaria, 1, 0.6)

local panelGrad = Instance.new("UIGradient")
panelGrad.Color = ColorSequence.new(CORES.fundo2, CORES.fundo)
panelGrad.Rotation = 100
panelGrad.Parent = panel

panel.BackgroundTransparency = 1
panel.Size = UDim2.fromOffset(PANEL_W, 0)
task.defer(function()
    tween(panel, { Size = UDim2.fromOffset(PANEL_W, COLLAPSED_H), BackgroundTransparency = 0 }, 0.45, Enum.EasingStyle.Back)
end)

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(1, 0, 0, 2)
accentBar.BorderSizePixel = 0
accentBar.BackgroundColor3 = CORES.primaria
accentBar.Parent = panel
corner(accentBar, 14)
gradient(accentBar, CORES.primaria, CORES.secundaria, 0)

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, COLLAPSED_H)
header.Position = UDim2.new(0, 0, 0, 2)
header.BackgroundTransparency = 1
header.Parent = panel

local shieldIcon = Instance.new("Frame")
shieldIcon.Position = UDim2.fromOffset(10, 10)
shieldIcon.Size = UDim2.fromOffset(22, 22)
shieldIcon.BackgroundColor3 = CORES.primaria
shieldIcon.BorderSizePixel = 0
shieldIcon.Parent = header
corner(shieldIcon, 7)
gradient(shieldIcon, CORES.primaria, CORES.secundaria, 45)

local shieldGlyph = Instance.new("TextLabel")
shieldGlyph.BackgroundTransparency = 1
shieldGlyph.Size = UDim2.fromScale(1, 1)
shieldGlyph.Font = Enum.Font.GothamBlack
shieldGlyph.TextSize = 12
shieldGlyph.Text = "🛡"
shieldGlyph.TextColor3 = Color3.new(1, 1, 1)
shieldGlyph.Parent = shieldIcon

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(38, 7)
title.Size = UDim2.new(1, -110, 0, 14)
title.Font = Enum.Font.GothamBlack
title.TextSize = 11
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = CORES.texto
title.Text = "SAMMODS"
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(38, 21)
subtitle.Size = UDim2.new(1, -110, 0, 12)
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextColor3 = CORES.subtexto
subtitle.Text = "Auto Defender v6"
subtitle.Parent = header

local statusDot = Instance.new("Frame")
statusDot.AnchorPoint = Vector2.new(0, 0.5)
statusDot.Position = UDim2.new(1, -86, 0.5, 0)
statusDot.Size = UDim2.fromOffset(8, 8)
statusDot.BackgroundColor3 = CORES.off
statusDot.BorderSizePixel = 0
statusDot.Parent = header
corner(statusDot, 4)

local statusDotGlow = Instance.new("UIStroke")
statusDotGlow.Thickness = 2.5
statusDotGlow.Transparency = 0.7
statusDotGlow.Color = CORES.off
statusDotGlow.Parent = statusDot

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "Minimize"
minimizeBtn.AnchorPoint = Vector2.new(1, 0.5)
minimizeBtn.Position = UDim2.new(1, -8, 0.5, 0)
minimizeBtn.Size = UDim2.fromOffset(22, 22)
minimizeBtn.BackgroundColor3 = CORES.fundo2
minimizeBtn.BackgroundTransparency = 0.5
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "➖"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 12
minimizeBtn.TextColor3 = CORES.subtexto
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = header
corner(minimizeBtn, 6)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "Toggle"
toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
toggleBtn.Position = UDim2.new(1, -36, 0.5, 0)
toggleBtn.Size = UDim2.fromOffset(38, 20)
toggleBtn.BackgroundColor3 = CORES.off
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = ""
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = header
corner(toggleBtn, 10)

local toggleKnob = Instance.new("Frame")
toggleKnob.Size = UDim2.fromOffset(14, 14)
toggleKnob.Position = UDim2.new(0, 3, 0.5, -7)
toggleKnob.BackgroundColor3 = Color3.new(1, 1, 1)
toggleKnob.BorderSizePixel = 0
toggleKnob.Parent = toggleBtn
corner(toggleKnob, 7)

local body = Instance.new("Frame")
body.Name = "Body"
body.Position = UDim2.fromOffset(0, COLLAPSED_H)
body.Size = UDim2.new(1, 0, 0, EXPANDED_H - COLLAPSED_H)
body.BackgroundTransparency = 1
body.ClipsDescendants = true
body.Parent = panel

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 0)
divider.BackgroundColor3 = CORES.primaria
divider.BackgroundTransparency = 0.85
divider.BorderSizePixel = 0
divider.Parent = body

local infoCard = Instance.new("Frame")
infoCard.Position = UDim2.fromOffset(10, 8)
infoCard.Size = UDim2.new(1, -20, 0, 42)
infoCard.BackgroundColor3 = CORES.fundo2
infoCard.BackgroundTransparency = 0.3
infoCard.BorderSizePixel = 0
infoCard.Parent = body
corner(infoCard, 8)

local infoStatusLabel = Instance.new("TextLabel")
infoStatusLabel.BackgroundTransparency = 1
infoStatusLabel.Position = UDim2.fromOffset(12, 4)
infoStatusLabel.Size = UDim2.new(1, -20, 0, 16)
infoStatusLabel.Font = Enum.Font.GothamBold
infoStatusLabel.TextSize = 10
infoStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
infoStatusLabel.TextColor3 = CORES.subtexto
infoStatusLabel.Text = "⭕ DESATIVADO"
infoStatusLabel.Parent = infoCard

local infoTargetLabel = Instance.new("TextLabel")
infoTargetLabel.BackgroundTransparency = 1
infoTargetLabel.Position = UDim2.fromOffset(12, 22)
infoTargetLabel.Size = UDim2.new(1, -20, 0, 16)
infoTargetLabel.Font = Enum.Font.GothamMedium
infoTargetLabel.TextSize = 9
infoTargetLabel.TextXAlignment = Enum.TextXAlignment.Left
infoTargetLabel.TextTruncate = Enum.TextTruncate.AtEnd
infoTargetLabel.TextColor3 = CORES.subtexto
infoTargetLabel.Text = "🎯 ALVO: nenhum"
infoTargetLabel.Parent = infoCard

local stopBtn = Instance.new("TextButton")
stopBtn.Name = "StopBtn"
stopBtn.Position = UDim2.fromOffset(10, 58)
stopBtn.Size = UDim2.new(1, -20, 0, 26)
stopBtn.BackgroundColor3 = CORES.danger
stopBtn.BackgroundTransparency = 0.85
stopBtn.BorderSizePixel = 0
stopBtn.Text = "⛔ PARAR DEFESA"
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 10
stopBtn.TextColor3 = CORES.danger
stopBtn.AutoButtonColor = false
stopBtn.Parent = body
corner(stopBtn, 8)
stroke(stopBtn, CORES.danger, 1, 0.6)

local openListBtn = Instance.new("TextButton")
openListBtn.Name = "OpenListBtn"
openListBtn.Position = UDim2.fromOffset(10, 92)
openListBtn.Size = UDim2.new(1, -20, 0, 26)
openListBtn.BackgroundColor3 = CORES.secundaria
openListBtn.BackgroundTransparency = 0.85
openListBtn.BorderSizePixel = 0
openListBtn.Text = "👥 ABRIR LISTA DE JOGADORES"
openListBtn.Font = Enum.Font.GothamBold
openListBtn.TextSize = 10
openListBtn.TextColor3 = CORES.secundaria
openListBtn.AutoButtonColor = false
openListBtn.Parent = body
corner(openListBtn, 8)
stroke(openListBtn, CORES.secundaria, 1, 0.6)

makeDraggable(header, panel, "panelPos")

-- =========================================================
--  LISTA DE JOGADORES (JANELA SEPARADA)
-- =========================================================
local LIST_W = 300
local LIST_H = 420

local playersList = Instance.new("Frame")
playersList.Name = "PlayersList"
playersList.AnchorPoint = Vector2.new(1, 0)
playersList.Position = STATE.listPos or UDim2.new(1, -12, 0, 96 + EXPANDED_H + 10)
playersList.Size = UDim2.fromOffset(LIST_W, LIST_H)
playersList.BackgroundColor3 = CORES.fundo
playersList.BorderSizePixel = 0
playersList.ClipsDescendants = true
playersList.Visible = false
playersList.Parent = gui
corner(playersList, 14)
stroke(playersList, CORES.secundaria, 1, 0.55)

local listGrad = Instance.new("UIGradient")
listGrad.Color = ColorSequence.new(CORES.fundo2, CORES.fundo)
listGrad.Rotation = 100
listGrad.Parent = playersList

local listAccent = Instance.new("Frame")
listAccent.Size = UDim2.new(1, 0, 0, 2)
listAccent.BorderSizePixel = 0
listAccent.BackgroundColor3 = CORES.secundaria
listAccent.Parent = playersList
corner(listAccent, 14)
gradient(listAccent, CORES.secundaria, CORES.destaque, 0)

local listHeader = Instance.new("Frame")
listHeader.Name = "Header"
listHeader.Size = UDim2.new(1, 0, 0, 40)
listHeader.Position = UDim2.new(0, 0, 0, 2)
listHeader.BackgroundTransparency = 1
listHeader.Parent = playersList

local listTitle = Instance.new("TextLabel")
listTitle.BackgroundTransparency = 1
listTitle.Position = UDim2.fromOffset(14, 0)
listTitle.Size = UDim2.new(1, -60, 1, 0)
listTitle.Font = Enum.Font.GothamBlack
listTitle.TextSize = 12
listTitle.TextXAlignment = Enum.TextXAlignment.Left
listTitle.TextColor3 = CORES.texto
listTitle.Text = "👥 JOGADORES"
listTitle.Parent = listHeader

local listCloseBtn = Instance.new("TextButton")
listCloseBtn.Name = "CloseBtn"
listCloseBtn.AnchorPoint = Vector2.new(1, 0.5)
listCloseBtn.Position = UDim2.new(1, -8, 0.5, 0)
listCloseBtn.Size = UDim2.fromOffset(24, 24)
listCloseBtn.BackgroundColor3 = CORES.fundo3
listCloseBtn.BackgroundTransparency = 0.4
listCloseBtn.BorderSizePixel = 0
listCloseBtn.Text = "✕"
listCloseBtn.Font = Enum.Font.GothamBold
listCloseBtn.TextSize = 12
listCloseBtn.TextColor3 = CORES.subtexto
listCloseBtn.AutoButtonColor = false
listCloseBtn.Parent = listHeader
corner(listCloseBtn, 6)

local listDivider = Instance.new("Frame")
listDivider.Size = UDim2.new(1, -20, 0, 1)
listDivider.Position = UDim2.new(0, 10, 0, 42)
listDivider.BackgroundColor3 = CORES.secundaria
listDivider.BackgroundTransparency = 0.8
listDivider.BorderSizePixel = 0
listDivider.Parent = playersList

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Position = UDim2.fromOffset(12, 50)
searchBox.Size = UDim2.new(1, -24, 0, 30)
searchBox.BackgroundColor3 = CORES.fundo2
searchBox.BackgroundTransparency = 0.2
searchBox.BorderSizePixel = 0
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 procurar jogador..."
searchBox.PlaceholderColor3 = CORES.subtexto
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 11
searchBox.TextColor3 = CORES.texto
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Parent = playersList
corner(searchBox, 8)
stroke(searchBox, CORES.secundaria, 1, 0.75)

local sPad = Instance.new("UIPadding")
sPad.PaddingLeft = UDim.new(0, 12)
sPad.PaddingRight = UDim.new(0, 12)
sPad.Parent = searchBox

local listScroll = Instance.new("ScrollingFrame")
listScroll.Position = UDim2.fromOffset(12, 88)
listScroll.Size = UDim2.new(1, -24, 1, -100)
listScroll.BackgroundColor3 = CORES.fundo2
listScroll.BackgroundTransparency = 0.5
listScroll.BorderSizePixel = 0
listScroll.ScrollBarThickness = 4
listScroll.ScrollBarImageColor3 = CORES.primaria
listScroll.ScrollBarImageTransparency = 0.3
listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
listScroll.Parent = playersList
corner(listScroll, 8)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listScroll

local listPad = Instance.new("UIPadding")
listPad.PaddingLeft = UDim.new(0, 6)
listPad.PaddingRight = UDim.new(0, 6)
listPad.PaddingTop = UDim.new(0, 6)
listPad.PaddingBottom = UDim.new(0, 6)
listPad.Parent = listScroll

makeDraggable(listHeader, playersList, "listPos")

-- =========================================================
--  TP E CÂMERA
-- =========================================================
local function teleportToPlayer(target)
    if not target or target == LocalPlayer then return false end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local theirChar = target.Character
    local theirRoot = theirChar and theirChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not theirRoot then return false end
    pcall(function() myRoot.CFrame = theirRoot.CFrame * CFrame.new(0, 0, 3) end)
    return true
end

function stopSpectate()
    if spectateConn then spectateConn:Disconnect() spectateConn = nil end
    spectating = nil
    local myChar = LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHum then workspace.CurrentCamera.CameraSubject = myHum end
    if updatePlayerList then updatePlayerList() end
end

local function startSpectate(target)
    if not target or target == LocalPlayer then return end
    stopSpectate()
    spectating = target
    spectateConn = RunService.RenderStepped:Connect(function()
        local t = spectating
        if not t or not t.Parent then stopSpectate() return end
        local char = t.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then workspace.CurrentCamera.CameraSubject = hum end
    end)
    updatePlayerList()
end

-- =========================================================
--  UPDATE LISTA
-- =========================================================
local searchTerm = ""

function updatePlayerList()
    if not listScroll then return end
    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
    end

    local others = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local dn = p.DisplayName:lower()
            local un = p.Name:lower()
            if searchTerm == "" or dn:find(searchTerm) or un:find(searchTerm) then
                table.insert(others, p)
            end
        end
    end
    table.sort(others, function(a, b) return a.DisplayName:lower() < b.DisplayName:lower() end)

    listTitle.Text = "👥 JOGADORES (" .. #others .. ")"

    if #others == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 40)
        empty.BackgroundTransparency = 1
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 11
        empty.TextColor3 = CORES.subtexto
        empty.Text = "Nenhum jogador"
        empty.LayoutOrder = 1
        empty.Parent = listScroll
        return
    end

    for i, plr in ipairs(others) do
        local isSpectating = (spectating == plr)

        local row = Instance.new("Frame")
        row.Name = "Player_" .. plr.Name
        row.Size = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3 = isSpectating and CORES.secundaria or CORES.fundo
        row.BackgroundTransparency = isSpectating and 0.75 or 0.3
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = listScroll
        corner(row, 8)

        local avatar = Instance.new("ImageLabel")
        avatar.Position = UDim2.fromOffset(6, 6)
        avatar.Size = UDim2.fromOffset(42, 42)
        avatar.BackgroundColor3 = CORES.fundo3
        avatar.BorderSizePixel = 0
        avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=60&h=60"
        avatar.Parent = row
        corner(avatar, 10)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.Position = UDim2.fromOffset(54, 8)
        nameLabel.Size = UDim2.new(1, -100, 0, 16)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.TextColor3 = CORES.texto
        nameLabel.Text = plr.DisplayName
        nameLabel.Parent = row

        local userLabel = Instance.new("TextLabel")
        userLabel.BackgroundTransparency = 1
        userLabel.Position = UDim2.fromOffset(54, 26)
        userLabel.Size = UDim2.new(1, -100, 0, 14)
        userLabel.Font = Enum.Font.Gotham
        userLabel.TextSize = 9
        userLabel.TextXAlignment = Enum.TextXAlignment.Left
        userLabel.TextTruncate = Enum.TextTruncate.AtEnd
        userLabel.TextColor3 = CORES.subtexto
        userLabel.Text = "@" .. plr.Name
        userLabel.Parent = row

        local tpBtn = Instance.new("TextButton")
        tpBtn.Name = "TPButton"
        tpBtn.AnchorPoint = Vector2.new(1, 0.5)
        tpBtn.Position = UDim2.new(1, -6, 0.5, -12)
        tpBtn.Size = UDim2.fromOffset(44, 20)
        tpBtn.BackgroundColor3 = CORES.primaria
        tpBtn.BackgroundTransparency = 0.82
        tpBtn.BorderSizePixel = 0
        tpBtn.Text = "🎯 TP"
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.TextSize = 9
        tpBtn.TextColor3 = CORES.primaria
        tpBtn.AutoButtonColor = false
        tpBtn.Parent = row
        corner(tpBtn, 5)
        stroke(tpBtn, CORES.primaria, 1, 0.55)

        local verBtn = Instance.new("TextButton")
        verBtn.Name = "VerButton"
        verBtn.AnchorPoint = Vector2.new(1, 0.5)
        verBtn.Position = UDim2.new(1, -6, 0.5, 12)
        verBtn.Size = UDim2.fromOffset(44, 20)
        verBtn.BackgroundColor3 = isSpectating and CORES.on or CORES.secundaria
        verBtn.BackgroundTransparency = isSpectating and 0.55 or 0.82
        verBtn.BorderSizePixel = 0
        verBtn.Text = isSpectating and "⏹ ver" or "👁 ver"
        verBtn.Font = Enum.Font.GothamBold
        verBtn.TextSize = 9
        verBtn.TextColor3 = isSpectating and CORES.on or CORES.secundaria
        verBtn.AutoButtonColor = false
        verBtn.Parent = row
        corner(verBtn, 5)
        stroke(verBtn, isSpectating and CORES.on or CORES.secundaria, 1, 0.55)

        tpBtn.MouseEnter:Connect(function() tween(tpBtn, { BackgroundTransparency = 0.5 }, 0.15) end)
        tpBtn.MouseLeave:Connect(function() tween(tpBtn, { BackgroundTransparency = 0.82 }, 0.15) end)
        tpBtn.MouseButton1Click:Connect(function()
            if teleportToPlayer(plr) then
                tween(tpBtn, { BackgroundColor3 = CORES.on, TextColor3 = CORES.on, BackgroundTransparency = 0.4 }, 0.1)
                task.delay(0.4, function()
                    tween(tpBtn, { BackgroundColor3 = CORES.primaria, TextColor3 = CORES.primaria, BackgroundTransparency = 0.82 }, 0.25)
                end)
            end
        end)

        verBtn.MouseEnter:Connect(function() tween(verBtn, { BackgroundTransparency = 0.5 }, 0.15) end)
        verBtn.MouseLeave:Connect(function()
            tween(verBtn, { BackgroundTransparency = isSpectating and 0.55 or 0.82 }, 0.15)
        end)
        verBtn.MouseButton1Click:Connect(function()
            if spectating == plr then stopSpectate() else startSpectate(plr) end
        end)
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchTerm = searchBox.Text:lower()
    updatePlayerList()
end)

-- =========================================================
--  ESTADO
-- =========================================================
local pulseThread = nil

local function stopPulse()
    if pulseThread then task.cancel(pulseThread) pulseThread = nil end
end

local function startPulse()
    stopPulse()
    pulseThread = task.spawn(function()
        while enabled do
            tween(statusDotGlow, { Transparency = 0.2, Thickness = 4 }, 0.7)
            task.wait(0.7)
            tween(statusDotGlow, { Transparency = 0.75, Thickness = 2.5 }, 0.7)
            task.wait(0.7)
        end
    end)
end

function updateUI()
    if enabled then
        tween(toggleBtn, { BackgroundColor3 = CORES.on }, 0.2)
        tween(toggleKnob, { Position = UDim2.new(1, -17, 0.5, -7) }, 0.2, Enum.EasingStyle.Back)
        if robberyActive and batAttemptedThisRobbery then
            infoStatusLabel.Text = "⚔ GOLPE FEITO"
            tween(infoStatusLabel, { TextColor3 = CORES.idle }, 0.2)
            statusDot.BackgroundColor3 = CORES.idle
            statusDotGlow.Color = CORES.idle
            startPulse()
        elseif robberyActive then
            infoStatusLabel.Text = "⚔ DEFENDENDO"
            tween(infoStatusLabel, { TextColor3 = CORES.idle }, 0.2)
            statusDot.BackgroundColor3 = CORES.idle
            statusDotGlow.Color = CORES.idle
            startPulse()
        else
            infoStatusLabel.Text = "✅ ATIVADO"
            tween(infoStatusLabel, { TextColor3 = CORES.on }, 0.2)
            statusDot.BackgroundColor3 = CORES.on
            statusDotGlow.Color = CORES.on
            startPulse()
        end
    else
        tween(toggleBtn, { BackgroundColor3 = CORES.off }, 0.2)
        tween(toggleKnob, { Position = UDim2.new(0, 3, 0.5, -7) }, 0.2, Enum.EasingStyle.Back)
        infoStatusLabel.Text = "⭕ DESATIVADO"
        tween(infoStatusLabel, { TextColor3 = CORES.subtexto }, 0.2)
        statusDot.BackgroundColor3 = CORES.off
        statusDotGlow.Color = CORES.off
        stopPulse()
        statusDotGlow.Transparency = 0.7
        statusDotGlow.Thickness = 2.5
    end
    if robberyActive and currentThief then
        infoTargetLabel.Text = "🎯 ALVO: " .. currentThief.Name
        tween(infoTargetLabel, { TextColor3 = CORES.texto }, 0.2)
    else
        infoTargetLabel.Text = "🎯 ALVO: nenhum"
        tween(infoTargetLabel, { TextColor3 = CORES.subtexto }, 0.2)
    end
end

local function setEnabled(value)
    enabled = value
    STATE.enabled = value
    if not enabled then
        stopDefense()
    elseif robberyActive and currentThief then
        startDefenseLoop()
    end
    updateUI()
end

-- =========================================================
--  BOTÕES
-- =========================================================
toggleBtn.MouseButton1Click:Connect(function() setEnabled(not enabled) end)

local minimized = false
local function setMinimized(state)
    minimized = state
    local targetH = state and COLLAPSED_H or EXPANDED_H
    tween(panel, { Size = UDim2.fromOffset(PANEL_W, targetH) }, 0.35, Enum.EasingStyle.Quint)
    minimizeBtn.Text = state and "➕" or "➖"
end

minimizeBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)
minimizeBtn.MouseEnter:Connect(function() tween(minimizeBtn, { BackgroundTransparency = 0.2, TextColor3 = CORES.primaria }, 0.15) end)
minimizeBtn.MouseLeave:Connect(function() tween(minimizeBtn, { BackgroundTransparency = 0.5, TextColor3 = CORES.subtexto }, 0.15) end)

stopBtn.MouseButton1Click:Connect(function()
    tween(stopBtn, { BackgroundTransparency = 0.4 }, 0.08)
    task.delay(0.15, function() tween(stopBtn, { BackgroundTransparency = 0.85 }, 0.2) end)
    enabled = false
    STATE.enabled = false
    releaseFromThief()
    unequipBat()
    updateUI()
end)
stopBtn.MouseEnter:Connect(function() tween(stopBtn, { BackgroundTransparency = 0.65 }, 0.15) end)
stopBtn.MouseLeave:Connect(function() tween(stopBtn, { BackgroundTransparency = 0.85 }, 0.15) end)

-- Abrir lista
openListBtn.MouseButton1Click:Connect(function()
    if playersList.Visible then
        tween(playersList, { Size = UDim2.fromOffset(0, LIST_H) }, 0.25, Enum.EasingStyle.Quint)
        task.delay(0.28, function() playersList.Visible = false end)
        openListBtn.Text = "👥 ABRIR LISTA DE JOGADORES"
        if spectating then stopSpectate() end
    else
        playersList.Visible = true
        playersList.Size = UDim2.fromOffset(0, LIST_H)
        tween(playersList, { Size = UDim2.fromOffset(LIST_W, LIST_H) }, 0.35, Enum.EasingStyle.Back)
        openListBtn.Text = "👥 FECHAR LISTA DE JOGADORES"
        updatePlayerList()
    end
end)
openListBtn.MouseEnter:Connect(function() tween(openListBtn, { BackgroundTransparency = 0.55 }, 0.15) end)
openListBtn.MouseLeave:Connect(function() tween(openListBtn, { BackgroundTransparency = 0.85 }, 0.15) end)

listCloseBtn.MouseEnter:Connect(function() tween(listCloseBtn, { BackgroundColor3 = CORES.danger, TextColor3 = CORES.danger, BackgroundTransparency = 0.6 }, 0.15) end)
listCloseBtn.MouseLeave:Connect(function() tween(listCloseBtn, { BackgroundColor3 = CORES.fundo3, TextColor3 = CORES.subtexto, BackgroundTransparency = 0.4 }, 0.15) end)
listCloseBtn.MouseButton1Click:Connect(function()
    tween(playersList, { Size = UDim2.fromOffset(0, LIST_H) }, 0.25, Enum.EasingStyle.Quint)
    task.delay(0.28, function() playersList.Visible = false end)
    openListBtn.Text = "👥 ABRIR LISTA DE JOGADORES"
    if spectating then stopSpectate() end
end)

-- =========================================================
--  TOPBAR — esconde/mostra tudo
-- =========================================================
local guiVisible = true

local defenderIcon = TopbarPlus.new()
defenderIcon:setName("SamModsAutoDefender")
defenderIcon:setLeft()
defenderIcon:setOrder(4)
defenderIcon:setCaption("SamMods Hub")

STATE.icon = defenderIcon

local defenderIconButton = defenderIcon:getInstance("IconButton")
if defenderIconButton then
    local lbl = Instance.new("TextLabel")
    lbl.Name = "SamModsIconLabel"
    lbl.BackgroundTransparency = 1
    lbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lbl.Position = UDim2.fromScale(0.5, 0.5)
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 18
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Text = "🛡"
    lbl.ZIndex = 20
    lbl.Parent = defenderIconButton
end

defenderIcon:bindEvent("clicked", function()
    guiVisible = not guiVisible
    gui.Enabled = guiVisible
end)

-- =========================================================
--  HOTKEYS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == CONFIG.ToggleKey then
        setEnabled(not enabled)
    elseif input.KeyCode == CONFIG.ListToggleKey then
        if playersList.Visible then
            tween(playersList, { Size = UDim2.fromOffset(0, LIST_H) }, 0.25, Enum.EasingStyle.Quint)
            task.delay(0.28, function() playersList.Visible = false end)
            openListBtn.Text = "👥 ABRIR LISTA DE JOGADORES"
        else
            playersList.Visible = true
            playersList.Size = UDim2.fromOffset(0, LIST_H)
            tween(playersList, { Size = UDim2.fromOffset(LIST_W, LIST_H) }, 0.35, Enum.EasingStyle.Back)
            openListBtn.Text = "👥 FECHAR LISTA DE JOGADORES"
            updatePlayerList()
        end
    end
end)

-- =========================================================
--  LOOP
-- =========================================================
task.spawn(function()
    while gui.Parent do
        if currentThief and currentThief.Parent ~= Players then
            robberyActive = false
            stopDefense()
        end
        updateUI()
        task.wait(0.15)
    end
end)

updateUI()
updatePlayerList()

-- =========================================================
--  CLEANUP
-- =========================================================
script.Destroying:Connect(function()
    enabled = false
    robberyActive = false
    releaseFromThief()
    unequipBat()
    stopPulse()
    stopSpectate()
    if gui then gui:Destroy() end
    if STATE.icon then pcall(function() STATE.icon:destroy() end) STATE.icon = nil end
end)
