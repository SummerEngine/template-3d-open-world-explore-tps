# Third-Person Adventure Asset Manifest

asset name | source url | license | imported res:// path | imported yes/no | notes
---|---|---|---|---|---
player_robot.fbx | local provided action-adventure robot pack | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/player_robot.fbx` | yes | Local test copy renamed to neutral project path.
player_robot_base_color.png | local provided `/Users/marcos/Downloads/robot/textures` source texture | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/textures/player_robot_base_color.png` | yes | Imported robot albedo texture, renamed to neutral project path.
player_robot_normal.png | local provided `/Users/marcos/Downloads/robot/textures` source texture | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/textures/player_robot_normal.png` | yes | Imported robot normal map, renamed to neutral project path.
player_robot_metallic.png | local provided `/Users/marcos/Downloads/robot/textures` source texture | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/textures/player_robot_metallic.png` | yes | Imported robot metallic map, renamed to neutral project path.
player_robot_roughness.png | local provided `/Users/marcos/Downloads/robot/textures` source texture | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/textures/player_robot_roughness.png` | yes | Imported robot roughness map, renamed to neutral project path.
player_robot_ao.png | local provided `/Users/marcos/Downloads/robot/textures` source texture | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/textures/player_robot_ao.png` | yes | Imported robot ambient-occlusion map, renamed to neutral project path.
player_robot_material.tres | generated from local robot texture set | same as texture set TODO | `res://assets/third_person_adventure/characters/player_robot/materials/player_robot_material.tres` | yes | StandardMaterial3D assigned through `adventure_model_material_applier.gd` on player and NPC `SkinPivot` nodes.
player_robot_idle.fbx | local provided action-adventure robot pack, standing breathing idle candidate | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/player_robot_idle.fbx` | yes | Second idle candidate from the pack. Used for default upright standing `Idle`; head/neck tracks are also held still by the animator.
player_robot_long_idle.fbx | local provided action-adventure robot pack, expressive idle candidate | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/player_robot_long_idle.fbx` | yes | Original expressive looking-around idle used only for delayed `LongIdle` after 10 seconds.
player_robot_walk.fbx | local provided action-adventure robot pack | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/player_robot_walk.fbx` | yes | Source import animation is duplicated into neutral `Walk` state.
player_robot_run.fbx | local provided action-adventure robot pack | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/player_robot_run.fbx` | yes | Source import animation is duplicated into neutral `Run` state.
player_robot_jump.fbx | local provided action-adventure robot pack | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/player_robot_jump.fbx` | yes | Source import animation is duplicated into neutral `Jump` state.
player_robot_fall.fbx | local provided action-adventure robot pack | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/player_robot_fall.fbx` | yes | Source import animation is duplicated into neutral `Fall` state.
player_robot_land.fbx | local provided action-adventure robot pack | TODO: verify before publishing | `res://assets/third_person_adventure/characters/player_robot/player_robot_land.fbx` | yes | Source import animation is duplicated into neutral `Land` state.
npc_robot temporary instance | same as local provided action-adventure robot pack | same as player robot TODO | `NPCs/ScoutRobotNPC/SkinPivot/npc_robot` | yes | Reuses `player_robot.fbx` as a second scene instance; `npc_uses_player_robot_assets: true`.
npc_robot idle/long-idle/walk/run clips | same as local provided action-adventure robot pack | same as player robot TODO | `player_robot_idle.fbx`, `player_robot_long_idle.fbx`, `player_robot_walk.fbx`, `player_robot_run.fbx` | yes | Reuses player robot locomotion clips for temporary NPC patrol. Short `Idle` is calm; full `LongIdle` plays after 10 seconds.
abandoned_farmhouse.glb | local provided farmhouse GLB | TODO: verify before publishing | `res://assets/third_person_adventure/environment/structures/abandoned_farmhouse.glb` | yes | Preprocessed to optimized GLB with neutral internal nodes and viewport/basic materials.
wasteland_barbed_fence.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_barbed_fence.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.
wasteland_blue_barrel.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_blue_barrel.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.
wasteland_concrete_slab.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_concrete_slab.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.
wasteland_corrugated_fence.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_corrugated_fence.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.
wasteland_dry_grass.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_dry_grass.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.
wasteland_modular_fence.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_modular_fence.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.
wasteland_pebble_large.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_pebble_large.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.
wasteland_pebble_small.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_pebble_small.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.
wasteland_red_barrel.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_red_barrel.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.
wasteland_shed.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_shed.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.
wasteland_utility_light.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_utility_light.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.
wasteland_worn_tire.glb | local provided wasteland prop pack | TODO: verify before publishing | `res://assets/third_person_adventure/environment/wasteland_props/wasteland_worn_tire.glb` | yes | Split from multi-object prop pack, sanitized, imported one file at a time.

player_model_node: `Player/SkinPivot/player_robot`
player_model_transform: position `Vector3(0, 0, 0)`, rotation_degrees `Vector3(0, 180, 0)`, scale `Vector3(1, 1, 1)`
player_material_path: `res://assets/third_person_adventure/characters/player_robot/materials/player_robot_material.tres`
player_texture_paths: `res://assets/third_person_adventure/characters/player_robot/textures/player_robot_base_color.png`, `player_robot_normal.png`, `player_robot_metallic.png`, `player_robot_roughness.png`, `player_robot_ao.png`
player_animation_player_path: `Player/SkinPivot/player_robot/AnimationPlayer`
player_skeleton_path: `Player/SkinPivot/player_robot/Skeleton3D`

npc_model_node: `NPCs/ScoutRobotNPC/SkinPivot/npc_robot`
npc_model_transform: position `Vector3(0, 0, 0)`, rotation_degrees `Vector3(0, 180, 0)`, scale `Vector3(1, 1, 1)`
npc_uses_player_robot_assets: `true`
npc_material_path: `res://assets/third_person_adventure/characters/player_robot/materials/player_robot_material.tres`
npc_animation_player_path: `NPCs/ScoutRobotNPC/SkinPivot/npc_robot/AnimationPlayer`
npc_skeleton_path: `NPCs/ScoutRobotNPC/SkinPivot/npc_robot/Skeleton3D`

idle_clip_name: `Idle`
long_idle_clip_name: `LongIdle`
long_idle_delay_seconds: `10.0`
short_idle_still_track_filters: `head`, `neck`
walk_clip_name: `Walk`
run_clip_name: `Run`
jump_clip_name: `Jump`
fall_clip_name: `Fall`
land_clip_name: `Land`

sky_environment_settings:
- `background_mode`: `Environment.BG_SKY`
- `sky_material`: `PhysicalSkyMaterial`
- `rayleigh_coefficient`: `2.35`
- `rayleigh_color`: `Color(0.31, 0.44, 0.72, 1)`
- `mie_coefficient`: `0.006`
- `mie_eccentricity`: `0.82`
- `mie_color`: `Color(0.86, 0.79, 0.66, 1)`
- `turbidity`: `4.2`
- `sun_disk_scale`: `1.7`
- `ground_color`: `Color(0.28, 0.25, 0.18, 1)`
- `sky_energy_multiplier`: `1.08`
- `ambient_light_source`: `Environment.AMBIENT_SOURCE_SKY`
- `ambient_light_color`: `Color(0.78, 0.86, 0.96, 1)`
- `ambient_light_energy`: `1.08`
- `fog_enabled`: `true`
- `fog_light_color`: `Color(0.82, 0.9, 0.98, 1)`
- `fog_density`: `0.0045`

sun_light_settings:
- `node`: `World/Sun`
- `type`: `DirectionalLight3D`
- `rotation_degrees`: `Vector3(-52, -35, 0)`
- `light_color`: `Color(1.0, 0.93, 0.82, 1)`
- `light_energy`: `3.8`
- `shadow_enabled`: `true`
- `shadow_opacity`: `0.72`

fill_light_settings:
- `node`: `World/FillLight`
- `type`: `DirectionalLight3D`
- `rotation_degrees`: `Vector3(-28, 130, 0)`
- `light_color`: `Color(0.68, 0.78, 1.0, 1)`
- `light_energy`: `0.65`
- `shadow_enabled`: `false`

terrain_features:
- `Level/TerrainRoot/Features/ScoutCampFlatPad`
- `Level/TerrainRoot/Features/RelicClearingFlatPad`
- `Level/TerrainRoot/Features/StarterHomesteadFlatPad`

terrain_feature_notes:
- Default roads are removed for this pass.
- `TerrainFlatPad.show_preview` is false, so no `FlatPadPreview` planes are visible above the generated terrain.
- No `RoadPreview` mesh is present.

environment_prop_paths:
- `Level/EnvironmentProps/AbandonedFarmhouse` -> `res://assets/third_person_adventure/environment/structures/abandoned_farmhouse.glb`
- `Level/EnvironmentProps/WastelandShed` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_shed.glb`
- `Level/EnvironmentProps/WastelandCorrugatedFenceA` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_corrugated_fence.glb`
- `Level/EnvironmentProps/WastelandBarbedFenceA` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_barbed_fence.glb`
- `Level/EnvironmentProps/WastelandModularFenceA` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_modular_fence.glb`
- `Level/EnvironmentProps/WastelandBlueBarrel` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_blue_barrel.glb`
- `Level/EnvironmentProps/WastelandRedBarrel` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_red_barrel.glb`
- `Level/EnvironmentProps/WastelandConcreteSlab` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_concrete_slab.glb`
- `Level/EnvironmentProps/WastelandUtilityLight` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_utility_light.glb`
- `Level/EnvironmentProps/WastelandWornTire` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_worn_tire.glb`
- `Level/EnvironmentProps/WastelandPebbleLarge` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_pebble_large.glb`
- `Level/EnvironmentProps/WastelandPebbleSmall` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_pebble_small.glb`
- `Level/EnvironmentProps/WastelandDryGrass` -> `res://assets/third_person_adventure/environment/wasteland_props/wasteland_dry_grass.glb`

environment_prop_transforms:
- `AbandonedFarmhouse`: position `Vector3(-16, 4, 14.5)`, rotation_degrees.y `-82`, scale `Vector3(2.7, 2.7, 2.7)`, script `adventure_environment_prop_setup.gd`, material_profile `farmhouse`, generate_mesh_collision `true`
- `WastelandShed`: position `Vector3(-5.6, 4, 18.2)`, rotation_degrees.y `-18`, scale `Vector3(8, 8, 8)`, script `adventure_environment_prop_setup.gd`, material_profile `shed`, generate_mesh_collision `true`
- `WastelandCorrugatedFenceA`: position `Vector3(-6, 4, 9.2)`, rotation_degrees.y `72`, scale `Vector3(4.4, 4.4, 4.4)`
- `WastelandBarbedFenceA`: position `Vector3(-13, 4, 4.8)`, rotation_degrees.y `92`, scale `Vector3(4.2, 4.2, 4.2)`
- `WastelandModularFenceA`: position `Vector3(-19, 4, 6.2)`, rotation_degrees.y `88`, scale `Vector3(4.2, 4.2, 4.2)`
- `WastelandBlueBarrel`: position `Vector3(-8, 4, 15.6)`, rotation_degrees.y `16`, scale `Vector3(4.7, 4.7, 4.7)`
- `WastelandRedBarrel`: position `Vector3(-9.2, 4, 16.8)`, rotation_degrees.y `-28`, scale `Vector3(4.7, 4.7, 4.7)`
- `WastelandConcreteSlab`: position `Vector3(-10.8, 4, 11.2)`, rotation_degrees.y `30`, scale `Vector3(5.2, 5.2, 5.2)`
- `WastelandUtilityLight`: position `Vector3(-7.4, 4, 12.8)`, rotation_degrees.y `0`, scale `Vector3(5, 5, 5)`
- `WastelandWornTire`: position `Vector3(-11.8, 4, 17)`, rotation_degrees.y `52`, scale `Vector3(5, 5, 5)`
- `WastelandPebbleLarge`: position `Vector3(-4.6, 4, 14.6)`, rotation_degrees.y `0`, scale `Vector3(12, 12, 12)`
- `WastelandPebbleSmall`: position `Vector3(-3.8, 4, 11.4)`, rotation_degrees.y `0`, scale `Vector3(5, 5, 5)`
- `WastelandDryGrass`: position `Vector3(-6.8, 4, 10.6)`, rotation_degrees.y `0`, scale `Vector3(8, 8, 8)`

environment_preprocessing_notes:
- Original texture-heavy GLBs were converted to lightweight prepared GLBs before Summer import.
- The wasteland pack was split into individual files before placement.
- Internal object, mesh, and material names were sanitized so raw source-pack names do not appear in the runtime scene tree.
- Official public use still needs final source URLs, licenses, and credits for every environment prop.
