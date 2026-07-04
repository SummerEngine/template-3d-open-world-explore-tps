extends SceneTree

const PLAYER_ROBOT_SCENE := "res://assets/third_person_adventure/characters/player_robot/player_robot.fbx"
const PLAYER_ROBOT_IDLE_CLIP := "res://assets/third_person_adventure/characters/player_robot/player_robot_idle.fbx"
const PLAYER_ROBOT_LONG_IDLE_CLIP := "res://assets/third_person_adventure/characters/player_robot/player_robot_long_idle.fbx"
const PLAYER_ROBOT_WALK_CLIP := "res://assets/third_person_adventure/characters/player_robot/player_robot_walk.fbx"
const PLAYER_ROBOT_RUN_CLIP := "res://assets/third_person_adventure/characters/player_robot/player_robot_run.fbx"
const PLAYER_ROBOT_JUMP_CLIP := "res://assets/third_person_adventure/characters/player_robot/player_robot_jump.fbx"
const PLAYER_ROBOT_FALL_CLIP := "res://assets/third_person_adventure/characters/player_robot/player_robot_fall.fbx"
const PLAYER_ROBOT_LAND_CLIP := "res://assets/third_person_adventure/characters/player_robot/player_robot_land.fbx"
const PLAYER_ROBOT_MATERIAL := "res://assets/third_person_adventure/characters/player_robot/materials/player_robot_material.tres"
const ABANDONED_FARMHOUSE_SCENE := "res://assets/third_person_adventure/environment/structures/abandoned_farmhouse.glb"
const WASTELAND_BARBED_FENCE_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_barbed_fence.glb"
const WASTELAND_BLUE_BARREL_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_blue_barrel.glb"
const WASTELAND_CONCRETE_SLAB_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_concrete_slab.glb"
const WASTELAND_CORRUGATED_FENCE_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_corrugated_fence.glb"
const WASTELAND_DRY_GRASS_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_dry_grass.glb"
const WASTELAND_MODULAR_FENCE_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_modular_fence.glb"
const WASTELAND_PEBBLE_LARGE_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_pebble_large.glb"
const WASTELAND_PEBBLE_SMALL_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_pebble_small.glb"
const WASTELAND_RED_BARREL_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_red_barrel.glb"
const WASTELAND_SHED_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_shed.glb"
const WASTELAND_UTILITY_LIGHT_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_utility_light.glb"
const WASTELAND_WORN_TIRE_SCENE := "res://assets/third_person_adventure/environment/wasteland_props/wasteland_worn_tire.glb"


func _init() -> void:
	var err := _build()
	quit(err)


func _build() -> int:
	var player_robot_scene := load(PLAYER_ROBOT_SCENE) as PackedScene
	if player_robot_scene == null:
		push_error("Missing imported player robot scene: %s" % PLAYER_ROBOT_SCENE)
		return ERR_CANT_OPEN
	var player_robot_material := load(PLAYER_ROBOT_MATERIAL) as Material
	if player_robot_material == null:
		push_error("Missing imported player robot material: %s" % PLAYER_ROBOT_MATERIAL)
		return ERR_CANT_OPEN

	var world := Node3D.new()
	world.name = "World"

	_add_input_reader(world)
	_add_lighting(world)
	_add_level(world)
	_add_player(world, player_robot_scene, player_robot_material)
	_add_camera(world)
	_add_npc(world, player_robot_scene, player_robot_material)
	_add_patrol_points(world)
	_add_inventory(world)
	_add_quest_state(world)
	_add_hud(world)

	_assign_owner(world, world)

	var packed := PackedScene.new()
	var pack_err := packed.pack(world)
	if pack_err != OK:
		push_error("Could not pack main scene: %s" % pack_err)
		return pack_err

	var save_err := ResourceSaver.save(packed, "res://scenes/main.tscn")
	if save_err != OK:
		push_error("Could not save main scene: %s" % save_err)
		return save_err

	world.free()
	print("Saved res://scenes/main.tscn")
	return OK


func _add_input_reader(world: Node3D) -> void:
	var input_reader := Node.new()
	input_reader.name = "InputReader"
	input_reader.set_script(load("res://scripts/adventure_input_reader.gd"))
	input_reader.set("capture_mouse_on_ready", true)
	input_reader.set("recapture_on_mouse_button", true)
	input_reader.set("ensure_input_actions", true)
	world.add_child(input_reader)


func _add_lighting(world: Node3D) -> void:
	var environment_node := WorldEnvironment.new()
	environment_node.name = "WorldEnvironment"
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := PhysicalSkyMaterial.new()
	sky_material.rayleigh_coefficient = 2.35
	sky_material.rayleigh_color = Color(0.31, 0.44, 0.72)
	sky_material.mie_coefficient = 0.006
	sky_material.mie_eccentricity = 0.82
	sky_material.mie_color = Color(0.86, 0.79, 0.66)
	sky_material.turbidity = 4.2
	sky_material.sun_disk_scale = 1.7
	sky_material.ground_color = Color(0.28, 0.25, 0.18)
	sky_material.energy_multiplier = 1.08
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.78, 0.86, 0.96)
	environment.ambient_light_energy = 1.08
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.82, 0.9, 0.98)
	environment.fog_density = 0.0045
	environment_node.environment = environment
	world.add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.light_energy = 3.8
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.72
	world.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-28.0, 130.0, 0.0)
	fill.light_color = Color(0.68, 0.78, 1.0)
	fill.light_energy = 0.65
	fill.shadow_enabled = false
	world.add_child(fill)


func _add_level(world: Node3D) -> void:
	var level := Node3D.new()
	level.name = "Level"
	world.add_child(level)

	var terrain_root := Node3D.new()
	terrain_root.name = "TerrainRoot"
	terrain_root.set_script(load("res://scripts/adventure_terrain_grid.gd"))
	terrain_root.set("target_path", NodePath("../../Player"))
	terrain_root.set("terrain_generator_script_path", "res://scripts/adventure_terrain_generator.gd")
	terrain_root.set("chunk_size", 72.0)
	terrain_root.set("active_radius", 1)
	terrain_root.set("subdivisions", 48)
	terrain_root.set("height_scale", 2.2)
	terrain_root.set("noise_frequency", 0.018)
	terrain_root.set("ridge_strength", 0.35)
	terrain_root.set("valley_width", 12.0)
	terrain_root.set("snap_group_name", &"snap_to_adventure_terrain")
	level.add_child(terrain_root)
	_add_terrain_features(terrain_root)

	var landmarks := Node3D.new()
	landmarks.name = "Landmarks"
	level.add_child(landmarks)
	_add_rock(landmarks, "RidgeRockA", Vector3(-18.0, 1.0, -4.0), Vector3(2.4, 1.4, 1.8))
	_add_rock(landmarks, "RidgeRockB", Vector3(18.0, 1.0, 8.0), Vector3(1.8, 1.2, 2.8))
	_add_rock(landmarks, "PathMarkerStone", Vector3(2.0, 0.7, -18.0), Vector3(1.2, 1.0, 1.2))

	var environment_props := Node3D.new()
	environment_props.name = "EnvironmentProps"
	level.add_child(environment_props)
	_add_starter_homestead_props(environment_props)

	var collectibles := Node3D.new()
	collectibles.name = "Collectibles"
	level.add_child(collectibles)
	_add_collectible(collectibles)


func _add_terrain_features(terrain_root: Node3D) -> void:
	var features := Node3D.new()
	features.name = "Features"
	terrain_root.add_child(features)

	var scout_pad := Node3D.new()
	scout_pad.name = "ScoutCampFlatPad"
	scout_pad.set_script(load("res://scripts/terrain_flat_pad.gd"))
	scout_pad.position = Vector3(10.0, 0.12, -8.0)
	scout_pad.rotation_degrees.y = -18.0
	scout_pad.set("size", Vector2(20.0, 14.0))
	scout_pad.set("blend_radius", 5.0)
	scout_pad.set("use_current_terrain_height", true)
	scout_pad.set("show_preview", false)
	features.add_child(scout_pad)

	var relic_pad := Node3D.new()
	relic_pad.name = "RelicClearingFlatPad"
	relic_pad.set_script(load("res://scripts/terrain_flat_pad.gd"))
	relic_pad.position = Vector3(-12.0, 0.12, -14.0)
	relic_pad.set("size", Vector2(12.0, 10.0))
	relic_pad.set("blend_radius", 4.0)
	relic_pad.set("use_current_terrain_height", true)
	relic_pad.set("show_preview", false)
	features.add_child(relic_pad)

	var homestead_pad := Node3D.new()
	homestead_pad.name = "StarterHomesteadFlatPad"
	homestead_pad.set_script(load("res://scripts/terrain_flat_pad.gd"))
	homestead_pad.position = Vector3(-13.0, 0.12, 14.0)
	homestead_pad.rotation_degrees.y = 8.0
	homestead_pad.set("size", Vector2(44.0, 32.0))
	homestead_pad.set("blend_radius", 7.0)
	homestead_pad.set("use_current_terrain_height", true)
	homestead_pad.set("show_preview", false)
	features.add_child(homestead_pad)


func _add_starter_homestead_props(parent: Node3D) -> void:
	_add_environment_prop(parent, "AbandonedFarmhouse", ABANDONED_FARMHOUSE_SCENE, Vector3(-16.0, 4.0, 14.5), -82.0, Vector3(2.7, 2.7, 2.7), "farmhouse", true)
	_add_environment_prop(parent, "WastelandShed", WASTELAND_SHED_SCENE, Vector3(-5.6, 4.0, 18.2), -18.0, Vector3(8.0, 8.0, 8.0), "shed", true)
	_add_environment_prop(parent, "WastelandCorrugatedFenceA", WASTELAND_CORRUGATED_FENCE_SCENE, Vector3(-6.0, 4.0, 9.2), 72.0, Vector3(4.4, 4.4, 4.4))
	_add_environment_prop(parent, "WastelandBarbedFenceA", WASTELAND_BARBED_FENCE_SCENE, Vector3(-13.0, 4.0, 4.8), 92.0, Vector3(4.2, 4.2, 4.2))
	_add_environment_prop(parent, "WastelandModularFenceA", WASTELAND_MODULAR_FENCE_SCENE, Vector3(-19.0, 4.0, 6.2), 88.0, Vector3(4.2, 4.2, 4.2))
	_add_environment_prop(parent, "WastelandBlueBarrel", WASTELAND_BLUE_BARREL_SCENE, Vector3(-8.0, 4.0, 15.6), 16.0, Vector3(4.7, 4.7, 4.7))
	_add_environment_prop(parent, "WastelandRedBarrel", WASTELAND_RED_BARREL_SCENE, Vector3(-9.2, 4.0, 16.8), -28.0, Vector3(4.7, 4.7, 4.7))
	_add_environment_prop(parent, "WastelandConcreteSlab", WASTELAND_CONCRETE_SLAB_SCENE, Vector3(-10.8, 4.0, 11.2), 30.0, Vector3(5.2, 5.2, 5.2))
	_add_environment_prop(parent, "WastelandUtilityLight", WASTELAND_UTILITY_LIGHT_SCENE, Vector3(-7.4, 4.0, 12.8), 0.0, Vector3(5.0, 5.0, 5.0))
	_add_environment_prop(parent, "WastelandWornTire", WASTELAND_WORN_TIRE_SCENE, Vector3(-11.8, 4.0, 17.0), 52.0, Vector3(5.0, 5.0, 5.0))
	_add_environment_prop(parent, "WastelandPebbleLarge", WASTELAND_PEBBLE_LARGE_SCENE, Vector3(-4.6, 4.0, 14.6), 0.0, Vector3(12.0, 12.0, 12.0))
	_add_environment_prop(parent, "WastelandPebbleSmall", WASTELAND_PEBBLE_SMALL_SCENE, Vector3(-3.8, 4.0, 11.4), 0.0, Vector3(5.0, 5.0, 5.0))
	_add_environment_prop(parent, "WastelandDryGrass", WASTELAND_DRY_GRASS_SCENE, Vector3(-6.8, 4.0, 10.6), 0.0, Vector3(8.0, 8.0, 8.0))


func _add_environment_prop(parent: Node3D, node_name: String, scene_path: String, pos: Vector3, yaw_degrees: float, scale_value: Vector3, material_profile: String = "none", generate_mesh_collision: bool = false) -> void:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("Missing environment prop scene: %s" % scene_path)
		return

	var prop_root := Node3D.new()
	prop_root.name = node_name
	prop_root.position = pos
	prop_root.rotation_degrees.y = yaw_degrees
	prop_root.scale = scale_value
	if material_profile != "none" or generate_mesh_collision:
		prop_root.set_script(load("res://scripts/adventure_environment_prop_setup.gd"))
		prop_root.set("material_profile", material_profile)
		prop_root.set("apply_procedural_materials", material_profile != "none")
		prop_root.set("generate_mesh_collision", generate_mesh_collision)
	prop_root.add_to_group("snap_to_adventure_terrain", true)
	parent.add_child(prop_root)

	var model := packed_scene.instantiate()
	model.name = "%sModel" % node_name
	prop_root.add_child(model)


func _add_rock(parent: Node3D, node_name: String, pos: Vector3, scale_value: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 1.6
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.scale = scale_value
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.36, 0.34)
	mat.roughness = 1.0
	mesh_instance.material_override = mat
	mesh_instance.add_to_group("snap_to_adventure_terrain", true)
	parent.add_child(mesh_instance)


func _add_collectible(parent: Node3D) -> void:
	var relic := Area3D.new()
	relic.name = "Relic"
	relic.position = Vector3(-12.0, 4.0, -14.0)
	relic.set_script(load("res://scripts/adventure_collectible.gd"))
	relic.set("collectible_id", &"forest_relic")
	relic.set("display_name", "Forest Relic")
	relic.set("description", "A cool blue relic from the old forest path.")
	relic.set("prompt_action", "Pick up")
	relic.set("auto_collect_on_touch", false)
	relic.add_to_group("snap_to_adventure_terrain", true)
	parent.add_child(relic)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "RelicMesh"
	var mesh := SphereMesh.new()
	mesh.radius = 0.35
	mesh.height = 0.7
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 0.95)
	mat.emission_enabled = true
	mat.emission = Color(0.18, 0.65, 0.9)
	mat.emission_energy_multiplier = 0.9
	mesh_instance.material_override = mat
	relic.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	collision.shape = shape
	relic.add_child(collision)


func _add_player(world: Node3D, player_robot_scene: PackedScene, player_robot_material: Material) -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0.0, 4.0, 12.0)
	player.set_script(load("res://scripts/third_person_controller.gd"))
	player.set("camera_path", NodePath("../CameraRig"))
	player.set("input_reader_path", NodePath("../InputReader"))
	player.set("hud_path", NodePath("../HUD"))
	player.set("skin_pivot_path", NodePath("SkinPivot"))
	player.set("animator_path", NodePath("Animator"))
	player.set("interact_sensor_path", NodePath("InteractSensor"))
	player.add_to_group("snap_to_adventure_terrain", true)
	world.add_child(player)

	_add_capsule(player, "CollisionShape3D", 0.35, 1.8, Vector3(0.0, 0.9, 0.0))
	_add_player_robot_visual(player, player_robot_scene, player_robot_material)
	_add_player_robot_animator(player)
	_add_player_readability_light(player)

	var sensor := Area3D.new()
	sensor.name = "InteractSensor"
	player.add_child(sensor)
	var sensor_collision := CollisionShape3D.new()
	sensor_collision.name = "CollisionShape3D"
	var sensor_shape := SphereShape3D.new()
	sensor_shape.radius = 2.0
	sensor_collision.shape = sensor_shape
	sensor.add_child(sensor_collision)


func _add_player_readability_light(player: Node3D) -> void:
	var light := OmniLight3D.new()
	light.name = "PlayerReadabilityLight"
	light.position = Vector3(0.0, 2.3, 0.8)
	light.light_color = Color(1.0, 0.9, 0.74)
	light.light_energy = 0.45
	light.omni_range = 6.0
	light.shadow_enabled = false
	player.add_child(light)


func _add_player_robot_visual(parent: Node3D, player_robot_scene: PackedScene, player_robot_material: Material) -> void:
	var skin := Node3D.new()
	skin.name = "SkinPivot"
	skin.set_script(load("res://scripts/adventure_model_material_applier.gd"))
	skin.set("target_path", NodePath("player_robot"))
	skin.set("material", player_robot_material)
	parent.add_child(skin)

	var robot := player_robot_scene.instantiate()
	robot.name = "player_robot"
	robot.position = Vector3(0.0, 0.0, 0.0)
	robot.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	skin.add_child(robot)


func _add_npc_robot_visual(parent: Node3D, npc_robot_scene: PackedScene, npc_robot_material: Material) -> void:
	var skin := Node3D.new()
	skin.name = "SkinPivot"
	skin.set_script(load("res://scripts/adventure_model_material_applier.gd"))
	skin.set("target_path", NodePath("npc_robot"))
	skin.set("material", npc_robot_material)
	parent.add_child(skin)

	var robot := npc_robot_scene.instantiate()
	robot.name = "npc_robot"
	robot.position = Vector3(0.0, 0.0, 0.0)
	robot.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	skin.add_child(robot)


func _add_capsule(parent: Node, node_name: String, radius: float, height: float, pos: Vector3) -> void:
	var collision := CollisionShape3D.new()
	collision.name = node_name
	collision.position = pos
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	parent.add_child(collision)


func _add_npc_robot_animator(parent: Node3D) -> void:
	var animator := Node.new()
	animator.name = "Animator"
	animator.set_script(load("res://scripts/humanoid_locomotion_animator.gd"))
	animator.set("animation_player_path", NodePath("../SkinPivot/npc_robot/AnimationPlayer"))
	animator.set("idle_fbx", PLAYER_ROBOT_IDLE_CLIP)
	animator.set("walk_fbx", PLAYER_ROBOT_WALK_CLIP)
	animator.set("run_fbx", PLAYER_ROBOT_RUN_CLIP)
	animator.set("long_idle_fbx", PLAYER_ROBOT_LONG_IDLE_CLIP)
	animator.set("idle_animation", &"Idle")
	animator.set("walk_animation", &"Walk")
	animator.set("run_animation", &"Run")
	animator.set("long_idle_animation", &"LongIdle")
	animator.set("long_idle_delay", 10.0)
	animator.set("root_motion_track_path", "")
	animator.set("root_motion_track_name_hint", "Hips")
	animator.set("strip_horizontal_root_motion", true)
	animator.set("normalize_low_root_y", true)
	animator.set("root_y_drop_tolerance", 0.18)
	parent.add_child(animator)


func _add_player_robot_animator(parent: Node3D) -> void:
	var animator := Node.new()
	animator.name = "Animator"
	animator.set_script(load("res://scripts/humanoid_locomotion_animator.gd"))
	animator.set("animation_player_path", NodePath("../SkinPivot/player_robot/AnimationPlayer"))
	animator.set("idle_fbx", PLAYER_ROBOT_IDLE_CLIP)
	animator.set("walk_fbx", PLAYER_ROBOT_WALK_CLIP)
	animator.set("run_fbx", PLAYER_ROBOT_RUN_CLIP)
	animator.set("jump_fbx", PLAYER_ROBOT_JUMP_CLIP)
	animator.set("fall_fbx", PLAYER_ROBOT_FALL_CLIP)
	animator.set("land_fbx", PLAYER_ROBOT_LAND_CLIP)
	animator.set("long_idle_fbx", PLAYER_ROBOT_LONG_IDLE_CLIP)
	animator.set("idle_animation", &"Idle")
	animator.set("walk_animation", &"Walk")
	animator.set("run_animation", &"Run")
	animator.set("jump_animation", &"Jump")
	animator.set("fall_animation", &"Fall")
	animator.set("land_animation", &"Land")
	animator.set("long_idle_animation", &"LongIdle")
	animator.set("long_idle_delay", 10.0)
	animator.set("root_motion_track_path", "")
	animator.set("root_motion_track_name_hint", "Hips")
	animator.set("strip_horizontal_root_motion", true)
	animator.set("normalize_low_root_y", true)
	animator.set("root_y_drop_tolerance", 0.18)
	parent.add_child(animator)


func _add_camera(world: Node3D) -> void:
	var camera_rig := Node3D.new()
	camera_rig.name = "CameraRig"
	camera_rig.set_script(load("res://scripts/third_person_camera.gd"))
	camera_rig.set("target_path", NodePath("../Player"))
	camera_rig.set("input_reader_path", NodePath("../InputReader"))
	camera_rig.set("pitch_pivot_path", NodePath("PitchPivot"))
	camera_rig.set("spring_arm_path", NodePath("PitchPivot/SpringArm3D"))
	camera_rig.set("camera_path", NodePath("PitchPivot/SpringArm3D/Camera3D"))
	camera_rig.set("height_offset", 1.55)
	camera_rig.set("follow_lag", 14.0)
	camera_rig.set("spring_length", 5.0)
	world.add_child(camera_rig)

	var pitch_pivot := Node3D.new()
	pitch_pivot.name = "PitchPivot"
	pitch_pivot.rotation_degrees.x = -18.0
	camera_rig.add_child(pitch_pivot)

	var spring_arm := SpringArm3D.new()
	spring_arm.name = "SpringArm3D"
	spring_arm.spring_length = 5.0
	spring_arm.margin = 0.2
	spring_arm.collision_mask = 1
	pitch_pivot.add_child(spring_arm)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 68.0
	camera.current = true
	spring_arm.add_child(camera)

	var aim_ray := RayCast3D.new()
	aim_ray.name = "AimRay"
	aim_ray.target_position = Vector3(0.0, 0.0, -20.0)
	camera.add_child(aim_ray)


func _add_npc(world: Node3D, npc_robot_scene: PackedScene, npc_robot_material: Material) -> void:
	var npcs := Node3D.new()
	npcs.name = "NPCs"
	world.add_child(npcs)

	var npc := CharacterBody3D.new()
	npc.name = "ScoutRobotNPC"
	npc.position = Vector3(8.0, 4.0, -10.0)
	npc.set_script(load("res://scripts/adventure_patrol_npc.gd"))
	npc.set("skin_pivot_path", NodePath("SkinPivot"))
	npc.set("animator_path", NodePath("Animator"))
	npc.set("patrol_points_parent_path", NodePath("../../PatrolPoints/ScoutRobotPatrol"))
	npc.set("walk_speed", 2.0)
	npc.set("run_speed", 4.0)
	npc.set("allow_running", false)
	npc.set("run_distance_threshold", 10.0)
	npc.set("address_player_min_time", 2.0)
	npc.set("address_player_max_time", 3.0)
	npc.add_to_group("snap_to_adventure_terrain", true)
	npcs.add_child(npc)

	_add_capsule(npc, "CollisionShape3D", 0.4, 1.8, Vector3(0.0, 0.9, 0.0))
	_add_npc_robot_visual(npc, npc_robot_scene, npc_robot_material)
	_add_npc_robot_animator(npc)

	var quest_area := Area3D.new()
	quest_area.name = "QuestGiverArea"
	quest_area.set_script(load("res://scripts/adventure_interactable.gd"))
	quest_area.set("display_name", "Scout")
	quest_area.set("prompt_action", "Talk")
	npc.add_child(quest_area)

	var quest_collision := CollisionShape3D.new()
	quest_collision.name = "CollisionShape3D"
	var quest_shape := SphereShape3D.new()
	quest_shape.radius = 2.4
	quest_collision.shape = quest_shape
	quest_area.add_child(quest_collision)


func _add_patrol_points(world: Node3D) -> void:
	var patrol_points := Node3D.new()
	patrol_points.name = "PatrolPoints"
	world.add_child(patrol_points)

	var scout_robot_patrol := Node3D.new()
	scout_robot_patrol.name = "ScoutRobotPatrol"
	patrol_points.add_child(scout_robot_patrol)

	_add_marker(scout_robot_patrol, "PatrolA", Vector3(8.0, 4.0, -10.0))
	_add_marker(scout_robot_patrol, "PatrolB", Vector3(18.0, 4.0, -2.0))
	_add_marker(scout_robot_patrol, "PatrolC", Vector3(4.0, 4.0, 6.0))


func _add_marker(parent: Node3D, marker_name: String, pos: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.position = pos
	marker.add_to_group("snap_to_adventure_terrain", true)
	parent.add_child(marker)


func _add_inventory(world: Node3D) -> void:
	var inventory := Node.new()
	inventory.name = "Inventory"
	inventory.set_script(load("res://scripts/adventure_inventory.gd"))
	world.add_child(inventory)


func _add_quest_state(world: Node3D) -> void:
	var quest := Node.new()
	quest.name = "QuestState"
	quest.set_script(load("res://scripts/adventure_quest_state.gd"))
	quest.set("hud_path", NodePath("../HUD"))
	quest.set("npc_interactable_path", NodePath("../NPCs/ScoutRobotNPC/QuestGiverArea"))
	quest.set("collectible_path", NodePath("../Level/Collectibles/Relic"))
	quest.set("inventory_path", NodePath("../Inventory"))
	world.add_child(quest)


func _add_hud(world: Node3D) -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(load("res://scripts/adventure_hud.gd"))
	hud.set("inventory_path", NodePath("../Inventory"))
	hud.set("input_reader_path", NodePath("../InputReader"))
	world.add_child(hud)

	var root := Control.new()
	root.name = "Root"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	hud.add_child(root)

	var objective := Label.new()
	objective.name = "ObjectiveLabel"
	objective.anchor_right = 0.55
	objective.offset_left = 20.0
	objective.offset_top = 18.0
	objective.offset_right = 520.0
	objective.offset_bottom = 58.0
	objective.text = "Talk to the scout."
	root.add_child(objective)

func _assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		if child.scene_file_path.is_empty():
			_assign_owner(child, owner)
