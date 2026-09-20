--[[
    ═══════════════════════════════════════════════════════════════
        SAMMODS · QUALITY OF LIFE HUB · v5
        Tudo em um script só · Feito com carinho
        by SamMods
    ═══════════════════════════════════════════════════════════════
]]

--═══════════ CONFIGURAÇÃO ═══════════
local CONFIG = {
    Nome     = "SamMods Hub",
    Versao   = "v5",
    Autor    = "SamMods",
    Pasta    = "SamModsHub",
}

--═══════════ SERVIÇOS ═══════════
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Stats            = game:GetService("Stats")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local StarterGui       = game:GetService("StarterGui")
local Lighting         = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

--═══════════ CORES DA MARCA SAMMODS ═══════════
local CORES = {
    Primaria   = Color3.fromRGB(0, 210, 255),   -- Ciano SamMods
    Secundaria = Color3.fromRGB(150, 90, 255),  -- Roxo SamMods
    Destaque   = Color3.fromRGB(255, 90, 200),  -- Rosa SamMods
    Fundo      = Color3.fromRGB(10, 8, 16),
    Texto      = Color3.fromRGB(240, 240, 250),
    TextoFraco = Color3.fromRGB(160, 165, 185),
}

--════════════════════════════════��══════════════════════════════
--  SPLASH SCREEN SAMMODS
--═══════════════════════════════════════════════════════════════
local Splash = {}

do
    local ACCENT  = CORES.Primaria
    local ACCENT2 = CORES.Secundaria
    local ACCENT3 = CORES.Destaque

    -- Destroi splash antigo se existir
    pcall(function()
        local parent = (gethui and gethui()) or game:GetService("CoreGui")
        local old = parent:FindFirstChild("SamMods_Splash")
        if old then old:Destroy() end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name           = "SamMods_Splash"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder   = 10000
    gui.ResetOnSpawn   = false

    if not pcall(function()
        gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end) then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Fundo escuro com gradiente
    local back = Instance.new("Frame")
    back.Size                   = UDim2.fromScale(1, 1)
    back.BackgroundColor3       = CORES.Fundo
    back.BackgroundTransparency = 1
    back.BorderSizePixel        = 0
    back.Parent                 = gui

    local vignette = Instance.new("UIGradient")
    vignette.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(16, 10, 30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 6, 14)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(14, 10, 26)),
    })
    vignette.Rotation = 25
    vignette.Parent   = back

    -- Container central
    local center = Instance.new("Frame")
    center.AnchorPoint            = Vector2.new(0.5, 0.5)
    center.Position               = UDim2.fromScale(0.5, 0.5)
    center.Size                   = UDim2.fromOffset(560, 320)
    center.BackgroundTransparency = 1
    center.Parent                 = back

    -- Círculo de brilho atrás do título
    local glowCircle = Instance.new("Frame")
    glowCircle.AnchorPoint            = Vector2.new(0.5, 0.5)
    glowCircle.Position               = UDim2.new(0.5, 0, 0, 60)
    glowCircle.Size                   = UDim2.fromOffset(400, 140)
    glowCircle.BackgroundColor3       = ACCENT
    glowCircle.BackgroundTransparency = 0.85
    glowCircle.BorderSizePixel        = 0
    glowCircle.ZIndex                 = 0
    glowCircle.Parent                 = center
    local gcc = Instance.new("UICorner")
    gcc.CornerRadius = UDim.new(1, 0)
    gcc.Parent = glowCircle
    local gcg = Instance.new("UIGradient")
    gcg.Color = ColorSequence.new(ACCENT, ACCENT2)
    gcg.Rotation = 45
    gcg.Parent = glowCircle

    -- Título SAMMODS
    local titulo = Instance.new("TextLabel")
    titulo.AnchorPoint            = Vector2.new(0.5, 0.5)
    titulo.Position               = UDim2.new(0.5, 0, 0, 52)
    titulo.Size                   = UDim2.new(1, 0, 0, 62)
    titulo.BackgroundTransparency = 1
    titulo.Font                   = Enum.Font.GothamBlack
    titulo.TextSize               = 54
    titulo.Text                   = "SAMMODS"
    titulo.TextColor3             = CORES.Texto
    titulo.TextTransparency       = 1
    titulo.ZIndex                 = 1
    titulo.Parent                 = center

    local tituloGrad = Instance.new("UIGradient")
    tituloGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   ACCENT),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1,   ACCENT2),
    })
    tituloGrad.Parent = titulo

    -- Sombra do título
    local tituloSombra = Instance.new("TextLabel")
    tituloSombra.AnchorPoint            = Vector2.new(0.5, 0.5)
    tituloSombra.Position               = UDim2.new(0.5, 0, 0, 54)
    tituloSombra.Size                   = UDim2.new(1, 0, 0, 62)
    tituloSombra.BackgroundTransparency = 1
    tituloSombra.Font                   = Enum.Font.GothamBlack
    tituloSombra.TextSize               = 54
    tituloSombra.Text                   = "SAMMODS"
    tituloSombra.TextColor3             = ACCENT2
    tituloSombra.TextTransparency       = 1
    tituloSombra.ZIndex                 = 0
    tituloSombra.Parent                 = center

    -- Subtítulo: QUALITY OF LIFE
    local sub = Instance.new("TextLabel")
    sub.AnchorPoint            = Vector2.new(0.5, 0.5)
    sub.Position               = UDim2.new(0.5, 0, 0, 98)
    sub.Size                   = UDim2.new(1, 0, 0, 22)
    sub.BackgroundTransparency = 1
    sub.Font                   = Enum.Font.GothamBold
    sub.TextSize               = 15
    sub.Text                   = "Q U A L I T Y   O F   L I F E"
    sub.TextColor3             = ACCENT
    sub.TextTransparency       = 1
    sub.Parent                 = center

    -- Badge de versão
    local versao = Instance.new("TextLabel")
    versao.AnchorPoint            = Vector2.new(0.5, 0.5)
    versao.Position               = UDim2.new(0.5, 0, 0, 122)
    versao.Size                   = UDim2.fromOffset(80, 18)
    versao.BackgroundColor3       = ACCENT2
    versao.BackgroundTransparency = 1
    versao.Font                   = Enum.Font.GothamBold
    versao.TextSize               = 11
    versao.Text                   = "v5 · HUB"
    versao.TextColor3             = Color3.fromRGB(255, 255, 255)
    versao.TextTransparency       = 1
    versao.Parent                 = center
    local vc = Instance.new("UICorner")
    vc.CornerRadius = UDim.new(1, 0)
    vc.Parent = versao

    -- Linhas decorativas
    local function linha(xScale, anchor)
        local l = Instance.new("Frame")
        l.AnchorPoint            = anchor
        l.Position               = UDim2.new(xScale, 0, 0, 98)
        l.Size                   = UDim2.fromOffset(140, 1)
        l.BackgroundColor3       = ACCENT
        l.BackgroundTransparency = 1
        l.BorderSizePixel        = 0
        l.Parent                 = center
        return l
    end
    local linhaEsq = linha(0.06, Vector2.new(0, 0.5))
    local linhaDir = linha(0.94, Vector2.new(1, 0.5))

    -- Spinner de pontos orbitando
    local spinner = Instance.new("Frame")
    spinner.AnchorPoint            = Vector2.new(0.5, 0.5)
    spinner.Position               = UDim2.new(0.5, 0, 0, 172)
    spinner.Size                   = UDim2.fromOffset(50, 50)
    spinner.BackgroundTransparency = 1
    spinner.Parent                 = center

    local pontosSpin = {}
    for i = 1, 10 do
        local d = Instance.new("Frame")
        d.AnchorPoint            = Vector2.new(0.5, 0.5)
        d.Size                   = UDim2.fromOffset(6, 6)
        d.BackgroundColor3       = i % 2 == 0 and ACCENT or ACCENT2
        d.BackgroundTransparency = 1
        d.BorderSizePixel        = 0
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = d
        d.Parent = spinner
        pontosSpin[i] = d
    end

    -- Barra de progresso
    local barraFundo = Instance.new("Frame")
    barraFundo.AnchorPoint            = Vector2.new(0.5, 0.5)
    barraFundo.Position               = UDim2.new(0.5, 0, 0, 226)
    barraFundo.Size                   = UDim2.fromOffset(400, 8)
    barraFundo.BackgroundColor3       = Color3.fromRGB(28, 24, 40)
    barraFundo.BackgroundTransparency = 1
    barraFundo.BorderSizePixel        = 0
    barraFundo.Parent                 = center
    local bfc = Instance.new("UICorner")
    bfc.CornerRadius = UDim.new(1, 0)
    bfc.Parent = barraFundo

    local barraFill = Instance.new("Frame")
    barraFill.Size                   = UDim2.new(0, 0, 1, 0)
    barraFill.BackgroundColor3       = ACCENT
    barraFill.BackgroundTransparency = 1
    barraFill.BorderSizePixel        = 0
    barraFill.Parent                 = barraFundo
    local bfCorner = Instance.new("UICorner")
    bfCorner.CornerRadius = UDim.new(1, 0)
    bfCorner.Parent = barraFill
    local bfGrad = Instance.new("UIGradient")
    bfGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   ACCENT),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1,   ACCENT2),
    })
    bfGrad.Parent = barraFill

    -- Brilho em baixo da barra
    local brilhoBarra = Instance.new("Frame")
    brilhoBarra.AnchorPoint            = Vector2.new(0.5, 0.5)
    brilhoBarra.Position               = UDim2.new(0.5, 0, 0, 226)
    brilhoBarra.Size                   = UDim2.fromOffset(400, 22)
    brilhoBarra.BackgroundColor3       = ACCENT
    brilhoBarra.BackgroundTransparency = 1
    brilhoBarra.BorderSizePixel        = 0
    brilhoBarra.ZIndex                 = 0
    brilhoBarra.Parent                 = center
    local brc = Instance.new("UICorner")
    brc.CornerRadius = UDim.new(1, 0)
    brc.Parent = brilhoBarra

    -- Status + porcentagem
    local status = Instance.new("TextLabel")
    status.AnchorPoint            = Vector2.new(0.5, 0.5)
    status.Position               = UDim2.new(0.5, 0, 0, 258)
    status.Size                   = UDim2.new(1, 0, 0, 20)
    status.BackgroundTransparency = 1
    status.Font                   = Enum.Font.Gotham
    status.TextSize               = 14
    status.Text                   = "Iniciando..."
    status.TextColor3             = CORES.TextoFraco
    status.TextTransparency       = 1
    status.Parent                 = center

    local porcento = Instance.new("TextLabel")
    porcento.AnchorPoint            = Vector2.new(1, 0.5)
    porcento.Position               = UDim2.new(0.5, 200, 0, 208)
    porcento.Size                   = UDim2.fromOffset(60, 16)
    porcento.BackgroundTransparency = 1
    porcento.Font                   = Enum.Font.GothamBold
    porcento.TextSize               = 12
    porcento.TextXAlignment         = Enum.TextXAlignment.Right
    porcento.Text                   = "0%"
    porcento.TextColor3             = ACCENT
    porcento.TextTransparency       = 1
    porcento.Parent                 = center

    -- Rodapé
    local rodape = Instance.new("TextLabel")
    rodape.AnchorPoint            = Vector2.new(0.5, 1)
    rodape.Position               = UDim2.new(0.5, 0, 1, -20)
    rodape.Size                   = UDim2.new(1, 0, 0, 16)
    rodape.BackgroundTransparency = 1
    rodape.Font                   = Enum.Font.Gotham
    rodape.TextSize               = 12
    rodape.Text                   = "SamMods  ·  v5  ·  Quality of Life Hub"
    rodape.TextColor3             = Color3.fromRGB(110, 115, 135)
    rodape.TextTransparency       = 1
    rodape.Parent                 = back

    -- Estado
    local vivo = true
    local progressoAlvo = 0
    local progressoAtual = 0

    -- Loop principal de animação
    task.spawn(function()
        local t = 0
        while vivo do
            local dt = task.wait()
            t += dt

            -- Spinner
            for i, d in ipairs(pontosSpin) do
                local ang = t * 4 + (i / #pontosSpin) * math.pi * 2
                d.Position = UDim2.new(0.5, math.cos(ang) * 20, 0.5, math.sin(ang) * 20)
                local fase = (math.sin(t * 6 - i * 0.7) + 1) / 2
                d.BackgroundTransparency = 0.1 + fase * 0.6
            end

            -- Progresso suave
            progressoAtual += (progressoAlvo - progressoAtual) * math.min(dt * 6, 1)
            barraFill.Size = UDim2.new(progressoAtual, 0, 1, 0)
            porcento.Text = math.floor(progressoAtual * 100 + 0.5) .. "%"

            -- Shimmer no gradiente do título
            tituloGrad.Offset = Vector2.new((t * 0.25) % 2 - 1, 0)

            -- Pulso do brilho
            brilhoBarra.BackgroundTransparency = 0.9 + math.sin(t * 3) * 0.05
            glowCircle.BackgroundTransparency  = 0.85 + math.sin(t * 2) * 0.05
        end
    end)

    -- Partículas flutuantes
    task.spawn(function()
        local rng = Random.new()
        while vivo do
            task.wait(rng:NextNumber(0.15, 0.35))
            if not vivo then break end
            pcall(function()
                local p = Instance.new("Frame")
                local size = rng:NextInteger(2, 5)
                p.Size                   = UDim2.fromOffset(size, size)
                p.Position               = UDim2.new(rng:NextNumber(), 0, 1.05, 0)
                p.BackgroundColor3       = rng:NextNumber() > 0.5 and ACCENT or ACCENT2
                p.BackgroundTransparency = 0.55
                p.BorderSizePixel        = 0
                p.ZIndex                 = 0
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = p
                p.Parent = back
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

    -- Fade in
    local FADE = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(back, FADE, { BackgroundTransparency = 0.06 }):Play()
    for _, obj in ipairs({ titulo, tituloSombra, sub, status, porcento, rodape }) do
        TweenService:Create(obj, FADE, { TextTransparency = (obj == tituloSombra) and 0.7 or 0 }):Play()
    end
    TweenService:Create(barraFundo, FADE, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(barraFill,  FADE, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(linhaEsq,   FADE, { BackgroundTransparency = 0.5 }):Play()
    TweenService:Create(linhaDir,   FADE, { BackgroundTransparency = 0.5 }):Play()
    TweenService:Create(versao,     FADE, { BackgroundTransparency = 0.3 }):Play()

    -- API pública
    function Splash.Set(progresso, texto)
        progressoAlvo = math.clamp(progresso, 0, 1)
        if texto then status.Text = texto end
    end

    function Splash.Fechar()
        if not vivo then return end
        vivo = false
        local OUT = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(back, OUT, { BackgroundTransparency = 1 }):Play()
        for _, obj in ipairs({ titulo, tituloSombra, sub, status, porcento, rodape }) do
            TweenService:Create(obj, OUT, { TextTransparency = 1 }):Play()
        end
        TweenService:Create(barraFundo, OUT, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(barraFill, OUT, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(linhaEsq,  OUT, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(linhaDir,  OUT, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(versao,    OUT, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(glowCircle, OUT, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(brilhoBarra, OUT, { BackgroundTransparency = 1 }):Play()
        for _, d in ipairs(pontosSpin) do
            TweenService:Create(d, OUT, { BackgroundTransparency = 1 }):Play()
        end
        task.delay(0.7, function() gui:Destroy() end)
    end
end

--═══════════ NOTIFICAÇÃO ═══════════
local function Aviso(texto, duracao)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = CONFIG.Nome,
            Text     = texto,
            Duration = duracao or 5,
        })
    end)
    print("[" .. CONFIG.Nome .. "] " .. texto)
end

--═══════════════════════════════════════════════════════════════
--  HELPERS
--═══════════════════════════════════════════════════════════════

local Running        = true
local StartTime      = os.time()
local FPS, Ping      = 0, 0
local NotifyJoins    = true
local OverlayEnabled = true
local CleanScreen    = false
local AutoRejoin     = false
local ShowSpeed      = false
local AfkConnection  = nil
local AfkCount       = 0
local DefaultFOV     = Camera and Camera.FieldOfView or 70
local JoinLog        = {}
local NamesHidden    = false

local Move = {
    WalkSpeedOn = false, WalkSpeed = 16,
    JumpOn      = false, JumpValue = 50,
    InfJump     = false,
    Fly         = false, FlySpeed  = 60,
    Noclip      = false,
    AutoJump    = false,
    Spin        = false, SpinSpeed = 5,
    Freeze      = false,
    ClickTP     = false,
    AntiVoid    = false,
    LastSafePos = nil,
}

local Esp = { Names = false, Highlight = false }
local DefaultGravity  = workspace.Gravity
local OriginalLighting = {
    Brightness    = Lighting.Brightness,
    ClockTime     = Lighting.ClockTime,
    FogEnd        = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient       = Lighting.Ambient,
}

local Waypoints = {}
local Connections = {}
local function Track(conn)
    table.insert(Connections, conn)
    return conn
end

local function HttpFetch(url)
    local req = (syn and syn.request) or request or http_request
    if req then
        local ok, res = pcall(req, { Url = url, Method = "GET" })
        if ok and res and (res.StatusCode == 200 or res.Success) then
            return res.Body
        end
    end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    return ok and body or nil
end

local function FetchJson(url)
    local body = HttpFetch(url)
    if not body then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    return ok and data or nil
end

local function GetChar() return LocalPlayer.Character end
local function GetHum()
    local char = GetChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function GetHRP()
    local char = GetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Loop de FPS
do
    local frames, elapsed = 0, 0
    Track(RunService.RenderStepped:Connect(function(dt)
        frames  += 1
        elapsed += dt
        if elapsed >= 0.5 then
            FPS = math.floor(frames / elapsed + 0.5)
            frames, elapsed = 0, 0
        end
    end))
end

local function GetPing()
    local ok, item = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]
    end)
    if not ok or not item then return 0 end
    local okV, value = pcall(function() return item:GetValue() end)
    if okV and tonumber(value) then
        return math.floor(value + 0.5)
    end
    okV, value = pcall(function()
        return tonumber(item:GetValueString():gsub(",", "."):match("[%d%.]+"))
    end)
    return (okV and tonumber(value)) and math.floor(value + 0.5) or 0
end

local function GetSpeed()
    local root = GetHRP()
    if not root then return 0 end
    local v = root.AssemblyLinearVelocity
    return math.floor(Vector3.new(v.X, 0, v.Z).Magnitude + 0.5)
end

local function FormatTime(sec)
    sec = math.floor(sec)
    return string.format("%02d:%02d:%02d", sec // 3600, (sec % 3600) // 60, sec % 60)
end

local function Clipboard(text)
    local write = setclipboard or toclipboard or (syn and syn.write_clipboard)
    if write then
        pcall(write, text)
        return true
    end
    return false
end

local WindUI
local function Notify(title, content, icon, duration)
    if WindUI then
        WindUI:Notify({
            Title    = title,
            Content  = content,
            Icon     = icon or "info",
            Duration = duration or 3,
        })
    else
        Aviso(title .. ": " .. content, duration)
    end
end

local function CopyWithToast(text, label)
    if Clipboard(text) then
        Notify("Copiado", label, "copy", 2)
    else
        Notify("Erro", "Área de transferência indisponível", "circle-alert", 3)
    end
end

--═══════════ HISTÓRICO ═══════════
local HISTORY_FILE = "SamModsHub/history.json"
local History = {}

local function LoadHistory()
    pcall(function()
        if isfile and isfile(HISTORY_FILE) then
            local data = HttpService:JSONDecode(readfile(HISTORY_FILE))
            if type(data) == "table" then History = data end
        end
    end)
end

local function SaveHistory()
    pcall(function()
        if writefile then
            if makefolder and not (isfolder and isfolder("SamModsHub")) then
                makefolder("SamModsHub")
            end
            writefile(HISTORY_FILE, HttpService:JSONEncode(History))
        end
    end)
end

local function PushHistory()
    if game.JobId == "" then return end
    table.insert(History, 1, {
        jobId   = game.JobId,
        placeId = game.PlaceId,
        time    = os.time(),
    })
    while #History > 10 do table.remove(History) end
    SaveHistory()
end

LoadHistory()

--═══════════ OVERLAY (FPS/PING) ═══════════
pcall(function()
    local parent = (gethui and gethui()) or game:GetService("CoreGui")
    local old = parent:FindFirstChild("SamMods_Overlay")
    if old then old:Destroy() end
end)

local Overlay = Instance.new("ScreenGui")
Overlay.Name           = "SamMods_Overlay"
Overlay.ResetOnSpawn   = false
Overlay.IgnoreGuiInset = true
Overlay.DisplayOrder   = 999

local Box = Instance.new("Frame")
Box.AnchorPoint            = Vector2.new(0.5, 0)
Box.Position               = UDim2.new(0.5, 0, 0, 6)
Box.Size                   = UDim2.fromOffset(250, 28)
Box.BackgroundColor3       = Color3.fromRGB(12, 10, 20)
Box.BackgroundTransparency = 0.2
Box.BorderSizePixel        = 0
Box.Parent                 = Overlay

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent       = Box

local Stroke = Instance.new("UIStroke")
Stroke.Color        = CORES.Primaria
Stroke.Transparency = 0.6
Stroke.Thickness    = 1
Stroke.Parent       = Box

local Label = Instance.new("TextLabel")
Label.BackgroundTransparency = 1
Label.Size       = UDim2.fromScale(1, 1)
Label.Font       = Enum.Font.GothamBold
Label.TextSize   = 13
Label.TextColor3 = CORES.Texto
Label.Text       = "FPS --  ·  PING --"
Label.Parent     = Box

if not pcall(function()
    Overlay.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end) then
    Overlay.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function SyncOverlay()
    Box.Visible = OverlayEnabled and not CleanScreen
end

--═══════════ MIRA CUSTOMIZADA ═══════════
pcall(function()
    local parent = (gethui and gethui()) or game:GetService("CoreGui")
    local old = parent:FindFirstChild("SamMods_Cross")
    if old then old:Destroy() end
end)

local Cross = Instance.new("ScreenGui")
Cross.Name           = "SamMods_Cross"
Cross.ResetOnSpawn   = false
Cross.IgnoreGuiInset = true
Cross.DisplayOrder   = 998
Cross.Enabled        = false
pcall(function()
    Cross.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not Cross.Parent then Cross.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local CrossColor = Color3.fromRGB(255, 255, 255)
local CrossSize  = 8
local CrossStyle = "Cruz"
local CrossParts = {}

local function RebuildCrosshair()
    for _, p in ipairs(CrossParts) do p:Destroy() end
    table.clear(CrossParts)
    local function part(w, h, dx, dy)
        local f = Instance.new("Frame")
        f.AnchorPoint      = Vector2.new(0.5, 0.5)
        f.Position         = UDim2.new(0.5, dx, 0.5, dy)
        f.Size             = UDim2.fromOffset(w, h)
        f.BackgroundColor3 = CrossColor
        f.BorderSizePixel  = 0
        f.Parent           = Cross
        table.insert(CrossParts, f)
        return f
    end
    if CrossStyle == "Ponto" then
        local d = part(CrossSize, CrossSize, 0, 0)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = d
    else
        local gap, len, thick = 4, CrossSize, 2
        part(len, thick, -(gap + len // 2), 0)
        part(len, thick,  (gap + len // 2), 0)
        part(thick, len, 0, -(gap + len // 2))
        part(thick, len, 0,  (gap + len // 2))
    end
end
RebuildCrosshair()

--═══════════ MOVIMENTO ═══════════
local function ApplyMovement()
    local hum = GetHum()
    if not hum then return end
    if Move.WalkSpeedOn then hum.WalkSpeed = Move.WalkSpeed end
    if Move.JumpOn then
        if hum.UseJumpPower then hum.JumpPower = Move.JumpValue
        else hum.JumpHeight = Move.JumpValue end
    end
end

local function ResetMovement()
    local hum = GetHum()
    if hum then
        hum.WalkSpeed = 16
        if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
    end
end

Track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Running then ApplyMovement() end
end))

Track(UserInputService.JumpRequest:Connect(function()
    if Running and Move.InfJump then
        local hum = GetHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

--═══════════ VOO ═══════════
local flyBV, flyGyro
local function StopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
    local hum = GetHum()
    if hum then hum.PlatformStand = false end
end

Track(RunService.RenderStepped:Connect(function()
    if not Running or not Move.Fly then return end
    local hrp, hum = GetHRP(), GetHum()
    if not hrp or not hum then return end
    if not flyBV or flyBV.Parent ~= hrp then
        StopFly()
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
        flyGyro = Instance.new("BodyGyro")
        flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyGyro.P = 9e4
        flyGyro.Parent = hrp
        hum.PlatformStand = true
    end
    local cam = workspace.CurrentCamera
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
    flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * Move.FlySpeed
    flyGyro.CFrame = cam.CFrame
end))

--═══════════ NOCLIP ═══════════
local NoclipParts = {}
local function HookNoclipCache(char)
    table.clear(NoclipParts)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(NoclipParts, part)
        end
    end
    Track(char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then table.insert(NoclipParts, d) end
    end))
end
if GetChar() then HookNoclipCache(GetChar()) end
Track(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    if Running then HookNoclipCache(char) end
end))

Track(RunService.Stepped:Connect(function()
    if not Running or not Move.Noclip then return end
    for _, part in ipairs(NoclipParts) do
        if part.Parent and part.CanCollide then
            part.CanCollide = false
        end
    end
end))

--═══════════ SPIN ═══════════
local spinBAV
local function SetSpin(state)
    Move.Spin = state
    if state then
        local hrp = GetHRP()
        if hrp then
            spinBAV = Instance.new("BodyAngularVelocity")
            spinBAV.MaxTorque = Vector3.new(0, 9e9, 0)
            spinBAV.AngularVelocity = Vector3.new(0, Move.SpinSpeed, 0)
            spinBAV.Parent = hrp
        end
    elseif spinBAV then
        spinBAV:Destroy()
        spinBAV = nil
    end
end

--═══════════ ANTI-VOID ═══════════
task.spawn(function()
    while Running do
        task.wait(1)
        local hrp, hum = GetHRP(), GetHum()
        if hrp and hum and hum.FloorMaterial ~= Enum.Material.Air then
            Move.LastSafePos = hrp.CFrame
        end
    end
end)

Track(RunService.Heartbeat:Connect(function()
    if not Running or not Move.AntiVoid then return end
    local hrp = GetHRP()
    if hrp and hrp.Position.Y < (workspace.FallenPartsDestroyHeight or -500) + 50 then
        if Move.LastSafePos then
            hrp.CFrame = Move.LastSafePos + Vector3.new(0, 5, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end
end))

--═══════════ ESP ═══════════
local EspObjects = {}

local function RemoveEsp(player)
    local obj = EspObjects[player]
    if obj then
        if obj.highlight then pcall(function() obj.highlight:Destroy() end) end
        if obj.billboard then pcall(function() obj.billboard:Destroy() end) end
        EspObjects[player] = nil
    end
end

local function CreateEsp(player)
    if player == LocalPlayer then return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    RemoveEsp(player)
    local obj = {}
    if Esp.Highlight then
        local hl = Instance.new("Highlight")
        hl.FillColor = CORES.Destaque
        hl.OutlineColor = CORES.Primaria
        hl.FillTransparency = 0.6
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = char
        obj.highlight = hl
    end
    if Esp.Names then
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 200, 0, 40)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = hrp
        bb.Parent = hrp
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = CORES.Texto
        label.TextStrokeTransparency = 0.3
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Name = "SamModsESP"
        label.Parent = bb
        obj.billboard = bb
    end
    EspObjects[player] = obj
end

local function RefreshAllEsp()
    for _, p in ipairs(Players:GetPlayers()) do
        if Esp.Names or Esp.Highlight then CreateEsp(p) else RemoveEsp(p) end
    end
end

local function ClearAllEsp()
    for player in pairs(EspObjects) do RemoveEsp(player) end
end

Track(RunService.Heartbeat:Connect(function()
    if not Running or not Esp.Names then return end
    local myHRP = GetHRP()
    if not myHRP then return end
    for player, obj in pairs(EspObjects) do
        if obj.billboard and obj.billboard.Parent then
            local label = obj.billboard:FindFirstChild("SamModsESP")
            local tHRP = obj.billboard.Adornee
            if label and tHRP then
                local dist = math.floor((tHRP.Position - myHRP.Position).Magnitude)
                label.Text = player.DisplayName .. " [" .. dist .. "m]"
            end
        end
    end
end))

local function HookEspRespawn(p)
    Track(p.CharacterAdded:Connect(function()
        task.wait(1)
        if Running and (Esp.Names or Esp.Highlight) then CreateEsp(p) end
    end))
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then HookEspRespawn(p) end
end

--═══════════ SERVIDOR ═══════════
local function Rejoin()
    local ok, err = pcall(function()
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
    if not ok then
        Notify("Erro", tostring(err), "circle-alert", 5)
    end
end

local HopMinPlayers = 0
local function ServerHop()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
        .. "/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"
    local data = FetchJson(url)
    if not data or not data.data then
        Notify("Erro", "Não foi possível buscar servidores", "circle-alert", 4)
        return
    end
    local candidatos = {}
    for _, server in ipairs(data.data) do
        if server.id ~= game.JobId and server.playing and server.maxPlayers
            and server.playing < server.maxPlayers
            and server.playing >= HopMinPlayers then
            table.insert(candidatos, server.id)
        end
    end
    if #candidatos == 0 then
        Notify("Vazio", "Nenhum servidor encontrado com esse filtro", "circle-alert", 4)
        return
    end
    PushHistory()
    Notify("Trocando", "Indo pra outro servidor...", "shuffle", 3)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, candidatos[math.random(1, #candidatos)], LocalPlayer)
end

local function ReturnToPrevious()
    local prev = History[1]
    if not prev then
        Notify("Histórico", "Nenhum servidor anterior registrado", "circle-alert", 3)
        return
    end
    if prev.jobId == game.JobId then
        table.remove(History, 1)
        prev = History[1]
        if not prev then
            Notify("Histórico", "Nenhum servidor anterior registrado", "circle-alert", 3)
            return
        end
    end
    Notify("Histórico", "Voltando pro servidor anterior...", "undo-2", 3)
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(prev.placeId, prev.jobId, LocalPlayer)
    end)
    if not ok then
        Notify("Erro", "Esse servidor provavelmente já caiu", "circle-alert", 4)
    end
end

local function Respawn()
    local char = GetChar()
    if not char then
        Notify("Sem personagem", "Espera o respawn", "circle-alert", 3)
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = 0
    else
        pcall(function() char:BreakJoints() end)
    end
end

local function SetNamesHidden(state)
    NamesHidden = state
    for _, plr in ipairs(Players:GetPlayers()) do
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum.DisplayDistanceType = state
                    and Enum.HumanoidDisplayDistanceType.None
                    or Enum.HumanoidDisplayDistanceType.Viewer
            end)
        end
    end
end

--═══════════════════════════════════════════════════════════════
--  CARREGA WINDUI
--═══════════════════════════════════════════════════════════════

Splash.Set(0.2, "Carregando interface...")

if _G.SamModsUnload then
    pcall(_G.SamModsUnload)
    task.wait(0.2)
end

local okUI, WindUIModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not okUI or not WindUIModule then
    Splash.Set(1, "Falha ao carregar")
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SamMods Hub",
            Text = "Falha ao carregar WindUI. Verifica sua internet ou executor.",
            Duration = 6,
        })
    end)
    error("SamMods Hub: WindUI falhou — " .. tostring(WindUIModule), 0)
end

WindUI = WindUIModule
Splash.Set(0.5, "Criando painel SamMods...")

--═══════════════════════════════════════════════════════════════
--  CRIA JANELA SAMMODS
--═══════════════════════════════════════════════════════════════

local Window = WindUI:CreateWindow({
    Title        = "SamMods Hub",
    Icon         = "zap",
    Author       = "by SamMods · v5",
    Folder       = "SamModsHub",
    Size         = UDim2.fromOffset(600, 480),
    Theme        = "Dark",
    Transparent  = true,
    SideBarWidth = 170,
    User = {
        Enabled   = true,
        Anonymous = false,
        Callback  = function()
            CopyWithToast(LocalPlayer.Name, "@" .. LocalPlayer.Name)
        end,
    },
})

pcall(function()
    Window:Tag({ Title = "SamMods · v5", Icon = "sparkles", Border = true })
end)

Splash.Set(0.75, "Preparando abas...")

--═══════════ ABAS ═══════════
local AbaPrincipal   = Window:Tab({ Title = "Principal",   Icon = "gauge" })
local AbaJogador     = Window:Tab({ Title = "Jogador",     Icon = "user" })
local AbaTeleporte   = Window:Tab({ Title = "Teleporte",   Icon = "map-pin" })
local AbaESP         = Window:Tab({ Title = "ESP",         Icon = "scan-eye" })
local AbaVisual      = Window:Tab({ Title = "Visual",      Icon = "eye" })
local AbaDesempenho  = Window:Tab({ Title = "Desempenho",  Icon = "cpu" })
local AbaJogadores   = Window:Tab({ Title = "Jogadores",   Icon = "users" })
local AbaInterface   = Window:Tab({ Title = "Interface",   Icon = "layout-dashboard" })
local AbaSobre       = Window:Tab({ Title = "Sobre",       Icon = "info" })

Window:SelectTab(1)

local Config
pcall(function()
    Config = Window.ConfigManager:CreateConfig("sammods_hub")
end)

--═══════════════════════════════════════════════════════════════
--  ABA PRINCIPAL
--═══════════════════════════════════════════════════════════════
AbaPrincipal:Section({ Title = "Estatísticas" })

local Info = AbaPrincipal:Paragraph({
    Title     = "FPS: --   ·   Ping: -- ms",
    Desc      = "Medindo...",
    Image     = "activity",
    ImageSize = 22,
})

AbaPrincipal:Toggle({
    Flag  = "Overlay",
    Title = "Overlay na tela",
    Desc  = "Contador de FPS e ping em cima do jogo",
    Icon  = "monitor",
    Value = true,
    Callback = function(state)
        OverlayEnabled = state
        SyncOverlay()
    end,
})

AbaPrincipal:Toggle({
    Flag  = "SpeedInOverlay",
    Title = "Mostrar velocidade no overlay",
    Desc  = "Velocidade horizontal do personagem (studs/s)",
    Icon  = "gauge",
    Value = false,
    Callback = function(state)
        ShowSpeed = state
        Box.Size = UDim2.fromOffset(state and 320 or 250, 28)
    end,
})

AbaPrincipal:Section({ Title = "Este jogo" })

local GameInfo = AbaPrincipal:Paragraph({
    Title     = "Info do jogo",
    Desc      = "Clica no botão pra carregar",
    Image     = "info",
    ImageSize = 22,
    Buttons   = {
        {
            Title = "Carregar",
            Icon  = "download",
            Callback = function()
                task.spawn(function()
                    local data = FetchJson("https://games.roblox.com/v1/games?universeIds=" .. game.GameId)
                    local g = data and data.data and data.data[1]
                    if not g then
                        Notify("Erro", "Não foi possível carregar", "circle-alert", 3)
                        return
                    end
                    pcall(function()
                        GameInfo:SetTitle(tostring(g.name))
                        GameInfo:SetDesc(string.format(
                            "por %s  ·  jogando: %s  ·  visitas: %s  ·  criado: %s",
                            tostring(g.creator and g.creator.name or "?"),
                            tostring(g.playing or "?"),
                            tostring(g.visits or "?"),
                            tostring(g.created and g.created:sub(1, 10) or "?")
                        ))
                    end)
                end)
            end,
        },
    },
})

AbaPrincipal:Section({ Title = "Servidor" })

AbaPrincipal:Button({
    Title = "Reentrar",
    Desc  = "Reconecta nesse mesmo servidor",
    Icon  = "refresh-cw",
    Callback = function()
        Notify("Reentrar", "Reconectando...", "refresh-cw", 2)
        PushHistory()
        task.wait(0.3)
        Rejoin()
    end,
})

AbaPrincipal:Button({
    Title = "Trocar de servidor",
    Desc  = "Vai pra um servidor diferente aleatório",
    Icon  = "shuffle",
    Callback = ServerHop,
})

AbaPrincipal:Slider({
    Flag  = "HopMinPlayers",
    Title = "Filtro: mínimo de players",
    Desc  = "0 = qualquer servidor, mais alto = servidores mais cheios",
    Step  = 1,
    Value = { Min = 0, Max = 30, Default = 0 },
    Callback = function(value) HopMinPlayers = value end,
})

AbaPrincipal:Button({
    Title = "Voltar pro servidor anterior",
    Desc  = "Volta pro servidor de antes da última troca",
    Icon  = "undo-2",
    Callback = ReturnToPrevious,
})

AbaPrincipal:Toggle({
    Flag  = "AutoRejoin",
    Title = "Reentrar automático ao desconectar",
    Desc  = "Detecta o prompt de desconexão e reconecta",
    Icon  = "plug-zap",
    Value = false,
    Callback = function(state) AutoRejoin = state end,
})

AbaPrincipal:Section({ Title = "Copiar" })

AbaPrincipal:Button({
    Title = "Copiar JobId",
    Icon  = "copy",
    Callback = function() CopyWithToast(game.JobId, "JobId do servidor") end,
})

AbaPrincipal:Button({
    Title = "Copiar PlaceId",
    Icon  = "copy",
    Callback = function() CopyWithToast(tostring(game.PlaceId), "PlaceId") end,
})

AbaPrincipal:Button({
    Title = "Copiar link do jogo",
    Icon  = "link",
    Callback = function()
        CopyWithToast("https://www.roblox.com/games/" .. game.PlaceId, "Link do jogo")
    end,
})

AbaPrincipal:Button({
    Title = "Copiar link de convite",
    Desc  = "Link web pra entrar nesse servidor exato",
    Icon  = "link",
    Callback = function()
        CopyWithToast(
            "https://www.roblox.com/games/start?placeId=" .. game.PlaceId
                .. "&gameInstanceId=" .. game.JobId,
            "Link de convite"
        )
    end,
})

AbaPrincipal:Section({ Title = "Personagem" })

AbaPrincipal:Button({
    Title = "Renascer",
    Desc  = "Mata o personagem (igual botão Reset)",
    Icon  = "skull",
    Callback = Respawn,
})

-- Auto-rejoin listener
task.spawn(function()
    pcall(function()
        local prompt = game:GetService("CoreGui"):WaitForChild("RobloxPromptGui", 10)
        local overlay = prompt and prompt:WaitForChild("promptOverlay", 10)
        if overlay then
            Track(overlay.ChildAdded:Connect(function(child)
                if AutoRejoin and child.Name == "ErrorPrompt" then
                    task.wait(1)
                    Rejoin()
                end
            end))
        end
    end)
end)

--═══════════════════════════════════════════════════════════════
--  ABA JOGADOR (MOVIMENTO)
--═══════════════════════════════════════════════════════════════
AbaJogador:Section({ Title = "Movimento" })

AbaJogador:Toggle({
    Flag  = "WalkSpeedOn",
    Title = "Velocidade",
    Desc  = "Velocidade de caminhada personalizada",
    Icon  = "footprints",
    Value = false,
    Callback = function(state)
        Move.WalkSpeedOn = state
        if state then ApplyMovement() else ResetMovement() ; if Move.JumpOn then ApplyMovement() end end
    end,
})

AbaJogador:Slider({
    Flag  = "WalkSpeed",
    Title = "Velocidade (studs)",
    Step  = 1,
    Value = { Min = 16, Max = 300, Default = 16 },
    Callback = function(value)
        Move.WalkSpeed = value
        if Move.WalkSpeedOn then ApplyMovement() end
    end,
})

AbaJogador:Toggle({
    Flag  = "JumpOn",
    Title = "Pulo (Power/Height)",
    Desc  = "Força de pulo personalizada",
    Icon  = "arrow-up",
    Value = false,
    Callback = function(state)
        Move.JumpOn = state
        if state then ApplyMovement() else ResetMovement() ; if Move.WalkSpeedOn then ApplyMovement() end end
    end,
})

AbaJogador:Slider({
    Flag  = "JumpValue",
    Title = "Força do pulo",
    Step  = 1,
    Value = { Min = 50, Max = 500, Default = 50 },
    Callback = function(value)
        Move.JumpValue = value
        if Move.JumpOn then ApplyMovement() end
    end,
})

AbaJogador:Toggle({
    Flag  = "InfJump",
    Title = "Pulo Infinito",
    Desc  = "Pula de novo mesmo no ar",
    Icon  = "chevrons-up",
    Value = false,
    Callback = function(state) Move.InfJump = state end,
})

AbaJogador:Section({ Title = "Voo" })

AbaJogador:Toggle({
    Flag  = "Fly",
    Title = "Voar (WASD + Espaço/Ctrl)",
    Desc  = "Voo relativo à câmera",
    Icon  = "feather",
    Value = false,
    Callback = function(state)
        Move.Fly = state
        if not state then StopFly() end
    end,
})

AbaJogador:Slider({
    Flag  = "FlySpeed",
    Title = "Velocidade de voo",
    Step  = 5,
    Value = { Min = 10, Max = 300, Default = 60 },
    Callback = function(v) Move.FlySpeed = v end,
})

AbaJogador:Toggle({
    Flag  = "Noclip",
    Title = "Atravessar paredes",
    Desc  = "Passa através de obstáculos",
    Icon  = "ghost",
    Value = false,
    Callback = function(state) Move.Noclip = state end,
})

AbaJogador:Section({ Title = "Extras" })

AbaJogador:Toggle({
    Flag  = "AutoJump",
    Title = "Pulo Automático",
    Desc  = "Pula sozinho a cada meio segundo",
    Icon  = "repeat",
    Value = false,
    Callback = function(state)
        Move.AutoJump = state
        task.spawn(function()
            while Running and Move.AutoJump do
                local hum = GetHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                task.wait(0.5)
            end
        end)
    end,
})

AbaJogador:Toggle({
    Title = "Girar",
    Desc  = "Personagem fica girando",
    Icon  = "rotate-cw",
    Value = false,
    Callback = SetSpin,
})

AbaJogador:Slider({
    Flag  = "SpinSpeed",
    Title = "Velocidade do giro",
    Step  = 1,
    Value = { Min = 1, Max = 50, Default = 5 },
    Callback = function(v)
        Move.SpinSpeed = v
        if spinBAV then spinBAV.AngularVelocity = Vector3.new(0, v, 0) end
    end,
})

AbaJogador:Toggle({
    Title = "Congelar",
    Desc  = "Trava o personagem no lugar",
    Icon  = "snowflake",
    Value = false,
    Callback = function(state)
        Move.Freeze = state
        local hrp = GetHRP()
        if hrp then hrp.Anchored = state end
    end,
})

AbaJogador:Button({
    Title = "Sentar / Levantar",
    Icon  = "armchair",
    Callback = function()
        local hum = GetHum()
        if hum then hum.Sit = not hum.Sit end
    end,
})

AbaJogador:Button({
    Title = "Resetar movimento",
    Desc  = "Restaura velocidade e pulo padrão",
    Icon  = "rotate-ccw",
    Callback = function()
        Move.WalkSpeedOn, Move.JumpOn = false, false
        ResetMovement()
        Notify("SamMods Hub", "Movimento resetado", "check", 2)
    end,
})

--═══════════════════════════════════════════════════════════════
--  ABA TELEPORTE
--═══════════════════════════════════════════════════════════════
AbaTeleporte:Section({ Title = "Para jogadores" })

local selectedPlayer = nil
local function PlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    return names
end

local playerDropdown = AbaTeleporte:Dropdown({
    Title  = "Selecionar jogador",
    Values = PlayerNames(),
    Value  = nil,
    Callback = function(option) selectedPlayer = option end,
})

AbaTeleporte:Button({
    Title = "Atualizar lista",
    Icon  = "refresh-cw",
    Callback = function()
        pcall(function() playerDropdown:Refresh(PlayerNames()) end)
        Notify("SamMods Hub", "Lista atualizada", "refresh-cw", 2)
    end,
})

local function TpToPlayer(name)
    local target = Players:FindFirstChild(name)
    local myHRP = GetHRP()
    if target and target.Character and myHRP then
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if tHRP then
            myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
            return true
        end
    end
    return false
end

AbaTeleporte:Button({
    Title = "TP pro jogador selecionado",
    Icon  = "locate",
    Callback = function()
        if selectedPlayer and TpToPlayer(selectedPlayer) then
            Notify("SamMods Hub", "Teleportado pra " .. selectedPlayer, "check", 2)
        else
            Notify("SamMods Hub", "Jogador não encontrado", "circle-alert", 3)
        end
    end,
})

AbaTeleporte:Button({
    Title = "TP pra um jogador aleatório",
    Icon  = "dices",
    Callback = function()
        local list = PlayerNames()
        if #list > 0 then TpToPlayer(list[math.random(1, #list)]) end
    end,
})

AbaTeleporte:Section({ Title = "Posicionamento" })

AbaTeleporte:Toggle({
    Flag  = "ClickTP",
    Title = "TP por clique",
    Desc  = "Ctrl + clique esquerdo = teleporta pro local",
    Icon  = "mouse-pointer-click",
    Value = false,
    Callback = function(state) Move.ClickTP = state end,
})

local Mouse = LocalPlayer:GetMouse()
Track(Mouse.Button1Down:Connect(function()
    if Running and Move.ClickTP and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local hrp = GetHRP()
        if hrp and Mouse.Hit then
            hrp.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 4, 0))
        end
    end
end))

AbaTeleporte:Button({
    Title = "TP 10 studs pra frente",
    Icon  = "arrow-right",
    Callback = function()
        local hrp = GetHRP()
        if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -10) end
    end,
})

AbaTeleporte:Toggle({
    Flag  = "AntiVoid",
    Title = "Anti-Vazio",
    Desc  = "Te teleporta de volta quando cai no vazio",
    Icon  = "shield",
    Value = false,
    Callback = function(state) Move.AntiVoid = state end,
})

AbaTeleporte:Section({ Title = "Marcadores" })

local waypointName = "spot1"
local selectedWaypoint = nil
local waypointDropdown

AbaTeleporte:Input({
    Title = "Nome do marcador",
    Value = "spot1",
    Placeholder = "Digita um nome...",
    Callback = function(text)
        if text and text ~= "" then waypointName = text end
    end,
})

AbaTeleporte:Button({
    Title = "Salvar marcador",
    Desc  = "Guarda a posição atual",
    Icon  = "bookmark",
    Callback = function()
        local hrp = GetHRP()
        if hrp then
            Waypoints[waypointName] = hrp.CFrame
            local names = {}
            for n in pairs(Waypoints) do table.insert(names, n) end
            table.sort(names)
            pcall(function() waypointDropdown:Refresh(names) end)
            Notify("SamMods Hub", "Salvo: " .. waypointName, "bookmark", 2)
        end
    end,
})

waypointDropdown = AbaTeleporte:Dropdown({
    Title  = "Selecionar marcador",
    Values = {},
    Callback = function(option) selectedWaypoint = option end,
})

AbaTeleporte:Button({
    Title = "TP pro marcador",
    Icon  = "map-pin",
    Callback = function()
        local hrp = GetHRP()
        if hrp and selectedWaypoint and Waypoints[selectedWaypoint] then
            hrp.CFrame = Waypoints[selectedWaypoint]
        end
    end,
})

AbaTeleporte:Button({
    Title = "Apagar todos os marcadores",
    Icon  = "trash-2",
    Callback = function()
        table.clear(Waypoints)
        pcall(function() waypointDropdown:Refresh({}) end)
    end,
})

--═══════════════════════════════════════════════════════════════
--  ABA ESP
--═══════════════════════════════════════════════════════════════
AbaESP:Section({ Title = "Jogadores" })

AbaESP:Toggle({
    Flag  = "EspNames",
    Title = "Nomes + distância",
    Desc  = "Nick e distância em cima da cabeça",
    Icon  = "tag",
    Value = false,
    Callback = function(state)
        Esp.Names = state
        RefreshAllEsp()
    end,
})

AbaESP:Toggle({
    Flag  = "EspHighlight",
    Title = "Destaque",
    Desc  = "Jogadores visíveis através de paredes",
    Icon  = "lightbulb",
    Value = false,
    Callback = function(state)
        Esp.Highlight = state
        RefreshAllEsp()
    end,
})

AbaESP:Button({
    Title = "Atualizar ESP",
    Icon  = "refresh-cw",
    Callback = function()
        RefreshAllEsp()
        Notify("SamMods Hub", "ESP atualizado", "refresh-cw", 2)
    end,
})

--═══════════════════════════════════════════════════════════════
--  ABA VISUAL
--═══════════════════════════════════════════════════════════════
AbaVisual:Section({ Title = "Mira" })

AbaVisual:Toggle({
    Flag  = "Crosshair",
    Title = "Mira personalizada",
    Desc  = "Overlay cosmético no meio da tela",
    Icon  = "crosshair",
    Value = false,
    Callback = function(state) Cross.Enabled = state end,
})

AbaVisual:Dropdown({
    Flag   = "CrossStyle",
    Title  = "Estilo",
    Values = { "Cruz", "Ponto" },
    Value  = "Cruz",
    Callback = function(style)
        CrossStyle = style
        RebuildCrosshair()
    end,
})

AbaVisual:Slider({
    Flag  = "CrossSize",
    Title = "Tamanho",
    Step  = 1,
    Value = { Min = 4, Max = 20, Default = 8 },
    Callback = function(value)
        CrossSize = value
        RebuildCrosshair()
    end,
})

AbaVisual:Dropdown({
    Flag   = "CrossColor",
    Title  = "Cor",
    Values = { "Branco", "Vermelho", "Verde", "Ciano", "Amarelo", "Magenta", "SamMods" },
    Value  = "Branco",
    Callback = function(name)
        CrossColor = ({
            Branco   = Color3.fromRGB(255, 255, 255),
            Vermelho = Color3.fromRGB(255, 70, 70),
            Verde    = Color3.fromRGB(80, 255, 120),
            Ciano    = Color3.fromRGB(80, 220, 255),
            Amarelo  = Color3.fromRGB(255, 230, 80),
            Magenta  = Color3.fromRGB(255, 90, 220),
            SamMods  = CORES.Primaria,
        })[name] or Color3.new(1, 1, 1)
        RebuildCrosshair()
    end,
})

AbaVisual:Section({ Title = "Câmera" })

AbaVisual:Slider({
    Flag  = "FOV",
    Title = "Campo de visão",
    Desc  = "Padrão é 70",
    Step  = 1,
    Value = { Min = 40, Max = 120, Default = math.floor(DefaultFOV) },
    Callback = function(value)
        pcall(function() workspace.CurrentCamera.FieldOfView = value end)
    end,
})

AbaVisual:Button({
    Title = "Resetar FOV",
    Icon  = "rotate-ccw",
    Callback = function()
        pcall(function() workspace.CurrentCamera.FieldOfView = DefaultFOV end)
    end,
})

AbaVisual:Button({
    Title = "Liberar zoom",
    Desc  = "Remove o limite de zoom",
    Icon  = "zoom-out",
    Callback = function()
        LocalPlayer.CameraMaxZoomDistance = math.huge
        Notify("SamMods Hub", "Zoom liberado", "check", 2)
    end,
})

AbaVisual:Section({ Title = "Iluminação e mundo" })

AbaVisual:Toggle({
    Flag  = "Fullbright",
    Title = "Claridade máxima",
    Desc  = "Brilho no máximo, sem escuridão",
    Icon  = "sun",
    Value = false,
    Callback = function(state)
        if state then
            Lighting.Brightness    = 2
            Lighting.ClockTime     = 14
            Lighting.GlobalShadows = false
            Lighting.Ambient       = Color3.fromRGB(178, 178, 178)
        else
            Lighting.Brightness    = OriginalLighting.Brightness
            Lighting.ClockTime     = OriginalLighting.ClockTime
            Lighting.GlobalShadows = OriginalLighting.GlobalShadows
            Lighting.Ambient       = OriginalLighting.Ambient
        end
    end,
})

AbaVisual:Toggle({
    Flag  = "NoFog",
    Title = "Sem neblina",
    Desc  = "Remove a neblina do jogo",
    Icon  = "cloud-off",
    Value = false,
    Callback = function(state)
        Lighting.FogEnd = state and 1e9 or OriginalLighting.FogEnd
    end,
})

AbaVisual:Slider({
    Flag  = "ClockTime",
    Title = "Hora do dia",
    Step  = 1,
    Value = { Min = 0, Max = 24, Default = math.floor(OriginalLighting.ClockTime) },
    Callback = function(v) Lighting.ClockTime = v end,
})

AbaVisual:Slider({
    Flag  = "Gravity",
    Title = "Gravidade",
    Desc  = "Padrão é 196",
    Step  = 5,
    Value = { Min = 0, Max = 350, Default = math.floor(DefaultGravity) },
    Callback = function(v) workspace.Gravity = v end,
})

AbaVisual:Section({ Title = "Modo print" })

AbaVisual:Toggle({
    Flag  = "HideNames",
    Title = "Esconder nomes dos jogadores",
    Desc  = "Esconde as nametags em cima dos personagens",
    Icon  = "venetian-mask",
    Value = false,
    Callback = SetNamesHidden,
})

AbaVisual:Button({
    Title = "Modo print: esconder tudo",
    Desc  = "Esconde UI do Roblox, hub, overlay e nomes por 5 segundos",
    Icon  = "camera",
    Callback = function()
        local namesWere = NamesHidden
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
        pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)
        SetNamesHidden(true)
        Box.Visible = false
        Cross.Enabled = false
        pcall(function() Window:ToggleUI() end)
        task.delay(5, function()
            if not Running then return end
            pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not CleanScreen) end)
            pcall(function() StarterGui:SetCore("TopbarEnabled", not CleanScreen) end)
            SetNamesHidden(namesWere)
            SyncOverlay()
            pcall(function() Window:ToggleUI() end)
            Notify("Modo print", "Voltou ao normal", "camera", 2)
        end)
    end,
})

--═══════════════════════════════════════════════════════════════
--  ABA DESEMPENHO
--═══════════════════════════════════════════════════════════════
AbaDesempenho:Section({ Title = "Presets gráficos" })

local Saved = {}
local SavedCaptured = false

local function CaptureDefaults()
    if SavedCaptured then return end
    SavedCaptured = true
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    pcall(function()
        Saved.Quality       = settings().Rendering.QualityLevel
        Saved.GlobalShadows = Lighting.GlobalShadows
        Saved.FogEnd        = Lighting.FogEnd
        if terrain then
            Saved.WaveSize     = terrain.WaterWaveSize
            Saved.WaveSpeed    = terrain.WaterWaveSpeed
            Saved.Reflectance  = terrain.WaterReflectance
            Saved.Transparency = terrain.WaterTransparency
            Saved.Decoration   = terrain.Decoration
        end
    end)
end

local function ApplyPreset(name)
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    CaptureDefaults()

    if name == "Padrão" then
        pcall(function() settings().Rendering.QualityLevel = Saved.Quality or Enum.QualityLevel.Automatic end)
        pcall(function()
            if Saved.GlobalShadows ~= nil then Lighting.GlobalShadows = Saved.GlobalShadows end
            if Saved.FogEnd then Lighting.FogEnd = Saved.FogEnd end
        end)
        if terrain then
            pcall(function()
                terrain.WaterWaveSize     = Saved.WaveSize or 0.15
                terrain.WaterWaveSpeed    = Saved.WaveSpeed or 10
                terrain.WaterReflectance  = Saved.Reflectance or 1
                terrain.WaterTransparency = Saved.Transparency or 0.3
                if Saved.Decoration ~= nil then terrain.Decoration = Saved.Decoration end
            end)
        end
        Notify("Gráficos", "Padrão restaurado", "check", 2)
        return
    end

    local level = (name == "Muito Baixo") and Enum.QualityLevel.Level01
        or (name == "Baixo") and Enum.QualityLevel.Level03
        or Enum.QualityLevel.Level07
    pcall(function() settings().Rendering.QualityLevel = level end)

    if name == "Muito Baixo" or name == "Baixo" then
        pcall(function()
            Lighting.GlobalShadows = false
            if name == "Muito Baixo" then Lighting.FogEnd = 9e9 end
        end)
        if terrain and name == "Muito Baixo" then
            pcall(function()
                terrain.WaterWaveSize     = 0
                terrain.WaterWaveSpeed    = 0
                terrain.WaterReflectance  = 0
                terrain.WaterTransparency = 0
                terrain.Decoration        = false
            end)
        end
    end

    Notify("Gráficos", name .. " aplicado", "zap", 2)
end

AbaDesempenho:Dropdown({
    Flag   = "GfxPreset",
    Title  = "Preset de qualidade",
    Values = { "Padrão", "Médio", "Baixo", "Muito Baixo" },
    Value  = "Padrão",
    Callback = ApplyPreset,
})

AbaDesempenho:Section({ Title = "Granular" })

AbaDesempenho:Toggle({
    Flag  = "NoParticles",
    Title = "Desativar partículas",
    Desc  = "Desliga emissores, rastros, fumaça, fogo (novos também)",
    Icon  = "sparkles",
    Value = false,
    Callback = function(state)
        local classes = { "ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles" }
        local function isEffect(v)
            for _, c in ipairs(classes) do
                if v:IsA(c) then return true end
            end
            return false
        end
        if state then
            task.spawn(function()
                local n = 0
                for _, v in ipairs(workspace:GetDescendants()) do
                    n += 1
                    if n % 800 == 0 then task.wait() end
                    if isEffect(v) then pcall(function() v.Enabled = false end) end
                end
            end)
            Saved.ParticleConn = Track(workspace.DescendantAdded:Connect(function(v)
                if isEffect(v) then pcall(function() v.Enabled = false end) end
            end))
        else
            if Saved.ParticleConn then
                Saved.ParticleConn:Disconnect()
                Saved.ParticleConn = nil
            end
            Notify("Partículas", "Novos efeitos liberados de novo", "info", 4)
        end
    end,
})

AbaDesempenho:Button({
    Title = "Tirar texturas e efeitos",
    Desc  = "Boost grande, só volta ao rejoin",
    Icon  = "eraser",
    Callback = function()
        Window:Dialog({
            Title   = "Tem certeza?",
            Content = "Todas as texturas, decais e partículas serão removidas até você reentrar no servidor.",
            Buttons = {
                { Title = "Cancelar" },
                {
                    Title   = "Aplicar",
                    Variant = "Primary",
                    Callback = function()
                        task.spawn(function()
                            local char = GetChar()
                            local count = 0
                            for _, v in ipairs(workspace:GetDescendants()) do
                                count += 1
                                if count % 700 == 0 then task.wait() end
                                if char and v:IsDescendantOf(char) then continue end
                                pcall(function()
                                    if v:IsA("BasePart") then
                                        v.Material    = Enum.Material.SmoothPlastic
                                        v.Reflectance = 0
                                        v.CastShadow  = false
                                    elseif v:IsA("Decal") or v:IsA("Texture") then
                                        v.Transparency = 1
                                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail")
                                        or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                                        v.Enabled = false
                                    end
                                end)
                            end
                            Notify("Pronto", "Objetos processados: " .. count, "check", 4)
                        end)
                    end,
                },
            },
        })
    end,
})

AbaDesempenho:Section({ Title = "Limite de FPS" })

AbaDesempenho:Slider({
    Flag  = "FPSCap",
    Title = "Cap de FPS",
    Desc  = "Funciona se teu executor suportar setfpscap",
    Step  = 10,
    Value = { Min = 30, Max = 360, Default = 240 },
    Callback = function(value)
        local cap = setfpscap or set_fps_cap or (syn and syn.set_fps_cap)
        if cap then pcall(cap, value) end
    end,
})

AbaDesempenho:Section({ Title = "Som" })

AbaDesempenho:Slider({
    Flag  = "Volume",
    Title = "Volume geral",
    Step  = 5,
    Value = { Min = 0, Max = 100, Default = 100 },
    Callback = function(value)
        pcall(function()
            game:GetService("UserSettings"):GetService("UserGameSettings").MasterVolume = value / 100
        end)
    end,
})

AbaDesempenho:Section({ Title = "Outros" })

local AfkInfo
AbaDesempenho:Toggle({
    Flag  = "AntiAFK",
    Title = "Anti-AFK",
    Desc  = "Impede o kick por inatividade (20 min)",
    Icon  = "coffee",
    Value = false,
    Callback = function(state)
        if AfkConnection then
            AfkConnection:Disconnect()
            AfkConnection = nil
        end
        if state then
            local ok = pcall(function()
                local VirtualUser = game:GetService("VirtualUser")
                AfkConnection = Track(LocalPlayer.Idled:Connect(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                    AfkCount += 1
                    pcall(function()
                        AfkInfo:SetDesc("Kicks por inatividade evitados: " .. AfkCount)
                    end)
                end))
            end)
            if not ok then
                Notify("Falhou", "VirtualUser indisponível nesse executor", "circle-alert", 4)
            end
        end
    end,
})

AfkInfo = AbaDesempenho:Paragraph({
    Title     = "Estatísticas Anti-AFK",
    Desc      = "Kicks por inatividade evitados: 0",
    Image     = "shield",
    ImageSize = 22,
})

--═══════════════════════════════════════════════════════════════
--  ABA JOGADORES
--═══════════════════════════════════════════════════════════════
local Cards = {}
local RefreshPending = false

local function ClearCards()
    for _, card in ipairs(Cards) do
        pcall(function() card:Destroy() end)
    end
    table.clear(Cards)
end

local function BuildCard(plr)
    local config = {
        Title     = plr.DisplayName .. (plr == LocalPlayer and "  (você)" or ""),
        Desc      = string.format("@%s  ·  UserId: %d  ·  conta com %d dias", plr.Name, plr.UserId, plr.AccountAge),
        Image     = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=48&h=48",
        ImageSize = 36,
        Buttons   = {
            {
                Title = "Nick",
                Icon  = "copy",
                Callback = function() CopyWithToast(plr.Name, "@" .. plr.Name) end,
            },
            {
                Title = "Perfil",
                Icon  = "link",
                Callback = function()
                    CopyWithToast("https://www.roblox.com/users/" .. plr.UserId .. "/profile", "Link do perfil")
                end,
            },
        },
    }
    local ok, card = pcall(function() return AbaJogadores:Paragraph(config) end)
    if not ok or not card then
        config.Image = "user"
        config.ImageSize = 22
        card = AbaJogadores:Paragraph(config)
    end
    return card
end

local function Refresh()
    ClearCards()
    local list = Players:GetPlayers()
    table.sort(list, function(a, b)
        if a == b then return false end
        if a == LocalPlayer then return true end
        if b == LocalPlayer then return false end
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)
    for _, plr in ipairs(list) do
        table.insert(Cards, BuildCard(plr))
    end
end

local function QueueRefresh()
    if RefreshPending then return end
    RefreshPending = true
    task.delay(1, function()
        RefreshPending = false
        if Running then Refresh() end
    end)
end

local function LogEvent(text)
    table.insert(JoinLog, os.date("[%H:%M:%S] ") .. text)
    while #JoinLog > 200 do table.remove(JoinLog, 1) end
end

AbaJogadores:Section({ Title = "Ações" })

AbaJogadores:Button({
    Title = "Atualizar lista",
    Icon  = "refresh-cw",
    Callback = Refresh,
})

AbaJogadores:Toggle({
    Flag  = "JoinNotify",
    Title = "Notificações de entrar/sair",
    Icon  = "bell",
    Value = true,
    Callback = function(state) NotifyJoins = state end,
})

AbaJogadores:Button({
    Title = "Copiar log de entradas/saídas",
    Desc  = "Tudo que aconteceu nessa sessão, com horário",
    Icon  = "clipboard-list",
    Callback = function()
        if #JoinLog == 0 then
            Notify("Log", "Nada aconteceu ainda", "info", 2)
            return
        end
        CopyWithToast(table.concat(JoinLog, "\n"), "Log (" .. #JoinLog .. " eventos)")
    end,
})

AbaJogadores:Section({ Title = "No servidor" })
Refresh()

Track(Players.PlayerAdded:Connect(function(plr)
    LogEvent("+ " .. plr.DisplayName .. " (@" .. plr.Name .. ")")
    if NotifyJoins then
        Notify("Entrou", plr.DisplayName .. " (@" .. plr.Name .. ")", "user-plus", 3)
    end
    if NamesHidden then
        task.delay(1, function()
            if NamesHidden then SetNamesHidden(true) end
        end)
    end
    HookEspRespawn(plr)
    task.delay(1.5, function()
        if Running and (Esp.Names or Esp.Highlight) then CreateEsp(plr) end
    end)
    QueueRefresh()
end))

Track(Players.PlayerRemoving:Connect(function(plr)
    LogEvent("- " .. plr.DisplayName .. " (@" .. plr.Name .. ")")
    if NotifyJoins then
        Notify("Saiu", plr.DisplayName .. " (@" .. plr.Name .. ")", "user-minus", 3)
    end
    RemoveEsp(plr)
    QueueRefresh()
end))

--═══════════════════════════════════════════════════════════════
--  ABA INTERFACE
--═══════════════════════════════════════════════════════════════
AbaInterface:Section({ Title = "Aparência" })

AbaInterface:Dropdown({
    Flag   = "Theme",
    Title  = "Tema",
    Values = { "Dark", "Light", "Rose", "Plant", "Indigo", "Sky", "Violet", "Amber" },
    Value  = "Dark",
    Callback = function(theme)
        pcall(function() WindUI:SetTheme(theme) end)
    end,
})

AbaInterface:Slider({
    Flag  = "UIScale",
    Title = "Escala do menu",
    Step  = 5,
    Value = { Min = 60, Max = 130, Default = 100 },
    Callback = function(value)
        pcall(function() Window:SetUIScale(value / 100) end)
    end,
})

AbaInterface:Keybind({
    Flag  = "ToggleKey",
    Title = "Tecla pra abrir/fechar",
    Desc  = "Abre e fecha o SamMods Hub",
    Value = "RightControl",
    Callback = function(key)
        pcall(function() Window:SetToggleKey(Enum.KeyCode[key]) end)
    end,
})

AbaInterface:Section({ Title = "UI do Roblox" })

AbaInterface:Toggle({
    Flag  = "CleanScreen",
    Title = "Tela limpa",
    Desc  = "Esconde toda a interface do Roblox, bom pra prints",
    Icon  = "camera",
    Value = false,
    Callback = function(state)
        CleanScreen = state
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not state) end)
        pcall(function() StarterGui:SetCore("TopbarEnabled", not state) end)
        SyncOverlay()
    end,
})

AbaInterface:Toggle({
    Flag  = "HideChat",
    Title = "Esconder chat",
    Icon  = "message-square-off",
    Value = false,
    Callback = function(state)
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, not state) end)
    end,
})

AbaInterface:Toggle({
    Flag  = "HideList",
    Title = "Esconder lista de jogadores",
    Icon  = "list-x",
    Value = false,
    Callback = function(state)
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not state) end)
    end,
})

AbaInterface:Section({ Title = "Script" })

AbaInterface:Button({
    Title = "Salvar configurações",
    Desc  = "Serão restauradas no próximo uso",
    Icon  = "save",
    Callback = function()
        local ok = pcall(function() Config:Save() end)
        Notify(ok and "Salvo" or "Falhou",
            ok and "Configurações gravadas no disco" or "Esse executor não pode escrever arquivos",
            ok and "check" or "circle-alert", 3)
    end,
})

--═══════════════════════════════════════════════════════════════
--  ABA SOBRE (Sobre a SamMods)
--═══════════════════════════════════════════════════════════════
AbaSobre:Section({ Title = "Sobre a SamMods" })

AbaSobre:Paragraph({
    Title     = "SamMods · Quality of Life Hub",
    Desc      = "Hub completo com tudo que você precisa pra melhorar sua experiência. Feito com carinho pela SamMods.",
    Image     = "sparkles",
    ImageSize = 22,
})

AbaSobre:Paragraph({
    Title     = "Versão",
    Desc      = "v5 · Ciano/Roxo/Rosa · Tema oficial SamMods",
    Image     = "tag",
    ImageSize = 22,
})

AbaSobre:Section({ Title = "Créditos" })

AbaSobre:Paragraph({
    Title     = "Desenvolvido por:",
    Desc      = "SamMods Team · 2024-2025",
    Image     = "code",
    ImageSize = 22,
})

AbaSobre:Paragraph({
    Title     = "Interface:",
    Desc      = "WindUI · por Footagesus",
    Image     = "layout",
    ImageSize = 22,
})

AbaSobre:Section({ Title = "Aviso" })

AbaSobre:Paragraph({
    Title     = "Uso por sua conta e risco",
    Desc      = "A SamMods não se responsabiliza por banimentos. Use com bom senso.",
    Image     = "shield-alert",
    ImageSize = 22,
})

--═══════════════════════════════════════════════════════════════
--  UNLOAD (descarga)
--═══════════════════════════════════════════════════════════════
local function Unload()
    if not Running then return end
    Running = false

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    StopFly()
    SetSpin(false)

    pcall(function()
        local hrp = GetHRP()
        if hrp then hrp.Anchored = false end
    end)

    pcall(ResetMovement)
    pcall(function() workspace.Gravity = DefaultGravity end)
    ClearAllEsp()

    pcall(function()
        Lighting.Brightness    = OriginalLighting.Brightness
        Lighting.ClockTime     = OriginalLighting.ClockTime
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.Ambient       = OriginalLighting.Ambient
        Lighting.FogEnd        = OriginalLighting.FogEnd
    end)

    pcall(function() Overlay:Destroy() end)
    pcall(function() Cross:Destroy() end)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
    pcall(function() StarterGui:SetCore("TopbarEnabled", true) end)
    pcall(function() workspace.CurrentCamera.FieldOfView = DefaultFOV end)

    SetNamesHidden(false)
    pcall(function() ApplyPreset("Padrão") end)
    pcall(function() Window:Destroy() end)

    _G.SamModsUnload = nil
    Notify("SamMods Hub", "Descarregado com sucesso", "log-out", 3)
end

_G.SamModsUnload = Unload

AbaInterface:Button({
    Title = "Descarregar script",
    Desc  = "Desconecta tudo, restaura UI, FOV, gráficos e física",
    Icon  = "log-out",
    Color = Color3.fromHex("#ff4830"),
    Callback = Unload,
})

pcall(function()
    Window:OnDestroy(Unload)
end)

--═══════════════════════════════════════════════════════════════
--  LOOP DE STATUS
--═══════════════════════════════════════════════════════════════
task.spawn(function()
    while Running and task.wait(0.5) do
        Ping = GetPing()
        pcall(function()
            Info:SetTitle(string.format("FPS: %d   ·   Ping: %d ms", FPS, Ping))
            Info:SetDesc(string.format(
                "Jogadores: %d/%d   ·   no servidor: %s",
                #Players:GetPlayers(), Players.MaxPlayers, FormatTime(os.time() - StartTime)
            ))
            if ShowSpeed then
                Label.Text = string.format("FPS %d  ·  PING %d ms  ·  VEL %d", FPS, Ping, GetSpeed())
            else
                Label.Text = string.format("FPS %d  ·  PING %d ms", FPS, Ping)
            end
        end)
    end
end)

pcall(function()
    Config:Load()
end)

SyncOverlay()

--═══════════ FINALIZA SPLASH ═══════════
Splash.Set(1, "Pronto, chefe!")
task.wait(0.6)
Splash.Fechar()

Notify("SamMods Hub v5", "Carregado com sucesso ✓", "check", 4)
print("═══════════════════════════════════════════")
print("  SAMMODS HUB · v5")
print("  Carregado com sucesso · Bom jogo!")
print("═══════════════════════════════════════════")
--aproveita!
