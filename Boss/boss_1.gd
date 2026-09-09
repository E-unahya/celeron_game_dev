## クラッシュ・バンディクー風の「壁にぶつけて頭を踏む」ボスの実装例です。
extends "res://Boss/boss.gd"

## 壁激突SE・よろけアニメーションをシーン側から接続できます。
signal stun_started

@export_category("Target")
@export var player_path: NodePath = NodePath("../Player")

@export_category("Boss 1 Charge AI")
@export var idle_duration: float = 1.5
@export var charge_speed: float = 15.0
@export var charge_acceleration: float = 60.0
@export var charge_duration: float = 0.8
## CHARGE終了後に速度を落とす量。小さいほど長く滑ります。
@export var slide_friction: float = 12.0
@export var stun_duration: float = 3.0
@export var recovery_duration: float = 0.5
@export var turn_speed: float = 10.0

@export_category("Stun Rebound")
## 壁激突時によろけて壁から遠ざかる初速
@export var stun_rebound_speed: float = 5.0
## よろけ後退中の摩擦減速度
@export var stun_friction: float = 10.0

enum State {
	IDLE,
	CHARGE,
	STUN,
	DAMAGE,
	RECOVERY,
}

var state: State = State.IDLE
var state_time: float = 0.0
var player: Node3D
## IDLE終了時の位置を保存するため、突進中はプレイヤーを追尾しません。
var target_position: Vector3 = Vector3.ZERO
var charge_direction: Vector3 = Vector3.ZERO

## 外部参照や被弾ガード（current_state）との互換性を保つためのエイリアス
var current_state: State:
	get:
		return state
	set(value):
		_change_state(value)

@onready var boss_life: Control = get_node_or_null("BossLife") as Control
@onready var boss_life_container: HBoxContainer = get_node_or_null("BossLife/BossLifeContainer") as HBoxContainer
@onready var wall_detector: Node3D = get_node_or_null("WallDetector")
@onready var weak_area: Area3D = get_node_or_null("WeakArea") as Area3D
@onready var weak_collision: CollisionShape3D = get_node_or_null("WeakArea/CollisionShape3D") as CollisionShape3D

func _ready() -> void:
	super._ready()

	# メッシュが未初期化の場合のフォールバック
	var mesh_inst := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst != null and mesh_inst.mesh == null:
		var cap := CapsuleMesh.new()
		cap.radius = 1.0
		cap.height = 7.0
		mesh_inst.mesh = cap

	var hana_inst := get_node_or_null("Hana") as MeshInstance3D
	if hana_inst != null and hana_inst.mesh == null:
		var cap := CapsuleMesh.new()
		cap.radius = 0.5
		cap.height = 2.0
		hana_inst.mesh = cap

	if boss_life_container != null:
		for l in max_health:
			var t = TextureRect.new()
			t.texture = load("res://Boss/boss_life_kakkokari.tres")
			boss_life_container.add_child(t)
	_set_weak_point_active(false)


## 弱点判定のモニタリングとCollisionShape3Dを一括で切り替えます。
func _set_weak_point_active(active: bool) -> void:
	if weak_collision != null:
		weak_collision.set_deferred("disabled", not active)
	if weak_area != null:
		weak_area.set_deferred("monitoring", active)


## Base の登場演出終了後に一度だけ呼ばれます。
func _setup_ai() -> void:
	player = get_node_or_null(player_path) as Node3D
	if player == null:
		push_warning("Boss1 could not find a player at %s." % player_path)
	_change_state(State.IDLE)


## IDLE → CHARGE → (壁なら STUN) → DAMAGE → RECOVERY → IDLE の状態機械です。
func _process_ai(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_apply_horizontal_friction(delta)
		return

	state_time += delta
	match state:
		State.IDLE:
			_apply_horizontal_friction(delta)
			_face_player(delta)
			if state_time >= idle_duration:
				_begin_charge()
		State.CHARGE:
			_process_charge(delta)
		State.STUN:
			_apply_stun_movement(delta)
			if state_time >= stun_duration:
				_change_state(State.RECOVERY)
		State.DAMAGE:
			_stop_horizontal_movement()
			# 被弾無敵が終わってから復帰させ、連続踏みつけを防ぎます。
			if not is_invincible:
				_change_state(State.RECOVERY)
		State.RECOVERY:
			_apply_horizontal_friction(delta)
			if state_time >= recovery_duration and not is_invincible:
				_change_state(State.IDLE)


func _process_charge(delta: float) -> void:
	# WallDetector ノードによる壁接触検知で即座に STUN へ遷移
	if _is_wall_detected():
		_change_state(State.STUN)
		return

	velocity.x = move_toward(velocity.x, charge_direction.x * charge_speed, charge_acceleration * delta)
	velocity.z = move_toward(velocity.z, charge_direction.z * charge_speed, charge_acceleration * delta)
	_face_direction(charge_direction, delta)

	# 到達点で急停止せず、RECOVERY中にslide_frictionで速度を落とします。
	if state_time >= charge_duration:
		_change_state(State.RECOVERY)


## WallDetector（Area3D / RayCast3D / ShapeCast3D）による壁検知判定
func _is_wall_detected() -> bool:
	if wall_detector == null:
		return false

	# Area3D の場合
	if wall_detector is Area3D:
		var area := wall_detector as Area3D
		for body: Node3D in area.get_overlapping_bodies():
			if body != player and body != self:
				return true

	# RayCast3D の場合
	elif wall_detector is RayCast3D:
		var ray := wall_detector as RayCast3D
		if ray.is_colliding():
			var collider := ray.get_collider()
			if collider != player and collider != self:
				return true

	# ShapeCast3D の場合
	elif wall_detector is ShapeCast3D:
		var shapecast := wall_detector as ShapeCast3D
		if shapecast.is_colliding():
			for i: int in shapecast.get_collision_count():
				var collider := shapecast.get_collider(i)
				if collider != player and collider != self:
					return true

	return false


## STUN中の頭部踏みつけだけがダメージになる、ボス1固有の弱点条件です。
func _can_receive_stomp_damage() -> bool:
	return not is_dead and not is_invincible and current_state == State.STUN


func _on_successful_stomp(stomping_player: Node3D) -> void:
	if stomping_player is CharacterBody3D:
		var cb := stomping_player as CharacterBody3D
		var bounce_power: float = 1.2
		if Input.is_action_pressed("ui_accept"):
			bounce_power = 1.5
		if cb.has_method("bounce"):
			cb.bounce(bounce_power)
		var base_jump: float = 12.0
		if "JUMP_VELOCITY" in cb:
			base_jump = float(cb.JUMP_VELOCITY)
		cb.velocity.y = maxf(cb.velocity.y, base_jump * bounce_power)


## Base の take_damage() から呼ばれます。無敵時間中は再度呼ばれません。
func _on_take_damage() -> void:
	_set_weak_point_active(false)
	_change_state(State.RECOVERY)


## 正面からの接触、またはSTUN以外での頭部接触はプレイヤー側の被弾として扱います。
func _on_player_front_collision(colliding_player: Node3D) -> void:
	if colliding_player.has_method("bounce"):
		colliding_player.bounce()
	super._on_player_front_collision(colliding_player)



func _begin_charge() -> void:
	target_position = player.global_position
	charge_direction = target_position - global_position
	charge_direction.y = 0.0
	if charge_direction.is_zero_approx():
		return

	charge_direction = charge_direction.normalized()
	_change_state(State.CHARGE)


func _change_state(next_state: State) -> void:
	state = next_state
	state_time = 0.0
	if state == State.STUN:
		_set_weak_point_active(true)
		_apply_stun_rebound()
	_play_animation()


func _apply_stun_rebound() -> void:
	if not charge_direction.is_zero_approx():
		var rebound_dir := -charge_direction.normalized()
		velocity.x = rebound_dir.x * stun_rebound_speed
		velocity.z = rebound_dir.z * stun_rebound_speed


func _apply_stun_movement(delta: float) -> void:

	velocity.x = move_toward(velocity.x, 0.0, stun_friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, stun_friction * delta)


func _play_animation() -> void:
	var animation_player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	match state:
		State.STUN:
			if animation_player != null and animation_player.has_animation("Stun"):
				animation_player.play("Stun")
			stun_started.emit()
		_:
			if animation_player != null and animation_player.has_animation("RESET"):
				animation_player.play("RESET")


func _play_wait_animation() -> void:
	pass


func _face_player(delta: float) -> void:
	var direction := player.global_position - global_position
	direction.y = 0.0
	if not direction.is_zero_approx():
		_face_direction(direction.normalized(), delta)


func _face_direction(direction: Vector3, delta: float) -> void:
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(turn_speed * delta, 1.0))


func _apply_horizontal_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, slide_friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, slide_friction * delta)


func _stop_horizontal_movement() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


## Boss01.tscn の頭部WeakAreaから接続されます。
func _on_weak_area_body_entered(body: Node3D) -> void:
	# ガード節: 無敵時間中および STUN 以外のステートでは絶対にダメージを受け付けない
	if is_dead or current_state != State.STUN:
		print("is_dead is " % is_dead)
		print("current state is " % current_state)
		return

	# 連続多段ヒット防止のため、即座に弱点判定を無効化
	_set_weak_point_active(false)

	var weak_pos: Vector3 = weak_area.global_position if weak_area != null else global_position
	handle_head_area_entered(body, weak_pos)


## Boss01.tscn の正面JumpAreaから接続されます。
func _on_jump_area_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and current_state == State.STUN:
		var cb := body as CharacterBody3D
		if cb.has_method("bounce"):
			cb.bounce(1.5)
		else:
			cb.velocity.y = 15.0


## Boss01.tscn / boss_1_body.tscn の WallDetector (Area3D) から接続されます。
func _on_wall_detector_body_entered(body: Node3D) -> void:
	if body is GridMap and body.get_collision_layer_value(4):
		_change_state(State.STUN)
	elif body is Player and not velocity.is_zero_approx(): # and 突進中:
		# プレイヤーだった場合、普通にダメージを与えたいがその時は突進してる最中が良い
		# ダメージ受けて即死とか笑えない。
		print("Player has damaged.")


## Boss01.tscn / boss_1_body.tscn の health_changed シグナルから接続されます。
func _on_health_changed(new_health: int) -> void:
	if boss_life_container != null:
		var children := boss_life_container.get_children()
		for i in range(children.size()):
			if children[i] is CanvasItem:
				(children[i] as CanvasItem).visible = (i < new_health)


func _on_stun_started() -> void:
	# 残りどれくらいのライフポイントでランダムに岩を落とすか
	if current_health <= 1:
		for i in range(3):
			var rakka_butu : Node3D = preload("res://3DModel/ohiwa/Ohiwa.tscn").instantiate()
			rakka_butu.global_position = self.global_position + Vector3(randf_range(1,3), randf_range(1,3), randf_range(1,3))
			owner.add_child(rakka_butu)
