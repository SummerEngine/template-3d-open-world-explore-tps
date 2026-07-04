extends Node3D
class_name ThirdPersonAdventureCamera

@export var target_path: NodePath
@export var input_reader_path: NodePath = ^"../InputReader"
@export var pitch_pivot_path: NodePath = ^"PitchPivot"
@export var spring_arm_path: NodePath = ^"PitchPivot/SpringArm3D"
@export var camera_path: NodePath = ^"PitchPivot/SpringArm3D/Camera3D"

@export_range(0.01, 2.0, 0.01) var mouse_sensitivity: float = 0.28
@export_range(0.1, 12.0, 0.1) var gamepad_sensitivity: float = 4.0
@export var invert_y: bool = false
@export var pitch_min_degrees: float = -55.0
@export var pitch_max_degrees: float = 35.0
@export var follow_lag: float = 14.0
@export var spring_length: float = 5.0
@export var height_offset: float = 1.55

@onready var input_reader := get_node_or_null(input_reader_path)
@onready var pitch_pivot: Node3D = get_node_or_null(pitch_pivot_path) as Node3D
@onready var spring_arm: SpringArm3D = get_node_or_null(spring_arm_path) as SpringArm3D
@onready var camera: Camera3D = get_node_or_null(camera_path) as Camera3D
@onready var target: Node3D = get_node_or_null(target_path) as Node3D

var _yaw: float = 0.0
var _pitch: float = deg_to_rad(-18.0)


func _ready() -> void:
	if input_reader == null:
		push_warning("ThirdPersonAdventureCamera needs World/InputReader for mouse-delta orbit input.")

	if spring_arm != null:
		spring_arm.spring_length = spring_length
		spring_arm.margin = 0.2
		spring_arm.collision_mask = AdventureLayers.CAMERA_MASK
		if target is CollisionObject3D:
			spring_arm.add_excluded_object((target as CollisionObject3D).get_rid())

	if camera != null:
		camera.current = true

	if target != null:
		global_position = _target_position()
		reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if target == null or pitch_pivot == null:
		return

	var mouse_delta: Vector2 = input_reader.consume_camera_orbit_delta() if input_reader != null else Vector2.ZERO
	var stick: Vector2 = input_reader.get_camera_axis() if input_reader != null else Vector2.ZERO
	_yaw += (-mouse_delta.x * mouse_sensitivity * 0.01) + (-stick.x * gamepad_sensitivity * delta)

	var pitch_sign := 1.0 if invert_y else -1.0
	_pitch += (pitch_sign * mouse_delta.y * mouse_sensitivity * 0.01) + (-stick.y * gamepad_sensitivity * delta)
	_pitch = clampf(_pitch, deg_to_rad(pitch_min_degrees), deg_to_rad(pitch_max_degrees))

	rotation.y = _yaw
	pitch_pivot.rotation.x = _pitch

	var desired := _target_position()
	var t := 1.0 if follow_lag <= 0.0 else 1.0 - exp(-follow_lag * delta)
	global_position = global_position.lerp(desired, t)


func _target_position() -> Vector3:
	return target.global_position + Vector3.UP * height_offset


func get_flat_forward() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


func get_flat_right() -> Vector3:
	var right := global_transform.basis.x
	right.y = 0.0
	if right.length_squared() < 0.0001:
		return Vector3.RIGHT
	return right.normalized()


func get_camera() -> Camera3D:
	return camera
