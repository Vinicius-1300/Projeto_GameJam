extends Area2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
var direction = 1
const SPEED = 600.0
var hit = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if hit:
		return
	if body.is_in_group("villain"):
		body.take_damage(20)  # ajuste o dano aqui
		queue_free()

func setup(dir: int) -> void:
	direction = dir
	animation.flip_h = dir < 0
	# Só toca animação se ela existir
	if animation.sprite_frames and animation.sprite_frames.has_animation("default"):
		animation.play("default")
		animation.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	position.x += SPEED * direction * delta

func _on_animation_finished() -> void:
	# Só deleta se a animação não for em loop
	if not animation.sprite_frames.get_animation_loop("default"):
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
