extends MeshInstance3D

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
@export var camera: Camera3D
@export var auto_kill_checkbox: CheckButton
@export var auto_mine_checkbox: CheckButton
@export var debug_move_label: Label

var concrete_scene = preload("res://Prefabs/Concrete.tscn")
var unknown_block_scene = preload("res://Prefabs/UnknownBlock.tscn")
var wood_scene = preload("res://Prefabs/Wood.tscn")
var dirt_scene = preload("res://Prefabs/Dirt.tscn")
var tombstone_scene = preload("res://Prefabs/Tombstone.tscn")

var player_scene = preload("res://Prefabs/Player.tscn")
var other_player_scene = preload("res://Prefabs/OtherPlayer.tscn")
var enemy_scene = preload("res://Prefabs/Enemy.tscn")
var ghost_scene = preload("res://Prefabs/Ghost.tscn")

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

var cursor_material: Material
var selected_square: Vector2


# Called when the node enters the scene tree for the first time.
func _ready():
	cursor_material = StandardMaterial3D.new()
	cursor_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cursor_material.albedo_color = 'ffffff20'
	
	var mesh_material = StandardMaterial3D.new()
	mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_material.albedo_color = 'ffffff08'
	var grid_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(13, 0.1, 13)
	mesh.material = mesh_material
	grid_instance.mesh = mesh
	add_child(grid_instance)
	grid_instance.translate(Vector3(0, -0.5, 0))
	
	#inventory_list.set_process_input(false)
	print("Connecting...")
	socket.connect_to_url(websocket_url)
	socket.inbound_buffer_size = 65535*256
	
	
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
		
	#if Time.get_unix_time_from_system() - last_move_time > 0.25:
	#	print('reseting...')
	##	last_move_time = Time.get_unix_time_from_system()
	#	move_3d(Vector3(0, 0, 0))
	
var last_move_time = 0
var highlight_square = null
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_K:
			for i in range(hp+1):
				interact(Vector2(0, 0))
	
	if event is InputEventMouseButton and \
	!event.pressed and \
	event.button_index == MOUSE_BUTTON_LEFT:
		interact(selected_square)
		
	if event is InputEventMouseButton and \
	!event.pressed and \
	event.button_index == MOUSE_BUTTON_RIGHT:
		var selected_items = inventory_list.get_selected_items()
		if len(selected_items) < 1: return
		interact(selected_square, selected_items[0])
		
	if event is InputEventMouseMotion:
		if highlight_square != null:
			highlight_square.queue_free()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * camera.far
		
		var cursorPos = Plane(Vector3(0, 1, 0), -0.5).intersects_ray(from, to)
		if cursorPos == null:
			return
		
		cursorPos += Vector3(0, 1, 0)
		var inst = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.material = cursor_material
		inst.mesh = mesh
		inst.translate(floor(cursorPos))
		selected_square = Vector2(floor(cursorPos.x), floor(cursorPos.z))
		add_child(inst)
		highlight_square = inst
		
func interact_raw(x, y, slot=-1):
	socket.send_text(JSON.stringify({
		"type": "interact",
		"x": str(x),
		"y": str(y),
		"slot": str(slot)
	}))

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
	var x = str(dpos.x)
	var y = str(-dpos.y)
		#if dpos.y != 0: y += "i"
	socket.send_text(JSON.stringify({
			"type": "move",
		"x": x,
		"y": y
	}))
		#next_move = Vector2(dpos.x, dpos.y)
	#player_pos += dpos
	
func move_3d(dpos):
	var x = str(dpos.x)
	if dpos.y != 0:
		x += "+" if dpos.y > 0 else "-"
		x += str(abs(dpos.y))
		x += "i"
	var y = str(-dpos.z)
	debug_move_label.text = "%s, %s" % [x, y]
	socket.send_text(JSON.stringify({
		"type": "move",
		"x": x,
		"y": y
	}))
	
	
var z = 0
var last_move
func update_map(new_map):
	last_map_fetch += 1
	
	var w = len(new_map[0])
	var h = len(new_map)
	for y in range(6, -7, -1):
		for x in range(6, -7, -1):
			var block = new_map[14-(y+7)][x+7]
			block['created'] = last_map_fetch
			var pos = Vector3(x, z, y)
			
			var instance = null
			if block.type == "air":
				pass
			elif block.type == 'concrete':
				instance = concrete_scene.instantiate()
			elif block.type == "wood":
				instance = wood_scene.instantiate()
			elif block.type == "dirt":
				instance = dirt_scene.instantiate()
			elif block.type == "tombstone":
				instance = tombstone_scene.instantiate()
				instance.set_text(block.text.left(25))
				instance.set_font_size(40)
			else:
				instance = unknown_block_scene.instantiate()
				instance.set_text(block.type)
			
			if instance != null:
				instance.translate(pos)
				add_child(instance)
			block.mesh_instance = instance
			if pos in map and map[pos].mesh_instance != null:
				map[pos].mesh_instance.queue_free()
			map[pos] = block
			
			if auto_mine_checkbox.button_pressed and block.type != "air" and \
			abs(pos.x) <= 1 and abs(pos.z) <= 1 \
			and (pos.x != 0 or pos.z != 0):
				interact(Vector2(pos.x, pos.z))
				


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
	

var hp = 0
func update_entities(new_entities):
	last_entity_fetch += 1
	
	for old_entity in entities:
		if old_entity.instance != null:
			old_entity.instance.queue_free()
	entities = []
	for entity in new_entities:
		if entity.type == "player" and entity.name == player_name:
			hp = int(entity.hp)
			hp_label.text = "HP: %s/%s" % [entity.hp, entity.max_hp]
			xp_label.text = "XP: %s" % [entity.xp]
			level_label.text = "Level: %s" % [entity.level]
			format_inventory(entity.inventory, inventory_list)

		var pos = Vector3(int(entity['x']), z, -int(entity['y']))
		var instance = null
		
		if auto_kill_checkbox.button_pressed and \
		(entity.type == "monster" or (entity.type == "player" and entity.name != player_name)):
			if max(abs(pos.x), abs(pos.z)) <= 1 and (pos.x != 0 or pos.z != 0):
				for i in range(10): interact(Vector2(pos.x, pos.z))
		
		if entity.type == "player":
			if entity.name == player_name:
				instance = player_scene.instantiate()
			else:
				instance = other_player_scene.instantiate()
			instance.set_text("%s %s/%s" % [entity.name, entity.hp, entity.max_hp])
		elif entity.type == "monster":
			instance = enemy_scene.instantiate()
			instance.set_text("Enemy %s/%s" % [entity.hp, entity.max_hp])
		elif entity.type == "ghost":
			instance = ghost_scene.instantiate()
			instance.set_text("Ghost")
			
		if instance != null:
			instance.translate(pos)
			add_child(instance)
		entity.instance = instance
		entity['pos'] = pos
		entities.append(entity)


var last_tick = 0
var has_moved_tick = false
func _handle_packet(data):
	if data['type'] == "connect":
		assert(data["version"] == 1)
		socket.send_text(JSON.stringify({
			"type": "connect",
			"name": player_name
		}))
		print("Connected to server")
		move_raw("0", "0")
	elif data['type'] == 'tick':
		has_moved_tick = false
		var map = data['map']
		var entities = data['entities']
		update_map(map)
		update_entities(entities)
	
	elif data['type'] == 'move':
		var failed_move = true
		for entity in data.entities:
			if entity.type == "player" and entity.name == player_name:
				if entity.x == "0" and entity.y == "0":
					failed_move = false
	
		if not failed_move and last_move != Vector3.ZERO and last_move != null:
			var new_map = {}
			for pos in map:
				if map[pos].type == "air": continue
				var new_pos = pos - last_move
				map[pos].mesh_instance.translate(-last_move)
				new_map[new_pos] = map[pos]
			map = new_map
			has_moved_tick = true
		last_move = null
	
		var keyboard = Vector2(
			Input.get_axis("ui_left","ui_right"), 
			Input.get_axis("ui_up","ui_down"))
		var dz = 0
		if Input.is_key_pressed(KEY_Z):
			dz = 1
		elif Input.is_key_pressed(KEY_X):
			dz = -1
		last_move = Vector3(keyboard.x, dz, keyboard.y)
		last_move_time = Time.get_unix_time_from_system()
		move_3d(last_move)
		
	

var CELL_SIZE = 120
var CELL_SIZE_VEC = Vector2(CELL_SIZE, CELL_SIZE)
