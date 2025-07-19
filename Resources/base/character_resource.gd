class_name CharacterResource extends Resource

@export var health: int = 0
@export var stamina: int =  0
@export var attack: int = 0
@export var defense: int = 0
@export var agility: int = 0
@export var luck: int = 0
@export var damage: int = 0
@export var armor: int = 0

var base_damage: float:
	get:
		return damage + (attack * 0.2)

var damage_reduction: float:
	get:
		return armor + (defense * 0.2)

var critical_chance: float:
	get:
		return luck * 0.01

var max_stamina: int:
	get:
		return stamina * 10
		
func to_dict() -> Dictionary:
	return {
		"health": health,
		"stamina": stamina,
		"attack": attack,
		"defense": defense,
		"agility": agility,
		"luck": luck,
		"damage": damage,
		"armor": armor
	}

static func from_dict(data: Dictionary) -> CharacterResource:
	var character = CharacterResource.new()
	
	character.health = data.get("health", 0)
	character.stamina = data.get("stamina", 0)
	character.attack = data.get("attack", 0)
	character.defense = data.get("defense", 0)
	character.agility = data.get("agility", 0)
	character.luck = data.get("luck", 0)
	character.damage = data.get("damage", 0)
	character.armor = data.get("armor", 0)
	
	return character
