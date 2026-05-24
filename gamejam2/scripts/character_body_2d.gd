extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_point: Marker2D = $ShootPoint
@onready var collision = $CollisionShape2D

# --- Áudio --
var sfx_shoot: AudioStreamPlayer
var sfx_death: AudioStreamPlayer
var sfx_melee_hit: AudioStreamPlayer
var sfx_hurt: AudioStreamPlayer

const SPEED = 200.0
const RUN_SPEED = 400.0
const JUMP_VELOCITY = -400.0
var jump_count = 0
const MAX_JUMPS = 2
var is_attacking = false
var facing_direction = 1
const BulletScene = preload("res://scenes/bullet.tscn")

const SHOOT_COOLDOWN = 0.3 

var is_shooting = false
var shoot_timer = 0.0
var is_sitting = false

# --- Valores de vida, escudo e hud ---
var max_hp = 100
var hp = 100
var max_shield = 50
var shield = 50
var hud = null

var is_dead = false
var is_hurt = false

# --- I-frame ---
var is_invulnerable = false
var invuln_timer = 0.0
const INVULN_TIME = 1.0 

# --- Minigame de calor ---
var max_heat = 100.0
var current_heat = 0.0
var heat_per_shot = 20.0       
var cooling_rate = 35.0        
var is_overheated = false      

var is_minigame_active = false
var minigame_progress = 0.0
const MINIGAME_SPEED = 0.5     

# --- Limite de queda para causar morte no jogador, caso ele passe da parede ---
const FALL_LIMIT = 800.0

func _ready() -> void:
	add_to_group("player")
	
	# Sons por script:
	sfx_shoot = AudioStreamPlayer.new()
	add_child(sfx_shoot)
	sfx_shoot.stream = _gerar_bip_provisorio(587.33, 0.08) 
	sfx_shoot.volume_db = -10.0 
	
	sfx_death = AudioStreamPlayer.new()
	add_child(sfx_death)
	sfx_death.stream = _gerar_bip_provisorio(146.83, 0.4) 
	sfx_death.volume_db = -5.0

	sfx_melee_hit = AudioStreamPlayer.new()
	add_child(sfx_melee_hit)
	sfx_melee_hit.stream = _gerar_bip_provisorio(880.0, 0.06) 
	sfx_melee_hit.volume_db = -8.0

	sfx_hurt = AudioStreamPlayer.new()
	add_child(sfx_hurt)
	sfx_hurt.stream = _gerar_bip_provisorio(220.0, 0.12) 
	sfx_hurt.volume_db = -6.0

func _physics_process(delta: float) -> void:
	if not hud:
		hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.atualizar_vida(hp, max_hp)
			hud.atualizar_escudo(shield, max_shield)
			hud.atualizar_arma("Pistola")
			hud.atualizar_calor(current_heat, max_heat, is_overheated)

	# Verificação do limite de quedra
	if global_position.y > FALL_LIMIT and not is_dead:
		take_damage(hp + shield)

	# Lógica do I-frame
	if is_invulnerable:
		invuln_timer -= delta
		if invuln_timer <= 0:
			is_invulnerable = false
			animation.visible = true 
		else:
			animation.visible = int(invuln_timer * 10) % 2 == 0

	if is_minigame_active:
		minigame_progress += MINIGAME_SPEED * delta
		if hud:
			hud.atualizar_cursor_resfriamento(minigame_progress)
		
		if minigame_progress >= 1.0:
			_finalizar_minigame(false, "errado")
		elif Input.is_action_just_pressed("shoot"):
			if minigame_progress >= 0.20 and minigame_progress <= 0.30:
				_finalizar_minigame(true, "perfeito")
			elif minigame_progress >= 0.49 and minigame_progress <= 0.65:
				_finalizar_minigame(true, "bom")
			else:
				_finalizar_minigame(false, "errado")

	elif current_heat > 0:
		current_heat -= cooling_rate * delta
		if current_heat < 0:
			current_heat = 0
		if is_overheated and current_heat == 0:
			is_overheated = false
		if hud:
			hud.atualizar_calor(current_heat, max_heat, is_overheated)

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

	if Input.is_action_pressed("shoot") and shoot_timer <= 0 and not is_overheated:
		_shoot()

	# Botão do ataque corpo a corpo (R)
	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		animation.flip_h = facing_direction < 0
		animation.play("attack")
		
	if is_attacking and not animation.is_playing():
		is_attacking = false
		_apply_melee_damage()

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
	
	if sfx_shoot:
		sfx_shoot.play()
	
	current_heat += heat_per_shot
	if current_heat >= max_heat:
		current_heat = max_heat
		is_overheated = true
		_iniciar_minigame_resfriamento()
		
	if hud:
		hud.atualizar_calor(current_heat, max_heat, is_overheated)
		
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

func _iniciar_minigame_resfriamento() -> void:
	is_minigame_active = true
	minigame_progress = 0.0
	if hud:
		hud.mostrar_minigame_resfriamento()

func _finalizar_minigame(sucesso: bool, tipo: String) -> void:
	is_minigame_active = false
	if hud:
		hud.esconder_minigame_resfriamento()
	
	if sucesso:
		is_overheated = false
		if tipo == "perfeito":
			current_heat = 0.0       
		elif tipo == "bom":
			current_heat = 25.0      
	else:
		current_heat = max_heat      
		
	if hud:
		hud.atualizar_calor(current_heat, max_heat, is_overheated)

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
	# Bloquea o dano caso o personagem esteja morto ou com I-frame
	if is_dead or is_invulnerable:
		return
		
	if not hud:
		hud = get_tree().get_first_node_in_group("hud")
		
	if shield > 0:
		if amount <= shield:
			shield -= amount
			amount = 0
		else:
			amount -= shield
			shield = 0
			
	if amount > 0:
		hp -= amount
		if hp < 0:
			hp = 0
			
	if hud:
		hud.atualizar_vida(hp, max_hp)
		hud.atualizar_escudo(shield, max_shield)
	
	if hp <= 0:
		is_dead = true
		
		if sfx_death:
			sfx_death.play()
		if hud:
			hud.mostrar_tela_morte()
			
		if animation.animation_finished.is_connected(_on_hurt_finished):
			animation.animation_finished.disconnect(_on_hurt_finished)
		animation.play("death")
		if not animation.animation_finished.is_connected(_on_death_finished):
			animation.animation_finished.connect(_on_death_finished)
	else:
		is_hurt = true
		is_invulnerable = true
		invuln_timer = INVULN_TIME
		if sfx_hurt:
			sfx_hurt.play()
		animation.play("hurt")
		if not animation.animation_finished.is_connected(_on_hurt_finished):
			animation.animation_finished.connect(_on_hurt_finished)

func _on_hurt_finished() -> void:
	is_hurt = false
	animation.animation_finished.disconnect(_on_hurt_finished)

func _on_death_finished() -> void:
	queue_free()
	
func _apply_melee_damage() -> void:
	if not hud:
		hud = get_tree().get_first_node_in_group("hud")

	var enemies = get_tree().get_nodes_in_group("villain")
	var hit_connected = false
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		
		var dir_to_enemy = enemy.global_position.x - global_position.x
		var is_facing_enemy = (dir_to_enemy * facing_direction) >= 0
		
		if dist <= 90.0 and is_facing_enemy:
			enemy.take_damage(30, 400.0 * facing_direction)
			hit_connected = true
			if hud:
				hud.mostrar_vida_inimigo("Ameaça Ciborgue", enemy.current_hp, enemy.max_hp)
				
	if hit_connected and sfx_melee_hit:
		sfx_melee_hit.play()

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
