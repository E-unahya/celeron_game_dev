extends Area3D

@onready var bomb: MeshInstance3D = $Bomb
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		# プレイヤーが４んでやり直しになる。
		# とりあえず後回しで再読み込みとする。
		# 本体には隠れてもらってからの
		bomb.hide()
		animated_sprite_3d.play("BombOrange")
