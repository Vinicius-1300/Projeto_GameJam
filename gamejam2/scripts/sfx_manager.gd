extends Node

# --- Som da interface ---
func play_click() -> void:
	var player = AudioStreamPlayer.new()
	var generator = AudioStreamGenerator.new()
	
	generator.mix_rate = 44100
	generator.buffer_length = 0.1 
	
	player.stream = generator
	player.bus = "SFX"
	add_child(player)
	player.play()
	
	var playback = player.get_stream_playback()
	var phase = 0.0
	var frequency = 880.0 
	var increment = frequency / generator.mix_rate
	
	var frames_available = playback.get_frames_available()
	for i in range(frames_available):
		playback.push_frame(Vector2.ONE * sin(phase * TAU))
		phase = fmod(phase + increment, 1.0)
	
	await get_tree().create_timer(0.2).timeout
	player.queue_free()

# --- Som do tiro de Plasma ---
func play_tiro_plasma() -> void:
	var player = AudioStreamPlayer.new()
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_length = 0.2 
	player.stream = generator
	player.bus = "SFX"
	add_child(player)
	player.play()

	var playback = player.get_stream_playback()
	var phase = 0.0
	var frames = playback.get_frames_available()
	
	var freq_inicial = 1500.0
	var freq_final = 200.0

	for i in range(frames):
		var t = float(i) / frames
		var current_freq = lerp(freq_inicial, freq_final, t * t) 
		var increment = current_freq / 44100.0
		
		var volume = 1.0 - t
		
		playback.push_frame(Vector2.ONE * sin(phase * TAU) * volume)
		phase = fmod(phase + increment, 1.0)

	await get_tree().create_timer(0.3).timeout
	player.queue_free()

# --- Som de explosão ---
func play_explosao() -> void:
	var player = AudioStreamPlayer.new()
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_length = 0.6 
	player.stream = generator
	player.bus = "SFX"
	add_child(player)
	player.play()

	var playback = player.get_stream_playback()
	var frames = playback.get_frames_available()

	for i in range(frames):
		var t = float(i) / frames
		var noise = randf_range(-1.0, 1.0)
		var volume = pow(1.0 - t, 3.0) 
		
		playback.push_frame(Vector2.ONE * noise * volume)

	await get_tree().create_timer(0.7).timeout
	player.queue_free()

# --- Som de alerta do inimigo ---
func play_alerta() -> void:
	var player = AudioStreamPlayer.new()
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_length = 0.3
	player.stream = generator
	player.bus = "SFX"
	add_child(player)
	player.play()

	var playback = player.get_stream_playback()
	var phase = 0.0
	var frames = playback.get_frames_available()
	var freq = 1200.0 
	var increment = freq / 44100.0

	for i in range(frames):
		var t = float(i) / frames
		var volume = 0.0
		if t < 0.2 or (t > 0.4 and t < 0.6):
			volume = 0.8
			
		playback.push_frame(Vector2.ONE * sin(phase * TAU) * volume)
		phase = fmod(phase + increment, 1.0)

	await get_tree().create_timer(0.4).timeout
	player.queue_free()
