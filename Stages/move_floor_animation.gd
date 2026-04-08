extends AnimationPlayer


func _ready() -> void:
	pass
	# play("RESET")

func _on_move_to_player_entered() -> void:
	play("MoveTo")
