extends SceneTree

const ROBOT_SCENE := "res://assets/third_person_adventure/characters/player_robot/player_robot.fbx"
const CLIPS := [
	"res://assets/third_person_adventure/characters/player_robot/player_robot_idle.fbx",
	"res://assets/third_person_adventure/characters/player_robot/player_robot_walk.fbx",
	"res://assets/third_person_adventure/characters/player_robot/player_robot_run.fbx",
	"res://assets/third_person_adventure/characters/player_robot/player_robot_jump.fbx",
	"res://assets/third_person_adventure/characters/player_robot/player_robot_fall.fbx",
	"res://assets/third_person_adventure/characters/player_robot/player_robot_land.fbx",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_inspect_scene(ROBOT_SCENE)
	for clip_path in CLIPS:
		_inspect_scene(clip_path)
	quit(OK)


func _inspect_scene(path: String) -> void:
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("Could not load %s" % path)
		return
	var instance := scene.instantiate()
	print("SCENE ", path)
	_walk(instance, 0)
	instance.free()


func _walk(node: Node, depth: int) -> void:
	var prefix := ""
	for _i in range(depth):
		prefix += "  "
	if node is AnimationPlayer:
		var animation_player := node as AnimationPlayer
		print(prefix, node.name, " [AnimationPlayer] animations=", animation_player.get_animation_list())
	elif node is Skeleton3D:
		print(prefix, node.name, " [Skeleton3D]")
	else:
		print(prefix, node.name, " [", node.get_class(), "]")

	for child in node.get_children():
		_walk(child, depth + 1)
