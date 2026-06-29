@tool
extends RefCounted

class_name GodotMCPCallableTool

## Thin wrapper that adapts a Callable into a tool object the registry can store.
## Usage: GodotMCPCallableTool.new(func(args): return {...})

var _fn: Callable

func _init(fn: Callable) -> void:
	_fn = fn

func execute(args: Dictionary) -> Variant:
	return await _fn.call(args)
