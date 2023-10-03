extends Node2D

@export_group("Textures")
@export var ghost_texture: Texture
@export var monster_texture: Texture
@export var player_texture: Texture
@export var other_player_texture: Texture
@export var unknown_texture: Texture
@export var tombstone_texture: Texture

@export_group("Random stuff")
@export var font: Font

@export_group("Nodes")
@export var hp_label: Label
@export var xp_label: Label
@export var level_label: Label
@export var inventory_list: ItemList
@export var camera: Camera2D
@export var auto_kill_checkbox: CheckButton

var websocket_url = "wss://daydun.com:666/"
var player_name = "blupper";

# Our WebSocketClient instance
var socket = WebSocketPeer.new()

var map = {}
var entities = []
var last_map_fetch = 0;
var last_entity_fetch = 0;

var next_move = null
var previous_move = Vector2(0, 0)

#var player_pos = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	inventory_list.set_process_input(false)
	socket.connect_to_url(websocket_url)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			_handle_packet(JSON.parse_string(socket.get_packet().get_string_from_utf8()))
	elif state == WebSocketPeer.STATE_CLOSING:
		print("websocket closing...")
	elif state == WebSocketPeer.STATE_CLOSED:
		print("websocket closed")
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.
		get_tree().quit()
	queue_redraw()
	

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			move(Vector2(0, -1))
		elif event.keycode == KEY_S:
			move(Vector2(0, 1))
		elif event.keycode == KEY_A:
			move(Vector2(-1, 0))
		elif event.keycode == KEY_D:
			move(Vector2(1, 0))
		elif event.keycode == KEY_K:
			for i in range(10):
				interact(Vector2(0, 0))
		elif event.keycode == KEY_I:
			move_raw("1i", "0")
		elif event.keycode == KEY_J:
			move_raw("0", "1i")
	
	if event is InputEventMouseButton and !event.pressed:
		var selected_pos = floor(get_global_mouse_position() / CELL_SIZE_VEC)
		if event.button_index == MOUSE_BUTTON_LEFT:
			interact(selected_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var selected_items = inventory_list.get_selected_items()
			if len(selected_items) < 1: return
			interact(selected_pos, selected_items[0])
		
		

func interact(pos, slot=-1):
	socket.send_text(JSON.stringify({
		"type": "interact",
		"x": str(pos.x),
		"y": str(-pos.y),
		"slot": str(slot)
	}))
	
func move_raw(x, y):
	socket.send_text(JSON.stringify({
		"type": "move",
		"x": x,
		"y": y
	}))
func move(dpos):
	if next_move == null:
		socket.send_text(JSON.stringify({
			"type": "move",
			"x": str(dpos.x),
			"y": str(-dpos.y)
		}))
		next_move = Vector2(dpos.x, dpos.y)
		print(next_move)
	#player_pos += dpos
	
func update_map(new_map):
	last_map_fetch += 1
	
	if next_move != null:
		var prev_map = map.duplicate()
		map.clear()
		for pos in prev_map:
			var new_pos = pos - next_move
			map[new_pos] = prev_map[pos]

	next_move = null
	
	var w = len(new_map[0])
	var h = len(new_map)
	for y in range(6, -7, -1):
		for x in range(6, -7, -1):
			var block = new_map[14-(y+7)][x+7]
			block['created'] = last_map_fetch
			map[Vector2(x, y)] = block
		
	
func format_inventory(inventory, item_list: ItemList):
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
	var digits = "0123456789"
	var selected_indices = item_list.get_selected_items()
	var prev_idx = -1
	if len(selected_indices) > 0:
		prev_idx = selected_indices[0]
	if len(new_items) == item_list.item_count:
		for j in range(len(new_items)):
			if new_items[j] != item_list.get_item_text(j): mismatch = true
	else:
		mismatch = true
	if mismatch:
		item_list.clear()
		for item in new_items:
			item_list.add_item(item)
	if prev_idx != -1:
		item_list.select(prev_idx)
	#if len(new_items) != item_list.get_item_text()
	#for i in range(len(new_items))
	

func update_entities(new_entities):
	last_entity_fetch += 1
	
	entities = []
	for entity in new_entities:
		if entity.type == "player" and entity.name == player_name:
			#hp_label.font
			hp_label.text = "HP: %s/%s" % [entity.hp, entity.max_hp]
			xp_label.text = "XP: %s" % [entity.xp]
			level_label.text = "Level: %s" % [entity.level]
			format_inventory(entity.inventory, inventory_list)
	
	
		entity['pos'] = Vector2(int(entity['x']), -int(entity['y']))
		entities.append(entity)
		

func _handle_packet(data):
	if data['type'] == "connect":
		assert(data["version"] == 1)
		socket.send_text(JSON.stringify({
			"type": "connect",
			"name": player_name
		}))
		print("Connected to server")
	elif data['type'] == 'tick' or data['type'] == 'move':
		var map = data['map']
		var entities = data['entities']
		update_map(map)
		update_entities(entities)
	
	

var CELL_SIZE = 120
var CELL_SIZE_VEC = Vector2(CELL_SIZE, CELL_SIZE)

func draw_texture_at_pos(tex, pos, flip=false):
	var fac = CELL_SIZE_VEC/tex.get_size()
	if flip:
		pos.x += CELL_SIZE
		fac.x *= -1
	draw_set_transform(Vector2.ZERO, 0.0, fac)
	draw_texture(tex, pos/fac)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_health_bar(pos, hp, max_hp):
	draw_string(font,
				CELL_SIZE*(pos + Vector2(0,-0.2)),
				"%d/%d" % [hp, max_hp], 0, -1, 64)
	
	return
	var health_frac = hp / max_hp
	# Health background
	draw_rect(Rect2(
		CELL_SIZE*(pos + Vector2(0, -0.3)),
		CELL_SIZE*Vector2(1, 0.2)
	), '#870f07')
	
	draw_rect(Rect2(
		CELL_SIZE*(pos + Vector2(0, -0.3)),
		CELL_SIZE*Vector2(health_frac, 0.2)
	), '#ff1100')

func _draw():
	
	for entity in entities:
		var glob_pos = entity['pos'] * CELL_SIZE
		
		if auto_kill_checkbox.button_pressed and (entity.type == "monster" or (entity.type == "player" and entity.name != player_name)):
			if max(abs(entity.pos.x), abs(entity.pos.y)) <= 1:
				interact(entity.pos)
		
		if entity.type == "player":
			draw_health_bar(entity.pos, int(entity.hp), int(entity.max_hp))
		
			if entity.name == player_name:
				var flip = get_global_mouse_position().x < glob_pos.x
				draw_texture_at_pos(player_texture, glob_pos, flip)
			else:
				draw_texture_at_pos(other_player_texture, glob_pos)
			
			#draw_set_transform(glob_pos + Vector2(0, 1.4)*CELL_SIZE, 0.0, Vector2(0.125,0.125))
			#draw_string(font, Vector2(0, 0), entity.name, 0, -1, 16*8)
			#draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			
			draw_string(font,
				glob_pos + Vector2(0, 1.4)*CELL_SIZE,
				entity.name, 0, -1, 64)
		elif entity.type == "monster":
			draw_health_bar(entity.pos, int(entity.hp), int(entity.max_hp))
			draw_texture_at_pos(monster_texture, glob_pos)
		elif entity.type == "ghost":
			draw_texture_at_pos(ghost_texture, glob_pos)
		else:
			draw_texture_at_pos(unknown_texture, glob_pos)
			draw_string(font,
				glob_pos + Vector2(0, 1.4)*CELL_SIZE,
				entity.type, 0, -1, 64)
	
	for pos in map:
		var block = map[pos]
		var glob_pos = pos * CELL_SIZE
		if block['type'] == "air": continue
		
		var rect = Rect2(glob_pos, CELL_SIZE_VEC)
		var opacity = 'ff' if block['created'] == last_map_fetch else '7f'
		
		if block.type == "dirt":
			draw_rect(rect, '674c39' + opacity)
		elif block.type == "concrete":
			draw_rect(rect, '7f7f7f' + opacity)
		elif block.type == "wood":
			draw_rect(rect, '937240' + opacity)
		elif block.type == "tombstone":
			draw_texture_at_pos(tombstone_texture, CELL_SIZE*pos)
			draw_string(font, CELL_SIZE*(pos + Vector2(0,1.4)), block.text, 0, -1, 64)
		else:
			draw_rect(rect, 'f542da' + opacity)
			draw_string(font,
				(pos + Vector2(0, 0.5))*CELL_SIZE,
				block.type, 0, -1, 64)
			
			
			
	
func _init():
	print("hello world!")


