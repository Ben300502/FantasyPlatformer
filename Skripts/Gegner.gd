extends CharacterBody2D

class_name Gegner

static var GESCHWINDIGKEIT
static var ANGRIFFSREICHWEITE
static var REAKTIONSZEIT
const GRAVITATION = 1000

@onready var animationsSpieler: AnimationPlayer
@onready var animation: Node2D
@onready var hitbox: CollisionShape2D
@onready var hitboxAngriff: Area2D
@onready var angriffsSichtfeld: Area2D
@onready var sichtfeld: Area2D
@onready var collisionShapeHitboxAngriff: CollisionShape2D
@onready var collisionShapeAngriffSichtfeld: CollisionShape2D
@onready var collisionShapeSichtfeld: CollisionShape2D
@onready var raycastSichtfeld: RayCast2D
@onready var bodenUeberprueferLinks: RayCast2D
@onready var bodenUeberprueferRechts: RayCast2D
@onready var timer: Timer


var richtung = 0
var letzteRichtung = 0
var warten = false
var leben

func _ready() -> void:
	animationsSpieler.play("idle")
	collisionShapeHitboxAngriff.disabled = true
	timer.timeout.connect(_on_timer_timeout)

func _physics_process(delta: float) -> void:
	if leben == 0:
		return
	
	letzteRichtung = richtung
	velocity.x = 0
	velocity.y += GRAVITATION * delta
	
	if animationsSpieler.current_animation in ["angriff", "verletzt", "tod"] or warten:
		return
	else:
		collisionShapeHitboxAngriff.disabled = true
		setzeLaufrichtung()
		ueberpruefeAbgrund()
		setzeLaufanimation()
		ueberpruefeAngriff()

	move_and_slide()

func spieleVerletzt():
	if animationsSpieler.current_animation not in ["verletzt", "tod"]:
		leben -= 1
		if leben > 0:
			animationsSpieler.play("verletzt")
		else:
			hitbox.disabled = true
			hitboxAngriff.body_entered.disconnect(_on_hitbox_angriff_body_entered)
			animationsSpieler.play("tod")
			

func setzeLaufanimation():
	if letzteRichtung != richtung:
		warten = true
		timer.start(REAKTIONSZEIT)
		velocity.x = 0
	elif richtung == 1:
		animation.scale.x = 1
		angriffsSichtfeld.scale.x = 1
		hitboxAngriff.scale.x = 1
	elif richtung == -1:
		animation.scale.x = -1
		angriffsSichtfeld.scale.x = -1
		hitboxAngriff.scale.x = -1
	if 	velocity.x != 0:
		animationsSpieler.play("laufen")
	elif animationsSpieler.current_animation != "verletzt":
		animationsSpieler.play("idle") 

func setzeLaufrichtung():
	for charakter in sichtfeld.get_overlapping_bodies():
		if charakter is Held:
			# RayCast auf das Ziel setzen
			raycastSichtfeld.target_position = charakter.position - position
			raycastSichtfeld.force_raycast_update()  # RayCast sofort aktualisieren
			
			if not raycastSichtfeld.is_colliding() or raycastSichtfeld.get_collider() == charakter:  # Nur wenn keine Wand im Weg ist
				if abs(charakter.position.x - position.x) > 80:
					richtung = sign(charakter.position.x - position.x)
					velocity.x = GESCHWINDIGKEIT * richtung
				elif charakter.is_on_floor():
					richtung = sign(charakter.position.x - position.x)
			else:
				velocity.x = 0  # Stoppt Bewegung, wenn eine Wand blockiert
	
			
func ueberpruefeAbgrund():
	bodenUeberprueferLinks.force_raycast_update()
	bodenUeberprueferRechts.force_raycast_update()
	if velocity.x < 0 and not bodenUeberprueferRechts.is_colliding():
		velocity.x = 0
	elif velocity.x > 0 and not bodenUeberprueferLinks.is_colliding():
		velocity.x = 0
	
				
func ueberpruefeAngriff():
	for body in angriffsSichtfeld.get_overlapping_bodies():
		if body is Held:
			animationsSpieler.play("angriff")
			velocity.x = 0
			

func _on_hitbox_angriff_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not body is Gegner:
		if body.has_method("spieleVerletzt") and body.leben > 0:
			body.spieleVerletzt()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "tod":
		collisionShapeHitboxAngriff.disabled = true
		collisionShapeAngriffSichtfeld.disabled = true
		collisionShapeSichtfeld.disabled = true
		hitbox.disabled = true
	elif anim_name == "verletzt":
		animationsSpieler.play("idle")
	elif anim_name == "angriff":
		warten = true
		timer.start(REAKTIONSZEIT)
		animationsSpieler.play("idle")
		
func _on_timer_timeout():
	warten = false
