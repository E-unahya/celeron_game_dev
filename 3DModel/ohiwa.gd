extends CharacterBody3D

class_name Ohiwa

@export var rakka_flag : bool = false
@export var forward : Vector3 = Vector3.MODEL_FRONT
@export var speed : float = 0
@onready var spiky_ball_2: Node3D = $SpikyBall2


func _ready() -> void:
	rakka_flag = false
	print("Ohiwa is here: ", name)

func _physics_process(delta: float) -> void:
	if rakka_flag:
		if !is_on_floor():
			velocity += get_gravity() * delta
		velocity.z = forward.z
		velocity.x = velocity.x
		if is_on_wall():
			velocity.y = 12.0
		move_and_slide()
		# spiky_ball_2.rotate_x(speed * delta)
