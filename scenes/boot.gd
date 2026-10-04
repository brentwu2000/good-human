extends Node
## Entry scene: initialize globals, load the save, then Home — or the shelter
## for a save that has not adopted a dog yet (Sprint 06).


func _ready() -> void:
	SaveManager.load_game()
	Game.load_profile()
	Game.goto_start()
