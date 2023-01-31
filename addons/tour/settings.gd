###############################################################################
#
# DEVELOPER SETTINGS
#
# These are settings saved when a _developer_ user of the plugin changes
# settings for their comfort. They are _unrelated_ to end-user preferences
#

const PLUGIN_ID := "tour"
const PLUGIN_PATH := "plugins/"+PLUGIN_ID

# Returns the shortcut that shows or hides the debugging window
static func get_show_debugger_window_shortcut() -> Shortcut:
	var default_input: InputEventKey = preload("show_debugger_window_shortcut.tres")
	return _get_or_set_shortcut("show window", default_input)


# Returns a keyboard shortcut from settings. If the settings isn't set, will create
# a new shortcut from the provided default.
static func _get_or_set_shortcut(shortcut_name: String, default_input: InputEventKey) -> Shortcut:
	var key := PLUGIN_PATH.path_join(shortcut_name.to_snake_case())
	if not ProjectSettings.has_setting(key):
		var property_info := {
				"name": key,
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "InputEventKey"
		}
		ProjectSettings.set_setting(key, default_input.duplicate())
		ProjectSettings.add_property_info(property_info)
	var loaded_input: InputEventKey = ProjectSettings.get_setting(key)
	var loaded_shortcut := Shortcut.new()
	loaded_shortcut.events = [loaded_input]
	return loaded_shortcut


const USER_PREFERENCES_PATH = "user://preferences.cfg"


static func get_preferences(section_name: String) -> Preferences:
	return Preferences.new(section_name).load()


class Preferences:
	
	var config_file := ConfigFile.new()
	var section := ""
	
	const USER_PREFERENCES_PATH = "user://preferences.cfg"
	const NOT_SET = { "not set": true }
	
	func _init(initial_section_name: String) -> void:
		section = initial_section_name
	
	func load() -> Preferences:
		var err = config_file.load(USER_PREFERENCES_PATH)
		if err != OK:
			config_file.save(USER_PREFERENCES_PATH)
		return self
	
	func save() -> void:
		config_file.save(USER_PREFERENCES_PATH)

	func get_value(value_name: String, default: Variant = null) -> Variant:
		return config_file.get_value(section, value_name, default)

	func set_value(value_name: String, value: Variant) -> void:
		var previous_value := get_value(value_name, NOT_SET)
		if previous_value != NOT_SET and value != previous_value:
			config_file.set_value(section, value_name, value)
			save()
	
