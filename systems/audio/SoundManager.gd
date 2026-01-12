extends Node

var sfx_coin: AudioStreamWAV
var sfx_dash: AudioStreamWAV
var sfx_hit: AudioStreamWAV

func _ready():
	# Generate sounds procedurally on startup
	var wave_gen = load("res://systems/audio/WaveGenerator.gd")
	if wave_gen:
		sfx_coin = wave_gen.generate_coin_sfx()
		sfx_dash = wave_gen.generate_dash_sfx()
		sfx_hit = wave_gen.generate_hit_sfx()
		print("SoundManager: Procedural Audio Generated")

func play_coin_sfx():
	if sfx_coin: play_sfx(sfx_coin, randf_range(0.9, 1.1))

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
