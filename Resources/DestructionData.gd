# DestructionData.gd
class_name DestructionData
extends Resource

enum DestructionType {
	CIRCULAR,
	RECTANGULAR, 
	IRREGULAR,
	PIERCING
}

@export var type: DestructionType = DestructionType.CIRCULAR
@export var radius: float = 50.0
@export var width: float = 0.0
@export var height: float = 0.0
@export var segments: int = 16
@export var damage_multiplier: float = 1.0
