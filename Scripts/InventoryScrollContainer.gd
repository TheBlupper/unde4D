extends ScrollContainer

@export var small_size = 300

func _ready():
	if Utils.small:
		custom_minimum_size.y = small_size
