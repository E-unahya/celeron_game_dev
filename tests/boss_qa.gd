## Headless regression test for the Boss base class and Boss1 state flow.
## Run with: godot --headless --path . -s res://tests/boss_qa.gd
extends SceneTree

const BOSS_1_SCENE := preload("res://Boss/boss_1_body.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var arena := Node3D.new()
	root.add_child(arena)

	var player := CharacterBody3D.new()
	player.name = "Player"
	arena.add_child(player)
	player.global_position = Vector3(0.0, 4.0, -12.0)

	var boss := BOSS_1_SCENE.instantiate() as CharacterBody3D
	boss.idle_duration = 1.0
	boss.charge_duration = 3.0
	boss.invincibility_time = 0.05
	boss.recovery_duration = 0.05
	arena.add_child(boss)

	# No "Entrance scene" exists in boss_1_body.tscn: AI must start without waiting.
	await process_frame
	await physics_frame
	_expect(boss.current_health == boss.max_health, "Boss base _ready() did not initialize HP.")
	_expect(boss.state == boss.State.IDLE, "AI did not enter IDLE when Entrance scene is absent.")

	# IDLE must capture a fixed target and transition to CHARGE.
	boss.idle_duration = 0.05
	await _wait_physics_frames(4)
	_expect(boss.state == boss.State.CHARGE, "Boss did not transition IDLE -> CHARGE.")
	_expect(not boss.charge_direction.is_zero_approx(), "CHARGE did not capture a target direction.")
	var speed_before_slide := Vector2(boss.velocity.x, boss.velocity.z).length()
	boss._change_state(boss.State.RECOVERY)
	await physics_frame
	var speed_after_slide := Vector2(boss.velocity.x, boss.velocity.z).length()
	_expect(speed_after_slide > 0.0 and speed_after_slide < speed_before_slide, "Recovery did not apply gradual slide friction.")

	# A head stomp outside STUN must not damage the boss.
	boss._change_state(boss.State.IDLE)
	player.velocity.y = -1.0
	player.global_position = boss.get_node("WeakArea").global_position
	boss._on_weak_area_body_entered(player)
	_expect(boss.current_health == boss.max_health, "Boss took stomp damage outside STUN.")

	# A descending stomp in STUN must damage exactly once and enable invincibility.
	boss._change_state(boss.State.STUN)
	boss._on_weak_area_body_entered(player)
	_expect(boss.current_health == boss.max_health - 1, "STUN head stomp did not reduce HP by one.")
	_expect(boss.is_invincible, "Damage did not start invincibility.")
	boss._on_weak_area_body_entered(player)
	_expect(boss.current_health == boss.max_health - 1, "Invincibility did not block repeated stomp damage.")

	# Damage waits for invincibility, then returns through RECOVERY to IDLE.
	await _wait_physics_frames(12)
	_expect(not boss.is_invincible, "Invincibility timer did not end.")
	await _wait_physics_frames(20)
	_expect(boss.state == boss.State.IDLE or boss.state == boss.State.CHARGE, "Boss did not recover back to the AI loop.")

	# A physics wall collision during CHARGE must put a separate boss into STUN.
	player.global_position = Vector3(10.0, 4.0, -12.0)
	var wall := StaticBody3D.new()
	wall.collision_layer = 8 # Project layer 4: Wall Floor.
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(8.0, 20.0, 1.0)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	arena.add_child(wall)
	wall.global_position = Vector3(10.0, 0.0, -4.0)

	var wall_boss := BOSS_1_SCENE.instantiate()
	wall_boss.idle_duration = 0.05
	wall_boss.charge_duration = 3.0
	arena.add_child(wall_boss)
	wall_boss.global_position = Vector3(10.0, 0.0, 0.0)
	await process_frame
	await _wait_physics_frames(40)
	_expect(wall_boss.state == wall_boss.State.STUN, "Wall collision did not transition CHARGE -> STUN.")

	if failures.is_empty():
		print("BOSS_QA_PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _wait_physics_frames(frame_count: int) -> void:
	for frame_index: int in frame_count:
		await physics_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
