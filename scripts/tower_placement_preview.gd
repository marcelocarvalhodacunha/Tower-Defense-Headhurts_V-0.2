extends Node2D
class_name TowerPlacementPreview

## Segue o mouse enquanto uma torre está selecionada pra colocação.
## Desenha o tile onde ela vai cair (verde = pode colocar, vermelho = não
## pode) e um círculo mostrando o alcance de ataque da torre selecionada.

var range_radius: float = 0.0
var is_valid: bool = true
var tile_size: Vector2 = Vector2(16, 16)

const VALID_COLOR := Color(0.3, 1.0, 0.3, 0.35)
const INVALID_COLOR := Color(1.0, 0.3, 0.3, 0.35)
const RANGE_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.6)
const RANGE_FILL_COLOR := Color(1.0, 1.0, 1.0, 0.08)


func _ready() -> void:
	z_index = 100  # sempre por cima do mapa, torres e inimigos


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var tile_color := VALID_COLOR if is_valid else INVALID_COLOR
	draw_rect(Rect2(-tile_size / 2.0, tile_size), tile_color, true)

	if range_radius > 0.0:
		draw_circle(Vector2.ZERO, range_radius, RANGE_FILL_COLOR)
		draw_arc(Vector2.ZERO, range_radius, 0.0, TAU, 64, RANGE_LINE_COLOR, 2.0, true)
