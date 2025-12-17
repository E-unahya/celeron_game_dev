extends Area3D

@onready var tower_door : MeshInstance3D = get_node("Tower_Door")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tower_door.rotation = Vector3.ZERO

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		var tween = get_tree().create_tween()
		tween.tween_property(tower_door, "rotation_degrees", Vector3(0, 105, 0), 1.5)
