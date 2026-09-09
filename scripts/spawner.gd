extends Node2D

@export var path: Path2D
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.5

@onready var timer = $TimerSpawn

func _ready():
	timer.wait_time = spawn_interval
	timer.timeout.connect(_on_timer_timeout)
	timer.start()


func _on_timer_timeout():
	spawn_enemy()

func spawn_enemy():
	var path_follow = PathFollow2D.new()
	path_follow.loop = false
	path.add_child(path_follow)

	var enemy: Enemy = enemy_scene.instantiate()
	path_follow.add_child(enemy)

	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)


func _on_enemy_died(enemy: Enemy) -> void:
	Game.add_gold(enemy.gold_reward)


func _on_enemy_reached_end(enemy: Enemy) -> void:
	Game.damage_base(enemy.damage)
