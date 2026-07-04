extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		push_error("Could not load main scene.")
		quit(FAILED)
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame

	var world_environment := scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var sun := scene.get_node_or_null("Sun") as DirectionalLight3D
	var fill := scene.get_node_or_null("FillLight") as DirectionalLight3D

	_check(world_environment != null, "WorldEnvironment exists.")
	_check(sun != null, "Sun DirectionalLight3D exists.")
	_check(fill != null, "FillLight DirectionalLight3D exists.")

	if world_environment == null or world_environment.environment == null:
		_finish()
		return

	var environment := world_environment.environment
	_check(environment.background_mode == Environment.BG_SKY, "Environment uses sky background mode.")
	_check(environment.sky != null, "Environment has a Sky resource.")
	_check(environment.ambient_light_source == Environment.AMBIENT_SOURCE_SKY, "Ambient light comes from sky.")
	_check(absf(environment.ambient_light_energy - 1.08) <= 0.02, "Ambient light energy matches realistic sky tuning.")
	_check(environment.fog_enabled, "Atmospheric fog is enabled.")
	_check(absf(environment.fog_density - 0.0045) <= 0.0005, "Fog density is subtle countryside haze.")

	if environment.sky != null:
		var sky_material := environment.sky.sky_material
		_check(sky_material is PhysicalSkyMaterial, "Sky uses PhysicalSkyMaterial.")
		if sky_material is PhysicalSkyMaterial:
			var physical := sky_material as PhysicalSkyMaterial
			_check(absf(physical.rayleigh_coefficient - 2.35) <= 0.05, "Rayleigh scattering is configured.")
			_check(absf(physical.mie_coefficient - 0.006) <= 0.001, "Mie scattering haze is configured.")
			_check(absf(physical.turbidity - 4.2) <= 0.1, "Turbidity is clear-day realistic.")
			_check(absf(physical.sun_disk_scale - 1.7) <= 0.05, "Visible sun disk scale is configured.")

	if sun != null:
		_check(sun.shadow_enabled, "Sun shadows are enabled.")
		_check(sun.light_energy >= 3.0, "Sun is bright enough for outdoor countryside.")

	if fill != null:
		_check(not fill.shadow_enabled, "Fill light does not cast duplicate shadows.")

	_finish()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		var failure := "FAIL: %s" % message
		_failures.append(failure)
		push_error(failure)


func _finish() -> void:
	if _failures.is_empty():
		print("realistic_sky_runtime_ok")
	quit(OK if _failures.is_empty() else FAILED)
