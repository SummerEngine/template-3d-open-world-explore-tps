extends Node3D
class_name TerrainFlatPad

@export var enabled: bool = true
@export var size: Vector2 = Vector2(18.0, 14.0)
@export var blend_radius: float = 4.0
@export var use_current_terrain_height: bool = true
@export var target_height: float = 0.12
@export var show_preview: bool = false
@export var preview_color: Color = Color(0.45, 0.5, 0.38, 0.45)


func _ready() -> void:
	call_deferred("_rebuild_preview")


func get_terrain_feature_data() -> Dictionary:
	return {
		"type": "flat_pad",
		"enabled": enabled,
		"center": Vector2(global_position.x, global_position.z),
		"half_size": size * 0.5,
		"rotation_y": global_rotation.y,
		"blend_radius": blend_radius,
		"use_current_terrain_height": use_current_terrain_height,
		"target_height": target_height,
	}


func _rebuild_preview() -> void:
	for child in get_children():
		if child.is_in_group(&"terrain_feature_preview"):
			child.queue_free()

	if not show_preview:
		return

	var preview := MeshInstance3D.new()
	preview.name = "FlatPadPreview"
	preview.add_to_group(&"terrain_feature_preview")

	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.04, size.y)
	preview.mesh = mesh
	preview.position.y = 0.03
	preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	preview.material_override = _make_preview_material(preview_color)
	add_child(preview)


func _make_preview_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat
