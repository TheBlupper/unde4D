extends ItemList


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_items(inventory):
	var i = 0
	var new_items = []
	for slot in inventory:
		var item = slot[0]
		var count = int(slot[1])
		var text = "%d. %s" % [i, item.type]
		for key in item:
			if key == "type": continue
			text += " %s=%s" % [key, item[key]]
		text += " x%s" % count
		new_items.append(text)
		i += 1
	
	var mismatch = false
	var selected_indices = get_selected_items()
	var prev_idx = -1
	var prev_item_count = item_count
	if len(selected_indices) > 0:
		prev_idx = selected_indices[0]
	if len(new_items) == prev_item_count:
		for j in range(len(new_items)):
			if new_items[j] != get_item_text(j): mismatch = true
	else:
		mismatch = true
	if mismatch:
		clear()
		for item in new_items:
			add_item(item)
	if prev_idx != -1 and prev_idx < len(new_items):
		select(prev_idx)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
