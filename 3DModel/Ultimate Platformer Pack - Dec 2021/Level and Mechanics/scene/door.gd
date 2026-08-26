extends Area3D

class_name Door

@onready var door: MeshInstance3D = $Door
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var stage_name_label: Label = $Control/StageNameLabel

@export_file("*.tscn") var to_stage
@export var stage_name : String = "Stage Name."

@export var cleared : bool

func _ready() -> void:
	door.rotation = Vector3.ZERO
	var id = ResourceUID.text_to_id(to_stage)
	var true_path = ResourceUID.get_id_path(id)
	cleared = Global.check_clear_stage("1", true_path)
	stage_name_label.hide()
	if cleared:
		stage_name_label.text = stage_name + "(CLEARED)"
		$Star_Outline.show()
	else:
		stage_name_label.text = stage_name
		$Star_Outline.hide()

func _on_body_entered(body: Node3D) -> void:
	animation_player.play("Door")
	stage_name_label.show()

func _on_body_exited(body: Node3D) -> void:
	animation_player.play_backwards("Door")
	stage_name_label.hide()

func _on_goto_stage_body_entered(body: Node3D) -> void:
	if body is Player:
		Global.go_to_stage(to_stage)
