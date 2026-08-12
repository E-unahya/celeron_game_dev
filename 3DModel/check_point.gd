extends Area3D

@onready var check_point_mesh: Sprite3D = $CheckPointMesh

func _ready() -> void:
	check_point_mesh.position = Vector3.ZERO
	check_point_mesh.rotation_degrees = Vector3.ZERO
	check_point_mesh.hide()

func _on_body_entered(body: Node3D) -> void:
	body.check_point = global_position
	call_deferred("check_point_animation")


func check_point_animation():
	# Area3Dの衝突監視を無効化（PhysicsServerへの負荷軽減のため遅延実行は維持）
	monitoring = false
	check_point_mesh.show()

	# MeshInstance3DのみをTweenさせて物理空間のTransform同期負荷を避ける
	var tween = get_tree().create_tween()
	# tween.set_ease(Tween.EASE_IN_OUT)
	# tween.set_parallel(true)
	
	# 位置の移動（MeshInstance3Dのローカル座標）
	tween.tween_property(check_point_mesh, "position", Vector3(0, 1.5, 0), 0.6)
	
	# 回転アニメーション（MeshInstance3Dのローカルquaternionを360度回転）
	# var target_quat = check_point_mesh.quaternion * Quaternion(Vector3.UP, TAU)
	# tween.tween_property(check_point_mesh, "quaternion", target_quat, 0.6).set_trans(Tween.TRANS_CUBIC)
