# SceneLoader.gd (Autoload推奨)
extends Node

var loading_path : String = ""

func load_scene_async(path: String) -> void:
	loading_path = path
	ResourceLoader.load_threaded_request(path)
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _process(_delta):
	if loading_path == "":
		return
	var status = ResourceLoader.load_threaded_get_status(loading_path)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var packed_scene = ResourceLoader.load_threaded_get(loading_path)
			loading_path = ""
			get_tree().change_scene_to_packed(packed_scene)
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Scene load failed: " + loading_path)
			loading_path = ""
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass # ここでプログレスバー更新も可能
