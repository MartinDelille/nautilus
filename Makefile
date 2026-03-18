default: e
scene = physic_playground
scene = map

check:
	@if [ -z "$$GODOT_PROGRAM" ]; then echo "GODOT_PROGRAM is not set"; exit 1; fi

e: check
	$$GODOT_PROGRAM project.godot

r: check
	$$GODOT_PROGRAM --path . --scene $(scene).tscn --screen 1

l:
	gdformat *.gd
	gdlint *.gd
	clang-format -i *.gdshader

x: check
	/bin/rm -rf ./export
	mkdir -p ./export
	$$GODOT_PROGRAM --headless --path . --export-release "html" ./export/index.html

generate_compass:
	echo compass/compass.svg | entr inkscape compass/compass.svg --export-type=png --export-filename=compass/compass.png --export-width=2048 --export-height=2048
