# SamMods-Scripts
```lua
-- ============================================================
--  SamMods Panel | LocalScript
--  Coloque em: StarterPlayerScripts ou StarterCharacterScripts
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local localChar   = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local camera      = workspace.CurrentCamera

local espEnabled      = false
local espObjects      = {}
local sittingOnPlayer = nil
local seatWeld        = nil

-- ============================================================
--  GUI PRINCIPAL
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "SamModsPanel"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = localPlayer.PlayerGui

local panel = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.new(0, 320, 0, 420)
panel.Position          = UDim2.new(0.5, -160, 0.5, -210)
panel.BackgroundColor3  = Color3.fromRGB(10, 10, 18)
panel.BorderSizePixel   = 0
panel.AnchorPoint       = Vector2.new(0.5, 0.5)
panel.ClipsDescendants  = true
panel.Parent            = screenGui

local stroke = Instance.new("UIStroke")
stroke.Color     = Color3.fromRGB(0, 200, 255)
stroke.Thickness = 2
stroke.Parent    = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 170, 230)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Size             = UDim2.new(1, 0, 0, 12)
titleFix.Position         = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = Color3.fromRGB(0, 170, 230)
titleFix.BorderSizePixel  = 0
titleFix.Parent           = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(1, -50, 1, 0)
titleLabel.Position           = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "⚡ SamMods"
titleLabel.TextColor3         = Color3.new(1,1,1)
titleLabel.Font               = Enum.Font.GothamBold
titleLabel.TextSize           = 17
titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
titleLabel.Parent             = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 32, 0, 32)
closeBtn.Position         = UDim2.new(1, -38, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
closeBtn.Text             = "✕"
closeBtn.TextColor3       = Color3.new(1,1,1)
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 14
closeBtn.BorderSizePixel  = 0
closeBtn.Parent           = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

local openBtn = Instance.new("TextButton")
openBtn.Size             = UDim2.new(0, 110, 0, 34)
openBtn.Position         = UDim2.new(0, 12, 0, 12)
openBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 230)
openBtn.Text             = "⚡ SamMods"
openBtn.TextColor3       = Color3.new(1,1,1)
openBtn.Font             = Enum.Font.GothamBold
openBtn.TextSize         = 13
openBtn.BorderSizePixel  = 0
openBtn.Visible          = false
openBtn.Parent           = screenGui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openBtn

-- ============================================================
--  ANIMAÇÃO ABRIR/FECHAR
-- ============================================================
local panelOpen = true

local function setPanelVisible(visible)
    panelOpen = visible
    if visible then
        panel.Visible = true
        panel.Size    = UDim2.new(0, 0, 0, 0)
        panel.Position = UDim2.new(0.5, 0, 0.5, 0)
        TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size     = UDim2.new(0, 320, 0, 420),
            Position = UDim2.new(0.5, -160, 0.5, -210),
        }):Play()
        openBtn.Visible = false
    else
        local t = TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size     = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
        })
        t:Play()
        t.Completed:Connect(function() panel.Visible = false end)
        openBtn.Visible = true
    end
end

closeBtn.MouseButton1Click:Connect(function() setPanelVisible(false) end)
openBtn.MouseButton1Click:Connect(function()  setPanelVisible(true)  end)

-- ============================================================
--  DRAG
-- ============================================================
do
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = panel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
--  CONTEÚDO
-- ============================================================
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size                 = UDim2.new(1, -16, 1, -56)
contentFrame.Position             = UDim2.new(0, 8, 0, 52)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel      = 0
contentFrame.ScrollBarThickness   = 4
contentFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
contentFrame.CanvasSize           = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize  = Enum.AutomaticSize.Y
contentFrame.Parent               = panel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding   = UDim.new(0, 8)
listLayout.Parent    = contentFrame

local padContent = Instance.new("UIPadding")
padContent.PaddingTop    = UDim.new(0, 4)
padContent.PaddingBottom = UDim.new(0, 4)
padContent.Parent        = contentFrame

local function makeSectionLabel(txt)
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text               = txt
    lbl.TextColor3         = Color3.fromRGB(0, 200, 255)
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 13
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = contentFrame
    return lbl
end

-- ============================================================
--  ESP
-- ============================================================
makeSectionLabel("  👁  VISUAL")

local espBtn = Instance.new("TextButton")
espBtn.Size             = UDim2.new(1, 0, 0, 42)
espBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
espBtn.BorderSizePixel  = 0
espBtn.Text             = "⬜ ESP  (ver jogadores)"
espBtn.TextColor3       = Color3.new(1,1,1)
espBtn.Font             = Enum.Font.GothamSemibold
espBtn.TextSize         = 14
espBtn.Parent           = contentFrame

do
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,8); bc.Parent = espBtn
    local bs = Instance.new("UIStroke"); bs.Color = Color3.fromRGB(255,80,80); bs.Thickness = 1.5; bs.Parent = espBtn
end

local function addESP(player)
    if player == localPlayer then return end
    if espObjects[player] then return end
    local char = player.Character
    if not char then return end

    local hl = Instance.new("SelectionBox")
    hl.Adornee             = char
    hl.Color3              = Color3.fromRGB(255, 50, 50)
    hl.LineThickness       = 0.05
    hl.SurfaceTransparency = 0.7
    hl.SurfaceColor3       = Color3.fromRGB(0, 120, 255)
    hl.Parent              = camera

    local bb = Instance.new("BillboardGui")
    bb.Adornee     = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    bb.Size        = UDim2.new(0, 120, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.ResetOnSpawn = false
    bb.Parent      = camera

    local nl = Instance.new("TextLabel", bb)
    nl.Size               = UDim2.new(1,0,1,0)
    nl.BackgroundTransparency = 1
    nl.Text               = player.Name
    nl.TextColor3         = Color3.new(1,1,1)
    nl.Font               = Enum.Font.GothamBold
    nl.TextSize           = 14
    nl.TextStrokeTransparency = 0

    espObjects[player] = { hl = hl, bb = bb }
end

local function removeESP(player)
    local obj = espObjects[player]
    if obj then
        obj.hl:Destroy()
        obj.bb:Destroy()
        espObjects[player] = nil
    end
end

local function refreshESP()
    if espEnabled then
        for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
    else
        for p in pairs(espObjects) do removeESP(p) end
    end
end

espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.BackgroundColor3 = espEnabled
        and Color3.fromRGB(140, 20, 20)
        or  Color3.fromRGB(20, 20, 32)
    espBtn.Text = (espEnabled and "✅" or "⬜") .. " ESP  (ver jogadores)"
    refreshESP()
end)

Players.PlayerAdded:Connect(function(p)
    if espEnabled then
        p.CharacterAdded:Connect(function()
            task.wait(1); removeESP(p); addESP(p)
        end)
        task.wait(1); addESP(p)
    end
end)
Players.PlayerRemoving:Connect(removeESP)

RunService.Heartbeat:Connect(function()
    if not espEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            local obj  = espObjects[p]
            local char = p.Character
            if char and (not obj or not obj.hl.Parent) then
                removeESP(p); addESP(p)
            elseif not char and obj then
                removeESP(p)
            end
        end
    end
end)

-- ============================================================
--  LISTA DE JOGADORES
-- ============================================================
makeSectionLabel("  👥  JOGADORES")

local playerListFrame = Instance.new("Frame")
playerListFrame.Size              = UDim2.new(1, 0, 0, 10)
playerListFrame.BackgroundTransparency = 1
playerListFrame.AutomaticSize    = Enum.AutomaticSize.Y
playerListFrame.Parent           = contentFrame

local plLayout = Instance.new("UIListLayout")
plLayout.SortOrder = Enum.SortOrder.LayoutOrder
plLayout.Padding   = UDim.new(0, 4)
plLayout.Parent    = playerListFrame

local playerButtons = {}

-- ---- Mini-menu ----
local actionMenu = Instance.new("Frame")
actionMenu.Name             = "ActionMenu"
actionMenu.Size             = UDim2.new(0, 200, 0, 10)
actionMenu.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
actionMenu.BorderSizePixel  = 0
actionMenu.AutomaticSize    = Enum.AutomaticSize.Y
actionMenu.Visible          = false
actionMenu.ZIndex           = 20
actionMenu.Parent           = screenGui

do
    local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(0,10); ac.Parent = actionMenu
    local as = Instance.new("UIStroke"); as.Color = Color3.fromRGB(0,200,255); as.Thickness = 1.5; as.Parent = actionMenu
    local al = Instance.new("UIListLayout"); al.Padding = UDim.new(0,4); al.Parent = actionMenu
    local ap = Instance.new("UIPadding"); ap.PaddingAll = UDim.new(0,6); ap.Parent = actionMenu
end

local actionTarget = nil

local function makeActionBtn(txt, color, cb)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(1,0,0,34)
    b.BackgroundColor3 = Color3.fromRGB(22,22,38)
    b.Text             = txt
    b.TextColor3       = color or Color3.new(1,1,1)
    b.Font             = Enum.Font.GothamSemibold
    b.TextSize         = 13
    b.BorderSizePixel  = 0
    b.ZIndex           = 21
    b.Parent           = actionMenu
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,7); bc.Parent = b
    b.MouseButton1Click:Connect(function()
        actionMenu.Visible = false
        if cb then cb(actionTarget) end
    end)
    return b
end

-- ---- Sentar na cabeça ----
local function sitOnHead(target)
    if not target or target == localPlayer then return end
    local myChar  = localPlayer.Character
    local tarChar = target.Character
    if not myChar or not tarChar then return end
    local myRoot  = myChar:FindFirstChild("HumanoidRootPart")
    local tarHead = tarChar:FindFirstChild("Head")
    if not myRoot or not tarHead then return end

    if seatWeld then seatWeld:Destroy(); seatWeld = nil end

    local weld = Instance.new("WeldConstraint")
    weld.Part0  = myRoot
    weld.Part1  = tarHead
    weld.Parent = myRoot

    myRoot.CFrame   = tarHead.CFrame * CFrame.new(0, 3, 0)
    seatWeld        = weld
    sittingOnPlayer = target

    local hum = myChar:FindFirstChildOfClass("Humanoid")
    if hum then
        local conn
        conn = hum.Jumping:Connect(function(isJumping)
            if isJumping and seatWeld then
                seatWeld:Destroy()
                seatWeld        = nil
                sittingOnPlayer = nil
                conn:Disconnect()
            end
        end)
    end
end

makeActionBtn("🪑 Sentar na cabeça", Color3.fromRGB(255,200,50), sitOnHead)

-- ---- Texto Rainbow ----
local rainbowTags = {}

local function applyRainbow(target)
    local inputGui = Instance.new("ScreenGui")
    inputGui.ResetOnSpawn = false
    inputGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    inputGui.Parent = localPlayer.PlayerGui

    local bg = Instance.new("Frame", inputGui)
    bg.Size             = UDim2.new(0, 300, 0, 110)
    bg.Position         = UDim2.new(0.5, -150, 0.5, -55)
    bg.BackgroundColor3 = Color3.fromRGB(10,10,22)
    bg.BorderSizePixel  = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,12)
    local bgs = Instance.new("UIStroke", bg); bgs.Color = Color3.fromRGB(0,200,255); bgs.Thickness = 2

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size               = UDim2.new(1,0,0,30)
    lbl.Position           = UDim2.new(0,0,0,6)
    lbl.BackgroundTransparency = 1
    lbl.Text               = "✏️  Digite o texto rainbow:"
    lbl.TextColor3         = Color3.new(1,1,1)
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 13

    local tb = Instance.new("TextBox", bg)
    tb.Size             = UDim2.new(1,-20,0,32)
    tb.Position         = UDim2.new(0,10,0,38)
    tb.BackgroundColor3 = Color3.fromRGB(22,22,40)
    tb.BorderSizePixel  = 0
    tb.PlaceholderText  = "seu texto aqui..."
    tb.Text             = ""
    tb.TextColor3       = Color3.new(1,1,1)
    tb.Font             = Enum.Font.Gotham
    tb.TextSize         = 14
    tb.ClearTextOnFocus = false
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,7)

    local confirm = Instance.new("TextButton", bg)
    confirm.Size             = UDim2.new(0,80,0,28)
    confirm.Position         = UDim2.new(0.5,-40,1,-34)
    confirm.BackgroundColor3 = Color3.fromRGB(0,170,230)
    confirm.Text             = "Confirmar"
    confirm.TextColor3       = Color3.new(1,1,1)
    confirm.Font             = Enum.Font.GothamBold
    confirm.TextSize         = 12
    confirm.BorderSizePixel  = 0
    Instance.new("UICorner", confirm).CornerRadius = UDim.new(0,7)

    confirm.MouseButton1Click:Connect(function()
        local msg = tb.Text
        inputGui:Destroy()
        if msg == "" then return end

        if rainbowTags[target] then
            if rainbowTags[target].bb then rainbowTags[target].bb:Destroy() end
            if rainbowTags[target].conn then rainbowTags[target].conn:Disconnect() end
            rainbowTags[target] = nil
        end

        local function getChar()
            return target == localPlayer and localPlayer.Character or target.Character
        end

        local function createBillboard()
            local char = getChar()
            if not char then return end
            local head = char:FindFirstChild("Head")
            if not head then return end

            local bbg = Instance.new("BillboardGui")
            bbg.Adornee      = head
            bbg.Size         = UDim2.new(0, 200, 0, 40)
            bbg.StudsOffset  = Vector3.new(0, 2.8, 0)
            bbg.AlwaysOnTop  = true
            bbg.ResetOnSpawn = false
            bbg.Parent       = localPlayer.PlayerGui

            local tl = Instance.new("TextLabel", bbg)
            tl.Size               = UDim2.new(1,0,1,0)
            tl.BackgroundTransparency = 1
            tl.Text               = msg
            tl.Font               = Enum.Font.GothamBold
            tl.TextSize           = 18
            tl.TextStrokeTransparency = 0

            local hue   = 0
            local conn2 = RunService.Heartbeat:Connect(function(dt)
                hue = (hue + dt * 0.5) % 1
                tl.TextColor3 = Color3.fromHSV(hue, 1, 1)
            end)

            rainbowTags[target] = { bb = bbg, conn = conn2 }
        end

        createBillboard()

        target.CharacterAdded:Connect(function()
            task.wait(1)
            if rainbowTags[target] then
                if rainbowTags[target].bb then rainbowTags[target].bb:Destroy() end
                if rainbowTags[target].conn then rainbowTags[target].conn:Disconnect() end
            end
            createBillboard()
        end)
    end)
end

makeActionBtn("🌈 Texto Rainbow", Color3.fromRGB(180,100,255), applyRainbow)
makeActionBtn("❌ Fechar menu",    Color3.fromRGB(200,60,60),   function() actionMenu.Visible = false end)

-- ---- Lista de jogadores ----
local function clearPlayerList()
    for _, b in pairs(playerButtons) do b:Destroy() end
    playerButtons = {}
end

local function buildPlayerList()
    clearPlayerList()
    for _, p in ipairs(Players:GetPlayers()) do
        local isMe = (p == localPlayer)
        local btn  = Instance.new("TextButton")
        btn.Size             = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = isMe and Color3.fromRGB(0,80,130) or Color3.fromRGB(20,20,32)
        btn.BorderSizePixel  = 0
        btn.Text             = (isMe and "🟢 " or "🔵 ") .. p.Name .. (isMe and "  (você)" or "")
        btn.TextColor3       = Color3.new(1,1,1)
        btn.Font             = Enum.Font.Gotham
        btn.TextSize         = 13
        btn.ZIndex           = 10
        btn.Parent           = playerListFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)

        btn.MouseButton1Click:Connect(function()
            actionTarget        = p
            actionMenu.Position = UDim2.new(0, btn.AbsolutePosition.X + 10,
                                            0, btn.AbsolutePosition.Y - 10)
            actionMenu.Visible  = true
        end)
        table.insert(playerButtons, btn)
    end
end
buildPlayerList()
Players.PlayerAdded:Connect(function()   task.wait(0.5); buildPlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); buildPlayerList() end)

-- ============================================================
--  ANIMAÇÃO INICIAL
-- ============================================================
panel.Size     = UDim2.new(0, 0, 0, 0)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Visible  = true
TweenService:Create(panel, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size     = UDim2.new(0, 320, 0, 420),
    Position = UDim2.new(0.5, -160, 0.5, -210),
}):Play()

print("[SamMods] Script carregado com sucesso!")
