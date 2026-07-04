extends SceneTree

const MATERIAL_PATH := "res://assets/third_person_adventure/characters/player_robot/materials/player_robot_material.tres"
const BASE_COLOR_TEXTURE := "res://assets/third_person_adventure/characters/player_robot/textures/player_robot_base_color.png"
const NORMAL_TEXTURE := "res://assets/third_person_adventure/characters/player_robot/textures/player_robot_normal.png"
const METALLIC_TEXTURE := "res://assets/third_person_adventure/characters/player_robot/textures/player_robot_metallic.png"
const ROUGHNESS_TEXTURE := "res://assets/third_person_adventure/characters/player_robot/textures/player_robot_roughness.png"
const AO_TEXTURE := "res://assets/third_person_adventure/characters/player_robot/textures/player_robot_ao.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var material := StandardMaterial3D.new()
	material.resource_name = "player_robot_material"
	material.set("albedo_texture", load(BASE_COLOR_TEXTURE))
	material.set("metallic_texture", load(METALLIC_TEXTURE))
	material.set("roughness_texture", load(ROUGHNESS_TEXTURE))
	material.set("normal_enabled", true)
	material.set("normal_texture", load(NORMAL_TEXTURE))
	material.set("ao_enabled", true)
	material.set("ao_texture", load(AO_TEXTURE))
	material.set("metallic", 1.0)
	material.set("roughness", 0.7)

	var err := ResourceSaver.save(material, MATERIAL_PATH)
	if err != OK:
		push_error("Could not save robot material: %s" % err)
		quit(err)
		return

	print("saved ", MATERIAL_PATH)
	quit(OK)
