extends CharacterBody2D

@export var speed: float = 300.0

func _process(delta):
	var direction = Vector2(0, 0)
	
	if Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	
	if direction != Vector2(0, 0):
		direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()
