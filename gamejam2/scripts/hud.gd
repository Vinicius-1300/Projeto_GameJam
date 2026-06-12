extends CanvasLayer

@onready var barra_vida = $MarginContainer/Control/BoxEsquerda/BarraVida
@onready var barra_escudo = $MarginContainer/Control/BoxEsquerda/BarraEscudo
@onready var barra_calor = $MarginContainer/Control/BoxDireita/BarraCalor
@onready var label_arma = $MarginContainer/Control/BoxDireita/LabelArma

# --- Textos Númericos ---
@onready var texto_vida = $MarginContainer/Control/BoxEsquerda/BarraVida/TextoVida
@onready var texto_escudo = $MarginContainer/Control/BoxEsquerda/BarraEscudo/TextoEscudo

@onready var minigame_node = $MinigameResfriamento
@onready var cursor_node = $MinigameResfriamento/Cursor

# --- Refêrencia do Inimigo ---
@onready var painel_inimigo = $PainelInimigo
@onready var barra_vida_inimigo = $PainelInimigo/BarraVidaInimigo
@onready var label_nome_inimigo = $PainelInimigo/NomeInimigo

# --- Tela de Morte ---
@onready var tela_morte = $TelaMorte
@onready var botao_reiniciar = $TelaMorte/BotaoReiniciar
@onready var som_morte = $TelaMorte/SomMorte
@onready var musica_game_over = $TelaMorte/MusicaGameOver

# --- Tela de Vitória ---
@onready var tela_vitoria = $TelaVitoria
@onready var botao_reiniciar_vitoria = $TelaVitoria/VBoxContainer/BotaoReiniciarVitoria

var tempo_visivel_inimigo: float = 0.0

# --- Variável de cooldown ---
var container_cooldowns: VBoxContainer
var barras_cooldown: Dictionary = {}

func _ready() -> void:
	add_to_group("hud")

	if minigame_node:
		minigame_node.hide()
	if painel_inimigo:
		painel_inimigo.hide()
	
	# Esconde a tela de morte
	if tela_morte:
		tela_morte.hide()
		
	# Esconde a tela de vitória
	if tela_vitoria:
		tela_vitoria.hide()
		
	# Conecta o botão de reiniciar da tela de morte
	if botao_reiniciar and not botao_reiniciar.pressed.is_connected(_on_botao_reiniciar_pressed):
		botao_reiniciar.pressed.connect(_on_botao_reiniciar_pressed)
		
	# Conecta o botão de reiniciar da tela de vitória (usa a mesma função para facilitar)
	if botao_reiniciar_vitoria and not botao_reiniciar_vitoria.pressed.is_connected(_on_botao_reiniciar_pressed):
		botao_reiniciar_vitoria.pressed.connect(_on_botao_reiniciar_pressed)

func _process(delta: float) -> void:
	if painel_inimigo and painel_inimigo.visible:
		tempo_visivel_inimigo -= delta
		if tempo_visivel_inimigo <= 0:
			painel_inimigo.hide()

# --- Mostra a tela de morte ---
func mostrar_tela_morte() -> void:
	if tela_morte:
		tela_morte.show()
		
		if som_morte:
			som_morte.play()
		if musica_game_over:
			musica_game_over.play()
			
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --- Mostra a tela de vitória ---
func mostrar_tela_vitoria() -> void:
	if tela_vitoria:
		tela_vitoria.show()
		
		# Se você adicionar um áudio de vitória na cena depois, pode dar o play() dele aqui
		
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_botao_reiniciar_pressed() -> void:
	# Tira o jogo do pause antes de recarregar a cena, senão a nova fase já nasce congelada
	get_tree().paused = false
	
	# Reinicia a fase
	get_tree().reload_current_scene()

# --- Atualiza a vida/escudo do jogador ---
func atualizar_vida(atual: float, maxima: float) -> void:
	if barra_vida:
		barra_vida.max_value = maxima
		barra_vida.value = atual
	if texto_vida:
		texto_vida.text = str(int(atual)) + " / " + str(int(maxima))

func atualizar_escudo(atual: float, maxima: float) -> void:
	if barra_escudo:
		barra_escudo.max_value = maxima
		barra_escudo.value = atual
	if texto_escudo:
		texto_escudo.text = str(int(atual)) + " / " + str(int(maxima))

func atualizar_calor(atual: float, maxima: float, sobreaquecida: bool) -> void:
	if barra_calor:
		barra_calor.max_value = maxima
		barra_calor.value = atual
		
		if sobreaquecida:
			barra_calor.modulate = Color(1.0, 0.0, 0.0) 
		else:
			barra_calor.modulate = Color(1.0, 0.5, 0.0).lerp(Color(1.0, 1.0, 1.0), 1.0 - (atual / maxima))

func atualizar_arma(nome_arma: String) -> void:
	if label_arma:
		label_arma.text = nome_arma

# --- Atualiza a vida do inimigo ---
func mostrar_vida_inimigo(nome: String, vida_atual: float, vida_max: float) -> void:
	if painel_inimigo:
		painel_inimigo.show()
		tempo_visivel_inimigo = 3.0 
		
		if label_nome_inimigo:
			label_nome_inimigo.text = nome + "  " + str(vida_atual) + " / " + str(vida_max)
		if barra_vida_inimigo:
			barra_vida_inimigo.max_value = vida_max
			barra_vida_inimigo.value = vida_atual

# --- Minigame de calor ---
func mostrar_minigame_resfriamento() -> void:
	if minigame_node:
		minigame_node.show()

func esconder_minigame_resfriamento() -> void:
	if minigame_node:
		minigame_node.hide()

func atualizar_cursor_resfriamento(progresso: float) -> void:
	if minigame_node and cursor_node:
		var largura_total = minigame_node.size.x
		cursor_node.position.x = largura_total * progresso
