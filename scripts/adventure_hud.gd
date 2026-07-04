extends CanvasLayer
class_name AdventureHUD

@export var mission_panel_path: NodePath = ^"Root/MissionPanel"
@export var mission_title_label_path: NodePath = ^"Root/MissionPanel/Margin/VBox/TitleLabel"
@export var objective_label_path: NodePath = ^"Root/MissionPanel/Margin/VBox/ObjectiveLabel"
@export var interaction_prompt_path: NodePath = ^"Root/InteractionPrompt"
@export var interaction_prompt_label_path: NodePath = ^"Root/InteractionPrompt/PromptLabel"
@export var status_prompt_path: NodePath = ^"Root/StatusPrompt"
@export var status_prompt_label_path: NodePath = ^"Root/StatusPrompt/StatusLabel"
@export var inventory_overlay_path: NodePath = ^"Root/InventoryOverlay"
@export var inventory_panel_path: NodePath = ^"Root/InventoryOverlay/InventoryPanel"
@export var inventory_grid_path: NodePath = ^"Root/InventoryOverlay/InventoryPanel/Margin/VBox/Scroll/ItemGrid"
@export var tooltip_path: NodePath = ^"Root/ItemTooltip"
@export var inventory_path: NodePath = ^"../Inventory"
@export var input_reader_path: NodePath = ^"../InputReader"
@export var prompt_bottom_offset: float = 84.0
@export var inventory_width_ratio: float = 0.8
@export var inventory_height_ratio: float = 0.9
@export var mission_panel_width_ratio: float = 0.34
@export var mission_panel_min_width: float = 280.0
@export var mission_panel_max_width: float = 440.0

@onready var root: Control = get_node_or_null(^"Root") as Control
@onready var mission_panel: PanelContainer = get_node_or_null(mission_panel_path) as PanelContainer
@onready var mission_title_label: Label = get_node_or_null(mission_title_label_path) as Label
@onready var objective_label: Label = get_node_or_null(objective_label_path) as Label
@onready var interaction_prompt: PanelContainer = get_node_or_null(interaction_prompt_path) as PanelContainer
@onready var interaction_prompt_label: Label = get_node_or_null(interaction_prompt_label_path) as Label
@onready var status_prompt: PanelContainer = get_node_or_null(status_prompt_path) as PanelContainer
@onready var status_prompt_label: Label = get_node_or_null(status_prompt_label_path) as Label
@onready var inventory_overlay: Control = get_node_or_null(inventory_overlay_path) as Control
@onready var inventory_panel: PanelContainer = get_node_or_null(inventory_panel_path) as PanelContainer
@onready var inventory_grid: GridContainer = get_node_or_null(inventory_grid_path) as GridContainer
@onready var tooltip: PanelContainer = get_node_or_null(tooltip_path) as PanelContainer
@onready var inventory: Node = get_node_or_null(inventory_path)
@onready var input_reader: Node = get_node_or_null(input_reader_path)

var _status_prompt_token: int = 0
var _last_viewport_size: Vector2i = Vector2i.ZERO
var _tooltip_title: Label
var _tooltip_description: Label
var _empty_inventory_label: Label
var _inventory_count_label: Label


func _ready() -> void:
	root = _ensure_root()
	mission_panel = _ensure_mission_panel()
	mission_title_label = _ensure_mission_title_label()
	objective_label = _ensure_objective_label()
	interaction_prompt = _ensure_interaction_prompt()
	interaction_prompt_label = interaction_prompt.get_node("PromptLabel") as Label
	status_prompt = _ensure_status_prompt()
	status_prompt_label = status_prompt.get_node("StatusLabel") as Label
	inventory_overlay = _ensure_inventory_overlay()
	inventory_panel = inventory_overlay.get_node("InventoryPanel") as PanelContainer
	inventory_grid = inventory_panel.get_node("Margin/VBox/Scroll/ItemGrid") as GridContainer
	tooltip = _ensure_tooltip()
	_hide_legacy_prompt_label()

	if inventory != null and inventory.has_signal("inventory_changed"):
		inventory.connect("inventory_changed", Callable(self, "_refresh_inventory"))

	set_objective("Talk to the scout.")
	clear_prompt()
	clear_interaction_prompt()
	_refresh_inventory()
	close_inventory(false)
	_on_viewport_resized()


func _process(_delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var viewport_size_i := Vector2i(int(viewport_size.x), int(viewport_size.y))
	if viewport_size_i != _last_viewport_size:
		_last_viewport_size = viewport_size_i
		_on_viewport_resized()
	if tooltip != null and tooltip.visible:
		_position_tooltip()


func _input(event: InputEvent) -> void:
	if is_inventory_open() and event.is_action_pressed(&"ui_cancel"):
		close_inventory()
		get_viewport().set_input_as_handled()


func set_objective(text: String) -> void:
	if objective_label != null:
		objective_label.text = text


func show_prompt(text: String, duration: float = 0.0) -> void:
	if status_prompt == null or status_prompt_label == null:
		return
	_status_prompt_token += 1
	status_prompt_label.text = text
	status_prompt.visible = not is_inventory_open()
	if duration > 0.0:
		var token := _status_prompt_token
		var timer := get_tree().create_timer(duration)
		timer.timeout.connect(_clear_prompt_if_current.bind(token), CONNECT_ONE_SHOT)


func clear_prompt() -> void:
	_status_prompt_token += 1
	if status_prompt_label != null:
		status_prompt_label.text = ""
	if status_prompt != null:
		status_prompt.visible = false


func show_interaction_prompt(text: String) -> void:
	if interaction_prompt == null or interaction_prompt_label == null:
		return
	interaction_prompt_label.text = text
	interaction_prompt.visible = not is_inventory_open()


func clear_interaction_prompt() -> void:
	if interaction_prompt_label != null:
		interaction_prompt_label.text = ""
	if interaction_prompt != null:
		interaction_prompt.visible = false


func toggle_inventory() -> void:
	if is_inventory_open():
		close_inventory()
	else:
		open_inventory()


func open_inventory() -> void:
	if inventory_overlay == null:
		return
	_refresh_inventory()
	inventory_overlay.visible = true
	clear_interaction_prompt()
	if status_prompt != null:
		status_prompt.visible = false
	if input_reader != null:
		input_reader.set("recapture_on_mouse_button", false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_on_viewport_resized()


func close_inventory(recapture_mouse: bool = true) -> void:
	if inventory_overlay != null:
		inventory_overlay.visible = false
	_hide_tooltip()
	if input_reader != null:
		input_reader.set("recapture_on_mouse_button", true)
	if recapture_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_inventory_open() -> bool:
	return inventory_overlay != null and inventory_overlay.visible


func _clear_prompt_if_current(token: int) -> void:
	if token == _status_prompt_token:
		clear_prompt()


func _ensure_root() -> Control:
	var existing := get_node_or_null(^"Root") as Control
	if existing != null:
		existing.set_anchors_preset(Control.PRESET_FULL_RECT)
		existing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return existing

	var created := Control.new()
	created.name = "Root"
	created.set_anchors_preset(Control.PRESET_FULL_RECT)
	created.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(created)
	return created


func _ensure_mission_panel() -> PanelContainer:
	var existing := get_node_or_null(mission_panel_path) as PanelContainer
	if existing != null:
		_style_mission_panel(existing)
		return existing

	var panel := PanelContainer.new()
	panel.name = "MissionPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.045, 0.05, 0.055, 0.78), 8.0, Color(1, 1, 1, 0.14), 1))
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 11)
	margin.add_theme_constant_override("margin_bottom", 13)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_style_mission_panel(panel)
	return panel


func _ensure_mission_title_label() -> Label:
	var existing := get_node_or_null(mission_title_label_path) as Label
	if existing != null:
		_style_mission_title_label(existing)
		return existing

	var label := Label.new()
	label.name = "TitleLabel"
	label.text = "MISSION"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_get_mission_vbox().add_child(label)
	_style_mission_title_label(label)
	return label


func _ensure_objective_label() -> Label:
	var existing := get_node_or_null(objective_label_path) as Label
	if existing != null:
		_style_objective_label(existing)
		return existing

	var legacy := get_node_or_null(^"Root/ObjectiveLabel") as Label
	if legacy != null:
		var legacy_parent := legacy.get_parent()
		if legacy_parent != null:
			legacy_parent.remove_child(legacy)
		legacy.name = "ObjectiveLabel"
		_get_mission_vbox().add_child(legacy)
		_style_objective_label(legacy)
		return legacy

	var label := Label.new()
	label.name = "ObjectiveLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_get_mission_vbox().add_child(label)
	_style_objective_label(label)
	return label


func _get_mission_vbox() -> VBoxContainer:
	var vbox := mission_panel.get_node_or_null("Margin/VBox") as VBoxContainer
	if vbox != null:
		return vbox

	var margin := mission_panel.get_node_or_null("Margin") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "Margin"
		mission_panel.add_child(margin)

	vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	return vbox


func _ensure_interaction_prompt() -> PanelContainer:
	var existing := get_node_or_null(interaction_prompt_path) as PanelContainer
	if existing != null:
		_style_prompt_bubble(existing)
		return existing

	var bubble := PanelContainer.new()
	bubble.name = "InteractionPrompt"
	bubble.custom_minimum_size = Vector2(180.0, 46.0)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bubble)
	_style_prompt_bubble(bubble)

	var label := Label.new()
	label.name = "PromptLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_font_size_override("font_size", 20)
	bubble.add_child(label)
	return bubble


func _ensure_status_prompt() -> PanelContainer:
	var existing := get_node_or_null(status_prompt_path) as PanelContainer
	if existing != null:
		_style_prompt_bubble(existing)
		return existing

	var bubble := PanelContainer.new()
	bubble.name = "StatusPrompt"
	bubble.custom_minimum_size = Vector2(360.0, 46.0)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bubble)
	_style_prompt_bubble(bubble)

	var label := Label.new()
	label.name = "StatusLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_font_size_override("font_size", 18)
	bubble.add_child(label)
	return bubble


func _ensure_inventory_overlay() -> Control:
	var existing := get_node_or_null(inventory_overlay_path) as Control
	if existing != null:
		return existing

	var overlay := Control.new()
	overlay.name = "InventoryOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.42)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.06, 0.065, 0.07, 0.88), 10.0, Color(1, 1, 1, 0.18), 1))
	overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var title := Label.new()
	title.name = "Title"
	title.text = "Inventory"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)

	_inventory_count_label = Label.new()
	_inventory_count_label.name = "Count"
	_inventory_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_inventory_count_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.74))
	_inventory_count_label.add_theme_font_size_override("font_size", 18)
	header.add_child(_inventory_count_label)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "ItemGrid"
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	_empty_inventory_label = Label.new()
	_empty_inventory_label.name = "EmptyInventoryLabel"
	_empty_inventory_label.text = "No items"
	_empty_inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_inventory_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.62))
	_empty_inventory_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_empty_inventory_label)

	return overlay


func _ensure_tooltip() -> PanelContainer:
	var existing := get_node_or_null(tooltip_path) as PanelContainer
	if existing != null:
		return existing

	var panel := PanelContainer.new()
	panel.name = "ItemTooltip"
	panel.visible = false
	panel.custom_minimum_size = Vector2(260.0, 82.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.03, 0.035, 0.04, 0.9), 8.0, Color(1, 1, 1, 0.2), 1))
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_tooltip_title = Label.new()
	_tooltip_title.name = "Title"
	_tooltip_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_tooltip_title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_tooltip_title)

	_tooltip_description = Label.new()
	_tooltip_description.name = "Description"
	_tooltip_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_description.add_theme_color_override("font_color", Color(1, 1, 1, 0.78))
	_tooltip_description.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_tooltip_description)
	return panel


func _style_objective_label(label: Label) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 18)


func _style_mission_panel(panel: PanelContainer) -> void:
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.045, 0.05, 0.055, 0.78), 8.0, Color(1, 1, 1, 0.14), 1))


func _style_mission_title_label(label: Label) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0, 0.9))
	label.add_theme_font_size_override("font_size", 13)


func _style_prompt_bubble(bubble: PanelContainer) -> void:
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_theme_stylebox_override("panel", _make_style(Color(0.04, 0.045, 0.05, 0.78), 8.0, Color(1, 1, 1, 0.16), 1))


func _make_style(bg_color: Color, corner_radius: float, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = int(corner_radius)
	style.corner_radius_top_right = int(corner_radius)
	style.corner_radius_bottom_left = int(corner_radius)
	style.corner_radius_bottom_right = int(corner_radius)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	return style


func _refresh_inventory() -> void:
	if inventory_grid == null:
		return

	for child in inventory_grid.get_children():
		child.queue_free()

	var items := _get_inventory_items()
	if _inventory_count_label != null:
		_inventory_count_label.text = "%d item%s" % [items.size(), "" if items.size() == 1 else "s"]
	if _empty_inventory_label != null:
		_empty_inventory_label.visible = items.is_empty()

	for item in items:
		inventory_grid.add_child(_create_item_card(item))

	_update_inventory_columns()


func _get_inventory_items() -> Array[Dictionary]:
	var typed_items: Array[Dictionary] = []
	if inventory == null or not inventory.has_method("get_items"):
		return typed_items

	var raw_items: Array = inventory.call("get_items")
	for item in raw_items:
		if item is Dictionary:
			typed_items.append(item)
	return typed_items


func _create_item_card(item: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = _safe_node_name(str(item.get("display_name", "Item")))
	card.custom_minimum_size = Vector2(120.0, 132.0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _make_style(Color(0.12, 0.13, 0.14, 0.86), 7.0, Color(1, 1, 1, 0.14), 1))
	card.mouse_entered.connect(_show_item_tooltip.bind(item))
	card.mouse_exited.connect(_hide_tooltip)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var icon := PanelContainer.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(72.0, 72.0)
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.add_theme_stylebox_override("panel", _make_style(Color(0.16, 0.38, 0.42, 0.92), 6.0, Color(1, 1, 1, 0.12), 1))
	vbox.add_child(icon)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = str(item.get("display_name", "Item"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_text = true
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)

	return card


func _show_item_tooltip(item: Dictionary) -> void:
	if tooltip == null:
		return
	if _tooltip_title == null:
		_tooltip_title = tooltip.get_node("Margin/VBox/Title") as Label
	if _tooltip_description == null:
		_tooltip_description = tooltip.get_node("Margin/VBox/Description") as Label

	_tooltip_title.text = str(item.get("display_name", "Item"))
	_tooltip_description.text = str(item.get("description", ""))
	tooltip.visible = true
	_position_tooltip()


func _hide_tooltip() -> void:
	if tooltip != null:
		tooltip.visible = false


func _position_tooltip() -> void:
	if tooltip == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var target_size := Vector2(280.0, max(tooltip.custom_minimum_size.y, tooltip.get_combined_minimum_size().y))
	var desired := get_viewport().get_mouse_position() + Vector2(18.0, 18.0)
	desired.x = clamp(desired.x, 12.0, max(12.0, viewport_size.x - target_size.x - 12.0))
	desired.y = clamp(desired.y, 12.0, max(12.0, viewport_size.y - target_size.y - 12.0))
	tooltip.position = desired
	tooltip.size = target_size


func _on_viewport_resized() -> void:
	_resize_mission_panel()
	_position_prompt_bubble(interaction_prompt, prompt_bottom_offset, 230.0)
	_position_prompt_bubble(status_prompt, prompt_bottom_offset + 58.0, 460.0)
	_resize_inventory_panel()
	_update_inventory_columns()


func _resize_mission_panel() -> void:
	if mission_panel == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var smallest_side: float = min(viewport_size.x, viewport_size.y)
	var safe_margin: float = clampf(smallest_side * 0.025, 12.0, 24.0)
	var max_available_width: float = max(120.0, viewport_size.x - safe_margin * 2.0)
	var target_width: float = clampf(
		viewport_size.x * mission_panel_width_ratio,
		mission_panel_min_width,
		mission_panel_max_width
	)
	target_width = min(target_width, max_available_width)

	mission_panel.anchor_left = 0.0
	mission_panel.anchor_right = 0.0
	mission_panel.anchor_top = 0.0
	mission_panel.anchor_bottom = 0.0
	mission_panel.offset_left = safe_margin
	mission_panel.offset_top = safe_margin
	mission_panel.offset_right = safe_margin + target_width
	mission_panel.offset_bottom = safe_margin + max(76.0, mission_panel.get_combined_minimum_size().y)

	var objective_font_size: int = clampi(int(round(smallest_side * 0.024)), 16, 20)
	var title_font_size: int = clampi(objective_font_size - 5, 12, 14)
	if objective_label != null:
		objective_label.add_theme_font_size_override("font_size", objective_font_size)
	if mission_title_label != null:
		mission_title_label.add_theme_font_size_override("font_size", title_font_size)


func _position_prompt_bubble(bubble: Control, bottom_offset: float, width: float) -> void:
	if bubble == null:
		return
	var height: float = max(46.0, bubble.custom_minimum_size.y)
	bubble.anchor_left = 0.5
	bubble.anchor_right = 0.5
	bubble.anchor_top = 1.0
	bubble.anchor_bottom = 1.0
	bubble.offset_left = -width * 0.5
	bubble.offset_right = width * 0.5
	bubble.offset_top = -bottom_offset - height
	bubble.offset_bottom = -bottom_offset


func _resize_inventory_panel() -> void:
	if inventory_panel == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var target_size := Vector2(
		max(320.0, viewport_size.x * inventory_width_ratio),
		max(360.0, viewport_size.y * inventory_height_ratio)
	)
	inventory_panel.size = target_size
	inventory_panel.position = (viewport_size - target_size) * 0.5


func _update_inventory_columns() -> void:
	if inventory_grid == null:
		return
	var viewport_width := get_viewport().get_visible_rect().size.x
	var panel_width: float = max(320.0, viewport_width * inventory_width_ratio)
	var usable_width: float = max(240.0, panel_width - 64.0)
	inventory_grid.columns = clampi(int(floor(usable_width / 132.0)), 2, 6)


func _safe_node_name(value: String) -> String:
	var clean := value.strip_edges().replace(" ", "_")
	if clean.is_empty():
		return "Item"
	return clean.validate_node_name()


func _hide_legacy_prompt_label() -> void:
	var legacy := get_node_or_null(^"Root/PromptLabel") as Label
	if legacy != null:
		legacy.visible = false
