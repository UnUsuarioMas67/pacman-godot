extends Node

signal pill_collected
signal big_pill_collected
signal half_pills_collected
signal level_completed
signal player_death_started
signal player_death_finished
signal global_ghost_state_updated(global_state: Ghost.State, scared_mode: bool)
signal ghost_eaten
signal ghost_reformed
signal level_changed(new_level: int)
