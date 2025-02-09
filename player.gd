extends CharacterBody2D


@export var SPEED = 200.0
@export var JUMP_VELOCITY = -390.0
@export var jump_distance  = 100
@export var knockback_power: float = 100
@onready var animations = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var slash_sound := $sounds/Slash as AudioStreamPlayer2D
@onready var h_timer = $hurt_timer
@onready var effects = $Effects
@onready var health_bar = $Health
@onready var attack = $area_attack/Attack
@onready var death_s = $sounds/death_sound
@onready var jumping = $sounds/jump
@onready var walk = $sounds/walk
@onready var potion = $sounds/potion
@onready var hurt_sound = $sounds/hurt
const max_health = 7
var health = max_health
var move_direction: int =  1
var attacking: bool = false
enum State {Idle, Run, Jump, Attack}
var is_hurt = false
var current_state: State
var motion = Vector2.ZERO
var enemy_colission = []
func _ready():
	current_state = State.Idle
	health_bar.max_value = max_health
	health_bar.visible = false
	attack.disabled = true
#tentando fazer tudo separado para depois juntar tudo
func player_falling(delta):
	if !is_on_floor():
		velocity += get_gravity() * delta

func player_idle(delta):
	if is_on_floor() && attacking == false:
		current_state = State.Idle
		
func player_run(delta):
	if !is_on_floor() or attacking == true:
		return
	var direction = Input.get_axis("esquerda","direita")
	if direction:
		velocity.x = direction * SPEED
		#walk.play()
		#if not walk.is_playing():
			#walk.play()
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if direction != 0:
		current_state = State.Run
		if direction > 0:
			sprite.flip_h = false
			attack.scale.x = 1
		else:
			sprite.flip_h = true
			attack.scale.x = -1
			
func player_jump(delta):
	if Input.is_action_just_pressed("pulo") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumping.play()
		current_state = State.Jump
		
	if !is_on_floor() and current_state == State.Jump:
		var direction =  Input.get_axis("esquerda","direita")
		velocity.x += direction * jump_distance * delta
		
func player_animations():
	if current_state == State.Idle and is_on_floor():
		animations.play("Idle")
		
	elif current_state == State.Run and is_on_floor():
		animations.play("move")
	elif current_state == State.Jump:
		animations.play("jump")
		
func player_attack():
	if Input.is_action_just_pressed("ataque"):
		attacking = true
		animations.play("attack")
		if attacking == true && animations.current_animation == "attack":
			velocity.x = 0
			current_state = State.Attack
			#slash_sound.play()
			await animations.animation_finished
			attacking = false
		

func apply_knockback():
	motion.x = 50 * move_direction
	var collision = move_and_collide(motion)
	if collision:
		move_direction *= -1
		velocity += collision.get_normal() * knockback_power
		if move_direction == 1:
			health_bar.position.x = 12
		elif move_direction == -1:
			health_bar.position.x = -22
	#if move_direction == 1:
		
func set_health_bar() -> void:
	health_bar.value = health
	

	
func _physics_process(delta: float) -> void:
	player_falling(delta)
	if not health == 0:
		player_attack()
		player_idle(delta)
		player_run(delta)
		player_jump(delta)
		move_and_slide()
		player_animations()
		if !is_hurt:
			for enemy_body in enemy_colission:
				hurt_by_enemy(enemy_body)

func hurt_by_enemy(body):
	health -= 1
	if health == 0:
		animations.play("death")
		death_s.play()
		h_timer.start(2)
		await  h_timer.timeout
		queue_free()
		get_tree().change_scene_to_file("res://Global/game_over.tscn")
	set_health_bar()
	health_bar.visible = true
	is_hurt = true
	apply_knockback()
	effects.play("blink")
	h_timer.start()
	await h_timer.timeout
	effects.play("RESET")
	health_bar.visible = false
	is_hurt = false
	
func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group('Enemy'):
		hurt_sound.play()
		enemy_colission.append(body)
	if body.name == "barreira":
		DialogueManager.show_example_dialogue_balloon(load("res://Global/Dialogue/aviso.dialogue"), 'start')
		


func _on_hurtbox_body_exited(body: Node2D) -> void:
	enemy_colission.erase(body)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "attack_area":
		health -= 1
		if health == 0:
			animations.play("death")
			death_s.play()
			h_timer.start(2)
			await  h_timer.timeout
			queue_free()
			get_tree().change_scene_to_file("res://Global/game_over.tscn")
		set_health_bar()
		hurt_sound.play()
		health_bar.visible = true
		is_hurt = true
		apply_knockback()
		effects.play("blink")
		h_timer.start()
		await h_timer.timeout
		effects.play("RESET")
		health_bar.visible = false
		is_hurt = false
	if area.is_in_group("potion"):
		print("entrou")
		if health == 7: return
		potion.play()
		health_bar.visible = true
		health += 1
		h_timer.start()
		await h_timer.timeout
		health_bar.visible = false
