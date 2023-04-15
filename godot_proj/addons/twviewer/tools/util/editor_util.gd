# Editor-specific utilities.
# This script cannot be loaded in an exported game.

tool

# Tries to load a texture with the ResourceLoader, and if it fails, attempts
# to load it manually as an ImageTexture
static func load_texture(path: String) -> Texture:
	var tex : Texture = load(path)
	if tex != null:
		print("Loaded texture " + path)
		return tex
	# This can unfortunately happen when the editor didn't import assets yet.
	# See https://github.com/godotengine/godot/issues/17483
	print(str("Failed to load texture ", path, ", attempting to load manually"))
	var im := Image.new()
	var err = im.load(path)
	if err != OK:
		print(str("Failed to load image ", path))
		return null
	print("Loaded image " + path)
	var itex := ImageTexture.new()
	itex.create_from_image(im, Texture.FLAG_FILTER)
	return itex
