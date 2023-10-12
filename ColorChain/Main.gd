extends Control

var user_address
var user_balance = "0"
var block_color

var sepolia_id = 11155111

#If the RPC is down, you can find a list at https://chainlist.org/chain/11155111
var sepolia_rpc = "https://ethereum-sepolia.publicnode.com"

var color_chain_contract = "0x7321F4C834b368b7e4eFaF5A9381F77F906AcDF1"

var confirmation_timer = 0
var tx_ongoing = false

func _ready():
	$Send.connect("pressed", self, "send_color")
	$Copy.connect("pressed", self, "copy_address")
	$GetGas.connect("pressed", self, "open_faucet")
	$Refresh.connect("pressed", self, "refresh_balance")
	check_keystore()
	get_address()
	refresh_balance()
	check_color()

func _process(delta):
	if confirmation_timer > 0:
		confirmation_timer -= delta
		if confirmation_timer < 0:
			check_color()

func check_keystore():
	var file = File.new()
	if file.file_exists("user://keystore") != true:
		var bytekey = Crypto.new()
		var content = bytekey.generate_random_bytes(32)
		file.open("user://keystore", File.WRITE)
		file.store_buffer(content)
		file.close()

func get_address():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	user_address = ColorChain.get_address(content)
	$Address.text = user_address
	file.close()

func refresh_balance():
	ColorChain.get_balance(user_address, sepolia_rpc, self)

func copy_address():
	OS.set_clipboard(user_address)

func open_faucet():
	OS.shell_open("https://sepolia-faucet.pk910.de")
	
func send_color():
	refresh_balance()
	if tx_ongoing == false && user_balance != "0":
		var sent_color = $ColorPicker.color
		var r = int(stepify(sent_color.r,0.001) * 1000)
		var g = int(stepify(sent_color.g,0.001) * 1000)
		var b = int(stepify(sent_color.b,0.001) * 1000)
		
		if [r,g,b] != block_color:
			
			print("Sending color:")
			print([r,g,b])
		
			var file = File.new()
			file.open("user://keystore", File.READ)
			var content = file.get_buffer(32)
			file.close()
			var success = ColorChain.send_color(content, sepolia_id, color_chain_contract, sepolia_rpc, r, g, b)
			if success:
				tx_ongoing = true
				confirmation_timer = 8
				$Send.text = "Confirming..."
			else:
				$Send.text = "TX ERROR"
		else:
			$Send.text = "Error (Pick New Color)"
			

func check_color():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	file.close()
	var success = ColorChain.get_color(content, sepolia_id, color_chain_contract, sepolia_rpc, self)
	if success:
		pass
	else:
		confirmation_timer = 4



#Called from Rust	

func set_color(var chain_color):
	var new_color = parse_json(chain_color)
	print("Raw JSON:")
	print(new_color)
	
	var compare = [new_color["r"].hex_to_int(), new_color["g"].hex_to_int(), new_color["b"].hex_to_int()]
	
	if compare != block_color:
		print("New Color:")
		print(compare)
		block_color = compare.duplicate()
		var material_color = Color(float(compare[0]) / 1000, float(compare[1]) / 1000, float(compare[2]) / 1000, 1)
		$Block.get_active_material(0).albedo_color = material_color
		confirmation_timer = 0
		tx_ongoing = false
		$Send.text = "Send Color"
	else:
		confirmation_timer = 4

func set_balance(var balance):
	user_balance = balance
	$GasBalance.text = balance
