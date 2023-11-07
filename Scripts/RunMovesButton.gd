extends Button

@onready var file_dialog: FileDialog = $FileDialog

func _pressed():
	file_dialog.popup_centered()
