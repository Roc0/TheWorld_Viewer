extends Spatial

# Import classes
const HTerrain = preload("res://addons/zylann.hterrain/hterrain.gd")
const HTerrainData = preload("res://addons/zylann.hterrain/hterrain_data.gd")
const HTerrainTextureSet = preload("res://addons/zylann.hterrain/hterrain_texture_set.gd")

# You may want to change paths to your own textures
var grass_texture = load("res://textures/ground/grass_albedo.png")
var sand_texture = load("res://textures/ground/sand_albedo.png")
var leaves_texture = load("res://textures/ground/leaves_albedo.png")

func read_image(file_name : String) -> Image:
	var image : Image = Image.new()
	var file : File = File.new()
	
	var e := file.open(file_name, File.READ)
	var file_size : int = file.get_len()
	var image_size : int = sqrt(file_size / 4)
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
			var c : Color
			c.r = float(image_row_buffer[idx]) / 255
			c.g = float(image_row_buffer[idx + 1]) / 255
			c.b = float(image_row_buffer[idx + 2]) / 255
			c.a = float(image_row_buffer[idx + 3]) / 255
			idx += 4
			image.set_pixel(x, y, c)
	image.unlock()

	file.close()
	
	image.generate_mipmaps()

	return image
	
func _ready():
	# Create terrain resource and give it a size.
	# It must be either 513, 1025, 2049 or 4097.
	
	if not is_visible():
		return
		
	var file_name : String = "res://textures/ground/Ground003_2K_albedo_bump.ground"
	var image : Image = read_image(file_name)
	var grass_albedo_bump_tex : ImageTexture = ImageTexture.new()
	grass_albedo_bump_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)
	file_name = "res://textures/ground/Ground003_2K_normal_roughness.ground"
	image = read_image(file_name)
	var grass_normal_roughness_tex : ImageTexture = ImageTexture.new()
	grass_normal_roughness_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)
	
	file_name = "res://textures/ground/Ground049C_1K_albedo_bump.ground"
	image = read_image(file_name)
	var sand_albedo_bump_tex : ImageTexture = ImageTexture.new()
	sand_albedo_bump_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)
	file_name = "res://textures/ground/Ground049C_1K_normal_roughness.ground"
	image = read_image(file_name)
	var sand_normal_roughness_tex : ImageTexture = ImageTexture.new()
	sand_normal_roughness_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)

	file_name = "res://textures/ground/PaintedPlaster017_1K_albedo_bump.ground"
	image = read_image(file_name)
	var snow_albedo_bump_tex : ImageTexture = ImageTexture.new()
	snow_albedo_bump_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)
	file_name = "res://textures/ground/PaintedPlaster017_1K_normal_roughness.ground"
	image = read_image(file_name)
	var snow_normal_roughness_tex : ImageTexture = ImageTexture.new()
	snow_normal_roughness_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)

	file_name = "res://textures/ground/Rock028_1K_albedo_bump.ground"
	image = read_image(file_name)
	var rocks_albedo_bump_tex : ImageTexture = ImageTexture.new()
	rocks_albedo_bump_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)
	file_name = "res://textures/ground/Rock028_1K_normal_roughness.ground"
	image = read_image(file_name)
	var rocks_normal_roughness_tex : ImageTexture = ImageTexture.new()
	rocks_normal_roughness_tex.create_from_image(image, ImageTexture.FLAG_FILTER | ImageTexture.FLAG_MIPMAPS | ImageTexture.FLAG_REPEAT)

	var terrain_data = HTerrainData.new()
	terrain_data.resize(513)

	var noise = OpenSimplexNoise.new()
	var noise_multiplier = 50.0
	var altitude_modifier = 2000.0

	# Get access to terrain maps
	var heightmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_HEIGHT)
	var normalmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_NORMAL)
	var splatmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_SPLAT)

	heightmap.lock()
	normalmap.lock()
	splatmap.lock()

	# Generate terrain maps
	# Note: this is an example with some arbitrary formulas,
	# you may want to come up with your owns
	for z in heightmap.get_height():
		for x in heightmap.get_width():
			# Generate height
			var h = (noise_multiplier * noise.get_noise_2d(x, z)) + altitude_modifier

			# Getting normal by generating extra heights directly from noise,
			# so map borders won't have seams in case you stitch them
			var h_right = (noise_multiplier * noise.get_noise_2d(x + 0.1, z)) + altitude_modifier
			var h_forward = (noise_multiplier * noise.get_noise_2d(x, z + 0.1)) + altitude_modifier
			#var normal = Vector3(h - h_right, 0.1, h_forward - h).normalized()
			var normal = Vector3(h - h_right, 0.1, h - h_forward).normalized()

			# Generate texture amounts
			var splat = splatmap.get_pixel(x, z)
			# slope = 2.0 quando la pendenza è minima (terreno orizzontale), -2.0 quando la pendenza è massima (terreno verticale)
			var slope = 4.0 * normal.dot(Vector3.UP) - 2.0
			#var slope = 4.0 * normal.dot(Vector3.RIGHT) - 2.0
			# Sand on the slopes
			var sand_amount = clamp(1.0 - slope, 0.0, 1.0)
			# Leaves below sea level
			var snow_amount = clamp(0.0 - h, 0.0, 1.0)
			var rocks_amount = clamp(slope, 0.0, 1.0)
			splat = splat.linear_interpolate(Color(0,1,0,0), sand_amount)
			splat = splat.linear_interpolate(Color(0,0,1,0), snow_amount)
			splat = splat.linear_interpolate(Color(0,0,0,1), rocks_amount)
			
			heightmap.set_pixel(x, z, Color(h, 0, 0))
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
	#texture_set.set_texture(1, HTerrainTextureSet.TYPE_ALBEDO_BUMP, sand_texture)
	texture_set.set_texture(1, HTerrainTextureSet.TYPE_ALBEDO_BUMP, sand_albedo_bump_tex)
	texture_set.set_texture(1, HTerrainTextureSet.TYPE_NORMAL_ROUGHNESS, sand_normal_roughness_tex)
	
	texture_set.insert_slot(-1)
	#texture_set.set_texture(2, HTerrainTextureSet.TYPE_ALBEDO_BUMP, leaves_texture)
	texture_set.set_texture(2, HTerrainTextureSet.TYPE_ALBEDO_BUMP, snow_albedo_bump_tex)
	texture_set.set_texture(2, HTerrainTextureSet.TYPE_NORMAL_ROUGHNESS, snow_normal_roughness_tex)
	#texture_set.set_texture(2, HTerrainTextureSet.TYPE_ALBEDO_BUMP, Snow005_1K_albedo_bump_tex)
	#texture_set.set_texture(2, HTerrainTextureSet.TYPE_NORMAL_ROUGHNESS, Snow005_1K_normal_roughness_tex)
	
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

	# No need to call this, but you may need to if you edit the terrain later on
	terrainDemo2.update_collider()
