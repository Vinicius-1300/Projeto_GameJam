extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_point: Marker2D = $ShootPoint
@onready var collision = $CollisionShape2D

const SPEED = 200.0
const RUN_SPEED = 400.0
const JUMP_VELOCITY = -400.0
var jump_count = 0
const MAX_JUMPS = 2
var is_attacking = false
var facing_direction = 1
const BulletScene = preload("res://bullet.tscn")
const SHOOT_COOLDOWN = 0.3
var is_shooting = false
var shoot_timer = 0.0
var is_sitting = false
var hp = 100
var is_dead = false
var is_hurt = false

func _physics_process(delta: float) -> void:
	if is_dead or is_hurt:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0

	if Input.is_action_just_pressed("sit") and is_on_floor() and not is_attacking:
		is_sitting = not is_sitting
		if is_sitting:
			animation.flip_h = facing_direction < 0
			animation.play("sit_down")
		else:
			animation.play("idle")

	if is_sitting and Input.get_axis("ui_left", "ui_right") != 0:
		is_sitting = false
		animation.play("idle")

	if is_sitting:
		velocity.x = 0
		move_and_slide()
		return

	if Input.is_action_just_pressed("ui_accept") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	var current_speed = RUN_SPEED if Input.is_action_pressed("run") else SPEED
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * current_speed
		facing_direction = 1 if direction > 0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	if shoot_timer > 0:
		shoot_timer -= delta

	if Input.is_action_just_pressed("shoot") and shoot_timer <= 0:
		_shoot()

	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		animation.flip_h = facing_direction < 0
		animation.play("attack")
	if is_attacking and not animation.is_playing():
		is_attacking = false
		_apply_melee_damage()

	if is_attacking and not animation.is_playing():
		is_attacking = false

	if not is_attacking:
		if is_shooting and animation.is_playing():
			pass
		else:
			is_shooting = false
			if not is_on_floor():
				animation.flip_h = facing_direction < 0
				if jump_count == 2:
					animation.play("double_jump")
				else:
					animation.play("jump")
			else:
				var is_running = Input.is_action_pressed("run") and direction != 0
				if is_running:
					animation.flip_h = facing_direction < 0
					animation.play("run")
				elif direction > 0:
					animation.flip_h = false
					animation.play("walk")
				elif direction < 0:
					animation.flip_h = true
					animation.play("walk")
				else:
					animation.play("idle")

	move_and_slide()

func _shoot() -> void:
	shoot_timer = SHOOT_COOLDOWN
	animation.flip_h = facing_direction < 0
	animation.play("shoot")
	is_shooting = true
	if not animation.animation_finished.is_connected(_on_shoot_animation_finished):
		animation.animation_finished.connect(_on_shoot_animation_finished)
	_animate_gun_recoil()
	var bullet = BulletScene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = shoot_point.global_position
	bullet.setup(facing_direction)

func _on_shoot_animation_finished() -> void:
	if is_shooting:
		is_shooting = false

func _animate_gun_recoil() -> void:
	var original_pos = animation.position
	var recoil_offset = Vector2(-3 * facing_direction, 0)
	var tween = create_tween()
	tween.tween_property(animation, "position", original_pos + recoil_offset, 0.05)
	tween.tween_property(animation, "position", original_pos, 0.08)
	
func take_damage(amount: int) -> void:
	if is_dead:
		return
	hp -= amount
	print("HP atual: ", hp)
	if hp <= 0:
		is_dead = true
		if animation.animation_finished.is_connected(_on_hurt_finished):
			animation.animation_finished.disconnect(_on_hurt_finished)
		animation.play("death")
		if not animation.animation_finished.is_connected(_on_death_finished):
			animation.animation_finished.connect(_on_death_finished)
	else:
		is_hurt = true
		animation.play("hurt")
		if not animation.animation_finished.is_connected(_on_hurt_finished):
			animation.animation_finished.connect(_on_hurt_finished)

func _on_hurt_finished() -> void:
	is_hurt = false
	animation.animation_finished.disconnect(_on_hurt_finished)

func _on_death_finished() -> void:
	queue_free()
	
func _apply_melee_damage() -> void:
	var enemies = get_tree().get_nodes_in_group("villain")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= 710.0:
			enemy.take_damage(30)
