extends Resource
class_name CommandStack

@export var commands: PackedStringArray

enum ParseError {
	NO_TOKENS,
	FIRST_TOKEN_UNKNOWN,
	SECOND_TOKEN_UNKNOWN,
	SECOND_TOKEN_MISSING,
}

func string_to_command(str: String):
	var tokens = str.split(" ")
	var command_tokens = tokens[0].split("")
	
	if command_tokens.is_empty():
		return ParseError.NO_TOKENS
	var second_parse = _parse_first_token(command_tokens[0])
	if second_parse == null:
		return ParseError.FIRST_TOKEN_UNKNOWN
	
	if command_tokens.size() < 2:
		return ParseError.SECOND_TOKEN_MISSING
	
	var command = second_parse.call(command_tokens[1])
	if command == null:
		return ParseError.SECOND_TOKEN_UNKNOWN
	
	return command

func _parse_first_token(token: String):
	match token:
		"m":
			return _parse_mode_token

func _parse_mode_token(token: String):
	match token:
		"f":
			return func(selection: Selection, model: Model):
				selection.mode = selection.Mode.FACE
		"e":
			return func(selection: Selection, model: Model):
				selection.mode = selection.Mode.EDGE
		"v":
			return func(selection: Selection, model: Model):
				selection.mode = selection.Mode.VERTEX
	
	return null
