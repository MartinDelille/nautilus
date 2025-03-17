include .env

default: g

check:
	@if [ -z "$$GODOT_PROGRAM" ]; then echo "GODOT_PROGRAM is not set"; exit 1; fi

g: check
	$$GODOT_PROGRAM project.godot

r: check
	$$GODOT_PROGRAM --path .&
	sleep 2
	osascript -e 'tell application "Ghostty" to activate'


l:
	gdformat *.gd
	gdlint *.gd
	clang-format -i *.gdshader
