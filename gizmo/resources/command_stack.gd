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
	var tokens = str.split(" ", false, 1)
	if tokens.is_empty():
		return ParseError.NO_TOKENS
	elif tokens.size() == 1:
		return func(command: Command):
			command.call(tokens[0])
			command.command_completed.emit(tokens[0])
	elif tokens.size() == 2:
		return func(command: Command):
			print(tokens[0], tokens[1])
			command.call(tokens[0]).call(tokens[1])
			command.command_completed.emit("%s %s" % [tokens[0], tokens[1]])
