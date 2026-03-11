extends Node2D

var frame_count = 0
func _ready() -> void:
	print("Empty ready. Waiting for idle frame...")
	# 1フレームだけ待ってから遷移を実行させる
	await get_tree().process_frame
	print("Idle frame passed. Changing scene now...")
	
	if Global.next_scene == "":
		printerr("Error: Global.next_scene is EMPTY!")
		return
	"""
	var err = get_tree().change_scene_to_file(Global.next_scene)
	if err != OK:
		printerr("Scene change error: ", err)
	"""

"""
func _process(delta: float) -> void:
	print("processing")
	frame_count += 1
	if frame_count % 10 == 0:
		print("Frame: ", frame_count)
	if frame_count == 30:
		get_tree().call_deferred("change_scene_to_file", Global.next_scene)
"""
