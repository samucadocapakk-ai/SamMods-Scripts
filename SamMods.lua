--[[
	=========================================================
	  SamMods — TokenPriceWatcher v2
	  Local: StarterPlayerScripts (LocalScript)
	=========================================================

	O QUE MUDOU EM RELAÇÃO À v1
	---------------------------
	CORREÇÕES
	  • Tabela de unidades unificada (o formatNumber antigo
	    repetia "No"/"Oc" em duas faixas e não batia com a
	    tabela de leitura, dando valor errado acima de 1e57).
	  • Leitura de tokens aceita sufixo em minúsculo e texto
	    com prefixo ("Tokens: 2.5t").
	  • Um único loop de rainbow para tudo (antes era um loop
	    por elemento + um por jogador na sala: com 20 jogadores
	    eram 20+ loops a 33fps só para trocar cor de contorno).
	  • Todas as conexões/loops são registrados e desligados
	    quando o script morre (antes vazavam).
	  • Pulsação do modo máximo usa UIScale em vez de mudar
	    Size, então não briga mais com o hover nem desalinha
	    os botões.
	  • O botão 📢 fazia outra coisa (ligava/desligava o som).
	    Agora cada botão faz o que o ícone diz.
	  • Limpeza remove TODAS as GUIs do mod ao recarregar.

	NOVIDADES
	  • Painel arrastável (segure e arraste o card) com a
	    posição lembrada.
	  • Painel de abas: Config / Roubos / Stats (botão ⚙).
	  • Config com liga-desliga de cada função.
	  • Log de roubos (quem, quando, quantas vezes).
	  • Stats da sessão: tokens ganhos, tokens/min, maior
	    preço visto, roubos sofridos.
	  • Mini gráfico do histórico de preço dentro do card.
	  • Meta de tokens/valor com aviso quando bater.
	  • Seta na borda da tela apontando pro ladrão quando ele
	    está fora do campo de visão.
	  • Auto-travar no ladrão (opcional).
	  • Atalhos de teclado (F1 esconde tudo, F2 config,
	    F3 som, F4 manda a mensagem, F5 vai até o ladrão).
	  • Modo discreto (esconde tudo pra print/gravação).
	  • Fila de notificações (não atropela mais uma na outra).

	OBS: as configurações ficam salvas enquanto você estiver
	no servidor. Script local não consegue gravar em disco,
	então ao trocar de servidor volta ao padrão — mude os
	valores em CONFIG abaixo se quiser outro padrão fixo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
--                        CONFIG
-- =========================================================
-- Tudo que dá pra mexer sem entender o resto do código.

local CONFIG = {

	-- Identidade
	introTitulo = "SamMods",
	introSubtitulo = "MODS ROBLOX",
	mostrarIntro = true,

	donoUserId = 4290770735,
	admNome = "spammarixx107",

	-- Nomes que disparam a notificação de chat
	nomesEspeciais = {
		RECRUTAKG = true,
		spammarixx107 = true,
	},

	-- Mensagem automática de loja no máximo
	mensagemMaximo = "🌈 Loja: preço dos tokens está no máximo",
	chatCooldown = 27,

	-- Sons
	somAlertaId = "rbxassetid://171165317",
	somAlertaVolume = 3,
	somNotifyId = "rbxassetid://71450094482101",
	somNotifyVolume = 3,

	-- Visual
	rainbowVelocidade = 0.45,
	historicoTamanho = 26,

	-- Padrões dos liga-desliga (o usuário muda no painel ⚙)
	padroes = {
		somAlerta = true,
		efeitosMaximo = true,
		avisoChatAuto = true,
		espLadrao = true,
		setaLadrao = true,
		tagsJogadores = true,
		autoTravar = false,
		notificacoes = true,
		travadoHud = false,
	},

	-- Metas (0 = desligado)
	metaTokens = 0,
	metaValor = 0,

	-- Atalhos
	teclas = {
		esconderTudo = Enum.KeyCode.F1,
		abrirConfig = Enum.KeyCode.F2,
		alternarSom = Enum.KeyCode.F3,
		enviarMensagem = Enum.KeyCode.F4,
		irAteLadrao = Enum.KeyCode.F5,
	},
}

local CARD_W, CARD_H = 190, 70

local CORES = {
	Min = Color3.fromRGB(80, 220, 120),
	Base = Color3.fromRGB(0, 170, 255),
	Spike = Color3.fromRGB(255, 130, 40),
	Max = Color3.fromRGB(255, 200, 0),
	Fundo = Color3.fromRGB(18, 20, 26),
	Fundo2 = Color3.fromRGB(28, 31, 38),
	Texto = Color3.fromRGB(255, 255, 255),
	TextoFraco = Color3.fromRGB(165, 170, 182),
	Perigo = Color3.fromRGB(220, 60, 60),
	Ok = Color3.fromRGB(60, 200, 120),
}

-- =========================================================
--            PROTEÇÃO CONTRA MÚLTIPLAS INSTÂNCIAS
-- =========================================================

local INSTANCE_MARKER = "SamMods_TokenWatcher_Instance"

if PlayerGui:FindFirstChild(INSTANCE_MARKER) then
	warn("[SamMods] Outra instância já está ativa. Esta foi bloqueada.")
	return
end

local marker = Instance.new("BoolValue")
marker.Name = INSTANCE_MARKER
marker.Value = true
marker.Parent = PlayerGui

-- Remove restos de execuções anteriores.
for _, nome in ipairs({
	"TokenPriceWatcherGui",
	"SamModsMainGui",
	"SamModsIntroGui",
	"ChatNotifyGui",
	"SamModsNotifyGui",
}) do
	local antigo = PlayerGui:FindFirstChild(nome)
	if antigo then
		antigo:Destroy()
	end
end

-- =========================================================
--                    JANITOR (limpeza)
-- =========================================================
-- Guarda conexões/instâncias e desliga tudo de uma vez.

local Janitor = {}
Janitor.__index = Janitor

function Janitor.new()
	return setmetatable({ _itens = {}, _morto = false }, Janitor)
end

function Janitor:add(item)
	if self._morto then
		if typeof(item) == "RBXScriptConnection" then
			item:Disconnect()
		elseif typeof(item) == "Instance" then
			item:Destroy()
		end
		return item
	end
	table.insert(self._itens, item)
	return item
end

function Janitor:destroy()
	if self._morto then
		return
	end
	self._morto = true
	for i = #self._itens, 1, -1 do
		local item = self._itens[i]
		if typeof(item) == "RBXScriptConnection" then
			pcall(function()
				item:Disconnect()
			end)
		elseif typeof(item) == "Instance" then
			pcall(function()
				item:Destroy()
			end)
		elseif type(item) == "function" then
			pcall(item)
		end
		self._itens[i] = nil
	end
end

function Janitor:vivo()
	return not self._morto
end

local jan = Janitor.new()
jan:add(marker)

local rodando = true

jan:add(function()
	rodando = false
end)

script.Destroying:Connect(function()
	jan:destroy()
end)

-- =========================================================
--                       UTILIDADES
-- =========================================================

local function tween(obj, props, tempo, estilo, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(
			tempo or 0.25,
			estilo or Enum.EasingStyle.Quad,
			dir or Enum.EasingDirection.Out
		),
		props
	)
	t:Play()
	return t
end

local function novo(classe, props, pai)
	local inst = Instance.new(classe)
	for k, v in pairs(props) do
		inst[k] = v
	end
	if pai then
		inst.Parent = pai
	end
	return inst
end

local function cantos(pai, raio)
	return novo("UICorner", { CornerRadius = UDim.new(0, raio or 10) }, pai)
end

local function contorno(pai, cor, grossura, transparencia)
	return novo("UIStroke", {
		Color = cor or CORES.Texto,
		Thickness = grossura or 1,
		Transparency = transparencia or 0.5,
	}, pai)
end

local function lerNumero(valor, padrao)
	return tonumber(valor) or padrao
end

-- ---- Unidades (uma tabela só, usada nos dois sentidos) ----

local UNIDADES = {
	{ 1e63, "Vg" },
	{ 1e60, "Nod" },
	{ 1e57, "Ocd" },
	{ 1e54, "Spd" },
	{ 1e51, "Sxd" },
	{ 1e48, "Qid" },
	{ 1e45, "Qad" },
	{ 1e42, "Td" },
	{ 1e39, "Dd" },
	{ 1e36, "Ud" },
	{ 1e33, "Dc" },
	{ 1e30, "No" },
	{ 1e27, "Oc" },
	{ 1e24, "Sp" },
	{ 1e21, "Sx" },
	{ 1e18, "Qi" },
	{ 1e15, "Qa" },
	{ 1e12, "T" },
	{ 1e9, "B" },
	{ 1e6, "M" },
	{ 1e3, "K" },
}

local UNIDADES_POR_SUFIXO = {}

for _, par in ipairs(UNIDADES) do
	UNIDADES_POR_SUFIXO[par[2]:lower()] = par[1]
end

local function formatarNumero(numero)

	numero = tonumber(numero) or 0

	local negativo = numero < 0
	local absoluto = math.abs(numero)

	for _, unidade in ipairs(UNIDADES) do

		if absoluto >= unidade[1] then

			-- O jogo trunca em 1 casa (não arredonda pra cima);
			-- fazemos igual pra bater com o modal.
			local valor = math.floor((absoluto / unidade[1]) * 10) / 10

			local texto = string.format("%.1f", valor)
				:gsub("%.0$", "")

			return (negativo and "-" or "") .. texto .. unidade[2]

		end

	end

	return (negativo and "-" or "") .. tostring(math.floor(absoluto + 0.5))

end

local function parseAbreviado(texto)

	if not texto then
		return nil
	end

	local numeroStr, sufixo = texto:match("(%-?%d+[%.,]?%d*)%s*(%a*)")

	if not numeroStr then
		return nil
	end

	local numero = tonumber((numeroStr:gsub(",", ".")))

	if not numero then
		return nil
	end

	if sufixo == "" then
		return numero
	end

	local mult = UNIDADES_POR_SUFIXO[sufixo:lower()]

	if mult then
		return numero * mult
	end

	-- Sufixo não reconhecido (ex: a palavra "Tokens" colada):
	-- trata como número puro em vez de descartar a leitura.
	return numero

end

local function formatarTempo(segundos)
	segundos = math.max(0, math.floor(segundos))
	local m = math.floor(segundos / 60)
	local s = segundos % 60
	return ("%02d:%02d"):format(m, s)
end

local function horaAgora()
	return os.date("%H:%M:%S")
end

-- =========================================================
--                  DRIVER ÚNICO DE RAINBOW
-- =========================================================
-- Um RenderStepped só para todos os elementos rainbow do mod.

local Rainbow = {}

do
	local inscritos = {}
	local hue = 0

	jan:add(RunService.RenderStepped:Connect(function(dt)

		hue = (hue + dt * CONFIG.rainbowVelocidade) % 1
		local cor = Color3.fromHSV(hue, 1, 1)

		for obj, aplicar in pairs(inscritos) do
			if typeof(obj) == "Instance" and obj.Parent == nil then
				inscritos[obj] = nil
			else
				local ok = pcall(aplicar, cor)
				if not ok then
					inscritos[obj] = nil
				end
			end
		end

	end))

	function Rainbow.add(obj, aplicar)
		inscritos[obj] = aplicar
	end

	function Rainbow.remove(obj)
		inscritos[obj] = nil
	end

	function Rainbow.cor()
		return Color3.fromHSV(hue, 1, 1)
	end
end

-- =========================================================
--                 ESTADO / CONFIGURAÇÕES VIVAS
-- =========================================================

local S = {}

for chave, valor in pairs(CONFIG.padroes) do
	S[chave] = valor
end

local stats = {
	inicioSessao = os.clock(),
	tokensIniciais = nil,
	tokensAtuais = 0,
	maiorPreco = 0,
	roubosSofridos = 0,
	vezesNoMaximo = 0,
}

local historicoPreco = {}
local logRoubos = {}

-- =========================================================
--                    INTRO "SamMods"
-- =========================================================
-- Roda em paralelo com o resto (não trava nada) e some sozinha.

local function rodarIntro()

	local introGui = novo("ScreenGui", {
		Name = "SamModsIntroGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 1000,
	}, PlayerGui)

	jan:add(introGui)

	local viva = true

	local bg = novo("Frame", {
		Name = "Background",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(5, 5, 8),
		BorderSizePixel = 0,
		ZIndex = 1,
	}, introGui)

	local vinheta = novo("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5028857084",
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 2,
	}, bg)

	local skip = novo("TextButton", {
		Name = "SkipIntroButton",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(110, 34),
		BackgroundColor3 = CORES.Texto,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = CORES.Texto,
		Text = "Pular ⏭",
		ZIndex = 2000,
	}, introGui)

	cantos(skip, 8)
	contorno(skip, CORES.Texto, 1, 0.6)

	local titulo = novo("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.42, 0),
		Size = UDim2.fromOffset(700, 160),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, bg)

	local function textoTitulo(nome, tamanho, cor, z)
		return novo("TextLabel", {
			Name = nome,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = tamanho,
			TextColor3 = cor,
			TextTransparency = 1,
			Text = CONFIG.introTitulo,
			ZIndex = z,
		}, titulo)
	end

	local glitch1 = textoTitulo("GlitchA", 72, Color3.fromRGB(255, 255, 255), 4)
	local glitch2 = textoTitulo("GlitchB", 72, Color3.fromRGB(20, 20, 20), 4)
	local principal = textoTitulo("MainTitle", 72, CORES.Texto, 6)
	local glow = textoTitulo("Glow", 74, CORES.Texto, 3)

	principal.TextStrokeTransparency = 1
	principal.TextStrokeColor3 = CORES.Texto

	local subtitulo = novo("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 6),
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(200, 200, 205),
		TextTransparency = 1,
		Text = CONFIG.introSubtitulo,
		ZIndex = 6,
	}, titulo)

	local linha = novo("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 40),
		Size = UDim2.new(0, 0, 0, 2),
		BackgroundColor3 = CORES.Texto,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, titulo)

	local carregando = novo("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -70),
		Size = UDim2.fromOffset(360, 40),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, bg)

	local labelCarregando = novo("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(180, 180, 190),
		TextTransparency = 1,
		Text = "CARREGANDO...",
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	}, carregando)

	local labelPercent = novo("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = CORES.Texto,
		TextTransparency = 1,
		Text = "0%",
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 6,
	}, carregando)

	local barraFundo = novo("Frame", {
		Position = UDim2.new(0, 0, 0, 22),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = Color3.fromRGB(40, 40, 45),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, carregando)

	cantos(barraFundo, 99)

	local barraFill = novo("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = CORES.Texto,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, barraFundo)

	cantos(barraFill, 99)
	contorno(barraFill, CORES.Texto, 1.5, 0.5)

	local particulasPai = novo("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, bg)

	local particulas = {}

	for i = 1, 24 do
		particulas[i] = novo("Frame", {
			Size = UDim2.fromOffset(math.random(1, 3), math.random(1, 3)),
			Position = UDim2.new(math.random(), 0, math.random(), 0),
			BackgroundColor3 = CORES.Texto,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, particulasPai)
	end

	local scanline = novo("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = CORES.Texto,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, bg)

	local function fechar()
		if not viva then
			return
		end
		viva = false
		if introGui.Parent then
			introGui:Destroy()
		end
	end

	skip.MouseButton1Click:Connect(fechar)

	task.spawn(function()

		tween(vinheta, { ImageTransparency = 0.8 }, 1.2)

		for i, p in ipairs(particulas) do
			task.delay(i * 0.02, function()
				if not viva then
					return
				end
				tween(p, { BackgroundTransparency = math.random(60, 85) / 100 }, 0.6)
				task.spawn(function()
					while viva and p.Parent do
						local destino = UDim2.new(p.Position.X.Scale, 0, p.Position.Y.Scale - 0.15, 0)
						local t = tween(p, { Position = destino }, math.random(4, 8), Enum.EasingStyle.Linear)
						t.Completed:Wait()
						if not (viva and p.Parent) then
							break
						end
						p.Position = UDim2.new(math.random(), 0, 1.05, 0)
					end
				end)
			end)
		end

		task.wait(0.5)
		if not viva then return end

		scanline.Position = UDim2.new(0, 0, -0.05, 0)
		scanline.BackgroundTransparency = 0.4
		tween(scanline, { Position = UDim2.new(0, 0, 1.05, 0) }, 0.5, Enum.EasingStyle.Linear)

		task.wait(0.55)
		if not viva then return end
		scanline.BackgroundTransparency = 1

		glitch1.TextTransparency = 0.6
		glitch2.TextTransparency = 0.6

		task.spawn(function()
			local fim = os.clock() + 1.0
			while viva and os.clock() < fim do
				glitch1.Position = UDim2.fromOffset(math.random(-6, 6), math.random(-3, 3))
				glitch2.Position = UDim2.fromOffset(math.random(-6, 6), math.random(-3, 3))
				task.wait(0.04)
			end
			if not viva then return end
			glitch1.Position = UDim2.fromOffset(2, 0)
			glitch2.Position = UDim2.fromOffset(-2, 0)
			tween(glitch1, { TextTransparency = 0.85 }, 0.3)
			tween(glitch2, { TextTransparency = 0.85 }, 0.3)
		end)

		tween(glow, { TextTransparency = 0.55 }, 0.4)

		task.spawn(function()
			while viva and glow.Parent do
				tween(glow, { TextTransparency = 0.35 }, 0.8, Enum.EasingStyle.Sine)
				task.wait(0.8)
				tween(glow, { TextTransparency = 0.6 }, 0.8, Enum.EasingStyle.Sine)
				task.wait(0.8)
			end
		end)

		task.wait(0.2)
		if not viva then return end

		task.spawn(function()
			local passos = {
				{ 0, 0.05 }, { 1, 0.03 }, { 0.2, 0.05 }, { 1, 0.04 },
				{ 0, 0.06 }, { 0.6, 0.05 }, { 0, 0.07 }, { 1, 0.05 },
				{ 0.1, 0.05 }, { 0, 0.09 },
			}
			for _, passo in ipairs(passos) do
				if not viva then return end
				principal.TextTransparency = passo[1]
				task.wait(passo[2])
			end
			if viva then
				tween(principal, { TextTransparency = 0 }, 0.15)
			end
		end)

		tween(principal, { TextStrokeTransparency = 0.4 }, 1.0)

		local escala = novo("UIScale", {}, titulo)

		task.spawn(function()
			while viva and titulo.Parent do
				tween(escala, { Scale = 1.04 }, 0.9, Enum.EasingStyle.Sine)
				task.wait(0.9)
				tween(escala, { Scale = 1 }, 0.9, Enum.EasingStyle.Sine)
				task.wait(0.9)
			end
		end)

		task.wait(1.0)
		if not viva then return end

		tween(linha, { Size = UDim2.new(0, 220, 0, 2) }, 0.5)

		task.wait(0.3)
		if not viva then return end

		tween(subtitulo, { TextTransparency = 0.15 }, 0.5)

		task.wait(0.4)
		if not viva then return end

		tween(labelCarregando, { TextTransparency = 0.3 }, 0.4)
		tween(labelPercent, { TextTransparency = 0 }, 0.4)
		tween(barraFundo, { BackgroundTransparency = 0.5 }, 0.4)

		task.wait(0.2)

		local duracao = 1.8
		local inicio = os.clock()

		while viva and os.clock() - inicio < duracao do
			local progresso = math.min(1, (os.clock() - inicio) / duracao)
			barraFill.Size = UDim2.new(progresso, 0, 1, 0)
			labelPercent.Text = ("%d%%"):format(math.floor(progresso * 100))
			task.wait(0.02)
		end

		if not viva then return end

		barraFill.Size = UDim2.new(1, 0, 1, 0)
		labelPercent.Text = "100%"

		task.wait(0.4)
		if not viva then return end

		for _, alvo in ipairs({
			{ labelCarregando, { TextTransparency = 1 } },
			{ labelPercent, { TextTransparency = 1 } },
			{ barraFundo, { BackgroundTransparency = 1 } },
			{ barraFill, { BackgroundTransparency = 1 } },
			{ subtitulo, { TextTransparency = 1 } },
			{ linha, { BackgroundTransparency = 1 } },
			{ principal, { TextTransparency = 1, TextStrokeTransparency = 1 } },
			{ glow, { TextTransparency = 1 } },
			{ glitch1, { TextTransparency = 1 } },
			{ glitch2, { TextTransparency = 1 } },
		}) do
			tween(alvo[1], alvo[2], 0.4)
		end

		task.wait(0.5)
		if not viva then return end

		tween(bg, { BackgroundTransparency = 1 }, 0.8)

		task.wait(0.9)
		fechar()

	end)

end

if CONFIG.mostrarIntro then
	task.spawn(rodarIntro)
end

-- =========================================================
--                LEITURA REAL DOS TOKENS
-- =========================================================
-- Lê do próprio HUD do jogo:
-- PlayerGui > HUD > Spendables > TokenRow > Tokens

local tokensLabel

task.spawn(function()

	local ok, resultado = pcall(function()
		local hud = PlayerGui:WaitForChild("HUD", 15)
		local spendables = hud:WaitForChild("Spendables", 15)
		local tokenRow = spendables:WaitForChild("TokenRow", 15)
		return tokenRow:WaitForChild("Tokens", 15)
	end)

	if ok and resultado then
		tokensLabel = resultado
	else
		warn("[SamMods] HUD.Spendables.TokenRow.Tokens não encontrado; usando o atributo Tokens como fallback.")
	end

end)

local function lerTokens()

	if tokensLabel and tokensLabel.Parent then
		local valor = parseAbreviado(tokensLabel.Text)
		if valor then
			return valor
		end
	end

	return tonumber(LocalPlayer:GetAttribute("Tokens")) or 0

end

-- =========================================================
--                  CONFIGURAÇÕES DO JOGO
-- =========================================================

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local OpenTokenExchange = Remotes:FindFirstChild("OpenTokenExchange")
local HackEvent = Remotes:WaitForChild("HackEvent")

local PRICE_MIN = math.floor(lerNumero(Config.Tokens.priceMin, 5))
local PRICE_MAX = math.floor(lerNumero(Config.Tokens.priceMax, 15))
local PRICE_SPIKE = math.floor(lerNumero(Config.Tokens.spikePrice, 12))
local PRICE_BASE = math.floor(lerNumero(Config.Tokens.basePrice, 10))
local EPOCH = math.max(1, math.floor(lerNumero(Config.Tokens.priceEpochSeconds, 30)))

-- =========================================================
--                          SONS
-- =========================================================

local function pegarSom(nome, id, volume, loop)

	local som = SoundService:FindFirstChild(nome)

	if not som then
		som = novo("Sound", { Name = nome }, SoundService)
	end

	som.SoundId = id
	som.Volume = volume
	som.Looped = loop or false

	return som

end

local AlertSound = pegarSom("SamMods_HackAlert", CONFIG.somAlertaId, CONFIG.somAlertaVolume, true)
local NotifySound = pegarSom("SamMods_Notify", CONFIG.somNotifyId, CONFIG.somNotifyVolume, false)

local function tocar(som)
	som:Stop()
	som.TimePosition = 0
	som:Play()
end

-- =========================================================
--                        UI RAIZ
-- =========================================================

local gui = novo("ScreenGui", {
	Name = "SamModsMainGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 10,
}, PlayerGui)

jan:add(gui)

local container = novo("Frame", {
	Name = "Container",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 92),
	Size = UDim2.fromOffset(CARD_W, CARD_H),
	BackgroundTransparency = 1,
	ZIndex = 10,
}, gui)

-- ---------------------- Aura externa ----------------------

local aura = novo("Frame", {
	Name = "MaxAura",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 9,
}, container)

cantos(aura, 14)

local auraStroke = contorno(aura, CORES.Max, 5, 0.75)

-- -------------------------- Card --------------------------

local card = novo("TextButton", {
	Name = "PriceCard",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = CORES.Fundo,
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	ZIndex = 10,
}, container)

cantos(card, 14)

local cardScale = novo("UIScale", {}, card)
local cardStroke = contorno(card, CORES.Base, 1.2, 0.8)

novo("UIPadding", {
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 4),
	PaddingLeft = UDim.new(0, 9),
	PaddingRight = UDim.new(0, 9),
}, card)

local shine = novo("Frame", {
	Name = "Shine",
	BackgroundColor3 = CORES.Texto,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.new(-0.5, 0, 0, 0),
	Size = UDim2.new(0.35, 0, 1, 0),
	Rotation = 15,
	ZIndex = 11,
}, card)

novo("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, shine)

local priceLabel = novo("TextLabel", {
	Name = "PriceLabel",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 2),
	Size = UDim2.new(0, 100, 0, 18),
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = CORES.Texto,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = ("💰 $%d"):format(PRICE_BASE),
	ZIndex = 13,
}, card)

local earningsLabel = novo("TextLabel", {
	Name = "EarningsLabel",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 21),
	Size = UDim2.new(1, 0, 0, 11),
	Font = Enum.Font.GothamBold,
	TextSize = 9,
	TextColor3 = Color3.fromRGB(220, 225, 235),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "💎 Tokens: 0  •  💰 Receber: $0",
	ZIndex = 13,
}, card)

local timerLabel = novo("TextLabel", {
	Name = "TimerLabel",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 33),
	Size = UDim2.new(1, 0, 0, 14),
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	TextColor3 = Color3.fromRGB(225, 228, 238),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "--s",
	ZIndex = 13,
}, card)

local statusBadge = novo("TextLabel", {
	Name = "StatusBadge",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 2),
	Size = UDim2.fromOffset(58, 16),
	BackgroundColor3 = CORES.Base,
	BackgroundTransparency = 0.2,
	Font = Enum.Font.GothamBold,
	TextSize = 9,
	TextColor3 = CORES.Texto,
	Text = "NORMAL",
	ZIndex = 14,
}, card)

cantos(statusBadge, 4)
local badgeStroke = contorno(statusBadge, CORES.Base, 1, 0.5)

-- --------------- Mini gráfico de histórico ---------------

local sparkline = novo("Frame", {
	Name = "Sparkline",
	Position = UDim2.new(0, 0, 0, 48),
	Size = UDim2.new(1, 0, 0, 12),
	BackgroundTransparency = 1,
	ZIndex = 12,
}, card)

local barrasHistorico = {}

do
	local n = CONFIG.historicoTamanho
	local largura = 1 / n

	for i = 1, n do
		barrasHistorico[i] = novo("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new((i - 1) * largura, 0, 1, 0),
			Size = UDim2.new(largura, -1, 0, 1),
			BackgroundColor3 = CORES.Base,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 12,
		}, sparkline)
	end
end

local function registrarHistorico(preco)

	table.insert(historicoPreco, preco)

	while #historicoPreco > CONFIG.historicoTamanho do
		table.remove(historicoPreco, 1)
	end

	local base = #historicoPreco
	local faixa = math.max(1, PRICE_MAX - PRICE_MIN)

	for i, barra in ipairs(barrasHistorico) do

		local idx = i - (#barrasHistorico - base)
		local valor = historicoPreco[idx]

		if valor then
			local prop = math.clamp((valor - PRICE_MIN) / faixa, 0, 1)
			barra.Size = UDim2.new(barra.Size.X.Scale, -1, 0, 2 + prop * 10)
			barra.BackgroundTransparency = 0.35
			barra.BackgroundColor3 =
				valor >= PRICE_MAX and CORES.Max
				or valor >= PRICE_SPIKE and CORES.Spike
				or valor <= PRICE_MIN and CORES.Min
				or CORES.Base
		else
			barra.Size = UDim2.new(barra.Size.X.Scale, -1, 0, 1)
			barra.BackgroundTransparency = 0.85
		end

	end

end

-- -------------------- Barra de progresso -------------------

local progressBackground = novo("Frame", {
	Name = "ProgressBackground",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 2),
	BackgroundColor3 = CORES.Texto,
	BackgroundTransparency = 0.9,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 12,
}, card)

local progressBar = novo("Frame", {
	Name = "ProgressBar",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = CORES.Base,
	BorderSizePixel = 0,
	ZIndex = 12,
}, progressBackground)

-- ------------------------ Sparkles -------------------------

local sparkleContainer = novo("Frame", {
	Name = "Sparkles",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 20,
}, card)

local sparkles = {}

for i = 1, 8 do
	sparkles[i] = novo("TextLabel", {
		Name = "Sparkle_" .. i,
		BackgroundTransparency = 1,
		Text = "✦",
		TextSize = math.random(8, 15),
		Font = Enum.Font.GothamBold,
		TextColor3 = CORES.Texto,
		Visible = false,
		ZIndex = 21,
	}, sparkleContainer)
end

-- =========================================================
--                    BOTÕES LATERAIS
-- =========================================================
-- Coluna de botõezinhos à esquerda do card. Cada um faz
-- exatamente o que o ícone diz (na v1 o 📢 mexia no som).

local barraBotoes = novo("Frame", {
	Name = "SideButtons",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(0, -6, 0, 0),
	Size = UDim2.fromOffset(24, 110),
	BackgroundTransparency = 1,
	ZIndex = 15,
}, container)

novo("UIListLayout", {
	Padding = UDim.new(0, 4),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, barraBotoes)

local function botaoIcone(icone, ordem, dica)

	local b = novo("TextButton", {
		Name = "Icon_" .. ordem,
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = CORES.Fundo2,
		BackgroundTransparency = 0.1,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		Text = icone,
		TextColor3 = CORES.Texto,
		LayoutOrder = ordem,
		ZIndex = 16,
	}, barraBotoes)

	cantos(b, 6)
	contorno(b, CORES.Texto, 1, 0.75)

	b.MouseEnter:Connect(function()
		tween(b, { BackgroundTransparency = 0 }, 0.15)
	end)

	b.MouseLeave:Connect(function()
		tween(b, { BackgroundTransparency = 0.1 }, 0.15)
	end)

	if dica then
		b.Name = dica
	end

	return b

end

local btnConfig = botaoIcone("⚙", 1, "BtnConfig")
local btnSom = botaoIcone("🔔", 2, "BtnSom")
local btnChat = botaoIcone("📢", 3, "BtnChat")
local btnPlayers = botaoIcone("👥", 4, "BtnPlayers")

-- =========================================================
--             BOTÕES DE AÇÃO CONTRA O LADRÃO
-- =========================================================

local function botaoLargo(nome, texto, corFundo, y)

	local b = novo("TextButton", {
		Name = nome,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 1, y),
		Size = UDim2.fromOffset(CARD_W, 28),
		BackgroundColor3 = corFundo,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		TextColor3 = CORES.Texto,
		Text = texto,
		Visible = false,
		ZIndex = 15,
	}, container)

	cantos(b, 10)

	return b

end

local lockButton = botaoLargo("LockOnThief", "🔓 Travar no ladrão", CORES.Fundo2, 8)
local teleportButton = botaoLargo("GoToThief", "🏃 Ir até o ladrão", CORES.Perigo, 40)

-- =========================================================
--                  PAINEL (CONFIG / LOG / STATS)
-- =========================================================

local painel = novo("Frame", {
	Name = "Painel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.fromOffset(268, 250),
	BackgroundColor3 = CORES.Fundo,
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 30,
}, gui)

cantos(painel, 12)
contorno(painel, CORES.Base, 1.2, 0.6)

novo("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, painel)

-- Arrastar painel de configurações pelo título
do
	local arrastando = false
	local inicioMouse
	local inicioPos

	painelTitulo.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if S.travadoHud then return end
			arrastando = true
			inicioMouse = input.Position
			inicioPos = painel.AbsolutePosition
			painel.AnchorPoint = Vector2.new(0, 0)
			painel.Position = UDim2.fromOffset(inicioPos.X, inicioPos.Y)
		end
	end)

	jan:add(UserInputService.InputChanged:Connect(function(input)
		if not arrastando then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local delta = input.Position - inicioMouse
		painel.Position = UDim2.fromOffset(
			math.floor(inicioPos.X + delta.X),
			math.floor(inicioPos.Y + delta.Y)
		)
	end))

	jan:add(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			arrastando = false
		end
	end))
end

local painelTitulo = novo("TextLabel", {
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextSize = 12,
	TextColor3 = CORES.Texto,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "SamMods • Painel",
	ZIndex = 31,
}, painel)

Rainbow.add(painelTitulo, function(cor)
	painelTitulo.TextColor3 = cor
end)

local abasFrame = novo("Frame", {
	Position = UDim2.new(0, 0, 0, 20),
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundTransparency = 1,
	ZIndex = 31,
}, painel)

novo("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, abasFrame)

local conteudoAbas = {}
local botoesAbas = {}
local abaAtual = "Config"

local function selecionarAba(nome)

	abaAtual = nome

	for chave, frame in pairs(conteudoAbas) do
		frame.Visible = (chave == nome)
	end

	for chave, botao in pairs(botoesAbas) do
		local ativo = (chave == nome)
		botao.BackgroundTransparency = ativo and 0.05 or 0.55
		botao.TextColor3 = ativo and CORES.Texto or CORES.TextoFraco
	end

end

local function criarAba(nome, rotulo, ordem)

	local botao = novo("TextButton", {
		Name = "Aba_" .. nome,
		Size = UDim2.fromOffset(80, 22),
		BackgroundColor3 = CORES.Fundo2,
		BackgroundTransparency = 0.55,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Text = rotulo,
		TextColor3 = CORES.TextoFraco,
		LayoutOrder = ordem,
		ZIndex = 32,
	}, abasFrame)

	cantos(botao, 6)

	local conteudo = novo("ScrollingFrame", {
		Name = "Conteudo_" .. nome,
		Position = UDim2.new(0, 0, 0, 48),
		Size = UDim2.new(1, 0, 1, -48),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = CORES.Base,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = 31,
	}, painel)

	novo("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, conteudo)

	botoesAbas[nome] = botao
	conteudoAbas[nome] = conteudo

	botao.MouseButton1Click:Connect(function()
		selecionarAba(nome)
	end)

	return conteudo

end

local abaConfig = criarAba("Config", "⚙ Config", 1)
local abaRoubos = criarAba("Roubos", "🚨 Roubos", 2)
local abaStats = criarAba("Stats", "📊 Stats", 3)

-- --------------------- Linhas de config --------------------

local function linhaToggle(pai, chave, rotulo, ordem, aoMudar)

	local linha = novo("TextButton", {
		Name = "Toggle_" .. chave,
		Size = UDim2.new(1, -6, 0, 26),
		BackgroundColor3 = CORES.Fundo2,
		BackgroundTransparency = 0.35,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = ordem,
		ZIndex = 32,
	}, pai)

	cantos(linha, 6)

	novo("TextLabel", {
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -54, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = CORES.Texto,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = rotulo,
		ZIndex = 33,
	}, linha)

	local trilho = novo("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(34, 16),
		BackgroundColor3 = CORES.Fundo,
		BorderSizePixel = 0,
		ZIndex = 33,
	}, linha)

	cantos(trilho, 99)

	local bolinha = novo("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = CORES.TextoFraco,
		BorderSizePixel = 0,
		ZIndex = 34,
	}, trilho)

	cantos(bolinha, 99)

	local function pintar()
		local ligado = S[chave]
		tween(bolinha, {
			Position = ligado and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			BackgroundColor3 = ligado and CORES.Ok or CORES.TextoFraco,
		}, 0.15)
		tween(trilho, {
			BackgroundColor3 = ligado and Color3.fromRGB(30, 70, 45) or CORES.Fundo,
		}, 0.15)
	end

	linha.MouseButton1Click:Connect(function()
		S[chave] = not S[chave]
		pintar()
		if aoMudar then
			aoMudar(S[chave])
		end
	end)

	pintar()

	return linha

end

local function linhaTexto(pai, rotulo, ordem)

	local label = novo("TextLabel", {
		Size = UDim2.new(1, -6, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = CORES.TextoFraco,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = rotulo,
		LayoutOrder = ordem,
		ZIndex = 32,
	}, pai)

	return label

end

local function linhaInput(pai, rotulo, valorInicial, ordem, aoConfirmar)

	local linha = novo("Frame", {
		Size = UDim2.new(1, -6, 0, 26),
		BackgroundColor3 = CORES.Fundo2,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		LayoutOrder = ordem,
		ZIndex = 32,
	}, pai)

	cantos(linha, 6)

	novo("TextLabel", {
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(0.55, -8, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = CORES.Texto,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = rotulo,
		ZIndex = 33,
	}, linha)

	local caixa = novo("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0.4, 0, 0, 18),
		BackgroundColor3 = CORES.Fundo,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = CORES.Texto,
		Text = tostring(valorInicial),
		ClearTextOnFocus = false,
		PlaceholderText = "0 = off",
		ZIndex = 33,
	}, linha)

	cantos(caixa, 4)

	caixa.FocusLost:Connect(function(enter)
		if enter then
			aoConfirmar(parseAbreviado(caixa.Text) or 0)
		end
	end)

	return caixa

end

-- =========================================================
--                  FILA DE NOTIFICAÇÕES
-- =========================================================
-- Empilha em vez de sobrescrever (a v1 tinha um frame só).

local notifyGui = novo("ScreenGui", {
	Name = "SamModsNotifyGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 200,
}, PlayerGui)

jan:add(notifyGui)

local notifyPilha = novo("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 16),
	Size = UDim2.fromOffset(330, 400),
	BackgroundTransparency = 1,
	ZIndex = 200,
}, notifyGui)

novo("UIListLayout", {
	Padding = UDim.new(0, 6),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, notifyPilha)

local notifyOrdem = 0

--[[
	opcoes = {
		titulo, texto, imagem, cor, duracao,
		rainbow (bool), som (bool)
	}
]]
local function notificar(opcoes)

	if not S.notificacoes then
		return
	end

	notifyOrdem += 1

	local frame = novo("Frame", {
		Name = "Notif_" .. notifyOrdem,
		Size = UDim2.fromOffset(330, 60),
		BackgroundColor3 = CORES.Fundo,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		LayoutOrder = notifyOrdem,
		ZIndex = 201,
	}, notifyPilha)

	cantos(frame, 10)

	local borda = contorno(frame, opcoes.cor or CORES.Base, 1.5, 0.25)

	if opcoes.rainbow then
		Rainbow.add(borda, function(cor)
			borda.Color = cor
		end)
	end

	local esquerdaX = 10

	if opcoes.imagem then

		local foto = novo("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(44, 44),
			BackgroundColor3 = Color3.fromRGB(10, 10, 14),
			Image = opcoes.imagem,
			ZIndex = 202,
		}, frame)

		cantos(foto, 99)

		local fotoStroke = contorno(foto, opcoes.cor or CORES.Base, 1.5, 0.2)

		if opcoes.rainbow then
			Rainbow.add(fotoStroke, function(cor)
				fotoStroke.Color = cor
			end)
		end

		esquerdaX = 60

	end

	novo("TextLabel", {
		Position = UDim2.new(0, esquerdaX, 0, 8),
		Size = UDim2.new(1, -esquerdaX - 10, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 13,
		TextColor3 = CORES.Texto,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = opcoes.titulo or "",
		ZIndex = 202,
	}, frame)

	novo("TextLabel", {
		Position = UDim2.new(0, esquerdaX, 0, 26),
		Size = UDim2.new(1, -esquerdaX - 10, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(215, 220, 230),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = opcoes.texto or "",
		ZIndex = 202,
	}, frame)

	if opcoes.som ~= false then
		tocar(NotifySound)
	end

	frame.BackgroundTransparency = 1
	frame.Position = UDim2.new(0, 40, 0, 0)
	tween(frame, { BackgroundTransparency = 0.1 }, 0.25)

	task.delay(opcoes.duracao or 4.5, function()
		if frame.Parent then
			local saida = tween(frame, { BackgroundTransparency = 1 }, 0.3)
			saida.Completed:Wait()
			if frame.Parent then
				frame:Destroy()
			end
		end
	end)

	return frame

end

-- =========================================================
--                   MENSAGEM NO CHAT
-- =========================================================

local CHAT_COOLDOWN_ATTR = "SamMods_LastChatMessage"

local function enviarMensagemChat(texto)

	texto = texto or CONFIG.mensagemMaximo

	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then

		local canais = TextChatService:FindFirstChild("TextChannels")
		local geral = canais and canais:FindFirstChild("RBXGeneral")

		if geral then
			local ok = pcall(function()
				geral:SendAsync(texto)
			end)
			if ok then
				return true
			end
		end

	end

	local ok = pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = texto,
			Font = Enum.Font.GothamBold,
			TextSize = 18,
		})
	end)

	return ok

end

-- Retorna: enviou (bool), segundosRestantes (number)
local function tentarEnviarMensagem()

	local agora = os.clock()
	local ultimo = PlayerGui:GetAttribute(CHAT_COOLDOWN_ATTR) or -math.huge
	local passou = agora - ultimo

	if passou >= CONFIG.chatCooldown then
		PlayerGui:SetAttribute(CHAT_COOLDOWN_ATTR, agora)
		enviarMensagemChat()
		return true, 0
	end

	return false, math.ceil(CONFIG.chatCooldown - passou)

end

-- =========================================================
--                    ARRASTAR O PAINEL
-- =========================================================
-- Clique curto = abrir a loja. Clique com movimento = arrastar.

local POSICAO_ATTR = "SamMods_PosicaoPainel"

local arrastouAgora = function()
	return false
end

do
	local arrastando = false
	local moveu = false
	local inicioMouse
	local inicioPos

	local function aplicarPosicaoSalva()
		local salvo = PlayerGui:GetAttribute(POSICAO_ATTR)
		if typeof(salvo) == "Vector2" then
			container.Position = UDim2.new(0, salvo.X, 0, salvo.Y)
			container.AnchorPoint = Vector2.new(0, 0)
		end
	end

	aplicarPosicaoSalva()

	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if S.travadoHud then return end
			arrastando = true
			moveu = false
			inicioMouse = input.Position
			inicioPos = container.AbsolutePosition
		end
	end)

	jan:add(UserInputService.InputChanged:Connect(function(input)

		if not arrastando then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - inicioMouse

		if delta.Magnitude > 4 then
			moveu = true
		end

		if moveu then
			container.AnchorPoint = Vector2.new(0, 0)
			container.Position = UDim2.new(
				0,
				math.floor(inicioPos.X + delta.X),
				0,
				math.floor(inicioPos.Y + delta.Y)
			)
		end

	end))

	jan:add(UserInputService.InputEnded:Connect(function(input)

		if not arrastando then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		arrastando = false

		if moveu then
			PlayerGui:SetAttribute(POSICAO_ATTR, container.AbsolutePosition)
		end

	end))

	-- Usado pelo clique do card para saber se foi arrasto.
	arrastouAgora = function()
		return moveu
	end
end

-- =========================================================
--                 EFEITOS DO MODO MÁXIMO
-- =========================================================

local maximoAtivo = false
local janMaximo = nil

local function pararEfeitoMaximo()

	if not maximoAtivo then
		return
	end

	maximoAtivo = false

	if janMaximo then
		janMaximo:destroy()
		janMaximo = nil
	end

	Rainbow.remove(cardStroke)

	aura.Visible = false
	sparkleContainer.Visible = false
	cardScale.Scale = 1
	cardStroke.Thickness = 1.2

end

local function iniciarEfeitoMaximo()

	if maximoAtivo then
		return
	end

	maximoAtivo = true
	stats.vezesNoMaximo += 1

	if S.avisoChatAuto then
		tentarEnviarMensagem()
	end

	if not S.efeitosMaximo then
		return
	end

	janMaximo = Janitor.new()

	aura.Visible = true
	sparkleContainer.Visible = true

	Rainbow.add(cardStroke, function(cor)
		cardStroke.Color = cor
		auraStroke.Color = cor
		badgeStroke.Color = cor
		progressBar.BackgroundColor3 = cor
		statusBadge.BackgroundColor3 = cor
		priceLabel.TextColor3 = cor
		shine.BackgroundColor3 = cor
	end)

	janMaximo:add(function()
		Rainbow.remove(cardStroke)
	end)

	local pulseTime = 0

	janMaximo:add(RunService.RenderStepped:Connect(function(dt)

		pulseTime += dt * 4

		local onda = (math.sin(pulseTime) + 1) / 2

		cardScale.Scale = 1 + onda * 0.035
		cardStroke.Thickness = 1.2 + onda * 2
		cardStroke.Transparency = 0.15 + onda * 0.25
		auraStroke.Transparency = 0.45 + onda * 0.3

	end))

	task.spawn(function()
		while maximoAtivo and card.Parent do
			shine.Position = UDim2.new(-0.5, 0, 0, 0)
			local t = tween(shine, { Position = UDim2.new(1.2, 0, 0, 0) }, 1.1, Enum.EasingStyle.Linear)
			t.Completed:Wait()
			task.wait(0.25)
		end
	end)

	task.spawn(function()
		while maximoAtivo and card.Parent do
			for _, sparkle in ipairs(sparkles) do
				if not maximoAtivo then
					break
				end
				sparkle.Visible = true
				sparkle.Position = UDim2.new(math.random(), 0, math.random(), 0)
				sparkle.TextTransparency = 0
				local pos = sparkle.Position
				tween(sparkle, {
					Position = UDim2.new(pos.X.Scale, 0, pos.Y.Scale - 0.25, 0),
					TextTransparency = 1,
					TextSize = math.random(14, 22),
				}, 0.6)
				task.wait(0.08)
			end
			task.wait(0.15)
		end
	end)

end

-- =========================================================
--                     TEMA / ANIMAÇÕES
-- =========================================================

local function aplicarTema(cor, transparenciaBorda, textoBadge)

	if maximoAtivo and S.efeitosMaximo then
		statusBadge.Text = textoBadge
		return
	end

	tween(progressBar, { BackgroundColor3 = cor }, 0.3)
	tween(cardStroke, { Color = cor, Transparency = transparenciaBorda }, 0.3)
	tween(statusBadge, { BackgroundColor3 = cor }, 0.3)
	tween(priceLabel, { TextColor3 = cor }, 0.3)

	badgeStroke.Color = cor
	statusBadge.Text = textoBadge
	statusBadge.TextColor3 = CORES.Texto

end

local function animarPreco()
	local sobe = tween(priceLabel, { TextSize = 17 }, 0.1)
	sobe.Completed:Connect(function()
		tween(priceLabel, { TextSize = 15 }, 0.15, Enum.EasingStyle.Back)
	end)
end

-- =========================================================
--                     HACK ALERT
-- =========================================================

local modoDiscreto = false
local alertaAtivo = false
local ladraoPersonagem = nil
local ladraoJogador = nil
local janEsp = nil
local setaLadrao = nil

local function pararAlerta()

	if not alertaAtivo then
		return
	end

	alertaAtivo = false
	AlertSound:Stop()
	AlertSound.TimePosition = 0

end

local function iniciarAlerta()

	if alertaAtivo then
		return
	end

	alertaAtivo = true

	if S.somAlerta then
		tocar(AlertSound)
	end

end

-- --------------------- Travar / teleporte -------------------

local travadoNoLadrao = false
local glueConn = nil

local function soltarLadrao()
	if glueConn then
		glueConn:Disconnect()
		glueConn = nil
	end
end

local function meuRoot()
	local personagem = LocalPlayer.Character
	return personagem and personagem:FindFirstChild("HumanoidRootPart")
end

local function rootLadrao()
	return ladraoPersonagem and ladraoPersonagem:FindFirstChild("HumanoidRootPart")
end

local function irAteLadrao()

	local meu = meuRoot()
	local alvo = rootLadrao()

	if meu and alvo then
		meu.CFrame = alvo.CFrame * CFrame.new(0, 0, 4)
		return true
	end

	return false

end

local function grudarNoLadrao()

	if glueConn then
		return
	end

	glueConn = jan:add(RunService.Heartbeat:Connect(function()

		local meu = meuRoot()
		local alvo = rootLadrao()

		if meu and alvo then
			meu.CFrame = alvo.CFrame * CFrame.new(0, 0, 4)
		else
			soltarLadrao()
		end

	end))

end

local function atualizarBotaoTravar()

	if travadoNoLadrao then
		lockButton.Text = "🔒 Travado no ladrão"
		lockButton.BackgroundColor3 = CORES.Perigo
	else
		lockButton.Text = "🔓 Travar no ladrão"
		lockButton.BackgroundColor3 = CORES.Fundo2
		soltarLadrao()
	end

end

lockButton.MouseButton1Click:Connect(function()

	travadoNoLadrao = not travadoNoLadrao
	atualizarBotaoTravar()

	if travadoNoLadrao then
		grudarNoLadrao()
	end

end)

teleportButton.MouseButton1Click:Connect(function()

	if travadoNoLadrao then
		grudarNoLadrao()
	else
		irAteLadrao()
	end

end)

-- ---------------------- Seta indicadora ---------------------

local function criarSeta()

	if setaLadrao then
		return setaLadrao
	end

	local seta = novo("TextLabel", {
		Name = "SetaLadrao",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(46, 46),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 34,
		Text = "➤",
		TextColor3 = CORES.Perigo,
		Visible = false,
		ZIndex = 150,
	}, gui)

	contorno(seta, Color3.fromRGB(0, 0, 0), 2, 0.3)

	Rainbow.add(seta, function(cor)
		seta.TextColor3 = cor
	end)

	setaLadrao = seta

	return seta

end

local function atualizarSeta()

	local seta = setaLadrao

	if not seta then
		return
	end

	local alvo = rootLadrao()

	if not alvo or not S.setaLadrao then
		seta.Visible = false
		return
	end

	local camera = Workspace.CurrentCamera

	if not camera then
		seta.Visible = false
		return
	end

	local pos, naTela = camera:WorldToViewportPoint(alvo.Position)
	local tamanho = camera.ViewportSize
	local centro = Vector2.new(tamanho.X / 2, tamanho.Y / 2)

	if naTela and pos.Z > 0
		and pos.X > 0 and pos.X < tamanho.X
		and pos.Y > 0 and pos.Y < tamanho.Y then
		seta.Visible = false
		return
	end

	local dir = Vector2.new(pos.X, pos.Y) - centro

	if pos.Z < 0 then
		dir = -dir
	end

	if dir.Magnitude < 1 then
		dir = Vector2.new(0, -1)
	end

	dir = dir.Unit

	local raio = math.min(tamanho.X, tamanho.Y) * 0.38
	local ponto = centro + dir * raio

	seta.Visible = true
	seta.Position = UDim2.fromOffset(ponto.X, ponto.Y)
	seta.Rotation = math.deg(math.atan2(dir.Y, dir.X))

end

-- --------------------------- ESP ---------------------------

local function limparEsp()

	if janEsp then
		janEsp:destroy()
		janEsp = nil
	end

	soltarLadrao()

	travadoNoLadrao = false
	atualizarBotaoTravar()

	ladraoPersonagem = nil
	ladraoJogador = nil

	teleportButton.Visible = false
	lockButton.Visible = false

	if setaLadrao then
		setaLadrao.Visible = false
	end

end

local function mostrarEsp(userId)

	if not userId or userId == 0 then
		return
	end

	limparEsp()

	local jogador = Players:GetPlayerByUserId(userId)

	if not jogador then
		return
	end

	ladraoJogador = jogador

	task.spawn(function()

		local personagem = jogador.Character or jogador.CharacterAdded:Wait()
		local root = personagem:WaitForChild("HumanoidRootPart", 5)

		if not root or not alertaAtivo then
			return
		end

		ladraoPersonagem = personagem

		teleportButton.Visible = true
		lockButton.Visible = true

		if S.autoTravar then
			travadoNoLadrao = true
			atualizarBotaoTravar()
			grudarNoLadrao()
		end

		if not S.espLadrao then
			return
		end

		janEsp = Janitor.new()

		local highlight = janEsp:add(novo("Highlight", {
			FillTransparency = 0.75,
			OutlineTransparency = 0,
			DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		}, personagem))

		local billboard = janEsp:add(novo("BillboardGui", {
			Name = "SamModsHackerEsp",
			Adornee = root,
			Size = UDim2.fromOffset(90, 100),
			StudsOffset = Vector3.new(0, 3.2, 0),
			AlwaysOnTop = true,
			MaxDistance = 500,
		}, personagem))

		local avatar = novo("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			Size = UDim2.fromOffset(46, 46),
			BackgroundColor3 = Color3.fromRGB(15, 17, 22),
			BackgroundTransparency = 0.15,
			Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(userId),
		}, billboard)

		cantos(avatar, 99)

		local avatarStroke = contorno(avatar, CORES.Perigo, 2.5, 0)

		local nomeLabel = novo("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 48),
			Size = UDim2.new(1.6, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 14,
			Text = jogador.Name,
			TextColor3 = CORES.Texto,
		}, billboard)

		local nomeStroke = contorno(nomeLabel, Color3.fromRGB(0, 0, 0), 2, 0)

		local distLabel = novo("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 66),
			Size = UDim2.new(1.6, 0, 0, 16),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			Text = "-- studs",
			TextColor3 = Color3.fromRGB(230, 230, 235),
		}, billboard)

		contorno(distLabel, Color3.fromRGB(0, 0, 0), 1.5, 0)

		Rainbow.add(highlight, function(cor)
			highlight.OutlineColor = cor
			highlight.FillColor = cor
			avatarStroke.Color = cor
			nomeStroke.Color = cor
		end)

		janEsp:add(function()
			Rainbow.remove(highlight)
		end)

		local acumulado = 0

		janEsp:add(RunService.Heartbeat:Connect(function(dt)

			acumulado += dt

			if acumulado < 0.1 then
				return
			end

			acumulado = 0

			local meu = meuRoot()
			local alvo = personagem:FindFirstChild("HumanoidRootPart")

			if meu and alvo then
				distLabel.Text = ("%d studs"):format(
					math.floor((meu.Position - alvo.Position).Magnitude)
				)
			end

		end))

	end)

end

criarSeta()

-- A seta tem loop próprio: o ESP pode estar desligado
-- e ela continuar ligada.
do
	local acumulado = 0

	jan:add(RunService.Heartbeat:Connect(function(dt)

		acumulado += dt

		if acumulado < 0.06 then
			return
		end

		acumulado = 0

		if modoDiscreto then
			if setaLadrao then
				setaLadrao.Visible = false
			end
			return
		end

		atualizarSeta()

	end))
end

-- ------------------------ Log de roubos ---------------------

local function atualizarLogUI()

	for _, filho in ipairs(abaRoubos:GetChildren()) do
		if filho:IsA("GuiObject") then
			filho:Destroy()
		end
	end

	if #logRoubos == 0 then
		linhaTexto(abaRoubos, "Nenhum roubo registrado nesta sessão.", 1)
		return
	end

	for i = #logRoubos, 1, -1 do

		local registro = logRoubos[i]

		local linha = novo("Frame", {
			Size = UDim2.new(1, -6, 0, 30),
			BackgroundColor3 = CORES.Fundo2,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			LayoutOrder = #logRoubos - i,
			ZIndex = 32,
		}, abaRoubos)

		cantos(linha, 6)

		novo("TextLabel", {
			Position = UDim2.new(0, 8, 0, 3),
			Size = UDim2.new(1, -16, 0, 14),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = CORES.Texto,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = ("%s  ×%d"):format(registro.nome, registro.vezes),
			ZIndex = 33,
		}, linha)

		novo("TextLabel", {
			Position = UDim2.new(0, 8, 0, 15),
			Size = UDim2.new(1, -16, 0, 12),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextColor3 = CORES.TextoFraco,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "último: " .. registro.hora,
			ZIndex = 33,
		}, linha)

	end

end

local function registrarRoubo(jogador)

	stats.roubosSofridos += 1

	local nome = jogador and jogador.Name or "Desconhecido"

	for _, registro in ipairs(logRoubos) do
		if registro.nome == nome then
			registro.vezes += 1
			registro.hora = horaAgora()
			atualizarLogUI()
			return
		end
	end

	table.insert(logRoubos, {
		nome = nome,
		vezes = 1,
		hora = horaAgora(),
		userId = jogador and jogador.UserId or 0,
	})

	atualizarLogUI()

end

-- ---------------------- Evento do jogo ----------------------

local KINDS_FIM = {
	robbery = true, roubo = true, steal = true, stealing = true,
	stolen = true, theft = true, robbery_start = true,
	robbery_end = true, steal_start = true, steal_end = true,
}

jan:add(HackEvent.OnClientEvent:Connect(function(data)

	if typeof(data) ~= "table" then
		return
	end

	local kind = tostring(data.kind or ""):lower()
	local action = tostring(data.action or ""):lower()
	local tipo = tostring(data.type or ""):lower()
	local role = tostring(data.role or ""):lower()
	local nome = tostring(data.name or "")

	if KINDS_FIM[kind] or KINDS_FIM[action] or KINDS_FIM[tipo] then
		pararAlerta()
		limparEsp()
		return
	end

	if kind == "phase" then

		if role == "victim" then

			local ladrao = Players:GetPlayerByUserId(tonumber(data.userId) or 0)

			if not alertaAtivo then
				registrarRoubo(ladrao)
				notificar({
					titulo = "🚨 ESTÃO TE ROUBANDO",
					texto = (ladrao and ladrao.Name or "Alguém") .. " está hackeando sua base",
					cor = CORES.Perigo,
					imagem = ladrao
						and ("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(ladrao.UserId)
						or nil,
					duracao = 6,
				})
			end

			iniciarAlerta()
			mostrarEsp(tonumber(data.userId))

		elseif role == "attacker" or (nome ~= "" and nome == LocalPlayer.Name) then

			-- Você é quem está roubando: não faz nada.

		else

			warn("[SamMods] role inesperado no HackEvent: '" .. tostring(data.role) .. "'")

		end

		return

	end

	if kind == "result" or kind == "abort" or kind == "end"
		or kind == "ended" or kind == "finish" or kind == "finished" then
		pararAlerta()
		limparEsp()
		return
	end

end))

-- =========================================================
--             NOTIFICAÇÃO DE CHAT (nomes especiais)
-- =========================================================

task.spawn(function()

	local canais = TextChatService:WaitForChild("TextChannels", 20)

	if not canais then
		return
	end

	local geral = canais:WaitForChild("RBXGeneral", 20)

	if not geral then
		return
	end

	jan:add(geral.MessageReceived:Connect(function(message)

		local fonte = message.TextSource

		if not fonte then
			return
		end

		local jogador = Players:GetPlayerByUserId(fonte.UserId)

		if not jogador or jogador == LocalPlayer then
			return
		end

		if CONFIG.nomesEspeciais[jogador.Name] then
			notificar({
				titulo = jogador.Name,
				texto = message.Text,
				imagem = ("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(jogador.UserId),
				rainbow = true,
				duracao = 5,
			})
		end

	end))

end)

-- =========================================================
--            TAG DE DONO/ADM/USUÁRIO ACIMA DA CABEÇA
-- =========================================================

local tagsAtivas = {}

local function removerTag(personagem)

	local tag = personagem:FindFirstChild("SamModsTag")

	if tag then
		local stroke = tagsAtivas[tag]
		if stroke then
			Rainbow.remove(stroke)
			tagsAtivas[tag] = nil
		end
		tag:Destroy()
	end

end

local function colocarTag(jogador, personagem)

	if not S.tagsJogadores then
		return
	end

	local root = personagem:WaitForChild("HumanoidRootPart", 5)

	if not root then
		return
	end

	removerTag(personagem)

	local billboard = novo("BillboardGui", {
		Name = "SamModsTag",
		Adornee = root,
		Size = UDim2.fromOffset(120, 20),
		StudsOffset = Vector3.new(0, 3, 0),
		AlwaysOnTop = true,
		MaxDistance = 120,
	}, personagem)

	local label = novo("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 13,
	}, billboard)

	local stroke = contorno(label, Color3.fromRGB(30, 30, 32), 1.5, 0)

	local ehDono = jogador.UserId == CONFIG.donoUserId
	local ehAdm = jogador.Name == CONFIG.admNome

	label.Text = ehDono and "OWNER" or ehAdm and "ADM" or "Usuário"

	if ehDono or ehAdm then
		label.TextColor3 = CORES.Texto
		tagsAtivas[billboard] = stroke
		Rainbow.add(stroke, function(cor)
			stroke.Color = cor
		end)
	else
		label.TextColor3 = Color3.fromRGB(160, 160, 165)
	end

end

local function acompanharJogador(jogador)

	if jogador.Character then
		task.spawn(colocarTag, jogador, jogador.Character)
	end

	jan:add(jogador.CharacterAdded:Connect(function(personagem)
		task.spawn(colocarTag, jogador, personagem)
	end))

end

for _, jogador in ipairs(Players:GetPlayers()) do
	acompanharJogador(jogador)
end

jan:add(Players.PlayerAdded:Connect(acompanharJogador))

local function reaplicarTags()

	for _, jogador in ipairs(Players:GetPlayers()) do

		local personagem = jogador.Character

		if personagem then
			if S.tagsJogadores then
				task.spawn(colocarTag, jogador, personagem)
			else
				removerTag(personagem)
			end
		end

	end

end

-- =========================================================
--                  METAS E MODO DISCRETO
-- =========================================================

local metaTokens = CONFIG.metaTokens
local metaValor = CONFIG.metaValor
local metaTokensAvisada = false
local metaValorAvisada = false

local function aplicarVisibilidade()
	container.Visible = not modoDiscreto
	notifyPilha.Visible = not modoDiscreto
	if setaLadrao then
		setaLadrao.Visible = setaLadrao.Visible and not modoDiscreto
	end
end

-- =========================================================
--                 CONTEÚDO DA ABA CONFIG
-- =========================================================

linhaTexto(abaConfig, "Funções", 0)

linhaToggle(abaConfig, "somAlerta", "🔔 Som de alerta de roubo", 1, function(ligado)
	if not ligado then
		AlertSound:Stop()
	elseif alertaAtivo then
		tocar(AlertSound)
	end
	btnSom.Text = ligado and "🔔" or "🔇"
end)

linhaToggle(abaConfig, "efeitosMaximo", "🌈 Efeitos do modo máximo", 2, function(ligado)
	if not ligado then
		pararEfeitoMaximo()
	end
end)

linhaToggle(abaConfig, "avisoChatAuto", "💬 Avisar no chat no máximo", 3)

linhaToggle(abaConfig, "espLadrao", "👁 Destacar o ladrão (ESP)", 4, function(ligado)
	if not ligado and janEsp then
		janEsp:destroy()
		janEsp = nil
	end
end)

linhaToggle(abaConfig, "setaLadrao", "➤ Seta apontando pro ladrão", 5)

linhaToggle(abaConfig, "tagsJogadores", "🏷 Tags acima da cabeça", 6, function()
	reaplicarTags()
end)

linhaToggle(abaConfig, "autoTravar", "🔒 Travar no ladrão automático", 7)

linhaToggle(abaConfig, "notificacoes", "🔔 Notificações na tela", 8)

linhaToggle(abaConfig, "travadoHud", "🔒 Travar HUD (sem mover painéis)", 9)

linhaTexto(abaConfig, "", 10)
linhaTexto(abaConfig, "Metas (0 = desligado)", 11)

linhaInput(abaConfig, "💎 Avisar com tokens ≥", metaTokens, 12, function(valor)
	metaTokens = valor
	metaTokensAvisada = false
end)

linhaInput(abaConfig, "💰 Avisar com valor ≥", metaValor, 13, function(valor)
	metaValor = valor
	metaValorAvisada = false
end)

linhaTexto(abaConfig, "", 14)
linhaTexto(abaConfig, "Atalhos: F1 esconder • F2 painel • F3 som", 15)
linhaTexto(abaConfig, "F4 mandar mensagem • F5 ir até o ladrão", 16)
linhaTexto(abaConfig, "Arraste os painéis pelo título (nome).", 17)

-- =========================================================
--                  CONTEÚDO DA ABA STATS
-- =========================================================

local statsLabels = {}

do
	local itens = {
		{ "tempo", "⏱ Tempo de sessão" },
		{ "tokens", "💎 Tokens agora" },
		{ "ganho", "📈 Ganho na sessão" },
		{ "porMin", "⚡ Tokens por minuto" },
		{ "valor", "💰 Valor a receber" },
		{ "maiorPreco", "🏆 Maior preço visto" },
		{ "maximos", "🌈 Vezes no máximo" },
		{ "roubos", "🚨 Roubos sofridos" },
	}

	for i, item in ipairs(itens) do

		local linha = novo("Frame", {
			Size = UDim2.new(1, -6, 0, 24),
			BackgroundColor3 = CORES.Fundo2,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			LayoutOrder = i,
			ZIndex = 32,
		}, abaStats)

		cantos(linha, 6)

		novo("TextLabel", {
			Position = UDim2.new(0, 8, 0, 0),
			Size = UDim2.new(0.62, -8, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			TextColor3 = CORES.TextoFraco,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = item[2],
			ZIndex = 33,
		}, linha)

		statsLabels[item[1]] = novo("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 0),
			Size = UDim2.new(0.38, 0, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = CORES.Texto,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "--",
			ZIndex = 33,
		}, linha)

	end
end

atualizarLogUI()
selecionarAba("Config")

-- =========================================================
--               PAINEL DE LISTA DE JOGADORES
-- =========================================================

local jogadorSelecionado = nil
local grudarJogadorAtivo = false
local grudarJogadorConn = nil

local function pararGrudarJogador()
	if grudarJogadorConn then
		grudarJogadorConn:Disconnect()
		grudarJogadorConn = nil
	end
	grudarJogadorAtivo = false
end

local painelPlayers = novo("Frame", {
	Name = "PainelPlayers",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.35, 0, 0.5, 0),
	Size = UDim2.fromOffset(260, 300),
	BackgroundColor3 = CORES.Fundo,
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 30,
}, gui)

cantos(painelPlayers, 12)
contorno(painelPlayers, CORES.Base, 1.2, 0.6)

novo("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, painelPlayers)

local playersTitulo = novo("TextLabel", {
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextSize = 12,
	TextColor3 = CORES.Texto,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "👥 Jogadores no Servidor",
	ZIndex = 31,
}, painelPlayers)

Rainbow.add(playersTitulo, function(cor)
	playersTitulo.TextColor3 = cor
end)

-- Lista scrollable de jogadores (ocupa o meio do painel)
local playersLista = novo("ScrollingFrame", {
	Position = UDim2.new(0, 0, 0, 22),
	Size = UDim2.new(1, 0, 1, -66),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = CORES.Base,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = 31,
}, painelPlayers)

-- Botões de ação na parte de BAIXO do painel
local acoesFrame = novo("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, -8),
	Size = UDim2.new(1, 0, 0, 32),
	BackgroundTransparency = 1,
	ZIndex = 31,
}, painelPlayers)

novo("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, acoesFrame)

local function botaoAcao(texto, cor, ordem)
	local b = novo("TextButton", {
		Size = UDim2.fromOffset(72, 28),
		BackgroundColor3 = cor,
		BackgroundTransparency = 0.15,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = CORES.Texto,
		Text = texto,
		LayoutOrder = ordem,
		ZIndex = 32,
	}, acoesFrame)
	cantos(b, 6)
	b.MouseEnter:Connect(function()
		tween(b, { BackgroundTransparency = 0 }, 0.15)
	end)
	b.MouseLeave:Connect(function()
		tween(b, { BackgroundTransparency = 0.15 }, 0.15)
	end)
	return b
end

local btnGrudarPlayer = botaoAcao("🔒 Grudar", CORES.Fundo2, 1)
local btnTpPlayer = botaoAcao("🏃 TP", CORES.Perigo, 2)
local btnCameraPlayer = botaoAcao("📷 Câmera", Color3.fromRGB(50, 90, 170), 3)

novo("UIListLayout", {
	Padding = UDim.new(0, 3),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, playersLista)

-- Arrastar painel de jogadores pelo título
do
	local arrastando = false
	local inicioMouse
	local inicioPos

	playersTitulo.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if S.travadoHud then return end
			arrastando = true
			inicioMouse = input.Position
			inicioPos = painelPlayers.AbsolutePosition
			painelPlayers.AnchorPoint = Vector2.new(0, 0)
			painelPlayers.Position = UDim2.fromOffset(inicioPos.X, inicioPos.Y)
		end
	end)

	jan:add(UserInputService.InputChanged:Connect(function(input)
		if not arrastando then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local delta = input.Position - inicioMouse
		painelPlayers.Position = UDim2.fromOffset(
			math.floor(inicioPos.X + delta.X),
			math.floor(inicioPos.Y + delta.Y)
		)
	end))

	jan:add(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			arrastando = false
		end
	end))
end

-- Funções de ação sobre o jogador selecionado

local function rootDeJogador(jogador)
	local personagem = jogador and jogador.Character
	return personagem and personagem:FindFirstChild("HumanoidRootPart")
end

local function irAteJogadorSelecionado()
	local meu = meuRoot()
	local alvo = rootDeJogador(jogadorSelecionado)
	if meu and alvo then
		meu.CFrame = alvo.CFrame * CFrame.new(0, 0, 4)
		return true
	end
	return false
end

local function grudarEmJogadorSelecionado()
	pararGrudarJogador()
	grudarJogadorAtivo = true
	grudarJogadorConn = jan:add(RunService.Heartbeat:Connect(function()
		local meu = meuRoot()
		local alvo = rootDeJogador(jogadorSelecionado)
		if meu and alvo then
			meu.CFrame = alvo.CFrame * CFrame.new(0, 0, 4)
		else
			pararGrudarJogador()
			btnGrudarPlayer.Text = "🔒 Grudar"
			btnGrudarPlayer.BackgroundColor3 = CORES.Fundo2
		end
	end))
end

local function cameraParaJogadorSelecionado()
	local alvo = rootDeJogador(jogadorSelecionado)
	if not alvo then return end
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(alvo.Position + Vector3.new(0, 5, 10), alvo.Position)
	task.delay(3, function()
		if camera then
			camera.CameraType = Enum.CameraType.Custom
		end
	end)
end

-- Itens da lista para highlight de seleção
local itensPlayer = {}

local function atualizarListaPlayers()
	for _, filho in ipairs(playersLista:GetChildren()) do
		if filho:IsA("GuiObject") then filho:Destroy() end
	end
	itensPlayer = {}
	jogadorSelecionado = nil
	pararGrudarJogador()
	btnGrudarPlayer.Text = "🔒 Grudar"
	btnGrudarPlayer.BackgroundColor3 = CORES.Fundo2

	local jogadores = Players:GetPlayers()
	table.sort(jogadores, function(a, b)
		return a.Name:lower() < b.Name:lower()
	end)

	local ordem = 0
	for _, jogador in ipairs(jogadores) do
		if jogador == LocalPlayer then continue end
		ordem += 1

		local item = novo("TextButton", {
			Name = "PlayerItem_" .. jogador.Name,
			Size = UDim2.new(1, -4, 0, 48),
			BackgroundColor3 = CORES.Fundo2,
			BackgroundTransparency = 0.35,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = ordem,
			ZIndex = 32,
		}, playersLista)

		cantos(item, 7)
		local itemStroke = contorno(item, CORES.Base, 0, 1)

		-- Avatar
		local avatar = novo("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 5, 0.5, 0),
			Size = UDim2.fromOffset(36, 36),
			BackgroundColor3 = CORES.Fundo,
			Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(jogador.UserId),
			ZIndex = 33,
		}, item)
		cantos(avatar, 99)

		-- Nome principal (grande)
		novo("TextLabel", {
			Position = UDim2.new(0, 47, 0, 5),
			Size = UDim2.new(1, -55, 0, 21),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 13,
			TextColor3 = CORES.Texto,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = jogador.Name,
			ZIndex = 33,
		}, item)

		-- DisplayName (menor, abaixo)
		local displayName = (jogador.DisplayName ~= jogador.Name)
			and jogador.DisplayName
			or ("@" .. jogador.Name)

		novo("TextLabel", {
			Position = UDim2.new(0, 47, 0, 27),
			Size = UDim2.new(1, -55, 0, 15),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextColor3 = CORES.TextoFraco,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = displayName,
			ZIndex = 33,
		}, item)

		itensPlayer[jogador.UserId] = { frame = item, stroke = itemStroke }

		item.MouseButton1Click:Connect(function()
			-- Desselecionar anterior
			if jogadorSelecionado then
				local ant = itensPlayer[jogadorSelecionado.UserId]
				if ant then
					tween(ant.frame, { BackgroundTransparency = 0.35, BackgroundColor3 = CORES.Fundo2 }, 0.15)
					ant.stroke.Thickness = 0
				end
			end

			-- Selecionar novo — fundo azul bem visível + borda grossa
			jogadorSelecionado = jogador
			tween(item, {
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(28, 60, 110),
			}, 0.15)
			itemStroke.Thickness = 2
			itemStroke.Color = CORES.Base

			-- Se estava grudado em outro, parar e resetar botão
			if grudarJogadorAtivo then
				pararGrudarJogador()
				btnGrudarPlayer.Text = "🔒 Grudar"
				btnGrudarPlayer.BackgroundColor3 = CORES.Fundo2
			end
		end)

		item.MouseEnter:Connect(function()
			if jogadorSelecionado ~= jogador then
				tween(item, { BackgroundTransparency = 0.15 }, 0.1)
			end
		end)
		item.MouseLeave:Connect(function()
			if jogadorSelecionado ~= jogador then
				tween(item, { BackgroundTransparency = 0.35, BackgroundColor3 = CORES.Fundo2 }, 0.1)
			end
		end)
	end

	if ordem == 0 then
		novo("TextLabel", {
			Size = UDim2.new(1, -6, 0, 30),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			TextColor3 = CORES.TextoFraco,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Nenhum outro jogador no servidor.",
			LayoutOrder = 1,
			ZIndex = 32,
		}, playersLista)
	end
end

local function avisoSemSelecao()
	notificar({
		titulo = "👥 Selecione um jogador",
		texto = "Clique em um jogador da lista primeiro.",
		cor = CORES.Spike,
		duracao = 3,
		som = false,
	})
end

btnGrudarPlayer.MouseButton1Click:Connect(function()
	if not jogadorSelecionado then
		avisoSemSelecao()
		return
	end
	grudarJogadorAtivo = not grudarJogadorAtivo
	if grudarJogadorAtivo then
		grudarEmJogadorSelecionado()
		btnGrudarPlayer.Text = "🔓 Soltar"
		btnGrudarPlayer.BackgroundColor3 = CORES.Perigo
	else
		pararGrudarJogador()
		btnGrudarPlayer.Text = "🔒 Grudar"
		btnGrudarPlayer.BackgroundColor3 = CORES.Fundo2
	end
end)

btnTpPlayer.MouseButton1Click:Connect(function()
	if not jogadorSelecionado then avisoSemSelecao() return end
	irAteJogadorSelecionado()
end)

btnCameraPlayer.MouseButton1Click:Connect(function()
	if not jogadorSelecionado then avisoSemSelecao() return end
	cameraParaJogadorSelecionado()
end)

local function alternarPainelPlayers()
	painelPlayers.Visible = not painelPlayers.Visible
	if painelPlayers.Visible then
		atualizarListaPlayers()
		painelPlayers.Size = UDim2.fromOffset(260, 0)
		tween(painelPlayers, { Size = UDim2.fromOffset(260, 300) }, 0.2, Enum.EasingStyle.Back)
	end
	-- Grudar/TP continuam ativos mesmo com painel fechado
end

btnPlayers.MouseButton1Click:Connect(alternarPainelPlayers)

jan:add(Players.PlayerAdded:Connect(function()
	if painelPlayers.Visible then
		atualizarListaPlayers()
	end
end))

-- =========================================================
--                   AÇÕES DOS BOTÕES
-- =========================================================

local function alternarPainel()

	painel.Visible = not painel.Visible

	if painel.Visible then
		painel.Size = UDim2.fromOffset(268, 0)
		tween(painel, { Size = UDim2.fromOffset(268, 250) }, 0.2, Enum.EasingStyle.Back)
	end

end

btnConfig.MouseButton1Click:Connect(alternarPainel)

btnSom.MouseButton1Click:Connect(function()

	S.somAlerta = not S.somAlerta
	btnSom.Text = S.somAlerta and "🔔" or "🔇"
	btnSom.BackgroundColor3 = S.somAlerta and CORES.Fundo2 or Color3.fromRGB(90, 30, 30)

	if S.somAlerta then
		if alertaAtivo then
			tocar(AlertSound)
		end
	else
		AlertSound:Stop()
	end

end)

btnChat.MouseButton1Click:Connect(function()

	local enviou, faltam = tentarEnviarMensagem()

	if enviou then
		notificar({
			titulo = "💬 Mensagem enviada",
			texto = CONFIG.mensagemMaximo,
			cor = CORES.Ok,
			duracao = 3,
			som = false,
		})
	else
		notificar({
			titulo = "⏳ Aguarde",
			texto = ("Cooldown do chat: faltam %ds"):format(faltam),
			cor = CORES.Spike,
			duracao = 3,
			som = false,
		})
	end

end)

-- Clique no card: abre a loja (só se não foi arrasto).
card.MouseButton1Click:Connect(function()

	if arrastouAgora() then
		return
	end

	tween(cardScale, { Scale = 0.96 }, 0.08).Completed:Connect(function()
		if not maximoAtivo then
			tween(cardScale, { Scale = 1 }, 0.12, Enum.EasingStyle.Back)
		end
	end)

	if OpenTokenExchange then
		if OpenTokenExchange:IsA("RemoteEvent") then
			OpenTokenExchange:FireServer()
		elseif OpenTokenExchange:IsA("BindableEvent") then
			OpenTokenExchange:Fire()
		end
	end

end)

card.MouseEnter:Connect(function()
	tween(card, { BackgroundTransparency = 0.12 }, 0.2)
	if not maximoAtivo then
		tween(cardStroke, { Transparency = 0.35 }, 0.2)
	end
end)

card.MouseLeave:Connect(function()
	tween(card, { BackgroundTransparency = 0.25 }, 0.2)
	if not maximoAtivo then
		tween(cardStroke, { Transparency = 0.8 }, 0.2)
	end
end)

-- =========================================================
--                   ATALHOS DE TECLADO
-- =========================================================

jan:add(UserInputService.InputBegan:Connect(function(input, processado)

	if processado or input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	local tecla = input.KeyCode

	if tecla == CONFIG.teclas.esconderTudo then

		modoDiscreto = not modoDiscreto
		aplicarVisibilidade()

	elseif tecla == CONFIG.teclas.abrirConfig then

		alternarPainel()

	elseif tecla == CONFIG.teclas.alternarSom then

		S.somAlerta = not S.somAlerta
		btnSom.Text = S.somAlerta and "🔔" or "🔇"
		if not S.somAlerta then
			AlertSound:Stop()
		elseif alertaAtivo then
			tocar(AlertSound)
		end

	elseif tecla == CONFIG.teclas.enviarMensagem then

		tentarEnviarMensagem()

	elseif tecla == CONFIG.teclas.irAteLadrao then

		irAteLadrao()

	end

end))

-- =========================================================
--                    ATUALIZAR DISPLAY
-- =========================================================

local ultimoPreco = PRICE_BASE

local function checarMetas(tokens, valor)

	if metaTokens > 0 and tokens >= metaTokens and not metaTokensAvisada then
		metaTokensAvisada = true
		notificar({
			titulo = "🎯 Meta de tokens batida",
			texto = ("Você chegou a %s tokens"):format(formatarNumero(tokens)),
			cor = CORES.Ok,
			duracao = 6,
		})
	elseif metaTokens > 0 and tokens < metaTokens then
		metaTokensAvisada = false
	end

	if metaValor > 0 and valor >= metaValor and not metaValorAvisada then
		metaValorAvisada = true
		notificar({
			titulo = "🎯 Meta de valor batida",
			texto = ("Vendendo agora você recebe $%s"):format(formatarNumero(valor)),
			cor = CORES.Ok,
			duracao = 6,
		})
	elseif metaValor > 0 and valor < metaValor then
		metaValorAvisada = false
	end

end

local function atualizarStats(tokens, valor)

	if not painel.Visible or abaAtual ~= "Stats" then
		return
	end

	local minutos = math.max(1 / 60, (os.clock() - stats.inicioSessao) / 60)
	local ganho = tokens - (stats.tokensIniciais or tokens)

	statsLabels.tempo.Text = formatarTempo(os.clock() - stats.inicioSessao)
	statsLabels.tokens.Text = formatarNumero(tokens)
	statsLabels.ganho.Text = (ganho >= 0 and "+" or "") .. formatarNumero(ganho)
	statsLabels.porMin.Text = formatarNumero(ganho / minutos)
	statsLabels.valor.Text = "$" .. formatarNumero(valor)
	statsLabels.maiorPreco.Text = "$" .. tostring(stats.maiorPreco)
	statsLabels.maximos.Text = tostring(stats.vezesNoMaximo)
	statsLabels.roubos.Text = tostring(stats.roubosSofridos)

end

local function atualizarDisplay()

	local precoBruto = lerNumero(Workspace:GetAttribute("TokenPrice"), PRICE_BASE)
	local preco = math.floor(precoBruto)

	local tokens = lerTokens()
	local valor = tokens * precoBruto

	if stats.tokensIniciais == nil and tokens > 0 then
		stats.tokensIniciais = tokens
	end

	stats.tokensAtuais = tokens
	stats.maiorPreco = math.max(stats.maiorPreco, preco)

	earningsLabel.Text = ("💎 Tokens: %s  •  💰 Receber: $%s"):format(
		formatarNumero(tokens),
		formatarNumero(valor)
	)

	local simbolo = ""

	if preco > ultimoPreco then
		simbolo = " ▲"
	elseif preco < ultimoPreco then
		simbolo = " ▼"
	end

	if preco ~= ultimoPreco then
		animarPreco()
		registrarHistorico(preco)
	end

	priceLabel.Text = ("💰 $%d%s"):format(preco, simbolo)

	if preco >= PRICE_MAX then

		if not maximoAtivo then
			iniciarEfeitoMaximo()
			notificar({
				titulo = "🌈 LOJA NO MÁXIMO",
				texto = ("$%d por token • você recebe $%s"):format(preco, formatarNumero(valor)),
				rainbow = true,
				cor = CORES.Max,
				duracao = 6,
			})
		end

		if S.efeitosMaximo then
			statusBadge.Text = "⚡ MÁXIMO"
			statusBadge.TextColor3 = CORES.Texto
		else
			aplicarTema(CORES.Max, 0.35, "⚡ MÁXIMO")
		end

	elseif preco >= PRICE_SPIKE then

		pararEfeitoMaximo()
		aplicarTema(CORES.Spike, 0.4, "🔥 ALTO")

	elseif preco <= PRICE_MIN then

		pararEfeitoMaximo()
		aplicarTema(CORES.Min, 0.4, "📉 MÍNIMO")

	else

		pararEfeitoMaximo()
		aplicarTema(CORES.Base, 0.8, "NORMAL")

	end

	checarMetas(tokens, valor)
	atualizarStats(tokens, valor)

	ultimoPreco = preco

end

-- =========================================================
--                 LOOP PRINCIPAL / EVENTOS
-- =========================================================

task.spawn(function()

	while rodando and gui.Parent do

		local agora = os.time()
		local faltam = EPOCH - (agora % EPOCH)

		timerLabel.Text = ("Troca em %ds"):format(faltam)

		tween(progressBar, { Size = UDim2.new(faltam / EPOCH, 0, 1, 0) }, 0.5, Enum.EasingStyle.Linear)

		atualizarDisplay()

		task.wait(0.5)

	end

end)

jan:add(Workspace:GetAttributeChangedSignal("TokenPrice"):Connect(atualizarDisplay))
jan:add(LocalPlayer:GetAttributeChangedSignal("Tokens"):Connect(atualizarDisplay))

jan:add(Players.PlayerRemoving:Connect(function(jogador)
	if jogador == ladraoJogador then
		pararAlerta()
		limparEsp()
	end
	if jogador == jogadorSelecionado then
		jogadorSelecionado = nil
		pararGrudarJogador()
		btnGrudarPlayer.Text = "🔒 Grudar"
		btnGrudarPlayer.BackgroundColor3 = CORES.Fundo2
	end
	if painelPlayers.Visible then
		atualizarListaPlayers()
	end
end))

registrarHistorico(PRICE_BASE)
atualizarDisplay()

print("[SamMods] TokenPriceWatcher v2 carregado. F1 esconde, F2 abre o painel.")
