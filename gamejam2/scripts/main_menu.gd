extends Control

# Variáveis dos botões.
@onready var btn_jogar = $MarginContainer/VBoxContainer/Jogar
@onready var btn_config = $MarginContainer/VBoxContainer/Configurações
@onready var btn_creditos = $MarginContainer/VBoxContainer/Creditos
@onready var btn_sair = $MarginContainer/VBoxContainer/Sair
@onready var titulo = $MarginContainer/VBoxContainer/TextureRect

func _ready():
	# Inicia o efeito do título piscar
	efeito_flicker()
	
	# --- Carrega as configurações salvas do jogador ---
	var config = ConfigFile.new()
	if config.load("user://configuracoes.cfg") == OK:
		# Aplica o Audio
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(config.get_value("Audio", "geral", 1.0)))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Musica"), linear_to_db(config.get_value("Audio", "musica", 1.0)))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(config.get_value("Audio", "sfx", 1.0)))
		
		# Aplica a tela
		if config.get_value("Video", "tela_cheia", false):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			
		if config.get_value("Video", "vsync", false):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			
		var fps_index = config.get_value("Video", "fps_index", 0)
		match fps_index:
			0: Engine.max_fps = 60
			1: Engine.max_fps = 120
			2: Engine.max_fps = 144
			3: Engine.max_fps = 180
			4: Engine.max_fps = 0
	# -------------------------------------

	# Fade In 
	$Fade.color.a = 1.0
	var tween_fade = get_tree().create_tween()
	tween_fade.tween_property($Fade, "color:a", 0.0, 0.5)

	
	var cursor_img = load("res://assets/ui/Mouse.png")
	Input.set_custom_mouse_cursor(cursor_img, Input.CURSOR_ARROW, Vector2(0, 0))
	
	# Conectando as ações de BRILHO do rato (mouse)
	btn_jogar.mouse_entered.connect(_on_jogar_entered)
	btn_jogar.mouse_exited.connect(_on_jogar_exited)
	
	btn_config.mouse_entered.connect(_on_config_entered)
	btn_config.mouse_exited.connect(_on_config_exited)
	
	btn_creditos.mouse_entered.connect(_on_creditos_entered)
	btn_creditos.mouse_exited.connect(_on_creditos_exited)
	
	btn_sair.mouse_entered.connect(_on_sair_entered)
	btn_sair.mouse_exited.connect(_on_sair_exited)
	
	# Conectando as ações de clique dos botões
	btn_jogar.pressed.connect(_on_jogar_pressed)
	btn_config.pressed.connect(_on_botao_configuracoes_pressed)
	btn_creditos.pressed.connect(_on_creditos_pressed)
	btn_sair.pressed.connect(_on_sair_pressed)


# --- Funções de Brilho ---

func _on_jogar_entered():
	btn_jogar.modulate = Color(2.0, 2.0, 2.0, 1.0) 

func _on_jogar_exited():
	btn_jogar.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_config_entered():
	btn_config.modulate = Color(2.0, 2.0, 2.0, 1.0)

func _on_config_exited():
	btn_config.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_creditos_entered():
	btn_creditos.modulate = Color(2.0, 2.0, 2.0, 1.0)

func _on_creditos_exited():
	btn_creditos.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_sair_entered():
	btn_sair.modulate = Color(2.0, 2.0, 2.0, 1.0)

func _on_sair_exited():
	btn_sair.modulate = Color(1.0, 1.0, 1.0, 1.0)

# --- Funções de Clique ---

func _on_sair_pressed():
	SfxManager.play_click()
	var tween = get_tree().create_tween()
	tween.tween_property($Fade, "color:a", 1.0, 0.5)
	await tween.finished
	get_tree().quit()

func _on_jogar_pressed():
	SfxManager.play_click()
	var tween = get_tree().create_tween()
	tween.tween_property($Fade, "color:a", 1.0, 0.5)
	await tween.finished
	
	get_tree().change_scene_to_file("res://scenes/Fase1.tscn")
	
func _on_creditos_pressed() -> void:
	SfxManager.play_click()
	get_tree().change_scene_to_file("res://scenes/creditos.tscn")

func _on_botao_configuracoes_pressed() -> void:
	SfxManager.play_click()
	var tween = get_tree().create_tween()
	tween.tween_property($Fade, "color:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/menu_configuracoes.tscn")
	
func efeito_flicker():
	while is_inside_tree():
		titulo.modulate.a = randf_range(0.7, 1.0)
		await get_tree().create_timer(randf_range(0.05, 0.2)).timeout
