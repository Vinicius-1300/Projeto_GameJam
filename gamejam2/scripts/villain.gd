extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_point: Marker2D = $ShootPoint
@onready var collision = $CollisionShape2D

# Patrulha
const SPEED = 80.0
var patrol_direction = 1
var start_position: Vector2

# HP
var max_hp = 500
var current_hp = 500
var is_dead = false
var is_hurt = false

# Ataque
var is_attacking = false
var attack_cooldown = 0.0
const ATTACK_COOLDOWN_TIME = 2.0

# Padrão de ataque por tempo
var attack_phase = 0
var special_done = false
var phase_timer = 0.0
const RANGED_PHASE_TIME = 8.0
const MELEE_PHASE_TIME = 6.0

# Ranges e dano
const MELEE_RANGE = 80.0
const SHOOT_RANGE = 500.0
const MELEE_DAMAGE = 50

# imunidade da barreira
var is_immune = false
var immune_timer = 0.0
const IMMUNE_TIME = 10.0

const BulletScene = preload("res://scenes/villain_bullet.tscn")
var player: CharacterBody2D = null
var playercollision: CollisionShape2D = null

# --- Refêrencia do Hud ---
var hud = null

# --- Áudio Provisório ---
var sfx_hurt: AudioStreamPlayer

func _ready() -> void:
	add_to_group("villain")
	start_position = global_position
	animation.animation_finished.connect(_on_animation_finished)
	animation.play("idle")
	
	sfx_hurt = AudioStreamPlayer.new()
	add_child(sfx_hurt)
	sfx_hurt.stream = _gerar_bip_provisorio(130.81, 0.15) 
	sfx_hurt.volume_db = -4.0

func _physics_process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if player:
			playercollision = player.get_node("CollisionShape2D")
			patrol_direction = 1 if playercollision.global_position.x > collision.global_position.x else -1
			animation.flip_h = patrol_direction < 0

	if not hud:
		hud = get_tree().get_first_node_in_group("hud")

	# Física do Knockback
	if is_dead or is_hurt:
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED * 4 * delta)
		move_and_slide()
		return
		
	if is_immune:
		immune_timer -= delta
		if immune_timer <= 0:
			is_immune = false
			animation.play("idle")

	if not is_on_floor():
		velocity += get_gravity() * delta

	if attack_cooldown > 0:
		attack_cooldown -= delta

	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return

	if player and playercollision:
		var dist = collision.global_position.distance_to(playercollision.global_position)
		phase_timer += delta

		match attack_phase:
			0:  # Ranged
				if phase_timer >= RANGED_PHASE_TIME:
					phase_timer = 0.0
					attack_phase = 1
				elif dist <= SHOOT_RANGE and attack_cooldown <= 0:
					_face_player()
					_do_ranged()
				elif dist < 5.0:
					_face_player()
					velocity.x = -SPEED * patrol_direction
					animation.play("walk")
				else:
					_face_player()
					_move_toward_player()

			1:  # Melee
				if phase_timer >= MELEE_PHASE_TIME:
					phase_timer = 0.0
					attack_phase = 2
				elif dist <= MELEE_RANGE and attack_cooldown <= 0:
					_face_player()
					_do_melee()
				else:
					_face_player()
					_move_toward_player()

			2:  # Special
				if not special_done and attack_cooldown <= 0:
					_face_player()
					_do_special()
				elif special_done:
					special_done = false
					phase_timer = 0.0
					attack_phase = 0
					attack_cooldown = ATTACK_COOLDOWN_TIME
				else:
					velocity.x = 0

	move_and_slide()

func _face_player() -> void:
	if playercollision:
		var diff = playercollision.global_position.x - collision.global_position.x
		patrol_direction = 1 if diff > 0 else -1
		animation.flip_h = patrol_direction < 0

func _move_toward_player() -> void:
	if playercollision:
		var dist = collision.global_position.distance_to(playercollision.global_position)
		if dist < 20.0:
			velocity.x = 0
			animation.play("idle")
			return
		
		velocity.x = SPEED * patrol_direction
		animation.play("walk")

func _do_ranged() -> void:
	is_attacking = true
	attack_cooldown = ATTACK_COOLDOWN_TIME
	animation.play("attack")

func _do_melee() -> void:
	is_attacking = true
	attack_cooldown = ATTACK_COOLDOWN_TIME
	animation.play("attack3")

func _do_special() -> void:
	is_attacking = true
	special_done = true
	is_immune = true
	immune_timer = IMMUNE_TIME
	attack_cooldown = ATTACK_COOLDOWN_TIME * 2
	animation.play("special")

func _spawn_bullet() -> void:
	var bullet = BulletScene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = shoot_point.global_position
	bullet.setup(patrol_direction)

func _apply_melee_damage() -> void:
	if player == null or playercollision == null:
		return
	var dist = collision.global_position.distance_to(playercollision.global_position)
	if dist <= MELEE_RANGE:
		player.take_damage(MELEE_DAMAGE)

func take_damage(amount: int, forca_empurrao: float = 0.0) -> void:
	if is_dead or is_immune:
		return
		
	current_hp -= amount 
	
	if sfx_hurt:
		sfx_hurt.play()
	
	if forca_empurrao != 0.0:
		velocity.x = forca_empurrao
		velocity.y = -200.0 
	
	if not hud:
		hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.mostrar_vida_inimigo("Ameaça Ciborgue", current_hp, max_hp)

	if current_hp <= 0:
		_die()
	else:
		if not is_hurt:
			_play_hurt()

func _play_hurt() -> void:
	is_hurt = true
	animation.play("hurt")

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	animation.play("dead")

func _on_animation_finished() -> void:
	var anim = animation.animation

	if anim == "dead":
		queue_free()
	elif anim == "hurt":
		is_hurt = false
		is_attacking = false
	elif anim == "attack":
		is_attacking = false
		animation.play("idle")
		_spawn_bullet()
	elif anim == "attack3":
		is_attacking = false
		animation.play("idle")
		_apply_melee_damage()
	elif anim == "special":
		is_attacking = false
		animation.play("idle")
		_spawn_bullet()
	else:
		is_attacking = false
		is_hurt = false
		animation.play("idle")

func _on_hitbox_contato_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_dead:
		body.take_damage(20)
		var direcao_empurrao = -1 if global_position.x > body.global_position.x else 1
		body.velocity.x = 600.0 * direcao_empurrao
		body.velocity.y = -200.0

# --- Gerador de som via código ---
func _gerar_bip_provisorio(frequencia: float, duracao: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	
	var total_amostras = int(stream.mix_rate * duracao)
	var bytes = PackedByteArray()
	bytes.resize(total_amostras * 2) 
	
	for i in range(total_amostras):
		var t = float(i) / stream.mix_rate
		var amostra = sin(t * frequencia * 2.0 * PI)
		
		if i > total_amostras * 0.8:
			var fator_fade = float(total_amostras - i) / (total_amostras * 0.2)
			amostra *= fator_fade
			
		var valor_int = int(amostra * 32767.0) 
		bytes.encode_s16(i * 2, valor_int)
		
	stream.data = bytes
	return stream
