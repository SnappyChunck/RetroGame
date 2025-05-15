extends CharacterBody3D
class_name MovementController


@onready var cam: Camera3D = $Head/Camera

var current_bobbing_speed = 0.0
var current_bobbing_amount = 0.0

var new_pos

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
@onready var gravity: float = (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier)

func _ready() -> void:
	mouse_sensitivity = mouse_sensitivity / 1000
	y_limit = deg_to_rad(y_limit)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.current = is_multiplayer_authority()

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		update_camera(delta)
		
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

func can_sprint() -> bool:
	return (Input.is_action_pressed(&"sprint") #controller.is_on_floor() and 
			and input_axis.x >= 0.5)

func camera_rotation() -> void:
	if is_multiplayer_authority():
		rot.y -= mouse_axis.x * mouse_sensitivity
		rot.x = clamp(rot.x - mouse_axis.y * mouse_sensitivity, -y_limit, y_limit)
		
		cam.get_owner().rotation.y = rot.y
		cam.rotation.x = rot.x

func update_camera(delta):
	if input_axis && is_on_floor():
		bobbing_timer += delta * current_bobbing_speed
		bob_offset_y = sin(bobbing_timer) * current_bobbing_amount
		new_pos = cam.position + Vector3(cam.position.x, bob_offset_y, 0)
		cam.position = new_pos
	else:
		cam.position = cam.position.lerp(base_cam_position, delta * 5.0)
		bobbing_timer = 0.0

	if can_sprint():
		current_bobbing_speed = sprint_bobbing_speed
		current_bobbing_amount = sprint_bobbing_amount
	else:
		current_bobbing_speed = bobbing_speed
		current_bobbing_amount = bobbing_amount

func _input(event: InputEvent) -> void:
	if is_multiplayer_authority():
		if event.is_action_pressed(&"ui_cancel"):
			$"../".exit_game(name.to_int())
			get_tree().quit()
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			mouse_axis = event.relative
			camera_rotation()
		if event.is_action_pressed(&"change_mouse_input"):
			match Input.get_mouse_mode():
				Input.MOUSE_MODE_CAPTURED:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				Input.MOUSE_MODE_VISIBLE:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
