extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		# プレイヤーが４んでやり直しになる。
		# とりあえず後回しで再読み込みとする。
		get_tree().reload_current_scene()
