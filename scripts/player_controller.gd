extends CharacterBody3D
class_name PlayerController

@export var camera: Camera3D
@export var footsteps: AudioStreamPlayer3D
@export_range(0.0, 32.0) var speed: float = 8.0
@export_range(0.0, 2.0) var view_bob_amplitude: float = 1.0
@export_range(0.0, 2.0) var view_bob_period: float = 1.0

var footsteps_played: bool = false

func _ready():
	if (!OS.is_debug_build()):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _notification(what):
	if (what == NOTIFICATION_APPLICATION_FOCUS_IN):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(_delta):
	set_shader_globals()

func _physics_process(_delta):
	move()
	bob_view()

func _input(event):
	if (event is InputEventMouseMotion):
		rotate(transform.basis.y, -event.relative.x * 0.001)
		camera.rotate(Vector3.RIGHT, -event.relative.y * 0.001)

func move():
	if (Input.is_action_pressed("move_forward")):
		velocity += -transform.basis.z
	if (Input.is_action_pressed("move_backward")):
		velocity += transform.basis.z
	if (Input.is_action_pressed("move_right")):
		velocity += transform.basis.x
	if (Input.is_action_pressed("move_left")):
		velocity += -transform.basis.x
	
	velocity *= speed
	
	move_and_slide()
	velocity = Vector3.ZERO

func set_shader_globals():
	RenderingServer.global_shader_parameter_set("player_pos", position)

func bob_view():
	var amplitude = get_real_velocity().length() * 0.001 * view_bob_amplitude
	var sine_wave = sin(Time.get_ticks_msec() * 0.01 * view_bob_period) * amplitude
	
	camera.position.y += sine_wave
	calculate_footstep_audio(amplitude, sine_wave)

func calculate_footstep_audio(amplitude: float, sine_wave: float):
	if (is_zero_approx(sine_wave)):
		return

	if (abs(sine_wave - amplitude) < 0.001):
		footsteps_played = false

	if (abs(sine_wave - -amplitude) < 0.001 && !footsteps_played):
		footsteps.pitch_scale = randf_range(0.8, 1.2)
		footsteps.play()
		footsteps_played = true
