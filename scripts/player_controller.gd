extends CharacterBody3D
class_name PlayerController

@export_range(0.0, 32.0) var speed: float = 8.0;
@export var camera: Camera3D;

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta):
	set_shader_globals()

func _physics_process(_delta):
	move()

func _input(event):
	if (event is InputEventMouseMotion):
		rotate(transform.basis.y, -event.relative.x * 0.001)
		camera.rotate(Vector3.RIGHT, -event.relative.y * 0.001)

func move():
	if (Input.is_action_pressed("move_forward")):
		velocity += -transform.basis.z;
	if (Input.is_action_pressed("move_backward")):
		velocity += transform.basis.z;
	if (Input.is_action_pressed("move_right")):
		velocity += transform.basis.x;
	if (Input.is_action_pressed("move_left")):
		velocity += -transform.basis.x;
	
	velocity *= speed;
	
	move_and_slide();
	velocity = Vector3.ZERO;

func set_shader_globals():
	RenderingServer.global_shader_parameter_set("player_pos", position)
