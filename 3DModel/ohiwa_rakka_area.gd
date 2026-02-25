extends Area3D

@onready var ohiwa: Ohiwa = $Ohiwa

@export var forward : Vector3 = Vector3.MODEL_FRONT

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		ohiwa.rakka_flag = true
		ohiwa.forward = forward
