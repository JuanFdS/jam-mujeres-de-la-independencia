extends Node

func start():
	if not $AudioStreamPlayer.playing:
		$AudioStreamPlayer.play()
