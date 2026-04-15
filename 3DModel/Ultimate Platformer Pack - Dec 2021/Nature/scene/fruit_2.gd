extends Area3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
signal fruit_get

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = get_tree().create_tween()
	tween.set_loops()
	tween.tween_property(self, "rotation", Vector3(0, 720, 0), 1.0)
	tween.tween_property(self, "rotation", Vector3(0, 0, 0), 1.0)
	show()


func _on_body_entered(body: Node3D) -> void:
	# どうも普通に隠すくらいが丁度いいらしい
	if body is Player and visible:
		hide()
		collision_shape_3d.disabled = true
		fruit_get.emit()
