extends Node

@export var snake_scene : PackedScene

#game vars
var score : int
var game_started : bool = false

#grid vars
var cells : int = 20
var cell_size : int = 50

#food vars
var food_pos : Vector2
var regen_food : bool = true

#snake vars
var old_data : Array
var snake_data : Array
var snake : Array

#movement vars
var start_pos = Vector2(9, 9)
var up = Vector2(0, -1)
var down = Vector2(0, 1)
var left = Vector2(-1, 0)
var right = Vector2(1, 0)
var move_direction : Vector2
var can_move: bool
var next_direction : Vector2

#high score counter!
var high_score : int = 0

func update_high_score_display():
	$Hud.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(high_score)

func _ready():
	new_game()

func new_game():
	get_tree().paused = false
	get_tree().call_group("segments", "queue_free")
	$GameOverMenu.hide()
	score = 0
	$Hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
	update_high_score_display()
	move_direction = up
	next_direction = Vector2.ZERO
	can_move = true
	generate_snake()
	move_food()

func generate_snake():
	old_data.clear()
	snake_data.clear()
	snake.clear()
	
	for i in range(3):
		add_segment(start_pos + Vector2(0, i))

func add_segment(pos):
	snake_data.append(pos)
	var SnakeSegment = snake_scene.instantiate()
	SnakeSegment.position = (pos * cell_size) + Vector2(0, cell_size)
	add_child(SnakeSegment)
	snake.append(SnakeSegment)

func _process(delta):
	move_snake()

func move_snake():
	# Always check for input, but respect direction rules
	if Input.is_action_just_pressed("move_down") and move_direction != up:
		next_direction = down
		if not game_started:
			start_game()
	elif Input.is_action_just_pressed("move_up") and move_direction != down:
		next_direction = up
		if not game_started:
			start_game()
	elif Input.is_action_just_pressed("move_left") and move_direction != right:
		next_direction = left
		if not game_started:
			start_game()
	elif Input.is_action_just_pressed("move_right") and move_direction != left:
		next_direction = right
		if not game_started:
			start_game()

func start_game():
	game_started = true
	$MoveTimer.start()

func _on_timer_timeout():
	# Apply buffered direction if we have one
	if next_direction != Vector2.ZERO:
		# Double-check the direction is still valid (prevents opposite direction)
		if (next_direction == up and move_direction != down) or \
		   (next_direction == down and move_direction != up) or \
		   (next_direction == left and move_direction != right) or \
		   (next_direction == right and move_direction != left):
			move_direction = next_direction
		next_direction = Vector2.ZERO  # Clear the buffer
	
	# Rest of your existing timer code stays the same
	old_data = [] + snake_data
	snake_data[0] += move_direction
	for i in range(len(snake_data)):
		if i > 0:
			snake_data[i] = old_data[i - 1]
		snake[i].position = (snake_data[i] * cell_size) + Vector2(0, cell_size)
	check_out_of_bounds()
	check_self_eaten()
	check_food_eaten()

func check_out_of_bounds():
	if snake_data[0].x < 0 or snake_data[0].x > cells - 1 or snake_data[0].y < 0 or snake_data[0].y > cells - 1:
		end_game()

func check_self_eaten():
	for i in range(1, len(snake_data)):
		if snake_data[0] == snake_data[i]:
			end_game()

func move_food():
	while regen_food:
		regen_food = false
		food_pos = Vector2(randi_range(0, cells - 1), randi_range(0, cells - 1))
		for i in snake_data:
			if food_pos == i:
				regen_food = true
	$Food.position = (food_pos * cell_size)+ Vector2(0, cell_size)
	regen_food = true
	

func end_game():
	$GameOverMenu.show()
	$MoveTimer.stop()
	game_started = false
	get_tree().paused = true

func check_food_eaten():
	if snake_data[0] == food_pos:
		score += 1
		$Hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
		
		# Check for new high score this session
		if score > high_score:
			high_score = score
			update_high_score_display()
		
		add_segment(old_data[-1])
		move_food()


func _on_game_over_menu_restart():
	new_game()
