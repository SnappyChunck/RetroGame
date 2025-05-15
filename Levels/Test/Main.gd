extends Node3D
#-----------------SCENE--SCRIPT------------------#
#    Close your game faster by clicking 'Esc'    #
#   Change mouse mode by clicking 'Shift + F1'   #
#------------------------------------------------#

@export var player_scene : PackedScene

var peer = ENetMultiplayerPeer.new()

func _on_join_pressed() -> void:
	$"Cross".show()
	peer.create_client("127.0.0.1", 1027)
	multiplayer.multiplayer_peer = peer
	$Buttons.hide()


func _on_host_pressed() -> void:
	$"Cross".show()
	peer.create_server(1027)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$Buttons.hide()

func add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child",player)

func del_player(id):
	rpc("_del_player",id)

@rpc("any_peer","call_local")
func _del_player(id):
	get_node(str(id)).queue_free()

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)
