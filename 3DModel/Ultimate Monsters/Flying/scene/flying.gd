extends Enemy

class_name FlyingEnemy

var tween: Tween

@export var move_axis: Vector3 = Vector3.UP
@export var move_distance: float = 2.0
@export var move_time: float = 1.5
@export var start_delay: float = 0.0
@export var ease: Tween.EaseType = Tween.EASE_IN_OUT
@export var transition: Tween.TransitionType = Tween.TRANS_SINE

func _ready() -> void:
	enemy_type = EnemyType.FLYING
	super._ready()
	if start_delay > 0.0:
		await get_tree().create_timer(start_delay).timeout
	start_hover()

func start_hover() -> void:
	if tween:
		tween.kill()
	var axis := move_axis
	if axis.is_zero_approx():
		axis = Vector3.UP
	tween = get_tree().create_tween()
	tween.set_loops()
	tween.set_ease(ease)
	tween.set_trans(transition)
	tween.tween_property(self, "position", home_pos + axis.normalized() * move_distance, move_time)
	tween.tween_property(self, "position", home_pos, move_time)

func _on_animation_player_animation_started(anim_name: StringName) -> void:
	match anim_name:
		"Death":
			super._on_animation_player_animation_started(anim_name)
			if tween:
				tween.kill()
