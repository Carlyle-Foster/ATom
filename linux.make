$(shell mkdir -p Build Build/Cache Build/Debug Build/Release)

RAYLIB=$(shell odin root)vendor/raylib/linux/libraylib.a

.PHONY: all 


all: Build/Debug/ATom
	./$<

Build/Debug/ATom: main.odin cities.odin database.odin tiles.odin units.odin sqlite/sqlite.odin Build/Cache/sqlite.a $(RAYLIB)
	odin build . -out:$@ -debug

Build/Cache/sqlite.a: sqlite/sqlite3.c
	clang -c $< -o $@ && echo 'built sqlite for linux'
