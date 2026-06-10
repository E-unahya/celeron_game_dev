extends Area3D

signal got_it

@onready var collition_3d = $CollisionShape3D 


func _ready() -> void:
	visible = false


func _on_body_entered(body: Node3D) -> void:
	# Body は前提としてプレイヤーである。
	got_it.emit()
	visible = false


func _on_visibility_changed() -> void:
	if visible:
		collition_3d.disabled = false
	else:
		collition_3d.disabled = true


func _on_stage_ui_all_box_breaked() -> void:
	visible = true
