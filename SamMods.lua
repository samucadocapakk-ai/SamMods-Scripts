--[[
    ============================================================
    SamMods Auto Defender • v3
    LocalScript - StarterPlayerScripts
    ============================================================

    BASE:
    - Auto Defender / Baseball Bat
    - HackEvent victim -> identifica o ladrão
    - ESP do ladrão
    - MeleeHit no ladrão durante a defesa
    - Solta quando o roubo termina

    NOVA ESTRUTURA:
    - Bolha pequena para abrir/fechar CONFIGURAÇÕES
    - LOJA independente do painel de configurações
    - Configurações com funções do sistema antigo
    - Stats / Roubos
    - Metas
    - Modo discreto
    - Som / efeitos / notificações / ESP / seta / auto-lock
    - Editor de interface por seleção:
        * clique em objetos
        * arraste um retângulo para selecionar vários
        * escala somente os selecionados
        * seleção múltipla
    - Não aplica UIScale automaticamente no painel da SamMods
    - Painéis próprios: sem fundo e sem borda estrutural.
      Contornos ficam nos textos/imagens/badges quando úteis.

    OBS:
    Tudo continua LOCAL. Nenhum Script de servidor é criado.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HackEvent = Remotes:WaitForChild("HackEvent")
local MeleeHit = Remotes:WaitForChild("MeleeHit")
local OpenTokenExchange = Remotes:FindFirstChild("OpenTokenExchange")

-- ============================================================
-- TAKEOVER: SOMENTE O AUTO DEFENDER
-- ============================================================

local INSTANCE_MARKER = "SamMods_AutoDefender_Instance"
local GUI_NAME = "SamModsAutoDefenderV3"

local oldMarker = PlayerGui:FindFirstChild(INSTANCE_MARKER)
if oldMarker then
    oldMarker:Destroy()
end

for _, name in ipairs({
    GUI_NAME,
    "SamModsAutoDefender",
    "SamMods_AutoDefender",
}) do
    local oldGui = PlayerGui:FindFirstChild(name)
    if oldGui then
        oldGui:Destroy()
    end
end

local instanceMarker = Instance.new("BoolValue")
instanceMarker.Name = INSTANCE_MARKER
instanceMarker.Value = true
instanceMarker.Parent = PlayerGui

-- ============================================================
-- CONFIG
-- ============================================================

local CONFIG = {
    ToolName = "Baseball Bat",
    FollowOffset = CFrame.new(0, 0, 3),
    AttemptDuration = 0.45,
    RetryDelay = 0.55,
    EquipDelay = 0.15,
    MeleeInterval = 0.10,

    PriceMin = 5,
    PriceMax = 15,
    PriceSpike = 12,
    BasePrice = 10,
    EpochSeconds = 30,

    ChatCooldown = 27,
    MaxMessage = "🌈 Loja: preço dos tokens está no máximo",

    RainbowSpeed = 0.45,

    MetaTokens = 0,
    MetaValor = 0,
}

-- Config do jogo, quando disponível.
do
    local ok, gameConfig = pcall(function()
        local Shared = ReplicatedStorage:WaitForChild("Shared", 5)
        return Shared and require(Shared:WaitForChild("Config", 5))
    end)

    if ok and gameConfig and gameConfig.Tokens then
        CONFIG.PriceMin = math.floor(tonumber(gameConfig.Tokens.priceMin) or CONFIG.PriceMin)
        CONFIG.PriceMax = math.floor(tonumber(gameConfig.Tokens.priceMax) or CONFIG.PriceMax)
        CONFIG.PriceSpike = math.floor(tonumber(gameConfig.Tokens.spikePrice) or CONFIG.PriceSpike)
        CONFIG.BasePrice = math.floor(tonumber(gameConfig.Tokens.basePrice) or CONFIG.BasePrice)
        CONFIG.EpochSeconds = math.max(
            1,
            math.floor(
                tonumber(gameConfig.Tokens.priceEpochSeconds)
                or CONFIG.EpochSeconds
            )
        )
    end
end

-- ============================================================
-- ESTADOS
-- ============================================================

local S = {
    autoDefender = false,
    somAlerta = true,
    efeitosMaximo = true,
    avisoChatAuto = true,
    espLadrao = true,
    setaLadrao = true,
    tagsJogadores = false,
    autoTravar = false,
    notificacoes = true,
    lojaVisivel = true,
    mostrarNotificacaoMaximo = true,
}

local stats = {
    inicioSessao = os.clock(),
    tokensIniciais = nil,
    tokensAtuais = 0,
    maiorPreco = 0,
    vezesNoMaximo = 0,
    roubosSofridos = 0,
}

local logRoubos = {}

local enabled = false
local robberyActive = false
local currentThief = nil
local followConnection = nil
local defenseThread = nil

local shopMaxActive = false
local lastPrice = nil
local lastChatMessageAt = -math.huge

local modoDiscreto = false
local configOpen = false

local tagConnections = {}
local thiefEspGui = nil
local thiefEspConnections = {}
local setaLadrao = nil

local maxConnections = {}

-- ============================================================
-- CORES
-- ============================================================

local COLORS = {
    Text = Color3.fromRGB(245, 247, 250),
    Muted = Color3.fromRGB(165, 170, 182),
    Accent = Color3.fromRGB(85, 165, 255),
    Good = Color3.fromRGB(60, 210, 120),
    Danger = Color3.fromRGB(235, 75, 75),
    Gold = Color3.fromRGB(255, 205, 65),
    Orange = Color3.fromRGB(255, 140, 45),
    Green = Color3.fromRGB(80, 220, 120),
}

local SYSTEM_PREFIXES = {
    SamModsAutoDefenderV3 = true,
    SamModsAutoDefender = true,
    SamMods_AutoDefender = true,
}

-- ============================================================
-- HELPERS UI
-- ============================================================

local function tween(obj, props, duration, style, direction)
    return TweenService:Create(
        obj,
        TweenInfo.new(
            duration or 0.18,
            style or Enum.EasingStyle.Quad,
            direction or Enum.EasingDirection.Out
        ),
        props
    )
end

local function make(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

local function addTextStroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(0, 0, 0)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = obj
    return s
end

local function addCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end

local function disconnect(conn)
    if conn then
        pcall(function()
            conn:Disconnect()
        end)
    end
end

local function disconnectList(list)
    for key, conn in pairs(list) do
        disconnect(conn)
        list[key] = nil
    end
end

local function isSystemGui(obj)
    if not obj:IsA("GuiObject") then
        return true
    end

    local root = obj:FindFirstAncestorOfClass("ScreenGui")
    if not root then
        return true
    end

    if SYSTEM_PREFIXES[root.Name] then
        return true
    end

    if root.Name == "SamModsNotifyV3" then
        return true
    end

    if root.Name == "SamModsUIEditor" then
        return true
    end

    return false
end

-- ============================================================
-- RAINBOW DRIVER
-- ============================================================

local Rainbow = {}

do
    local subscribers = {}
    local hue = 0
    local connection

    connection = RunService.RenderStepped:Connect(function(dt)
        hue = (hue + dt * CONFIG.RainbowSpeed) % 1
        local color = Color3.fromHSV(hue, 1, 1)

        for obj, callback in pairs(subscribers) do
            if typeof(obj) ~= "Instance" or obj.Parent == nil then
                subscribers[obj] = nil
            else
                local ok = pcall(callback, color)
                if not ok then
                    subscribers[obj] = nil
                end
            end
        end
    end)

    function Rainbow.add(obj, callback)
        subscribers[obj] = callback
    end

    function Rainbow.remove(obj)
        subscribers[obj] = nil
    end

    function Rainbow.color()
        return Color3.fromHSV(hue, 1, 1)
    end
end

-- ============================================================
-- NOTIFICAÇÕES
-- ============================================================

local notifyGui = make("ScreenGui", {
    Name = "SamModsNotifyV3",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 250,
}, PlayerGui)

local notifyHolder = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.fromScale(0.5, 0),
    Size = UDim2.fromOffset(300, 420),
    BackgroundTransparency = 1,
}, notifyGui)

make("UIListLayout", {
    Padding = UDim.new(0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, notifyHolder)

local notifyIndex = 0

local AlertSound = Instance.new("Sound")
AlertSound.Name = "SamMods_AutoDefenderAlert"
AlertSound.SoundId = "rbxassetid://171165317"
AlertSound.Volume = 3
AlertSound.Looped = true
AlertSound.Parent = game:GetService("SoundService")

local NotifySound = Instance.new("Sound")
NotifySound.Name = "SamMods_AutoDefenderNotify"
NotifySound.SoundId = "rbxassetid://71450094482101"
NotifySound.Volume = 3
NotifySound.Parent = game:GetService("SoundService")

local function playSound(sound)
    pcall(function()
        sound:Stop()
        sound.TimePosition = 0
        sound:Play()
    end)
end

local function notify(options)
    if not S.notificacoes then
        return
    end

    notifyIndex += 1

    local item = make("Frame", {
        Size = UDim2.fromOffset(300, 54),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = notifyIndex,
    }, notifyHolder)

    local title = make("TextLabel", {
        Position = UDim2.fromOffset(8, 2),
        Size = UDim2.new(1, -16, 0, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 12,
        TextColor3 = options.color or COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = options.title or "",
    }, item)

    local body = make("TextLabel", {
        Position = UDim2.fromOffset(8, 20),
        Size = UDim2.new(1, -16, 0, 30),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextWrapped = true,
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = options.text or "",
    }, item)

    addTextStroke(title, Color3.fromRGB(0, 0, 0), 1.2, 0.1)
    addTextStroke(body, Color3.fromRGB(0, 0, 0), 1, 0.15)

    local rainbowConn
    if options.rainbow then
        rainbowConn = RunService.RenderStepped:Connect(function()
            if not item.Parent then
                disconnect(rainbowConn)
                return
            end
            title.TextColor3 = Rainbow.color()
        end)
    end

    if options.sound ~= false then
        playSound(NotifySound)
    end

    task.delay(options.duration or 4.5, function()
        disconnect(rainbowConn)
        if item.Parent then
            item:Destroy()
        end
    end)
end

-- ============================================================
-- CHAT
-- ============================================================

local function sendChat(text)
    text = text or CONFIG.MaxMessage

    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channels = TextChatService:FindFirstChild("TextChannels")
        local general = channels and channels:FindFirstChild("RBXGeneral")

        if general then
            local ok = pcall(function()
                general:SendAsync(text)
            end)

            if ok then
                return true
            end
        end
    end

    return pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = text,
            Font = Enum.Font.GothamBold,
            TextSize = 18,
        })
    end)
end

local function tryAutoChat()
    if not S.avisoChatAuto then
        return false
    end

    local now = os.clock()
    if now - lastChatMessageAt < CONFIG.ChatCooldown then
        return false
    end

    lastChatMessageAt = now
    sendChat(CONFIG.MaxMessage)
    return true
end

-- ============================================================
-- TOKENS / LOJA
-- ============================================================

local UNITS = {
    {1e63, "Vg"},
    {1e60, "Nod"},
    {1e57, "Ocd"},
    {1e54, "Spd"},
    {1e51, "Sxd"},
    {1e48, "Qid"},
    {1e45, "Qad"},
    {1e42, "Td"},
    {1e39, "Dd"},
    {1e36, "Ud"},
    {1e33, "Dc"},
    {1e30, "No"},
    {1e27, "Oc"},
    {1e24, "Sp"},
    {1e21, "Sx"},
    {1e18, "Qi"},
    {1e15, "Qa"},
    {1e12, "T"},
    {1e9, "B"},
    {1e6, "M"},
    {1e3, "K"},
}

local UNIT_MULTIPLIERS = {}
for _, pair in ipairs(UNITS) do
    UNIT_MULTIPLIERS[pair[2]:lower()] = pair[1]
end

local function formatNumber(number)
    number = tonumber(number) or 0

    local negative = number < 0
    local absolute = math.abs(number)

    for _, pair in ipairs(UNITS) do
        if absolute >= pair[1] then
            local value = math.floor((absolute / pair[1]) * 10) / 10
            local text = string.format("%.1f", value):gsub("%.0$", "")
            return (negative and "-" or "") .. text .. pair[2]
        end
    end

    return (negative and "-" or "") .. tostring(math.floor(absolute + 0.5))
end

local function parseShort(text)
    if not text then
        return nil
    end

    local numberText, suffix =
        text:match("(%-?%d+[%.,]?%d*)%s*(%a*)")

    if not numberText then
        return nil
    end

    local number = tonumber(numberText:gsub(",", "."))
    if not number then
        return nil
    end

    if suffix == "" then
        return number
    end

    local multiplier = UNIT_MULTIPLIERS[suffix:lower()]
    if multiplier then
        return number * multiplier
    end

    return number
end

local tokensLabel

task.spawn(function()
    local ok, result = pcall(function()
        local hud = PlayerGui:WaitForChild("HUD", 15)
        local spendables = hud:WaitForChild("Spendables", 15)
        local tokenRow = spendables:WaitForChild("TokenRow", 15)
        return tokenRow:WaitForChild("Tokens", 15)
    end)

    if ok then
        tokensLabel = result
    end
end)

local function readTokens()
    if tokensLabel and tokensLabel.Parent then
        local value = parseShort(tokensLabel.Text)
        if value then
            return value
        end
    end

    return tonumber(LocalPlayer:GetAttribute("Tokens")) or 0
end

local function startMaxEffect()
    if shopMaxActive then
        return
    end

    shopMaxActive = true
    stats.vezesNoMaximo += 1

    if S.efeitosMaximo then
        maxConnections.render = RunService.RenderStepped:Connect(function()
            if not shopMaxActive then
                return
            end

            local c = Rainbow.color()
            storePrice.TextColor3 = c
            storeStatus.TextColor3 = c
            storeIcon.TextColor3 = c
        end)
    end

    if S.mostrarNotificacaoMaximo then
        notify({
            title = "🌈 LOJA NO MÁXIMO",
            text = ("$%d por token"):format(CONFIG.PriceMax),
            color = COLORS.Gold,
            rainbow = true,
            duration = 5,
        })
    end

    tryAutoChat()
end

local function stopMaxEffect()
    shopMaxActive = false
    disconnect(maxConnections.render)
    maxConnections.render = nil
    storeIcon.TextColor3 = COLORS.Gold
end

-- ============================================================
-- AUTO DEFENDER + ESP
-- ============================================================

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot(player)
    if not player or not player.Character then
        return nil
    end

    return player.Character:FindFirstChild("HumanoidRootPart")
end

local function getBat()
    local char = getCharacter()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

    if char then
        local tool = char:FindFirstChild(CONFIG.ToolName)
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

    return nil
end

local function equipBat()
    local humanoid = getHumanoid()
    local bat = getBat()

    if not humanoid or not bat then
        return false
    end

    if bat.Parent ~= getCharacter() then
        pcall(function()
            humanoid:EquipTool(bat)
        end)

        task.wait(CONFIG.EquipDelay)
    end

    local equipped =
        getCharacter()
        and getCharacter():FindFirstChild(CONFIG.ToolName)

    return equipped ~= nil
        and equipped:IsA("Tool")
end

local function unequipBat()
    local humanoid = getHumanoid()
    if humanoid then
        pcall(function()
            humanoid:UnequipTools()
        end)
    end
end

local function releaseFromThief()
    disconnect(followConnection)
    followConnection = nil
end

local function followThief(thief)
    releaseFromThief()

    local mine = getRoot(LocalPlayer)
    local target = getRoot(thief)

    if not mine or not target then
        return false
    end

    pcall(function()
        mine.CFrame =
            target.CFrame
            * CONFIG.FollowOffset
    end)

    followConnection =
        RunService.Heartbeat:Connect(function()
            if not enabled
                or not robberyActive
                or currentThief ~= thief then

                releaseFromThief()
                return
            end

            local myRoot = getRoot(LocalPlayer)
            local thiefRoot = getRoot(thief)

            if not myRoot or not thiefRoot then
                releaseFromThief()
                return
            end

            pcall(function()
                myRoot.CFrame =
                    thiefRoot.CFrame
                    * CONFIG.FollowOffset
            end)
        end)

    return true
end

local function fireMelee(thief)
    if not thief then
        return false
    end

    if not MeleeHit:IsA("RemoteEvent") then
        return false
    end

    return pcall(function()
        MeleeHit:FireServer(thief)
    end)
end

local function cleanupThiefESP()
    disconnectList(thiefEspConnections)

    if thiefEspGui then
        pcall(function()
            thiefEspGui:Destroy()
        end)
    end

    thiefEspGui = nil
    if setaLadrao then
        setaLadrao.Visible = false
    end
end

function noop()
end

local function showThiefESP(player)
    if not S.espLadrao or not player then
        return
    end

    cleanupThiefESP()

    task.spawn(function()
        local character = player.Character or player.CharacterAdded:Wait()
        local root = character:WaitForChild("HumanoidRootPart", 5)

        if not root
            or not robberyActive
            or currentThief ~= player then
            return
        end

        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.78
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "SamModsThiefESP"
        billboard.Adornee = root
        billboard.Size = UDim2.fromOffset(88, 92)
        billboard.StudsOffset = Vector3.new(0, 3.1, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 500
        billboard.Parent = character

        thiefEspGui = billboard

        local avatar = make("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.fromOffset(42, 42),
            BackgroundTransparency = 1,
            Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(player.UserId),
        }, billboard)
        addTextStroke(avatar, Color3.fromRGB(255, 255, 255), 1.5, 0)

        local name = make("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 44),
            Size = UDim2.new(1.6, 0, 0, 18),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBlack,
            TextSize = 12,
            Text = "🚨 " .. player.Name,
            TextColor3 = COLORS.Text,
        }, billboard)
        addTextStroke(name, Color3.fromRGB(0, 0, 0), 1.4, 0)

        local distance = make("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 62),
            Size = UDim2.new(1.6, 0, 0, 14),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            Text = "-- studs",
            TextColor3 = COLORS.Text,
        }, billboard)
        addTextStroke(distance, Color3.fromRGB(0, 0, 0), 1, 0)

        thiefEspConnections.rainbow =
            RunService.RenderStepped:Connect(function()
                if not billboard.Parent then
                    return
                end

                local c = Rainbow.color()

                highlight.OutlineColor = c
                highlight.FillColor = c
                name.TextColor3 = c
            end)

        thiefEspConnections.distance =
            RunService.Heartbeat:Connect(function()
                local myRoot = getRoot(LocalPlayer)
                local thiefRoot = character:FindFirstChild("HumanoidRootPart")

                if myRoot and thiefRoot then
                    distance.Text = ("%d studs"):format(
                        math.floor(
                            (myRoot.Position - thiefRoot.Position).Magnitude
                        )
                    )
                end
            end)
    end)
end

local function stopDefense()
    releaseFromThief()
    cleanupThiefESP()
    currentThief = nil
    unequipBat()
end

local function oneAttempt(thief)
    if not enabled
        or not robberyActive
        or not thief then
        return
    end

    if thief.Parent ~= Players
        or not getRoot(thief) then
        return
    end

    if not equipBat() then
        return
    end

    if not followThief(thief) then
        return
    end

    local started = os.clock()

    while enabled
        and robberyActive
        and currentThief == thief
        and os.clock() - started < CONFIG.AttemptDuration do

        if not getRoot(thief) then
            break
        end

        fireMelee(thief)
        task.wait(CONFIG.MeleeInterval)
    end

    if not enabled or not robberyActive then
        stopDefense()
        return
    end

    releaseFromThief()
end

local function startDefenseLoop()
    if defenseThread
        or not enabled
        or not robberyActive
        or not currentThief then
        return
    end

    defenseThread =
        task.spawn(function()

            while enabled
                and robberyActive
                and currentThief do

                local thief = currentThief

                if thief.Parent ~= Players then
                    break
                end

                oneAttempt(thief)

                if not enabled
                    or not robberyActive
                    or currentThief ~= thief then
                    break
                end

                task.wait(CONFIG.RetryDelay)
            end

            defenseThread = nil

            if not robberyActive
                or not enabled then

                releaseFromThief()
                unequipBat()
            end
        end)
end

local function resolveThief(data)
    if typeof(data) ~= "table" then
        return nil
    end

    for _, id in ipairs({
        tonumber(data.userId),
        tonumber(data.attackerUserId),
        tonumber(data.attackerId),
        tonumber(data.thiefUserId),
        tonumber(data.thiefId),
        tonumber(data.robberUserId),
        tonumber(data.robberId),
    }) do
        if id then
            local player = Players:GetPlayerByUserId(id)
            if player and player ~= LocalPlayer then
                return player
            end
        end
    end

    for _, name in ipairs({
        data.attackerName,
        data.thiefName,
        data.robberName,
        data.name,
    }) do
        if typeof(name) == "string" and name ~= "" then
            local player = Players:FindFirstChild(name)
            if player and player ~= LocalPlayer then
                return player
            end
        end
    end

    return nil
end

-- ============================================================
-- ALERTA / ROUBO
-- ============================================================

local alertaAtivo = false

local function iniciarAlerta()
    if alertaAtivo then
        return
    end

    alertaAtivo = true

    if S.somAlerta then
        playSound(AlertSound)
    end
end

local function pararAlerta()
    alertaAtivo = false
    pcall(function()
        AlertSound:Stop()
    end)
end

local robberyEndKinds = {
    result = true,
    abort = true,
    ["end"] = true,
    ended = true,
    finish = true,
    finished = true,
    robbery_end = true,
    steal_end = true,
}

local function registerRobbery(player)
    stats.roubosSofridos += 1

    if not player then
        return
    end

    for _, entry in ipairs(logRoubos) do
        if entry.userId == player.UserId then
            entry.times += 1
            entry.time = os.date("%H:%M:%S")
            return
        end
    end

    table.insert(logRoubos, {
        userId = player.UserId,
        name = player.Name,
        times = 1,
        time = os.date("%H:%M:%S"),
    })

    while #logRoubos > 20 do
        table.remove(logRoubos, 1)
    end
end

HackEvent.OnClientEvent:Connect(function(data)
    if typeof(data) ~= "table" then
        return
    end

    local kind = tostring(data.kind or ""):lower()
    local action = tostring(data.action or ""):lower()
    local eventType = tostring(data.type or ""):lower()
    local role = tostring(data.role or ""):lower()

    if robberyEndKinds[kind]
        or robberyEndKinds[action]
        or robberyEndKinds[eventType] then

        robberyActive = false
        pararAlerta()
        stopDefense()
        return
    end

    if kind == "phase" then
        if role == "victim" then
            local thief = resolveThief(data)

            if thief then
                if not robberyActive then
                    registerRobbery(thief)

                    notify({
                        title = "🚨 ESTÃO TE ROUBANDO",
                        text = thief.Name .. " está tentando te roubar.",
                        color = COLORS.Danger,
                        duration = 5,
                    })
                end

                robberyActive = true
                currentThief = thief

                iniciarAlerta()

                if S.espLadrao then
                    showThiefESP(thief)
                end

                if enabled then
                    startDefenseLoop()
                end
            end

        elseif role == "attacker" then
            -- você é o atacante; não inicia defesa
        end

        return
    end

    if kind == "result"
        or kind == "abort"
        or kind == "end"
        or kind == "ended"
        or kind == "finish"
        or kind == "finished" then

        robberyActive = false
        pararAlerta()
        stopDefense()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player == currentThief then
        robberyActive = false
        pararAlerta()
        stopDefense()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.4)

    if enabled
        and robberyActive
        and currentThief then

        if S.espLadrao then
            showThiefESP(currentThief)
        end

        startDefenseLoop()
    end
end)

-- ============================================================
-- SETA DO LADRÃO
-- ============================================================

local function createThiefArrow()
    if setaLadrao then
        return
    end

    setaLadrao = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(44, 44),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 31,
        Text = "➤",
        TextColor3 = COLORS.Danger,
        Visible = false,
        ZIndex = 120,
    }, gui)

    addTextStroke(
        setaLadrao,
        Color3.fromRGB(0, 0, 0),
        1.5,
        0
    )
end

local function updateThiefArrow()
    if not setaLadrao then
        return
    end

    if not robberyActive
        or not currentThief
        or not S.setaLadrao
        or modoDiscreto then

        setaLadrao.Visible = false
        return
    end

    local root = getRoot(currentThief)
    local camera = Workspace.CurrentCamera

    if not root or not camera then
        setaLadrao.Visible = false
        return
    end

    local point, onScreen =
        camera:WorldToViewportPoint(root.Position)

    local viewport =
        camera.ViewportSize

    if onScreen
        and point.Z > 0
        and point.X > 0
        and point.X < viewport.X
        and point.Y > 0
        and point.Y < viewport.Y then

        setaLadrao.Visible = false
        return
    end

    local center =
        Vector2.new(
            viewport.X / 2,
            viewport.Y / 2
        )

    local direction =
        Vector2.new(
            point.X,
            point.Y
        ) - center

    if point.Z < 0 then
        direction = -direction
    end

    if direction.Magnitude < 1 then
        direction = Vector2.new(0, -1)
    end

    direction = direction.Unit

    local radius =
        math.min(
            viewport.X,
            viewport.Y
        ) * 0.37

    local position =
        center
        + direction * radius

    setaLadrao.Visible = true
    setaLadrao.Position =
        UDim2.fromOffset(
            position.X,
            position.Y
        )

    setaLadrao.Rotation =
        math.deg(
            math.atan2(
                direction.Y,
                direction.X
            )
        )

    setaLadrao.TextColor3 =
        Rainbow.color()
end

createThiefArrow()

-- ============================================================
-- TAGS LOCAIS
-- ============================================================
-- Mantém o princípio do script local: não marca todo mundo
-- automaticamente como executor. A função é opcional e deixa
-- apenas o visual local configurável.

local function removeLocalTags()
    for _, conn in pairs(tagConnections) do
        disconnect(conn)
    end
    tagConnections = {}

    local character = LocalPlayer.Character
    if character then
        local head = character:FindFirstChild("Head")
        if head then
            local old = head:FindFirstChild("SamModsLocalTag")
            if old then
                old:Destroy()
            end
        end
    end
end

local function createLocalTag()
    removeLocalTags()

    if not S.tagsJogadores then
        return
    end

    local character = LocalPlayer.Character
    if not character then
        return
    end

    local head = character:FindFirstChild("Head")
    if not head then
        return
    end

    local billboard =
        Instance.new("BillboardGui")

    billboard.Name =
        "SamModsLocalTag"

    billboard.Adornee =
        head

    billboard.AlwaysOnTop =
        true

    billboard.LightInfluence =
        0

    billboard.MaxDistance =
        100

    billboard.Size =
        UDim2.fromOffset(
            135,
            28
        )

    billboard.StudsOffset =
        Vector3.new(
            0,
            2.65,
            0
        )

    billboard.Parent =
        head

    local label =
        Instance.new("TextLabel")

    label.BackgroundTransparency =
        1

    label.Size =
        UDim2.fromScale(
            1,
            1
        )

    label.Font =
        Enum.Font.GothamBlack

    label.TextScaled =
        true

    label.Text =
        "USER"

    label.TextColor3 =
        Color3.fromRGB(
            155,
            155,
            155
        )

    label.Parent =
        billboard

    addTextStroke(
        label,
        Color3.fromRGB(0, 0, 0),
        1.2,
        0.15
    )

    tagConnections.character =
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.3)
            createLocalTag()
        end)
end

-- ============================================================
-- UI RAIZ
-- ============================================================

local gui =
    make("ScreenGui", {
        Name = GUI_NAME,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 60,
    }, PlayerGui)

-- Sem fundo e sem borda estrutural.
-- A escala fica aqui somente para os elementos do Auto Defender.
local guiScale =
    make("UIScale", {
        Scale = 1,
    }, gui)

-- ============================================================
-- BOLHA DE CONFIGURAÇÕES
-- ============================================================

local settingsBubble =
    make("TextButton", {
        Name = "SettingsBubble",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 88),
        Size = UDim2.fromOffset(38, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBlack,
        TextSize = 21,
        Text = "⚙",
        TextColor3 = COLORS.Text,
        ZIndex = 100,
    }, gui)

addTextStroke(
    settingsBubble,
    Color3.fromRGB(0, 0, 0),
    1.7,
    0
)

Rainbow.add(settingsBubble, function(c)
    if configOpen then
        settingsBubble.TextColor3 = c
    end
end)

-- ============================================================
-- LOJA INDEPENDENTE
-- ============================================================

local storeWidget =
    make("Frame", {
        Name = "StoreWidget",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 132),
        Size = UDim2.fromOffset(178, 62),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 80,
    }, gui)

local storeIcon =
    make("TextLabel", {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(28, 22),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 16,
        Text = "💎",
        TextColor3 = COLORS.Gold,
        ZIndex = 81,
    }, storeWidget)

addTextStroke(
    storeIcon,
    Color3.fromRGB(0, 0, 0),
    1.2,
    0
)

local storePrice =
    make("TextLabel", {
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.fromOffset(72, 22),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 17,
        Text = "$10",
        TextColor3 = COLORS.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 81,
    }, storeWidget)

addTextStroke(
    storePrice,
    Color3.fromRGB(0, 0, 0),
    1.4,
    0
)

local storeStatus =
    make("TextLabel", {
        Position = UDim2.fromOffset(100, 1),
        Size = UDim2.new(1, -100, 0, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        Text = "NORMAL",
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 81,
    }, storeWidget)

addTextStroke(
    storeStatus,
    Color3.fromRGB(0, 0, 0),
    1,
    0.15
)

local storeEarnings =
    make("TextLabel", {
        Position = UDim2.fromOffset(0, 23),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        Text = "Tokens: 0  •  Receber: $0",
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 81,
    }, storeWidget)

addTextStroke(
    storeEarnings,
    Color3.fromRGB(0, 0, 0),
    1,
    0.2
)

local storeTimer =
    make("TextLabel", {
        Position = UDim2.fromOffset(0, 40),
        Size = UDim2.new(1, -2, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 8,
        Text = "Troca em --s",
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 81,
    }, storeWidget)

addTextStroke(
    storeTimer,
    Color3.fromRGB(0, 0, 0),
    1,
    0.2
)

storeWidget.MouseEnter = nil

-- Clique abre a loja do jogo.
storeWidget.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    if OpenTokenExchange then
        if OpenTokenExchange:IsA("RemoteEvent") then
            pcall(function()
                OpenTokenExchange:FireServer()
            end)
        elseif OpenTokenExchange:IsA("BindableEvent") then
            pcall(function()
                OpenTokenExchange:Fire()
            end)
        end
    end
end)

-- ============================================================
-- PAINEL DE CONFIGURAÇÕES
-- ============================================================

local settingsPanel =
    make("Frame", {
        Name = "SettingsPanel",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 88),
        Size = UDim2.fromOffset(238, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 110,
    }, gui)

local header =
    make("TextLabel", {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 14,
        Text = "SamMods • Configurações",
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 111,
    }, settingsPanel)

addTextStroke(
    header,
    Color3.fromRGB(0, 0, 0),
    1.4,
    0
)

local closeButton =
    make("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(26, 24),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBlack,
        TextSize = 14,
        Text = "✕",
        TextColor3 = COLORS.Text,
        ZIndex = 112,
    }, settingsPanel)

addTextStroke(
    closeButton,
    Color3.fromRGB(0, 0, 0),
    1.2,
    0
)

local panelContent =
    make("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 1, -30),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 111,
    }, settingsPanel)

make("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, panelContent)

-- ============================================================
-- COMPONENTES DO PAINEL
-- ============================================================

local function makeSection(text, order)
    local label =
        make("TextLabel", {
            Size = UDim2.new(1, -6, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBlack,
            TextSize = 10,
            TextColor3 = COLORS.Muted,
            Text = text,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = order,
            ZIndex = 112,
        }, panelContent)

    addTextStroke(
        label,
        Color3.fromRGB(0, 0, 0),
        1,
        0.18
    )

    return label
end

local function makeRow(text, order, rightText)
    local row =
        make("Frame", {
            Size = UDim2.new(1, -4, 0, 27),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = order,
            ZIndex = 112,
        }, panelContent)

    local label =
        make("TextLabel", {
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, -74, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextColor3 = COLORS.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = text,
            ZIndex = 113,
        }, row)

    addTextStroke(
        label,
        Color3.fromRGB(0, 0, 0),
        1,
        0.2
    )

    local button =
        make("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(62, 22),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBlack,
            TextSize = 9,
            Text = rightText or "OFF",
            TextColor3 = COLORS.Muted,
            ZIndex = 113,
        }, row)

    addTextStroke(
        button,
        Color3.fromRGB(0, 0, 0),
        1,
        0.1
    )

    return row, button
end

local function bindToggle(text, key, order, callback)
    local row, button =
        makeRow(
            text,
            order,
            S[key] and "ON" or "OFF"
        )

    local function refresh()
        button.Text = S[key] and "ON" or "OFF"
        button.TextColor3 =
            S[key]
            and COLORS.Good
            or COLORS.Muted
    end

    button.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        refresh()

        if callback then
            callback(S[key])
        end
    end)

    refresh()
    return row, button
end

makeSection("DEFESA", 1)

bindToggle(
    "🛡 Auto Defender",
    "autoDefender",
    2,
    function(value)
        enabled = value

        if enabled
            and robberyActive
            and currentThief then

            startDefenseLoop()
        elseif not enabled then

            releaseFromThief()
            unequipBat()
        end
    end
)

bindToggle(
    "🔔 Som de alerta",
    "somAlerta",
    3,
    function(value)
        if not value then
            AlertSound:Stop()
        elseif alertaAtivo then
            playSound(AlertSound)
        end
    end
)

bindToggle(
    "👁 ESP do ladrão",
    "espLadrao",
    4,
    function(value)
        if value
            and robberyActive
            and currentThief then

            showThiefESP(currentThief)
        else
            cleanupThiefESP()
        end
    end
)

bindToggle(
    "➤ Seta do ladrão",
    "setaLadrao",
    5
)

bindToggle(
    "🔒 Auto-travar no ladrão",
    "autoTravar",
    6,
    function(value)
        if value
            and robberyActive
            and currentThief then

            followThief(currentThief)
        elseif not value then
            releaseFromThief()
        end
    end
)

makeSection("LOJA", 8)

bindToggle(
    "🌈 Efeitos no máximo",
    "efeitosMaximo",
    9,
    function(value)
        if not value then
            stopMaxEffect()
        end
    end
)

bindToggle(
    "💬 Aviso automático no chat",
    "avisoChatAuto",
    10
)

bindToggle(
    "🔔 Notificações",
    "notificacoes",
    11
)

makeSection("OUTROS", 13)

bindToggle(
    "🙈 Modo discreto",
    "lojaVisivel",
    14,
    function(value)
        modoDiscreto = not value
    end
)

local metaTokensRow, metaTokensButton =
    makeRow(
        "💎 Meta de Tokens",
        16,
        "0"
    )

local metaTokensBox =
    make("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(62, 22),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = COLORS.Text,
        Text = "0",
        ZIndex = 114,
    }, metaTokensRow)

addTextStroke(
    metaTokensBox,
    Color3.fromRGB(0, 0, 0),
    1,
    0.1
)

metaTokensBox.FocusLost:Connect(function()
    CONFIG.MetaTokens =
        math.max(
            0,
            parseShort(metaTokensBox.Text)
                or 0
        )
end)

local metaValueRow =
    makeRow(
        "💰 Meta de valor",
        17,
        "0"
    )

local metaValueBox =
    make("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(62, 22),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = COLORS.Text,
        Text = "0",
        ZIndex = 114,
    }, metaValueRow)

addTextStroke(
    metaValueBox,
    Color3.fromRGB(0, 0, 0),
    1,
    0.1
)

metaValueBox.FocusLost:Connect(function()
    CONFIG.MetaValor =
        math.max(
            0,
            parseShort(metaValueBox.Text)
                or 0
        )
end)

local interfaceButton =
    make("TextButton", {
        Size = UDim2.new(1, -4, 0, 28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBlack,
        TextSize = 9,
        Text = "◈ EDITAR INTERFACE / SELECIONAR OBJETOS",
        TextColor3 = COLORS.Accent,
        LayoutOrder = 19,
        ZIndex = 113,
    }, panelContent)

addTextStroke(
    interfaceButton,
    Color3.fromRGB(0, 0, 0),
    1.2,
    0
)

local statsButton =
    make("TextButton", {
        Size = UDim2.new(1, -4, 0, 28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBlack,
        TextSize = 9,
        Text = "📊 ABRIR STATS / ROUBOS",
        TextColor3 = COLORS.Text,
        LayoutOrder = 20,
        ZIndex = 113,
    }, panelContent)

addTextStroke(
    statsButton,
    Color3.fromRGB(0, 0, 0),
    1.2,
    0
)

-- ============================================================
-- STATS / ROUBOS WINDOW
-- ============================================================

local statsWindow =
    make("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 88),
        Size = UDim2.fromOffset(245, 250),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 150,
    }, gui)

local statsTitle =
    make("TextLabel", {
        Size = UDim2.new(1, -28, 0, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 13,
        Text = "📊 Stats / Roubos",
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 151,
    }, statsWindow)

addTextStroke(
    statsTitle,
    Color3.fromRGB(0, 0, 0),
    1.3,
    0
)

local statsClose =
    make("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(24, 22),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBlack,
        TextSize = 13,
        Text = "✕",
        TextColor3 = COLORS.Text,
        ZIndex = 152,
    }, statsWindow)

addTextStroke(
    statsClose,
    Color3.fromRGB(0, 0, 0),
    1.2,
    0
)

local statsContent =
    make("Frame", {
        Position = UDim2.fromOffset(0, 28),
        Size = UDim2.new(1, 0, 1, -28),
        BackgroundTransparency = 1,
        ZIndex = 151,
    }, statsWindow)

local statsLabels = {}

local function makeStatLine(key, labelText, y)
    local label =
        make("TextLabel", {
            Position = UDim2.fromOffset(0, y),
            Size = UDim2.new(0.58, 0, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextColor3 = COLORS.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = labelText,
            ZIndex = 152,
        }, statsContent)

    local value =
        make("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, y),
            Size = UDim2.new(0.42, 0, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextColor3 = COLORS.Text,
            TextXAlignment = Enum.TextXAlignment.Right,
            Text = "--",
            ZIndex = 152,
        }, statsContent)

    addTextStroke(value, Color3.fromRGB(0, 0, 0), 1, 0.18)
    statsLabels[key] = value
end

makeStatLine("time", "⏱ Sessão", 0)
makeStatLine("tokens", "💎 Tokens", 22)
makeStatLine("gain", "📈 Ganho", 44)
makeStatLine("perMin", "⚡ Tokens/min", 66)
makeStatLine("value", "💰 Valor", 88)
makeStatLine("maxPrice", "🏆 Maior preço", 110)
makeStatLine("maxTimes", "🌈 Vezes no máximo", 132)
makeStatLine("robberies", "🚨 Roubos sofridos", 154)

local robberyTitle =
    make("TextLabel", {
        Position = UDim2.fromOffset(0, 180),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 9,
        Text = "Últimos roubos",
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 152,
    }, statsContent)

local robberyList =
    make("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 198),
        Size = UDim2.new(1, 0, 1, -198),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
        ZIndex = 152,
    }, statsContent)

make("UIListLayout", {
    Padding = UDim.new(0, 2),
}, robberyList)

local function refreshRobberyLog()
    for _, child in ipairs(robberyList:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    if #logRoubos == 0 then
        local empty =
            make("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                TextSize = 8,
                TextColor3 = COLORS.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "Nenhum roubo nesta sessão.",
            }, robberyList)

        addTextStroke(empty, Color3.fromRGB(0, 0, 0), 1, 0.2)
        return
    end

    for i = #logRoubos, 1, -1 do
        local item = logRoubos[i]

        local label =
            make("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                TextSize = 8,
                TextColor3 = COLORS.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = ("%s ×%d • %s"):format(
                    item.name,
                    item.times,
                    item.time
                ),
            }, robberyList)

        addTextStroke(label, Color3.fromRGB(0, 0, 0), 1, 0.18)
    end
end

-- ============================================================
-- EDITOR DE INTERFACE
-- ============================================================

local editorGui =
    make("ScreenGui", {
        Name = "SamModsUIEditor",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 400,
        Enabled = false,
    }, PlayerGui)

local selectionArea =
    make("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
    }, editorGui)

local selectionBox =
    make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 1,
        BorderColor3 = COLORS.Accent,
        Visible = false,
        ZIndex = 20,
    }, selectionArea)

local selectionHint =
    make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 10),
        Size = UDim2.fromOffset(330, 30),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 11,
        TextColor3 = COLORS.Text,
        Text = "◈ Arraste para selecionar • toque/click para selecionar",
        ZIndex = 21,
    }, selectionArea)

addTextStroke(
    selectionHint,
    Color3.fromRGB(0, 0, 0),
    1.2,
    0
)

local selectionControls =
    make("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -12),
        Size = UDim2.fromOffset(340, 58),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 30,
    }, selectionArea)

local selectedCountLabel =
    make("TextLabel", {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(110, 22),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = COLORS.Text,
        Text = "0 selecionados",
        ZIndex = 31,
    }, selectionControls)

addTextStroke(
    selectedCountLabel,
    Color3.fromRGB(0, 0, 0),
    1,
    0
)

local function editorButton(text, x, callback)
    local b =
        make("TextButton", {
            Position = UDim2.fromOffset(x, 25),
            Size = UDim2.fromOffset(58, 25),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBlack,
            TextSize = 11,
            Text = text,
            TextColor3 = COLORS.Text,
            ZIndex = 31,
        }, selectionControls)

    addTextStroke(
        b,
        Color3.fromRGB(0, 0, 0),
        1,
        0
    )

    b.MouseButton1Click:Connect(callback)

    return b
end

local selectedObjects = {}

local function clearSelection()
    for obj in pairs(selectedObjects) do
        local marker = obj:FindFirstChild("SamModsSelectionMarker")
        if marker then
            marker:Destroy()
        end
    end
    selectedObjects = {}
    selectedCountLabel.Text = "0 selecionados"
end

local function markSelected(obj)
    if selectedObjects[obj] then
        return
    end

    selectedObjects[obj] = true

    local marker =
        make("SelectionBox", {
            Name = "SamModsSelectionMarker",
            Adornee = obj,
            LineThickness = 0.03,
            Color3 = COLORS.Accent,
            SurfaceTransparency = 1,
        }, obj)

    selectedCountLabel.Text =
        tostring(
            (function()
                local count = 0
                for _ in pairs(selectedObjects) do
                    count += 1
                end
                return count
            end)()
        ) .. " selecionados"
end

local function selectableObjectsAtPoint(screenPosition)
    local candidates = {}

    for _, descendant in ipairs(PlayerGui:GetDescendants()) do
        if descendant:IsA("GuiObject")
            and descendant.Visible
            and not isSystemGui(descendant)
            and descendant.AbsoluteSize.X > 2
            and descendant.AbsoluteSize.Y > 2 then

            local p = descendant.AbsolutePosition
            local s = descendant.AbsoluteSize

            if screenPosition.X >= p.X
                and screenPosition.X <= p.X + s.X
                and screenPosition.Y >= p.Y
                and screenPosition.Y <= p.Y + s.Y then

                table.insert(
                    candidates,
                    descendant
                )
            end
        end
    end

    table.sort(
        candidates,
        function(a, b)
            return #a:GetFullName()
                > #b:GetFullName()
        end
    )

    return candidates
end

local function applySelectionScale(delta)
    for obj in pairs(selectedObjects) do
        if obj.Parent then
            local scale =
                obj:FindFirstChild(
                    "SamModsEditorScale"
                )

            if not scale then
                scale =
                    make(
                        "UIScale",
                        {
                            Name =
                                "SamModsEditorScale",
                            Scale = 1,
                        },
                        obj
                    )
            end

            scale.Scale =
                math.clamp(
                    scale.Scale + delta,
                    0.35,
                    2
                )
        else
            selectedObjects[obj] = nil
        end
    end
end

local function closeEditor()
    clearSelection()
    editorGui.Enabled = false
    settingsPanel.Visible = configOpen
end

editorButton(
    "−",
    115,
    function()
        applySelectionScale(-0.1)
    end
)

editorButton(
    "+",
    177,
    function()
        applySelectionScale(0.1)
    end
)

editorButton(
    "RESET",
    239,
    function()
        for obj in pairs(selectedObjects) do
            local scale =
                obj:FindFirstChild(
                    "SamModsEditorScale"
                )

            if scale then
                scale.Scale = 1
            end
        end
    end
)

editorButton(
    "FECHAR",
    301,
    closeEditor
)

local draggingSelection = false
local selectionStart = Vector2.zero

local function setSelectionRect(a, b)
    local x1 = math.min(a.X, b.X)
    local y1 = math.min(a.Y, b.Y)
    local x2 = math.max(a.X, b.X)
    local y2 = math.max(a.Y, b.Y)

    selectionBox.Position =
        UDim2.fromOffset(
            x1,
            y1
        )

    selectionBox.Size =
        UDim2.fromOffset(
            x2 - x1,
            y2 - y1
        )
end

local function collectInRect(a, b)
    local x1 = math.min(a.X, b.X)
    local y1 = math.min(a.Y, b.Y)
    local x2 = math.max(a.X, b.X)
    local y2 = math.max(a.Y, b.Y)

    for _, descendant in ipairs(PlayerGui:GetDescendants()) do
        if descendant:IsA("GuiObject")
            and descendant.Visible
            and not isSystemGui(descendant)
            and descendant.AbsoluteSize.X > 3
            and descendant.AbsoluteSize.Y > 3 then

            local p = descendant.AbsolutePosition
            local s = descendant.AbsoluteSize

            local overlap =
                p.X < x2
                and p.X + s.X > x1
                and p.Y < y2
                and p.Y + s.Y > y1

            if overlap then
                markSelected(descendant)
            end
        end
    end
end

selectionArea.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    draggingSelection = true
    selectionStart = input.Position

    local under =
        selectableObjectsAtPoint(
            input.Position
        )

    if #under > 0 then
        clearSelection()
        markSelected(under[1])
    else
        clearSelection()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not draggingSelection then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta =
        input.Position - selectionStart

    if delta.Magnitude > 8 then
        selectionBox.Visible = true
        setSelectionRect(
            selectionStart,
            input.Position
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not draggingSelection then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    draggingSelection = false

    if selectionBox.Visible then
        collectInRect(
            selectionStart,
            input.Position
        )

        selectionBox.Visible = false
    end
end)

-- ============================================================
-- AÇÕES DO PAINEL
-- ============================================================

local function openSettings()
    configOpen = not configOpen

    if modoDiscreto then
        configOpen = false
    end

    settingsPanel.Visible = configOpen

    if configOpen then
        statsWindow.Visible = false

        -- Reinicia em Configuração no topo.
        panelContent.CanvasPosition =
            Vector2.new(0, 0)
    end
end

settingsBubble.MouseButton1Click:Connect(openSettings)

closeButton.MouseButton1Click:Connect(function()
    configOpen = false
    settingsPanel.Visible = false
end)

interfaceButton.MouseButton1Click:Connect(function()
    configOpen = false
    settingsPanel.Visible = false
    editorGui.Enabled = true
end)

statsButton.MouseButton1Click:Connect(function()
    settingsPanel.Visible = false
    configOpen = false
    statsWindow.Visible = true
    refreshRobberyLog()
end)

statsClose.MouseButton1Click:Connect(function()
    statsWindow.Visible = false
end)

-- ============================================================
-- MODO DISCRETO
-- ============================================================

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    if input.KeyCode == Enum.KeyCode.F1 then
        modoDiscreto = not modoDiscreto

        settingsPanel.Visible = false
        statsWindow.Visible = false
        configOpen = false

        gui.Enabled = not modoDiscreto
        notifyGui.Enabled = not modoDiscreto
    end

    if input.KeyCode == Enum.KeyCode.F2 then
        if not modoDiscreto then
            openSettings()
        end
    end

    if input.KeyCode == Enum.KeyCode.F3 then
        S.somAlerta = not S.somAlerta
        if not S.somAlerta then
            AlertSound:Stop()
        elseif alertaAtivo then
            playSound(AlertSound)
        end
    end

    if input.KeyCode == Enum.KeyCode.F4 then
        -- Continua existindo como atalho do sistema antigo.
        -- A mensagem manual NÃO ganhou botão.
        local now = os.clock()

        if now - lastChatMessageAt >= CONFIG.ChatCooldown then
            lastChatMessageAt = now
            sendChat(CONFIG.MaxMessage)
        end
    end

    if input.KeyCode == Enum.KeyCode.F5 then
        if currentThief then
            local mine = getRoot(LocalPlayer)
            local target = getRoot(currentThief)

            if mine and target then
                pcall(function()
                    mine.CFrame =
                        target.CFrame
                        * CFrame.new(0, 0, 4)
                end)
            end
        end
    end

    if input.KeyCode == Enum.KeyCode.F6 then
        S.autoDefender = not S.autoDefender
        enabled = S.autoDefender

        if enabled
            and robberyActive
            and currentThief then

            startDefenseLoop()

        elseif not enabled then

            releaseFromThief()
            unequipBat()
        end
    end
end)

-- ============================================================
-- ATUALIZAÇÃO DE DISPLAY
-- ============================================================

local metaTokensTriggered = false
local metaValueTriggered = false

local function updateStats(tokens, value)
    local elapsed =
        math.max(
            1,
            os.clock() - stats.inicioSessao
        )

    local minutes =
        math.max(
            1 / 60,
            elapsed / 60
        )

    local initial =
        stats.tokensIniciais
        or tokens

    local gain =
        tokens - initial

    statsLabels.time.Text =
        ("%02d:%02d"):format(
            math.floor(elapsed / 60),
            math.floor(elapsed % 60)
        )

    statsLabels.tokens.Text =
        formatNumber(tokens)

    statsLabels.gain.Text =
        (gain >= 0 and "+" or "")
        .. formatNumber(gain)

    statsLabels.perMin.Text =
        formatNumber(
            gain / minutes
        )

    statsLabels.value.Text =
        "$"
        .. formatNumber(value)

    statsLabels.maxPrice.Text =
        "$"
        .. tostring(stats.maiorPreco)

    statsLabels.maxTimes.Text =
        tostring(
            stats.vezesNoMaximo
        )

    statsLabels.robberies.Text =
        tostring(
            stats.roubosSofridos
        )
end

local function checkGoals(tokens, value)
    if CONFIG.MetaTokens > 0 then
        if tokens >= CONFIG.MetaTokens
            and not metaTokensTriggered then

            metaTokensTriggered = true

            notify({
                title = "🎯 Meta de tokens",
                text = "Você chegou a "
                    .. formatNumber(tokens)
                    .. " tokens.",
                color = COLORS.Good,
                duration = 5,
            })

        elseif tokens < CONFIG.MetaTokens then
            metaTokensTriggered = false
        end
    end

    if CONFIG.MetaValor > 0 then
        if value >= CONFIG.MetaValor
            and not metaValueTriggered then

            metaValueTriggered = true

            notify({
                title = "🎯 Meta de valor",
                text =
                    "Valor atual: $"
                    .. formatNumber(value),
                color = COLORS.Good,
                duration = 5,
            })

        elseif value < CONFIG.MetaValor then
            metaValueTriggered = false
        end
    end
end

local function updateShop()
    local rawPrice =
        tonumber(
            Workspace:GetAttribute("TokenPrice")
        )
        or CONFIG.BasePrice

    local price =
        math.floor(
            rawPrice
        )

    local tokens =
        readTokens()

    local value =
        tokens
        * rawPrice

    if stats.tokensIniciais == nil
        and tokens > 0 then

        stats.tokensIniciais = tokens
    end

    stats.tokensAtuais = tokens
    stats.maiorPreco =
        math.max(
            stats.maiorPreco,
            price
        )

    storePrice.Text =
        "$"
        .. tostring(price)

    storeEarnings.Text =
        "Tokens: "
        .. formatNumber(tokens)
        .. "  •  Receber: $"
        .. formatNumber(value)

    local now =
        os.time()

    local left =
        CONFIG.EpochSeconds
        - (now % CONFIG.EpochSeconds)

    storeTimer.Text =
        "Troca em "
        .. tostring(left)
        .. "s"

    if price >= CONFIG.PriceMax then

        if not shopMaxActive then
            startMaxEffect()
        end

        storeStatus.Text =
            "⚡ MÁXIMO"

    elseif price >= CONFIG.PriceSpike then

        if shopMaxActive then
            stopMaxEffect()
        end

        storeStatus.Text =
            "🔥 ALTO"

        storePrice.TextColor3 =
            COLORS.Orange

        storeStatus.TextColor3 =
            COLORS.Orange

    elseif price <= CONFIG.PriceMin then

        if shopMaxActive then
            stopMaxEffect()
        end

        storeStatus.Text =
            "📉 MÍNIMO"

        storePrice.TextColor3 =
            COLORS.Green

        storeStatus.TextColor3 =
            COLORS.Green

    else

        if shopMaxActive then
            stopMaxEffect()
        end

        storeStatus.Text =
            "NORMAL"

        storePrice.TextColor3 =
            COLORS.Accent

        storeStatus.TextColor3 =
            COLORS.Muted
    end

    if S.efeitosMaximo
        and shopMaxActive then

        local c =
            Rainbow.color()

        storePrice.TextColor3 =
            c

        storeStatus.TextColor3 =
            c

        storeIcon.TextColor3 =
            c
    end

    if lastPrice ~= nil
        and lastPrice ~= price then

        tween(
            storePrice,
            {
                TextSize = 19
            },
            0.1,
            Enum.EasingStyle.Back
        ).Completed:Connect(function()

            tween(
                storePrice,
                {
                    TextSize = 17
                },
                0.15
            )
        end)
    end

    lastPrice = price

    checkGoals(tokens, value)
    updateStats(tokens, value)
end

-- ============================================================
-- LOOP
-- ============================================================

RunService.Heartbeat:Connect(function()
    if modoDiscreto then
        storeWidget.Visible = false
        settingsBubble.Visible = false
        setaLadrao.Visible = false
    else
        storeWidget.Visible = S.lojaVisivel
        settingsBubble.Visible = true

        updateThiefArrow()
    end
end)

LocalPlayer:GetAttributeChangedSignal("Tokens"):Connect(
    updateShop
)

Workspace:GetAttributeChangedSignal("TokenPrice"):Connect(
    updateShop
)

task.spawn(function()
    while gui.Parent do
        updateShop()
        task.wait(0.5)
    end
end)

-- ============================================================
-- INICIALIZAÇÃO
-- ============================================================

createLocalTag()
refreshRobberyLog()
updateShop()

print(
    "[SamMods Auto Defender v3] carregado | F6 = Auto Defender | F1 = Discreto | F2 = Config | F3 = Som | F4 = Chat | F5 = Ladrão"
)

-- ============================================================
-- CLEANUP
-- ============================================================

script.Destroying:Connect(function()
    disconnect(followConnection)
    disconnect(defenseThread)

    disconnectList(thiefEspConnections)
    disconnectList(tagConnections)
    disconnectList(maxConnections)

    pcall(function()
        AlertSound:Stop()
        NotifySound:Stop()
    end)

    if instanceMarker and instanceMarker.Parent then
        instanceMarker:Destroy()
    end
end)
