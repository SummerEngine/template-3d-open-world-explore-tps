extends Node3D
class_name TerrainRoadPath

@export var enabled: bool = true
@export var road_width: float = 4.0
@export var shoulder_width: float = 3.0
@export var surface_drop: float = 0.06
@export var show_preview: bool = false
@export var preview_samples_per_meter: float = 0.35
@export var preview_color: Color = Color(0.34, 0.28, 0.2, 0.82)


func _ready() -> void:
	call_deferred("_rebuild_preview")


func get_terrain_feature_data() -> Dictionary:
	return {
		"type": "road_path",
		"enabled": enabled,
		"points": _get_path_points_2d(),
		"road_width": road_width,
		"shoulder_width": shoulder_width,
		"surface_drop": surface_drop,
	}


func _get_path_points_2d() -> PackedVector2Array:
	var points := PackedVector2Array()
	for child in get_children():
		if child is Marker3D:
			var marker := child as Marker3D
			points.append(Vector2(marker.global_position.x, marker.global_position.z))
	return points


func _rebuild_preview() -> void:
	for child in get_children():
		if child.is_in_group(&"terrain_feature_preview"):
			child.queue_free()

	if not show_preview:
		return

	var path_points := _get_path_points_3d()
	if path_points.size() < 2:
		return

	var sampled := _sample_path(path_points)
	if sampled.size() < 2:
		return

	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var half_width := road_width * 0.5

	for index in range(sampled.size()):
		var previous: Vector3 = sampled[maxi(index - 1, 0)]
		var current: Vector3 = sampled[index]
		var next: Vector3 = sampled[mini(index + 1, sampled.size() - 1)]
		var forward := next - previous
		forward.y = 0.0
		if forward.length_squared() <= 0.001:
			forward = Vector3.FORWARD
		forward = forward.normalized()
		var right := Vector3(forward.z, 0.0, -forward.x)
		vertices.append(to_local(current - right * half_width))
		vertices.append(to_local(current + right * half_width))

	for index in range(sampled.size() - 1):
		var i := index * 2
		indices.append(i)
		indices.append(i + 1)
		indices.append(i + 2)
		indices.append(i + 1)
		indices.append(i + 3)
		indices.append(i + 2)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var preview := MeshInstance3D.new()
	preview.name = "RoadPreview"
	preview.mesh = mesh
	preview.add_to_group(&"terrain_feature_preview")
	preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	preview.material_override = _make_preview_material(preview_color)
	add_child(preview)


func _get_path_points_3d() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for child in get_children():
		if child is Marker3D:
			points.append((child as Marker3D).global_position)
	return points


func _sample_path(points: Array[Vector3]) -> Array[Vector3]:
	var sampled: Array[Vector3] = []
	var sampler := _find_terrain_sampler()
	var spacing := 1.0 / maxf(preview_samples_per_meter, 0.05)

	for index in range(points.size() - 1):
		var start := points[index]
		var end := points[index + 1]
		var distance := start.distance_to(end)
		var steps := maxi(1, ceili(distance / spacing))
		for step_index in range(steps + 1):
			if index > 0 and step_index == 0:
				continue
			var t := float(step_index) / float(steps)
			var point := start.lerp(end, t)
			if sampler != null and sampler.has_method("get_height_at_global"):
				point.y = float(sampler.call("get_height_at_global", point.x, point.z)) + 0.045
			else:
				point.y += 0.045
			sampled.append(point)

	return sampled


func _find_terrain_sampler() -> Node:
	var node: Node = self
	while node != null:
		if node.has_method("get_height_at_global"):
			return node
		node = node.get_parent()
	return null


func _make_preview_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat
