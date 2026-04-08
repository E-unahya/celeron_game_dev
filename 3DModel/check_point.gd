extends Area3D

@onready var check_point_mesh: MeshInstance3D = $CheckPointMesh

func _ready() -> void:
	check_point_mesh.position = Vector3.ZERO
	check_point_mesh.rotation = Vector3.ZERO
	check_point_mesh.hide()

func _on_body_entered(body: Node3D) -> void:
	var tween = get_tree().create_tween()
	check_point_mesh.show()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(check_point_mesh, "position", Vector3(0, 1.5, 0), 1.0)
	tween.tween_property(check_point_mesh, "rotation", Vector3(0, 3600, 0), 1.0)
	body.check_point = global_position
