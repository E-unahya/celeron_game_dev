# Boss implementation guidelines

## Scope

This project uses Godot 4 and GDScript. Keep boss-related scripts under
`res://Boss/`.

## Class structure

- `res://Boss/boss.gd` is the shared `Boss` base class and extends
  `CharacterBody3D`.
- Individual bosses inherit it, for example:
  `extends "res://Boss/boss.gd"` in `res://Boss/boss_1.gd`.
- Add future bosses as `boss_2.gd`, `boss_3.gd`, and so on. Do not duplicate
  common HP, invincibility, entrance, or death logic in derived classes.

## Base boss contract

`Boss` owns the common combat lifecycle:

- HP is configured with `@export var max_health: int = 3`.
- Call `take_damage()` for a normal single-hit attack. It decreases HP by one.
- `is_invincible` prevents repeated damage during the exported
  `invincibility_time` window.
- The base class emits `health_changed`, `invincibility_started`,
  `invincibility_ended`, and `died`.
- Call `die()` rather than manually emitting `died`.
- Never start AI movement or attacks before the optional `"Entrance scene"`
  animation finishes. If there is no `AnimationPlayer` or no such animation,
  begin AI immediately.

## Extending a boss AI

Derived classes should use an enum and a clear state-transition method for
their behavior. Override these hooks instead of overriding the base lifecycle:

- `_setup_ai() -> void`: initialize the first state after entrance completes.
- `_process_ai(delta: float) -> void`: update state and set horizontal
  `velocity`; the base class applies gravity and calls `move_and_slide()`.
- `_on_take_damage() -> void`: add hurt feedback or phase transitions after a
  valid hit.
- `_on_died() -> void`: add death animation, drops, or cleanup before the
  `died` signal is emitted.

`boss_1.gd` is the reference pattern:
`IDLE -> CHARGE -> STUN -> DAMAGE -> RECOVERY`. It locks the target position
before charging, exposes its weak point only in `STUN`, and uses friction for
the post-charge slide.
Put per-boss timing, speed, range, and target paths in typed exported
properties so they remain editable in the Inspector.

## Scene integration

- Keep an `AnimationPlayer` named `AnimationPlayer` anywhere under the boss
  node when an entrance animation is required.
- Name the entrance animation exactly `Entrance scene`.
- Route a head-area callback to `handle_head_area_entered(body, head_position)`
  and a front-area callback to `handle_front_area_entered(body)`. Override
  `_can_receive_stomp_damage()` to control when a stomp can call
  `take_damage()`; do not edit `current_health` directly.
- Keep `Boss01.tscn` signal callbacks compatible with the methods in
  `boss_1.gd` when editing its collision areas.

## Code style and validation

- Use Godot 4 GDScript with explicit argument and return types.
- Prefer `get_node_or_null()` for optional scene dependencies and handle a
  missing target safely.
- Preserve unrelated scene and script changes.
- After boss changes, validate loading with:

  ```bash
  godot --headless --path . --editor --quit
  ```
