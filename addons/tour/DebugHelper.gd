@tool
###############################################################################
#
# DEBUG UTILITIES
# 
# To activate: 
# Run godot with the custom command line argument --tour-debug:
# ```
# godot --editor . -- --tour-debug
# ```
#

var is_debug_mode := get_is_debug_mode()

## Returns a dictionary of all arguments passed after `--` on the command line
## arguments take one of 2 forms:
## - `--arg` which is a boolean (using `--no-arg` for `false` is possible)
## - `--arg=value`. If the value is quoted with `"` or `'`, this function will 
##    unsurround the string
## This function does no evaluation and does not attempt to guess the type of
## arguments. You will receive either bools, or strings.
static func get_command_line_arguments() -> Dictionary:
	var arguments := {}
	for argument in OS.get_cmdline_user_args():
		argument = argument.lstrip("--").to_lower()
		if argument.find("=") > -1:
			var arg_tuple := argument.split("=")
			var key := arg_tuple[0]
			var value := unsurround(unsurround(arg_tuple[1], '"'), "'")\
				.strip_edges()
			arguments[key] = value
		else:
			var key := argument
			var value := true
			if argument.begins_with("no-"):
				value = false
				key = argument.lstrip("no-")
			arguments[key] = value
	return arguments


## Removes a single surrounding character at the beginning and end of a string
static func unsurround(value: String, quote_str := '"') -> String:
	if value.begins_with(quote_str) \
		and value.ends_with(quote_str) \
		and value[value.length() - 2] != "\\":
		return value.trim_prefix(quote_str).trim_suffix(quote_str)
	return value


## Returns `true` if Godot was ran with `-- --tour-debug`
static func get_is_debug_mode() -> bool:
	var command_line_arguments := get_command_line_arguments()
	return command_line_arguments.has("tour-debug") \
		and command_line_arguments["tour-debug"] == true
