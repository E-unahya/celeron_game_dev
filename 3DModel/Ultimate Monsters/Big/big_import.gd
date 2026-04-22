@tool
extends EditorScenePostImport

# Called by the editor when a scene has this script set as the import script in the import tab.
func _post_import(scene: Node) -> Object:
	scene.set_script(load("res://3DModel/Ultimate Monsters/Big/tscn/big.gd"))
	scene.set("collision_mask", 33)
	scene.set("enemy_type", 3)

	var collision_shape = CollisionShape3D.new()
	collision_shape.position = Vector3(0, 1, 0)
	var collision_shape_data = CylinderShape3D.new()
	collision_shape_data.radius = 1.0
	collision_shape.shape = collision_shape_data

	# 実装ボール投げ実装
	var ball = MeshInstance3D.new()
	ball.name = "ball"
	ball.position = Vector3(0.7, 1.6, 1.0)
	var ball_area = Area3D.new()
	ball_area.name = "Area3D"
	ball_area.collision_layer = 2
	ball_area.collision_mask = 33
	var ball_collision = CollisionShape3D.new()
	ball_collision.name = "BallCollision"
	ball_collision.shape = SphereShape3D.new()
	ball_collision.shape.radius = 0.3
	ball_collision.disabled = true
	ball_area.add_child(ball_collision)
	ball.mesh = preload("res://3DModel/Ultimate Monsters/Big/tscn/ball_mesh.tres")
	ball.add_child(ball_area)

	var weak_area = Area3D.new()
	weak_area.name = "WeakArea"
	var weak_collision = CollisionShape3D.new()
	weak_collision.position = Vector3(0, 2.326, 0)
	var weak_shape = CylinderShape3D.new()
	weak_shape.height = 1.284
	weak_shape.radius = 1.12
	weak_collision.shape = weak_shape
	weak_area.add_child(weak_collision)

	var static_body = StaticBody3D.new()
	static_body.name = "StaticBody3D"
	static_body.collision_layer = 16
	static_body.collision_mask = 0
	var static_collision = CollisionShape3D.new()
	static_collision.position = Vector3(0, 1.0436584, 0)
	var static_shape = CylinderShape3D.new()
	static_shape.height = 0.49726564
	static_shape.radius = 0.7036133
	static_collision.shape = static_shape
	static_body.add_child(static_collision)

	scene.add_child(collision_shape)
	scene.add_child(weak_area)
	scene.add_child(ball)
	scene.add_child(static_body)

	collision_shape.set_owner(scene)
	weak_area.set_owner(scene)
	weak_collision.set_owner(scene)
	ball.set_owner(scene)
	ball_area.set_owner(scene)
	ball_collision.set_owner(scene)
	static_body.set_owner(scene)
	static_collision.set_owner(scene)
	return scene
