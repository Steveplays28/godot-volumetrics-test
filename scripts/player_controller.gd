extends CharacterBody3D
class_name PlayerController

@export var camera: Camera3D
@export_range(0.0, 32.0) var speed: float = 8.0
@export_range(0.0, 2.0) var view_bob_amplitude: float = 1.0
@export_range(0.0, 2.0) var view_bob_period: float = 1.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	camera.position.y += sin(Time.get_ticks_msec() * 0.01 * view_bob_period) * get_real_velocity().length() * 0.001 * view_bob_amplitude
