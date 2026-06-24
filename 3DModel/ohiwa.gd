extends RigidBody3D
# 大岩をRigidBodyにしたの失敗っぽいしArea3DとAnimationPlayerを組み合わせて落ちた専用のアニメーションを再生してそれが終わったら当たり判定が飛ぶ仕組みを実装すればいいんだ

class_name Ohiwa
@export var forward : Vector3 = Vector3.MODEL_FRONT
@export var speed : float = 0
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var shadow_mesh: MeshInstance3D = $ShadowMesh


func _ready() -> void:
	ray_cast_3d.target_position = forward.normalized() * 10 + Vector3(0, -10.0, 0)
	freeze = true


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not freeze:
		add_constant_central_force(forward * 5)
		if ray_cast_3d.is_colliding():
			apply_impulse(Vector3.UP * 100)


func _physics_process(delta: float) -> void:
	if !freeze and ray_cast_3d.is_colliding():
		shadow_mesh.position = position - Vector3.UP * 10 * delta
		shadow_mesh.global_rotation = Vector3.ZERO
		shadow_mesh.global_position = ray_cast_3d.target_position


func _on_area_3d_body_entered(body:Node3D) -> void:
	if body is Player:
		body.die()
		freeze = true
