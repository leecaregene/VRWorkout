extends Node

var vrhealthAPI = null

signal heart_rate_received(hr)

var hr_active = false

#
func process_heartrate(hr):
	hr_active = true
	print ("Heartrate received %s"%str(hr))
	emit_signal("heart_rate_received",hr)
	GameVariables.current_hr = hr
	GameVariables.hr_active = true


# Replace with your actual WebSocket key
var WEBSOCKET_KEY = ProjectSettings.get_setting("global/hyperate api key")
var WEBSOCKET_URL = "wss://app.hyperate.io/socket/websocket?token=" + WEBSOCKET_KEY

# Channel ID for testing
var CHANNEL_ID = ProjectSettings.get_setting("global/hyperate id")

var websocket = WebSocketClient.new()
var keep_alive_timer = Timer.new()

func _ready():
	# Connect WebSocket signals
	websocket.connect("connection_established", self, "_on_connection_established")
	websocket.connect("connection_closed", self, "_on_connection_closed")
	websocket.connect("connection_error", self, "_on_connection_error")
	websocket.connect("data_received", self, "_on_data_received")

	# Set up keep-alive timer
	keep_alive_timer.wait_time = 10  # Send keep-alive every 10 seconds
	keep_alive_timer.connect("timeout", self, "_send_keep_alive")
	add_child(keep_alive_timer)

	# Connect to the WebSocket server
	var err = websocket.connect_to_url(WEBSOCKET_URL)
	if err != OK:
		print("Failed to connect to WebSocket: ", err)

func _process(delta):
	# Poll the WebSocket client
	websocket.poll()

func _on_connection_established(protocol):
	print("WebSocket connection established with protocol: ", protocol)
	keep_alive_timer.start()  # Start the keep-alive timer
	_join_channel(CHANNEL_ID)  # Join the testing channel

func _on_connection_closed(was_clean):
	print("WebSocket connection closed. Clean: ", was_clean)
	keep_alive_timer.stop()  # Stop the keep-alive timer

func _on_connection_error():
	print("WebSocket connection error")

func _on_data_received():
	# Handle incoming data
	var data = websocket.get_peer(1).get_packet().get_string_from_utf8()
	var json = JSON.parse(data)
	if json.error == OK:
		var message = json.result
		if message.has("event") and message["event"] == "hr_update":
			var hr = message["payload"]["hr"]
#			print("Heart rate update: ", hr)
			process_heartrate(hr)
	else:
		print("Failed to parse JSON: ", json.error_string)

func _join_channel(channel_id):
	var join_message = {
		"topic": "hr:" + channel_id,
		"event": "phx_join",
		"payload": {},
		"ref": 0
	}
	_send_message(join_message)

func _leave_channel(channel_id):
	var leave_message = {
		"topic": "hr:" + channel_id,
		"event": "phx_leave",
		"payload": {},
		"ref": 0
	}
	_send_message(leave_message)

func _send_keep_alive():
	var keep_alive_message = {
		"topic": "phoenix",
		"event": "heartbeat",
		"payload": {},
		"ref": 0
	}
	_send_message(keep_alive_message)

func _send_message(message):
	var json_string = JSON.print(message)
	websocket.get_peer(1).put_packet(json_string.to_utf8())

func _exit_tree():
	# Clean up
	if websocket.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED:
		_leave_channel(CHANNEL_ID)
		websocket.disconnect_from_host()
