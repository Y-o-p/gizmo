extends RefCounted
class_name LindenmayerSystem

var production_rules: Dictionary[String, String]
var functions: Dictionary[String, Array]
var axiom: String

func get_next_sequence(sequence: String):
	var next_sequence := String()
	for symbol in sequence:
		if not production_rules.has(symbol):
			next_sequence += symbol
			continue
		
		next_sequence += production_rules[symbol]
	
	return next_sequence


func execute_sequence(sequence: String):
	for symbol in sequence:
		if functions.has(symbol):
			for function in functions[symbol]:
				function.callable.call()
