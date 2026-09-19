extends CharacterBody3D

## Walking speed in meters per second.
@export var speed := 6.0
## Upward speed when jumping. Higher number = higher jump.
@export var jump_velocity := 5.5
## How fast the mouse turns the camera.
@export var mouse_sensitivity := 0.003
## How fast the character turns to face the way it walks.
@export var turn_speed := 10.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var model: Node3D = $Model
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D


func _ready() -> void:
	# Hide the mouse and lock it to the window so it can turn the camera.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Stop the camera arm from bumping into our own body.
	spring_arm.add_excluded_object(get_rid())


func _unhandled_input(event: InputEvent) -> void:
	# Mouse left/right turns the pivot, mouse up/down tilts the arm.
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-70), deg_to_rad(20))

	# Esc shows the mouse again; clicking in the game hides it again.
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	# Gravity pulls us down while we are in the air.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump only when standing on something.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Turn WASD into a direction based on where the camera is looking.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := camera_pivot.global_basis * Vector3(input_dir.x, 0, input_dir.y)
	direction.y = 0
	direction = direction.normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		# Smoothly turn the model to face the way we are walking.
		var target_angle := atan2(direction.x, direction.z)
		model.global_rotation.y = lerp_angle(model.global_rotation.y, target_angle, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
