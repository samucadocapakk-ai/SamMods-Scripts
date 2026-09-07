--// ============================================================
--// TokenPriceWatcher + QuickShop + Hack Alert + OWNER/USER TAG
--// LocalScript - StarterPlayerScripts
--//
--// OWNER:
--// UserId = 4290770735
--// TAG = 👑 OWNER
--//
--// OUTROS EXECUTORES:
--// TAG = USER
--//
--// LOJA NO MÁXIMO:
--// Visual: 🌈 LOJA NO MÁXIMO! • $15 💎
--// Chat: 🌈 Loja: preço dos tokens está no máximo
--// Cooldown: 27 segundos
--// ============================================================

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

--// ============================================================
--// CONFIGURAÇÃO DA TAG
--// ============================================================

local OWNER_USER_ID = 4290770735

local TAG_OWNER_TEXT = "👑 OWNER"
local TAG_USER_TEXT = "USER"

local TAG_NAME = "SamModsAdminTag"

local currentTag = nil
local tagRainbowConnection = nil
local tagCharacterConnection = nil
local tagHumanoidConnection = nil

local function destruirTag()
	if tagRainbowConnection then
		tagRainbowConnection:Disconnect()
		tagRainbowConnection = nil
	end

	if tagHumanoidConnection then
		tagHumanoidConnection:Disconnect()
		tagHumanoidConnection = nil
	end

	if currentTag then
		pcall(function()
			currentTag:Destroy()
		end)

		currentTag = nil
	end
end

local function criarTag(character)
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		head = character:WaitForChild("Head", 5)
	end

	if not head then
		return
	end

	-- Remove uma TAG antiga deste script, caso exista.
	local antiga = head:FindFirstChild(TAG_NAME)
	if antiga then
		antiga:Destroy()
	end

	-- Remove somente a TAG atual deste cliente.
	destruirTag()

	local billboard = Instance.new("BillboardGui")
	billboard.Name = TAG_NAME
	billboard.Adornee = head
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 100
	billboard.Size = UDim2.fromOffset(150, 35)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.ResetOnSpawn = false
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Name = "TagLabel"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Position = UDim2.fromScale(0, 0)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextWrapped = false
	label.TextStrokeTransparency = 1
	label.TextTransparency = 0
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = (
		LocalPlayer.UserId == OWNER_USER_ID
			and TAG_OWNER_TEXT
			or TAG_USER_TEXT
	)
	label.Parent = billboard

	currentTag = billboard

	--// Rainbow contínuo
	local hue = 0

	tagRainbowConnection = RunService.RenderStepped:Connect(function(dt)
		if not currentTag or not currentTag.Parent then
			return
		end

		hue = (hue + dt * 0.45) % 1

		label.TextColor3 = Color3.fromHSV(
			hue,
			1,
			1
		)
	end)

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		tagHumanoidConnection = humanoid.Died:Connect(function()
			destruirTag()
		end)
	end
end

--// CharacterAdded fica separado das conexões que são destruídas
--// pela troca de personagem.
tagCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
	task.wait(0.5)

	if character and character.Parent then
		criarTag(character)
	end
end)

if LocalPlayer.Character then
	task.spawn(function()
		task.wait(0.5)

		if LocalPlayer.Character then
			criarTag(LocalPlayer.Character)
		end
	end)
end

--// ============================================================
--// INTRO
--// ============================================================

local existingIntro = PlayerGui:FindFirstChild("SamModsIntroGui")

if existingIntro then
	existingIntro:Destroy()
end

local IntroGui = Instance.new("ScreenGui")
IntroGui.Name = "SamModsIntroGui"
IntroGui.ResetOnSpawn = false
IntroGui.IgnoreGuiInset = true
IntroGui.DisplayOrder = 999
IntroGui.Parent = PlayerGui

local IntroBackground = Instance.new("Frame")
IntroBackground.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
IntroBackground.BorderSizePixel = 0
IntroBackground.Size = UDim2.fromScale(1, 1)
IntroBackground.Parent = IntroGui

local IntroTitle = Instance.new("TextLabel")
IntroTitle.BackgroundTransparency = 1
IntroTitle.Size = UDim2.fromScale(0.8, 0.15)
IntroTitle.Position = UDim2.fromScale(0.1, 0.38)
IntroTitle.Font = Enum.Font.GothamBlack
IntroTitle.Text = "SAM MODS"
IntroTitle.TextScaled = true
IntroTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
IntroTitle.TextTransparency = 1
IntroTitle.Parent = IntroBackground

local IntroSub = Instance.new("TextLabel")
IntroSub.BackgroundTransparency = 1
IntroSub.Size = UDim2.fromScale(0.8, 0.07)
IntroSub.Position = UDim2.fromScale(0.1, 0.53)
IntroSub.Font = Enum.Font.GothamBold
IntroSub.Text = "TOKEN PRICE WATCHER"
IntroSub.TextScaled = true
IntroSub.TextColor3 = Color3.fromRGB(255, 255, 255)
IntroSub.TextTransparency = 1
IntroSub.Parent = IntroBackground

task.spawn(function()
	TweenService:Create(
		IntroTitle,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			TextTransparency = 0
		}
	):Play()

	task.wait(0.35)

	TweenService:Create(
		IntroSub,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			TextTransparency = 0
		}
	):Play()

	task.wait(1.4)

	local fade1 = TweenService:Create(
		IntroTitle,
		TweenInfo.new(0.7),
		{
			TextTransparency = 1
		}
	)

	local fade2 = TweenService:Create(
		IntroSub,
		TweenInfo.new(0.7),
		{
			TextTransparency = 1
		}
	)

	local fade3 = TweenService:Create(
		IntroBackground,
		TweenInfo.new(0.7),
		{
			BackgroundTransparency = 1
		}
	)

	fade1:Play()
	fade2:Play()
	fade3:Play()

	task.wait(0.8)

	if IntroGui then
		IntroGui:Destroy()
	end
end)

--// ============================================================
--// TOKEN / NÚMEROS
--// ============================================================

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
	if texto == nil then
		return 0
	end

	texto = tostring(texto)
	texto = texto:gsub("%$", "")
	texto = texto:gsub("%s+", "")

	local numero, unidade = texto:match("(%-?%d+[%.,]?%d*)%s*(%a*)")

	if not numero then
		return tonumber(texto) or 0
	end

	numero = numero:gsub(",", ".")

	local valor = tonumber(numero) or 0

	if unidade and unidade ~= "" then
		unidade = unidade:gsub("%s+", "")

		local multiplicador = UNIDADES_REVERSO[unidade]

		if multiplicador then
			valor *= multiplicador
		end
	end

	return valor
end

local function readNumber(value, fallback)
	local number = tonumber(value)

	if number then
		return number
	end

	return fallback
end

--// ============================================================
--// PROTEÇÃO CONTRA MÚLTIPLAS INSTÂNCIAS
--// ============================================================

local instanceValue = PlayerGui:FindFirstChild("TokenPriceWatcher_Instance")

if instanceValue then
	script:Destroy()
	return
end

instanceValue = Instance.new("BoolValue")
instanceValue.Name = "TokenPriceWatcher_Instance"
instanceValue.Value = true
instanceValue.Parent = PlayerGui

local oldGui = PlayerGui:FindFirstChild("TokenPriceWatcherGui")

if oldGui then
	oldGui:Destroy()
end

--// ============================================================
--// CONFIG
--// ============================================================

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local OpenTokenExchange = Remotes:FindFirstChild("OpenTokenExchange")
local HackEvent = Remotes:WaitForChild("HackEvent")

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

--// ============================================================
--// CORES
--// ============================================================

local COLOR_MIN = Color3.fromRGB(60, 255, 120)
local COLOR_BASE = Color3.fromRGB(70, 150, 255)
local COLOR_SPIKE = Color3.fromRGB(255, 150, 40)
local COLOR_MAX = Color3.fromRGB(255, 230, 60)

--// ============================================================
--// HACK ALERT
--// ============================================================

local hackSound = SoundService:FindFirstChild("HackAlertSound")

if not hackSound then
	hackSound = Instance.new("Sound")
	hackSound.Name = "HackAlertSound"
	hackSound.SoundId = "rbxassetid://5348162330"
	hackSound.Volume = 3
	hackSound.Looped = true
	hackSound.Parent = SoundService
end

local function iniciarHackAlert()
	if not hackSound.IsPlaying then
		pcall(function()
			hackSound:Play()
		end)
	end
end

local function pararHackAlert()
	pcall(function()
		hackSound:Stop()
	end)
end

if HackEvent then
	HackEvent.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then
			return
		end

		local kind = tostring(
			data.kind
				or data.action
				or data.type
				or ""
		):lower()

		local role = tostring(
			data.role
				or ""
		):lower()

		local name = tostring(
			data.name
				or data.player
				or ""
		)

		if kind == "robbery"
			or kind == "steal"
			or kind == "stole"
			or kind == "theft" then

			pararHackAlert()
			return
		end

		if kind == "phase" then
			if role == "victim" then
				iniciarHackAlert()

			elseif role == "attacker" then
				pararHackAlert()

			elseif name == LocalPlayer.Name then
				pararHackAlert()
			end

			return
		end

		if kind == "result"
			or kind == "abort"
			or kind == "end"
			or kind == "ended"
			or kind == "finish"
			or kind == "finished" then

			pararHackAlert()
			return
		end
	end)
end

--// ============================================================
--// MAIN GUI
--// ============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TokenPriceWatcherGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 10
ScreenGui.Parent = PlayerGui

--// ============================================================
--// AURA DO MÁXIMO
--// ============================================================

local aura = Instance.new("Frame")
aura.Name = "MaxAura"
aura.BackgroundTransparency = 1
aura.BorderSizePixel = 0
aura.Size = UDim2.fromOffset(170, 74)
aura.Position = UDim2.new(1, -180, 0, 10)
aura.Visible = false
aura.Parent = ScreenGui

local auraCorner = Instance.new("UICorner")
auraCorner.CornerRadius = UDim.new(0, 16)
auraCorner.Parent = aura

local auraStroke = Instance.new("UIStroke")
auraStroke.Thickness = 3
auraStroke.Transparency = 0.1
auraStroke.Parent = aura

--// ============================================================
--// CARD PRINCIPAL
--// ============================================================

local card = Instance.new("TextButton")
card.Name = "TokenPriceCard"
card.AutoButtonColor = false
card.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
card.BorderSizePixel = 0
card.Size = UDim2.fromOffset(150, 54)
card.Position = UDim2.new(1, -180, 0, 20)
card.Text = ""
card.Parent = ScreenGui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 12)
cardCorner.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Thickness = 2
cardStroke.Color = COLOR_BASE
cardStroke.Parent = card

--// ============================================================
--// SHINE
--// ============================================================

local shine = Instance.new("Frame")
shine.Name = "Shine"
shine.BackgroundTransparency = 0.75
shine.BorderSizePixel = 0
shine.Size = UDim2.fromOffset(35, 100)
shine.Position = UDim2.new(-0.25, 0, -0.2, 0)
shine.Rotation = 20
shine.Visible = false
shine.Parent = card

local shineGradient = Instance.new("UIGradient")
shineGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 1),
})
shineGradient.Parent = shine

--// ============================================================
--// PREÇO
--// ============================================================

local priceLabel = Instance.new("TextLabel")
priceLabel.Name = "PriceLabel"
priceLabel.BackgroundTransparency = 1
priceLabel.BorderSizePixel = 0
priceLabel.Position = UDim2.fromOffset(8, 3)
priceLabel.Size = UDim2.new(1, -16, 0, 25)
priceLabel.Font = Enum.Font.GothamBlack
priceLabel.Text = "$10"
priceLabel.TextScaled = true
priceLabel.TextColor3 = COLOR_BASE
priceLabel.Parent = card

--// ============================================================
--// TOKENS / RECEBER
--// ============================================================

local earningsLabel = Instance.new("TextLabel")
earningsLabel.Name = "EarningsLabel"
earningsLabel.BackgroundTransparency = 1
earningsLabel.BorderSizePixel = 0
earningsLabel.Position = UDim2.fromOffset(6, 28)
earningsLabel.Size = UDim2.new(1, -12, 0, 19)
earningsLabel.Font = Enum.Font.GothamBold
earningsLabel.Text = "💎 Tokens: 0  •  💰 Receber: $0"
earningsLabel.TextScaled = true
earningsLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
earningsLabel.Parent = card

--// ============================================================
--// TIMER
--// ============================================================

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.BackgroundTransparency = 1
timerLabel.BorderSizePixel = 0
timerLabel.Position = UDim2.new(0, 0, 1, 4)
timerLabel.Size = UDim2.new(1, 0, 0, 16)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Text = "⏱ 30s"
timerLabel.TextScaled = true
timerLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
timerLabel.Parent = card

--// ============================================================
--// STATUS BADGE
--// ============================================================

local statusBadge = Instance.new("TextLabel")
statusBadge.Name = "StatusBadge"
statusBadge.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
statusBadge.BorderSizePixel = 0
statusBadge.Position = UDim2.new(1, -78, 0, -10)
statusBadge.Size = UDim2.fromOffset(74, 20)
statusBadge.Font = Enum.Font.GothamBlack
statusBadge.Text = "NORMAL"
statusBadge.TextScaled = true
statusBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
statusBadge.Parent = card

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(1, 0)
badgeCorner.Parent = statusBadge

local badgeStroke = Instance.new("UIStroke")
badgeStroke.Thickness = 1.5
badgeStroke.Parent = statusBadge

--// ============================================================
--// BOTÃO MANUAL DE CHAT
--// ============================================================

local manualChatButton = Instance.new("TextButton")
manualChatButton.Name = "ManualChatButton"
manualChatButton.AutoButtonColor = false
manualChatButton.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
manualChatButton.BorderSizePixel = 0
manualChatButton.Position = UDim2.new(1, -28, 0, 50)
manualChatButton.Size = UDim2.fromOffset(22, 22)
manualChatButton.Font = Enum.Font.GothamBold
manualChatButton.Text = "📢"
manualChatButton.TextScaled = true
manualChatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
manualChatButton.Parent = ScreenGui

local manualCorner = Instance.new("UICorner")
manualCorner.CornerRadius = UDim.new(1, 0)
manualCorner.Parent = manualChatButton

--// ============================================================
--// PROGRESS BAR
--// ============================================================

local progressBack = Instance.new("Frame")
progressBack.Name = "ProgressBack"
progressBack.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
progressBack.BorderSizePixel = 0
progressBack.Position = UDim2.new(1, -180, 0, 82)
progressBack.Size = UDim2.fromOffset(150, 5)
progressBack.Parent = ScreenGui

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0)
progressCorner.Parent = progressBack

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.BackgroundColor3 = COLOR_BASE
progressBar.BorderSizePixel = 0
progressBar.Size = UDim2.fromScale(1, 1)
progressBar.Parent = progressBack

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(1, 0)
progressBarCorner.Parent = progressBar

--// ============================================================
--// SPARKLES
--// ============================================================

local sparkleContainer = Instance.new("Frame")
sparkleContainer.Name = "Sparkles"
sparkleContainer.BackgroundTransparency = 1
sparkleContainer.BorderSizePixel = 0
sparkleContainer.Size = UDim2.fromOffset(180, 90)
sparkleContainer.Position = UDim2.new(1, -185, 0, 0)
sparkleContainer.Visible = false
sparkleContainer.Parent = ScreenGui

local sparkles = {}

for i = 1, 8 do
	local sparkle = Instance.new("TextLabel")
	sparkle.BackgroundTransparency = 1
	sparkle.BorderSizePixel = 0
	sparkle.Size = UDim2.fromOffset(20, 20)
	sparkle.Position = UDim2.fromScale(
		math.random(),
		math.random()
	)
	sparkle.Font = Enum.Font.GothamBlack
	sparkle.Text = "✦"
	sparkle.TextScaled = true
	sparkle.TextTransparency = 0.2
	sparkle.TextColor3 = Color3.fromRGB(255, 255, 255)
	sparkle.Parent = sparkleContainer

	table.insert(sparkles, sparkle)
end

--// ============================================================
--// NOTIFICAÇÃO DO MÁXIMO
--// ============================================================

local maxNotification = Instance.new("TextLabel")
maxNotification.Name = "MaxNotification"
maxNotification.AnchorPoint = Vector2.new(0.5, 0)
maxNotification.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
maxNotification.BackgroundTransparency = 0.05
maxNotification.BorderSizePixel = 0
maxNotification.Position = UDim2.new(0.5, 0, -0.12, 0)
maxNotification.Size = UDim2.fromOffset(390, 48)
maxNotification.Font = Enum.Font.GothamBlack
maxNotification.Text = "🌈  LOJA NO MÁXIMO!  •  $15  💎"
maxNotification.TextScaled = true
maxNotification.TextColor3 = COLOR_MAX
maxNotification.TextTransparency = 1
maxNotification.Visible = true
maxNotification.Parent = ScreenGui

local maxNotificationCorner = Instance.new("UICorner")
maxNotificationCorner.CornerRadius = UDim.new(0, 14)
maxNotificationCorner.Parent = maxNotification

local maxNotificationStroke = Instance.new("UIStroke")
maxNotificationStroke.Thickness = 2
maxNotificationStroke.Transparency = 0.05
maxNotificationStroke.Parent = maxNotification

--// ============================================================
--// CHAT
--// ============================================================

local function enviarMensagemChat()
	local mensagem = "🌈 Loja: preço dos tokens está no máximo"

	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local textChannels = TextChatService:FindFirstChild("TextChannels")

		if textChannels then
			local general = textChannels:FindFirstChild("RBXGeneral")

			if general then
				pcall(function()
					general:SendAsync(mensagem)
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
				TextSize = 18,
			}
		)
	end)
end

--// ============================================================
--// COOLDOWN DO CHAT
--// ============================================================

local maximoAtivo = false

local CHAT_COOLDOWN = 27
local CHAT_COOLDOWN_ATTRIBUTE = "TokenPriceWatcher_LastChatMessage"

local function tentarEnviarMensagemMaximo()
	local agora = os.clock()

	local ultimoEnvioGlobal =
		PlayerGui:GetAttribute(CHAT_COOLDOWN_ATTRIBUTE)
		or -math.huge

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

--// ============================================================
--// NOTIFICAÇÃO
--// ============================================================

local notificationConnection = nil

local function mostrarNotificacaoMaximo()
	maxNotification.Visible = true
	maxNotification.TextTransparency = 1

	maxNotification.Position =
		UDim2.new(0.5, 0, -0.12, 0)

	if notificationConnection then
		notificationConnection:Disconnect()
		notificationConnection = nil
	end

	local tweenIn = TweenService:Create(
		maxNotification,
		TweenInfo.new(
			0.5,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Position = UDim2.new(0.5, 0, 0.04, 0),
			TextTransparency = 0,
		}
	)

	tweenIn:Play()

	local hue = 0

	notificationConnection =
		RunService.RenderStepped:Connect(function(dt)
			if not maxNotification.Visible then
				return
			end

			hue = (hue + dt * 0.7) % 1

			maxNotification.TextColor3 =
				Color3.fromHSV(hue, 1, 1)

			maxNotificationStroke.Color =
				Color3.fromHSV(
					(hue + 0.15) % 1,
					1,
					1
				)
		end)

	task.delay(4, function()
		if not maxNotification then
			return
		end

		local tweenOut = TweenService:Create(
			maxNotification,
			TweenInfo.new(0.5),
			{
				Position = UDim2.new(0.5, 0, -0.12, 0),
				TextTransparency = 1,
			}
		)

		tweenOut:Play()

		tweenOut.Completed:Wait()

		maxNotification.Visible = false

		if notificationConnection then
			notificationConnection:Disconnect()
			notificationConnection = nil
		end
	end)
end

--// ============================================================
--// EFEITO MÁXIMO
--// ============================================================

local rainbowConnection = nil
local pulseConnection = nil
local shineThread = nil
local sparkleThread = nil

local originalCardSize = UDim2.fromOffset(150, 54)

local function pararEfeitoMaximo()
	maximoAtivo = false

	if rainbowConnection then
		rainbowConnection:Disconnect()
		rainbowConnection = nil
	end

	if pulseConnection then
		pulseConnection:Disconnect()
		pulseConnection = nil
	end

	aura.Visible = false
	sparkleContainer.Visible = false
	shine.Visible = false

	card.Size = originalCardSize

	cardStroke.Thickness = 2

	for _, sparkle in ipairs(sparkles) do
		sparkle.Visible = true
	end
end

local function iniciarEfeitoMaximo()
	if maximoAtivo then
		return
	end

	maximoAtivo = true

	-- Envia somente uma vez quando entra no máximo.
	tentarEnviarMensagemMaximo()

	aura.Visible = true
	sparkleContainer.Visible = true
	shine.Visible = true

	local hue = 0

	rainbowConnection =
		RunService.RenderStepped:Connect(function(dt)
			if not maximoAtivo then
				return
			end

			hue = (hue + dt * 0.55) % 1

			local rainbowColor =
				Color3.fromHSV(hue, 1, 1)

			local rainbowColor2 =
				Color3.fromHSV(
					(hue + 0.15) % 1,
					1,
					1
				)

			cardStroke.Color = rainbowColor
			auraStroke.Color = rainbowColor2
			badgeStroke.Color = rainbowColor
			progressBar.BackgroundColor3 = rainbowColor
			statusBadge.TextColor3 = rainbowColor
			priceLabel.TextColor3 = rainbowColor
			shineGradient.Color = ColorSequence.new(
				rainbowColor,
				rainbowColor2,
				rainbowColor
			)
		end)

	local pulseTime = 0

	pulseConnection =
		RunService.RenderStepped:Connect(function(dt)
			if not maximoAtivo then
				return
			end

			pulseTime += dt * 4

			local pulse =
				(math.sin(pulseTime) + 1) / 2

			card.Size = UDim2.fromOffset(
				150 + pulse * 4,
				54 + pulse * 2
			)

			cardStroke.Thickness =
				2 + pulse * 1.5

			auraStroke.Transparency =
				0.15 + pulse * 0.35
		end)

	--// Shine
	task.spawn(function()
		while maximoAtivo and card.Parent do
			shine.Position =
				UDim2.new(-0.3, 0, -0.2, 0)

			local tween = TweenService:Create(
				shine,
				TweenInfo.new(
					1.2,
					Enum.EasingStyle.Linear
				),
				{
					Position =
						UDim2.new(1.2, 0, -0.2, 0)
				}
			)

			tween:Play()
			tween.Completed:Wait()

			task.wait(0.5)
		end
	end)

	--// Sparkles
	task.spawn(function()
		while maximoAtivo and sparkleContainer.Parent do
			for _, sparkle in ipairs(sparkles) do
				if not maximoAtivo then
					break
				end

				sparkle.Position = UDim2.fromScale(
					math.random(5, 95) / 100,
					math.random(5, 95) / 100
				)

				sparkle.TextTransparency = 0

				local sparkleTween =
					TweenService:Create(
						sparkle,
						TweenInfo.new(
							0.6,
							Enum.EasingStyle.Quad,
							Enum.EasingDirection.Out
						),
						{
							TextTransparency = 1,
						}
					)

				sparkleTween:Play()
			end

			task.wait(0.3)
		end
	end)
end

--// ============================================================
--// BOTÃO DE CHAT MANUAL
--// ============================================================

manualChatButton.MouseButton1Click:Connect(function()
	local enviado = tentarEnviarMensagemMaximo()

	if enviado then
		manualChatButton.Text = "✓"
		manualChatButton.TextColor3 =
			Color3.fromRGB(80, 255, 120)

		task.delay(1, function()
			if manualChatButton then
				manualChatButton.Text = "📢"
				manualChatButton.TextColor3 =
					Color3.fromRGB(255, 255, 255)
			end
		end)
	else
		manualChatButton.Text = "⏳"
		manualChatButton.TextColor3 =
			Color3.fromRGB(255, 80, 80)

		task.delay(1, function()
			if manualChatButton then
				manualChatButton.Text = "📢"
				manualChatButton.TextColor3 =
					Color3.fromRGB(255, 255, 255)
			end
		end)
	end
end)

--// ============================================================
--// ABRIR LOJA
--// ============================================================

card.MouseButton1Click:Connect(function()
	if not OpenTokenExchange then
		return
	end

	if OpenTokenExchange:IsA("RemoteEvent") then
		pcall(function()
			OpenTokenExchange:FireServer()
		end)

	elseif OpenTokenExchange:IsA("BindableEvent") then
		pcall(function()
			OpenTokenExchange:Fire()
		end)
	end
end)

--// ============================================================
--// HOVER
--// ============================================================

card.MouseEnter:Connect(function()
	TweenService:Create(
		card,
		TweenInfo.new(0.15),
		{
			BackgroundColor3 =
				Color3.fromRGB(25, 30, 43),
		}
	):Play()
end)

card.MouseLeave:Connect(function()
	TweenService:Create(
		card,
		TweenInfo.new(0.15),
		{
			BackgroundColor3 =
				Color3.fromRGB(15, 18, 28),
		}
	):Play()
end)

--// ============================================================
--// ANIMAÇÃO DO PREÇO
--// ============================================================

local function animatePriceBounce()
	local originalSize = priceLabel.Size

	local grow = TweenService:Create(
		priceLabel,
		TweenInfo.new(
			0.12,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Size = UDim2.new(
				1,
				-10,
				0,
				29
			),
		}
	)

	local shrink = TweenService:Create(
		priceLabel,
		TweenInfo.new(
			0.12,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.In
		),
		{
			Size = originalSize,
		}
	)

	grow:Play()

	grow.Completed:Connect(function()
		shrink:Play()
	end)
end

--// ============================================================
--// TEMA
--// ============================================================

local function applyTheme(color, status)
	if maximoAtivo then
		return
	end

	cardStroke.Color = color
	priceLabel.TextColor3 = color
	progressBar.BackgroundColor3 = color
	badgeStroke.Color = color
	statusBadge.Text = status
	statusBadge.TextColor3 = color
end

--// ============================================================
--// FORMATAÇÃO
--// ============================================================

local function formatNumber(number)
	number = tonumber(number) or 0

	local units = {
		{"Vg", 1e63},
		{"No", 1e60},
		{"Oc", 1e57},
		{"Spd", 1e54},
		{"Sxd", 1e51},
		{"Qid", 1e48},
		{"Qad", 1e45},
		{"Td", 1e42},
		{"Dd", 1e39},
		{"Ud", 1e36},
		{"Dc", 1e33},
		{"No", 1e30},
		{"Oc", 1e27},
		{"Sp", 1e24},
		{"Sx", 1e21},
		{"Qi", 1e18},
		{"Qa", 1e15},
		{"T", 1e12},
		{"B", 1e9},
		{"M", 1e6},
		{"K", 1e3},
	}

	for _, unit in ipairs(units) do
		if math.abs(number) >= unit[2] then
			local value = number / unit[2]

			if value >= 100 then
				return string.format(
					"%.0f%s",
					value,
					unit[1]
				)
			elseif value >= 10 then
				return string.format(
					"%.1f%s",
					value,
					unit[1]
				)
			else
				return string.format(
					"%.2f%s",
					value,
					unit[1]
				)
			end
		end
	end

	return string.format("%.0f", number)
end

--// ============================================================
--// LER TOKENS
--// ============================================================

local function getTokenAmount()
	local amount = 0

	pcall(function()
		local HUD = PlayerGui:FindFirstChild("HUD")

		if not HUD then
			return
		end

		local Spendables =
			HUD:FindFirstChild("Spendables")

		if not Spendables then
			return
		end

		local TokenRow =
			Spendables:FindFirstChild("TokenRow")

		if not TokenRow then
			return
		end

		local Tokens =
			TokenRow:FindFirstChild("Tokens")

		if not Tokens then
			return
		end

		if Tokens:IsA("TextLabel")
			or Tokens:IsA("TextButton")
			or Tokens:IsA("TextBox") then

			amount =
				parseValorAbreviado(Tokens.Text)
		end
	end)

	if amount == 0 then
		local attributeValue =
			LocalPlayer:GetAttribute("Tokens")

		if attributeValue ~= nil then
			amount = tonumber(attributeValue) or 0
		end
	end

	return amount
end

--// ============================================================
--// UPDATE DISPLAY
--// ============================================================

local lastPrice = nil

local function updateDisplay()
	local rawPrice =
		Workspace:GetAttribute("TokenPrice")

	if rawPrice == nil then
		rawPrice = PRICE_BASE
	end

	rawPrice = tonumber(rawPrice) or PRICE_BASE

	local price = math.floor(rawPrice)

	local tokenAmount = getTokenAmount()

	local valorReceber =
		tokenAmount * rawPrice

	--// Preço
	priceLabel.Text = "$" .. tostring(price)

	--// Tokens + Receber
	earningsLabel.Text =
		"💎 Tokens: "
		.. formatNumber(tokenAmount)
		.. "  •  💰 Receber: $"
		.. formatNumber(valorReceber)

	--// Animação quando o preço muda
	if lastPrice ~= nil and lastPrice ~= price then
		animatePriceBounce()
	end

	lastPrice = price

	--// ========================================================
	--// MÁXIMO
	--// ========================================================

	if price >= PRICE_MAX then
		statusBadge.Text = "⚡ MÁXIMO"

		if not maximoAtivo then
			iniciarEfeitoMaximo()

			-- Notificação visual somente na entrada do máximo.
			mostrarNotificacaoMaximo()
		end

		return
	end

	--// Saiu do máximo
	if maximoAtivo then
		pararEfeitoMaximo()
	end

	--// ========================================================
	--// SPIKE
	--// ========================================================

	if price >= PRICE_SPIKE then
		applyTheme(
			COLOR_SPIKE,
			"🔥 ALTO"
		)

		return
	end

	--// ========================================================
	--// MÍNIMO
	--// ========================================================

	if price <= PRICE_MIN then
		applyTheme(
			COLOR_MIN,
			"📉 MÍNIMO"
		)

		return
	end

	--// ========================================================
	--// NORMAL
	--// ========================================================

	applyTheme(
		COLOR_BASE,
		"💎 NORMAL"
	)
end

--// ============================================================
--// TIMER
--// ============================================================

task.spawn(function()
	while ScreenGui.Parent do
		local now = os.time()

		local secondsLeft =
			EPOCH_SECONDS - (now % EPOCH_SECONDS)

		local progress =
			secondsLeft / EPOCH_SECONDS

		timerLabel.Text =
			"⏱ " .. tostring(secondsLeft) .. "s"

		progressBar.Size =
			UDim2.new(
				math.clamp(progress, 0, 1),
				0,
				1,
				0
			)

		updateDisplay()

		task.wait(0.5)
	end
end)

--// ============================================================
--// ATUALIZAÇÃO POR ATRIBUTO
--// ============================================================

Workspace:GetAttributeChangedSignal(
	"TokenPrice"
):Connect(function()
	updateDisplay()
end)

LocalPlayer:GetAttributeChangedSignal(
	"Tokens"
):Connect(function()
	updateDisplay()
end)

--// ============================================================
--// PRIMEIRA ATUALIZAÇÃO
--// ============================================================

updateDisplay()

--// ============================================================
--// LIMPEZA
--// ============================================================

script.Destroying:Connect(function()
	if tagCharacterConnection then
		tagCharacterConnection:Disconnect()
		tagCharacterConnection = nil
	end

	destruirTag()

	if rainbowConnection then
		rainbowConnection:Disconnect()
		rainbowConnection = nil
	end

	if pulseConnection then
		pulseConnection:Disconnect()
		pulseConnection = nil
	end

	if notificationConnection then
		notificationConnection:Disconnect()
		notificationConnection = nil
	end

	pararHackAlert()

	if instanceValue and instanceValue.Parent then
		instanceValue:Destroy()
	end
end)
