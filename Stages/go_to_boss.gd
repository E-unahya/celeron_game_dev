extends Area3D

@onready var thunder: Node3D = $Thunder

@export_file("*.tscn") var boss_stage

@export var stages : Array[Door] = []

func check(is_cleared:bool):
	return is_cleared

func _ready() -> void:
	var clear_array = []
	for s in stages:
		clear_array.append(s.cleared)
	if clear_array.all(check):
		monitoring = true
		show()
	else:
		monitoring = false
		hide()

func _on_body_entered(body: Node3D) -> void:
	Global.go_to_stage(boss_stage)
