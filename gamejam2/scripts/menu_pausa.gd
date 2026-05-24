extends CanvasLayer

@onready var botao_continuar = $MarginContainer/VBoxContainer/Continuar
@onready var botoes_pausa = $MarginContainer/VBoxContainer
@onready var menu_config = $MenuConfiguracoes

func _ready() -> void:
	self.hide()
	if menu_config:
		menu_config.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Tecla ESC
		if not get_tree().paused:
			# Verifica se o jogador está morto antes de pausar
			var player = get_tree().current_scene.find_child("Player", true, false)
			if player and player.esta_morto:
				return 
				
			pausar_jogo()
		else:
			if menu_config and menu_config.visible:
				_on_voltar_das_configuracoes()
			else:
				despausar_jogo()

func pausar_jogo() -> void:
	self.show()
	botoes_pausa.show()
	if menu_config:
		menu_config.hide()
	
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	botao_continuar.grab_focus()
	
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud:
		hud.hide()

func despausar_jogo() -> void:
	self.hide()
	if menu_config:
		menu_config.hide()
		
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud:
		hud.show()

# --- SINAIS DOS BOTÕES ---

func _on_continuar_pressed() -> void:
	SfxManager.play_click()
	despausar_jogo()

func _on_configuracoes_pressed() -> void:
	SfxManager.play_click()
	botoes_pausa.hide()
	if menu_config:
		menu_config.veio_do_pause = true
		menu_config.show()

func _on_voltar_das_configuracoes() -> void:
	SfxManager.play_click()
	if menu_config:
		menu_config.hide()
	botoes_pausa.show()
	botao_continuar.grab_focus()

func _on_sair_pressed() -> void:
	SfxManager.play_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_sair_do_jogo_pressed() -> void:
	SfxManager.play_click()
	get_tree().quit()
