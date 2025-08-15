extends RefCounted
class_name LindenmayerSystem

var production_rules: Dictionary[String, String]
var constants: Dictionary[String, Callable]
var BUILT_IN_CONSTANTS: Dictionary[String, Callable] = {
	"D": func (command: Command):
		command.pull(),
	"J": func (command: Command):
		command.move_edge_selection(),
	"K": func (command: Command):
		command.move_face_selection(),
	"L": func (command: Command):
		command.move_vertex_selection(),
	"H": func (command: Command):
		command.select_vertex(),
	"[": func (command: Command):
		command.push_selection(),
	"]": func (command: Command):
		command.pop_selection(),
}

func get_next_sequence(sequence: String):
	var next_sequence := String()
	for symbol in sequence:
		if not production_rules.has(symbol):
			next_sequence += symbol
			continue
		
		next_sequence += production_rules[symbol]
	
	return next_sequence
	

func execute_sequence(sequence: String, command: Command):
	for symbol in sequence:
		if constants.has(symbol):
			constants[symbol].call(command)
		elif BUILT_IN_CONSTANTS.has(symbol):
			BUILT_IN_CONSTANTS[symbol].call(command)
