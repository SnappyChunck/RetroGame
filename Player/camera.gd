extends Node3D


@export_node_path("Camera3D") var cam_path := NodePath("Camera")
@onready var cam: Camera3D = get_node(cam_path)

@onready var player = $".."

var current_bobbing_speed = 0.0
var current_bobbing_amount = 0.0

@onready var base_cam_position = cam.position

var bobbing_speed = 10.0
var bobbing_amount = 0.01

var bobbing_timer = 0.0
var bob_offset_y = 0.0

var sprint_bobbing_amount = 0.02
var sprint_bobbing_speed = 12.0

@export var mouse_sensitivity := 2.0
@export var y_limit := 90.0
var mouse_axis := Vector2()
var rot := Vector3()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_sensitivity = mouse_sensitivity / 1000
	y_limit = deg_to_rad(y_limit)


# Called when there is an input event
func _input(event: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_axis = event.relative
		camera_rotation()


# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	var joystick_axis := Input.get_vector(&"look_left", &"look_right",
			&"look_down", &"look_up")
	
	if joystick_axis != Vector2.ZERO:
		mouse_axis = joystick_axis * 1000.0 * delta
		camera_rotation()
	
	if player.input_axis && player.is_on_floor():
		bobbing_timer += delta * current_bobbing_speed
		var bob_offset_y = sin(bobbing_timer) * current_bobbing_amount
		var new_pos = cam.position + Vector3(cam.position.x, bob_offset_y, 0)
		cam.position = new_pos
	else:
		cam.position = cam.position.lerp(base_cam_position, delta * 5.0)
		bobbing_timer = 0.0

	if player.can_sprint():
		current_bobbing_speed = sprint_bobbing_speed
		current_bobbing_amount = sprint_bobbing_amount
	else:
		current_bobbing_speed = bobbing_speed
		current_bobbing_amount = bobbing_amount


func camera_rotation() -> void:
	# Horizontal mouse look.
	rot.y -= mouse_axis.x * mouse_sensitivity
	# Vertical mouse look.
	rot.x = clamp(rot.x - mouse_axis.y * mouse_sensitivity, -y_limit, y_limit)
	
	get_owner().rotation.y = rot.y
	rotation.x = rot.x
