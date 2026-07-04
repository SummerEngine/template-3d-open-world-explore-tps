extends RefCounted
class_name AdventureLayers

const WORLD: int = 1
const PLAYER: int = 2
const NPC: int = 4
const INTERACTABLE: int = 8

const PLAYER_MASK: int = WORLD
const NPC_MASK: int = WORLD
const INTERACT_SENSOR_MASK: int = INTERACTABLE
const CAMERA_MASK: int = WORLD
