extends Resource
class_name CommandStack

@export var commands: PackedStringArray
@export var macros: Dictionary

enum ParseError {
	NO_TOKENS,
	FIRST_TOKEN_UNKNOWN,
	SECOND_TOKEN_UNKNOWN,
	SECOND_TOKEN_MISSING,
}

func string_to_command(str: String):
	var tokens = str.split(" ", false, 1)
	if tokens.is_empty():
		return ParseError.NO_TOKENS
	elif tokens.size() == 1:
		return func(command: Command):
			command.call(tokens[0])
	elif tokens.size() == 2:
		return func(command: Command):
			command.call(tokens[0]).call(tokens[1])
