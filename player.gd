extends CharacterBody3D

signal hit

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75 # Gravity
# Vertical impulse applied to the character upon jumping in meters per second.
@export var jump_impulse = 20
# Vertical impulse applied to the character upon bouncing over a mob in
# meters per second.
@export var bounce_impulse = 16

var target_velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	# Calls this function before each physics step
	
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO
	
	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
		
	# Prevent diagonal moving fast af
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		# Setting the basis property will affect the rotation of the node.
		$Pivot.look_at(position + direction, Vector3.UP)
		$AnimationPlayer.speed_scale = 4
	else:
		$AnimationPlayer.speed_scale = 1
		
	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		#if $AnimationPlayer.is_playing():
			#$AnimationPlayer.stop()
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		#if not $AnimationPlayer.is_playing():
			#$AnimationPlayer.play()
		target_velocity.y = jump_impulse
		# Iterate through all collisions that occurred this frame
	# in C this would be for(int i = 0; i < collisions.Count; i++)
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)
		
		# If the collision is with the ground
		if collision.get_collider() == null:
			continue
		
		# If the collider is with a mob
		if collision.get_collider().is_in_group("mob"):
			var mob = collision.get_collider()
			# we check that we are hitting it from above
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				# If so, we squish it
				mob.squash()
				target_velocity.y = bounce_impulse
				# Prevent further duplicate calls.
				break
		
	# Moving the Character
	velocity = target_velocity
	move_and_slide()
	$Pivot.rotation.x = PI / 6 * velocity.y / jump_impulse

func die():
	hit.emit()
	queue_free()

func _on_mob_detector_body_entered(body: Node3D) -> void:
	die()
