extends Node2D

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	pass

func mudar_para_fase_1() -> void:
	get_tree().change_scene_to_file("res://scenes/Fase1.tscn")
