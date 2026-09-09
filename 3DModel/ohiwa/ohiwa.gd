extends Node3D
class_name Ohiwa
@export var forward : Vector3 = Vector3.MODEL_FRONT
@export var speed : float = 0
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var shadow_mesh: MeshInstance3D = $ShadowMesh

var move_start = false

func _ready() -> void:
	await get_tree().create_timer(randf_range(1, 3)).timeout
	move_start = true

func _physics_process(delta: float) -> void:
	if move_start:
		position.y -= speed * delta
	if ray_cast_3d.is_colliding():
		await get_tree().create_timer(0.5).timeout
		queue_free()


func _on_area_3d_body_entered(body:Node3D) -> void:
	if body is Player:
		body.die()
