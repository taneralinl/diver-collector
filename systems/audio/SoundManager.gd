extends Node

var sfx_shard: AudioStreamWAV
var sfx_dash: AudioStreamWAV
var sfx_hit: AudioStreamWAV

func _ready():
	# Generate sounds procedurally on startup
	var wave_gen = load("res://systems/audio/WaveGenerator.gd")
	if wave_gen:
		sfx_shard = wave_gen.generate_shard_sfx()
		sfx_dash = wave_gen.generate_dash_sfx()
		sfx_hit = wave_gen.generate_hit_sfx()
		print("SoundManager: Procedural Audio Generated")
		
		# Start Ambient Loop
		var ambient = wave_gen.generate_ambient_sfx()
		play_ambient(ambient)

func play_ambient(stream: AudioStream):
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -12.0
	player.autoplay = true
	add_child(player)

func play_coin_sfx():
	# Legacy support, defaults to Tier 1 (Pearl)
	play_capture_sfx(1)

func play_capture_sfx(tier: int):
	var wave_gen = load("res://systems/audio/WaveGenerator.gd")
	if wave_gen:
		var stream = wave_gen.generate_capture_sfx(tier)
		play_sfx(stream, randf_range(0.95, 1.05))

func play_dash_sfx():
	if sfx_dash: play_sfx(sfx_dash, randf_range(0.9, 1.1))

func play_hit_sfx():
	if sfx_hit: play_sfx(sfx_hit, randf_range(0.8, 1.0))

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0):
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.autoplay = true
	player.finished.connect(player.queue_free)
	add_child(player)

func play_music(_stream: AudioStream):
	pass
