extends Node
var next_scene : String

func go_to_stage(to_stage:String):
	for t in get_tree().get_processed_tweens():
	# とりあえずTweenが働いているところを全てkill
		t.kill()
	load_scene_async(to_stage)

# score等のセーブするデータはどこでもいじれると良いので、ここに一連の処理を作成する
func stage_clear(save_data_name : String, stage_name : String, score:int):
	"""
	ステージをクリアーしたら呼ぶメソッド、とりあえずこれにステージのデータを書き込む
	"""
	var config_file = ConfigFile.new() 
	config_file.set_value(save_data_name, "stage_name", stage_name)
	config_file.set_value(save_data_name, stage_name+"_score", score)
	config_file.set_value(save_data_name, stage_name+"_cleared", true)
	config_file.save("user://stage_clear.cfg")


var loading_path : String = ""

func load_scene_async(path: String) -> void:
	loading_path = path
	ResourceLoader.load_threaded_request(path)
	get_tree().change_scene_to_file("res://Stages/loading_scene.tscn")

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
