extends CharacterBody2D

class_name Held

static var GESCHWINDIGKEIT
static var SPRUNGKRAFT
const GRAVITATION = 1000

@onready var animationsSpieler: AnimationPlayer
@onready var animation: Node2D
@onready var hitboxAngriff: Area2D
@onready var collisionShapeHitboxAngriff: CollisionShape2D
@onready var hitbox: CollisionShape2D

var schnellerSprung = false
var leben

# Called when the node enters the scene tree for the first time.
func _ready():
	collisionShapeHitboxAngriff.disabled = true
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if leben <= 0:
		return
	
	velocity.x = 0
	velocity.y += GRAVITATION * delta
	
	if spieltAngriffsanimation() or animationsSpieler.current_animation == "verletzt" or animationsSpieler.current_animation == "tod":
		velocity.x == 0
	else:
		ueberpruefeRichtungsEingabe()
		rennenUndLaufen()
		springenUndLanden()
		ueberpruefeAngriff()
	
	move_and_slide()
	
	
func spieltAngriffsanimation():
	return animationsSpieler.current_animation == "angriff_stand" or animationsSpieler.current_animation == "angriff_laufen" or animationsSpieler.current_animation == "angriff_rennen"

func spieltSprungOderLandeAnimation():
	return animationsSpieler.current_animation in ["sprung_hoch", "doppel_sprung", "doppel_sprung_fallen", "landen", "fallen"]

func ueberpruefeRichtungsEingabe():
	if Input.is_action_pressed("links"):
		animation.scale.x = -1
		hitboxAngriff.scale.x = -1
		velocity.x = -GESCHWINDIGKEIT
	if Input.is_action_pressed("rechts"):
		animation.scale.x = 1
		hitboxAngriff.scale.x = 1
		velocity.x = GESCHWINDIGKEIT
	if Input.is_action_just_pressed("hoch") and is_on_floor():
		velocity.y += -SPRUNGKRAFT
		if Input.is_action_pressed("shift"):
			schnellerSprung = true
		else:
			schnellerSprung = false
	elif is_on_floor() and Input.is_action_pressed("shift"):
		velocity.x *= 2

func rennenUndLaufen():
	if is_on_floor() and not spieltSprungOderLandeAnimation() and not spieltAngriffsanimation():
		if velocity.x != 0:
			if Input.is_action_pressed("shift"):
				animationsSpieler.play("rennen")
			else:
				animationsSpieler.play("laufen")
		else:
			animationsSpieler.play("idle") 
			

func springenUndLanden():
	if animationsSpieler.current_animation == "landen" or spieltAngriffsanimation():
		pass
	else:
		if (animationsSpieler.current_animation == "fallen" or animationsSpieler.current_animation == "doppel_sprung") and is_on_floor():
			animationsSpieler.play("landen")
		elif velocity.y >= 0 and not is_on_floor():
			if schnellerSprung == true:
				velocity.x *= 1.5
			if animationsSpieler.current_animation == "doppel_sprung":
				animationsSpieler.play("doppel_sprung")
			else:
				animationsSpieler.play("fallen")
		elif velocity.y < 0 and not is_on_floor():
			if schnellerSprung == true:
				velocity.x *= 1.5
			if animationsSpieler.current_animation == "doppel_sprung":
				pass
			elif Input.is_action_just_pressed("hoch"):
				velocity.y = -SPRUNGKRAFT
				animationsSpieler.play("doppel_sprung")
			else:
				animationsSpieler.play("sprung_hoch")
			
func ueberpruefeAngriff():
	if Input.is_action_just_pressed("angriff") and is_on_floor():
		animationsSpieler.play("angriff_stand")
	#if(Input.is_action_pressed("angriff") and is_on_floor()):
		#if velocity.x != 0:
			#if Input.is_action_pressed("shift"):
				#animationsSpieler.play("angriff_rennen")
			#else:
				#animationsSpieler.play("angriff_laufen")
		#else :
			#animationsSpieler.play("angriff_stand")
			
func spieleVerletzt():
	if animationsSpieler.current_animation != "verletzt" and animationsSpieler.current_animation != "tod":
		leben -= 1
		if leben > 0:
			animationsSpieler.play("verletzt")
		else:
			hitbox.disabled = true
			animationsSpieler.play("tod")


func _on_hitbox_angriff_body_entered(body: Node2D) -> void:
	if body.has_method("spieleVerletzt") and not body is Held and body.leben > 0:
		body.spieleVerletzt()
		
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "tod":
		queue_free()
