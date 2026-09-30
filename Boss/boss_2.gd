## 2面ボス: 隠れて雑魚を召喚し、全滅後だけ姿を現して銃撃するボスです。
extends "res://Boss/boss.gd"

const BIRB_SCENE: PackedScene = preload("res://3DModel/Ultimate Monsters/Big/tscn/birb.tscn")
const ORC_SCENE: PackedScene = preload("res://3DModel/Ultimate Monsters/Big/tscn/orc.tscn")

enum State {
	SPAWN_PHASE,
	APPEAR_PHASE,
	ATTACK_PHASE,
	DAMAGE,
	KNOCKOUT,
}

## SpawnPoints は Boss2 の子に Node3D として複数置き、この配列に登録します。
## 未設定時は spawn_radius を使い、ボスの周囲に自動配置します。
@export_category("Target and Spawn Points")
@export var player_path: NodePath = NodePath("../Player")
@export var spawn_points: Array[NodePath] = []
@export var spawn_radius: float = 7.0

@export_category("Minion Phase")
@export var minion_spawn_interval: float = 1.0
@export var max_health_minion_count: int = 5
@export var two_health_minion_count: int = 10
@export var one_health_minion_count: int = 20

@export_category("Appear and Attack Phase")
@export var appear_duration: float = 0.4
@export var attack_duration: float = 10.0
@export var shot_interval: float = 1.5
@export var bullet_speed: float = 16.0
@export var bullet_lifetime: float = 4.0

var state: State = State.SPAWN_PHASE
var state_time: float = 0.0
var _spawn_elapsed: float = 0.0
var _shot_elapsed: float = 0.0
var _minions_to_spawn: int = 0
var _minions_spawned: int = 0
var _next_minion_is_birb: bool = true
var player: Node3D
# 敵は配列で管理される。それ自体はいいかも、Node3Dの子ノードよりメモリに優しいから
var active_minions: Array[Node3D] = []
var active_bullets: Array[Bullet] = []

@onready var weak_area: Area3D = get_node_or_null("WeakArea") as Area3D
@onready var weak_collision: CollisionShape3D = get_node_or_null("WeakArea/CollisionShape3D") as CollisionShape3D

# ボスのライフ関係
@onready var boss_life: Control = get_node_or_null("BossLife") as Control
@onready var boss_life_container: HBoxContainer = get_node_or_null("BossLife/BossLifeContainer") as HBoxContainer

# アニメーション関係
@onready var animation_player : AnimationPlayer = get_node("AnimationPlayer")

## 動的に作る簡易弾です。Area3D のため、MeshInstance3D だけより衝突処理を明確に保てます。
class Bullet extends Area3D:
	var direction: Vector3 = Vector3.FORWARD
	var speed: float = 16.0
	var lifetime: float = 4.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1 # Player レイヤー
		monitoring = true
		monitorable = false
		body_entered.connect(_on_body_entered)

		var mesh_instance := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3(0.35, 0.35, 0.35)
		mesh_instance.mesh = box_mesh
		add_child(mesh_instance)

		var collision := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(0.35, 0.35, 0.35)
		collision.shape = box_shape
		add_child(collision)

	func _physics_process(delta: float) -> void:
		global_position += direction * speed * delta
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()

	func _on_body_entered(body: Node3D) -> void:
		if body.has_method("take_damage"):
			body.call("take_damage", 1)
		elif body is Player:
			# 現行 Player は take_damage() を持たないため、既存の死亡 API を使う。
			body.die()
		queue_free()


func _ready() -> void:
	super._ready()
	_set_boss_collision_active(false)
	_set_weak_point_active(false)
	player = get_node_or_null(player_path) as Node3D
	if player is Player:
		var spin_area := player.get_node_or_null("SpinArea") as Area3D
		if spin_area != null and not spin_area.body_entered.is_connected(_on_spin_area_body_entered):
			spin_area.body_entered.connect(_on_spin_area_body_entered)
	# TODO　ボスのライフポイント関係の共通メソッド化
	if boss_life_container != null:
		for l in max_health:
			var t = TextureRect.new()
			t.texture = load("res://Boss/boss_life_kakkokari.tres")
			boss_life_container.add_child(t)


func _setup_ai() -> void:
	player = get_node_or_null(player_path) as Node3D
	if player == null:
		push_warning("Boss2 could not find a player at %s." % player_path)
	_change_state(State.SPAWN_PHASE)


func _process_ai(delta: float) -> void:
	state_time += delta
	_prune_minions()
	_prune_bullets()

	match state:
		State.SPAWN_PHASE:
			# 本体 CollisionShape を切っている間も Base が重力を適用するため、
			# 地面をすり抜けないようこのフェーズでは垂直移動を止める。
			velocity.y = 0.0
			_process_spawn_phase(delta)
		State.APPEAR_PHASE:
			if state_time >= appear_duration:
				_change_state(State.ATTACK_PHASE)
		State.ATTACK_PHASE:
			_process_attack_phase(delta)
		State.KNOCKOUT:
			pass


func _process_spawn_phase(delta: float) -> void:
	if _minions_spawned < _minions_to_spawn:
		_spawn_elapsed += delta
		if _spawn_elapsed >= minion_spawn_interval:
			_spawn_elapsed = 0.0
			_spawn_minion()
		return

	# 生成済みの全員が tree_exiis_empty()ted した後にのみ姿を現す。
	# 何故か空中に敵が2匹飛んでることがあるので2匹飛ばす。
	# TOOD どうやって残りの敵を引きずり下ろすか
	if len(active_minions) <= 0:
		_change_state(State.APPEAR_PHASE)


func _process_attack_phase(delta: float) -> void:
	_shot_elapsed += delta
	if _shot_elapsed >= shot_interval:
		_shot_elapsed = 0.0
		_fire_bullet_at_player()

	if state_time >= attack_duration:
		_clear_bullets()
		_change_state(State.SPAWN_PHASE)


func _change_state(next_state: State) -> void:
	if state == next_state and next_state != State.SPAWN_PHASE:
		return

	state = next_state
	state_time = 0.0
	match state:
		State.SPAWN_PHASE:
			hide()
			_set_boss_collision_active(false)
			_set_weak_point_active(false)
			_clear_bullets()
			_minions_to_spawn = _get_minion_count_for_health()
			_minions_spawned = 0
			_spawn_elapsed = minion_spawn_interval # フェーズ開始時の一体目は即時生成。
			_next_minion_is_birb = true
		State.APPEAR_PHASE:
			show()
			_set_boss_collision_active(true)
			_set_weak_point_active(false)
		State.ATTACK_PHASE:
			_set_weak_point_active(true)
			_shot_elapsed = shot_interval # 登場直後の一発目は即時発射。
		State.DAMAGE:
			animation_player.play("Damage")
		State.KNOCKOUT:
			_set_boss_collision_active(false)
			_set_weak_point_active(false)
			animation_player.play("KnockOut")


func _get_minion_count_for_health() -> int:
	if current_health <= 1:
		return one_health_minion_count
	if current_health == 2:
		return two_health_minion_count
	return max_health_minion_count


func _spawn_minion() -> void:
	var minion_scene: PackedScene = BIRB_SCENE if _next_minion_is_birb else ORC_SCENE
	_next_minion_is_birb = not _next_minion_is_birb
	var minion := minion_scene.instantiate() as Node3D
	if minion == null:
		push_error("Boss2 failed to instantiate a minion.")
		return

	var parent_node: Node = get_tree().current_scene if get_tree().current_scene != null else get_parent()
	if parent_node == null:
		return
	minion.target = parent_node.get_node("Player")
	parent_node.add_child(minion)
	minion.global_position = _get_next_spawn_position()
	active_minions.append(minion)
	minion.visibility_changed.connect(_on_minion_tree_exited.bind(minion), CONNECT_ONE_SHOT)
	_minions_spawned += 1


func _get_next_spawn_position() -> Vector3:
	if not spawn_points.is_empty():
		var point_index: int = _minions_spawned % spawn_points.size()
		var point := get_node_or_null(spawn_points[point_index]) as Node3D
		if point != null:
			return point.global_position
	var angle: float = TAU * float(_minions_spawned) / float(maxi(_minions_to_spawn, 1))
	return global_position + Vector3(cos(angle), -0.5, sin(angle)) * spawn_radius


func _on_minion_tree_exited(minion: Node3D) -> void:
	if minion.visible:
		return
	else:
		active_minions.erase(minion)


func _prune_minions() -> void:
	for index: int in range(active_minions.size() - 1, -1, -1):
		if not active_minions[index].visible:
			active_minions.remove_at(index)


func _fire_bullet_at_player() -> void:
	if player == null or not is_instance_valid(player):
		player = get_node_or_null(player_path) as Node3D
	if player == null:
		return

	var direction := player.global_position - global_position
	direction.y = 0.0
	if direction.is_zero_approx():
		direction = -global_transform.basis.z
	var bullet := Bullet.new()
	bullet.direction = direction.normalized()
	bullet.speed = bullet_speed
	bullet.lifetime = bullet_lifetime
	bullet.global_position = global_position + Vector3.UP * randf_range(-0.5, 1.5) + bullet.direction * 1.2
	var parent_node: Node = get_tree().current_scene if get_tree().current_scene != null else get_parent()
	if parent_node == null:
		bullet.queue_free()
		return
	parent_node.add_child(bullet)
	active_bullets.append(bullet)


func _clear_bullets() -> void:
	for bullet: Bullet in active_bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	active_bullets.clear()


func _prune_bullets() -> void:
	for index: int in range(active_bullets.size() - 1, -1, -1):
		if not is_instance_valid(active_bullets[index]):
			active_bullets.remove_at(index)


## CollisionShape3D と Area3D を子孫まで切り替えます。隠蔽中は本体も弱点も無敵です。
func _set_boss_collision_active(active: bool) -> void:
	for collision: CollisionShape3D in find_children("*", "CollisionShape3D", true, false):
		collision.set_deferred("disabled", not active)
	for area: Area3D in find_children("*", "Area3D", true, false):
		area.set_deferred("monitoring", active)


func _set_weak_point_active(active: bool) -> void:
	if weak_collision != null:
		weak_collision.set_deferred("disabled", not active)
	if weak_area != null:
		weak_area.set_deferred("monitoring", active)


## ATTACK_PHASE だけ踏みつけを受け付けます。WeakArea の body_entered に接続します。
func _can_receive_stomp_damage() -> bool:
	return not is_dead and not is_invincible and state == State.ATTACK_PHASE


func _on_weak_area_body_entered(body: Node3D) -> void:
	if not _can_receive_stomp_damage():
		return
	var weak_position: Vector3 = weak_area.global_position if weak_area != null else global_position
	handle_head_area_entered(body, weak_position)


func _on_take_damage() -> void:
	_set_weak_point_active(false)
	_clear_bullets()


func _on_died() -> void:
	_clear_bullets()
	_change_state(State.KNOCKOUT)


## boss_1_body.tscn から引き継ぐ既存シグナルの互換ハンドラです。
func _on_jump_area_body_entered(body: Node3D) -> void:
	if state != State.SPAWN_PHASE:
		handle_front_area_entered(body)


## Player の SpinArea (Area3D) が本体 CharacterBody3D に入った時だけ被弾する。
func _on_spin_area_body_entered(body: Node3D) -> void:
	if body != self or not visible:
		return
	_change_state(State.DAMAGE)
	take_damage()


func _on_wall_detector_body_entered(_body: Node3D) -> void:
	pass


## Boss01.tscn / boss_1_body.tscn の health_changed シグナルから接続されます。
func _on_health_changed(new_health: int) -> void:
	if new_health == 0:
		# ここにライフがゼロになったときのアニメーションを再生したい。
		_change_state(State.KNOCKOUT)
	if boss_life_container != null:
		var children := boss_life_container.get_children()
		for i in range(children.size()):
			if children[i] is CanvasItem:
				(children[i] as CanvasItem).visible = (i < new_health)


func _on_stun_started() -> void:
	pass


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Damage":
			if current_health > 0:
				_change_state(State.SPAWN_PHASE)
			animation_player.play("RESET")
