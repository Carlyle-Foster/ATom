$(shell mkdir -p Build Build/Cache Build/Debug Build/Release)

RAYLIB=$(shell odin root)vendor/raylib/linux/libraylib.a

.PHONY: all 


all: Build/Debug/ATom
	./$<

Build/Debug/ATom: first.odin game/game.odin shared/shared.odin cities/cities.odin database/database.odin tiles/tiles.odin units/units.odin ui/ui.odin pathing/pathing.odin technologies/technologies.odin factions/factions.odin pops/pops.odin projects/projects.odin rendering/rendering.odin sqlite/sqlite.odin Build/Cache/sqlite.a $(RAYLIB)
	odin build . -out:$@ -debug

Build/Cache/sqlite.a: sqlite/sqlite3.c
	clang -c $< -o $@ && echo 'built sqlite for linux'
