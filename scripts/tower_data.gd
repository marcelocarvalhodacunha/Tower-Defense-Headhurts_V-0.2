extends Resource
class_name TowerData

## Representa uma opção de torre que aparece na barra de construção.
## Crie um .tres desses pra cada classe de aventureiro (ex: arqueiro, mago...)
## e arraste no array "tower_options" do TowerPlacer.

@export var scene: PackedScene
@export var icon: Texture2D
@export var display_name: String = "Torre"
