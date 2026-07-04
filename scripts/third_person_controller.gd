extends CharacterBody3D
class_name ThirdPersonAdventureController

signal interacted(interactable: Node)

@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.0
@export var jump_velocity: float = 5.0
@export var gravity: float = 20.0
@export var fall_gravity_multiplier: float = 1.35
@export var ground_accel: float = 55.0
@export var ground_friction: float = 65.0
@export var air_accel: float = 18.0
@export var air_friction: float = 3.0
@export var turn_speed: float = 12.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

@export var camera_path: NodePath
@export var input_reader_path: NodePath = ^"../InputReader"
@export var hud_path: NodePath = ^"../HUD"
@export var skin_pivot_path: NodePath = ^"SkinPivot"
@export var animator_path: NodePath = ^"Animator"
@export var interact_sensor_path: NodePath = ^"InteractSensor"

@onready var camera: ThirdPersonAdventureCamera = get_node_or_null(camera_path) as ThirdPersonAdventureCamera
@onready var input_reader := get_node_or_null(input_reader_path)
@onready var hud: AdventureHUD = get_node_or_null(hud_path) as AdventureHUD
@onready var skin_pivot: Node3D = get_node_or_null(skin_pivot_path) as Node3D
@onready var animator: HumanoidLocomotionAnimator = get_node_or_null(animator_path) as HumanoidLocomotionAnimator
@onready var interact_sensor: Area3D = get_node_or_null(interact_sensor_path) as Area3D

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _last_facing: Vector3 = Vector3.FORWARD
var _nearby_interactables: Array[Node] = []


func _ready() -> void:
	add_to_group(&"player")
	collision_layer = AdventureLayers.PLAYER
	collision_mask = AdventureLayers.PLAYER_MASK
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(45.0)

	if input_reader == null:
		push_warning("ThirdPersonAdventureController needs World/InputReader for movement, jump, sprint, and interact input.")

	if interact_sensor != null:
		interact_sensor.collision_layer = 0
		interact_sensor.collision_mask = AdventureLayers.INTERACT_SENSOR_MASK
		interact_sensor.area_entered.connect(_on_interact_area_entered)
		interact_sensor.area_exited.connect(_on_interact_area_exited)


func _physics_process(delta: float) -> void:
	if input_reader != null and input_reader.is_inventory_just_pressed() and hud != null:
		hud.toggle_inventory()

	if hud != null and hud.is_inventory_open():
		hud.clear_interaction_prompt()
		_apply_gravity_only(delta)
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, ground_friction * delta)
		move_and_slide()
		_update_animation(false, delta)
		return

	_update_interaction_prompt()

	if input_reader != null and input_reader.is_interact_just_pressed():
		_try_interact()

	_apply_gravity_and_jump(delta)

	var input_v: Vector2 = input_reader.get_movement_vector() if input_reader != null else Vector2.ZERO
	var wish_dir := _camera_relative_direction(input_v)
	var sprinting: bool = input_reader != null and input_reader.is_sprint_pressed() and wish_dir.length_squared() > 0.01
	var target_speed := sprint_speed if sprinting else walk_speed

	var accel := ground_accel if is_on_floor() else air_accel
	var friction := ground_friction if is_on_floor() else air_friction
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)

	if wish_dir.length_squared() > 0.01:
		horizontal = horizontal.move_toward(wish_dir * target_speed, accel * delta)
		_last_facing = wish_dir
	else:
		horizontal = horizontal.move_toward(Vector3.ZERO, friction * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()

	_orient_visual(delta)
	_update_animation(sprinting, delta)


func _apply_gravity_and_jump(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	elif _coyote_timer > 0.0:
		_coyote_timer -= delta

	if input_reader != null and input_reader.is_jump_just_pressed():
		_jump_buffer_timer = jump_buffer_time
	elif _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	elif not is_on_floor():
		var multiplier := fall_gravity_multiplier if velocity.y < 0.0 else 1.0
		velocity.y -= gravity * multiplier * delta


func _apply_gravity_only(delta: float) -> void:
	if not is_on_floor():
		var multiplier := fall_gravity_multiplier if velocity.y < 0.0 else 1.0
		velocity.y -= gravity * multiplier * delta


func _camera_relative_direction(input_v: Vector2) -> Vector3:
	if camera == null:
		return Vector3(input_v.x, 0.0, input_v.y).normalized()

	var dir := camera.get_flat_right() * input_v.x + camera.get_flat_forward() * -input_v.y
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	return dir


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


func _update_animation(sprinting: bool, delta: float) -> void:
	if animator == null:
		return
	var horizontal_speed := Vector3(velocity.x, 0.0, velocity.z).length()
	animator.set_locomotion(horizontal_speed, sprinting, is_on_floor(), velocity.y, delta)


func _try_interact() -> void:
	var interactable := _get_best_interactable()
	if interactable == null:
		return
	if interactable.has_method("interact"):
		interactable.call("interact", self)
	interacted.emit(interactable)


func _update_interaction_prompt() -> void:
	if hud == null:
		return
	var interactable := _get_best_interactable()
	if interactable == null:
		hud.clear_interaction_prompt()
		return
	if interactable.has_method("get_prompt_text"):
		hud.show_interaction_prompt(str(interactable.call("get_prompt_text")))
	else:
		hud.show_interaction_prompt("E  Interact")


func _on_interact_area_entered(area: Area3D) -> void:
	if area.is_in_group(&"adventure_interactable"):
		_nearby_interactables.append(area)


func _on_interact_area_exited(area: Area3D) -> void:
	_nearby_interactables.erase(area)
	_update_interaction_prompt()


func _get_best_interactable() -> Node:
	var best: Node = null
	var best_dist := INF
	for item in _nearby_interactables:
		if not is_instance_valid(item) or not (item is Node3D):
			continue
		var dist := global_position.distance_squared_to((item as Node3D).global_position)
		if dist < best_dist:
			best_dist = dist
			best = item
	return best
