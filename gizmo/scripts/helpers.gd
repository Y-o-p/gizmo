extends Node


func wrapping_slice(array: Variant, start: int, end: int):
	var new_array = []
	for offset in range(abs(end - start)):
		new_array.append(array[(start + offset) % array.size()])
	
	return new_array
