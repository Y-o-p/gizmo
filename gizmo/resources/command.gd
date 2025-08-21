extends Resource
class_name Command

var function_name: String
var arguments: Array

func _init(function_name: String, arguments: Array) -> void:
	self.function_name = function_name
	self.arguments = arguments
	
static func from_callable(callable: Callable) -> Command:
	return Command.new(callable.get_method(), callable.get_bound_arguments())
