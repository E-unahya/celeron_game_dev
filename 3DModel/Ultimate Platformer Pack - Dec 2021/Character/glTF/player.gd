extends CharacterBody3D

class_name Player

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 12.0

@export var accel: float = 15.0  # 加速の鋭さ
@export var friction: float = 10.0 # 摩擦（止まりやすさ）
@export var fall_gravity_mult : float = 0.04 # どれくらい早く落ちるのか
@export var low_jump_mult : float = 0.02 # ジャンプボタンをHanasitaTokiniGensokusuru

## 攻撃中です
@export var attack_now : bool = false

## 所持しているフルーツの数、後々、cfgファイルに読み込む
@export_range(0, 100, 1.0) var fruits_counter : int = 0

## クラッシュ的にダイヤとかのポジションにするべきか？コインを

## トラップのマップ
@export var trap_map : GridMap

## プレイヤーのアニメーションツリー
@onready var animation_player : AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var animation_tree = get_node("AnimationTree")
var state_machine : AnimationNodeStateMachinePlayback

@onready var character_armature : Node3D = get_node_or_null("CharacterArmature")

## The RayCast is Judge shadow position
@onready var shadow_ray_cast_3d: RayCast3D = $ShadowRayCast3D
@onready var shadow_mesh: MeshInstance3D = $ShadowMesh

@onready var spin_area: Area3D = $SpinArea

var rotation_speed : float = 5.0

var target_rotation : float = 0.0

var coyote_time : float = 0.15
var coyote_time_counter : float = 0.0

var is_dead : bool = false

# ダメージを受けたときの管理、ハザード編
enum Hazard {
	NONE = -1,
	CYLINDER = 0,
	SAW = 1,
	SPIKE_TRAP = 2
}

func _ready() -> void:
	animation_tree.active = true
	state_machine = animation_tree.get("parameters/playback")
	state_machine.travel("IdleAndRun")

func _physics_process(delta: float) -> void:
	var current_gravity = get_gravity() * 2.5
	if not is_on_floor():
		if velocity.y < 3:
			# 1. 落下中は重力を強くして「キレ」を出す
			current_gravity *= fall_gravity_mult
		elif velocity.y > -3:
			if not Input.is_action_pressed("jump"):
				# 2. 上昇中にボタンを離すと、急ブレーキをかけて低ジャンプにする
				current_gravity.y *= low_jump_mult
		else:
			current_gravity = get_gravity() * delta
		coyote_time_counter -= delta
		velocity += current_gravity
	else:
		coyote_time_counter = coyote_time

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and ( is_on_floor() or coyote_time_counter > 0.0):
		velocity.y = JUMP_VELOCITY
		coyote_time_counter = 0.0

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	# 回転の際に反応するためにわざとif文を分ける
	if direction.length() > 0:
		# 目標地点 = 自分の現在地 + 進みたい方向
		var look_target = character_armature.global_position + direction
		
		# その方向を向かせる（一瞬で向く）
		character_armature.look_at(look_target, Vector3.UP)
	if direction:
		velocity.x = lerp(velocity.x ,direction.x * SPEED, accel * delta)
		velocity.z = lerp(velocity.z, direction.z * SPEED, accel * delta)
		# rotateさせるのどうすればいい？
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)
	# ここからトラップに落ちたらの処理
	var cell_pos = trap_map.local_to_map(global_position)
# 罠用GridMapからその場所のタイルIDを取得
	var trap_id = trap_map.get_cell_item(cell_pos)
	
	# Check Shadow Position
	if shadow_ray_cast_3d.is_colliding():
		shadow_mesh.show()
		var shadow_mesh_position : Vector3
		if velocity.y < 0:
			shadow_mesh_position = shadow_ray_cast_3d.get_collision_point() + Vector3(0, 0.3, 0)
		else:
			shadow_mesh_position = shadow_ray_cast_3d.get_collision_point() + Vector3(0, 0.05, 0)
		shadow_mesh.global_position = shadow_mesh_position

	# タイルIDに応じて処理を分岐 (例: ID 0=トゲ, ID 1=炎)
	match trap_id:
		Hazard.NONE:
			pass # 何もない(空)
		_:
			apply_Hazard(trap_id)
	move_and_slide()


func _process(delta: float) -> void:
	# あるきのアニメーションを実装するためにこのようにしている
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	if not is_on_floor():
		state_machine.travel("JumpStateMachine")
	else:
		state_machine.travel("IdleAndRun")

	if velocity.length() > 0.1:
		animation_tree.set("parameters/IdleAndRun/IdleAndRun/blend_amount", direction.length())
	if Input.is_action_just_pressed("spin_attack"):
		state_machine.travel("SpinAttack")

	if is_dead:
		state_machine.travel("Death")
	if state_machine.get_current_node() == "SpinAttack":
		attack_now = true
	else:
		attack_now = false


func _on_rakka_area_body_entered(body: Node3D) -> void:
	if body is Player:
		# TODO ここで落下音がピューってなってそれが終わったらリロードの処理を行う
		get_tree().reload_current_scene()

func apply_Hazard(trap_id : int):
	match trap_id:
		Hazard.CYLINDER:
			die()
		Hazard.SAW:
			die()
		Hazard.SPIKE_TRAP:
			if is_on_floor():
				die()

func bounce():
	velocity.y = JUMP_VELOCITY


func die():
	# 4んだときのアニメーションを再生
	is_dead = true
	set_physics_process(false)
	set_process(false)
