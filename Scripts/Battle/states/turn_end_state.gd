class_name TurnEndState extends BattleState


func enter():
	battle_manager.next_player()
	state_machine.start_turn()
