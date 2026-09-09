extends Node2D
class_name Tower

# ==== Sinais ====
signal target_acquired(target: Enemy)
signal target_lost
signal attacked(target: Enemy)

# ==== Atributos exportados (sobrescreva nos valores da cena herdada) ====
@export var damage: int = 5
@export var attack_range: float = 150.0
@export var attack_speed: float = 1.0     # ataques por segundo
@export var cost: int = 50
@export var projectile_scene: PackedScene # deixe vazio se a torre não atira projétil (ex: dano em área instantâneo)

# ==== Estratégia de alvo ====
enum TargetPriority { FIRST, LAST, CLOSEST, STRONGEST, WEAKEST }
@export var target_priority: TargetPriority = TargetPriority.FIRST

# ==== Estado interno ====
var enemies_in_range: Array[Enemy] = []
var current_target: Enemy = null
var can_attack: bool = true

@onready var base_sprite: Sprite2D = $Base
@onready var turret: AnimatedSprite2D = $Turret
@onready var range_area: Area2D = $EnemyDetectionArea
@onready var range_shape: CollisionShape2D = $EnemyDetectionArea/CollisionShape2D
@onready var attack_timer: Timer = $ReloadTimer


func _ready() -> void:
	_update_range_shape()

	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)

	attack_timer.wait_time = 1.0 / attack_speed
	attack_timer.timeout.connect(_on_reload_timer_timeout)
	attack_timer.start()


func _process(_delta: float) -> void:
	if is_instance_valid(current_target):
		_face_target(current_target)
	else:
		_select_target()


func _update_range_shape() -> void:
	if range_shape.shape is CircleShape2D:
		range_shape.shape.radius = attack_range


# ==== Detecção de inimigos ====
func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		enemies_in_range.append(body)
		body.tree_exiting.connect(_on_enemy_removed.bind(body), CONNECT_ONE_SHOT)
		if current_target == null:
			_select_target()


func _on_body_exited(body: Node2D) -> void:
	if body is Enemy:
		_remove_enemy(body)


func _on_enemy_removed(enemy: Enemy) -> void:
	_remove_enemy(enemy)


func _remove_enemy(enemy: Enemy) -> void:
	enemies_in_range.erase(enemy)
	if current_target == enemy:
		current_target = null
		target_lost.emit()
		_select_target()


# ==== Seleção de alvo ====
func _select_target() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))

	if enemies_in_range.is_empty():
		current_target = null
		return

	match target_priority:
		TargetPriority.FIRST:
			current_target = enemies_in_range[0]
		TargetPriority.LAST:
			current_target = enemies_in_range[-1]
		TargetPriority.CLOSEST:
			current_target = enemies_in_range.reduce(
				func(a, b): return a if global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position) else b
			)
		TargetPriority.STRONGEST:
			current_target = enemies_in_range.reduce(
				func(a, b): return a if a.current_health > b.current_health else b
			)
		TargetPriority.WEAKEST:
			current_target = enemies_in_range.reduce(
				func(a, b): return a if a.current_health < b.current_health else b
			)

	if current_target:
		target_acquired.emit(current_target)


func _face_target(target: Enemy) -> void:
	# só a torreta gira; a base fica fixa apontando pra baixo/padrão
	turret.rotation = (target.global_position - global_position).angle() + 90


# ==== Ataque ====
func _on_reload_timer_timeout() -> void:
	if is_instance_valid(current_target):
		_attack(current_target)


func _attack(target: Enemy) -> void:
	attacked.emit(target)

	if turret.sprite_frames and turret.sprite_frames.has_animation("shoot"):
		turret.play("shoot")

	if projectile_scene:
		_shoot_projectile(target)
	else:
		# torre de dano instantâneo (ex: laser, área) — sobrescreva _apply_direct_damage se precisar
		_apply_direct_damage(target)


func _shoot_projectile(target: Enemy) -> void:
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	if projectile.has_method("launch"):
		projectile.launch(target, damage)


func _apply_direct_damage(target: Enemy) -> void:
	target.take_damage(damage)


# ==== Hooks virtuais para as cenas herdadas sobrescreverem ====
# Ex: numa cena herdada, você pode fazer:
#     func _attack(target: Enemy) -> void:
#         super._attack(target)
#         tocar_efeito_sonoro()
func upgrade() -> void:
	pass
