extends CharacterBody3D


## 通常敵の speed = 5.0 より十分速い、突進時の移動速度。
@export var charge_speed: float = 15.0
## 突進前にその場で狙いを定める時間。
@export var charge_time: float = 1.0
## 一度の突進を続ける時間。
@export var charge_duration: float = 0.8
## 突進終了後に残る滑走の開始速度。
@export var slide_speed: float = 7.5
## 滑走を続ける最大時間。
@export var slide_duration: float = 0.35
## 滑走中の減速量。大きいほど早く止まる。
@export var slide_deceleration: float = 20.0
## 壁に当たったときに跳ね返る速度。
@export var wall_bounce_speed: float = 8.0
## 跳ね返り移動を続ける時間。
@export var wall_bounce_duration: float = 0.2
## 壁衝突後、次のチャージに入るまで動けない時間。
@export var wall_stun_time: float = 3.0

@onready var player: Node3D = get_node_or_null("../Player") as Node3D

enum State {
	CHARGING,
	CHARGING_FORWARD,
	SLIDING,
	BOUNCING,
	STUNNED,
}

var state: State = State.CHARGING
var state_time: float = 0.0
var charge_direction: Vector3 = Vector3.ZERO
var current_slide_speed: float = 0.0


func _ready() -> void:
	if player == null:
		push_error("Boss1 could not find Player at ../Player.")
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	var was_charging_forward := state == State.CHARGING_FORWARD or state == State.SLIDING

	match state:
		State.CHARGING:
			velocity.x = 0.0
			velocity.z = 0.0
			state_time += delta
			if state_time >= charge_time:
				_begin_charge()
		State.CHARGING_FORWARD:
			velocity.x = charge_direction.x * charge_speed
			velocity.z = charge_direction.z * charge_speed
			state_time += delta
			if state_time >= charge_duration:
				_begin_slide()
		State.SLIDING:
			velocity.x = charge_direction.x * current_slide_speed
			velocity.z = charge_direction.z * current_slide_speed
			current_slide_speed = move_toward(current_slide_speed, 0.0, slide_deceleration * delta)
			state_time += delta
			if state_time >= slide_duration or is_zero_approx(current_slide_speed):
				_end_charge()
		State.BOUNCING:
			velocity.x = charge_direction.x * wall_bounce_speed
			velocity.z = charge_direction.z * wall_bounce_speed
			state_time += delta
			if state_time >= wall_bounce_duration:
				_begin_stun()
		State.STUNNED:
			velocity.x = 0.0
			velocity.z = 0.0
			state_time += delta
			if state_time >= wall_stun_time:
				_end_charge()

	move_and_slide()
	if was_charging_forward:
		_bounce_if_hit_wall()


func _begin_charge() -> void:
	# チャージ完了時の主人公の位置だけを使い、突進中は追尾しない。
	charge_direction = player.global_position - global_position
	charge_direction.y = 0.0

	if charge_direction.is_zero_approx():
		state_time = 0.0
		return

	charge_direction = charge_direction.normalized()
	look_at(global_position + charge_direction, Vector3.UP)
	state = State.CHARGING_FORWARD
	state_time = 0.0


func _begin_slide() -> void:
	current_slide_speed = slide_speed
	state = State.SLIDING
	state_time = 0.0


func _end_charge() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	state = State.CHARGING
	state_time = 0.0


func _bounce_if_hit_wall() -> void:
	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		var normal := collision.get_normal()
		var collider := collision.get_collider()
		# 床・天井と主人公への接触は、壁衝突として扱わない。
		if abs(normal.y) >= 0.5 or collider == player:
			continue

		charge_direction = charge_direction.bounce(normal)
		charge_direction.y = 0.0
		if charge_direction.is_zero_approx():
			return

		charge_direction = charge_direction.normalized()
		look_at(global_position + charge_direction, Vector3.UP)
		state = State.BOUNCING
		state_time = 0.0
		return


func _begin_stun() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	state = State.STUNNED
	state_time = 0.0


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity += get_gravity() * delta


func _on_jump_area_body_entered(body: Node3D) -> void:
	# 前提としてプレイヤーしか侵入不可
	if not body.is_on_floor() :
		if Input.is_action_pressed("ui_accept"):
			body.bounce(1.5)
		else:
			body.bounce()


func _on_weak_area_body_entered(body: Node3D) -> void:
	print("ダメージをうけた。")
	body.bounce()
