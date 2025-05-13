extends CharacterBody3D
class_name MovementController


@onready var cam: Camera3D = $Head/Camera

@export var mouse_sensitivity := 2.0
@export var y_limit := 90.0
var mouse_axis := Vector2()
var rot := Vector3()

@export var sprint_speed := 9.5
@export var fov_multiplier := 1.1
@onready var normal_speed: float = speed
@onready var normal_fov: float = cam.fov

@export var gravity_multiplier := 3.5
@export var speed := 7.5
@export var acceleration := 6
@export var deceleration := 10
@export_range(0.0, 1.0, 0.05) var air_control := 0.3
@export var jump_height := 10
var direction := Vector3()
var input_axis := Vector2()
# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
@onready var gravity: float = (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier)

func _ready() -> void:
	mouse_sensitivity = mouse_sensitivity / 1000
	y_limit = deg_to_rad(y_limit)

# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	input_axis = Input.get_vector(&"move_back", &"move_forward", &"move_left", &"move_right")
	
	direction_input()
	
	if is_on_floor():
		if Input.is_action_just_pressed(&"jump"):
			velocity.y = jump_height
	else:
		velocity.y -= gravity * delta
	
	if can_sprint():
		speed = sprint_speed
		cam.set_fov(lerp(cam.fov, normal_fov * fov_multiplier, delta * 8))
	else:
		speed = normal_speed
		cam.set_fov(lerp(cam.fov, normal_fov, delta * 8))
	
	accelerate(delta)
	
	var joystick_axis := Input.get_vector(&"look_left", &"look_right", &"look_down", &"look_up")
	
	if joystick_axis != Vector2.ZERO:
		mouse_axis = joystick_axis * 1000.0 * delta
		camera_rotation()
	
	move_and_slide()


func direction_input() -> void:
	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	direction = aim.z * -input_axis.x + aim.x * input_axis.y


func accelerate(delta: float) -> void:
	# Using only the horizontal velocity, interpolate towards the input.
	var temp_vel := velocity
	temp_vel.y = 0
	
	var temp_accel: float
	var target: Vector3 = direction * speed
	
	if direction.dot(temp_vel) > 0:
		temp_accel = acceleration
	else:
		temp_accel = deceleration
	
	if not is_on_floor():
		temp_accel *= air_control
	
	var accel_weight = clamp(temp_accel * delta, 0.0, 1.0)
	temp_vel = temp_vel.lerp(target, accel_weight)
	
	velocity.x = temp_vel.x
	velocity.z = temp_vel.z


func camera_rotation() -> void:
	# Horizontal mouse look.
	rot.y -= mouse_axis.x * mouse_sensitivity
	# Vertical mouse look.
	rot.x = clamp(rot.x - mouse_axis.y * mouse_sensitivity, -y_limit, y_limit)
	
	rotation.y = rot.y
	rotation.x = rot.x

func _input(event: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_axis = event.relative
		camera_rotation()

func can_sprint() -> bool:
	return (Input.is_action_pressed(&"sprint") #controller.is_on_floor() and 
			and input_axis.x >= 0.5)
