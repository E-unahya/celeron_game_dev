@tool
extends EditorScenePostImport


# Called by the editor when a scene has this script set as the import script in the import tab.
func _post_import(scene: Node) -> Object:
	var animation_player := scene.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		return scene

	for library_name in animation_player.get_animation_library_list():
		var library := animation_player.get_animation_library(library_name)
		if library == null or not library.has_animation("Dance"):
			continue

		var wave_animation := library.get_animation("Dance")
		if wave_animation:
			wave_animation.loop_mode = Animation.LOOP_LINEAR

	return scene
