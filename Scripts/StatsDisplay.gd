extends MeshInstance3D


@export var offset: float

var label: Label3D

func set_text(text: String):
	label.text = text
	
func set_font_size(sz: int):
	label.font_size = sz
	
# Called when the node enters the scene tree for the first time.
func _init():
	label = Label3D.new()
	label.text = ""
	label.font_size = 64
	add_child(label)

func _ready():
	label.translate(Vector3(0, offset, 0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
