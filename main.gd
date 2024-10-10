extends Node2D

const tile_empty = 0
const tile_wall = 1
const tile_floor = 2
const tile_pass = 3

const tile_ground = 5
const tile_grass = 6
const tile_tree = 7

var map_size = Vector2(40, 40)
var map = []
var rooms = []
var floor_level = 1
var player_level = 1

var player_location = Vector2()
var player_health_max = 15
var player_health = player_health_max
var player_health_grow = 5
var player_health_gen = 0
var player_health_gen_turn = 5
var player_atk = 5
var player_atk_grow = 5
var player_exp = 0
var player_exp_max = 5

var portal_location = Vector2()
var portal_id = 5

var entities = [] # 적의 위치
var entities_health = [] # 적의 현재 체력
var enemy_health = 10
var enemy_health_grow = 5
var enemy_atk = 1
var enemy_atk_grow = 2
var enemy_num_max = 5

var min_size = 4
var max_size = 10
var max_rooms = 10
var rules = {
	tile_wall : [tile_ground, tile_grass, tile_tree],
	tile_pass : [tile_ground, tile_grass, tile_tree],
	tile_ground : [tile_ground, tile_grass],
	tile_grass : [tile_grass, tile_ground, tile_tree],
	tile_tree : [tile_tree, tile_grass]
}

# Called when the node enters the scene tree for the first time.
func _ready():
	$PlayerFace.position = Vector2(30, 30)
	$PlayerFace.texture = preload("res://art/player_face_0.png")
	make_map()
	make_tile()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$LabelLevel.text = "LEVEL " + str(player_level)
	$LabelFloor.text = "FLOOR " + str(floor_level)
	$LabelExp.text = "EXP " + str(player_exp) + " / " + str(player_exp_max)
	$LabelHealth.text = "HP " + str(player_health) + " / " + str(player_health_max)
	
	for y in range(player_location.y-4, player_location.y+5):
		for x in range(player_location.x-4, player_location.x+5):
			var tile_position = Vector2i(x-player_location.x+4, y-player_location.y+4)
			$Map.set_cell(0, tile_position, map[y][x], Vector2i(0, 0))
			$EnemyMap.set_cell(0, tile_position, -1)
			if entities[y][x]:
				$EnemyMap.set_cell(0, tile_position, entities[y][x], Vector2i(0, 0))
			if x == portal_location.x and y == portal_location.y:
				$EnemyMap.set_cell(0, tile_position, portal_id, Vector2i(0, 0))
	if player_health <= 0:
		$LabelGameover.visible = true
	elif player_health * 3 < player_health_max :
		$PlayerFace.texture = preload("res://art/player_face_2.png")
	elif player_health * 3 < player_health_max * 2 :
		$PlayerFace.texture = preload("res://art/player_face_1.png")
	else :
		$PlayerFace.texture = preload("res://art/player_face_0.png")
	
	var move = Vector2(0, 0)
	if Input.is_action_just_pressed("up"):
		move.y = -1
	if Input.is_action_just_pressed("down"):
		move.y = 1
	if Input.is_action_just_pressed("left"):
		move.x = -1
	if Input.is_action_just_pressed("right"):
		move.x = 1
	
	if move != Vector2(0, 0):
		turn_player(move)

func turn_player(move):
	player_health_gen += 1
	if player_health_gen >= player_health_gen_turn and player_health < player_health_max:
		player_health_gen = 0
		player_health += 1
	var next = player_location+move
	if next == portal_location:
		floor_level += 1
		enemy_atk += enemy_atk_grow
		enemy_health += enemy_health_grow
		make_map()
		make_tile()
	elif entities[next.y][next.x]:
		entities_health[next.y][next.x] -= player_atk
		if entities_health[next.y][next.x] < 1:
			entities_health[next.y][next.x] = 0
			entities[next.y][next.x] = 0
			player_exp += 1
		if player_exp >= player_exp_max:
			player_exp = 0
			player_health_max += player_health_grow
			player_health = player_health_max
			player_atk += player_atk_grow
			player_level += 1
	elif map[next.y][next.x] == tile_wall:
		pass
	else:
		player_location += move
	
	turn_enemy()

func turn_enemy():
	for y in range(map_size.y):
		for x in range(map_size.x):
			if entities[y][x]:
				enemy_move(x, y)

func enemy_move(x, y):
	var dis_x = abs(player_location.x - x)
	var dis_y = abs(player_location.y - y)
	if dis_x + dis_y == 1:
		player_health -= enemy_atk
	elif dis_x > dis_y:
		if player_location.x < x and entities[y][x-1] is Array:
			entities[y][x-1] = entities[y][x]
			entities[y][x] = []
			entities_health[y][x-1] = entities_health[y][x]
			entities_health[y][x] = []
		elif entities[y][x+1] is Array:
			entities[y][x+1] = entities[y][x]
			entities[y][x] = []
			entities_health[y][x+1] = entities_health[y][x]
			entities_health[y][x] = []
	else :
		if player_location.y < y and entities[y-1][x] is Array:
			entities[y-1][x] = entities[y][x]
			entities[y][x] = []
			entities_health[y-1][x] = entities_health[y][x]
			entities_health[y][x] = []
		elif entities[y+1][x] is Array:
			entities[y+1][x] = entities[y][x]
			entities[y][x] = []
			entities_health[y+1][x] = entities_health[y][x]
			entities_health[y][x] = []

func make_tile():
	for y in range(map_size.y):
		for x in range(map_size.x):
			if map[y][x] == tile_floor :
				var can = intersection(rules[map[y-1][x]], rules[map[y][x-1]])
				map[y][x] = can[randi() % can.size()]
	for i in range(enemy_num_max):
		var x = randi_range(5, map_size.x-5)
		var y = randi_range(5, map_size.y-5)
		entities[y][x] = randi()%3 + 1
		entities_health[y][x] = enemy_health
		


func intersection(arr1, arr2):
	var result = []
	for element in arr1:
		if arr2.has(element) and not result.has(element):
			result.append(element)
	return result

func make_map():
	map = []
	rooms = []
	entities = []
	entities_health = []
	for y in range(map_size.y):
		map.append([])
		entities.append([])
		entities_health.append([])
		for x in range(map_size.x):
			map[y].append(tile_wall)
			entities[y].append([])
			entities_health[y].append([])
	# generate rooms
	for i in range(max_rooms):
		var room_width = randi_range(min_size, max_size)
		var room_height = randi_range(min_size, max_size)
		var room_x = randi_range(5, map_size.x - room_width - 5)
		var room_y = randi_range(5, map_size.y - room_height - 5)
		for y in range(room_y, room_y+room_height):
			for x in range(room_x, room_x+room_width):
				map[y][x] = tile_floor
		rooms.append(Rect2(room_x, room_y, room_width, room_height))
		# generate pass
		if i > 0:
			var c1 = rooms[i-1].position + rooms[i-1].size / 2
			var c2 = rooms[i].position + rooms[i].size / 2
			if randf() > 0.5:
				make_hall_h(c1.x, c2.x, c1.y)
				make_hall_v(c1.y, c2.y, c2.x)
			else:
				make_hall_v(c1.y, c2.y, c1.x)
				make_hall_h(c1.x, c2.x, c2.y)
	player_location = Vector2(randi_range(rooms[0].position.x, rooms[0].position.x+rooms[0].size.x-1), randi_range(rooms[0].position.y, rooms[0].position.y+rooms[0].size.y-1))
	while(1):
		var portal_x = randi_range(5, map_size.x-5)
		var portal_y = randi_range(5, map_size.y-5)
		if map[portal_y][portal_x] == tile_floor and player_location != Vector2(portal_x, portal_y):
			portal_location = Vector2(portal_x, portal_y)
			break

func make_hall_h(x1, x2, y):
	for x in range(min(x1, x2), max(x1, x2)+1):
		if map[y][x] == tile_wall:
			map[y][x] = tile_pass
func make_hall_v(y1, y2, x):
	for y in range(min(y1, y2), max(y1, y2)+1):
		if map[y][x] == tile_wall:
			map[y][x] = tile_pass
