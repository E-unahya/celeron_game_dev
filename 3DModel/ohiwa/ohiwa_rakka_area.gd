extends Area3D
@onready var ohiwa : MeshInstance3D = $Ohiwa
@onready var ohiwa_raycast : RayCast3D = $Ohiwa/RayCast3D
@onready var animation_player :AnimationPlayer= $AnimationPlayer
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var shadow_mesh : MeshInstance3D = $ShadowMesh
@onready var ohiwa_material : StandardMaterial3D = $Ohiwa.mesh.material

var ohiwa_start : bool = false
var target : Player

# 初期位置を保存する変数
var ohiwa_initial_position : Vector3
var shadow_initial_position : Vector3

func _ready() -> void:
	# 大岩・影の初期位置(グローバル座標)を保存
	ohiwa_initial_position = ohiwa.global_position
	shadow_initial_position = shadow_mesh.global_position
	animation_player.play("RESET")

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		animation_player.play("Ohiwa Go")
		target = body
		target.still_alive.connect(_on_player_dead)

func _physics_process(delta: float) -> void:
	if ohiwa_start and target:
		ohiwa_material.uv1_offset.x += delta * 300
		var hit_pos_y
		if ohiwa_raycast.is_colliding():
			hit_pos_y = ohiwa_raycast.get_collision_point().y
		else:
			hit_pos_y = 1
		var goto_position = Vector3(global_position.x, hit_pos_y * 6, target.global_position.z)
		ohiwa.global_position = ohiwa.global_position.lerp(goto_position, 0.005)
		shadow_mesh.global_position = Vector3(ohiwa.global_position.x, ohiwa.global_position.y - 9.0, ohiwa.global_position.z)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Ohiwa Go":
			animation_player.play("Rolling")
			ohiwa_start = true


# 共通化したリセット処理
func _reset_ohiwa() -> void:
	target = null
	ohiwa_start = false

	# アニメーションを止めてから RESET を再生し、状態を初期化する
	animation_player.stop()
	animation_player.play("RESET")
	# RESET内で値が反映されるように一度シークしておく(念のため)
	animation_player.seek(0.0, true)
	animation_player.stop()

	# 大岩・影の座標を明示的に初期位置へ戻す
	ohiwa.global_position = ohiwa_initial_position
	shadow_mesh.global_position = shadow_initial_position

	# UVオフセットもリセットしたい場合はここで初期化
	ohiwa_material.uv1_offset.x = 0

func _on_area_3d_body_entered(body:Node3D) -> void:
	if body is Player:
		body.die()
		_reset_ohiwa()

func _on_ohiwa_stop_area_area_entered(area: Area3D) -> void:
	ohiwa_start = false
	animation_player.stop()

func _on_player_dead() -> void:
	_reset_ohiwa()
