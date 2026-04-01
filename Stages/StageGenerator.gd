extends Node3D

# GridMap ベースの自動配置ジェネレータ（Godot 4）
# 使い方:
#  - このスクリプトを Node3D にアタッチしてシーンを実行。
#  - Inspector で gridmap_path を指定し、mesh_item_* を設定してから Generate を押すか自動実行する。
# 注意:
#  - mesh_item_* は使用している GridMap.mesh_library のアイテムインデックス（整数）を入れてください。
#  - GridMap のセルサイズに合わせて位置が丸められます。

@export var seed: int = 0
@export var platform_count: int = 80
@export var vertical_spacing_cells: int = 1   # GridMap のセル単位での縦間隔
@export var horizontal_range_cells: int = 6   # 左右に何セル分までランダムに広げるか
@export var forward_step_cells_min: int = 2
@export var forward_step_cells_max: int = 4

@export var gridmap_path: NodePath = NodePath("StageMap")  # シーンの GridMap を指定
@export var mesh_item_platform: int = 0
@export var mesh_item_fruit: int = -1    # -1 = 無効
@export var mesh_item_enemy_bee: int = -1
@export var mesh_item_enemy_crab: int = -1
@export var mesh_item_bouncer: int = -1
@export var mesh_item_trap: int = -1

@export var place_fruit_chance: float = 0.5
@export var place_enemy_chance: float = 0.22
@export var place_bouncer_chance: float = 0.09
@export var place_trap_chance: float = 0.08

@export var auto_generate_on_ready: bool = true

@onready var rng := RandomNumberGenerator.new()
@onready var gridmap: GridMap = null

func _ready() -> void:
	if seed == 0:
		seed = int(Time.get_ticks_msec())
	rng.seed = seed

	gridmap = get_node_or_null(gridmap_path)
	if not gridmap:
		push_error("LevelGeneratorGridMap: gridmap_path is not set or node not found: %s" % gridmap_path)
		return

	# 一回だけ: GridMap に紐付く MeshLibrary の中身を出力（どのアイテムが何番か確認したい時のみ）
	print_mesh_library_items()

	if auto_generate_on_ready:
		generate_level_gridmap()

func print_mesh_library_items() -> void:
	var lib := gridmap.mesh_library
	if not lib:
		push_warning("LevelGeneratorGridMap: GridMap has no mesh_library assigned.")
		return
	# Godot 4 MeshLibrary API: get_item_count(), get_item_name(index)
	var count := 0
	if lib.has_method("get_item_count"):
		count = lib.get_item_count()
	else:
		# 万一 API が違えば try 抜ける
		push_warning("LevelGeneratorGridMap: mesh_library does not expose get_item_count().")
		return
	print("=== MeshLibrary items (index : name) ===")
	for i in range(count):
		var name := ""
		if lib.has_method("get_item_name"):
			name = lib.get_item_name(i)
		else:
			name = str(i)
		print("%d : %s" % [i, name])
	print("=== end ===")

func clear_generated() -> void:
	# GridMap のセルをクリアする簡易的なクリア
	if gridmap:
		if gridmap.has_method("clear"):
			gridmap.clear()
		else:
			# 手動で範囲をクリア（保険）
			var r := 64
			for x in range(-r, r):
				for y in range(-r, r):
					for z in range(-r, r):
						if gridmap.get_cell_item(Vector3i(x,y,z)) != -1:
							gridmap.set_cell_item(Vector3i(x,y,z), -1)

func generate_level_gridmap() -> void:
	if not gridmap:
		push_error("LevelGeneratorGridMap: no gridmap to generate into.")
		return

	clear_generated()

	# GridMap ローカル座標変換の準備
	var cell_size := gridmap.cell_size
	if cell_size == Vector3.ZERO:
		cell_size = Vector3(2.0, 4.0, 2.0) # デフォルト推定

	var cur_cell := Vector3i(0, 0, 0)   # x, y, z セル座標（y が高さ）
	var forward_z := 0  # z 軸方向へ負方向に進める想定（GridMap の向きに合わせてお使いください）

	for i in range(platform_count):
		# 横方向にランダム移動（セル単位）
		var dx := rng.randi_range(-horizontal_range_cells, horizontal_range_cells)
		cur_cell.x = dx

		# 上昇 (セル単位)
		cur_cell.y = i * vertical_spacing_cells

		# 前進（奥行き = z）
		var step := rng.randi_range(forward_step_cells_min, forward_step_cells_max)
		forward_z -= step
		cur_cell.z = forward_z

		# プラットフォームを配置
		if mesh_item_platform >= 0:
			gridmap.set_cell_item(Vector3i(cur_cell.x, cur_cell.y, cur_cell.z), mesh_item_platform)

		# フルーツ配置
		if mesh_item_fruit >= 0 and rng.randf() < place_fruit_chance:
			# フルーツはプラットフォームの上に置くので y+1
			gridmap.set_cell_item(Vector3i(cur_cell.x, cur_cell.y + 1, cur_cell.z), mesh_item_fruit)
		# 敵配置（Bee/Crab のどちらか）
		if rng.randf() < place_enemy_chance:
			if rng.randf() < 0.65 and mesh_item_enemy_bee >= 0:
				gridmap.set_cell_item(Vector3i(cur_cell.x + rng.randi_range(-1,1), cur_cell.y + 1, cur_cell.z), mesh_item_enemy_bee)
			elif mesh_item_enemy_crab >= 0:
				gridmap.set_cell_item(Vector3i(cur_cell.x + rng.randi_range(-1,1), cur_cell.y, cur_cell.z), mesh_item_enemy_crab)

		# バウンサー
		if mesh_item_bouncer >= 0 and rng.randf() < place_bouncer_chance:
			gridmap.set_cell_item(Vector3i(cur_cell.x + rng.randi_range(-1,1), cur_cell.y + 1, cur_cell.z), mesh_item_bouncer)

		# トラップ（床や回転系など別アイテム）
		if mesh_item_trap >= 0 and rng.randf() < place_trap_chance:
			gridmap.set_cell_item(Vector3i(cur_cell.x + rng.randi_range(-2,2), cur_cell.y, cur_cell.z), mesh_item_trap)

	# タワー（ゴール）を最上段の少し先に配置する例（MeshLibrary にタワーアイテムがあればそのインデックスを入れてください）
	# 例: var tower_item_index := 10 ; if tower_item_index >= 0: gridmap.set_cell_item(0, platform_count * vertical_spacing_cells + 2, forward_z - 5, tower_item_index)

	print("LevelGeneratorGridMap: generation complete (seed=%d)" % seed)

# 外部から再生成したい場合に呼べる関数
func regen(new_seed: int = 0) -> void:
	if new_seed != 0:
		seed = new_seed
	rng.seed = seed
	generate_level_gridmap()
	print("LevelGeneratorGridMap: regenerated with seed %d" % seed)
