extends CharacterBody3D
class_name AdventurePatrolNPC

enum State { IDLE, WALK, RUN }

@export var walk_speed: float = 2.0
@export var run_speed: float = 4.0
@export var allow_running: bool = false
@export var run_distance_threshold: float = 10.0
@export var arrival_distance: float = 0.8
@export var idle_wait_time: float = 1.4
@export var address_player_min_time: float = 2.0
@export var address_player_max_time: float = 3.0
@export var gravity: float = 20.0
@export var turn_speed: float = 8.0
@export var skin_pivot_path: NodePath = ^"SkinPivot"
@export var animator_path: NodePath = ^"Animator"
@export var patrol_points_parent_path: NodePath

@onready var skin_pivot: Node3D = get_node_or_null(skin_pivot_path) as Node3D
@onready var animator: HumanoidLocomotionAnimator = get_node_or_null(animator_path) as HumanoidLocomotionAnimator
@onready var patrol_parent: Node = get_node_or_null(patrol_points_parent_path)

var _state: State = State.IDLE
var _patrol_points: Array[Node3D] = []
var _patrol_index: int = 0
var _wait_timer: float = 0.0
var _last_facing: Vector3 = Vector3.FORWARD
var _address_target: Node3D = null
var _address_timer: float = 0.0


func _ready() -> void:
	add_to_group(&"npc")
	collision_layer = AdventureLayers.NPC
	collision_mask = AdventureLayers.NPC_MASK
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(45.0)
	_collect_patrol_points()
	_set_state(State.IDLE)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if _patrol_points.is_empty():
		_update_addressing(delta)
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * delta)
		move_and_slide()
		_orient_visual(delta)
		_update_anim()
		return

	match _state:
		State.IDLE:
			_update_addressing(delta)
			_wait_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, walk_speed * delta)
			velocity.z = move_toward(velocity.z, 0.0, walk_speed * delta)
			if _address_timer <= 0.0 and _wait_timer <= 0.0:
				_patrol_index = (_patrol_index + 1) % _patrol_points.size()
				_set_state(_travel_state_to_current_target())
		State.WALK, State.RUN:
			_move_to_patrol(delta)

	move_and_slide()
	_orient_visual(delta)
	_update_anim()


func on_interacted_by(by: Node) -> void:
	var minimum_time := minf(address_player_min_time, address_player_max_time)
	var maximum_time := maxf(address_player_min_time, address_player_max_time)
	pause_for_interaction(by, randf_range(minimum_time, maximum_time))


func pause_for_interaction(by: Node, duration: float = 2.5) -> void:
	_address_target = by as Node3D
	_address_timer = maxf(duration, 0.0)
	_set_state(State.IDLE)
	_wait_timer = maxf(_wait_timer, _address_timer)
	velocity.x = 0.0
	velocity.z = 0.0
	_face_address_target()


func is_addressing_player() -> bool:
	return _address_timer > 0.0


func get_address_pause_remaining() -> float:
	return _address_timer


func get_current_state() -> int:
	return int(_state)


func get_current_facing() -> Vector3:
	return _last_facing


func _collect_patrol_points() -> void:
	_patrol_points.clear()
	if patrol_parent == null:
		return
	for child in patrol_parent.get_children():
		if child is Node3D:
			_patrol_points.append(child)


func _move_to_patrol(delta: float) -> void:
	var target := _patrol_points[_patrol_index]
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length() <= arrival_distance:
		_set_state(State.IDLE)
		return

	var direction := offset.normalized()
	_last_facing = direction
	var speed := run_speed if _state == State.RUN else walk_speed
	velocity.x = move_toward(velocity.x, direction.x * speed, speed * 4.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, speed * 4.0 * delta)


func _travel_state_to_current_target() -> State:
	if _patrol_points.is_empty():
		return State.IDLE
	if not allow_running:
		return State.WALK
	var distance := global_position.distance_to(_patrol_points[_patrol_index].global_position)
	return State.RUN if distance >= run_distance_threshold else State.WALK


func _set_state(next_state: State) -> void:
	if _state == next_state:
		return
	_state = next_state
	if _state == State.IDLE:
		_wait_timer = idle_wait_time


func _update_addressing(delta: float) -> void:
	if _address_timer <= 0.0:
		return
	_face_address_target()
	_address_timer = maxf(_address_timer - delta, 0.0)
	if _address_timer <= 0.0:
		_address_target = null


func _face_address_target() -> void:
	if _address_target == null or not is_instance_valid(_address_target):
		_address_target = null
		return
	var offset := _address_target.global_position - global_position
	offset.y = 0.0
	if offset.length_squared() > 0.001:
		_last_facing = offset.normalized()


func _orient_visual(delta: float) -> void:
	if skin_pivot == null or _last_facing.length_squared() < 0.001:
		return
	var target_basis := Basis.looking_at(_last_facing.normalized(), Vector3.UP)
	var current := skin_pivot.global_transform.basis.get_rotation_quaternion()
	var goal := target_basis.get_rotation_quaternion()
	var t := 1.0 - exp(-turn_speed * delta)
	var skin_transform := skin_pivot.global_transform
	skin_transform.basis = Basis(current.slerp(goal, t))
	skin_pivot.global_transform = skin_transform


func _update_anim() -> void:
	if animator == null:
		return
	var horizontal_speed := Vector3(velocity.x, 0.0, velocity.z).length()
	animator.set_locomotion(horizontal_speed, _state == State.RUN, is_on_floor(), velocity.y)
