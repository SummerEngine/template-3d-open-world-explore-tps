extends SceneTree

const ASSETS := [
	"res://assets/third_person_adventure/environment/structures/abandoned_farmhouse.glb",
	"res://assets/third_person_adventure/environment/wasteland_props/wasteland_shed.glb",
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
		print("ASSET ", path)
		_print_materials(instance)
		instance.queue_free()
		await process_frame
	quit(OK)


func _print_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		print("  mesh=", mesh_instance.name, " surfaces=", mesh_instance.get_surface_override_material_count())
		var mesh := mesh_instance.mesh
		if mesh != null:
			for surface in range(mesh.get_surface_count()):
				var material := mesh_instance.get_active_material(surface)
				var texture_state := "no material"
				if material is StandardMaterial3D:
					var standard := material as StandardMaterial3D
					texture_state = "albedo_texture=%s color=%s" % [
						str(standard.albedo_texture.resource_path if standard.albedo_texture != null else "<none>"),
						str(standard.albedo_color),
					]
				elif material != null:
					texture_state = "%s path=%s" % [material.get_class(), material.resource_path]
				print("    surface=", surface, " ", texture_state)
	for child in node.get_children():
		_print_materials(child)
