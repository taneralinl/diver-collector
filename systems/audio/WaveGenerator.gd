class_name WaveGenerator
extends RefCounted

const SAMPLE_RATE = 44100
const BIT_DEPTH = 16 # 16-bit PCM

# Generates a "Kickbox Impact" (Low Thud + Noise)
static func generate_shard_sfx() -> AudioStreamWAV:
	var duration = 0.15 # Short and punchy
	var frames = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	
	var buffer = PackedByteArray()
	buffer.resize(frames * 2)
	
	var phase = 0.0
	var freq = 150.0 # Low frequency thud
	
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var envelope = exp(-20.0 * t) # Very fast decay
		
		# Sine sweep down (Kick drum effect)
		var current_freq = freq * (1.0 - t * 4.0)
		if current_freq < 20.0: current_freq = 20.0
		
		var signal_val = sin(phase) * 0.8
		
		# Add Noise for "Slap" texture
		signal_val += (randf() * 2.0 - 1.0) * 0.4 * exp(-40.0 * t)
		
		signal_val *= envelope
		
		phase += 2.0 * PI * current_freq / SAMPLE_RATE
		
		var sample_int = int(clamp(signal_val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)
		
	stream.data = buffer
	return stream

# Generates a noise "Dash" sound
static func generate_dash_sfx() -> AudioStreamWAV:
	var duration = 0.2
	var frames = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	
	var buffer = PackedByteArray()
	buffer.resize(frames * 2)
	
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var envelope = 1.0 - (t / duration) # Linear decay
		
		var sample = randf_range(-1.0, 1.0)
		sample *= envelope * 0.4
		
		var sample_int = int(sample * 32767.0)
		buffer.encode_s16(i * 2, sample_int)
		
	stream.data = buffer
	return stream

# Generates a low "Hit/Explosion" sound
static func generate_hit_sfx() -> AudioStreamWAV:
	var duration = 0.5
	var frames = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	
	var buffer = PackedByteArray()
	buffer.resize(frames * 2)
	
	var phase = 0.0
	var frequency = 150.0 # Low pitch
	
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var envelope = exp(-8.0 * t)
		
		# Sawtooth-ish
		var sample = (fmod(phase, 2.0 * PI) / PI) - 1.0
		sample *= envelope * 0.6
		
		# Pitch Drop
		frequency = max(20.0, frequency - 0.5)
		phase += 2.0 * PI * frequency / SAMPLE_RATE
		
		var sample_int = int(sample * 32767.0)
		buffer.encode_s16(i * 2, sample_int)
		
	stream.data = buffer
	return stream

# Generates a looping "Underwater Drone/Bubbles" sound
static func generate_ambient_sfx() -> AudioStreamWAV:
	var duration = 2.0 # Longer loop
	var frames = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = frames
	
	var buffer = PackedByteArray()
	buffer.resize(frames * 2)
	
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		# Low frequency noise (bubbling/drone)
		var sample = (randf() * 2.0 - 1.0) * 0.1
		# Low pass filter (very simple: average with prev)
		sample = (sample + sin(t * 2.0 * PI * 40.0)) * 0.5
		
		var sample_int = int(clamp(sample, -1.0, 1.0) * 16000.0) # Lower volume
		buffer.encode_s16(i * 2, sample_int)
		
	stream.data = buffer
	return stream

# Specialized Capture Sounds (Addictive Profiles)
static func generate_capture_sfx(tier: int) -> AudioStreamWAV:
	var duration = 0.2
	var freq = 800.0
	var type = "sine"
	
	match tier:
		0: # Pearl: Plink!
			duration = 0.1
			freq = 1200.0
		1, 2: # Fish: Splash/Meat!
			duration = 0.2
			freq = 400.0
			type = "noise"
		3, 4: # Large/Treasure: Jackpot!
			duration = 0.4
			freq = 600.0
			type = "chime"
			
	var frames = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	
	var buffer = PackedByteArray()
	buffer.resize(frames * 2)
	
	var phase = 0.0
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var envelope = exp(-15.0 * t) if tier < 4 else exp(-5.0 * t)
		
		var sample = 0.0
		if type == "sine":
			sample = sin(phase)
		elif type == "noise":
			sample = (randf() * 2.0 - 1.0) * 0.5 + sin(phase) * 0.5
		elif type == "chime":
			# Arpeggio/Bell sound
			var f_mod = freq * (1.0 + floor(t * 10.0) * 0.5)
			sample = sin(phase) * 0.6 + sin(phase * 2.0) * 0.3
			phase += 2.0 * PI * f_mod / SAMPLE_RATE
		
		if type != "chime":
			phase += 2.0 * PI * freq / SAMPLE_RATE
			
		sample *= envelope * 0.8
		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)
		
	stream.data = buffer
	return stream
