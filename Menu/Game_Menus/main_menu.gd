extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/start_button.grab_focus() # Replace with function body.

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/train_map/train_world.tscn") # Replace with function body.


func _on_options_button_pressed():
	pass # NO OPTIONS MENU RIPERONIS


func _on_quit_button_pressed():
	get_tree().quit() # Replace with function body.
