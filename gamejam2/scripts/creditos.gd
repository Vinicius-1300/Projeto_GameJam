extends Control

@onready var botao_voltar = $MarginContainer/VBoxContainer/Button

func _ready() -> void:
	botao_voltar.grab_focus()
	
	# Conecta as ações do mouse para ativar o brilho
	botao_voltar.mouse_entered.connect(_on_voltar_entered)
	botao_voltar.mouse_exited.connect(_on_voltar_exited)

func _on_button_pressed() -> void:
	SfxManager.play_click()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# --- FUNÇÕES DE BRILHO ---

func _on_voltar_entered() -> void:
	botao_voltar.modulate = Color(2.0, 2.0, 2.0, 1.0)

func _on_voltar_exited() -> void:
	botao_voltar.modulate = Color(1.0, 1.0, 1.0, 1.0)
