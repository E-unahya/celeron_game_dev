@tool
extends EditorScenePostImport

# Called by the editor when a scene has this script set as the import script in the import tab.
func _post_import(scene: Node) -> Object:
	# 実装ボール投げ実装
	var ball = MeshInstance3D.new()
	var ball_area = Area3D.new()
	var ball_collision = CollisionShape3D.new()
	ball_collision.shape = SphereShape3D.new()
	ball_area.add_child(ball_collision)
	ball.mesh = preload("res://3DModel/Ultimate Monsters/Big/tscn/ball_mesh.tres")
	ball.add_child(ball_area)
	ball.set_owner(scene)
	ball_area.set_owner(scene)
	ball_collision.set_owner(scene)
	scene.add_child(ball)

	var weak_area = Area3D.new()
	return scene
