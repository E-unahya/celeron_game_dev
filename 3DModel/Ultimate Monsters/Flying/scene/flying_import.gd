@tool
extends EditorScenePostImport


func _post_import(scene: Node) -> Object:
	var animation_player := scene.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		return scene

	for library_name in animation_player.get_animation_library_list():
		var library := animation_player.get_animation_library(library_name)
		if library == null:
			continue
		if library.has_animation("Flying"):
			var flying_animation := library.get_animation("Flying")
			if flying_animation:
				flying_animation.loop_mode = Animation.LOOP_LINEAR
		if library.has_animation("Dance"):
			var dance_animation := library.get_animation("Dance")
			if dance_animation:
				dance_animation.loop_mode = Animation.LOOP_LINEAR

	return scene
