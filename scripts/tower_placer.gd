extends Node2D

## Fluxo: jogador clica num ícone de torre (canto superior direito) -> entra
## em "modo colocação" -> um preview (tile + alcance) segue o mouse -> clique
## esquerdo no mapa instancia a torre ali (se tiver ouro e o tile tiver livre).
## Clique direito ou Esc cancela a colocação.

@export var tower_options: Array[TowerData] = []
@export var tile_map: TileMapLayer  # arraste o TileMapLayer do mapa aqui

const BUTTON_SIZE := 56
const DEFAULT_TOWER_DATA_PATH := "res://resources/tower_data_basic.tres"

var _tile_size: Vector2
var _occupied_tiles: Dictionary = {}  # Vector2i -> true

var _selected_tower: TowerData = null
var _selected_cost: int = 0
var _selected_range: float = 0.0

var _preview: TowerPlacementPreview
var _ui_layer: CanvasLayer


func _ready() -> void:
	_tile_size = tile_map.tile_set.tile_size if tile_map and tile_map.tile_set else Vector2(16, 16)

	if tower_options.is_empty():
		var default_data: TowerData = load(DEFAULT_TOWER_DATA_PATH)
		if default_data:
			tower_options.append(default_data)

	_build_ui()
	_build_preview()


# ==== UI (ícones de torre no canto superior direito) ====
func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	var container := HBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	container.offset_top = 12
	container.offset_right = -12
	container.add_theme_constant_override("separation", 8)
	_ui_layer.add_child(container)

	for data in tower_options:
		container.add_child(_create_tower_button(data))


func _create_tower_button(data: TowerData) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = data.icon
	button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.tooltip_text = data.display_name
	button.pressed.connect(_on_tower_button_pressed.bind(data))
	return button


func _on_tower_button_pressed(data: TowerData) -> void:
	if _selected_tower == data:
		_cancel_placement()
		return

	# instancia só pra ler cost/attack_range da torre real (fonte única da
	# verdade fica no script da torre, não duplicada aqui)
	var temp: Node = data.scene.instantiate()
	_selected_cost = temp.cost if "cost" in temp else 0
	_selected_range = temp.attack_range if "attack_range" in temp else 0.0
	temp.free()

	_selected_tower = data
	_preview.range_radius = _selected_range
	_preview.visible = true
	_update_preview_position()


func _cancel_placement() -> void:
	_selected_tower = null
	_preview.visible = false


# ==== Preview (tile highlight + alcance seguindo o mouse) ====
func _build_preview() -> void:
	_preview = TowerPlacementPreview.new()
	_preview.tile_size = _tile_size
	_preview.visible = false
	add_child(_preview)


func _update_preview_position() -> void:
	var tile_coord := _world_to_tile(get_global_mouse_position())
	_preview.global_position = _tile_to_world_center(tile_coord)
	_preview.is_valid = not _occupied_tiles.has(tile_coord)


# ==== Input ====
func _unhandled_input(event: InputEvent) -> void:
	if _selected_tower == null:
		return

	if event is InputEventMouseMotion:
		_update_preview_position()
	elif event.is_action_pressed("ui_cancel"):
		_cancel_placement()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_tower()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_placement()


func _try_place_tower() -> void:
	var tile_coord := _world_to_tile(get_global_mouse_position())

	if _occupied_tiles.has(tile_coord):
		return  # já tem torre nesse tile

	if not Game.spend_gold(_selected_cost):
		return  # ouro insuficiente

	var tower: Node2D = _selected_tower.scene.instantiate()
	get_tree().current_scene.add_child(tower)
	tower.global_position = _tile_to_world_center(tile_coord)

	_occupied_tiles[tile_coord] = true
	_cancel_placement()


# ==== Conversão mundo <-> grid do tilemap ====
func _world_to_tile(world_pos: Vector2) -> Vector2i:
	if tile_map:
		return tile_map.local_to_map(tile_map.to_local(world_pos))
	return Vector2i(floori(world_pos.x / _tile_size.x), floori(world_pos.y / _tile_size.y))


func _tile_to_world_center(tile_coord: Vector2i) -> Vector2:
	if tile_map:
		return tile_map.to_global(tile_map.map_to_local(tile_coord))
	return Vector2(tile_coord) * _tile_size + _tile_size / 2.0
