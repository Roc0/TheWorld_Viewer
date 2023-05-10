extends Spatial

# Import classes
const HTerrain = preload("res://addons/zylann.hterrain/hterrain.gd")
const HTerrainData = preload("res://addons/zylann.hterrain/hterrain_data.gd")
const HTerrainTextureSet = preload("res://addons/zylann.hterrain/hterrain_texture_set.gd")

# You may want to change paths to your own textures
var grass_texture = load("res://assets/textures/ground/grass_albedo.png")
var sand_texture = load("res://assets/textures/ground/sand_albedo.png")
var leaves_texture = load("res://assets/textures/ground/leaves_albedo.png")

func read_image_from_ground_file(file_name : String) -> Image:
	var image : Image = Image.new()

	var file : File = File.new()
	if not file.file_exists(file_name):
		print ("Error: file " + file_name + "does not exist")
		return image

	var _e := file.open(file_name, File.READ)
	var file_size : int = file.get_len()
	var image_size : int = int(sqrt(float(file_size) / 4))
	if (image_size * image_size * 4 != file_size):
		print ("Error: " + file_name + "with wrong length")
		return image

	image.create(image_size, image_size, true, Image.FORMAT_RGBA8)

	var image_row_buffer : PoolByteArray
	var row_size : int = image_size * 4
	image.lock()
	for y in image_size:
		image_row_buffer = file.get_buffer(row_size)
		#var image_row_buffer_size : int = image_row_buffer.size()
		var idx : int = 0
		
		for x in image_size:
			var c : Color = Color(1, 1, 1, 1)
			c.r = float(image_row_buffer[idx]) / 255
			c.g = float(image_row_buffer[idx + 1]) / 255
			c.b = float(image_row_buffer[idx + 2]) / 255
			c.a = float(image_row_buffer[idx + 3]) / 255
			idx += 4
			image.set_pixel(x, y, c)
	image.unlock()

	file.close()
	
	var _ret = image.generate_mipmaps()

	return image

func read_image_from_quadrant_file(file_name : String, image_type : int, _grid_step_in_wu : float, max_terrain_size : int) -> Image:
	var image : Image = Image.new()

	var file : File = File.new()
	if not file.file_exists(file_name):
		print ("Error: file " + file_name + "does not exist")
		return image

	var _e := file.open(file_name, File.READ)
	var _file_size : int = file.get_len()
	var offset : int = 0
	
	var _file_size_from_file := file.get_64()
	offset += 8
	var _char_zero := file.get_8()
	offset += 1
	var meshid_size := file.get_64()
	offset += 8
	var _meshid := file.get_buffer(meshid_size)
	offset += meshid_size
	var terrain_edit_value_size := file.get_64()
	offset += 8
	var _terrain_edit := file.get_buffer(terrain_edit_value_size)
	offset += terrain_edit_value_size
	var num_vertices := file.get_64()
	offset += 8
	var num_vertices_per_size := sqrt(num_vertices)
	var image_size : int = int(num_vertices_per_size)
	if (max_terrain_size > 0):
		image_size = max_terrain_size
	if (num_vertices > 0):
		var _min_altitude := file.get_float()
		var _max_altitude := file.get_float()
		offset += 8
		
		if image_type == 0:			# Heights
			# bypass 16-bit heights
			offset += num_vertices * 2
			file.seek(offset)
			
			image.create(image_size, image_size, false, Image.FORMAT_RH)

			image.lock()
			for y in num_vertices_per_size:
				for x in num_vertices_per_size:
					#var h := file.get_float() / grid_step_in_wu
					var h := file.get_float()
					if (x < image_size && y < image_size):
						image.set_pixel(x, y , Color(h, 0, 0))
			image.unlock()
			
		else:
			if image_type == 1:		# Normals
				# bypass 16-bit heights and 32-bit heights
				offset += num_vertices * 2
				offset += num_vertices * 4
				file.seek(offset)
				
				image.create(image_size, image_size, false, Image.FORMAT_RGB8)

				image.lock()
				for y in num_vertices_per_size:
					for x in num_vertices_per_size:
						var r := file.get_8()
						var g := file.get_8()
						var b := file.get_8()
						if (x == 0 && y == 0 && r == 0 && g == 0 && b == 0):
							image.unlock()
							return image
						if (x < image_size && y < image_size):
							var packed_normal := Vector3(float(r) / 255, float(g) / 255, float(b) / 255)
							#var c := decode_normal(packed_normal)
							image.set_pixel(x, y , Color(packed_normal.x, packed_normal.y, packed_normal.z))
				image.unlock()
	
	return image

#static func decode_normal(packed_normal : Vector3) -> Color:
static func decode_normal(packed_normal : Color) -> Vector3:
	var temp : Vector3 = (Vector3(packed_normal.r, packed_normal.b, packed_normal.g) * 2) - Vector3.ONE
	return temp
	#n = 0.5 * (n + Vector3.ONE)
	#return Color(n.x, n.z, n.y)

func _ready():
	# Create terrain resource and give it a size.
	# It must be either 513, 1025, 2049 or 4097.
	
	if not is_visible():
		return
		
	var grid_step_in_wu : float = 2.0
	
	var file_name : String = "res://assets/textures/ground/Ground003_2K_albedo_bump.ground"
	var image : Image = read_image_from_ground_file(file_name)
	var grass_albedo_bump_tex : ImageTexture = ImageTexture.new()
	grass_albedo_bump_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)
	file_name = "res://assets/textures/ground/Ground003_2K_normal_roughness.ground"
	image = read_image_from_ground_file(file_name)
	var grass_normal_roughness_tex : ImageTexture = ImageTexture.new()
	grass_normal_roughness_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)
	
	file_name = "res://assets/textures/ground/Ground049C_1K_albedo_bump.ground"
	image = read_image_from_ground_file(file_name)
	var sand_albedo_bump_tex : ImageTexture = ImageTexture.new()
	sand_albedo_bump_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)
	file_name = "res://assets/textures/ground/Ground049C_1K_normal_roughness.ground"
	image = read_image_from_ground_file(file_name)
	var sand_normal_roughness_tex : ImageTexture = ImageTexture.new()
	sand_normal_roughness_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)

	file_name = "res://assets/textures/ground/PaintedPlaster017_1K_albedo_bump.ground"
	image = read_image_from_ground_file(file_name)
	var snow_albedo_bump_tex : ImageTexture = ImageTexture.new()
	snow_albedo_bump_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)
	file_name = "res://assets/textures/ground/PaintedPlaster017_1K_normal_roughness.ground"
	image = read_image_from_ground_file(file_name)
	var snow_normal_roughness_tex : ImageTexture = ImageTexture.new()
	snow_normal_roughness_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)

	file_name = "res://assets/textures/ground/Rock028_1K_albedo_bump.ground"
	image = read_image_from_ground_file(file_name)
	var rocks_albedo_bump_tex : ImageTexture = ImageTexture.new()
	rocks_albedo_bump_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)
	file_name = "res://assets/textures/ground/Rock028_1K_normal_roughness.ground"
	image = read_image_from_ground_file(file_name)
	var rocks_normal_roughness_tex : ImageTexture = ImageTexture.new()
	rocks_normal_roughness_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)

	var terrain_size = 513
	var quadrant_file := ""
	quadrant_file = OS.get_user_data_dir() + "/TheWorld/Cache/ST-2.000000_SZ-2049/L-0/X-0.000000_Z-0.000000.mesh"
	
	var max_terrain_size := 513
	max_terrain_size = -1
	var heightmap_from_quadrant_file: Image = read_image_from_quadrant_file(quadrant_file, 0, grid_step_in_wu, max_terrain_size)
	if (heightmap_from_quadrant_file.get_height() > 0):
		terrain_size = heightmap_from_quadrant_file.get_height()

	var normalmap_from_quadrant_file: Image = Image.new()
	normalmap_from_quadrant_file = read_image_from_quadrant_file(quadrant_file, 1, grid_step_in_wu, max_terrain_size)
	
	var terrain_data = HTerrainData.new()
	terrain_data.resize(terrain_size)
	
	var noise = OpenSimplexNoise.new()
	var noise_multiplier = 50.0
	var altitude_modifier = 2000.0

	# Get access to terrain maps
	var heightmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_HEIGHT)
	var normalmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_NORMAL)
	var splatmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_SPLAT)

	if (heightmap_from_quadrant_file.get_height() > 0):
		heightmap.copy_from(heightmap_from_quadrant_file)
		
	if (normalmap_from_quadrant_file.get_height() > 0):
		normalmap.copy_from(normalmap_from_quadrant_file)
	
	heightmap.lock()
	normalmap.lock()
	splatmap.lock()

	var first : bool = true
	var min_height : float = 0
	var max_height : float = 0
	for z in heightmap.get_height():
		for x in heightmap.get_width():
			var h : float
			if (heightmap_from_quadrant_file.get_height() > 0):
				h = heightmap.get_pixel(x, z).r
			else:
				h = (noise_multiplier * noise.get_noise_2d(x, z)) + altitude_modifier
			if first == true:
				min_height = h
				max_height = h
				first = false
			else:
				if (h < min_height):
					min_height = h
				if (h > max_height):
					max_height = h
	
	#var half_height : float = (max_height + min_height) / 2
	var diff : float = max_height - min_height
	
	# Generate terrain maps
	# Note: this is an example with some arbitrary formulas,
	# you may want to come up with your owns
	for z in heightmap.get_height():
		for x in heightmap.get_width():
			var h : float
			var h_right : float
			var h_forward : float
			var normal : Vector3
			# Generate height
			if (heightmap_from_quadrant_file.get_height() > 0):
				#h = heightmap.get_pixel(x, z).r / grid_step_in_wu
				#h_right = heightmap.get_pixel(x + 1, z).r / grid_step_in_wu
				#h_forward = heightmap.get_pixel(x, z + 1).r / grid_step_in_wu
				h = heightmap.get_pixel(x, z).r
				if (normalmap_from_quadrant_file.get_height() > 0):
					normal = decode_normal(normalmap.get_pixel(x, z)).normalized()
					# debug
					if (x < 2048):
						h_right = heightmap.get_pixel(x + 1, z).r
					else:
						h_right = h
					if (z < 2048):
						h_forward = heightmap.get_pixel(x, z + 1).r
					else:
						h_forward = h
					var step : float = grid_step_in_wu
					#var normal = Vector3(h - h_right, 0.1, h_forward - h).normalized()	# original
					var _normal1 = Vector3(h - h_right, step, h - h_forward).normalized()
					# debug
				else:
					if (x < 2048):
						h_right = heightmap.get_pixel(x + 1, z).r
					else:
						h_right = h
					if (z < 2048):
						h_forward = heightmap.get_pixel(x, z + 1).r
					else:
						h_forward = h
					var step : float = grid_step_in_wu
					#var normal = Vector3(h - h_right, 0.1, h_forward - h).normalized()	# original
					normal = Vector3(h - h_right, step, h - h_forward).normalized()
			else:
				h = (noise_multiplier * noise.get_noise_2d(x, z)) + altitude_modifier
				# Getting normal by generating extra heights directly from noise,
				# so map borders won't have seams in case you stitch them
				h_right = (noise_multiplier * noise.get_noise_2d(x + 0.1, z)) + altitude_modifier
				h_forward = (noise_multiplier * noise.get_noise_2d(x, z + 0.1)) + altitude_modifier
				var step : float = 0.1
				#var normal = Vector3(h - h_right, 0.1, h_forward - h).normalized()	# original
				normal = Vector3(h - h_right, step, h - h_forward).normalized()

			# Generate texture amounts
			var splat = splatmap.get_pixel(x, z)
			# slope = 2.0 quando la pendenza è minima (terreno orizzontale), -2.0 quando la pendenza è massima (terreno verticale)
			#var slope = 4.0 * normal.dot(Vector3.UP) - 2.0	# original
			var slope = 4.0 * (1.0 - normal.dot(Vector3.UP)) - 1.0		# -1 / 3: -1=orizontal terrain, 3=vertical terrain
			
			var snow_amount : float = 4.0 * ((h - min_height) / diff) - 2.0		# ranges from -2 (at min_height) and 2 (at max_height)
			snow_amount = clamp(snow_amount, 0.0, 1.0)	# we cap fram 0 and 1 so that -2 / 0 no snow and 1 / 2 max snow
			var _grass_amount = 1.0 - snow_amount
			var rocks_amount : float = clamp(slope, 0.0, 1.0)		# rocks on the slopes: we ignore slopes less than 0 (not enough vertical)
			var sand_amount : float = rocks_amount * 2

			#snow_amount = 1
			splat = splat.linear_interpolate(Color(0,1,0,0), snow_amount)
			
			#sand_amount = 1
			splat = splat.linear_interpolate(Color(0,0,1,0), sand_amount)
			
			#rocks_amount = 1
			splat = splat.linear_interpolate(Color(0,0,0,1), rocks_amount)
			
			if (heightmap_from_quadrant_file.get_height() == 0):
				heightmap.set_pixel(x, z, Color(h, 0, 0))
			if (normalmap_from_quadrant_file.get_height() == 0):
				normalmap.set_pixel(x, z, HTerrainData.encode_normal(normal))
			splatmap.set_pixel(x, z, splat)

	heightmap.unlock()
	normalmap.unlock()
	splatmap.unlock()

	# Commit modifications so they get uploaded to the graphics card
	var modified_region = Rect2(Vector2(), heightmap.get_size())
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_HEIGHT)
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_NORMAL)
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_SPLAT)

	# Create texture set
	# NOTE: usually this is not made from script, it can be built with editor tools
	var texture_set = HTerrainTextureSet.new()
	texture_set.set_mode(HTerrainTextureSet.MODE_TEXTURES)
	
	texture_set.insert_slot(-1)
	#texture_set.set_texture(0, HTerrainTextureSet.TYPE_ALBEDO_BUMP, grass_texture)
	texture_set.set_texture(0, HTerrainTextureSet.TYPE_ALBEDO_BUMP, grass_albedo_bump_tex)
	texture_set.set_texture(0, HTerrainTextureSet.TYPE_NORMAL_ROUGHNESS, grass_normal_roughness_tex)
	
	texture_set.insert_slot(-1)
	#texture_set.set_texture(1, HTerrainTextureSet.TYPE_ALBEDO_BUMP, leaves_texture)
	texture_set.set_texture(1, HTerrainTextureSet.TYPE_ALBEDO_BUMP, snow_albedo_bump_tex)
	texture_set.set_texture(1, HTerrainTextureSet.TYPE_NORMAL_ROUGHNESS, snow_normal_roughness_tex)
	#texture_set.set_texture(1, HTerrainTextureSet.TYPE_ALBEDO_BUMP, Snow005_1K_albedo_bump_tex)
	#texture_set.set_texture(1, HTerrainTextureSet.TYPE_NORMAL_ROUGHNESS, Snow005_1K_normal_roughness_tex)
	
	texture_set.insert_slot(-1)
	#texture_set.set_texture(2, HTerrainTextureSet.TYPE_ALBEDO_BUMP, sand_texture)
	texture_set.set_texture(2, HTerrainTextureSet.TYPE_ALBEDO_BUMP, sand_albedo_bump_tex)
	texture_set.set_texture(2, HTerrainTextureSet.TYPE_NORMAL_ROUGHNESS, sand_normal_roughness_tex)
	
	texture_set.insert_slot(-1)
	texture_set.set_texture(3, HTerrainTextureSet.TYPE_ALBEDO_BUMP, rocks_albedo_bump_tex)
	texture_set.set_texture(3, HTerrainTextureSet.TYPE_NORMAL_ROUGHNESS, rocks_normal_roughness_tex)

	# Create terrain node
	var terrainDemo2 = HTerrain.new()
	#terrain.set_shader_type(HTerrain.SHADER_CLASSIC4_LITE)
	terrainDemo2.set_shader_type(HTerrain.SHADER_CLASSIC4)
	terrainDemo2.set_data(terrain_data)
	terrainDemo2.set_texture_set(texture_set)
	add_child(terrainDemo2)
	
	if (heightmap_from_quadrant_file.get_height() > 0):
		terrainDemo2.global_transform.origin.y += 1000

	# No need to call this, but you may need to if you edit the terrain later on
	terrainDemo2.update_collider()
