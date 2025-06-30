class_name ChargeState extends State

var current_power: float = 0.0
var max_power: float = 100.0
var charge_speed: float = 15

func enter():
	print("Charging")
	current_power = 0.0
	player.power_bar.value = 0.0
	
func execute(delta):
	if Input.is_action_just_released('charge'):
		state_machine.change_state('shoot')
	else:
		current_power += charge_speed * delta
		current_power = min(current_power, max_power)
		player.power_bar.value = min(current_power, max_power)
		player.powerbar_label.set_powerbar_value(current_power)

func exit():
	print("Leaving charging")
