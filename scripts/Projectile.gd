extends Node2D
class_name Projectile

# ==== Sinais ====
signal hit(target: Enemy)

# ==== Atributos exportados (sobrescreva nos valores da cena herdada) ====
@export var speed: float = 400.0
@export var homing: bool = false          # true = persegue o alvo, false = mira na posição inicial do alvo e vai reto
@export var max_travel_distance: float = 900.0  # some sozinho se não acertar ninguém (evita projétil eterno)

# ==== Estado interno ====
var target: Enemy = null
var damage: int = 0
var direction: Vector2 = Vector2.ZERO   # usado quando homing = false
var has_hit: bool = false
var _distance_traveled: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_area: Area2D = $HitArea


func _ready() -> void:
	hit_area.body_entered.connect(_on_hit_area_body_entered)


# Chamado pela torre logo após instanciar o projétil
func launch(p_target: Enemy, p_damage: int) -> void:
	target = p_target
	damage = p_damage

	if is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)
		rotation = direction.angle() + deg_to_rad(90)

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("fly"):
		sprite.play("fly")


func _physics_process(delta: float) -> void:
	if homing and is_instance_valid(target):
		_move_towards_target(delta)
	else:
		_move_straight(delta)

	_distance_traveled += speed * delta
	if _distance_traveled >= max_travel_distance:
		_on_target_lost()  # não acertou ninguém no percurso — some


func _move_towards_target(delta: float) -> void:
	direction = global_position.direction_to(target.global_position)
	rotation = direction.angle() + deg_to_rad(90)
	global_position += direction * speed * delta


func _move_straight(delta: float) -> void:
	# Vai reto na direção calculada em launch(); não precisa mais checar o
	# alvo aqui — o hit por colisão (HitArea) acerta qualquer inimigo que
	# cruzar o caminho, mesmo que o alvo original já tenha morrido.
	global_position += direction * speed * delta


# A Area2D (HitArea) é quem detecta o impacto de verdade agora — muito mais
# confiável que comparar distância manualmente, principalmente pra tiro reto
# (homing = false), onde o alvo se move depois do disparo.
func _on_hit_area_body_entered(body: Node2D) -> void:
	if body is Enemy:
		_hit(body)


func _hit(enemy: Enemy) -> void:
	if has_hit or not is_instance_valid(enemy):
		return

	has_hit = true
	set_physics_process(false)  # para de se mover assim que acerta

	enemy.take_damage(damage)
	hit.emit(enemy)
	_on_hit(enemy)
	_play_impact_and_free()


func _play_impact_and_free() -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("impact"):
		sprite.play("impact")
		await sprite.animation_finished
	queue_free()


func _on_target_lost() -> void:
	# comportamento padrão: destrói o projétil se o alvo sumir antes do impacto
	queue_free()


# ==== Hooks virtuais para as cenas herdadas sobrescreverem ====
# Ex: numa cena herdada (projétil de área), você pode fazer:
#     func _on_hit(enemy: Enemy) -> void:
#         super._on_hit(enemy)
#         aplicar_dano_em_area(enemy.global_position)
func _on_hit(_enemy: Enemy) -> void:
	pass
