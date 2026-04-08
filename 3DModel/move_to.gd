extends AnimatableBody3D

class_name MoveTo
signal player_entered

func _on_area_3d_body_entered(body: Node3D) -> void:
	# Body is player.
	player_entered.emit()
