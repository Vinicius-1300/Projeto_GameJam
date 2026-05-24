extends Control

# Variáveis de barramento
var master_bus: int
var musica_bus: int
var sfx_bus: int

# Sistema de Save
var config = ConfigFile.new()
var caminho_save = "user://configuracoes.cfg"

# Variável para saber de onde o menu foi aberto
var veio_do_pause = false

@onready var seletor_fps = $MarginContainer/VBoxContainer/OptionButton
@onready var slider_geral = $MarginContainer/VBoxContainer/HSlider
@onready var slider_musica = $MarginContainer/VBoxContainer/HSlider2
@onready var slider_sfx = $MarginContainer/VBoxContainer/HSlider3
@onready var check_tela_cheia = $MarginContainer/VBoxContainer/CheckBox
@onready var check_vsync = $MarginContainer/VBoxContainer/CheckBox2

func _ready() -> void:
	# 1. Pega os índices dos canais
	master_bus = AudioServer.get_bus_index("Master")
	musica_bus = AudioServer.get_bus_index("Musica")
	sfx_bus = AudioServer.get_bus_index("SFX")

	# 2. Conecta o sinal para mudanças futuras e checa o estado atual
	self.visibility_changed.connect(_on_visibility_changed)
	
	# Chamada Manual: Verifica se o menu já começou visível
	_on_visibility_changed()

	# 3. Fade In visual
	$Fade.color.a = 1.0
	var tween_fade = create_tween()
	tween_fade.tween_property($Fade, "color:a", 0.0, 0.5)

	# 4. Configura as opções de FPS
	seletor_fps.clear()
	seletor_fps.add_item("60 FPS")
	seletor_fps.add_item("120 FPS")
	seletor_fps.add_item("144 FPS")
	seletor_fps.add_item("180 FPS")
	seletor_fps.add_item("Ilimitado")

	# 5. Carrega configurações salvas
	if config.load(caminho_save) == OK:
		slider_geral.value = config.get_value("Audio", "geral", 1.0)
		slider_musica.value = config.get_value("Audio", "musica", 1.0)
		slider_sfx.value = config.get_value("Audio", "sfx", 1.0)
		check_tela_cheia.button_pressed = config.get_value("Video", "tela_cheia", false)
		check_vsync.button_pressed = config.get_value("Video", "vsync", false)
		seletor_fps.selected = config.get_value("Video", "fps_index", 0)
	else:
		slider_geral.value = 1.0
		slider_musica.value = 1.0
		slider_sfx.value = 1.0

	# Sincroniza o som da engine imediatamente
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(slider_geral.value))
	AudioServer.set_bus_volume_db(musica_bus, linear_to_db(slider_musica.value))
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(slider_sfx.value))

func _on_visibility_changed() -> void:
	if has_node("AudioStreamPlayer"):
		if is_visible_in_tree():
			if not $AudioStreamPlayer.playing:
				$AudioStreamPlayer.play()
		else:
			$AudioStreamPlayer.stop()

func _on_button_pressed() -> void:
	SfxManager.play_click()
	# Salva os dados no arquivo .cfg
	config.set_value("Audio", "geral", slider_geral.value)
	config.set_value("Audio", "musica", slider_musica.value)
	config.set_value("Audio", "sfx", slider_sfx.value)
	config.set_value("Video", "tela_cheia", check_tela_cheia.button_pressed)
	config.set_value("Video", "vsync", check_vsync.button_pressed)
	config.set_value("Video", "fps_index", seletor_fps.selected)
	config.save(caminho_save)
	
	# Transição de saída
	var tween = create_tween()
	tween.tween_property($Fade, "color:a", 1.0, 0.5)
	await tween.finished
	
	if veio_do_pause:
		if get_parent().has_method("despausar_jogo"):
			get_parent().despausar_jogo()
		else:
			get_parent().get_parent().despausar_jogo()
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# --- Atualizações em tempo real ---

func _on_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))

func _on_h_slider_2_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(musica_bus, linear_to_db(value))

func _on_h_slider_3_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))

func _on_check_box_toggled(toggled_on: bool) -> void:
	SfxManager.play_click()
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_check_box_2_toggled(toggled_on: bool) -> void:
	SfxManager.play_click()
	var mode = DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)

func _on_option_button_item_selected(index: int) -> void:
	SfxManager.play_click()
	match index:
		0: Engine.max_fps = 60
		1: Engine.max_fps = 120
		2: Engine.max_fps = 144
		3: Engine.max_fps = 180
		4: Engine.max_fps = 0
