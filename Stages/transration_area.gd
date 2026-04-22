extends Area3D

@export_file("*.tscn") var stage_path

func _ready() -> void:
	body_entered.connect(owner._on_transration_area_body_entered.bind(stage_path))
