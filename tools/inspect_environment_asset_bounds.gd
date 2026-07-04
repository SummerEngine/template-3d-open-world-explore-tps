extends SceneTree

const ASSETS := [
	"res://assets/third_person_adventure/environment/structures/abandoned_farmhouse.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_barbed_fence.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_blue_barrel.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_concrete_slab.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_corrugated_fence.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_dry_grass.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_modular_fence.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_pebble_large.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_pebble_small.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_red_barrel.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_shed.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_utility_light.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_worn_tire.glb",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for path in ASSETS:
		var scene := load(path) as PackedScene
		if scene == null:
			push_error("Could not load %s" % path)
			continue
		var instance := scene.instantiate() as Node3D
		root.add_child(instance)
		await process_frame
		var bounds := _global_bounds(instance)
		print(path.get_file(), " bounds_pos=", bounds.position, " bounds_size=", bounds.size)
		instance.queue_free()
		await process_frame
	quit(OK)


func _global_bounds(root_node: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is MeshInstance3D:
			var mesh_instance := node as MeshInstance3D
			if mesh_instance.mesh == null:
				continue
			var transformed := _transform_aabb(mesh_instance.global_transform, mesh_instance.get_aabb())
			if not has_bounds:
				bounds = transformed
				has_bounds = true
			else:
				bounds = bounds.merge(transformed)
	return bounds


func _transform_aabb(transform: Transform3D, aabb: AABB) -> AABB:
	var result := AABB()
	var has_point := false
	for x in [aabb.position.x, aabb.position.x + aabb.size.x]:
		for y in [aabb.position.y, aabb.position.y + aabb.size.y]:
			for z in [aabb.position.z, aabb.position.z + aabb.size.z]:
				var point := transform * Vector3(x, y, z)
				if not has_point:
					result.position = point
					result.size = Vector3.ZERO
					has_point = true
				else:
					result = result.expand(point)
	return result
