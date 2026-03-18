extends Node3D

@onready var enemies : Node = get_node("Enemies")
@onready var attack_se : AudioStreamPlayer = get_node("AttackSE")
@onready var jump_bounce_se : AudioStreamPlayer = get_node("JumpBounceSE")
@onready var box_break_se : AudioStreamPlayer = get_node("BoxBreakSE")
@onready var player : Player = get_node("Player")
@onready var boxs: Node = $Boxs
@onready var box_break_particle: GPUParticles3D = $BoxBreakParticle
@onready var fruits: Node = $fruits
@onready var stage_ui: StageUI = $StageUI

var se_pitch_limit : int = 0

func _ready():
	PhysicsServer3D.set_active(true)
	var box_counter :int = 0
	# 敵がArea3Dになってること前提
	for e : Enemy in enemies.get_children():
		e.area_entered.connect(_on_enemy_area_entered)
		e.weak_area.body_entered.connect(_on_enemy_weak_area_entered)
	# 箱ノード関係で破壊されたときの動作を行う。
	for b : Box in boxs.get_children():
		b.breaked.connect(_on_box_breaked)
		box_counter += 1
	for f in fruits.get_children():
		f.fruit_get.connect(_on_fruits_get)
	stage_ui.set_score(0)
	stage_ui.set_box_label(box_counter)

func _physics_process(delta: float) -> void:
	if player.is_on_floor(): 
		jump_bounce_se.pitch_scale = 1.0

func _on_enemy_area_entered(area: Area3D) -> void:
	if area.get_collision_layer_value(6) or area.get_collision_layer_value(2):
		attack_se.play()
		stage_ui.set_score(5000)

func _on_enemy_weak_area_entered(body : CharacterBody3D) -> void:
	if body is Player:
		jump_bounce_se.play()
		var score : int = 1000
		if !body.is_on_floor() and se_pitch_limit < 18:
			jump_bounce_se.pitch_scale += 0.1
			se_pitch_limit += 1
			stage_ui.set_score(score)
			score += score

func _on_rakka_area_area_entered(area: Area3D) -> void:
	if area is Enemy:
		area.position = area.home_pos

func _on_box_breaked(box_pos:Vector3) -> void:
	box_break_se.play()
	box_break_particle.global_position = box_pos
	box_break_particle.emitting = true
	stage_ui.set_box_label()


func _on_fruits_get() -> void:
	$FruitsGetSE.play()
	print("Fruits get.")

func _on_tower_animation_finished(anim_name : String):
	if anim_name == "GOAL":
		# プレイしてくれてありがとうのシーンを出す。
		set_physics_process(false)
		player.set_physics_process(false)
		for t in get_tree().get_processed_tweens():
		# とりあえずTweenが働いているところを全てkill
			t.kill()
		get_tree().call_deferred("change_scene_to_file", "uid://dupjvv3trnpvk")


func _on_player_dead() -> void:
	for t in get_tree().get_processed_tweens():
		# とりあえずTweenが働いているところを全てkill
		t.kill()
	# 敵が投げる球等はTweenなのでそれをkillする
	PhysicsServer3D.set_active(false)
	"""
	for e in enemies.get_children():
		if is_instance_valid(e):
			e.set_process(false)
			e.set_physics_process(false)
			e.set_script(null)
			await get_tree().process_frame
	set_physics_process(false)
	set_process(false)
	await get_tree().process_frame
	for i in get_children():
		i.queue_free()
	"""
	var global = get_node("/root/Global")

	if global:
		global.next_scene = self.scene_file_path
	else:
		push_error("Global_not_found.")
	get_tree().call_deferred("change_scene_to_file", "res://Empty.tscn")
