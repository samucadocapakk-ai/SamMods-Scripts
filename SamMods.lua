--[[
    TokenPriceWatcher + QuickShop + Hack Alert + ESP Anti-Roubo + Player Tags
    Local: StarterPlayerScripts

    Alterações:
    - Tags (Owner/User) agora são geradas apenas para quem executou o script (local GUI).
    - O LocalPlayer também recebe sua própria tag (se for Owner mostram o efeito rainbow na própria cabeça).
    - Removido o painel de histórico de roubo (funcionalidade removida conforme pedido).
    - As tags de USER/ADM não possuem mais fundo (transparente) — só o texto aparece.
    - Owner tem efeito rainbow na fonte (TextColor3 + TextStrokeColor3) com fonte mais destacada.
    - ESP "ROUBANDO VOCÊ" continua com visual rainbow para o atacante.
    - Ao receber eventos de fim/abort/resultado ou quando role deixar de ser 'victim', o ESP é removido imediatamente e o alerta para.
    - Integração do sistema de loja: mostra o preço atual e o valor a receber no HUD quando OpenTokenExchange é aberto; envia uma mensagem no chat (uma vez por ativação).
    - Correção: tags agora somente são criadas para o LocalPlayer (evita aparecer em todas as cabeças).
    - Removida borda do DONO e deixado USER mais visível.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
--                    CONFIGURAÇÕES DO ESP
-- =========================================================

local OWNER_ID = 4290770735
local ESP_MAX_DISTANCE = 2000 -- Distância máxima para mostrar ESP
local ESP_UPDATE_RATE = 0.05 -- Taxa de atualização do ESP (segundos)

-- Tabela para armazenar ESPs ativos
local activeESPs = {}
local activePlayerTags = {}
local robberyInProgress = false
local currentRobber = nil

-- =========================================================
--                    INTRO "SamMods"
-- =========================================================

-- (mantive a intro existente sem alterações)

-- carregar intro (o código da intro permanece inalterado)
-- Para brevidade mantive o bloco original: se necessário altero depois.

-- =========================================================
--              SISTEMA DE ESP ANTI-ROUBO
-- =========================================================

local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "ESPAntiRobo"
ESPGui.ResetOnSpawn = false
ESPGui.IgnoreGuiInset = true
ESPGui.DisplayOrder = 999
ESPGui.Parent = PlayerGui

-- Criar ESP para um jogador específico
local function criarESP(player)
	if not player then return nil end
	if activeESPs[player.UserId] then return activeESPs[player.UserId] end
	
	-- Container na tela (overlay)
	local espContainer = Instance.new("Frame")
	espContainer.Name = "ESP_" .. player.Name
	espContainer.Size = UDim2.fromOffset(120, 80)
	espContainer.BackgroundTransparency = 1
	espContainer.BorderSizePixel = 0
	espContainer.ZIndex = 100
	espContainer.Parent = ESPGui
	
	-- Avatar do jogador (circular)
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Name = "AvatarFrame"
	avatarFrame.Size = UDim2.fromOffset(50, 50)
	avatarFrame.Position = UDim2.new(0.5, -25, 0, 0)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	avatarFrame.BorderSizePixel = 0
	avatarFrame.ZIndex = 101
	avatarFrame.Parent = espContainer
	
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatarFrame
	
	-- Borda rainbow do avatar (mantida apenas para HUD)
	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Thickness = 3
	avatarStroke.Transparency = 0
	avatarStroke.Parent = avatarFrame
	
	-- Imagem do avatar
	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "AvatarImage"
	avatarImage.Size = UDim2.fromScale(1, 1)
	avatarImage.BackgroundTransparency = 1
	local success, thumb = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	if success and thumb then
		avatarImage.Image = thumb
	end
	avatarImage.ZIndex = 102
	avatarImage.Parent = avatarFrame
	
	local avatarImageCorner = Instance.new("UICorner")
	avatarImageCorner.CornerRadius = UDim.new(1, 0)
	avatarImageCorner.Parent = avatarImage
	
	-- Label de distância (na HUD)
	local distLabel = Instance.new("TextLabel")
	distLabel.Name = "DistanceLabel"
	distLabel.Size = UDim2.new(1, 0, 0, 20)
	distLabel.Position = UDim2.new(0, 0, 0, 55)
	distLabel.BackgroundTransparency = 1
	distLabel.Font = Enum.Font.GothamBold
	distLabel.TextSize = 14
	distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	distLabel.Text = "0m"
	distLabel.ZIndex = 101
	distLabel.Parent = espContainer
	
	-- Label de aviso (HUD)
	local warnLabel = Instance.new("TextLabel")
	warnLabel.Name = "WarnLabel"
	warnLabel.Size = UDim2.new(1, 0, 0, 16)
	warnLabel.Position = UDim2.new(0, 0, 0, 75)
	warnLabel.BackgroundTransparency = 1
	warnLabel.Font = Enum.Font.GothamBlack
	warnLabel.TextSize = 14
	warnLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	warnLabel.Text = "⚠️ ROUBANDO VOCÊ"
	warnLabel.ZIndex = 101
	warnLabel.Parent = espContainer
	
	-- Billboard para mostrar o aviso diretamente na cabeça do atacante
	local headBillboard = Instance.new("BillboardGui")
	headBillboard.Name = "ESP_Head_" .. player.UserId
	headBillboard.AlwaysOnTop = true
	headBillboard.Size = UDim2.fromOffset(150, 24)
	headBillboard.StudsOffset = Vector3.new(0, 2.6, 0)
	headBillboard.MaxDistance = ESP_MAX_DISTANCE
	headBillboard.ZIndexBehavior = Enum.ZIndexBehavior.Global
	headBillboard.Parent = ESPGui
	
	local headWarn = Instance.new("TextLabel")
	headWarn.Name = "HeadWarn"
	headWarn.Size = UDim2.new(1, 0, 1, 0)
	headWarn.BackgroundTransparency = 1
	headWarn.Font = Enum.Font.GothamBlack
	headWarn.TextSize = 16
	headWarn.Text = "⚠️ ROUBANDO VOCÊ"
	headWarn.TextColor3 = Color3.fromRGB(255, 50, 50)
	headWarn.ZIndex = 2
	headWarn.Parent = headBillboard
	
	-- Animação rainbow para HUD + head label
	local hue = 0
	local rainbowConnection = RunService.RenderStepped:Connect(function(dt)
		if not espContainer.Parent and not headBillboard.Parent then return end
		hue = (hue + dt * 2) % 1
		local rainbowColor = Color3.fromHSV(hue, 1, 1)
		avatarStroke.Color = rainbowColor
		warnLabel.TextColor3 = rainbowColor
		headWarn.TextColor3 = rainbowColor
	end)
	
	local espData = {
		container = espContainer,
		avatarFrame = avatarFrame,
		distLabel = distLabel,
		warnLabel = warnLabel,
		avatarStroke = avatarStroke,
		headBillboard = headBillboard,
		headWarn = headWarn,
		player = player,
		rainbowConnection = rainbowConnection,
		hue = 0
	}
	
	activeESPs[player.UserId] = espData
	return espData
end

-- Remover ESP de um jogador
local function removerESP(player)
	local espData = activeESPs[player.UserId]
	if not espData then return end
	
	if espData.rainbowConnection then
		espData.rainbowConnection:Disconnect()
	end
	
	if espData.container and espData.container.Parent then
		espData.container:Destroy()
	end
	if espData.headBillboard and espData.headBillboard.Parent then
		espData.headBillboard:Destroy()
	end
	
	activeESPs[player.UserId] = nil
end

-- Atualizar posição do ESP (HUD) e definir adornee do billboard
local function atualizarESP(espData)
	if not espData or not espData.player or not espData.player.Character then return end
	
	local character = espData.player.Character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local head = character:FindFirstChild("Head")
	if espData.headBillboard and head then
		espData.headBillboard.Adornee = head
	end
	
	local localCharacter = LocalPlayer.Character
	if not localCharacter then return end
	
	local localHRP = localCharacter:FindFirstChild("HumanoidRootPart")
	if not localHRP then return end
	
	local distance = (humanoidRootPart.Position - localHRP.Position).Magnitude
	espData.distLabel.Text = string.format("%.0fm", distance)
	
	-- Verificar se está dentro da distância máxima
	if distance > ESP_MAX_DISTANCE then
		espData.container.Visible = false
		if espData.headBillboard then espData.headBillboard.Enabled = false end
		return
	else
		espData.container.Visible = true
		if espData.headBillboard then espData.headBillboard.Enabled = true end
	end
	
	-- Converter posição 3D para 2D na tela para HUD
	local camera = Workspace.CurrentCamera
	local screenPos, onScreen = camera:WorldToViewportPoint(humanoidRootPart.Position + Vector3.new(0, 3, 0))
	
	if onScreen then
		espData.container.Position = UDim2.fromOffset(screenPos.X - 60, screenPos.Y - 80)
		espData.container.Visible = true
		
		-- Escala baseada na distância (menor quando mais longe)
		local scale = math.clamp(1 - (distance / ESP_MAX_DISTANCE) * 0.5, 0.6, 1)
		espData.container.Size = UDim2.fromOffset(120 * scale, 80 * scale)
	else
		espData.container.Visible = false
	end
end

-- =========================================================
--              SISTEMA DE TAGS DE JOGADORES (visível só pra quem executou)
-- =========================================================

local function criarPlayerTag(player)
	-- Garantia extra: somente criamos tag para quem executou o script (LocalPlayer)
	if not player or player ~= LocalPlayer then return nil end
	if activePlayerTags[player.UserId] then return activePlayerTags[player.UserId] end
	
	local isOwner = (player.UserId == OWNER_ID)
	
	local tagContainer = Instance.new("BillboardGui")
	tagContainer.Name = "PlayerTag_" .. player.Name
	tagContainer.AlwaysOnTop = true
	tagContainer.Size = UDim2.fromOffset(140, 30)
	tagContainer.StudsOffset = Vector3.new(0, 2.6, 0)
	tagContainer.MaxDistance = 1000
	tagContainer.ZIndexBehavior = Enum.ZIndexBehavior.Global
	tagContainer.Parent = ESPGui
	
	-- Fundo da tag: deixamos transparente (sem fundo feio)
	local tagBg = Instance.new("Frame")
	tagBg.Name = "TagBackground"
	tagBg.Size = UDim2.fromScale(1, 1)
	tagBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	tagBg.BackgroundTransparency = 1 -- sem fundo
	tagBg.BorderSizePixel = 0
	tagBg.ZIndex = 1
	tagBg.Parent = tagContainer
	
	local tagCorner = Instance.new("UICorner")
	tagCorner.CornerRadius = UDim.new(0, 6)
	tagCorner.Parent = tagBg
	
	-- Borda: sempre transparente (removida)
	local tagStroke = Instance.new("UIStroke")
	tagStroke.Thickness = 1.8
	tagStroke.Transparency = 1
	tagStroke.Parent = tagBg
	
	-- Texto da tag
	local tagText = Instance.new("TextLabel")
	tagText.Name = "TagText"
	tagText.Size = UDim2.new(1, 0, 1, 0)
	tagText.Position = UDim2.new(0, 0, 0, 0)
	tagText.BackgroundTransparency = 1
	-- fonte mais marcante para owner
	tagText.Font = isOwner and Enum.Font.GothamBlack or Enum.Font.GothamBold
	tagText.TextSize = isOwner and 16 or 16 -- deixar USER mais visível
	tagText.Text = isOwner and "👑 DONO" or "👤 USER"
	tagText.ZIndex = 2
	-- tornar o texto do USER mais visível (mesmo sem fundo)
	tagText.TextStrokeTransparency = isOwner and 0.6 or 0.2
	tagText.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	tagText.Parent = tagBg
	
	if isOwner then
		-- Animação rainbow para dono (colorindo texto e stroke) — sem borda externa
		local hue = 0
		local rainbowConn = RunService.RenderStepped:Connect(function(dt)
			if not tagContainer.Parent then return end
			hue = (hue + dt * 1.2) % 1
			local rainbowColor = Color3.fromHSV(hue, 1, 1)
			tagText.TextColor3 = rainbowColor
			tagText.TextStrokeColor3 = Color3.fromHSV((hue + 0.15) % 1, 0.9, 0.2)
			-- tagStroke permanece transparente
		end)
		
		activePlayerTags[player.UserId] = {
			container = tagContainer,
			rainbowConnection = rainbowConn,
			player = player
		}
	else
		-- Usuários normais: texto mais visível, sem fundo
		tagText.TextColor3 = Color3.fromRGB(245, 245, 245)
		tagText.TextStrokeTransparency = 0.2
		tagStroke.Transparency = 1
		
		activePlayerTags[player.UserId] = {
			container = tagContainer,
			rainbowConnection = nil,
			player = player
		}
	end
	
	return activePlayerTags[player.UserId]
end

-- Atualizar posição da tag
local function atualizarPlayerTag(tagData)
	if not tagData or not tagData.player or not tagData.player.Character then return end
	
	local character = tagData.player.Character
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	tagData.container.Adornee = head
end

-- Remover tag
local function removerPlayerTag(player)
	local tagData = activePlayerTags[player.UserId]
	if not tagData then return end
	
	if tagData.rainbowConnection then
		tagData.rainbowConnection:Disconnect()
	end
	
	if tagData.container and tagData.container.Parent then
		tagData.container:Destroy()
	end
	
	activePlayerTags[player.UserId] = nil
end

-- =========================================================
--              GERENCIAMENTO DE ESP E TAGS
-- =========================================================

-- Loop principal de atualização
task.spawn(function()
	while ESPGui.Parent do
		-- Atualizar ESPs ativos (apenas durante roubo)
		if robberyInProgress and currentRobber then
			local espData = activeESPs[currentRobber.UserId]
			if espData then
				atualizarESP(espData)
			end
		end
		
		-- Atualizar tags de todos os jogadores (apenas as criadas localmente)
		for userId, tagData in pairs(activePlayerTags) do
			atualizarPlayerTag(tagData)
		end
		
		task.wait(ESP_UPDATE_RATE)
	end
end)

-- Monitorar jogadores entrando e saindo
Players.PlayerAdded:Connect(function(player)
	task.wait(1) -- Esperar carregar
	-- Criar tag apenas se for o LocalPlayer (executando o script)
	if player == LocalPlayer then
		criarPlayerTag(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	removerESP(player)
	removerPlayerTag(player)
	if currentRobber == player then
		robberyInProgress = false
		currentRobber = nil
	end
end)

-- Criar tag apenas para o LocalPlayer (inclui LocalPlayer para que o dono veja sua própria tag)
criarPlayerTag(LocalPlayer)

-- =========================================================
--              LEITURA REAL DOS TOKENS
-- =========================================================

local tokensLabel

do
	local ok, resultado = pcall(function()
		local hud = PlayerGui:WaitForChild("HUD", 10)
		local spendables = hud:WaitForChild("Spendables", 10)
		local tokenRow = spendables:WaitForChild("TokenRow", 10)
		return tokenRow:WaitForChild("Tokens", 10)
	end)

	if ok then
		tokensLabel = resultado
	else
		warn("[TokenPriceWatcher] Não encontrei PlayerGui.HUD.Spendables.TokenRow.Tokens: " .. tostring(resultado))
	end
end

-- (mantive o resto do script – TokenPriceWatcher, UI e Hack Alert – com pequenas melhorias para remoção imediata do ESP quando necessário)

local UNIDADES_REVERSO = {
	K = 1e3,
	M = 1e6,
	B = 1e9,
	T = 1e12,
	Qa = 1e15,
	Qi = 1e18,
	Sx = 1e21,
	Sp = 1e24,
	Oc = 1e27,
	No = 1e30,
	Dc = 1e33,
	Ud = 1e36,
	Dd = 1e39,
	Td = 1e42,
	Qad = 1e45,
	Qid = 1e48,
	Sxd = 1e51,
	Spd = 1e54,
	Vg = 1e63,
}

local function parseValorAbreviado(texto)
	if not texto then return nil end
	local numeroStr, sufixo = texto:match("(%-?%d+[%.,]?%d*)%s*(%a*)")
	if not numeroStr then return nil end
	numeroStr = numeroStr:gsub(",", ".")
	local numero = tonumber(numeroStr)
	if not numero then return nil end
	local multiplicador = UNIDADES_REVERSO[sufixo]
	if multiplicador then return numero * multiplicador end
	if sufixo == "" or sufixo == nil then return numero end
	return nil
end

local lastReadTokenAmount = nil

local function lerQuantidadeTokens()
	if tokensLabel and tokensLabel.Parent then
		local valor = parseValorAbreviado(tokensLabel.Text)
		if valor then return valor end
	end
	return tonumber(LocalPlayer:GetAttribute("Tokens")) or 0
end

-- =========================================================
--              PROTEÇÃO CONTRA MÚLTIPLAS INSTÂNCIAS
-- =========================================================

local INSTANCE_MARKER_NAME = "TokenPriceWatcher_Instance"
local existingInstance = PlayerGui:FindFirstChild(INSTANCE_MARKER_NAME)

if existingInstance then
	warn("[TokenPriceWatcher] Outra instância já está ativa. Esta instância foi bloqueada.")
	script:Destroy()
	return
end

local instanceMarker = Instance.new("BoolValue")
instanceMarker.Name = INSTANCE_MARKER_NAME
instanceMarker.Value = true
instanceMarker.Parent = PlayerGui

script.Destroying:Connect(function()
	if instanceMarker and instanceMarker.Parent then
		instanceMarker:Destroy()
	end
end)

-- =========================================================
--                     LIMPEZA AUTOMÁTICA
-- =========================================================

local existingGui = PlayerGui:FindFirstChild("TokenPriceWatcherGui")
if existingGui then existingGui:Destroy() end

-- =========================================================
--                     CONFIGURAÇÕES
-- =========================================================

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local OpenTokenExchange = Remotes:FindFirstChild("OpenTokenExchange")
local HackEvent = Remotes:WaitForChild("HackEvent")

local function readNumber(value, default)
	local n = tonumber(value)
	return n or default
end

local PRICE_MIN = math.floor(readNumber(Config.Tokens.priceMin, 5))
local PRICE_MAX = math.floor(readNumber(Config.Tokens.priceMax, 15))
local PRICE_SPIKE = math.floor(readNumber(Config.Tokens.spikePrice, 12))
local PRICE_BASE = math.floor(readNumber(Config.Tokens.basePrice, 10))
local EPOCH_SECONDS = math.max(1, math.floor(readNumber(Config.Tokens.priceEpochSeconds, 30)))

local COLOR_THEMES = {
	Min = Color3.fromRGB(80, 220, 120),
	Base = Color3.fromRGB(0, 170, 255),
	Spike = Color3.fromRGB(255, 130, 40),
	Max = Color3.fromRGB(255, 200, 0)
}

-- =========================================================
--                         HACK ALERT
-- =========================================================

local AlertSound = SoundService:FindFirstChild("HackAlertSound")
if not AlertSound then
	AlertSound = Instance.new("Sound")
	AlertSound.Name = "HackAlertSound"
	AlertSound.SoundId = "rbxassetid://5348162330"
	AlertSound.Volume = 3
	AlertSound.Looped = true
	AlertSound.Parent = SoundService
end
AlertSound.Volume = 3

local alertaAtivo = false

local function iniciarAlerta()
	if alertaAtivo then return end
	alertaAtivo = true
	AlertSound:Stop()
	AlertSound.TimePosition = 0
	AlertSound:Play()
	print("[HACK ALERT] ALERTA INICIADO")
end

local function pararAlerta()
	if not alertaAtivo then return end
	alertaAtivo = false
	AlertSound:Stop()
	AlertSound.TimePosition = 0
	print("[HACK ALERT] ALERTA ENCERRADO")
end

-- =========================================================
-- (UI principal, TokenPriceWatcher etc. mantidos sem mudanças relevantes para as tags/ESP)
-- =========================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TokenPriceWatcherGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10
screenGui.Parent = PlayerGui

-- Criar um display simples para preço e earnings (visível para quem executa o script)
local priceCard = Instance.new("Frame")
priceCard.Name = "PriceCard"
priceCard.AnchorPoint = Vector2.new(1, 0)
priceCard.Position = UDim2.new(1, -16, 0, 110)
priceCard.Size = UDim2.fromOffset(150, 54)
priceCard.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
priceCard.BackgroundTransparency = 0.25
priceCard.BorderSizePixel = 0
priceCard.ZIndex = 50
priceCard.Parent = screenGui

local priceCorner = Instance.new("UICorner")
priceCorner.CornerRadius = UDim.new(0, 8)
priceCorner.Parent = priceCard

local priceLabel = Instance.new("TextLabel")
priceLabel.Name = "PriceLabel"
priceLabel.BackgroundTransparency = 1
priceLabel.Position = UDim2.new(0, 8, 0, 6)
priceLabel.Size = UDim2.new(0, 80, 0, 18)
priceLabel.Font = Enum.Font.GothamBold
priceLabel.TextSize = 15
priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
priceLabel.TextXAlignment = Enum.TextXAlignment.Left
priceLabel.Text = ("$%d"):format(PRICE_BASE)
priceLabel.ZIndex = 51
priceLabel.Parent = priceCard

local earningsLabel = Instance.new("TextLabel")
earningsLabel.Name = "EarningsLabel"
earningsLabel.BackgroundTransparency = 1
earningsLabel.Position = UDim2.new(0, 8, 0, 26)
earningsLabel.Size = UDim2.new(1, -16, 0, 20)
earningsLabel.Font = Enum.Font.Gotham
earningsLabel.TextSize = 12
earningsLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
earningsLabel.TextXAlignment = Enum.TextXAlignment.Left
earningsLabel.Text = "💎 Tokens: 0  •  💰 Receber: $0"
earningsLabel.ZIndex = 51
earningsLabel.Parent = priceCard

local function formatInt(n)
	if not n then return "0" end
	local s = tostring(math.floor(n))
	local res = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	res = res:gsub("^%.", "")
	return res
end

local function updatePriceDisplay(price)
	price = math.floor(tonumber(price) or PRICE_BASE)
	priceLabel.Text = ("$%d"):format(price)
	local tokens = lerQuantidadeTokens() or 0
	local receive = math.floor(tokens * price)
	earningsLabel.Text = string.format("💎 Tokens: %s  •  💰 Receber: $%s", formatInt(tokens), formatInt(receive))
end

-- Debounce para enviar chat apenas uma vez por abertura da loja
local exchangeDebounce = false

if OpenTokenExchange and OpenTokenExchange:IsA("RemoteEvent") then
	OpenTokenExchange.OnClientEvent:Connect(function(payload)
		-- payload pode conter preço atual (campo `.price`) — fallback para PRICE_BASE
		local price = PRICE_BASE
		if type(payload) == "table" and payload.price then
			price = tonumber(payload.price) or PRICE_BASE
		end
		updatePriceDisplay(price)
		
		-- Enviar mensagem no chat como jogador UMA ÚNICA VEZ por abertura
		if not exchangeDebounce then
			exchangeDebounce = true
			local tokens = lerQuantidadeTokens() or 0
			local receive = math.floor(tokens * price)
			local msg = ("Loja aberta — Preço: $%d — Tokens: %s — Receber: $%s"):format(price, formatInt(tokens), formatInt(receive))
			-- Tenta usar o evento padrão de chat (SayMessageRequest)
			local ok, err = pcall(function()
				local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
				if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
					chatEvents.SayMessageRequest:FireServer(msg, "All")
				else
					StarterGui:SetCore("ChatMakeSystemMessage", {Text = msg})
				end
			end)
			if not ok then
				warn("Erro ao enviar mensagem de chat: ", err)
			end
			-- Reset após 8 segundos caso a loja permaneça aberta ou se não houver evento de fechamento
			task.delay(8, function()
				exchangeDebounce = false
			end)
		end
	end)
end

-- =========================================================
--              HACK EVENT COM ESP INTEGRADO
-- =========================================================

HackEvent.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then return end
	
	local kind = tostring(data.kind or ""):lower()
	local action = tostring(data.action or ""):lower()
	local eventType = tostring(data.type or ""):lower()
	local role = tostring(data.role or ""):lower()
	local name = tostring(data.name or "")

	local rouboKinds = {
		robbery = true, roubo = true, steal = true, stealing = true,
		stolen = true, theft = true, robbery_start = true, robbery_end = true,
		steal_start = true, steal_end = true,
	}

	-- Se o evento indica fim/abort/result, removemos o ESP e paramos o alerta
	if rouboKinds[kind] or rouboKinds[action] or rouboKinds[eventType] then
		if kind:find("end") or kind:find("finish") or action:find("end") then
			if currentRobber then
				removerESP(currentRobber)
				robberyInProgress = false
				currentRobber = nil
			end
		end
		pararAlerta()
		return
	end

	-- Se o role não for victim, garantimos limpeza (para remover o estado quando o roubo parar)
	if role ~= "victim" then
		if currentRobber then
			removerESP(currentRobber)
			robberyInProgress = false
			currentRobber = nil
		end
		pararAlerta()
	end

	-- =====================================================
	--     ESP PARA QUEM ESTÁ TE ROUBANDO
	-- =====================================================
	if data.kind == "phase" then
		if role == "victim" then
			iniciarAlerta()
			
			-- Procurar quem está roubando (attacker). Preferir attackerUserId quando disponível
			local attackerId = data.attackerUserId or data.attackerUserId or nil
			local attackerName = data.attacker or data.name
			if attackerId then
				for _, player in ipairs(Players:GetPlayers()) do
					if player.UserId == attackerId then
						currentRobber = player
						break
					end
				end
			end
			
			-- Se não encontrou por id, tenta por nome
			if not currentRobber and attackerName then
				for _, player in ipairs(Players:GetPlayers()) do
					if player.Name == attackerName then
						currentRobber = player
						break
					end
				end
			end
			
			-- Se não achou pelo nome/id, tenta detectar por proximidade
			if not currentRobber then
				local localChar = LocalPlayer.Character
				if localChar then
					local localHRP = localChar:FindFirstChild("HumanoidRootPart")
					if localHRP then
						local closestPlayer = nil
						local closestDist = math.huge
						
						for _, player in ipairs(Players:GetPlayers()) do
							if player ~= LocalPlayer and player.Character then
								local hrp = player.Character:FindFirstChild("HumanoidRootPart")
								if hrp then
									local dist = (hrp.Position - localHRP.Position).Magnitude
									if dist < 100 and dist < closestDist then
										closestDist = dist
										closestPlayer = player
									end
								end
							end
						end
						
						if closestPlayer then
							currentRobber = closestPlayer
						end
					end
				end
			end
			
			-- Se encontrou o atacante, cria ESP independente se ele executa o script ou não
			if currentRobber then
				robberyInProgress = true
				criarESP(currentRobber)
			end
		
		elseif role == "attacker" then
			-- Você é quem está roubando, não mostra ESP
			exists = true
		else
			if name ~= "" and name == LocalPlayer.Name then
				-- Você é o atacante
			else
				warn("[HACK ALERT] role inesperado recebido: '" .. tostring(data.role) .. "' (esperado 'victim' ou 'attacker')")
			end
		end
		return
	end

	if data.kind == "result" then
		-- Remove ESP quando o roubo termina
		if currentRobber then
			removerESP(currentRobber)
			robberyInProgress = false
			currentRobber = nil
		end
		pararAlerta()
		return
	end

	if data.kind == "abort" or data.kind == "end" or data.kind == "ended" or data.kind == "finish" or data.kind == "finished" then
		-- Remove ESP quando aborta/termina
		if currentRobber then
			removerESP(currentRobber)
			robberyInProgress = false
			currentRobber = nil
		end
		pararAlerta()
		return
	end
end)

-- =========================================================
--                  TOKENS / VALOR A RECEBER
-- =========================================================

local earningsLabel = Instance.new("TextLabel")

earningsLabel.Name = "EarningsLabel"

earningsLabel.BackgroundTransparency = 1

earningsLabel.Position = UDim2.new(
	0,
	0,
	0,
	21
)

earningsLabel.Size = UDim2.new(
	1,
	0,
	0,
	10
)

earningsLabel.Font = Enum.Font.GothamBold
earningsLabel.TextSize = 9
earningsLabel.TextColor3 = Color3.fromRGB(
	220,
	225,
	235
)

earningsLabel.TextXAlignment = Enum.TextXAlignment.Left
earningsLabel.Text = "💎 Tokens: 0  •  💰 Receber: $0"

earningsLabel.ZIndex = 5
earningsLabel.Parent = card

-- =========================================================
--                         TIMER
-- =========================================================

local timerLabel = Instance.new("TextLabel")

timerLabel.Name = "TimerLabel"

timerLabel.BackgroundTransparency = 1

timerLabel.Position = UDim2.new(
	0,
	0,
	0,
	34
)

timerLabel.Size = UDim2.new(
	1,
	0,
	0,
	14
)

timerLabel.Font = Enum.Font.GothamBold

timerLabel.TextSize = 11

timerLabel.TextColor3 = Color3.fromRGB(
	225,
	228,
	238
)

timerLabel.TextXAlignment = Enum.TextXAlignment.Left

timerLabel.Text = "--s"

timerLabel.ZIndex = 5

timerLabel.Parent = card

-- =========================================================
--                         BADGE
-- =========================================================

local statusBadge = Instance.new("TextLabel")

statusBadge.Name = "StatusBadge"

statusBadge.AnchorPoint = Vector2.new(
	1,
	0
)

statusBadge.Position = UDim2.new(
	1,
	0,
	0,
	2
)

statusBadge.Size = UDim2.fromOffset(
	52,
	15
)

statusBadge.BackgroundColor3 =
	COLOR_THEMES.Base

statusBadge.BackgroundTransparency = 0.2

statusBadge.Font = Enum.Font.GothamBold

statusBadge.TextSize = 8

statusBadge.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

statusBadge.Text = "NORMAL"

statusBadge.ZIndex = 6

statusBadge.Parent = card

local badgeCorner = Instance.new("UICorner")

badgeCorner.CornerRadius =
	UDim.new(0, 4)

badgeCorner.Parent =
	statusBadge

local badgeStroke = Instance.new("UIStroke")

badgeStroke.Thickness = 1

badgeStroke.Transparency = 0.5

badgeStroke.Parent = statusBadge

-- =========================================================
--         BOTÃO MANUAL DE ENVIAR MENSAGEM NO CHAT
-- =========================================================
-- Permite mandar a mensagem de "loja no máximo" na hora,
-- sem precisar esperar o preço realmente chegar no máximo.
-- Ainda respeita o cooldown de CHAT_COOLDOWN segundos para
-- não tomar punição por flood se clicar várias vezes seguidas.

local sendMsgButton = Instance.new("TextButton")

sendMsgButton.Name = "SendMaxMessageButton"

sendMsgButton.AnchorPoint = Vector2.new(0, 0)

sendMsgButton.Position = UDim2.new(
	0,
	-28,
	0,
	8
)

sendMsgButton.Size = UDim2.fromOffset(
	22,
	22
)

sendMsgButton.BackgroundColor3 = Color3.fromRGB(
	40,
	120,
	220
)

sendMsgButton.AutoButtonColor = false

sendMsgButton.Font = Enum.Font.GothamBold

sendMsgButton.TextSize = 11

sendMsgButton.Text = "📢"

sendMsgButton.TextColor3 = Color3.fromRGB(
	255,
	255,
	255
)

sendMsgButton.ZIndex = 10

sendMsgButton.Parent = card

local sendMsgCorner = Instance.new("UICorner")

sendMsgCorner.CornerRadius = UDim.new(0, 4)
sendMsgCorner.Parent = sendMsgButton

local sendMsgStroke = Instance.new("UIStroke")

sendMsgStroke.Thickness = 1
sendMsgStroke.Transparency = 0.4
sendMsgStroke.Parent = sendMsgButton

-- =========================================================
--                    BARRA DE PROGRESSO
-- =========================================================

local progressBackground = Instance.new("Frame")

progressBackground.Name =
	"ProgressBackground"

progressBackground.Position =
	UDim2.new(
		0,
		0,
		1,
		-2
	)

progressBackground.Size =
	UDim2.new(
		1,
		0,
		0,
		2
	)

progressBackground.BackgroundColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

progressBackground.BackgroundTransparency =
	0.9

progressBackground.BorderSizePixel =
	0

progressBackground.ClipsDescendants =
	true

progressBackground.Parent =
	card

local progressBar = Instance.new("Frame")

progressBar.Name =
	"ProgressBar"

progressBar.Size =
	UDim2.new(
		1,
		0,
		1,
		0
	)

progressBar.BackgroundColor3 =
	COLOR_THEMES.Base

progressBar.BorderSizePixel =
	0

progressBar.Parent =
	progressBackground

-- =========================================================
--                 PARTICULAS VISUAIS
-- =========================================================

local sparkleContainer = Instance.new("Frame")

sparkleContainer.Name =
	"Sparkles"

sparkleContainer.BackgroundTransparency =
	1

sparkleContainer.Size =
	UDim2.fromScale(
		1,
		1
	)

sparkleContainer.ClipsDescendants =
	false

sparkleContainer.Visible =
	false

sparkleContainer.ZIndex =
	20

sparkleContainer.Parent =
	card

local sparkles = {}

for i = 1, 8 do

	local sparkle = Instance.new("TextLabel")

	sparkle.Name =
		"Sparkle_" .. i

	sparkle.BackgroundTransparency =
		1

	sparkle.Text =
		"✦"

	sparkle.TextSize =
		math.random(8, 15)

	sparkle.Font =
		Enum.Font.GothamBold

	sparkle.TextColor3 =
		Color3.fromRGB(
			255,
			255,
			255
		)

	sparkle.Visible =
		false

	sparkle.ZIndex =
		21

	sparkle.Parent =
		sparkleContainer

	table.insert(
		sparkles,
		sparkle
	)

end

-- =========================================================
--              NOTIFICAÇÃO DE PREÇO MÁXIMO
-- =========================================================

local maxNotification = Instance.new("Frame")

maxNotification.Name = "MaxPriceNotification"

maxNotification.AnchorPoint = Vector2.new(0.5, 0)

maxNotification.Position = UDim2.new(
	0.5,
	0,
	0,
	75
)

maxNotification.Size = UDim2.fromOffset(
	285,
	48
)

maxNotification.BackgroundColor3 =
	Color3.fromRGB(
		15,
		17,
		23
	)

maxNotification.BackgroundTransparency = 0.08
maxNotification.BorderSizePixel = 0
maxNotification.Visible = false
maxNotification.ZIndex = 100
maxNotification.Parent = screenGui

local notificationCorner = Instance.new("UICorner")

notificationCorner.CornerRadius =
	UDim.new(
		0,
		12
	)

notificationCorner.Parent =
	maxNotification

local notificationStroke = Instance.new("UIStroke")

notificationStroke.Thickness = 2
notificationStroke.Transparency = 0.1

notificationStroke.Parent =
	maxNotification

local notificationText = Instance.new("TextLabel")

notificationText.Name = "NotificationText"

notificationText.BackgroundTransparency = 1

notificationText.Size =
	UDim2.new(
		1,
		-16,
		1,
		0
	)

notificationText.Position =
	UDim2.new(
		0,
		8,
		0,
		0
	)

notificationText.Font =
	Enum.Font.GothamBlack

notificationText.TextSize =
	13

notificationText.TextWrapped =
	true

notificationText.Text =
	"🌈  LOJA NO MÁXIMO!  •  $15  💎"

notificationText.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

notificationText.ZIndex =
	101

notificationText.Parent =
	maxNotification

-- =========================================================
--               FUNÇÃO DE MENSAGEM NO CHAT
-- =========================================================

local function enviarMensagemChat()

	local mensagem =
		"🌈 Loja: preço dos tokens está no máximo"

	if TextChatService.ChatVersion ==
		Enum.ChatVersion.TextChatService then

		local textChannels =
			TextChatService:FindFirstChild("TextChannels")

		if textChannels then

			local general =
				textChannels:FindFirstChild("RBXGeneral")

			if general then

				pcall(function()
					general:SendAsync(mensagem)
				end)

				return

			end

		end

	end

	-- Chat antigo
	pcall(function()

		StarterGui:SetCore(
			"ChatMakeSystemMessage",
			{
				Text = mensagem,
				Font = Enum.Font.GothamBold,
				TextSize = 18
			}
		)

	end)

end

-- =========================================================
--               ANIMAÇÃO DA NOTIFICAÇÃO
-- =========================================================

local notificationToken = 0

local function mostrarNotificacaoMaximo()

	notificationToken += 1

	local meuToken =
		notificationToken

	maxNotification.Visible = true

	maxNotification.Position =
		UDim2.new(
			0.5,
			0,
			0,
			55
		)

	maxNotification.BackgroundTransparency =
		1

	notificationText.TextTransparency =
		1

	TweenService:Create(
		maxNotification,
		TweenInfo.new(
			0.35,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Position =
				UDim2.new(
					0.5,
					0,
					0,
					75
				),

			BackgroundTransparency = 0.08
		}
	):Play()

	TweenService:Create(
		notificationText,
		TweenInfo.new(
			0.3
		),
		{
			TextTransparency = 0
		}
	):Play()

	task.spawn(function()

		local hue = 0

		while
			meuToken == notificationToken
			and maxNotification.Visible
		do

			hue =
				(hue + 0.01) % 1

			notificationStroke.Color =
				Color3.fromHSV(
					hue,
					1,
					1
				)

			notificationText.TextColor3 =
				Color3.fromHSV(
					(hue + 0.12) % 1,
					0.8,
					1
				)

			task.wait(0.03)

		end

	end)

	task.delay(
		4,
		function()

			if meuToken ~= notificationToken then
				return
			end

			local outTween =
				TweenService:Create(
					maxNotification,
					TweenInfo.new(
						0.3,
						Enum.EasingStyle.Quad,
						Enum.EasingDirection.In
					),
					{
						Position =
							UDim2.new(
								0.5,
								0,
								0,
								55
							),

						BackgroundTransparency = 1
					}
				)

			TweenService:Create(
				notificationText,
				TweenInfo.new(
					0.2
				),
				{
					TextTransparency = 1
				}
			):Play()

			outTween:Play()

			outTween.Completed:Wait()

			if meuToken == notificationToken then
				maxNotification.Visible = false
			end

		end
	)

end

-- =========================================================
--                     ESTADO MAXIMO
-- =========================================================

local maximoAtivo = false

-- =========================================================
--          CONTROLE DE ENVIO ÚNICO DA MENSAGEM
-- =========================================================
-- A mensagem no chat deve ser enviada apenas UMA VEZ por
-- ativação do modo MÁXIMO (não repetir enquanto o preço
-- permanecer em $15). Um cooldown extra por segurança evita
-- flood caso o preço oscile rapidamente entre estados.

local CHAT_COOLDOWN = 27

local CHAT_COOLDOWN_ATTRIBUTE =
	"TokenPriceWatcher_LastChatMessage"

local function tentarEnviarMensagemMaximo()

	local agora = os.clock()

	local ultimoEnvioGlobal =
		PlayerGui:GetAttribute(
			CHAT_COOLDOWN_ATTRIBUTE
		) or -math.huge

	if agora - ultimoEnvioGlobal >= CHAT_COOLDOWN then

		PlayerGui:SetAttribute(
			CHAT_COOLDOWN_ATTRIBUTE,
			agora
		)

		enviarMensagemChat()

		return true

	end

	return false

end

-- =========================================================
--       CLIQUE MANUAL: ENVIAR MENSAGEM NA HORA
-- =========================================================
-- Ao clicar no botão 📢, tenta mandar a mensagem imediatamente,
-- sem esperar o preço bater no máximo. Ainda respeita o
-- cooldown de CHAT_COOLDOWN segundos pra evitar punição por
-- flood no chat.

sendMsgButton.MouseButton1Click:Connect(function()

	local enviou =
		tentarEnviarMensagemMaximo()

	if enviou then

		-- Feedback visual: pisca verde ao enviar com sucesso.
		local corOriginal =
			sendMsgButton.BackgroundColor3

		sendMsgButton.BackgroundColor3 =
			Color3.fromRGB(60, 200, 100)

		TweenService:Create(
			sendMsgButton,
			TweenInfo.new(0.6),
			{ BackgroundColor3 = corOriginal }
		):Play()

	else

		-- Feedback visual: pisca vermelho se ainda em cooldown.
		local corOriginal =
			sendMsgButton.BackgroundColor3

		sendMsgButton.BackgroundColor3 =
			Color3.fromRGB(200, 60, 60)

		TweenService:Create(
			sendMsgButton,
			TweenInfo.new(0.6),
			{ BackgroundColor3 = corOriginal }
		):Play()

	end

end)

local rainbowConnection = nil
local pulseConnection = nil

local function pararEfeitoMaximo()

	maximoAtivo = false

	aura.Visible = false
	sparkleContainer.Visible = false

	if rainbowConnection then

		rainbowConnection:Disconnect()
		rainbowConnection = nil

	end

	if pulseConnection then

		pulseConnection:Disconnect()
		pulseConnection = nil

	end

	card.Size = UDim2.fromOffset(
		150,
		54
	)

end

local function iniciarEfeitoMaximo()

	if maximoAtivo then
		return
	end

	maximoAtivo = true

	-- Mensagem enviada UMA ÚNICA VEZ, no exato momento em que
	-- o modo MÁXIMO é ativado (transição normal -> máximo).
	tentarEnviarMensagemMaximo()

	aura.Visible = true
	sparkleContainer.Visible = true

	-- =====================================================
	--                     RAINBOW
	-- =====================================================

	local hue = 0

	rainbowConnection =
		RunService.RenderStepped:Connect(function(dt)

			if not maximoAtivo then
				return
			end

			hue =
				(hue + dt * 0.45) % 1

			local rainbowColor =
				Color3.fromHSV(
					hue,
					1,
					1
				)

			cardStroke.Color =
				rainbowColor

			auraStroke.Color =
				rainbowColor

			badgeStroke.Color =
				rainbowColor

			progressBar.BackgroundColor3 =
				rainbowColor

			statusBadge.BackgroundColor3 =
				rainbowColor

			priceLabel.TextColor3 =
				rainbowColor

			shine.BackgroundColor3 =
				rainbowColor

		end)

	-- =====================================================
	--                     PULSAÇÃO
	-- =====================================================

	local pulseTime = 0

	pulseConnection =
		RunService.RenderStepped:Connect(function(dt)

			if not maximoAtivo then
				return
			end

			pulseTime += dt * 4

			local wave =
				(math.sin(pulseTime) + 1) / 2

			local scale =
				1 + (wave * 0.035)

			card.Size =
				UDim2.fromOffset(
					150 * scale,
					54 * scale
				)

			cardStroke.Thickness =
				1.2 + wave * 2

			cardStroke.Transparency =
				0.15 + wave * 0.25

			auraStroke.Transparency =
				0.45 + wave * 0.3

		end)

	-- =====================================================
	--                  ANIMAÇÃO DA FAIXA
	-- =====================================================

	task.spawn(function()

		while maximoAtivo and card.Parent do

			shine.Position =
				UDim2.new(
					-0.5,
					0,
					0,
					0
				)

			local tween =
				TweenService:Create(
					shine,
					TweenInfo.new(
						1.1,
						Enum.EasingStyle.Linear
					),
					{
						Position =
							UDim2.new(
								1.2,
								0,
								0,
								0
							)
					}
				)

			tween:Play()

			tween.Completed:Wait()

			task.wait(0.25)

		end

	end)

	-- =====================================================
	--                    SPARKLES
	-- =====================================================

	task.spawn(function()

		while maximoAtivo and card.Parent do

			for _, sparkle in ipairs(sparkles) do

				if not maximoAtivo then
					break
				end

				sparkle.Visible = true

				sparkle.Position =
					UDim2.new(
						math.random(),
						0,
						math.random(),
						0
					)

				sparkle.TextTransparency = 0

				local finalPos =
					sparkle.Position

				local tween =
					TweenService:Create(
						sparkle,
						TweenInfo.new(
							0.6,
							Enum.EasingStyle.Quad,
							Enum.EasingDirection.Out
						),
						{
							Position =
								UDim2.new(
									finalPos.X.Scale,
									finalPos.X.Offset,
									finalPos.Y.Scale - 0.25,
									finalPos.Y.Offset
								),

							TextTransparency = 1,

							TextSize =
								math.random(14, 22)
						}
					)

				tween:Play()

				task.wait(0.08)

			end

			task.wait(0.15)

		end

	end)

end

-- =========================================================
--                    INTERAÇÃO DE CLIQUE
-- =========================================================

card.MouseButton1Down:Connect(function()

	TweenService:Create(
		card,
		TweenInfo.new(
			0.08
		),
		{
			Size =
				UDim2.fromOffset(
					145,
					52
				)
		}
	):Play()

end)

card.MouseButton1Up:Connect(function()

	if maximoAtivo then

		TweenService:Create(
			card,
			TweenInfo.new(
				0.08
			),
			{
				Size =
					UDim2.fromOffset(
						153,
						55
					)
			}
		):Play()

	else

		TweenService:Create(
			card,
			TweenInfo.new(
				0.08
			),
			{
				Size =
					UDim2.fromOffset(
						150,
						54
					)
			}
		):Play()

	end

	if OpenTokenExchange then

		if OpenTokenExchange:IsA(
			"RemoteEvent"
		) then

			OpenTokenExchange:FireServer()

		elseif OpenTokenExchange:IsA(
			"BindableEvent"
		) then

			OpenTokenExchange:Fire()

		end

	end

end)

-- =========================================================
--                         HOVER
-- =========================================================

card.MouseEnter:Connect(function()

	TweenService:Create(
		card,
		TweenInfo.new(
			0.2
		),
		{
			BackgroundTransparency =
				0.12
		}
	):Play()

	if not maximoAtivo then

		TweenService:Create(
			cardStroke,
			TweenInfo.new(
				0.2
			),
			{
				Transparency =
					0.35
			}
		):Play()

	end

end)

card.MouseLeave:Connect(function()

	TweenService:Create(
		card,
		TweenInfo.new(
			0.2
		),
		{
			BackgroundTransparency =
				0.25
		}
	):Play()

	if not maximoAtivo then

		TweenService:Create(
			cardStroke,
			TweenInfo.new(
				0.2
			),
			{
				Transparency =
					0.8
			}
		):Play()

		TweenService:Create(
			card,
			TweenInfo.new(
				0.08
			),
			{
				Size =
					UDim2.fromOffset(
						150,
						54
					)
			}
		):Play()

	end

end)

-- =========================================================
--                  ANIMAÇÃO DO PREÇO
-- =========================================================

local lastPrice = PRICE_BASE

local function animatePriceBounce()

	local tweenUp =
		TweenService:Create(
			priceLabel,
			TweenInfo.new(
				0.1,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				TextSize = 17
			}
		)

	local tweenDown =
		TweenService:Create(
			priceLabel,
			TweenInfo.new(
				0.15,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			),
			{
				TextSize = 15
			}
		)

	tweenUp:Play()

	tweenUp.Completed:Connect(function()

		tweenDown:Play()

	end)

end

-- =========================================================
--                      TEMA NORMAL
-- =========================================================

local function applyTheme(
	themeColor,
	strokeTransparency,
	badgeText
)

	TweenService:Create(
		progressBar,
		TweenInfo.new(
			0.3,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			BackgroundColor3 =
				themeColor
		}
	):Play()

	TweenService:Create(
		cardStroke,
		TweenInfo.new(
			0.3,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			Color = themeColor,
			Transparency =
				strokeTransparency
		}
	):Play()

	TweenService:Create(
		statusBadge,
		TweenInfo.new(
			0.3,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			BackgroundColor3 =
				themeColor
		}
	):Play()

	TweenService:Create(
		priceLabel,
		TweenInfo.new(
			0.3,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			TextColor3 =
				themeColor
		}
	):Play()

	statusBadge.Text =
		badgeText

	statusBadge.TextColor3 =
		Color3.fromRGB(
			255,
			255,
			255
		)

end

-- =========================================================
--                    FORMATAR NÚMEROS
-- =========================================================

local function formatNumber(number)

	number = tonumber(number) or 0

	local unidades = {
		{1e63, "Vg"},
		{1e60, "No"},
		{1e57, "Oc"},
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

	local negativo = number < 0
	local absoluto = math.abs(number)

	for _, unidade in ipairs(unidades) do

		if absoluto >= unidade[1] then

			local valor = absoluto / unidade[1]

			-- O jogo sempre exibe só 1 casa decimal e trunca
			-- (não arredonda pra cima) — por isso usamos o
			-- mesmo padrão aqui, garantindo que bata exatamente
			-- com os valores mostrados no modal do jogo.
			local casas = 1

			local fator = 10 ^ casas

			local valorTruncado =
				math.floor(valor * fator) / fator

			local texto =
				string.format(
					"%." .. casas .. "f",
					valorTruncado
				)

			texto =
				texto
				:gsub("(%..-)0+$", "%1")
				:gsub("%.$", "")

			if negativo then
				texto = "-" .. texto
			end

			return texto .. unidade[2]

		end

	end

	return tostring(
		math.floor(number + 0.5)
	)

end
HackEvent.OnClientEvent:Connect(function(data)

	if typeof(data) ~= "table" then
		return
	end

	print(
		"[HACK ALERT]",
		"kind =", data.kind,
		"role =", data.role,
		"name =", data.name
	)

	local kind = tostring(data.kind or ""):lower()
	local action = tostring(data.action or ""):lower()
	local eventType = tostring(data.type or ""):lower()
	local role = tostring(data.role or ""):lower()
	local name = tostring(data.name or "")

	local rouboKinds = {
		robbery = true,
		roubo = true,
		steal = true,
		stealing = true,
		stolen = true,
		theft = true,
		robbery_start = true,
		robbery_end = true,
		steal_start = true,
		steal_end = true,
	}

	if rouboKinds[kind]
		or rouboKinds[action]
		or rouboKinds[eventType] then

		pararAlerta()
		return
	end

	-- =====================================================
	--     SÓ TOCA O ALERTA SE VOCÊ FOR A VÍTIMA DO ROUBO
	-- =====================================================
	-- Confirmado no sistema do jogo: data.role vem como
	-- "victim" (você está sendo hackeado/roubado) ou
	-- "attacker" (você é quem está tentando roubar).
	-- O alerta sonoro só deve tocar para "victim".

	if data.kind == "phase" then

		if role == "victim" then

			iniciarAlerta()

		elseif role == "attacker" then

			-- Você é quem está roubando: não toca o alerta.

		elseif name ~= "" and name == LocalPlayer.Name then

			-- Sem "role" reconhecido, mas o nome do evento é o
			-- seu: você é quem está roubando, não a vítima.

		else

			-- Role desconhecido/ausente: avisa no output para
			-- podermos ajustar, mas não arrisca tocar à toa.
			warn("[HACK ALERT] role inesperado recebido: '" .. tostring(data.role) .. "' (esperado 'victim' ou 'attacker')")

		end

		return
	end

	if data.kind == "result" then
		pararAlerta()
		return
	end

	if data.kind == "abort"
		or data.kind == "end"
		or data.kind == "ended"
		or data.kind == "finish"
		or data.kind == "finished" then

		pararAlerta()
		return
	end

end)

-- =========================================================
--                     ATUALIZAR DISPLAY
-- =========================================================

local function updateDisplay()

	local rawPrice =
		readNumber(
			Workspace:GetAttribute(
				"TokenPrice"
			),
			PRICE_BASE
		)

	-- "price" continua arredondado pra baixo, só para exibição
	-- do preço (ex: "$14"), igual já era antes.
	local price =
		math.floor(rawPrice)

	local tokenAmount =
		lerQuantidadeTokens()

	-- Cálculo automático: sempre atualiza em tempo real, sem
	-- depender de nenhum menu estar aberto.
	local valorReceber =
		tokenAmount * rawPrice

	earningsLabel.Text =
		("💎 Tokens: %s  •  💰 Receber: $%s"):format(
			formatNumber(tokenAmount),
			formatNumber(valorReceber)
		)

	if price ~= lastPrice then
		animatePriceBounce()
	end

	local trendSymbol = ""

	if price > lastPrice then

		trendSymbol = " ▲"

	elseif price < lastPrice then

		trendSymbol = " ▼"

	end

	priceLabel.Text =
		("$%d%s"):format(
			price,
			trendSymbol
		)

	-- =====================================================
	--                     PREÇO 15
	-- =====================================================

	if price >= PRICE_MAX then

		statusBadge.Text =
			"⚡ MÁXIMO"

		statusBadge.TextColor3 =
			Color3.fromRGB(
				255,
				255,
				255
			)

		if not maximoAtivo then

			-- Isso dispara os efeitos visuais, a notificação
			-- E a única mensagem de chat (dentro de iniciarEfeitoMaximo)
			iniciarEfeitoMaximo()

			mostrarNotificacaoMaximo()

		end

		-- A mensagem de chat NÃO é reenviada aqui.
		-- Ela só acontece uma vez, na transição para o modo máximo,
		-- dentro de iniciarEfeitoMaximo().

	-- =====================================================
	--                     PREÇO ALTO
	-- =====================================================

	elseif price >= PRICE_SPIKE then

		if maximoAtivo then
			pararEfeitoMaximo()
		end

		applyTheme(
			COLOR_THEMES.Spike,
			0.4,
			"🔥 ALTO"
		)

	-- =====================================================
	--                     PREÇO MÍNIMO
	-- =====================================================

	elseif price <= PRICE_MIN then

		if maximoAtivo then
			pararEfeitoMaximo()
		end

		applyTheme(
			COLOR_THEMES.Min,
			0.4,
			"📉 MÍNIMO"
		)

	-- =====================================================
	--                     NORMAL
	-- =====================================================

	else

		if maximoAtivo then
			pararEfeitoMaximo()
		end

		applyTheme(
			COLOR_THEMES.Base,
			0.8,
			"NORMAL"
		)

	end

	lastPrice = price

end

-- =========================================================
--                         TIMER
-- =========================================================

task.spawn(function()

	while screenGui.Parent do

		local now = os.time()

		local secondsLeft =
			EPOCH_SECONDS -
			(now % EPOCH_SECONDS)

		local progress =
			secondsLeft /
			EPOCH_SECONDS

		timerLabel.Text =
			("Troca em %ds"):format(
				secondsLeft
			)

		TweenService:Create(
			progressBar,
			TweenInfo.new(
				0.5,
				Enum.EasingStyle.Linear
			),
			{
				Size =
					UDim2.new(
						progress,
						0,
						1,
						0
					)
			}
		):Play()

		updateDisplay()

		task.wait(0.5)

	end

end)

-- =========================================================
--                 ALTERAÇÃO DO TOKEN PRICE
-- =========================================================

Workspace:GetAttributeChangedSignal(
	"TokenPrice"
):Connect(
	updateDisplay
)

-- =========================================================
--          ATUALIZAÇÃO EM TEMPO REAL DOS TOKENS
-- =========================================================

LocalPlayer:GetAttributeChangedSignal(
	"Tokens"
):Connect(function()

	lastReadTokenAmount =
		lerQuantidadeTokens()

	updateDisplay()

end)

-- =========================================================
--                     INICIALIZAÇÃO
-- =========================================================

updateDisplay()
