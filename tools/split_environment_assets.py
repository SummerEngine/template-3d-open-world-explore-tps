import os
import re
import sys

import bpy
from mathutils import Vector


FARM_SOURCE = "/Users/marcos/Downloads/low__farm__assembly__dirty__house__poor.glb"
PACK_SOURCE = "/Users/marcos/Downloads/post-apocalyptic_asset_pack.glb"
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ENV_ROOT = os.path.join(PROJECT_ROOT, "assets", "third_person_adventure", "environment")
STRUCTURE_DIR = os.path.join(ENV_ROOT, "structures")
PROP_DIR = os.path.join(ENV_ROOT, "wasteland_props")

POST_PACK_NAMES = {
	"BlueBarrel_LOD2": "wasteland_blue_barrel",
	"BarbedFence_LOD2": "wasteland_barbed_fence",
	"BarbedFenceModular1": "wasteland_modular_fence",
	"RedBarrel_LOD2": "wasteland_red_barrel",
	"Corregated_Fence1": "wasteland_corrugated_fence",
	"Light1": "wasteland_utility_light",
	"Sandy_Pebble1": "wasteland_pebble_large",
	"Shed1": "wasteland_shed",
	"Slab1": "wasteland_concrete_slab",
	"Tyre_LOD2": "wasteland_worn_tire",
	"Wheat_Blade1": "wasteland_dry_grass",
	"Sandy_Pebble2": "wasteland_pebble_small",
}


def reset_scene() -> None:
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete()


def descendants(root: bpy.types.Object) -> list[bpy.types.Object]:
	result = [root]
	stack = list(root.children)
	while stack:
		item = stack.pop()
		result.append(item)
		stack.extend(item.children)
	return result


def mesh_descendants(root: bpy.types.Object) -> list[bpy.types.Object]:
	return [obj for obj in descendants(root) if obj.type == "MESH"]


def world_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
	minimum = Vector((float("inf"), float("inf"), float("inf")))
	maximum = Vector((float("-inf"), float("-inf"), float("-inf")))
	for obj in objects:
		for corner in obj.bound_box:
			point = obj.matrix_world @ Vector(corner)
			minimum.x = min(minimum.x, point.x)
			minimum.y = min(minimum.y, point.y)
			minimum.z = min(minimum.z, point.z)
			maximum.x = max(maximum.x, point.x)
			maximum.y = max(maximum.y, point.y)
			maximum.z = max(maximum.z, point.z)
	return minimum, maximum


def normalize_to_origin(root: bpy.types.Object) -> None:
	meshes = mesh_descendants(root)
	if not meshes:
		return
	minimum, maximum = world_bounds(meshes)
	center_x = (minimum.x + maximum.x) * 0.5
	center_y = (minimum.y + maximum.y) * 0.5
	offset = Vector((center_x, center_y, minimum.z))
	for obj in descendants(root):
		obj.matrix_world.translation -= offset


def sanitize_hierarchy(root: bpy.types.Object, export_name: str) -> None:
	root.name = export_name
	for index, obj in enumerate([item for item in descendants(root) if item != root], start=1):
		clean_object_name = f"{export_name}_part_{index:02d}"
		obj.name = clean_object_name
		if getattr(obj, "data", None) is not None:
			obj.data.name = clean_object_name
		for material_index, material in enumerate(getattr(obj, "material_slots", []), start=1):
			if material.material is not None:
				material.material.name = f"{export_name}_material_{index:02d}_{material_index:02d}"


def select_hierarchy(root: bpy.types.Object) -> None:
	bpy.ops.object.select_all(action="DESELECT")
	for obj in descendants(root):
		obj.select_set(True)
	bpy.context.view_layer.objects.active = root


def export_selected(filepath: str) -> None:
	bpy.ops.export_scene.gltf(
		filepath=filepath,
		export_format="GLB",
		use_selection=True,
		export_apply=True,
		export_yup=True,
		export_materials="VIEWPORT",
		export_image_format="NONE",
	)


def clean_name(name: str) -> str:
	name = re.sub(r"[^A-Za-z0-9_]+", "_", name)
	name = re.sub(r"_+", "_", name)
	return name.strip("_").lower()


def export_farmhouse() -> None:
	reset_scene()
	bpy.ops.import_scene.gltf(filepath=FARM_SOURCE)
	root = bpy.data.objects.new("abandoned_farmhouse", None)
	bpy.context.collection.objects.link(root)
	for obj in list(bpy.context.scene.objects):
		if obj == root:
			continue
		if obj.parent is None:
			obj.parent = root
	normalize_to_origin(root)
	sanitize_hierarchy(root, "abandoned_farmhouse")
	select_hierarchy(root)
	export_selected(os.path.join(STRUCTURE_DIR, "abandoned_farmhouse.glb"))


def find_showcase_root() -> bpy.types.Object:
	for obj in bpy.context.scene.objects:
		if obj.name.startswith("Showcase"):
			return obj
	raise RuntimeError("Could not find Showcase root in post-apocalyptic pack.")


def export_post_pack() -> None:
	reset_scene()
	bpy.ops.import_scene.gltf(filepath=PACK_SOURCE)
	showcase = find_showcase_root()
	for child in sorted(showcase.children, key=lambda item: item.name):
		source_name = child.name.split(".")[0]
		export_name = POST_PACK_NAMES.get(source_name, clean_name(source_name))
		normalize_to_origin(child)
		sanitize_hierarchy(child, export_name)
		select_hierarchy(child)
		export_selected(os.path.join(PROP_DIR, f"{export_name}.glb"))


def main() -> int:
	os.makedirs(STRUCTURE_DIR, exist_ok=True)
	os.makedirs(PROP_DIR, exist_ok=True)
	export_farmhouse()
	export_post_pack()
	return 0


if __name__ == "__main__":
	sys.exit(main())
