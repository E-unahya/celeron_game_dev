extends Node3D
class_name Ohiwa
@export var forward : Vector3 = Vector3.MODEL_FRONT
@export var speed : float = 0
@onready var ray_cast_3d: RayCast3D = $OhiwaHontai/RayCast3D
@onready var shadow_ray_cast_3d: RayCast3D = $ShadowRayCast3D
@onready var shadow_mesh: MeshInstance3D = $ShadowMesh
@onready var gareki_particle: GPUParticles3D = $GarekiParticle
@onready var ohiwa_hontai: Area3D = $OhiwaHontai

var move_start = false

func _ready() -> void:
	await get_tree().create_timer(randf_range(0.01, 0.1)).timeout
	move_start = true


func _physics_process(delta: float) -> void:
	if move_start:
		ohiwa_hontai.position.y -= speed * delta
	if shadow_ray_cast_3d.is_colliding():
		print("Before")
		print(shadow_mesh.position)
		shadow_mesh.position = shadow_ray_cast_3d.get_collision_point()
		print("After")
		print(shadow_mesh.position)
	if ray_cast_3d.is_colliding():
		gareki_particle.emitting = false
		await get_tree().create_timer(0.5).timeout
		queue_free()


func _on_area_3d_body_entered(body:Node3D) -> void:
	if body is Player:
		body.die()
