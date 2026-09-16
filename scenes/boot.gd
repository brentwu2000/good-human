extends Node
## Entry scene: initialize globals, load the save, go Home.


func _ready() -> void:
	SaveManager.load_game()
	Game.load_profile()
	Game.goto_home()
