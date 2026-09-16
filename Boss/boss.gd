## すべての3Dボスが継承する共通クラスです。
## boss_2.gd などでは _setup_ai(), _process_ai(delta), _on_take_damage() を
## オーバーライドして、HPや登場演出の実装を重複させずにAIだけを差し替えます。
class_name Boss
extends CharacterBody3D

signal health_changed(change_health: int)
signal invincibility_started
signal invincibility_ended
signal died
## 正面接触などでプレイヤー側のダメージ処理を起動するための接点です。
signal player_hit(player: Node3D)

@export_category("Health")
@export var max_health: int = 3
@export var invincibility_time: float = 2.0

@export_category("Weak Point")
## 頭部Area3Dに入ったプレイヤーを踏みつけと判定する高さの許容値です。
@export var stomp_height_tolerance: float = 1.5
## この値以下（通常は落下中）のY速度で頭部に入った場合だけ踏みつけです。
@export var stomp_max_vertical_velocity: float = 0.0

const ENTRANCE_ANIMATION: StringName = &"Entrance scene"

var current_health: int = 0
var is_invincible: bool = false
var is_dead: bool = false

var _ai_active: bool = false
var _invincibility_timer: Timer
var _animation_player: AnimationPlayer


func _ready() -> void:
	current_health = max(max_health, 1)
	_invincibility_timer = Timer.new()
	_invincibility_timer.one_shot = true
	add_child(_invincibility_timer)
	_invincibility_timer.timeout.connect(_end_invincibility)

	# プレイヤーがボスを通り抜けず壁のように衝突するようLayer 4(Wall Floor)をレイヤーに付与
	# 一方でボス自身がプレイヤーから押されないよう自身のマスクからはPlayer(Layer 1)を除外
	set_collision_layer_value(3, true) # Layer 3: Enemy Weak
	set_collision_layer_value(4, true) # Layer 4: Wall Floor (プレイヤーの衝突対象)
	set_collision_mask_value(1, false) # Layer 1: Player (プレイヤーに押されないよう除外)
	set_collision_mask_value(4, true)  # Layer 4: Wall Floor (壁・床とのみ衝突)
	floor_stop_on_slope = true

	# 子階層を検索するので、AnimationPlayer の配置は自由です。
	_animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	_start_battle()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_apply_gravity(delta)
	if _ai_active:
		_process_ai(delta)

	var is_moving_horizontally: bool = not (is_zero_approx(velocity.x) and is_zero_approx(velocity.z))
	var prev_horizontal_pos := Vector2(global_position.x, global_position.z)

	move_and_slide()

	# AIが自発的に水平移動していない時は、外部からの力や接触による水平ズレを完全に無効化
	if not is_moving_horizontally:
		global_position.x = prev_horizontal_pos.x
		global_position.z = prev_horizontal_pos.y


## 攻撃を受けた側から呼び出します。通常は引数なしで1ダメージです。
func take_damage(amount: int = 1) -> void:
	if is_dead or is_invincible or amount <= 0:
		return

	_begin_invincibility()
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health)
	_on_take_damage()

	if current_health == 0:
		die()
		return


## 死亡演出やドロップは派生クラスの _on_died() で追加できます。
func die() -> void:
	if is_dead:
		return

	is_dead = true
	_ai_active = false
	velocity = Vector3.ZERO
	_invincibility_timer.stop()
	is_invincible = false
	_on_died()
	died.emit()


## --- 派生ボス用フック ---------------------------------------------------
## boss_2.gd / boss_3.gd では、主に以下の3つをオーバーライドしてください。

## 登場演出が終わった直後に一度だけ呼ばれます。初期ステートを設定します。
func _setup_ai() -> void:
	pass


## AIが有効な間、physics frame ごとに呼ばれます。移動量は velocity に設定します。
func _process_ai(_delta: float) -> void:
	pass


## 有効なダメージを受けた直後に呼ばれます。被弾演出・フェーズ変更に使います。
func _on_take_damage() -> void:
	pass


## die() 内で died シグナルを発火する直前に呼ばれます。死亡演出などに使います。
func _on_died() -> void:
	pass


## 頭部用Area3Dの body_entered から呼びます。
## 派生クラスは _can_receive_stomp_damage() をオーバーライドして、
## 「STUN中だけ有効」のような弱点公開条件を実装します。
func handle_head_area_entered(body: Node3D, head_position: Vector3) -> void:
	if _is_player_stomping(body, head_position) and _can_receive_stomp_damage():
		_on_successful_stomp(body)
		take_damage()
		return

	_on_player_front_collision(body)


## 胴体・正面用Area3Dの body_entered から呼びます。
func handle_front_area_entered(body: Node3D) -> void:
	_on_player_front_collision(body)


## 派生クラスで、弱点を開いているステートだけ true を返します。
func _can_receive_stomp_damage() -> bool:
	return false


## 踏みつけ成功時の跳ね返りやSEを派生クラスで実装します。
func _on_successful_stomp(_player: Node3D) -> void:
	pass


## 正面衝突時のプレイヤー被弾処理を派生クラスまたは外部シグナルで実装します。
func _on_player_front_collision(player: Node3D) -> void:
	if player is Player:
		player_hit.emit(player)


func _is_player_stomping(body: Node3D, head_position: Vector3) -> bool:
	if not body is CharacterBody3D:
		return false
	else:
		return true

	"""
	return body.velocity.y <= stomp_max_vertical_velocity \
		and body.global_position.y >= head_position.y - stomp_height_tolerance
	"""

func _start_battle() -> void:
	if _animation_player != null and _animation_player.has_animation(ENTRANCE_ANIMATION):
		_animation_player.play(ENTRANCE_ANIMATION)
		var finished_animation: StringName = await _animation_player.animation_finished
		if finished_animation != ENTRANCE_ANIMATION or is_dead:
			return

	_ai_active = true
	_setup_ai()


func _begin_invincibility() -> void:
	is_invincible = true
	invincibility_started.emit()
	_invincibility_timer.start(maxf(invincibility_time, 0.0))


func _end_invincibility() -> void:
	if not is_invincible:
		return
	is_invincible = false
	invincibility_ended.emit()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
