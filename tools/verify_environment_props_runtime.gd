extends SceneTree

const PROP_SCENES := {
	"AbandonedFarmhouse": "res://assets/third_person_adventure/environment/structures/abandoned_farmhouse.glb",
	"WastelandShed": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_shed.glb",
	"WastelandCorrugatedFenceA": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_corrugated_fence.glb",
	"WastelandBarbedFenceA": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_barbed_fence.glb",
	"WastelandModularFenceA": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_modular_fence.glb",
	"WastelandBlueBarrel": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_blue_barrel.glb",
	"WastelandRedBarrel": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_red_barrel.glb",
	"WastelandConcreteSlab": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_concrete_slab.glb",
	"WastelandUtilityLight": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_utility_light.glb",
	"WastelandWornTire": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_worn_tire.glb",
	"WastelandPebbleLarge": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_pebble_large.glb",
	"WastelandPebbleSmall": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_pebble_small.glb",
	"WastelandDryGrass": "res://assets/third_person_adventure/environment/wasteland_props/wasteland_dry_grass.glb",
}

const BANNED_NAME_FRAGMENTS := [
	"low__",
	"dirty",
	"poor",
	"post-apocalyptic",
	"post_apocalyptic",
	"sketchfab_model",
	"showcase",
	"_lod2",
	"corregated",
	"sandy_pebble",
	"tyre",
	"wheat_blade",
]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		push_error("Could not load main scene.")
		quit(FAILED)
		return

	var scene: Node = packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	for _i in range(12):
		await physics_frame

	var terrain := scene.get_node_or_null("Level/TerrainRoot")
	var pad := scene.get_node_or_null("Level/TerrainRoot/Features/StarterHomesteadFlatPad")
	var road := scene.get_node_or_null("Level/TerrainRoot/Features/PlayerScoutRelicRoad")
	var environment_props := scene.get_node_or_null("Level/EnvironmentProps")

	_check(terrain != null, "TerrainRoot exists.")
	_check(pad != null and pad.has_method("get_terrain_feature_data"), "StarterHomesteadFlatPad exists and exports feature data.")
	_check(road == null, "PlayerScoutRelicRoad is removed from the default scene.")
	_check(environment_props != null, "EnvironmentProps root exists.")
	_check(_first_named(scene, "FlatPadPreview") == null, "Flat pad preview planes are not present.")
	_check(_first_named(scene, "RoadPreview") == null, "Road preview planes are not present.")

	if terrain == null or environment_props == null:
		_finish()
		return

	for prop_name in PROP_SCENES.keys():
		var scene_path := String(PROP_SCENES[prop_name])
		var prop_root := environment_props.get_node_or_null(String(prop_name)) as Node3D
		var model := environment_props.get_node_or_null("%s/%sModel" % [String(prop_name), String(prop_name)])
		_check(ResourceLoader.exists(scene_path), "Imported scene exists: %s." % scene_path)
		_check(prop_root != null, "Placed prop root exists: %s." % String(prop_name))
		_check(model != null, "Placed prop has model child: %s." % String(prop_name))
		if prop_root != null:
			_check(prop_root.is_in_group(&"snap_to_adventure_terrain"), "%s is snapped to terrain." % String(prop_name))
			var terrain_y: float = terrain.call("get_height_at_global", prop_root.global_position.x, prop_root.global_position.z)
			_check(absf(prop_root.global_position.y - (terrain_y + 0.05)) <= 0.08, "%s sits on sampled terrain." % String(prop_name))
			_check(_global_bounds(prop_root).size.length() > 0.02, "%s has visible mesh bounds." % String(prop_name))

	var farmhouse := environment_props.get_node_or_null("AbandonedFarmhouse") as Node3D
	var shed := environment_props.get_node_or_null("WastelandShed") as Node3D
	_check(farmhouse != null and farmhouse.scale.is_equal_approx(Vector3(2.7, 2.7, 2.7)), "AbandonedFarmhouse is doubled to scale Vector3(2.7, 2.7, 2.7).")
	_check(shed != null and shed.scale.is_equal_approx(Vector3(8, 8, 8)), "WastelandShed is doubled to scale Vector3(8, 8, 8).")
	if farmhouse != null:
		_check(_has_textured_material(farmhouse), "AbandonedFarmhouse has generated textured materials.")
		_check(_has_mesh_collider(farmhouse), "AbandonedFarmhouse has generated mesh colliders.")
	if shed != null:
		_check(_has_textured_material(shed), "WastelandShed has generated textured materials.")
		_check(_has_mesh_collider(shed), "WastelandShed has generated mesh colliders.")

	var old_name := _first_banned_name(environment_props)
	_check(old_name.is_empty(), "Environment prop subtree avoids source-file and raw-pack node names. First raw name: %s" % old_name)

	var player := scene.get_node_or_null("Player") as Node3D
	if farmhouse != null and player != null:
		_check(farmhouse.global_position.distance_to(player.global_position) <= 30.0, "AbandonedFarmhouse starts near the player.")

	var homestead_range := _height_range(terrain, Vector2(-13.0, 14.0), Vector2(9.0, 6.0))
	_check(homestead_range <= 0.08, "StarterHomesteadFlatPad has a low height range for prop placement.")

	if _failures.is_empty():
		print("environment_props_runtime_ok homestead_range=", snappedf(homestead_range, 0.001))
	_finish()


func _first_banned_name(root_node: Node) -> String:
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var lower_name := String(node.name).to_lower()
		for fragment in BANNED_NAME_FRAGMENTS:
			if lower_name.contains(String(fragment)):
				return node.get_path()
		for child in node.get_children():
			stack.append(child)
	return ""


func _first_named(root_node: Node, node_name: StringName) -> Node:
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.name == node_name:
			return node
		for child in node.get_children():
			stack.append(child)
	return null


func _has_textured_material(root_node: Node) -> bool:
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			var mesh_instance := node as MeshInstance3D
			if mesh_instance.mesh == null:
				continue
			for surface in range(mesh_instance.mesh.get_surface_count()):
				var material := mesh_instance.get_active_material(surface)
				if material is StandardMaterial3D and (material as StandardMaterial3D).albedo_texture != null:
					return true
		for child in node.get_children():
			stack.append(child)
	return false


func _has_mesh_collider(root_node: Node) -> bool:
	var body := root_node.get_node_or_null("MeshColliders") as StaticBody3D
	if body == null:
		return false
	for child in body.get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).shape is ConcavePolygonShape3D:
			return true
	return false


func _height_range(terrain: Node, center: Vector2, half_extents: Vector2) -> float:
	var min_height := INF
	var max_height := -INF
	for x_index in range(4):
		for z_index in range(4):
			var x := center.x + lerpf(-half_extents.x, half_extents.x, float(x_index) / 3.0)
			var z := center.y + lerpf(-half_extents.y, half_extents.y, float(z_index) / 3.0)
			var h: float = terrain.call("get_height_at_global", x, z)
			min_height = minf(min_height, h)
			max_height = maxf(max_height, h)
	return max_height - min_height


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


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		var failure := "FAIL: %s" % message
		_failures.append(failure)
		push_error(failure)


func _finish() -> void:
	quit(OK if _failures.is_empty() else FAILED)
