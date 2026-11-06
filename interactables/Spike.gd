extends Area2D

# Modular interval configuration (seconds)
@export var visible_interval = 1.0
@export var invisible_interval = 1.0

# Internal state
@onready var collision_shape = $CollisionShape2D
var timer = 0.0
var is_visible = true

func _process(delta):
	timer += delta

	# Turn the spike on (visible & monitoring)
	if not is_visible and timer >= invisible_interval:
		is_visible = true
		monitoring = true
		collision_shape.visible = true
		timer = 0.0

	# Turn the spike off (invisible & not monitoring)
	if is_visible and timer >= visible_interval:
		is_visible = false
		monitoring = false
		collision_shape.visible = false
		timer = 0.0

func _on_body_entered(body):
	# Only trigger when the spike is currently visible (ON state)
	if not is_visible:
		return
	
	# Check if the entering body is the player (CharacterController)
	if body is CharacterController:
		# Switch to OFF state immediately when player detected
		is_visible = false
		monitoring = false
		collision_shape.visible = false
		$ON.visible = false
		$OFF.visible = true
		timer = 0.0
		
		# Emit signal for scene restart
		emit_signal("player_detected")

func _ready():
	# Initial state: spike starts visible (ON), OFF sprite hidden
	$ON.visible = true
	$OFF.visible = false
	collision_shape.visible = true
	is_visible = true
	# Only trigger when the spike is currently visible
	
		
		
			
		
		
		
