extends Label

func _process(_delta):
	text = "%s" % Engine.get_frames_per_second()
