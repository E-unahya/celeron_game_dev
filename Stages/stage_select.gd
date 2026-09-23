extends Node3D
@onready var camera_3d: Camera3D = $Camera3D
@onready var player: Player = $Player
@onready var doors = [$Door, $Door2, $Door3, $Door4]
## 試験段階用のデバッグ
@onready var label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_camera_rotation()
	label.text = self.scene_file_path

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_camera_rotation()


func _update_camera_rotation() -> void:
	var target_position := player.global_position
	target_position.y = camera_3d.global_position.y
	camera_3d.look_at(target_position, Vector3.UP)
