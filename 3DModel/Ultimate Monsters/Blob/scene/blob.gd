extends Enemy

var tween : Tween

## delay 少し待ってからぴょんって飛ぶ
@export var delay : bool = false
## Tweeのeraseとtransをいじれるようにしたい。
@export var ease : Tween.EaseType = Tween.EASE_IN_OUT
@export var transition : Tween.TransitionType = Tween.TRANS_BACK

func _ready() -> void:
	super._ready()
	if delay:
		await get_tree().create_timer(2.0).timeout
	tween_generate()


func tween_generate() -> void:
	tween = get_tree().create_tween()
	tween.set_loops()
	tween.set_ease(ease)
	tween.set_trans(transition)
	tween.tween_property(self, "position", home_pos + Vector3.UP * 5, 2.0)
	tween.tween_property(self, "position", home_pos, 2.0)


func _on_animation_player_animation_started(anim_name: StringName) -> void:
	match anim_name:
		"Death":
			super._on_animation_player_animation_started(anim_name)
			if tween:
				tween.kill()
