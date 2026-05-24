extends Area2D

const SPEED = 400.0
var direction = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)

func setup(dir: int) -> void:
	direction = dir
	# Espelha o sprite se for para a esquerda
	$Sprite2D.flip_h = dir < 0

func _process(delta: float) -> void:
	position.x += SPEED * direction * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(20)
		queue_free()

func _on_screen_exited() -> void:
	queue_free()
