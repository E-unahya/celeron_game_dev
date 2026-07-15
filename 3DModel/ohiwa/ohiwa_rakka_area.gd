extends Area3D

@onready var ohiwa : MeshInstance3D = $Ohiwa
@onready var ohiwa_raycast : RayCast3D = $Ohiwa/RayCast3D
@onready var animation_player :AnimationPlayer= $AnimationPlayer
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var shadow_mesh : MeshInstance3D = $ShadowMesh
@onready var ohiwa_material : StandardMaterial3D = $Ohiwa.mesh.material

var ohiwa_start : bool = false
var target : Player

func _ready() -> void:
	animation_player.play("RESET")

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		animation_player.play("Ohiwa Go")
		target = body

func _physics_process(delta: float) -> void:
	if ohiwa_start and target:
		ohiwa_material.uv1_offset.x += delta * 300
		# TODO targetのglobal_positionのyの部分を意図的に固定したい。
		var hit_pos_y
		if ohiwa_raycast.is_colliding():
			hit_pos_y = ohiwa_raycast.get_collision_point().y
		else:
			hit_pos_y = 1
			pass
		var goto_position = Vector3(global_position.x, hit_pos_y * 6, target.global_position.z)
		ohiwa.global_position = ohiwa.global_position.lerp(goto_position, 0.003)
		shadow_mesh.global_position = Vector3( ohiwa.global_position.x, ohiwa.global_position.y - 9.0, ohiwa.global_position.z)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Ohiwa Go":
			animation_player.play("Rolling")
			ohiwa_start = true


func _on_area_3d_body_entered(body:Node3D) -> void:
	if body is Player:
		body.die()
		target = null
		animation_player.play("RESET")
		animation_player.stop()


func _on_player_dead() -> void:
	ohiwa_start = false


func _on_ohiwa_stop_area_area_entered(area: Area3D) -> void:
	ohiwa_start = false
	animation_player.stop()
