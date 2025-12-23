extends CharacterBody3D


@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

## 所持しているフルーツの数、後々、cfgファイルに読み込む
@export_range(0, 100, 1.0) var fruits_counter : int = 0

## クラッシュ的にダイヤとかのポジションにするべきか？コインを

## トラップのマップ
@export var trap_map : GridMap

@onready var kaiten_you := get_node("KaitenYou")

# ダメージを受けたときの管理、ハザード編
enum Hazard {
	NONE = -1,
	CYLINDER = 0,
	SAW = 1,
	SPIKE_TRAP = 2
}

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		# rotateさせるのどうすればいい？
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	# ここからトラップに落ちたらの処理
	var cell_pos = trap_map.local_to_map(global_position)
# 罠用GridMapからその場所のタイルIDを取得
	var trap_id = trap_map.get_cell_item(cell_pos)
	
	# タイルIDに応じて処理を分岐 (例: ID 0=トゲ, ID 1=炎)
	match trap_id:
		Hazard.NONE:
			pass # 何もない(空)
		_:
			apply_Hazard(trap_id)
	move_and_slide()


func _on_rakka_area_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		# TODO ここで落下音がピューってなってそれが終わったらリロードの処理を行う
		get_tree().reload_current_scene()

func apply_Hazard(trap_id : int):
	match trap_id:
		Hazard.CYLINDER:
			print("シリンダーに打たれた")
		Hazard.SAW:
			print("丸鋸怖い")
		Hazard.SPIKE_TRAP:
			if is_on_floor():
				print("足痛い")
