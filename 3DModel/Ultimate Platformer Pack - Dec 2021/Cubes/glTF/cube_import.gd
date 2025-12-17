@tool
extends EditorScenePostImport


# Called by the editor when a scene has this script set as the import script in the import tab.
func _post_import(scene: Node) -> Object:
	if not scene:
		push_error("not scene.")
	# Modify the contents of the scene upon import.
	var static_body3d = StaticBody3D.new()
	var collision : CollisionShape3D = CollisionShape3D.new()
	var box_shape_3d = BoxShape3D.new()
	box_shape_3d.size = Vector3(2,2,2)
	collision.shape = box_shape_3d
	static_body3d.add_child(collision)
	var is_mesh = scene.get_child(0)
	if is_mesh is MeshInstance3D:
		is_mesh.add_child(static_body3d)
	static_body3d.set_owner(scene)
	collision.set_owner(scene)
	return scene # Return the modified root node when you're done.
