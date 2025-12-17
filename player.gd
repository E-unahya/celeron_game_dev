extends CharacterBody3D


@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
## カメラを動かす速度設定
@export var camera_speed := 0.03

@onready var kaiten_you := get_node("KaitenYou")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		# rotateさせるのどうすればいい？
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	"""
		# カメラを回す処理　デバッグ用に？
	if Input.is_action_pressed("rotate_y_left"):
		# kaiten_you.rotate_y(camera_speed)
		rotate_y(camera_speed)
	if Input.is_action_pressed("rotate_y_right"):
		# kaiten_you.rotate_y(-camera_speed)
		rotate_y(-camera_speed)
	"""
	move_and_slide()
