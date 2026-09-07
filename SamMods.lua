```lua
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
--                    CONFIGURAÇÕES EXTRAS
-- =========================================================

local OWNER_USER_ID = 4290770735

local USER_TAG_TEXT = "USER"
local OWNER_TAG_TEXT = "👑 DONO"

-- =========================================================
--                    INTRO "SamMods"
-- =========================================================

do

	local introExisting = PlayerGui:FindFirstChild("SamModsIntroGui")
	if introExisting then
		introExisting:Destroy()
	end

	local INTRO_TITULO = "SamMods"
	local INTRO_SUBTITULO = "MODS ROBLOX"

	local INTRO_COR_FUNDO = Color3.fromRGB(5, 5, 8)
	local INTRO_COR_PRINCIPAL = Color3.fromRGB(255, 30, 40)
	local INTRO_COR_GLITCH_1 = Color3.fromRGB(255, 0, 60)
	local INTRO_COR_GLITCH_2 = Color3.fromRGB(0, 200, 255)

	local introGui = Instance.new("ScreenGui")
	introGui.Name = "SamModsIntroGui"
	introGui.ResetOnSpawn = false
	introGui.IgnoreGuiInset = true
	introGui.DisplayOrder = 1000
	introGui.Parent = PlayerGui

	local introBg = Instance.new("Frame")
	introBg.Name = "Background"
	introBg.Size = UDim2.fromScale(1, 1)
	introBg.BackgroundColor3 = INTRO_COR_FUNDO
	introBg.BackgroundTransparency = 0
	introBg.BorderSizePixel = 0
	introBg.ZIndex = 1
	introBg.Parent = introGui

	local introVinheta = Instance.new("ImageLabel")
	introVinheta.Name = "Vinheta"
	introVinheta.Size = UDim2.fromScale(1, 1)
	introVinheta.BackgroundTransparency = 1
	introVinheta.Image = "rbxassetid://5028857084"
	introVinheta.ImageTransparency = 0.85
	introVinheta.ScaleType = Enum.ScaleType.Stretch
	introVinheta.ZIndex = 2
	introVinheta.Parent = introBg

	local introTitleContainer = Instance.new("Frame")
	introTitleContainer.Name = "TitleContainer"
	introTitleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	introTitleContainer.Position = UDim2.new(0.5, 0, 0.42, 0)
	introTitleContainer.Size = UDim2.fromOffset(700, 160)
	introTitleContainer.BackgroundTransparency = 1
	introTitleContainer.ZIndex = 5
	introTitleContainer.Parent = introBg

	local introGlitchRed = Instance.new("TextLabel")
	introGlitchRed.Name = "GlitchRed"
	introGlitchRed.Size = UDim2.fromScale(1, 1)
	introGlitchRed.BackgroundTransparency = 1
	introGlitchRed.Font = Enum.Font.GothamBlack
	introGlitchRed.TextSize = 72
	introGlitchRed.TextColor3 = INTRO_COR_GLITCH_1
	introGlitchRed.TextTransparency = 1
	introGlitchRed.Text = INTRO_TITULO
	introGlitchRed.ZIndex = 4
	introGlitchRed.Parent = introTitleContainer

	local introGlitchBlue = Instance.new("TextLabel")
	introGlitchBlue.Name = "GlitchBlue"
	introGlitchBlue.Size = UDim2.fromScale(1, 1)
	introGlitchBlue.BackgroundTransparency = 1
	introGlitchBlue.Font = Enum.Font.GothamBlack
	introGlitchBlue.TextSize = 72
	introGlitchBlue.TextColor3 = INTRO_COR_GLITCH_2
	introGlitchBlue.TextTransparency = 1
	introGlitchBlue.Text = INTRO_TITULO
	introGlitchBlue.ZIndex = 4
	introGlitchBlue.Parent = introTitleContainer

	local introTitleMain = Instance.new("TextLabel")
	introTitleMain.Name = "MainTitle"
	introTitleMain.Size = UDim2.fromScale(1, 1)
	introTitleMain.BackgroundTransparency = 1
	introTitleMain.Font = Enum.Font.GothamBlack
	introTitleMain.TextSize = 72
	introTitleMain.TextColor3 = Color3.fromRGB(255, 255, 255)
	introTitleMain.TextTransparency = 1
	introTitleMain.TextStrokeTransparency = 1
	introTitleMain.TextStrokeColor3 = INTRO_COR_PRINCIPAL
	introTitleMain.Text = INTRO_TITULO
	introTitleMain.ZIndex = 6
	introTitleMain.Parent = introTitleContainer

	local introTitleGlow = Instance.new("TextLabel")
	introTitleGlow.Name = "Glow"
	introTitleGlow.Size = UDim2.fromScale(1, 1)
	introTitleGlow.BackgroundTransparency = 1
	introTitleGlow.Font = Enum.Font.GothamBlack
	introTitleGlow.TextSize = 74
	introTitleGlow.TextColor3 = INTRO_COR_PRINCIPAL
	introTitleGlow.TextTransparency = 1
	introTitleGlow.Text = INTRO_TITULO
	introTitleGlow.ZIndex = 3
	introTitleGlow.Parent = introTitleContainer

	local introSubtitle = Instance.new("TextLabel")
	introSubtitle.Name = "Subtitle"
	introSubtitle.AnchorPoint = Vector2.new(0.5, 0)
	introSubtitle.Position = UDim2.new(0.5, 0, 1, 6)
	introSubtitle.Size = UDim2.new(1, 0, 0, 28)
	introSubtitle.BackgroundTransparency = 1
	introSubtitle.Font = Enum.Font.Gotham
	introSubtitle.TextSize = 18
	introSubtitle.TextColor3 = Color3.fromRGB(200, 200, 205)
	introSubtitle.TextTransparency = 1
	introSubtitle.Text = INTRO_SUBTITULO
	introSubtitle.TextXAlignment = Enum.TextXAlignment.Center
	introSubtitle.ZIndex = 6
	introSubtitle.Parent = introTitleContainer

	local introLinha = Instance.new("Frame")
	introLinha.Name = "Linha"
	introLinha.AnchorPoint = Vector2.new(0.5, 0)
	introLinha.Position = UDim2.new(0.5, 0, 1, 40)
	introLinha.Size = UDim2.new(0, 0, 0, 2)
	introLinha.BackgroundColor3 = INTRO_COR_PRINCIPAL
	introLinha.BackgroundTransparency = 0.3
	introLinha.BorderSizePixel = 0
	introLinha.ZIndex = 6
	introLinha.Parent = introTitleContainer

	local introLoadingContainer = Instance.new("Frame")
	introLoadingContainer.Name = "LoadingContainer"
	introLoadingContainer.AnchorPoint = Vector2.new(0.5, 1)
	introLoadingContainer.Position = UDim2.new(0.5, 0, 1, -70)
	introLoadingContainer.Size = UDim2.fromOffset(360, 40)
	introLoadingContainer.BackgroundTransparency = 1
	introLoadingContainer.ZIndex = 5
	introLoadingContainer.Parent = introBg

	local introLoadingLabel = Instance.new("TextLabel")
	introLoadingLabel.Name = "LoadingLabel"
	introLoadingLabel.Size = UDim2.new(1, 0, 0, 16)
	introLoadingLabel.BackgroundTransparency = 1
	introLoadingLabel.Font = Enum.Font.GothamMedium
	introLoadingLabel.TextSize = 12
	introLoadingLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
	introLoadingLabel.TextTransparency = 1
	introLoadingLabel.Text = "CARREGANDO..."
	introLoadingLabel.TextXAlignment = Enum.TextXAlignment.Left
	introLoadingLabel.ZIndex = 6
	introLoadingLabel.Parent = introLoadingContainer

	local introLoadingPercent = Instance.new("TextLabel")
	introLoadingPercent.Name = "LoadingPercent"
	introLoadingPercent.Size = UDim2.new(1, 0, 0, 16)
	introLoadingPercent.BackgroundTransparency = 1
	introLoadingPercent.Font = Enum.Font.GothamBold
	introLoadingPercent.TextSize = 12
	introLoadingPercent.TextColor3 = INTRO_COR_PRINCIPAL
	introLoadingPercent.TextTransparency = 1
	introLoadingPercent.Text = "0%"
	introLoadingPercent.TextXAlignment = Enum.TextXAlignment.Right
	introLoadingPercent.ZIndex = 6
	introLoadingPercent.Parent = introLoadingContainer

	local introBarBg = Instance.new("Frame")
	introBarBg.Name = "BarBackground"
	introBarBg.Position = UDim2.new(0, 0, 0, 22)
	introBarBg.Size = UDim2.new(1, 0, 0, 4)
	introBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	introBarBg.BackgroundTransparency = 1
	introBarBg.BorderSizePixel = 0
	introBarBg.ZIndex = 5
	introBarBg.Parent = introLoadingContainer

	local introBarBgCorner = Instance.new("UICorner")
	introBarBgCorner.CornerRadius = UDim.new(1, 0)
	introBarBgCorner.Parent = introBarBg

	local introBarFill = Instance.new("Frame")
	introBarFill.Name = "BarFill"
	introBarFill.Size = UDim2.new(0, 0, 1, 0)
	introBarFill.BackgroundColor3 = INTRO_COR_PRINCIPAL
	introBarFill.BorderSizePixel = 0
	introBarFill.ZIndex = 6
	introBarFill.Parent = introBarBg

	local introBarFillCorner = Instance.new("UICorner")
	introBarFillCorner.CornerRadius = UDim.new(1, 0)
	introBarFillCorner.Parent = introBarFill

	local introBarGlow = Instance.new("UIStroke")
	introBarGlow.Color = INTRO_COR_PRINCIPAL
	introBarGlow.Thickness = 1.5
	introBarGlow.Transparency = 0.5
	introBarGlow.Parent = introBarFill

	local introParticleContainer = Instance.new("Frame")
	introParticleContainer.Name = "Particles"
	introParticleContainer.Size = UDim2.fromScale(1, 1)
	introParticleContainer.BackgroundTransparency = 1
	introParticleContainer.ZIndex = 2
	introParticleContainer.Parent = introBg

	local introParticles = {}

	for i = 1, 24 do

		local p = Instance.new("Frame")
		p.Name = "P" .. i
		p.Size = UDim2.fromOffset(math.random(1, 3), math.random(1, 3))
		p.Position = UDim2.new(math.random(), 0, math.random(), 0)
		p.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		p.BackgroundTransparency = 1
		p.BorderSizePixel = 0
		p.ZIndex = 2
		p.Parent = introParticleContainer

		table.insert(introParticles, p)

	end

	local introScanline = Instance.new("Frame")
	introScanline.Name = "Scanline"
	introScanline.Size = UDim2.new(1, 0, 0, 2)
	introScanline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	introScanline.BackgroundTransparency = 1
	introScanline.BorderSizePixel = 0
	introScanline.ZIndex = 7
	introScanline.Parent = introBg

	local function introTween(obj, props, time, style, dir)
		return TweenService:Create(
			obj,
			TweenInfo.new(
				time or 0.3,
				style or Enum.EasingStyle.Quad,
				dir or Enum.EasingDirection.Out
			),
			props
		)
	end

	local function introFlickerIn(obj, tempoTotal)

		tempoTotal = tempoTotal or 0.9

		task.spawn(function()

			local passos = {
				{0, 0.05}, {1, 0.03}, {0.2, 0.05}, {1, 0.04},
				{0, 0.06}, {0.6, 0.05}, {0, 0.07}, {1, 0.05},
				{0.1, 0.05}, {0, 0.09},
			}

			for _, passo in ipairs(passos) do

				obj.TextTransparency = passo[1]
				task.wait(passo[2])

			end

			introTween(obj, {TextTransparency = 0}, 0.15):Play()

		end)

	end

	local function rodarIntroSamMods()

		introBg.BackgroundTransparency = 0
		introVinheta.ImageTransparency = 1

		introTween(introVinheta, {ImageTransparency = 0.8}, 1.2):Play()

		for i, p in ipairs(introParticles) do

			task.delay(i * 0.02, function()

				introTween(p, {BackgroundTransparency = math.random(60, 85) / 100}, 0.6):Play()

				task.spawn(function()

					while p.Parent do

						local destino = UDim2.new(
							p.Position.X.Scale,
							0,
							p.Position.Y.Scale - 0.15,
							0
						)

						local t = introTween(p, {Position = destino}, math.random(4, 8), Enum.EasingStyle.Linear)
						t:Play()
						t.Completed:Wait()

						p.Position = UDim2.new(math.random(), 0, 1.05, 0)

					end

				end)

			end)

		end

		task.wait(0.5)

		introScanline.Position = UDim2.new(0, 0, -0.05, 0)
		introScanline.BackgroundTransparency = 0.4

		introTween(introScanline, {Position = UDim2.new(0, 0, 1.05, 0)}, 0.5, Enum.EasingStyle.Linear):Play()

		task.wait(0.55)
		introScanline.BackgroundTransparency = 1

		introGlitchRed.TextTransparency = 0.6
		introGlitchBlue.TextTransparency = 0.6

		task.spawn(function()

			local tempoFim = os.clock() + 1.0

			while os.clock() < tempoFim do

				introGlitchRed.Position = UDim2.fromOffset(
					math.random(-6, 6), math.random(-3, 3)
				)

				introGlitchBlue.Position = UDim2.fromOffset(
					math.random(-6, 6), math.random(-3, 3)
				)

				task.wait(0.04)

			end

			introGlitchRed.Position = UDim2.fromOffset(2, 0)
			introGlitchBlue.Position = UDim2.fromOffset(-2, 0)

			introTween(introGlitchRed, {TextTransparency = 0.85}, 0.3):Play()
			introTween(introGlitchBlue, {TextTransparency = 0.85}, 0.3):Play()

		end)

		introTween(introTitleGlow, {TextTransparency = 0.55}, 0.4):Play()

		task.spawn(function()

			while introTitleGlow.Parent do

				introTween(introTitleGlow, {TextTransparency = 0.35}, 0.8, Enum.EasingStyle.Sine):Play()
				task.wait(0.8)
				introTween(introTitleGlow, {TextTransparency = 0.6}, 0.8, Enum.EasingStyle.Sine):Play()
				task.wait(0.8)

			end

		end)

		task.wait(0.2)
		introFlickerIn(introTitleMain, 0.9)
		introTween(introTitleMain, {TextStrokeTransparency = 0.4}, 1.0):Play()

		task.wait(1.0)

		introTween(introLinha, {Size = UDim2.new(0, 220, 0, 2)}, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()

		task.wait(0.3)

		introTween(introSubtitle, {TextTransparency = 0.15}, 0.5):Play()

		task.wait(0.4)

		introTween(introLoadingLabel, {TextTransparency = 0.3}, 0.4):Play()
		introTween(introLoadingPercent, {TextTransparency = 0}, 0.4):Play()
		introTween(introBarBg, {BackgroundTransparency = 0.5}, 0.4):Play()

		task.wait(0.2)

		local duracaoCarregamento = 1.8
		local inicio = os.clock()

		while os.clock() - inicio < duracaoCarregamento do

			local progresso = (os.clock() - inicio) / duracaoCarregamento
			progresso = math.min(1, progresso)

			introBarFill.Size = UDim2.new(progresso, 0, 1, 0)
			introLoadingPercent.Text = ("%d%%"):format(math.floor(progresso * 100))

			task.wait(0.02)

		end

		introBarFill.Size = UDim2.new(1, 0, 1, 0)
		introLoadingPercent.Text = "100%"

		task.wait(0.4)

		introTween(introLoadingLabel, {TextTransparency = 1}, 0.3):Play()
		introTween(introLoadingPercent, {TextTransparency = 1}, 0.3):Play()
		introTween(introBarBg, {BackgroundTransparency = 1}, 0.3):Play()
		introTween(introBarFill, {BackgroundTransparency = 1}, 0.3):Play()
		introTween(introSubtitle, {TextTransparency = 1}, 0.3):Play()
		introTween(introLinha, {BackgroundTransparency = 1}, 0.3):Play()
		introTween(introTitleMain, {TextTransparency = 1, TextStrokeTransparency = 1}, 0.5):Play()
		introTween(introTitleGlow, {TextTransparency = 1}, 0.5):Play()
		introTween(introGlitchRed, {TextTransparency = 1}, 0.5):Play()
		introTween(introGlitchBlue, {TextTransparency = 1}, 0.5):Play()

		task.wait(0.5)

		introTween(introBg, {BackgroundTransparency = 1}, 0.8):Play()

		task.wait(0.9)

		introGui:Destroy()

	end

	task.spawn(rodarIntroSamMods)

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

	if not texto then
		return nil
	end

	local numeroStr, sufixo =
		texto:match("(%-?%d+[%.,]?%d*)%s*(%a*)")

	if not numeroStr then
		return nil
	end

	numeroStr = numeroStr:gsub(",", ".")

	local numero = tonumber(numeroStr)

	if not numero then
		return nil
	end

	local multiplicador = UNIDADES_REVERSO[sufixo]

	if multiplicador then
		return numero * multiplicador
	end

	if sufixo == "" or sufixo == nil then
		return numero
	end

	return nil

end

local lastReadTokenAmount = nil

local function lerQuantidadeTokens()

	if tokensLabel and tokensLabel.Parent then

		local valor = parseValorAbreviado(tokensLabel.Text)

		if valor then
			return valor
		end

	end

	return tonumber(LocalPlayer:GetAttribute("Tokens")) or 0

end

-- =========================================================
--              PROTEÇÃO CONTRA MÚLTIPLAS INSTÂNCIAS
-- =========================================================

local INSTANCE_MARKER_NAME = "TokenPriceWatcher_Instance"

local existingInstance =
	PlayerGui:FindFirstChild(INSTANCE_MARKER_NAME)

if existingInstance then
	warn("[TokenPriceWatcher] Outra instância já está ativa. Esta instância foi bloqueada.")
	script:Destroy()
	return
end

local instanceMarker =
	Instance.new("BoolValue")

instanceMarker.Name =
	INSTANCE_MARKER_NAME

instanceMarker.Value =
	true

instanceMarker.Parent =
	PlayerGui

script.Destroying:Connect(function()

	if instanceMarker
		and instanceMarker.Parent then

		instanceMarker:Destroy()

	end

end)

-- =========================================================
--                     LIMPEZA AUTOMÁTICA
-- =========================================================

local existingGui =
	PlayerGui:FindFirstChild("TokenPriceWatcherGui")

if existingGui then
	existingGui:Destroy()
end

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

local PRICE_MIN = math.floor(
	readNumber(Config.Tokens.priceMin, 5)
)

local PRICE_MAX = math.floor(
	readNumber(Config.Tokens.priceMax, 15)
)

local PRICE_SPIKE = math.floor(
	readNumber(Config.Tokens.spikePrice, 12)
)

local PRICE_BASE = math.floor(
	readNumber(Config.Tokens.basePrice, 10)
)

local EPOCH_SECONDS = math.max(
	1,
	math.floor(
		readNumber(Config.Tokens.priceEpochSeconds, 30)
	)
)

local COLOR_THEMES = {
	Min = Color3.fromRGB(80, 220, 120),
	Base = Color3.fromRGB(0, 170, 255),
	Spike = Color3.fromRGB(255, 130, 40),
	Max = Color3.fromRGB(255, 200, 0)
}

-- =========================================================
--                       SISTEMA DE TAGS
-- =========================================================
-- DONO:
--   UserId fixo 4290770735.
--
-- USER:
--   O próprio jogador recebe USER enquanto este LocalScript
--   estiver executando.
--
-- IMPORTANTE:
--   Uma marca criada somente por LocalScript não replica para
--   os outros clientes. Portanto, sem uma informação vinda do
--   servidor, não é possível saber com segurança quais OUTROS
--   jogadores executaram o painel.
--
-- O sistema abaixo deixa a estrutura pronta e também aceita
-- atributos replicados pelo servidor, caso existam:
--   SamModsUser
--   SamModsUsingPanel
--   TokenPriceWatcher_User
-- =========================================================

local tagConnections = {}
local tagObjects = {}
local tagRainbowConnections = {}

local function desconectarTag(player)

	if tagConnections[player] then

		for _, connection in ipairs(tagConnections[player]) do

			if connection then
				connection:Disconnect()
			end

		end

		tagConnections[player] = nil

	end

	if tagRainbowConnections[player] then

		tagRainbowConnections[player]:Disconnect()
		tagRainbowConnections[player] = nil

	end

end

local function removerTag(player)

	desconectarTag(player)

	local character = player.Character

	if character then

		local existente =
			character:FindFirstChild("SamModsHeadTag")

		if existente then
			existente:Destroy()
		end

	end

	tagObjects[player] = nil

end

local function jogadorEhUser(player)

	if player.UserId == OWNER_USER_ID then
		return false
	end

	if player == LocalPlayer then
		return true
	end

	local atributos = {
		player:GetAttribute("SamModsUser"),
		player:GetAttribute("SamModsUsingPanel"),
		player:GetAttribute("TokenPriceWatcher_User"),
	}

	for _, valor in ipairs(atributos) do

		if valor == true then
			return true
		end

	end

	return false

end

local function criarTag(player)

	if not player or not player.Parent then
		return
	end

	local character = player.Character

	if not character then
		return
	end

	local head =
		character:FindFirstChild("Head")

	if not head then
		return
	end

	local isOwner =
		player.UserId == OWNER_USER_ID

	local isUser =
		jogadorEhUser(player)

	if not isOwner and not isUser then

		removerTag(player)
		return

	end

	local old =
		character:FindFirstChild("SamModsHeadTag")

	if old then
		old:Destroy()
	end

	desconectarTag(player)

	local billboard =
		Instance.new("BillboardGui")

	billboard.Name =
		"SamModsHeadTag"

	billboard.Adornee =
		head

	billboard.AlwaysOnTop =
		true

	billboard.LightInfluence =
		0

	billboard.MaxDistance =
		250

	billboard.Size =
		UDim2.fromOffset(
			180,
			48
		)

	billboard.StudsOffset =
		Vector3.new(
			0,
			3.25,
			0
		)

	billboard.Parent =
		character

	local container =
		Instance.new("Frame")

	container.Name =
		"Container"

	container.Size =
		UDim2.fromScale(
			1,
			1
		)

	container.BackgroundTransparency =
		1

	container.BorderSizePixel =
		0

	container.Parent =
		billboard

	local text =
		Instance.new("TextLabel")

	text.Name =
		"Tag"

	text.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	text.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	text.Size =
		UDim2.fromScale(
			1,
			1
		)

	text.BackgroundTransparency =
		1

	text.BorderSizePixel =
		0

	text.Font =
		Enum.Font.GothamBlack

	text.TextScaled =
		true

	text.TextStrokeTransparency =
		0.15

	text.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)

	text.Text =
		isOwner and OWNER_TAG_TEXT or USER_TAG_TEXT

	text.Parent =
		container

	tagObjects[player] =
		billboard

	local hue = math.random()

	tagRainbowConnections[player] =
		RunService.RenderStepped:Connect(function(dt)

			if not billboard.Parent
				or not text.Parent then

				return

			end

			hue =
				(hue + dt * 0.45) % 1

			text.TextColor3 =
				Color3.fromHSV(
					hue,
					1,
					1
				)

			text.TextStrokeColor3 =
				Color3.fromHSV(
					(hue + 0.5) % 1,
					0.8,
					0.25
				)

		end)

	tagConnections[player] = {}

	table.insert(
		tagConnections[player],
		player.CharacterAdded:Connect(function()

			task.wait(0.5)

			criarTag(player)

		end)
	)

	table.insert(
		tagConnections[player],
		player:GetAttributeChangedSignal("SamModsUser"):Connect(function()
			criarTag(player)
		end)
	)

	table.insert(
		tagConnections[player],
		player:GetAttributeChangedSignal("SamModsUsingPanel"):Connect(function()
			criarTag(player)
		end)
	)

	table.insert(
		tagConnections[player],
		player:GetAttributeChangedSignal("TokenPriceWatcher_User"):Connect(function()
			criarTag(player)
		end)
	)

end

local function atualizarTagPlayer(player)

	if not player or not player.Parent then
		return
	end

	if player.Character then
		criarTag(player)
	end

end

local function iniciarSistemaTags()

	for _, player in ipairs(Players:GetPlayers()) do

		task.spawn(function()

			if player.Character then
				criarTag(player)
			end

			local connection =
				player.CharacterAdded:Connect(function()

					task.wait(0.5)
					criarTag(player)

				end)

			if not tagConnections[player] then
				tagConnections[player] = {}
			end

			table.insert(
				tagConnections[player],
				connection
			)

		end)

	end

	Players.PlayerAdded:Connect(function(player)

		player.CharacterAdded:Connect(function()

			task.wait(0.5)
			criarTag(player)

		end)

		if player.Character then
			task.wait(0.5)
			criarTag(player)
		end

	end)

	Players.PlayerRemoving:Connect(function(player)

		removerTag(player)

	end)

end

-- =========================================================
--                    SISTEMA DE ROUBO
-- =========================================================

local robberyIndicatorObjects = {}
local robberyConnections = {}
local robberyRainbowConnections = {}

local robberyTargetPlayer = nil

local function desconectarRobbery(player)

	if robberyConnections[player] then

		for _, connection in ipairs(robberyConnections[player]) do

			if connection then
				connection:Disconnect()
			end

		end

		robberyConnections[player] = nil

	end

	if robberyRainbowConnections[player] then

		robberyRainbowConnections[player]:Disconnect()
		robberyRainbowConnections[player] = nil

	end

end

local function removerIndicadorRoubo(player)

	if not player then
		return
	end

	desconectarRobbery(player)

	local character =
		player.Character

	if character then

		local indicador =
			character:FindFirstChild(
				"SamModsRobberyIndicator"
			)

		if indicador then
			indicador:Destroy()
		end

	end

	robberyIndicatorObjects[player] = nil

	if robberyTargetPlayer == player then
		robberyTargetPlayer = nil
	end

end

local function obterPlayerPorNome(nome)

	if not nome or nome == "" then
		return nil
	end

	local alvo =
		Players:FindFirstChild(nome)

	if alvo then
		return alvo
	end

	local nomeLower =
		tostring(nome):lower()

	for _, player in ipairs(Players:GetPlayers()) do

		if player.Name:lower() == nomeLower
			or player.DisplayName:lower() == nomeLower then

			return player

		end

	end

	return nil

end

local function obterNumero(data, ...)
	local campos = {...}

	for _, campo in ipairs(campos) do

		local valor =
			data[campo]

		if typeof(valor) == "number" then
			return valor
		end

		if typeof(valor) == "string" then

			local numero =
				tonumber(valor)

			if numero then
				return numero
			end

		end

	end

	return nil
end

local function obterNomeJogador(data, ...)

	local campos = {...}

	for _, campo in ipairs(campos) do

		local valor =
			data[campo]

		if typeof(valor) == "string"
			and valor ~= "" then

			return valor

		end

	end

	return nil

end

local function obterPlayerDoRoubo(data, role)

	-- Caso o servidor envie UserId diretamente.
	local userId =
		obterNumero(
			data,
			"robberUserId",
			"attackerUserId",
			"thiefUserId",
			"ladrãoUserId",
			"robberId",
			"attackerId",
			"thiefId"
		)

	if userId then

		local player =
			Players:GetPlayerByUserId(
				math.floor(userId)
			)

		if player then
			return player
		end

	end

	-- Caso o servidor envie o nome do ladrão.
	local nomeLadrao =
		obterNomeJogador(
			data,
			"robberName",
			"attackerName",
			"thiefName",
			"ladrãoName",
			"robber",
			"attacker",
			"thief"
		)

	if nomeLadrao then

		local player =
			obterPlayerPorNome(
				nomeLadrao
			)

		if player then
			return player
		end

	end

	-- No evento "phase", o comportamento original usa
	-- data.name. Quando somos a vítima, normalmente esse
	-- nome representa o outro participante.
	if role == "victim" then

		local outroNome =
			obterNomeJogador(
				data,
				"name",
				"playerName",
				"targetName"
			)

		if outroNome then

			local player =
				obterPlayerPorNome(
					outroNome
				)

			if player
				and player ~= LocalPlayer then

				return player

			end

		end

	end

	-- Se este cliente recebeu o evento como atacante,
	-- o próprio jogador é o ladrão.
	if role == "attacker" then

		return LocalPlayer

	end

	return nil

end

local function criarIndicadorRoubo(player)

	if not player
		or not player.Parent then

		return

	end

	local character =
		player.Character

	if not character then
		return
	end

	local head =
		character:FindFirstChild("Head")

	if not head then
		return
	end

	removerIndicadorRoubo(player)

	local billboard =
		Instance.new("BillboardGui")

	billboard.Name =
		"SamModsRobberyIndicator"

	billboard.Adornee =
		head

	billboard.AlwaysOnTop =
		true

	billboard.LightInfluence =
		0

	billboard.MaxDistance =
		300

	billboard.Size =
		UDim2.fromOffset(
			240,
			82
		)

	billboard.StudsOffset =
		Vector3.new(
			0,
			4.4,
			0
		)

	billboard.Parent =
		character

	local container =
		Instance.new("Frame")

	container.Name =
		"Container"

	container.Size =
		UDim2.fromScale(
			1,
			1
		)

	container.BackgroundTransparency =
		1

	container.Parent =
		billboard

	local avatar =
		Instance.new("ImageLabel")

	avatar.Name =
		"Avatar"

	avatar.AnchorPoint =
		Vector2.new(
			0,
			0.5
		)

	avatar.Position =
		UDim2.new(
			0,
			2,
			0.5,
			0
		)

	avatar.Size =
		UDim2.fromOffset(
			48,
			48
		)

	avatar.BackgroundTransparency =
		1

	avatar.Parent =
		container

	local avatarCorner =
		Instance.new("UICorner")

	avatarCorner.CornerRadius =
		UDim.new(
			1,
			0
		)

	avatarCorner.Parent =
		avatar

	local avatarStroke =
		Instance.new("UIStroke")

	avatarStroke.Thickness =
		2

	avatarStroke.Parent =
		avatar

	local content =
		Instance.new("Frame")

	content.Name =
		"Content"

	content.Position =
		UDim2.new(
			0,
			55,
			0,
			0
		)

	content.Size =
		UDim2.new(
			1,
			-55,
			1,
			0
		)

	content.BackgroundTransparency =
		1

	content.Parent =
		container

	local robberyText =
		Instance.new("TextLabel")

	robberyText.Name =
		"RobberyText"

	robberyText.Size =
		UDim2.new(
			1,
			0,
			0,
			25
		)

	robberyText.BackgroundTransparency =
		1

	robberyText.Font =
		Enum.Font.GothamBlack

	robberyText.TextScaled =
		true

	robberyText.Text =
		"🔴 ROUBANDO"

	robberyText.TextStrokeTransparency =
		0.1

	robberyText.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)

	robberyText.Parent =
		content

	local nameText =
		Instance.new("TextLabel")

	nameText.Name =
		"Name"

	nameText.Position =
		UDim2.new(
			0,
			0,
			0,
			25
		)

	nameText.Size =
		UDim2.new(
			1,
			0,
			0,
			19
		)

	nameText.BackgroundTransparency =
		1

	nameText.Font =
		Enum.Font.GothamBold

	nameText.TextSize =
		13

	nameText.Text =
		player.DisplayName

	nameText.TextStrokeTransparency =
		0.2

	nameText.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)

	nameText.Parent =
		content

	local distanceText =
		Instance.new("TextLabel")

	distanceText.Name =
		"Distance"

	distanceText.Position =
		UDim2.new(
			0,
			0,
			0,
			44
		)

	distanceText.Size =
		UDim2.new(
			1,
			0,
			0,
			17
		)

	distanceText.BackgroundTransparency =
		1

	distanceText.Font =
		Enum.Font.GothamBold

	distanceText.TextSize =
		11

	distanceText.Text =
		"Distância: --"

	distanceText.TextStrokeTransparency =
		0.2

	distanceText.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)

	distanceText.Parent =
		content

	local ok,
		thumbnail =
		pcall(function()

			return Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)

		end)

	if ok and thumbnail then
		avatar.Image =
			thumbnail
	end

	robberyIndicatorObjects[player] =
		billboard

	robberyConnections[player] = {}

	table.insert(
		robberyConnections[player],
		player.CharacterAdded:Connect(function()

			task.wait(0.3)

			if robberyTargetPlayer == player then
				criarIndicadorRoubo(player)
			end

		end)
	)

	local hue =
		math.random()

	robberyRainbowConnections[player] =
		RunService.RenderStepped:Connect(function(dt)

			if not billboard.Parent then
				return
			end

			hue =
				(hue + dt * 0.6) % 1

			local cor =
				Color3.fromHSV(
					hue,
					1,
					1
				)

			robberyText.TextColor3 =
				cor

			nameText.TextColor3 =
				Color3.fromHSV(
					(hue + 0.15) % 1,
					0.85,
					1
				)

			distanceText.TextColor3 =
				Color3.fromHSV(
					(hue + 0.3) % 1,
					0.85,
					1
				)

			avatarStroke.Color =
				Color3.fromHSV(
					(hue + 0.5) % 1,
					1,
					1
				)

			local myCharacter =
				LocalPlayer.Character

			local targetCharacter =
				player.Character

			local myRoot =
				myCharacter
				and myCharacter:FindFirstChild("HumanoidRootPart")

			local targetRoot =
				targetCharacter
				and targetCharacter:FindFirstChild("HumanoidRootPart")

			if myRoot and targetRoot then

				local distancia =
					(myRoot.Position - targetRoot.Position).Magnitude

				distanceText.Text =
					("Distância: %dm"):format(
						math.floor(distancia + 0.5)
					)

			else

				distanceText.Text =
					"Distância: --"

			end

		end)

end

local function iniciarIndicadorRoubo(player)

	if not player then
		return
	end

	robberyTargetPlayer =
		player

	criarIndicadorRoubo(player)

end

local function pararIndicadorRoubo()

	local alvo =
		robberyTargetPlayer

	robberyTargetPlayer =
		nil

	if alvo then
		removerIndicadorRoubo(alvo)
	end

	for player in pairs(robberyIndicatorObjects) do

		if player ~= alvo then
			removerIndicadorRoubo(player)
		end

	end

end

-- =========================================================
--                         HACK ALERT
-- =========================================================

local AlertSound =
	SoundService:FindFirstChild(
		"HackAlertSound"
	)

if not AlertSound then

	AlertSound =
		Instance.new("Sound")

	AlertSound.Name =
		"HackAlertSound"

	AlertSound.SoundId =
		"rbxassetid://5348162330"

	AlertSound.Volume =
		3

	AlertSound.Looped =
		true

	AlertSound.Parent =
		SoundService

end

AlertSound.Volume =
	3

local alertaAtivo =
	false

local function iniciarAlerta()

	if alertaAtivo then
		return
	end

	alertaAtivo =
		true

	AlertSound:Stop()
	AlertSound.TimePosition =
		0

	AlertSound:Play()

	print("[HACK ALERT] ALERTA INICIADO")

end

local function pararAlerta()

	if not alertaAtivo then
		return
	end

	alertaAtivo =
		false

	AlertSound:Stop()
	AlertSound.TimePosition =
		0

	print("[HACK ALERT] ALERTA ENCERRADO")

end

-- =========================================================
--                         UI PRINCIPAL
-- =========================================================

local screenGui =
	Instance.new("ScreenGui")

screenGui.Name =
	"TokenPriceWatcherGui"

screenGui.ResetOnSpawn =
	false

screenGui.IgnoreGuiInset =
	true

screenGui.DisplayOrder =
	10

screenGui.Parent =
	PlayerGui

-- =========================================================
--                         AURA EXTERNA
-- =========================================================

local aura =
	Instance.new("Frame")

aura.Name =
	"MaxAura"

aura.AnchorPoint =
	Vector2.new(
		1,
		0
	)

aura.Position =
	UDim2.new(
		1,
		-16,
		0,
		110
	)

aura.Size =
	UDim2.fromOffset(
		150,
		54
	)

aura.BackgroundTransparency =
	1

aura.BorderSizePixel =
	0

aura.Visible =
	false

aura.Parent =
	screenGui

local auraCorner =
	Instance.new("UICorner")

auraCorner.CornerRadius =
	UDim.new(
		0,
		12
	)

auraCorner.Parent =
	aura

local auraStroke =
	Instance.new("UIStroke")

auraStroke.Thickness =
	5

auraStroke.Transparency =
	0.75

auraStroke.Parent =
	aura

-- =========================================================
--                         CARD
-- =========================================================

local card =
	Instance.new("TextButton")

card.Name =
	"PriceCard"

card.AnchorPoint =
	Vector2.new(
		1,
		0
	)

card.Position =
	UDim2.new(
		1,
		-16,
		0,
		110
	)

card.Size =
	UDim2.fromOffset(
		150,
		54
	)

card.BackgroundColor3 =
	Color3.fromRGB(
		18,
		20,
		26
	)

card.BackgroundTransparency =
	0.25

card.BorderSizePixel =
	0

card.AutoButtonColor =
	false

card.Text =
	""

card.Parent =
	screenGui

local cardCorner =
	Instance.new("UICorner")

cardCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

cardCorner.Parent =
	card

local cardStroke =
	Instance.new("UIStroke")

cardStroke.Color =
	COLOR_THEMES.Base

cardStroke.Transparency =
	0.8

cardStroke.Thickness =
	1.2

cardStroke.Parent =
	card

local cardPadding =
	Instance.new("UIPadding")

cardPadding.PaddingTop =
	UDim.new(
		0,
		3
	)

cardPadding.PaddingBottom =
	UDim.new(
		0,
		3
	)

cardPadding.PaddingLeft =
	UDim.new(
		0,
		8
	)

cardPadding.PaddingRight =
	UDim.new(
		0,
		8
	)

cardPadding.Parent =
	card

-- =========================================================
--                     BRILHO INTERNO
-- =========================================================

local shine =
	Instance.new("Frame")

shine.Name =
	"Shine"

shine.BackgroundColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

shine.BackgroundTransparency =
	1

shine.BorderSizePixel =
	0

shine.Position =
	UDim2.new(
		-0.5,
		0,
		0,
		0
	)

shine.Size =
	UDim2.new(
		0.35,
		0,
		1,
		0
	)

shine.Rotation =
	15

shine.Parent =
	card

local shineGradient =
	Instance.new("UIGradient")

shineGradient.Transparency =
	NumberSequence.new({
		NumberSequenceKeypoint.new(
			0,
			1
		),
		NumberSequenceKeypoint.new(
			0.5,
			0.4
		),
		NumberSequenceKeypoint.new(
			1,
			1
		)
	})

shineGradient.Parent =
	shine

-- =========================================================
--                     PREÇO
-- =========================================================

local priceLabel =
	Instance.new("TextLabel")

priceLabel.Name =
	"PriceLabel"

priceLabel.BackgroundTransparency =
	1

priceLabel.Position =
	UDim2.new(
		0,
		0,
		0,
		3
	)

priceLabel.Size =
	UDim2.new(
		0,
		80,
		0,
		18
	)

priceLabel.Font =
	Enum.Font.GothamBold

priceLabel.TextSize =
	15

priceLabel.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

priceLabel.TextXAlignment =
	Enum.TextXAlignment.Left

priceLabel.Text =
	("$%d"):format(
		PRICE_BASE
	)

priceLabel.ZIndex =
	5

priceLabel.Parent =
	card

-- =========================================================
--                  TOKENS / VALOR A RECEBER
-- =========================================================

local earningsLabel =
	Instance.new("TextLabel")

earningsLabel.Name =
	"EarningsLabel"

earningsLabel.BackgroundTransparency =
	1

earningsLabel.Position =
	UDim2.new(
		0,
		0,
		0,
		21
	)

earningsLabel.Size =
	UDim2.new(
		1,
		0,
		0,
		10
	)

earningsLabel.Font =
	Enum.Font.GothamBold

earningsLabel.TextSize =
	9

earningsLabel.TextColor3 =
	Color3.fromRGB(
		220,
		225,
		235
	)

earningsLabel.TextXAlignment =
	Enum.TextXAlignment.Left

earningsLabel.Text =
	"💎 Tokens: 0  •  💰 Receber: $0"

earningsLabel.ZIndex =
	5

earningsLabel.Parent =
	card

-- =========================================================
--                         TIMER
-- =========================================================

local timerLabel =
	Instance.new("TextLabel")

timerLabel.Name =
	"TimerLabel"

timerLabel.BackgroundTransparency =
	1

timerLabel.Position =
	UDim2.new(
		0,
		0,
		0,
		34
	)

timerLabel.Size =
	UDim2.new(
		1,
		0,
		0,
		14
	)

timerLabel.Font =
	Enum.Font.GothamBold

timerLabel.TextSize =
	11

timerLabel.TextColor3 =
	Color3.fromRGB(
		225,
		228,
		238
	)

timerLabel.TextXAlignment =
	Enum.TextXAlignment.Left

timerLabel.Text =
	"--s"

timerLabel.ZIndex =
	5

timerLabel.Parent =
	card

-- =========================================================
--                         BADGE
-- =========================================================

local statusBadge =
	Instance.new("TextLabel")

statusBadge.Name =
	"StatusBadge"

statusBadge.AnchorPoint =
	Vector2.new(
		1,
		0
	)

statusBadge.Position =
	UDim2.new(
		1,
		0,
		0,
		2
	)

statusBadge.Size =
	UDim2.fromOffset(
		52,
		15
	)

statusBadge.BackgroundColor3 =
	COLOR_THEMES.Base

statusBadge.BackgroundTransparency =
	0.2

statusBadge.Font =
	Enum.Font.GothamBold

statusBadge.TextSize =
	8

statusBadge.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

statusBadge.Text =
	"NORMAL"

statusBadge.ZIndex =
	6

statusBadge.Parent =
	card

local badgeCorner =
	Instance.new("UICorner")

badgeCorner.CornerRadius =
	UDim.new(
		0,
		4
	)

badgeCorner.Parent =
	statusBadge

local badgeStroke =
	Instance.new("UIStroke")

badgeStroke.Thickness =
	1

badgeStroke.Transparency =
	0.5

badgeStroke.Parent =
	statusBadge

-- =========================================================
--                    BARRA DE PROGRESSO
-- =========================================================

local progressBackground =
	Instance.new("Frame")

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

local progressBar =
	Instance.new("Frame")

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

local sparkleContainer =
	Instance.new("Frame")

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

	local sparkle =
		Instance.new("TextLabel")

	sparkle.Name =
		"Sparkle_" .. i

	sparkle.BackgroundTransparency =
		1

	sparkle.Text =
		"✦"

	sparkle.TextSize =
		math.random(
			8,
			15
		)

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

local maxNotification =
	Instance.new("Frame")

maxNotification.Name =
	"MaxPriceNotification"

maxNotification.AnchorPoint =
	Vector2.new(
		0.5,
		0
	)

maxNotification.Position =
	UDim2.new(
		0.5,
		0,
		0,
		75
	)

maxNotification.Size =
	UDim2.fromOffset(
		285,
		48
	)

maxNotification.BackgroundColor3 =
	Color3.fromRGB(
		15,
		17,
		23
	)

maxNotification.BackgroundTransparency =
	0.08

maxNotification.BorderSizePixel =
	0

maxNotification.Visible =
	false

maxNotification.ZIndex =
	100

maxNotification.Parent =
	screenGui

local notificationCorner =
	Instance.new("UICorner")

notificationCorner.CornerRadius =
	UDim.new(
		0,
		12
	)

notificationCorner.Parent =
	maxNotification

local notificationStroke =
	Instance.new("UIStroke")

notificationStroke.Thickness =
	2

notificationStroke.Transparency =
	0.1

notificationStroke.Parent =
	maxNotification

local notificationText =
	Instance.new("TextLabel")

notificationText.Name =
	"NotificationText"

notificationText.BackgroundTransparency =
	1

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
			TextChatService:FindFirstChild(
				"TextChannels"
			)

		if textChannels then

			local general =
				textChannels:FindFirstChild(
					"RBXGeneral"
				)

			if general then

				pcall(function()
					general:SendAsync(
						mensagem
					)
				end)

				return

			end

		end

	end

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

local notificationToken =
	0

local function mostrarNotificacaoMaximo()

	notificationToken += 1

	local meuToken =
		notificationToken

	maxNotification.Visible =
		true

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

			BackgroundTransparency =
				0.08
		}
	):Play()

	TweenService:Create(
		notificationText,
		TweenInfo.new(
			0.3
		),
		{
			TextTransparency =
				0
		}
	):Play()

	task.spawn(function()

		local hue =
			0

		while
			meuToken ==
				notificationToken
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

			task.wait(
				0.03
			)

		end

	end)

	task.delay(
		4,
		function()

			if meuToken ~=
				notificationToken then
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

						BackgroundTransparency =
							1
					}
				)

			TweenService:Create(
				notificationText,
				TweenInfo.new(
					0.2
				),
				{
					TextTransparency =
						1
				}
			):Play()

			outTween:Play()

			outTween.Completed:Wait()

			if meuToken ==
				notificationToken then

				maxNotification.Visible =
					false

			end

		end
	)

end

-- =========================================================
--                     ESTADO MAXIMO
-- =========================================================

local maximoAtivo =
	false

-- =========================================================
--          CONTROLE DE ENVIO ÚNICO DA MENSAGEM
-- =========================================================

local CHAT_COOLDOWN =
	27

local CHAT_COOLDOWN_ATTRIBUTE =
	"TokenPriceWatcher_LastChatMessage"

local function tentarEnviarMensagemMaximo()

	local agora =
		os.clock()

	local ultimoEnvioGlobal =
		PlayerGui:GetAttribute(
			CHAT_COOLDOWN_ATTRIBUTE
		) or -math.huge

	if agora -
		ultimoEnvioGlobal >=
		CHAT_COOLDOWN then

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
--              EFEITO MÁXIMO
-- =========================================================

local rainbowConnection =
	nil

local pulseConnection =
	nil

local function pararEfeitoMaximo()

	maximoAtivo =
		false

	aura.Visible =
		false

	sparkleContainer.Visible =
		false

	if rainbowConnection then

		rainbowConnection:Disconnect()
		rainbowConnection = nil

	end

	if pulseConnection then

		pulseConnection:Disconnect()
		pulseConnection = nil

	end

	card.Size =
		UDim2.fromOffset(
			150,
			54
		)

end

local function iniciarEfeitoMaximo()

	if maximoAtivo then
		return
	end

	maximoAtivo =
		true

	tentarEnviarMensagemMaximo()

	aura.Visible =
		true

	sparkleContainer.Visible =
		true

	local hue =
		0

	rainbowConnection =
		RunService.RenderStepped:Connect(
			function(dt)

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

			end
		)

	local pulseTime =
		0

	pulseConnection =
		RunService.RenderStepped:Connect(
			function(dt)

				if not maximoAtivo then
					return
				end

				pulseTime +=
					dt * 4

				local wave =
					(math.sin(
						pulseTime
					) + 1) / 2

				local scale =
					1 + (
						wave * 0.035
					)

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

			end
		)

	task.spawn(function()

		while maximoAtivo
			and card.Parent do

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

			task.wait(
				0.25
			)

		end

	end)

	task.spawn(function()

		while maximoAtivo
			and card.Parent do

			for _, sparkle in
				ipairs(sparkles) do

				if not maximoAtivo then
					break
				end

				sparkle.Visible =
					true

				sparkle.Position =
					UDim2.new(
						math.random(),
						0,
						math.random(),
						0
					)

				sparkle.TextTransparency =
					0

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

							TextTransparency =
								1,

							TextSize =
								math.random(
									14,
									22
								)
						}
					)

				tween:Play()

				task.wait(
					0.08
				)

			end

			task.wait(
				0.15
			)

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

local lastPrice =
	PRICE_BASE

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
				TextSize =
					17
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
				TextSize =
					15
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
			Color =
				themeColor,

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

	number =
		tonumber(number) or 0

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

	local negativo =
		number < 0

	local absoluto =
		math.abs(number)

	for _, unidade in
		ipairs(unidades) do

		if absoluto >=
			unidade[1] then

			local valor =
				absoluto /
				unidade[1]

			local casas =
				1

			local fator =
				10 ^ casas

			local valorTruncado =
				math.floor(
					valor * fator
				) / fator

			local texto =
				string.format(
					"%." ..
						casas ..
						"f",
					valorTruncado
				)

			texto =
				texto
				:gsub(
					"(%..-)0+$",
					"%1"
				)
				:gsub(
					"%.$",
					""
				)

			if negativo then
				texto =
					"-" ..
					texto
			end

			return texto ..
				unidade[2]

		end

	end

	return tostring(
		math.floor(
			number + 0.5
		)
	)

end

-- =========================================================
--                     HACK EVENT
-- =========================================================

HackEvent.OnClientEvent:Connect(function(data)

	if typeof(data) ~= "table" then
		return
	end

	print(
		"[HACK ALERT]",
		"kind =",
		data.kind,
		"role =",
		data.role,
		"name =",
		data.name
	)

	local kind =
		tostring(
			data.kind or ""
		):lower()

	local action =
		tostring(
			data.action or ""
		):lower()

	local eventType =
		tostring(
			data.type or ""
		):lower()

	local role =
		tostring(
			data.role or ""
		):lower()

	local name =
		tostring(
			data.name or ""
		)

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

	-- =====================================================
	--                 INÍCIO DO ROUBO
	-- =====================================================

	if kind == "phase" then

		if role == "victim" then

			iniciarAlerta()

			local robber =
				obterPlayerDoRoubo(
					data,
					role
				)

			if robber then

				iniciarIndicadorRoubo(
					robber
				)

			else

				warn(
					"[SAMMODS ROUBO] Não consegui identificar o ladrão no evento recebido."
				)

			end

		elseif role == "attacker" then

			-- Você é o ladrão.
			-- O indicador aparece acima da sua própria cabeça
			-- para que este cliente também veja o estado.
			iniciarIndicadorRoubo(
				LocalPlayer
			)

		elseif name ~= ""
			and name == LocalPlayer.Name then

			-- Sem role reconhecido, mas o evento identifica
			-- você pelo nome. Mantemos o comportamento original
			-- de não tocar o alerta.

		else

			warn(
				"[HACK ALERT] role inesperado recebido: '" ..
				tostring(data.role) ..
				"' (esperado 'victim' ou 'attacker')"
			)

		end

		return

	end

	-- =====================================================
	--                 FIM DO ROUBO
	-- =====================================================

	if kind == "result"
		or kind == "abort"
		or kind == "end"
		or kind == "ended"
		or kind == "finish"
		or kind == "finished"
		or action == "robbery_end"
		or action == "steal_end"
		or eventType == "robbery_end"
		or eventType == "steal_end" then

		pararAlerta()
		pararIndicadorRoubo()

		return

	end

	-- Eventos explicitamente classificados como roubo.
	if rouboKinds[kind]
		or rouboKinds[action]
		or rouboKinds[eventType] then

		-- Eventos de encerramento removem o indicador.
		if kind == "robbery_end"
			or kind == "steal_end"
			or action == "robbery_end"
			or action == "steal_end"
			or eventType == "robbery_end"
			or eventType == "steal_end" then

			pararAlerta()
			pararIndicadorRoubo()

			return

		end

		-- Para um evento genérico de início, tentamos
		-- identificar o ladrão.
		local robber =
			obterPlayerDoRoubo(
				data,
				role
			)

		if robber then
			iniciarIndicadorRoubo(
				robber
			)
		end

		pararAlerta()

		return

	end

end)

-- =========================================================
--                  ATUALIZAR DISPLAY
-- =========================================================

local function updateDisplay()

	local rawPrice =
		readNumber(
			Workspace:GetAttribute(
				"TokenPrice"
			),
			PRICE_BASE
		)

	local price =
		math.floor(
			rawPrice
		)

	local tokenAmount =
		lerQuantidadeTokens()

	local valorReceber =
		tokenAmount *
		rawPrice

	earningsLabel.Text =
		("💎 Tokens: %s  •  💰 Receber: $%s"):format(
			formatNumber(
				tokenAmount
			),
			formatNumber(
				valorReceber
			)
		)

	if price ~= lastPrice then
		animatePriceBounce()
	end

	local trendSymbol =
		""

	if price > lastPrice then

		trendSymbol =
			" ▲"

	elseif price < lastPrice then

		trendSymbol =
			" ▼"

	end

	priceLabel.Text =
		("$%d%s"):format(
			price,
			trendSymbol
		)

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

			iniciarEfeitoMaximo()

			mostrarNotificacaoMaximo()

		end

	elseif price >= PRICE_SPIKE then

		if maximoAtivo then
			pararEfeitoMaximo()
		end

		applyTheme(
			COLOR_THEMES.Spike,
			0.4,
			"🔥 ALTO"
		)

	elseif price <= PRICE_MIN then

		if maximoAtivo then
			pararEfeitoMaximo()
		end

		applyTheme(
			COLOR_THEMES.Min,
			0.4,
			"📉 MÍNIMO"
		)

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

	lastPrice =
		price

end

-- =========================================================
--                         TIMER
-- =========================================================

task.spawn(function()

	while screenGui.Parent do

		local now =
			os.time()

		local secondsLeft =
			EPOCH_SECONDS -
			(
				now %
				EPOCH_SECONDS
			)

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

		task.wait(
			0.5
		)

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

iniciarSistemaTags()

-- Marca o próprio cliente como usuário do painel localmente.
-- Isso permite que a própria tag USER apareça imediatamente.
LocalPlayer:SetAttribute(
	"SamModsUser",
	true
)

updateDisplay()
```

[/writing]

**O botão 📢 foi removido de verdade**, não apenas escondido. A função automática de mensagem, o cooldown de **27 segundos** e os efeitos de `$15` continuam.

E não coloquei a notificação do **Chronos Lattice**, porque você tinha mandado deixar essa parte de lado.
