extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("up"):
		pass
	if Input.is_action_just_pressed("down"):
		pass
	if Input.is_action_just_pressed("left"):
		flip_h = true
	if Input.is_action_just_pressed("right"):
		flip_h = false
