-- SamMods Auto Defender · v8.7
-- Lista independente (não fecha o painel) + defesa com a lógica original que funcionava

print("[SamMods] Carregando v8.7...")

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Remotes     = ReplicatedStorage:WaitForChild("Remotes")

local HackEvent = Remotes:WaitForChild("HackEvent")
local MeleeHit  = Remotes:WaitForChild("MeleeHit")

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local TopbarPlus = require(Shared:WaitForChild("TopbarPlus"))

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

_G.SamModsDefender = _G.SamModsDefender or {}
local STATE = _G.SamModsDefender

if STATE.icon then
    pcall(function() STATE.icon:destroy() end)
    STATE.icon = nil
end

local oldGui = PlayerGui:FindFirstChild("SamModsAutoDefender")
if oldGui then
    oldGui:Destroy()
end

local enabled                 = STATE.enabled or false
local robberyActive           = false
local currentThief            = nil
local batAttemptedThisRobbery = false
local followConnection        = nil
local defenseThread           = nil
local spectating              = nil
local spectateConn            = nil
local playersListOpen         = false
local selectedPlayer          = nil
local guiVisible              = true
local minimized               = true
local pulseThread             = nil
local searchTerm              = ""
local openingPanelTween       = nil
local introAlive              = true

-- =========================================================
-- HELPERS PERSONAGEM
-- =========================================================
local function getCharacter()
    return LocalPlayer.Character
end

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
        if tool and tool:IsA("Tool") then
            return tool
        end
    end

    if backpack then
        local tool = backpack:FindFirstChild(CONFIG.ToolName)
        if tool and tool:IsA("Tool") then
            return tool
        end
    end
end

local function equipBat()
    local humanoid = getHumanoid()
    local bat = getBat()
    if not humanoid or not bat then
        return false
    end

    if bat.Parent ~= getCharacter() then
        pcall(function() humanoid:EquipTool(bat) end)
        task.wait(CONFIG.EquipDelay)
    end

    local equipped = getCharacter() and getCharacter():FindFirstChild(CONFIG.ToolName)
    return equipped ~= nil and equipped:IsA("Tool")
end

local function unequipBat()
    local humanoid = getHumanoid()
    if humanoid then
        pcall(function() humanoid:UnequipTools() end)
    end
end

local function releaseFromThief()
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end
end

local function followThief(thief)
    releaseFromThief()

    local myRoot = getRoot(LocalPlayer)
    local thiefRoot = getRoot(thief)
    if not myRoot or not thiefRoot then
        return false
    end

    pcall(function()
        myRoot.CFrame = thiefRoot.CFrame * CONFIG.FollowOffset
    end)

    followConnection = RunService.Heartbeat:Connect(function()
        if not enabled or not robberyActive or currentThief ~= thief then
            releaseFromThief()
            return
        end

        local mine = getRoot(LocalPlayer)
        local target = getRoot(thief)
        if not mine or not target then
            releaseFromThief()
            return
        end

        pcall(function()
            mine.CFrame = target.CFrame * CONFIG.FollowOffset
        end)
    end)

    return true
end

local function stopDefense(clearAttempt)
    releaseFromThief()
    currentThief = nil
    unequipBat()

    if clearAttempt then
        batAttemptedThisRobbery = false
    end
end

-- =========================================================
-- DEFESA — lógica original que funcionava
-- =========================================================
local function fireMelee(thief)
    if not thief or not MeleeHit:IsA("RemoteEvent") then
        return false
    end

    return pcall(function()
        MeleeHit:FireServer(thief)
    end)
end

local function oneAttempt(thief)
    if not enabled
        or not robberyActive
        or not thief
        or batAttemptedThisRobbery then
        return
    end

    if thief.Parent ~= Players or not getRoot(thief) then
        return
    end

    -- GUARD: só uma tentativa por roubo.
    batAttemptedThisRobbery = true

    if not equipBat() then
        batAttemptedThisRobbery = false
        return
    end

    if not followThief(thief) then
        batAttemptedThisRobbery = false
        unequipBat()
        return
    end

    local started = os.clock()

    while enabled
        and robberyActive
        and currentThief == thief
        and (os.clock() - started) < CONFIG.AttemptDuration do

        if not getRoot(thief) then break end
        fireMelee(thief)
        task.wait(CONFIG.MeleeInterval)
    end

    releaseFromThief()
    unequipBat()

    if updateUI then updateUI() end
end

local function startDefenseLoop()
    if defenseThread
        or not enabled
        or not robberyActive
        or not currentThief
        or batAttemptedThisRobbery then
        return
    end

    defenseThread = task.spawn(function()
        oneAttempt(currentThief)
        defenseThread = nil
        if updateUI then updateUI() end
    end)
end

local function resolveThief(data)
    if typeof(data) ~= "table" then
        return nil
    end

    local ids = {
        tonumber(data.userId),
        tonumber(data.attackerUserId),
        tonumber(data.attackerId),
        tonumber(data.thiefUserId),
        tonumber(data.thiefId),
        tonumber(data.robberUserId),
        tonumber(data.robberId),
    }

    for _, id in ipairs(ids) do
        if id then
            local player = Players:GetPlayerByUserId(id)
            if player and player ~= LocalPlayer then
                return player
            end
        end
    end

    local names = {
        data.attackerName,
        data.thiefName,
        data.robberName,
        data.name,
    }

    for _, name in ipairs(names) do
        if typeof(name) == "string" and name ~= "" then
            local player = Players:FindFirstChild(name)
            if player and player ~= LocalPlayer then
                return player
            end
        end
    end
end

local END_KINDS = {
    result      = true,
    abort       = true,
    ["end"]     = true,
    ended       = true,
    finish      = true,
    finished    = true,
    robbery_end = true,
    steal_end   = true,
}

-- =========================================================
-- UI HELPERS
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
    local t = TweenService:Create(
        inst,
        TweenInfo.new(
            time or 0.22,
            style or Enum.EasingStyle.Quint,
            dir or Enum.EasingDirection.Out
        ),
        props
    )
    t:Play()
    return t
end

local function makeDraggable(handle, target, stateKey)
    local dragging = false
    local dragStart
    local startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging
            and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then

            local delta = input.Position - dragStart

            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )

            if stateKey then
                STATE[stateKey] = target.Position
            end
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
-- INTRO
-- =========================================================
local function createIntro()
    local old = PlayerGui:FindFirstChild("SamModsIntro")
    if old then old:Destroy() end

    local intro = Instance.new("ScreenGui")
    intro.Name = "SamModsIntro"
    intro.ResetOnSpawn = false
    intro.IgnoreGuiInset = true
    intro.DisplayOrder = 9999
    intro.Parent = PlayerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(3, 4, 10)
    bg.BorderSizePixel = 0
    bg.Parent = intro

    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 8, 20)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(13, 5, 24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 10, 18)),
    })
    bgGrad.Rotation = 35
    bgGrad.Parent = bg

    for i = -12, 18 do
        local line = Instance.new("Frame")
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Position = UDim2.new(0.5, i * 95, 0.5, 0)
        line.Size = UDim2.fromOffset(1, 900)
        line.Rotation = 25
        line.BackgroundColor3 = i % 2 == 0 and CORES.primaria or CORES.secundaria
        line.BackgroundTransparency = 0.94
        line.BorderSizePixel = 0
        line.Parent = bg
    end

    local tunnel = Instance.new("Frame")
    tunnel.AnchorPoint = Vector2.new(0.5, 0.5)
    tunnel.Position = UDim2.fromScale(0.5, 0.46)
    tunnel.Size = UDim2.fromOffset(10, 10)
    tunnel.BackgroundTransparency = 1
    tunnel.Parent = bg

    local tunnelItems = {}
    for i = 1, 9 do
        local sq = Instance.new("Frame")
        sq.AnchorPoint = Vector2.new(0.5, 0.5)
        sq.Position = UDim2.fromScale(0.5, 0.5)
        sq.Size = UDim2.fromOffset(45 + i * 48, 45 + i * 48)
        sq.BackgroundTransparency = 1
        sq.BorderSizePixel = 0
        sq.Rotation = (i % 2 == 0) and 45 or 0
        sq.Parent = tunnel

        local st = Instance.new("UIStroke")
        st.Color = i % 2 == 0 and CORES.secundaria or CORES.primaria
        st.Thickness = i <= 3 and 1.5 or 1
        st.Transparency = 0.78
        st.Parent = sq
        table.insert(tunnelItems, sq)
    end

    local core = Instance.new("Frame")
    core.AnchorPoint = Vector2.new(0.5, 0.5)
    core.Position = UDim2.fromScale(0.5, 0.46)
    core.Size = UDim2.fromOffset(86, 86)
    core.BackgroundColor3 = Color3.fromRGB(8, 12, 25)
    core.BackgroundTransparency = 0.15
    core.BorderSizePixel = 0
    core.Parent = bg
    corner(core, 22)

    local coreStroke = Instance.new("UIStroke")
    coreStroke.Color = CORES.primaria
    coreStroke.Thickness = 2
    coreStroke.Transparency = 0.1
    coreStroke.Parent = core

    local coreGrad = Instance.new("UIGradient")
    coreGrad.Color = ColorSequence.new(CORES.primaria, CORES.secundaria)
    coreGrad.Rotation = 45
    coreGrad.Parent = coreStroke

    local shield = Instance.new("TextLabel")
    shield.BackgroundTransparency = 1
    shield.Size = UDim2.fromScale(1, 1)
    shield.Font = Enum.Font.GothamBlack
    shield.Text = "◆"
    shield.TextSize = 38
    shield.TextColor3 = Color3.new(1, 1, 1)
    shield.TextTransparency = 1
    shield.Parent = core

    local scanner = Instance.new("Frame")
    scanner.AnchorPoint = Vector2.new(0.5, 0.5)
    scanner.Position = UDim2.fromScale(0.5, 0.46)
    scanner.Size = UDim2.new(0.85, 0, 0, 1)
    scanner.BackgroundColor3 = CORES.primaria
    scanner.BackgroundTransparency = 0.35
    scanner.BorderSizePixel = 0
    scanner.Parent = bg

    local modules = {}
    local moduleTexts = {"CORE", "LINK", "GUARD", "SYNC"}
    for i, txt in ipairs(moduleTexts) do
        local side = (i % 2 == 0) and 1 or -1
        local card = Instance.new("Frame")
        card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.new(0.5, side * 520, 0.46, (i - 2.5) * 38)
        card.Size = UDim2.fromOffset(150, 27)
        card.BackgroundColor3 = Color3.fromRGB(8, 12, 25)
        card.BackgroundTransparency = 0.18
        card.BorderSizePixel = 0
        card.Parent = bg
        corner(card, 7)

        local cs = Instance.new("UIStroke")
        cs.Color = side == 1 and CORES.secundaria or CORES.primaria
        cs.Thickness = 1
        cs.Transparency = 0.45
        cs.Parent = card

        local cl = Instance.new("TextLabel")
        cl.BackgroundTransparency = 1
        cl.Size = UDim2.new(1, -16, 1, 0)
        cl.Position = UDim2.fromOffset(8, 0)
        cl.Font = Enum.Font.Code
        cl.TextSize = 10
        cl.TextXAlignment = Enum.TextXAlignment.Left
        cl.Text = "// " .. txt .. "_MODULE"
        cl.TextColor3 = side == 1 and CORES.secundaria or CORES.primaria
        cl.TextTransparency = 1
        cl.Parent = card
        table.insert(modules, {card = card, label = cl, side = side})
    end

    local brand = Instance.new("TextLabel")
    brand.AnchorPoint = Vector2.new(0.5, 0)
    brand.Position = UDim2.new(0.5, 0, 0.46, 62)
    brand.Size = UDim2.fromOffset(500, 46)
    brand.BackgroundTransparency = 1
    brand.Font = Enum.Font.GothamBlack
    brand.TextSize = 34
    brand.Text = "SAMMODS"
    brand.TextColor3 = Color3.new(1, 1, 1)
    brand.TextTransparency = 1
    brand.Parent = bg

    local brandGrad = Instance.new("UIGradient")
    brandGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CORES.primaria),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, CORES.secundaria),
    })
    brandGrad.Parent = brand

    local sub = Instance.new("TextLabel")
    sub.AnchorPoint = Vector2.new(0.5, 0)
    sub.Position = UDim2.new(0.5, 0, 0.46, 104)
    sub.Size = UDim2.fromOffset(500, 20)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Code
    sub.TextSize = 11
    sub.Text = "AUTO DEFENDER  //  SYSTEM ONLINE"
    sub.TextColor3 = CORES.subtexto
    sub.TextTransparency = 1
    sub.Parent = bg

    local progressBack = Instance.new("Frame")
    progressBack.AnchorPoint = Vector2.new(0.5, 0)
    progressBack.Position = UDim2.new(0.5, 0, 0.46, 140)
    progressBack.Size = UDim2.fromOffset(300, 3)
    progressBack.BackgroundColor3 = Color3.fromRGB(30, 32, 48)
    progressBack.BackgroundTransparency = 0.2
    progressBack.BorderSizePixel = 0
    progressBack.Parent = bg
    corner(progressBack, 3)

    local progress = Instance.new("Frame")
    progress.Size = UDim2.new(0, 0, 1, 0)
    progress.BackgroundColor3 = CORES.primaria
    progress.BorderSizePixel = 0
    progress.Parent = progressBack
    corner(progress, 3)
    gradient(progress, CORES.primaria, CORES.secundaria, 0)

    local status = Instance.new("TextLabel")
    status.AnchorPoint = Vector2.new(0.5, 0)
    status.Position = UDim2.new(0.5, 0, 0.46, 153)
    status.Size = UDim2.fromOffset(500, 18)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Code
    status.TextSize = 10
    status.Text = "CONNECTING..."
    status.TextColor3 = CORES.primaria
    status.TextTransparency = 1
    status.Parent = bg

    local particleAlive = true
    task.spawn(function()
        local rng = Random.new()
        while particleAlive and intro.Parent do
            local dot = Instance.new("Frame")
            local side = rng:NextInteger(1, 2)
            dot.Size = UDim2.fromOffset(rng:NextInteger(1, 3), rng:NextInteger(1, 3))
            dot.Position = side == 1
                and UDim2.new(-0.02, 0, rng:NextNumber(0.1, 0.9), 0)
                or UDim2.new(1.02, 0, rng:NextNumber(0.1, 0.9), 0)
            dot.BackgroundColor3 = side == 1 and CORES.primaria or CORES.secundaria
            dot.BackgroundTransparency = 0.2
            dot.BorderSizePixel = 0
            dot.Parent = bg
            corner(dot, 2)

            local targetX = side == 1 and 1.02 or -0.02
            local tw = TweenService:Create(dot, TweenInfo.new(rng:NextNumber(1.4, 2.8), Enum.EasingStyle.Linear), {
                Position = UDim2.new(targetX, 0, dot.Position.Y.Scale + rng:NextNumber(-0.08, 0.08), 0),
                BackgroundTransparency = 1,
            })
            tw:Play()
            tw.Completed:Connect(function() if dot then dot:Destroy() end end)
            task.wait(rng:NextNumber(0.06, 0.14))
        end
    end)

    local fadeIn = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(core, fadeIn, {BackgroundTransparency = 0.05}):Play()
    TweenService:Create(shield, fadeIn, {TextTransparency = 0}):Play()
    TweenService:Create(brand, fadeIn, {TextTransparency = 0}):Play()
    TweenService:Create(sub, fadeIn, {TextTransparency = 0}):Play()
    TweenService:Create(status, fadeIn, {TextTransparency = 0}):Play()

    for _, item in ipairs(modules) do
        TweenService:Create(item.card, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, item.side * 230, item.card.Position.Y.Scale, item.card.Position.Y.Offset),
        }):Play()
        TweenService:Create(item.label, fadeIn, {TextTransparency = 0}):Play()
    end

    for i, sq in ipairs(tunnelItems) do
        task.delay(i * 0.045, function()
            if not sq.Parent then return end
            local original = sq.Size
            sq.Size = UDim2.fromOffset(original.X.Offset * 0.25, original.Y.Offset * 0.25)
            sq.Rotation = sq.Rotation + 18
            TweenService:Create(sq, TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = original,
                Rotation = sq.Rotation + 90,
            }):Play()
        end)
    end

    local statuses = {
        {0.12, "CALIBRATING DEFENSE CORE..."},
        {0.30, "LOADING PLAYER GUARD MODULE..."},
        {0.52, "SYNCING HACK EVENT MONITOR..."},
        {0.74, "ARMING AUTO DEFENDER..."},
        {1.00, "SYSTEM READY  //  SAMMODS ONLINE"},
    }

    for _, step in ipairs(statuses) do
        if not intro.Parent then return end
        TweenService:Create(progress, TweenInfo.new(0.32, Enum.EasingStyle.Quart), {
            Size = UDim2.new(step[1], 0, 1, 0),
        }):Play()
        status.Text = step[2]
        task.wait(0.38)
    end

    for _ = 1, 2 do
        TweenService:Create(core, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Size = UDim2.fromOffset(100, 100)}):Play()
        TweenService:Create(coreStroke, TweenInfo.new(0.18), {Transparency = 0}):Play()
        task.wait(0.18)
        TweenService:Create(core, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Size = UDim2.fromOffset(86, 86)}):Play()
        TweenService:Create(coreStroke, TweenInfo.new(0.18), {Transparency = 0.15}):Play()
        task.wait(0.18)
    end

    particleAlive = false
    local fadeOut = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    TweenService:Create(bg, fadeOut, {BackgroundTransparency = 1}):Play()
    TweenService:Create(brand, fadeOut, {TextTransparency = 1}):Play()
    TweenService:Create(sub, fadeOut, {TextTransparency = 1}):Play()
    TweenService:Create(status, fadeOut, {TextTransparency = 1}):Play()
    TweenService:Create(shield, fadeOut, {TextTransparency = 1}):Play()
    TweenService:Create(core, fadeOut, {BackgroundTransparency = 1}):Play()
    TweenService:Create(scanner, fadeOut, {BackgroundTransparency = 1}):Play()

    task.wait(0.6)
    if intro.Parent then intro:Destroy() end
end

task.spawn(createIntro)

-- =========================================================
-- GUI
-- =========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SamModsAutoDefender"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 60
gui.Parent = PlayerGui

-- =========================================================
-- PAINEL PRINCIPAL
-- =========================================================
local PANEL_W = 240
local COLLAPSED_H = 46
local EXPANDED_H = 184

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = STATE.panelPos or UDim2.new(1, -12, 0, 12)
panel.Size = UDim2.fromOffset(PANEL_W, COLLAPSED_H)
panel.BackgroundColor3 = CORES.fundo
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Parent = gui
corner(panel, 14)
stroke(panel, CORES.primaria, 1, 0.6)
gradient(panel, CORES.fundo2, CORES.fundo, 100)
panel.BackgroundTransparency = 1
panel.Size = UDim2.fromOffset(PANEL_W, 0)

openingPanelTween = tween(
    panel,
    {
        Size = UDim2.fromOffset(PANEL_W, COLLAPSED_H),
        BackgroundTransparency = 0,
    },
    0.45,
    Enum.EasingStyle.Back
)

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(1, 0, 0, 2)
accentBar.BorderSizePixel = 0
accentBar.BackgroundColor3 = CORES.primaria
accentBar.ZIndex = 2
accentBar.Parent = panel
corner(accentBar, 14)
gradient(accentBar, CORES.primaria, CORES.secundaria, 0)

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, COLLAPSED_H)
header.Position = UDim2.new(0, 0, 0, 2)
header.BackgroundTransparency = 1
header.ZIndex = 2
header.Parent = panel

local shieldIcon = Instance.new("Frame")
shieldIcon.Position = UDim2.fromOffset(10, 12)
shieldIcon.Size = UDim2.fromOffset(22, 22)
shieldIcon.BackgroundColor3 = CORES.primaria
shieldIcon.BorderSizePixel = 0
shieldIcon.ZIndex = 3
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
shieldGlyph.ZIndex = 4
shieldGlyph.Parent = shieldIcon

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(38, 9)
title.Size = UDim2.new(1, -100, 0, 14)
title.Font = Enum.Font.GothamBlack
title.TextSize = 11
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = CORES.texto
title.Text = "SAMMODS"
title.ZIndex = 3
title.Parent = header

local subtitleLbl = Instance.new("TextLabel")
subtitleLbl.BackgroundTransparency = 1
subtitleLbl.Position = UDim2.fromOffset(38, 23)
subtitleLbl.Size = UDim2.new(1, -100, 0, 12)
subtitleLbl.Font = Enum.Font.GothamMedium
subtitleLbl.TextSize = 9
subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left
subtitleLbl.TextColor3 = CORES.subtexto
subtitleLbl.Text = "Auto Defender"
subtitleLbl.ZIndex = 3
subtitleLbl.Parent = header

local statusDot = Instance.new("Frame")
statusDot.AnchorPoint = Vector2.new(0, 0.5)
statusDot.Position = UDim2.new(1, -74, 0.5, 0)
statusDot.Size = UDim2.fromOffset(8, 8)
statusDot.BackgroundColor3 = CORES.off
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 3
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
minimizeBtn.Position = UDim2.new(1, -6, 0.5, 0)
minimizeBtn.Size = UDim2.fromOffset(30, 30)
minimizeBtn.BackgroundColor3 = CORES.fundo3
minimizeBtn.BackgroundTransparency = 0.3
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "+"
minimizeBtn.Font = Enum.Font.GothamBlack
minimizeBtn.TextSize = 20
minimizeBtn.TextColor3 = CORES.primaria
minimizeBtn.AutoButtonColor = false
minimizeBtn.ZIndex = 5
minimizeBtn.Parent = header
corner(minimizeBtn, 8)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "Toggle"
toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
toggleBtn.Position = UDim2.new(1, -42, 0.5, 0)
toggleBtn.Size = UDim2.fromOffset(52, 26)
toggleBtn.BackgroundColor3 = CORES.off
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = ""
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 4
toggleBtn.Parent = header
corner(toggleBtn, 13)

local toggleKnob = Instance.new("Frame")
toggleKnob.Size = UDim2.fromOffset(20, 20)
toggleKnob.Position = UDim2.new(0, 3, 0.5, -10)
toggleKnob.BackgroundColor3 = Color3.new(1, 1, 1)
toggleKnob.BorderSizePixel = 0
toggleKnob.ZIndex = 5
toggleKnob.Parent = toggleBtn
corner(toggleKnob, 10)

local body = Instance.new("Frame")
body.Name = "Body"
body.Position = UDim2.fromOffset(0, COLLAPSED_H)
body.Size = UDim2.new(1, 0, 0, EXPANDED_H - COLLAPSED_H)
body.BackgroundTransparency = 1
body.ClipsDescendants = true
body.ZIndex = 2
body.Parent = panel

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 0)
divider.BackgroundColor3 = CORES.primaria
divider.BackgroundTransparency = 0.85
divider.BorderSizePixel = 0
divider.ZIndex = 3
divider.Parent = body

local infoCard = Instance.new("Frame")
infoCard.Position = UDim2.fromOffset(10, 8)
infoCard.Size = UDim2.new(1, -20, 0, 42)
infoCard.BackgroundColor3 = CORES.fundo2
infoCard.BackgroundTransparency = 0.3
infoCard.BorderSizePixel = 0
infoCard.ZIndex = 3
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
infoStatusLabel.ZIndex = 4
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
infoTargetLabel.ZIndex = 4
infoTargetLabel.Parent = infoCard

local stopBtn = Instance.new("TextButton")
stopBtn.Name = "StopBtn"
stopBtn.Position = UDim2.fromOffset(10, 58)
stopBtn.Size = UDim2.new(1, -20, 0, 28)
stopBtn.BackgroundColor3 = CORES.danger
stopBtn.BackgroundTransparency = 0.85
stopBtn.BorderSizePixel = 0
stopBtn.Text = "⛔ PARAR DEFESA"
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 10
stopBtn.TextColor3 = CORES.danger
stopBtn.AutoButtonColor = false
stopBtn.ZIndex = 3
stopBtn.Parent = body
corner(stopBtn, 8)
stroke(stopBtn, CORES.danger, 1, 0.6)

local openListBtn = Instance.new("TextButton")
openListBtn.Name = "OpenListBtn"
openListBtn.Position = UDim2.fromOffset(10, 94)
openListBtn.Size = UDim2.new(1, -20, 0, 28)
openListBtn.BackgroundColor3 = CORES.secundaria
openListBtn.BackgroundTransparency = 0.85
openListBtn.BorderSizePixel = 0
openListBtn.Text = "👥 ABRIR LISTA"
openListBtn.Font = Enum.Font.GothamBold
openListBtn.TextSize = 10
openListBtn.TextColor3 = CORES.secundaria
openListBtn.AutoButtonColor = false
openListBtn.ZIndex = 3
openListBtn.Parent = body
corner(openListBtn, 8)
stroke(openListBtn, CORES.secundaria, 1, 0.6)

-- Painel arrastável pelo header
makeDraggable(header, panel, "panelPos")

-- =========================================================
-- LISTA SEPARADA / INDEPENDENTE
-- =========================================================
local LIST_W = 255
local LIST_H = 305
local FOOTER_H = 38

local playersList = Instance.new("Frame")
playersList.Name = "PlayersList"
playersList.AnchorPoint = Vector2.new(1, 0)
playersList.Position = STATE.listPos or UDim2.new(1, -12, 0, 66)
playersList.Size = UDim2.fromOffset(LIST_W, LIST_H)
playersList.BackgroundColor3 = CORES.fundo
playersList.BorderSizePixel = 0
playersList.ClipsDescendants = true
playersList.Visible = false
playersList.ZIndex = 50
playersList.Parent = gui
corner(playersList, 14)
stroke(playersList, CORES.secundaria, 1.5, 0.4)
gradient(playersList, CORES.fundo2, CORES.fundo, 100)

local listAccent = Instance.new("Frame")
listAccent.Size = UDim2.new(1, 0, 0, 2)
listAccent.BorderSizePixel = 0
listAccent.BackgroundColor3 = CORES.secundaria
listAccent.ZIndex = 51
listAccent.Parent = playersList
corner(listAccent, 14)
gradient(listAccent, CORES.secundaria, CORES.destaque, 0)

local listHeader = Instance.new("Frame")
listHeader.Name = "Header"
listHeader.Size = UDim2.new(1, 0, 0, 36)
listHeader.Position = UDim2.new(0, 0, 0, 2)
listHeader.BackgroundTransparency = 1
listHeader.ZIndex = 51
listHeader.Parent = playersList

local listTitle = Instance.new("TextLabel")
listTitle.BackgroundTransparency = 1
listTitle.Position = UDim2.fromOffset(14, 0)
listTitle.Size = UDim2.new(1, -50, 1, 0)
listTitle.Font = Enum.Font.GothamBlack
listTitle.TextSize = 12
listTitle.TextXAlignment = Enum.TextXAlignment.Left
listTitle.TextColor3 = CORES.texto
listTitle.Text = "👥 JOGADORES"
listTitle.ZIndex = 52
listTitle.Parent = listHeader

local listCloseBtn = Instance.new("TextButton")
listCloseBtn.Name = "CloseBtn"
listCloseBtn.AnchorPoint = Vector2.new(1, 0.5)
listCloseBtn.Position = UDim2.new(1, -8, 0.5, 0)
listCloseBtn.Size = UDim2.fromOffset(26, 26)
listCloseBtn.BackgroundColor3 = CORES.fundo3
listCloseBtn.BackgroundTransparency = 0.4
listCloseBtn.BorderSizePixel = 0
listCloseBtn.Text = "X"
listCloseBtn.Font = Enum.Font.GothamBlack
listCloseBtn.TextSize = 13
listCloseBtn.TextColor3 = CORES.subtexto
listCloseBtn.AutoButtonColor = false
listCloseBtn.ZIndex = 52
listCloseBtn.Parent = listHeader
corner(listCloseBtn, 8)

local listDivider = Instance.new("Frame")
listDivider.Size = UDim2.new(1, -20, 0, 1)
listDivider.Position = UDim2.new(0, 10, 0, 38)
listDivider.BackgroundColor3 = CORES.secundaria
listDivider.BackgroundTransparency = 0.8
listDivider.BorderSizePixel = 0
listDivider.ZIndex = 51
listDivider.Parent = playersList

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Position = UDim2.fromOffset(10, 44)
searchBox.Size = UDim2.new(1, -20, 0, 26)
searchBox.BackgroundColor3 = CORES.fundo2
searchBox.BackgroundTransparency = 0.2
searchBox.BorderSizePixel = 0
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 procurar jogador..."
searchBox.PlaceholderColor3 = CORES.subtexto
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 10
searchBox.TextColor3 = CORES.texto
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.ZIndex = 51
searchBox.Parent = playersList
corner(searchBox, 8)
stroke(searchBox, CORES.secundaria, 1, 0.75)

local sPad = Instance.new("UIPadding")
sPad.PaddingLeft = UDim.new(0, 10)
sPad.PaddingRight = UDim.new(0, 10)
sPad.Parent = searchBox

local listScroll = Instance.new("ScrollingFrame")
listScroll.Position = UDim2.fromOffset(10, 74)
listScroll.Size = UDim2.new(1, -20, 1, -(74 + FOOTER_H + 8))
listScroll.BackgroundColor3 = CORES.fundo2
listScroll.BackgroundTransparency = 0.5
listScroll.BorderSizePixel = 0
listScroll.ScrollBarThickness = 3
listScroll.ScrollBarImageColor3 = CORES.primaria
listScroll.ScrollBarImageTransparency = 0.3
listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
listScroll.ZIndex = 51
listScroll.Parent = playersList
corner(listScroll, 8)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listScroll

local listPad = Instance.new("UIPadding")
listPad.PaddingLeft = UDim.new(0, 4)
listPad.PaddingRight = UDim.new(0, 4)
listPad.PaddingTop = UDim.new(0, 4)
listPad.PaddingBottom = UDim.new(0, 4)
listPad.Parent = listScroll

local listFooter = Instance.new("Frame")
listFooter.Name = "Footer"
listFooter.AnchorPoint = Vector2.new(0, 1)
listFooter.Position = UDim2.new(0, 0, 1, 0)
listFooter.Size = UDim2.new(1, 0, 0, FOOTER_H)
listFooter.BackgroundColor3 = CORES.fundo2
listFooter.BackgroundTransparency = 0.2
listFooter.BorderSizePixel = 0
listFooter.ZIndex = 51
listFooter.Parent = playersList

local footerDivider = Instance.new("Frame")
footerDivider.Size = UDim2.new(1, 0, 0, 1)
footerDivider.BackgroundColor3 = CORES.secundaria
footerDivider.BackgroundTransparency = 0.75
footerDivider.BorderSizePixel = 0
footerDivider.ZIndex = 52
footerDivider.Parent = listFooter

local footerTpBtn = Instance.new("TextButton")
footerTpBtn.Name = "FooterTP"
footerTpBtn.Position = UDim2.fromOffset(10, 7)
footerTpBtn.Size = UDim2.new(0.5, -14, 0, 24)
footerTpBtn.BackgroundColor3 = CORES.primaria
footerTpBtn.BackgroundTransparency = 0.75
footerTpBtn.BorderSizePixel = 0
footerTpBtn.Text = "🎯 TP"
footerTpBtn.Font = Enum.Font.GothamBold
footerTpBtn.TextSize = 10
footerTpBtn.TextColor3 = CORES.primaria
footerTpBtn.AutoButtonColor = false
footerTpBtn.ZIndex = 52
footerTpBtn.Parent = listFooter
corner(footerTpBtn, 6)
stroke(footerTpBtn, CORES.primaria, 1, 0.4)

local footerCamBtn = Instance.new("TextButton")
footerCamBtn.Name = "FooterCAM"
footerCamBtn.AnchorPoint = Vector2.new(1, 0)
footerCamBtn.Position = UDim2.new(1, -10, 0, 7)
footerCamBtn.Size = UDim2.new(0.5, -14, 0, 24)
footerCamBtn.BackgroundColor3 = CORES.secundaria
footerCamBtn.BackgroundTransparency = 0.75
footerCamBtn.BorderSizePixel = 0
footerCamBtn.Text = "👁 CAM"
footerCamBtn.Font = Enum.Font.GothamBold
footerCamBtn.TextSize = 10
footerCamBtn.TextColor3 = CORES.secundaria
footerCamBtn.AutoButtonColor = false
footerCamBtn.ZIndex = 52
footerCamBtn.Parent = listFooter
corner(footerCamBtn, 6)
stroke(footerCamBtn, CORES.secundaria, 1, 0.4)

-- Lista arrastável pelo header dela
makeDraggable(listHeader, playersList, "listPos")

-- =========================================================
-- TP / CAM
-- =========================================================
local function teleportToPlayer(target)
    if not target or target == LocalPlayer then
        return false
    end

    local myRoot = getRoot(LocalPlayer)
    local theirRoot = getRoot(target)

    if not myRoot or not theirRoot then
        return false
    end

    pcall(function()
        myRoot.CFrame = theirRoot.CFrame * CFrame.new(0, 0, 3)
    end)

    return true
end

function stopSpectate()
    if spectateConn then
        spectateConn:Disconnect()
        spectateConn = nil
    end

    spectating = nil

    local myHum = getHumanoid()
    if myHum and workspace.CurrentCamera then
        workspace.CurrentCamera.CameraSubject = myHum
    end

    if updatePlayerList then
        updatePlayerList()
    end
end

local function startSpectate(target)
    if not target or target == LocalPlayer then
        return
    end

    stopSpectate()
    spectating = target

    spectateConn = RunService.RenderStepped:Connect(function()
        local t = spectating

        if not t or not t.Parent then
            stopSpectate()
            return
        end

        local char = t.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if hum and hum.Health > 0 and workspace.CurrentCamera then
            workspace.CurrentCamera.CameraSubject = hum
        end
    end)

    updatePlayerList()
end

-- =========================================================
-- UPDATE LISTA
-- =========================================================
function updatePlayerList()
    if not listScroll then
        return
    end

    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local others = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local dn = string.lower(p.DisplayName)
            local un = string.lower(p.Name)

            if searchTerm == ""
                or string.find(dn, searchTerm, 1, true)
                or string.find(un, searchTerm, 1, true) then
                table.insert(others, p)
            end
        end
    end

    table.sort(others, function(a, b)
        return string.lower(a.DisplayName) < string.lower(b.DisplayName)
    end)

    listTitle.Text = "👥 JOGADORES (" .. #others .. ")"

    if #others == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 36)
        empty.BackgroundTransparency = 1
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 10
        empty.TextColor3 = CORES.subtexto
        empty.Text = "Nenhum jogador"
        empty.LayoutOrder = 1
        empty.ZIndex = 52
        empty.Parent = listScroll
        return
    end

    for i, plr in ipairs(others) do
        local isSelected = selectedPlayer == plr
        local isSpectating = spectating == plr

        local row = Instance.new("TextButton")
        row.Name = "Player_" .. plr.Name
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundColor3 = isSelected and CORES.primaria
            or (isSpectating and CORES.secundaria or CORES.fundo)
        row.BackgroundTransparency = isSelected and 0.75
            or (isSpectating and 0.8 or 0.3)
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.ZIndex = 52
        row.Text = ""
        row.AutoButtonColor = false
        row.Parent = listScroll
        corner(row, 6)

        if isSelected then
            stroke(row, CORES.primaria, 1.5, 0.3)
        end

        local avatar = Instance.new("ImageLabel")
        avatar.Position = UDim2.fromOffset(5, 5)
        avatar.Size = UDim2.fromOffset(32, 32)
        avatar.BackgroundColor3 = CORES.fundo3
        avatar.BorderSizePixel = 0
        avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=60&h=60"
        avatar.ZIndex = 53
        avatar.Parent = row
        corner(avatar, 8)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.Position = UDim2.fromOffset(44, 4)
        nameLabel.Size = UDim2.new(1, -52, 0, 15)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 10
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.TextColor3 = CORES.texto
        nameLabel.Text = plr.DisplayName
        nameLabel.ZIndex = 53
        nameLabel.Parent = row

        local userLabel = Instance.new("TextLabel")
        userLabel.BackgroundTransparency = 1
        userLabel.Position = UDim2.fromOffset(44, 21)
        userLabel.Size = UDim2.new(1, -52, 0, 13)
        userLabel.Font = Enum.Font.Gotham
        userLabel.TextSize = 8
        userLabel.TextXAlignment = Enum.TextXAlignment.Left
        userLabel.TextTruncate = Enum.TextTruncate.AtEnd
        userLabel.TextColor3 = CORES.subtexto
        userLabel.Text = "@" .. plr.Name
        userLabel.ZIndex = 53
        userLabel.Parent = row

        if isSpectating then
            local spectLbl = Instance.new("TextLabel")
            spectLbl.BackgroundTransparency = 1
            spectLbl.AnchorPoint = Vector2.new(1, 0.5)
            spectLbl.Position = UDim2.new(1, -8, 0.5, 0)
            spectLbl.Size = UDim2.fromOffset(44, 14)
            spectLbl.Font = Enum.Font.GothamBold
            spectLbl.TextSize = 8
            spectLbl.TextXAlignment = Enum.TextXAlignment.Right
            spectLbl.TextColor3 = CORES.on
            spectLbl.Text = "👁 ON"
            spectLbl.ZIndex = 53
            spectLbl.Parent = row
        end

        row.Activated:Connect(function()
            selectedPlayer = (selectedPlayer == plr) and nil or plr
            updatePlayerList()
        end)
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchTerm = string.lower(searchBox.Text)
    updatePlayerList()
end)

-- =========================================================
-- BOTÕES DA LISTA
-- =========================================================
footerTpBtn.Activated:Connect(function()
    if not selectedPlayer then
        tween(footerTpBtn, {
            BackgroundColor3 = CORES.danger,
            TextColor3 = CORES.danger,
        }, 0.1)

        task.delay(0.3, function()
            tween(footerTpBtn, {
                BackgroundColor3 = CORES.primaria,
                TextColor3 = CORES.primaria,
            }, 0.25)
        end)
        return
    end

    if teleportToPlayer(selectedPlayer) then
        tween(footerTpBtn, {
            BackgroundColor3 = CORES.on,
            TextColor3 = CORES.on,
            BackgroundTransparency = 0.3,
        }, 0.1)

        task.delay(0.4, function()
            tween(footerTpBtn, {
                BackgroundColor3 = CORES.primaria,
                TextColor3 = CORES.primaria,
                BackgroundTransparency = 0.75,
            }, 0.25)
        end)
    end
end)

footerCamBtn.Activated:Connect(function()
    if not selectedPlayer then
        tween(footerCamBtn, {
            BackgroundColor3 = CORES.danger,
            TextColor3 = CORES.danger,
        }, 0.1)

        task.delay(0.3, function()
            tween(footerCamBtn, {
                BackgroundColor3 = CORES.secundaria,
                TextColor3 = CORES.secundaria,
            }, 0.25)
        end)
        return
    end

    if spectating == selectedPlayer then
        stopSpectate()
    else
        startSpectate(selectedPlayer)
    end
end)

-- =========================================================
-- UPDATE UI / STATUS
-- =========================================================
local function stopPulse()
    if pulseThread then
        task.cancel(pulseThread)
        pulseThread = nil
    end
end

local function startPulse()
    stopPulse()

    pulseThread = task.spawn(function()
        while enabled do
            tween(statusDotGlow, {
                Transparency = 0.2,
                Thickness = 4,
            }, 0.7)

            task.wait(0.7)

            tween(statusDotGlow, {
                Transparency = 0.75,
                Thickness = 2.5,
            }, 0.7)

            task.wait(0.7)
        end
    end)
end

function updateUI()
    if enabled then
        tween(toggleBtn, {BackgroundColor3 = CORES.on}, 0.2)
        tween(toggleKnob, {
            Position = UDim2.new(1, -23, 0.5, -10),
        }, 0.2, Enum.EasingStyle.Back)

        if robberyActive and batAttemptedThisRobbery then
            infoStatusLabel.Text = "⚔ GOLPE FEITO"
            tween(infoStatusLabel, {TextColor3 = CORES.idle}, 0.2)
            statusDot.BackgroundColor3 = CORES.idle
            statusDotGlow.Color = CORES.idle
            startPulse()
        elseif robberyActive then
            infoStatusLabel.Text = "⚔ DEFENDENDO"
            tween(infoStatusLabel, {TextColor3 = CORES.idle}, 0.2)
            statusDot.BackgroundColor3 = CORES.idle
            statusDotGlow.Color = CORES.idle
            startPulse()
        else
            infoStatusLabel.Text = "✅ ATIVADO"
            tween(infoStatusLabel, {TextColor3 = CORES.on}, 0.2)
            statusDot.BackgroundColor3 = CORES.on
            statusDotGlow.Color = CORES.on
            startPulse()
        end
    else
        tween(toggleBtn, {BackgroundColor3 = CORES.off}, 0.2)
        tween(toggleKnob, {
            Position = UDim2.new(0, 3, 0.5, -10),
        }, 0.2, Enum.EasingStyle.Back)
        infoStatusLabel.Text = "⭕ DESATIVADO"
        tween(infoStatusLabel, {TextColor3 = CORES.subtexto}, 0.2)
        statusDot.BackgroundColor3 = CORES.off
        statusDotGlow.Color = CORES.off
        stopPulse()
        statusDotGlow.Transparency = 0.7
        statusDotGlow.Thickness = 2.5
    end

    if robberyActive and currentThief then
        infoTargetLabel.Text = "🎯 ALVO: " .. currentThief.Name
        tween(infoTargetLabel, {TextColor3 = CORES.texto}, 0.2)
    else
        infoTargetLabel.Text = "🎯 ALVO: nenhum"
        tween(infoTargetLabel, {TextColor3 = CORES.subtexto}, 0.2)
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
-- MINIMIZAR
-- =========================================================
local function setMinimized(state)
    minimized = state

    if openingPanelTween then
        pcall(function()
            openingPanelTween:Cancel()
        end)
        openingPanelTween = nil
    end

    local targetH = state and COLLAPSED_H or EXPANDED_H

    tween(panel, {
        Size = UDim2.fromOffset(PANEL_W, targetH),
        BackgroundTransparency = 0,
    }, 0.28, Enum.EasingStyle.Quint)

    minimizeBtn.Text = state and "+" or "-"
end

minimizeBtn.Activated:Connect(function()
    setMinimized(not minimized)
end)

minimizeBtn.MouseEnter:Connect(function()
    tween(minimizeBtn, {
        BackgroundTransparency = 0.1,
        TextColor3 = CORES.destaque,
        BackgroundColor3 = CORES.secundaria,
    }, 0.15)
end)

minimizeBtn.MouseLeave:Connect(function()
    tween(minimizeBtn, {
        BackgroundTransparency = 0.3,
        TextColor3 = CORES.primaria,
        BackgroundColor3 = CORES.fundo3,
    }, 0.15)
end)

-- =========================================================
-- BOTÕES PRINCIPAIS
-- =========================================================
toggleBtn.Activated:Connect(function()
    setEnabled(not enabled)
end)

stopBtn.Activated:Connect(function()
    tween(stopBtn, {BackgroundTransparency = 0.4}, 0.08)

    task.delay(0.15, function()
        if stopBtn.Parent then
            tween(stopBtn, {BackgroundTransparency = 0.85}, 0.2)
        end
    end)

    enabled = false
    STATE.enabled = false
    releaseFromThief()
    unequipBat()
    updateUI()
end)

stopBtn.MouseEnter:Connect(function()
    tween(stopBtn, {BackgroundTransparency = 0.65}, 0.15)
end)

stopBtn.MouseLeave:Connect(function()
    tween(stopBtn, {BackgroundTransparency = 0.85}, 0.15)
end)

-- =========================================================
-- ABRIR/FECHAR LISTA — janela independente (painel NÃO fecha)
-- =========================================================
local function computeListPos()
    if STATE.listPos then return STATE.listPos end

    -- Encosta na ESQUERDA do painel, mesma linha de topo.
    local panelLeftEdge = panel.Position.X.Offset - PANEL_W

    return UDim2.new(
        panel.Position.X.Scale,
        panelLeftEdge - (LIST_W + 8),
        panel.Position.Y.Scale,
        panel.Position.Y.Offset
    )
end

local function closePlayerList()
    playersListOpen = false

    tween(playersList, {
        Size = UDim2.fromOffset(0, LIST_H),
    }, 0.2, Enum.EasingStyle.Quint)

    task.delay(0.22, function()
        if not playersListOpen then
            playersList.Visible = false
        end
    end)

    openListBtn.Text = "👥 ABRIR LISTA"

    if spectating then stopSpectate() end
    selectedPlayer = nil
end

local function openPlayerList()
    playersListOpen = true

    if not STATE.listPos then
        STATE.listPos = computeListPos()
    end
    playersList.Position = STATE.listPos

    playersList.Visible = true
    playersList.Size = UDim2.fromOffset(0, LIST_H)

    tween(playersList, {
        Size = UDim2.fromOffset(LIST_W, LIST_H),
    }, 0.3, Enum.EasingStyle.Back)

    openListBtn.Text = "👥 FECHAR LISTA"
    updatePlayerList()
end

openListBtn.Activated:Connect(function()
    if playersListOpen or playersList.Visible then
        closePlayerList()
    else
        openPlayerList()
    end
end)

openListBtn.MouseEnter:Connect(function()
    tween(openListBtn, {BackgroundTransparency = 0.55}, 0.15)
end)

openListBtn.MouseLeave:Connect(function()
    tween(openListBtn, {BackgroundTransparency = 0.85}, 0.15)
end)

listCloseBtn.Activated:Connect(closePlayerList)

listCloseBtn.MouseEnter:Connect(function()
    tween(listCloseBtn, {
        BackgroundColor3 = CORES.danger,
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.3,
    }, 0.15)
end)

listCloseBtn.MouseLeave:Connect(function()
    tween(listCloseBtn, {
        BackgroundColor3 = CORES.fundo3,
        TextColor3 = CORES.subtexto,
        BackgroundTransparency = 0.4,
    }, 0.15)
end)

-- =========================================================
-- TOPBAR
-- =========================================================
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

pcall(function() defenderIcon:select() end)

defenderIcon:bindEvent("clicked", function()
    guiVisible = not guiVisible
    gui.Enabled = guiVisible

    if guiVisible then
        pcall(function() defenderIcon:select() end)
        defenderIcon:setCaption("SamMods ON")
    else
        pcall(function() defenderIcon:deselect() end)
        defenderIcon:setCaption("SamMods OFF")
    end
end)

-- =========================================================
-- HOTKEYS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == CONFIG.ToggleKey then
        setEnabled(not enabled)
    elseif input.KeyCode == CONFIG.ListToggleKey then
        if playersList.Visible then
            closePlayerList()
        else
            openPlayerList()
        end
    end
end)

-- =========================================================
-- HACKEVENT
-- =========================================================
HackEvent.OnClientEvent:Connect(function(data)
    if typeof(data) ~= "table" then
        return
    end

    local kind = tostring(data.kind or ""):lower()
    local action = tostring(data.action or ""):lower()
    local eventType = tostring(data.type or ""):lower()
    local role = tostring(data.role or ""):lower()

    if END_KINDS[kind]
        or END_KINDS[action]
        or END_KINDS[eventType] then

        robberyActive = false
        stopDefense(true)
        updateUI()
        return
    end

    if kind ~= "phase" then
        return
    end

    if role == "victim" then
        local thief = resolveThief(data)
        if not thief then
            return
        end

        if not robberyActive then
            batAttemptedThisRobbery = false
        end

        robberyActive = true
        currentThief = thief
        updateUI()

        if enabled then
            startDefenseLoop()
        end
    end
end)

-- =========================================================
-- PLAYERS EVENTS
-- =========================================================
Players.PlayerRemoving:Connect(function(player)
    if player == currentThief then
        robberyActive = false
        stopDefense(true)
        updateUI()
    end

    if updatePlayerList then
        updatePlayerList()
    end

    if spectating == player then
        stopSpectate()
    end

    if selectedPlayer == player then
        selectedPlayer = nil
    end
end)

Players.PlayerAdded:Connect(function()
    if updatePlayerList then
        updatePlayerList()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)

    if enabled and robberyActive and currentThief then
        startDefenseLoop()
    end
end)

-- =========================================================
-- LOOP
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

print("[SamMods] v8.7 carregado com sucesso!")

script.Destroying:Connect(function()
    introAlive = false
    enabled = false
    robberyActive = false

    if openingPanelTween then
        pcall(function() openingPanelTween:Cancel() end)
        openingPanelTween = nil
    end

    releaseFromThief()
    unequipBat()
    stopPulse()
    stopSpectate()

    if gui then
        gui:Destroy()
    end

    local intro = PlayerGui:FindFirstChild("SamModsIntro")
    if intro then
        intro:Destroy()
    end

    if STATE.icon then
        pcall(function() STATE.icon:destroy() end)
        STATE.icon = nil
    end
end)
