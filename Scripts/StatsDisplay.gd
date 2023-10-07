extends MeshInstance3D

@export var offset: float
@export var font_size: int = 64
@export var max_length: int = 64

var label: Label3D

func set_text(text: String):
	label.text = text.left(max_length)
	
func set_font_size(sz: int):
	label.font_size = sz
	
func _init():
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.text = ""
	label.font_size = font_size
	add_child(label)

func _ready():
	label.translate(Vector3(0, offset, 0))
