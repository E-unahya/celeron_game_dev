@tool
extends EditorScenePostImport


# Called by the editor when a scene has this script set as the import script in the import tab.
func _post_import(scene: Node) -> Object:
	if not scene:
		push_error("not scene.")
	# Modify the contents of the scene upon import.
	var is_mesh = scene.get_child(0)
	if is_mesh is MeshInstance3D:
		is_mesh.create_convex_collision()
	return scene # Return the modified root node when you're done.
