extends Window
class_name LindenmayerEditor


func _on_add_rule_button_pressed() -> void:
	var rule_editor = Scenes.LINDENMAYER_RULE_EDITOR.instantiate()
	%RuleContainer.add_child(rule_editor)


func get_lindenmayer_system() -> LindenmayerSystem:
	var lindenmayer_system := LindenmayerSystem.new()
	lindenmayer_system.axiom = %Axiom.text
	for rule_editor in %RuleContainer.get_children():
		var variable: String = rule_editor.get_node("%Variable").text
		var mutation: String = rule_editor.get_node("%Mutation").text
		lindenmayer_system.production_rules[variable] = mutation
		lindenmayer_system.functions[variable] = []
		for command_editor in rule_editor.get_node("%CommandContainer").get_children():
			lindenmayer_system.functions[variable].append(command_editor.stored_command)
	
	return lindenmayer_system


func _on_save_button_pressed() -> void:
	var system_name: String = %NameEdit.text
	User.command.l_systems[system_name] = get_lindenmayer_system()
