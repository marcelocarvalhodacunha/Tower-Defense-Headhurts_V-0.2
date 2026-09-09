extends CharacterBody2D
class_name Enemy

# ==== Sinais ====
signal died(enemy: Enemy)
signal reached_end(enemy: Enemy)
signal health_changed(current: int, max: int)

# ==== Atributos exportados (sobrescreva nos valores da cena herdada) ====
@export var max_health: int = 10
@export var speed: float = 80.0
@export var damage: int = 1        # dano causado à base/vida do jogador ao chegar no fim
@export var gold_reward: int = 5
@export var armor: int = 0         # reduz dano recebido, opcional

# ==== Estado interno ====
var current_health: int
var is_dead: bool = false
var has_reached_end: bool = false
var path_follow: PathFollow2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
# Se você tiver uma barra de vida, descomente e ajuste o path:
# @onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	current_health = max_health
	# Só agora o nó já está na árvore, então get_parent() funciona de verdade
	# (pegar isso no topo da classe sempre retornava null).
	path_follow = get_parent() as PathFollow2D
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	if is_dead or has_reached_end:
		return
	_move_along_path(delta)


# Renomeado de "_process" pra "_move_along_path": o nome "_process" é
# reservado pela engine e ela chamava esse método sozinha todo frame,
# então o inimigo andava rápido demais (dobro da velocidade real).
func _move_along_path(delta: float) -> void:
	if not is_instance_valid(path_follow):
		return

	path_follow.progress += speed * delta
	if path_follow.progress_ratio >= 1.0:
		_on_reached_end()


func take_damage(amount: int) -> void:
	if is_dead or has_reached_end:
		return

	var final_damage: int = max(amount - armor, 0)
	current_health -= final_damage
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		_die()


func _die() -> void:
	if is_dead or has_reached_end:
		return
	is_dead = true
	died.emit(self)
	_on_death()  # hook para cenas herdadas sobrescreverem (efeitos, drops, etc.)
	_free_self()


func _on_reached_end() -> void:
	if is_dead or has_reached_end:
		return
	has_reached_end = true
	reached_end.emit(self)
	_free_self()


func _free_self() -> void:
	# Liberar o PathFollow2D já libera o inimigo junto (ele é filho dele).
	if is_instance_valid(path_follow):
		path_follow.queue_free()
	else:
		queue_free()


# ==== Hooks virtuais para as cenas herdadas sobrescreverem ====
# Ex: numa cena herdada, você pode fazer:
#     func _on_death() -> void:
#         super._on_death()
#         spawn_particulas_de_morte()
func _on_death() -> void:
	pass
