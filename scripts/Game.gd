extends Node

# ==== Sinais (a HUD e outras cenas escutam esses eventos) ====
signal gold_changed(new_gold: int)
signal base_health_changed(current: int, max: int)
signal base_destroyed

# ==== Configuração inicial ====
@export var starting_gold: int = 150
@export var starting_base_health: int = 20

# ==== Estado atual da partida ====
var gold: int
var base_health: int
var max_base_health: int
var is_game_over: bool = false


func _ready() -> void:
	reset()


# Chame isso ao (re)iniciar uma missão/partida.
func reset() -> void:
	gold = starting_gold
	max_base_health = starting_base_health
	base_health = starting_base_health
	is_game_over = false

	gold_changed.emit(gold)
	base_health_changed.emit(base_health, max_base_health)


# ==== Ouro ====
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func can_afford(amount: int) -> bool:
	return gold >= amount


# Tenta gastar ouro (ex: comprar/upgradar uma torre).
# Retorna true se conseguiu pagar, false se não tinha ouro suficiente.
func spend_gold(amount: int) -> bool:
	if not can_afford(amount):
		return false

	gold -= amount
	gold_changed.emit(gold)
	return true


# ==== Vida da base ====
func damage_base(amount: int) -> void:
	if is_game_over:
		return

	base_health = max(base_health - amount, 0)
	base_health_changed.emit(base_health, max_base_health)

	if base_health <= 0:
		_game_over()


func _game_over() -> void:
	is_game_over = true
	base_destroyed.emit()
	print("GAME OVER — a base caiu!")
