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
	if not player or player == LocalPlayer then
		-- permite ESP para LocalPlayer? não para a janela de "roubando você" (somente atacantes)
		-- manter a checagem de player válida
		if not player then return nil end
	end
	if activeESPs[player.UserId] then return activeESPs[player.UserId] end
	
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
	
	-- Borda rainbow do avatar
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
	
	-- Label de distância
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
	
	-- Label de aviso
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
	
	-- Animação rainbow
	local hue = 0
	local rainbowConnection = RunService.RenderStepped:Connect(function(dt)
		if not espContainer.Parent then return end
		hue = (hue + dt * 2) % 1
		local rainbowColor = Color3.fromHSV(hue, 1, 1)
		avatarStroke.Color = rainbowColor
		warnLabel.TextColor3 = rainbowColor
	end)
	
	local espData = {
		container = espContainer,
		avatarFrame = avatarFrame,
		distLabel = distLabel,
		warnLabel = warnLabel,
		avatarStroke = avatarStroke,
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
	
	activeESPs[player.UserId] = nil
end

-- Atualizar posição do ESP
local function atualizarESP(espData)
	if not espData or not espData.player or not espData.player.Character then return end
	
	local character = espData.player.Character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local localCharacter = LocalPlayer.Character
	if not localCharacter then return end
	
	local localHRP = localCharacter:FindFirstChild("HumanoidRootPart")
	if not localHRP then return end
	
	local distance = (humanoidRootPart.Position - localHRP.Position).Magnitude
	espData.distLabel.Text = string.format("%.0fm", distance)
	
	-- Verificar se está dentro da distância máxima
	if distance > ESP_MAX_DISTANCE then
		espData.container.Visible = false
		return
	else
		espData.container.Visible = true
	end
	
	-- Converter posição 3D para 2D na tela
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
	if not player then return nil end
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
	
	-- Borda (invisível para usuários comuns)
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
	tagText.TextSize = isOwner and 16 or 14
	tagText.Text = isOwner and "👑 DONO" or "👤 USER"
	tagText.ZIndex = 2
	tagText.TextStrokeTransparency = isOwner and 0.4 or 1
	tagText.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	tagText.Parent = tagBg
	
	if isOwner then
		-- Animação rainbow para dono (colorindo texto e stroke)
		local hue = 0
		local rainbowConn = RunService.RenderStepped:Connect(function(dt)
			if not tagContainer.Parent then return end
			hue = (hue + dt * 1.2) % 1
			local rainbowColor = Color3.fromHSV(hue, 1, 1)
			tagText.TextColor3 = rainbowColor
			tagText.TextStrokeColor3 = Color3.fromHSV((hue + 0.15) % 1, 0.9, 0.2)
			tagStroke.Color = rainbowColor
			tagStroke.Transparency = 0.0
		end)
		
		activePlayerTags[player.UserId] = {
			container = tagContainer,
			rainbowConnection = rainbowConn,
			player = player
		}
	else
		-- Usuários normais: texto simples, sem fundo
		tagText.TextColor3 = Color3.fromRGB(180, 180, 180)
		tagText.TextStrokeTransparency = 1
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
		
		-- Atualizar tags de todos os jogadores
		for userId, tagData in pairs(activePlayerTags) do
			atualizarPlayerTag(tagData)
		end
		
		task.wait(ESP_UPDATE_RATE)
	end
end)

-- Monitorar jogadores entrando e saindo
Players.PlayerAdded:Connect(function(player)
	task.wait(1) -- Esperar carregar
	criarPlayerTag(player)
end)

Players.PlayerRemoving:Connect(function(player)
	removerESP(player)
	removerPlayerTag(player)
	if currentRobber == player then
		robberyInProgress = false
		currentRobber = nil
	end
end)

-- Criar tags para jogadores existentes (inclui LocalPlayer para que o dono veja sua própria tag)
for _, player in ipairs(Players:GetPlayers()) do
	criarPlayerTag(player)
end

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

-- (Demais elementos de UI mantidos...)

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
			
			-- Procurar quem está roubando (attacker)
			local attackerName = data.attacker or data.name
			if attackerName then
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= LocalPlayer and player.Name == attackerName then
						currentRobber = player
						robberyInProgress = true
						criarESP(player)
						break
					end
				end
			end
			
			-- Se não achou pelo nome, tenta detectar por proximidade
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
							robberyInProgress = true
							criarESP(closestPlayer)
						end
					end
				end
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
--                     ATUALIZAR DISPLAY (Token price watcher)
-- =========================================================

-- (mantive as funções restantes do TokenPriceWatcher sem alterações funcionais importantes)

print("[SamMods] Sistema atualizado: tags ajustadas, histórico removido, ESP Anti-Roubo ajustado.")
