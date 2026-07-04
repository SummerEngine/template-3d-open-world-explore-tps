extends Node3D
class_name AdventureTerrainGenerator

@export var generate_on_ready: bool = true
@export var terrain_size: float = 72.0
@export_range(8, 192, 1) var subdivisions: int = 64
@export var height_scale: float = 2.2
@export var noise_seed: int = 1337
@export var noise_frequency: float = 0.018
@export var ridge_strength: float = 0.35
@export var valley_width: float = 12.0
@export var sample_origin: Vector2 = Vector2.ZERO
@export var use_bounded_edge_lift: bool = true
@export var use_spawn_clearings: bool = true
@export var generate_collision: bool = true
@export var snap_group_name: StringName = &"snap_to_adventure_terrain"
@export var terrain_material: Material
@export var terrain_features: Array[Dictionary] = []

var _noise := FastNoiseLite.new()


func _ready() -> void:
	if generate_on_ready:
		generate()


func generate() -> void:
	_clear_generated()
	_configure_noise()

	var step := terrain_size / float(subdivisions)
	var half := terrain_size * 0.5
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for z in range(subdivisions + 1):
		for x in range(subdivisions + 1):
			var local_x := -half + float(x) * step
			var local_z := -half + float(z) * step
			var h := get_height_at(local_x, local_z)
			vertices.append(Vector3(local_x, h, local_z))
			uvs.append(Vector2(float(x) / float(subdivisions), float(z) / float(subdivisions)) * 8.0)

	for z in range(subdivisions):
		for x in range(subdivisions):
			var i := z * (subdivisions + 1) + x
			indices.append(i)
			indices.append(i + 1)
			indices.append(i + subdivisions + 1)
			indices.append(i + 1)
			indices.append(i + subdivisions + 2)
			indices.append(i + subdivisions + 1)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var surface := SurfaceTool.new()
	surface.create_from(mesh, 0)
	surface.generate_normals()
	mesh = surface.commit()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "GeneratedTerrainMesh"
	mesh_instance.mesh = mesh
	mesh_instance.add_to_group("generated_adventure_terrain")
	if terrain_material != null:
		mesh_instance.material_override = terrain_material
	else:
		mesh_instance.material_override = _make_default_material()
	add_child(mesh_instance)

	if generate_collision:
		_add_collision(mesh)

	_snap_group_members()


func get_height_at(local_x: float, local_z: float) -> float:
	var sample_x := local_x + sample_origin.x
	var sample_z := local_z + sample_origin.y
	var h := _base_height_at(sample_x, sample_z, local_x, local_z)
	h = _apply_terrain_features(h, sample_x, sample_z)
	return h


func _base_height_at(sample_x: float, sample_z: float, local_x: float = NAN, local_z: float = NAN) -> float:
	if is_nan(local_x):
		local_x = sample_x - sample_origin.x
	if is_nan(local_z):
		local_z = sample_z - sample_origin.y

	var broad: float = _noise.get_noise_2d(sample_x, sample_z)
	var mid: float = _noise.get_noise_2d(sample_x * 1.55 + 40.0, sample_z * 1.55 - 20.0)
	var detail: float = _noise.get_noise_2d(sample_x * 3.25 - 80.0, sample_z * 3.25 + 10.0)
	var ridge: float = 1.0 - absf(_noise.get_noise_2d(sample_x * 0.55 - 18.0, sample_z * 0.55 + 11.0))

	var dist_from_center: float = Vector2(local_x, local_z).length() / (terrain_size * 0.5)
	var edge_lift: float = smoothstep(0.68, 1.0, dist_from_center) * 0.9 if use_bounded_edge_lift else 0.0
	var path_cut: float = exp(-pow(absf(sample_x) / maxf(valley_width, 0.1), 2.0)) * 0.35

	var h := broad * height_scale
	h += mid * height_scale * 0.28
	h += detail * 0.16
	h += ridge * ridge_strength
	h += edge_lift
	h -= path_cut
	h = clampf(h, -1.2, 3.2)
	if use_spawn_clearings:
		h = _flatten_circle(h, sample_x, sample_z, Vector2(0, 12), 7.0)
		h = _flatten_circle(h, sample_x, sample_z, Vector2(8, -10), 6.0)
		h = _flatten_circle(h, sample_x, sample_z, Vector2(-12, -14), 5.0)
	return h


func _apply_terrain_features(height: float, sample_x: float, sample_z: float) -> float:
	var h := height
	for feature in terrain_features:
		if not bool(feature.get("enabled", true)):
			continue
		var feature_type := String(feature.get("type", ""))
		if feature_type == "road_path":
			h = _apply_road_path_feature(h, sample_x, sample_z, feature)

	for feature in terrain_features:
		if not bool(feature.get("enabled", true)):
			continue
		var feature_type := String(feature.get("type", ""))
		if feature_type == "flat_pad":
			h = _apply_flat_pad_feature(h, sample_x, sample_z, feature)
	return h


func _apply_flat_pad_feature(height: float, sample_x: float, sample_z: float, feature: Dictionary) -> float:
	var center := feature.get("center", Vector2.ZERO) as Vector2
	var half_size := feature.get("half_size", Vector2(5.0, 5.0)) as Vector2
	var rotation_y := float(feature.get("rotation_y", 0.0))
	var blend_radius := maxf(float(feature.get("blend_radius", 3.0)), 0.01)
	var use_current_terrain_height := bool(feature.get("use_current_terrain_height", true))
	var target_height := float(feature.get("target_height", 0.12))

	if use_current_terrain_height:
		target_height = _base_height_at(center.x, center.y)

	var local := _rotate_2d(Vector2(sample_x, sample_z) - center, -rotation_y)
	var outside := Vector2(
		maxf(absf(local.x) - maxf(half_size.x, 0.01), 0.0),
		maxf(absf(local.y) - maxf(half_size.y, 0.01), 0.0)
	)
	var outside_distance := outside.length()
	if outside_distance >= blend_radius:
		return height

	var weight := 1.0 if outside_distance <= 0.0 else 1.0 - smoothstep(0.0, blend_radius, outside_distance)
	return lerpf(height, target_height, weight)


func _apply_road_path_feature(height: float, sample_x: float, sample_z: float, feature: Dictionary) -> float:
	var points := feature.get("points", PackedVector2Array()) as PackedVector2Array
	if points.size() < 2:
		return height

	var road_width := maxf(float(feature.get("road_width", 4.0)), 0.1)
	var shoulder_width := maxf(float(feature.get("shoulder_width", 3.0)), 0.0)
	var surface_drop := float(feature.get("surface_drop", 0.06))
	var half_width := road_width * 0.5
	var outer_width := half_width + shoulder_width
	var sample := Vector2(sample_x, sample_z)
	var closest_point := points[0]
	var closest_distance := INF

	for index in range(points.size() - 1):
		var a := points[index]
		var b := points[index + 1]
		var projected := _closest_point_on_segment(sample, a, b)
		var distance := sample.distance_to(projected)
		if distance < closest_distance:
			closest_distance = distance
			closest_point = projected

	if closest_distance >= outer_width:
		return height

	var target_height := _base_height_at(closest_point.x, closest_point.y) - surface_drop
	var weight := 1.0
	if closest_distance > half_width and shoulder_width > 0.0:
		weight = 1.0 - smoothstep(half_width, outer_width, closest_distance)
	return lerpf(height, target_height, weight)


func _rotate_2d(value: Vector2, radians: float) -> Vector2:
	var c := cos(radians)
	var s := sin(radians)
	return Vector2(value.x * c - value.y * s, value.x * s + value.y * c)


func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var length_squared := ab.length_squared()
	if length_squared <= 0.001:
		return a
	var t := clampf((point - a).dot(ab) / length_squared, 0.0, 1.0)
	return a + ab * t


func snap_node_to_terrain(node: Node3D, y_offset: float = 0.05) -> void:
	var local := to_local(node.global_position)
	local.y = get_height_at(local.x, local.z) + y_offset
	node.global_position = to_global(local)
	node.reset_physics_interpolation()


func _configure_noise() -> void:
	_noise.seed = noise_seed
	_noise.frequency = noise_frequency
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 3
	_noise.fractal_lacunarity = 2.0
	_noise.fractal_gain = 0.42


func _flatten_circle(height: float, world_x: float, world_z: float, center: Vector2, radius: float) -> float:
	var dist := Vector2(world_x, world_z).distance_to(center)
	if dist >= radius:
		return height
	var t := smoothstep(0.0, radius, dist)
	return lerpf(height, 0.12, 1.0 - t)


func _add_collision(mesh: ArrayMesh) -> void:
	var shape := mesh.create_trimesh_shape()
	if shape is ConcavePolygonShape3D:
		(shape as ConcavePolygonShape3D).backface_collision = true

	var body := StaticBody3D.new()
	body.name = "GeneratedTerrainBody"
	body.collision_layer = AdventureLayers.WORLD
	body.collision_mask = 0
	body.add_to_group("generated_adventure_terrain")

	var collision := CollisionShape3D.new()
	collision.name = "GeneratedTerrainCollision"
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _snap_group_members() -> void:
	if snap_group_name == StringName():
		return
	for node in get_tree().get_nodes_in_group(snap_group_name):
		if node is Node3D:
			var offset := 0.45 if node is CharacterBody3D else 0.05
			snap_node_to_terrain(node as Node3D, offset)
			if node is CharacterBody3D:
				(node as CharacterBody3D).velocity = Vector3.ZERO


func _clear_generated() -> void:
	for child in get_children():
		if child.is_in_group("generated_adventure_terrain"):
			child.queue_free()


func _make_default_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.42, 0.25, 1.0)
	mat.roughness = 0.95
	return mat
