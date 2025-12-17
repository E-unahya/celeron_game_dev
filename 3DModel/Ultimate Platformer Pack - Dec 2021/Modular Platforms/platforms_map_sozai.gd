@tool
extends Node3D

## 複数ファイルを指定したい。
@export_file_path("*.gltf") var gltf_file : Array[String]

##
@export_tool_button("ボタンを押すとインポートされるよ") var fukusuu_add_child = super_add_child

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func super_add_child():
	pass
