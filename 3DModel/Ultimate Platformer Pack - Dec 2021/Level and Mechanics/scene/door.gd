extends Area3D

@onready var door: MeshInstance3D = $Door
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export_file("*.tscn") var to_stage

func _ready() -> void:
	door.rotation = Vector3.ZERO

func _on_body_entered(body: Node3D) -> void:
	animation_player.play("Door")

func _on_body_exited(body: Node3D) -> void:
	animation_player.play_backwards("Door")

func _on_goto_stage_body_entered(body: Node3D) -> void:
	Global.go_to_stage(to_stage)
