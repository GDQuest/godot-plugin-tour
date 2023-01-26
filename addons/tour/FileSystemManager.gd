@tool
###############################################################################
#
# HELPER for FILE SYSTEM DOCK
#

const GQuery = preload("GQuery.gd")

var file_system_dock: FileSystemDock
var file_system_tabs: TabContainer

func setup() -> void:
	file_system_tabs = GQuery.find_ancestor(file_system_dock, func (node: Node) -> bool: return node is TabContainer)


func show() -> void:
	var idx := file_system_tabs.get_tab_idx_from_control(file_system_dock)
	file_system_tabs.current_tab = idx
