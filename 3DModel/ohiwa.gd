extends CharacterBody3D

class_name Ohiwa

@export var rakka_flag : bool = false
@export var forward : Vector3 = Vector3.MODEL_FRONT
@export var speed : float = 0
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	rakka_flag = false

func _physics_process(delta: float) -> void:
	if rakka_flag:
		if !is_on_floor():
			velocity += get_gravity() * delta
		velocity.z = forward.z
		velocity.x = velocity.x
		if is_on_wall():
			velocity.y = 12.0
		move_and_slide()
		mesh_instance_3d.rotate_x(speed * delta)
		if is_on_ceiling():
			rakka_flag = false


func _on_area_3d_body_entered(body:Node3D) -> void:
	if body is Player:
		body.die()
		rakka_flag = false
