extends Node
var next_scene : String

func go_to_stage(to_stage:String):
	for t in get_tree().get_processed_tweens():
	# とりあえずTweenが働いているところを全てkill
		t.kill()
	get_tree().call_deferred("change_scene_to_file", to_stage)
