@tool
###############################################################################
#
# STATIC UTILITIES
#

## Used in `find` to skip processing a node's children
## @see `find`
const SKIP := { skip = true }


## Finds a nested node in the given tree, with a given predicate. The predicate
## receives the node as an argument and:
## - *must* return true if you want to select the node.
## - *may* return the constant `SKIP` if you do not want its children to be processed.
##
## @param target the start of the search. This root _is_ passed to the predicate
## @param {Node -> bool} the predicate to use
## @param max_depth use this to limit the search's depth. Defaults to 40
## @param min_depth use this to determine a minimal depth. Defaults to 0 (which includes the root node)
## @param _current_depth used internally to track the depth. Do not set it
static func find(target: Node, predicate: Callable, max_depth := 40, min_depth := 0, _current_depth := 0) -> Control:
	if _current_depth > max_depth or target == null:
		return null
	if _current_depth >= min_depth:
		var result = predicate.call(target)
		if result == true:
			return target
		if result is Dictionary and result == SKIP:
			return null
	for child in target.get_children():	
		var found := find(child, predicate, max_depth, min_depth, _current_depth + 1)
		if found != null:
			return found
	return null


## Finds a parent node in the given tree, with a given predicate. The predicate
## receives the node as an argument and:
## - *must* return true if you want to select the node.
##
## @param target the start of the search. This root _is_ passed to the predicate
## @param {Node -> bool} the predicate to use
## @param max_depth use this to limit the search's depth. Defaults to 40
## @param min_depth use this to determine a minimal depth. Defaults to 1 (which avoides the root node)
static func find_ancestor(target: Node, predicate: Callable, max_depth := 40, min_depth := 1) -> Control:
	if max_depth <= 0 or target == null:
		return null
	var _current_depth := 0
	while target and _current_depth <= max_depth:
		if _current_depth >= min_depth and predicate.call(target) == true:
			return target
		_current_depth += 1
		target = target.get_parent()
	return null
