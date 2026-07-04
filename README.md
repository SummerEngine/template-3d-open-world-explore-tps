# 3D Open World Explore TPS Template

A third-person adventure starter template for Summer Engine/Godot projects. It gives you a small playable open-world slice with a controllable character, orbit camera, terrain, environmental props, a patrolling NPC, interaction prompts, a simple quest/relic pickup flow, and a lightweight inventory HUD.

Use it as a foundation for exploration games, action-adventure prototypes, survival-lite worlds, quest hubs, or any project that needs a ready third-person movement and interaction baseline.

## What's Included

- Third-person character controller with walking, sprinting, jumping, coyote time, and jump buffering.
- Mouse/gamepad orbit camera with spring-arm collision.
- Terrain generation helpers and placed open-world landmarks.
- Interactable NPC and collectible relic examples.
- HUD with interaction prompts, mission/status text, and inventory overlay.
- Robot character mesh, locomotion animation clips, and environment prop assets.
- Utility scripts for rebuilding, inspecting, and verifying scene pieces.

## Controls

| Action | Keyboard / Mouse |
| --- | --- |
| Move | `W` `A` `S` `D` |
| Look / orbit camera | Mouse movement |
| Sprint | `Shift` |
| Jump | `Space` |
| Interact | `E` |
| Inventory | `I` |
| Release mouse | `Esc` |
| Recapture mouse | Click in the game window |

Gamepad camera orbit is wired to the right stick through the `camera_left`, `camera_right`, `camera_up`, and `camera_down` input actions.

## Building On It

Start from `scenes/main.tscn` and the gameplay scripts in `scripts/`. The main extension points are:

- `scripts/third_person_controller.gd` for movement, jumping, sprinting, and interaction behavior.
- `scripts/third_person_camera.gd` for camera feel, follow distance, pitch limits, and sensitivity.
- `scripts/adventure_interactable.gd` and `scripts/adventure_collectible.gd` for adding new interactable objects.
- `scripts/adventure_quest_state.gd` for expanding the sample NPC/relic quest.
- `scripts/adventure_hud.gd` for mission text, inventory UI, prompts, and tooltip presentation.
- `tools/build_main_scene.gd` for regenerating the main scene structure after changing template content.

Asset source and license notes live in `asset_manifest/third_person_adventure_assets.md`; review and complete those notes before shipping a public game built from this template.
