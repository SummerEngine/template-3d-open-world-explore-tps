extends Node
class_name HumanoidLocomotionAnimator

@export var animation_player_path: NodePath
@export_file("*.fbx") var idle_fbx: String = ""
@export_file("*.fbx") var walk_fbx: String = ""
@export_file("*.fbx") var run_fbx: String = ""
@export_file("*.fbx") var jump_fbx: String = ""
@export_file("*.fbx") var fall_fbx: String = ""
@export_file("*.fbx") var land_fbx: String = ""
@export_file("*.fbx") var long_idle_fbx: String = ""
@export var library_name: StringName = &"adventure_locomotion"
@export var idle_animation: StringName = &"Idle"
@export var walk_animation: StringName = &"Walk"
@export var run_animation: StringName = &"Run"
@export var jump_animation: StringName = &"Jump"
@export var fall_animation: StringName = &"Fall"
@export var land_animation: StringName = &"Land"
@export var long_idle_animation: StringName = &"LongIdle"
@export var long_idle_delay: float = 10.0
@export var still_idle_track_name_filters: PackedStringArray = PackedStringArray(["head", "neck"])
@export var walk_speed_threshold: float = 0.25
@export var run_speed_threshold: float = 4.8
@export var landing_vertical_speed_threshold: float = -3.0
@export var land_hold_time: float = 0.35
@export var root_motion_track_path: String = ""
@export var root_motion_track_name_hint: String = "Hips"
@export var strip_horizontal_root_motion: bool = true
@export var normalize_low_root_y: bool = true
@export var root_y_drop_tolerance: float = 0.18

@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path) as AnimationPlayer

var _current: StringName = &""
var _root_y_reference: float = NAN
var _was_on_floor: bool = true
var _last_vertical_velocity: float = 0.0
var _land_timer: float = 0.0
var _idle_timer: float = 0.0


func _ready() -> void:
	if animation_player == null:
		push_warning("HumanoidLocomotionAnimator has no AnimationPlayer.")
		return
	_root_y_reference = NAN
	_import_configured_clips()
	_play(idle_animation)


func set_locomotion(horizontal_speed: float, sprinting: bool, on_floor: bool = true, vertical_velocity: float = 0.0, delta: float = 0.0) -> void:
	if animation_player == null:
		return

	var step_delta := delta if delta > 0.0 else 1.0 / float(Engine.physics_ticks_per_second)
	var landed := on_floor and not _was_on_floor
	if landed and _last_vertical_velocity <= landing_vertical_speed_threshold and _has_anim(land_animation):
		_idle_timer = 0.0
		_land_timer = land_hold_time
		_play(land_animation)

	_was_on_floor = on_floor
	_last_vertical_velocity = vertical_velocity

	if _land_timer > 0.0:
		_land_timer = maxf(_land_timer - step_delta, 0.0)
		return

	if not on_floor:
		_idle_timer = 0.0
		if vertical_velocity > 0.1 and _has_anim(jump_animation):
			_play(jump_animation)
		elif _has_anim(fall_animation):
			_play(fall_animation)
		else:
			_play(run_animation if _has_anim(run_animation) else idle_animation)
		return

	if horizontal_speed <= walk_speed_threshold:
		_idle_timer += step_delta
		if _idle_timer >= long_idle_delay and _has_anim(long_idle_animation):
			_play(long_idle_animation)
		else:
			_play(idle_animation)
	elif sprinting or horizontal_speed >= run_speed_threshold or not _has_anim(walk_animation):
		_idle_timer = 0.0
		_play(run_animation if _has_anim(run_animation) else idle_animation)
	else:
		_idle_timer = 0.0
		_play(walk_animation)


func _import_configured_clips() -> void:
	var lib := AnimationLibrary.new()
	_add_clip(lib, idle_fbx, idle_animation, true, true)
	_add_clip(lib, walk_fbx, walk_animation, true)
	_add_clip(lib, run_fbx, run_animation, true)
	_add_clip(lib, jump_fbx, jump_animation, false)
	_add_clip(lib, fall_fbx, fall_animation, true)
	_add_clip(lib, land_fbx, land_animation, false)
	var effective_long_idle_fbx := long_idle_fbx if not long_idle_fbx.is_empty() else idle_fbx
	if long_idle_animation != idle_animation:
		_add_clip(lib, effective_long_idle_fbx, long_idle_animation, true)

	if lib.get_animation_list().is_empty():
		return

	if animation_player.has_animation_library(library_name):
		animation_player.remove_animation_library(library_name)
	animation_player.add_animation_library(library_name, lib)


func _add_clip(lib: AnimationLibrary, fbx_path: String, target_name: StringName, loop_clip: bool, still_head_tracks: bool = false) -> void:
	if fbx_path.is_empty():
		return
	if not ResourceLoader.exists(fbx_path):
		push_warning("Missing animation FBX: %s" % fbx_path)
		return

	var scene := load(fbx_path) as PackedScene
	if scene == null:
		push_warning("Could not load animation FBX: %s" % fbx_path)
		return

	var inst := scene.instantiate()
	var source_player := inst.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if source_player == null or source_player.get_animation_list().is_empty():
		push_warning("No AnimationPlayer found in %s" % fbx_path)
		inst.free()
		return

	var source_name := source_player.get_animation_list()[0]
	var anim := source_player.get_animation(source_name)
	if anim != null:
		var copy := anim.duplicate()
		if loop_clip:
			copy.loop_mode = Animation.LOOP_LINEAR
		_sanitize_root_motion(copy)
		if still_head_tracks:
			_freeze_named_tracks(copy, still_idle_track_name_filters)
		lib.add_animation(target_name, copy)

	inst.free()


func _sanitize_root_motion(anim: Animation) -> void:
	for track_index in range(anim.get_track_count()):
		if not _is_root_motion_track(anim, track_index):
			continue
		var key_count := anim.track_get_key_count(track_index)
		if key_count < 2:
			return
		var first_value: Variant = anim.track_get_key_value(track_index, 0)
		if not (first_value is Vector3):
			return
		var first_position := first_value as Vector3
		if is_nan(_root_y_reference):
			_root_y_reference = first_position.y

		var y_offset := 0.0
		if normalize_low_root_y and first_position.y < _root_y_reference - root_y_drop_tolerance:
			y_offset = _root_y_reference - first_position.y

		for key_index in range(key_count):
			var value: Variant = anim.track_get_key_value(track_index, key_index)
			if value is Vector3:
				var position := value as Vector3
				if strip_horizontal_root_motion:
					position.x = first_position.x
					position.z = first_position.z
				if y_offset != 0.0:
					position.y += y_offset
				anim.track_set_key_value(track_index, key_index, position)
		return


func _is_root_motion_track(anim: Animation, track_index: int) -> bool:
	var track_path := str(anim.track_get_path(track_index))
	if not root_motion_track_path.is_empty():
		return track_path == root_motion_track_path
	if root_motion_track_name_hint.is_empty():
		return false
	if not track_path.to_lower().contains(root_motion_track_name_hint.to_lower()):
		return false
	if anim.track_get_key_count(track_index) == 0:
		return false
	return anim.track_get_key_value(track_index, 0) is Vector3


func _play(anim_name: StringName) -> void:
	if anim_name == StringName() or _current == anim_name:
		return

	var library_anim := "%s/%s" % [String(library_name), String(anim_name)]
	if animation_player.has_animation(library_anim):
		animation_player.play(library_anim, 0.12)
		_current = anim_name
	elif animation_player.has_animation(anim_name):
		animation_player.play(anim_name, 0.12)
		_current = anim_name


func _freeze_named_tracks(anim: Animation, name_filters: PackedStringArray) -> void:
	if name_filters.is_empty():
		return

	for track_index in range(anim.get_track_count()):
		var track_path := str(anim.track_get_path(track_index)).to_lower()
		var should_freeze := false
		for name_filter in name_filters:
			if not name_filter.is_empty() and track_path.contains(name_filter.to_lower()):
				should_freeze = true
				break
		if not should_freeze:
			continue

		var key_count := anim.track_get_key_count(track_index)
		if key_count < 2:
			continue

		var first_value: Variant = anim.track_get_key_value(track_index, 0)
		for key_index in range(1, key_count):
			anim.track_set_key_value(track_index, key_index, first_value)


func _has_anim(anim_name: StringName) -> bool:
	if anim_name == StringName() or animation_player == null:
		return false
	return animation_player.has_animation("%s/%s" % [String(library_name), String(anim_name)]) or animation_player.has_animation(anim_name)
