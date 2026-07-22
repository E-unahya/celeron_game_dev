extends Area3D

@onready var check_point_mesh: MeshInstance3D = $CheckPointMesh

var is_activated := false

func _ready() -> void:
	check_point_mesh.position = Vector3.ZERO
	check_point_mesh.rotation_degrees = Vector3.ZERO
	check_point_mesh.hide()

func _on_body_entered(body: Node3D) -> void:
	if is_activated or not body is Player:
		return

	is_activated = true
	monitoring = false
	body.check_point = global_position

	var tween = get_tree().create_tween()
	check_point_mesh.show()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(check_point_mesh, "position", Vector3(0, 1.5, 0), 0.6)
	tween.tween_property(check_point_mesh, "rotation_degrees", Vector3(0, 360, 0), 0.6)

