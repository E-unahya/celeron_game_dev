extends RigidBody3D

class_name Ohiwa
@export var forward : Vector3 = Vector3.MODEL_FRONT
@export var speed : float = 0
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D


func _ready() -> void:
	ray_cast_3d.target_position = forward.normalized() * 10 + Vector3(0, -10.0, 0)
	freeze = true


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not freeze:
		add_constant_central_force(forward)
		if ray_cast_3d.is_colliding():
			apply_impulse(Vector3.UP * 10)

func _on_area_3d_body_entered(body:Node3D) -> void:
	if body is Player:
		body.die()
		freeze = true
