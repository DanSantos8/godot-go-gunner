class_name PowerupResource extends Resource

@export var damage_multiplier: float = 0.0
@export var additional_projectiles: int = 0
@export var powerup_id: String = ""
@export var powerup_name: String = ""
@export var powerup_icon: Texture2D

func to_dict() -> Dictionary:
	"""Converte PowerupResource para Dictionary"""
	var data = {
		"damage_multiplier": damage_multiplier,
		"additional_projectiles": additional_projectiles,
		"powerup_id": powerup_id,
		"powerup_name": powerup_name,
		"powerup_icon_path": ""  # Vamos tratar isso na parte 3
	}
	
	# Tratamento básico da texture (por enquanto)
	if powerup_icon:
		data["powerup_icon_path"] = powerup_icon.resource_path
	
	return data

static func from_dict(data: Dictionary) -> PowerupResource:
	"""Cria PowerupResource a partir de Dictionary"""
	var powerup = PowerupResource.new()
	
	# Propriedades básicas com valores padrão
	powerup.damage_multiplier = data.get("damage_multiplier", 1.0)
	powerup.additional_projectiles = data.get("additional_projectiles", 0)
	powerup.powerup_id = data.get("powerup_id", "")
	powerup.powerup_name = data.get("powerup_name", "")
	
	# Tratamento da texture
	var icon_path = data.get("powerup_icon_path", "")
	if not icon_path.is_empty():
		powerup.powerup_icon = load(icon_path)
	
	return powerup
