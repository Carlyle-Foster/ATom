$(shell mkdir -p Build Build/Cache Build/Debug Build/Release)

RAYLIB=$(shell odin root)vendor/raylib/linux/libraylib.a

.PHONY: all 


all: Build/Debug/ATom
	gdb -ex run ./$<

Build/Debug/ATom: Source/*.odin sqlite/sqlite.odin Build/Cache/sqlite.a $(RAYLIB)
	odin build Source -out:$@ -debug

Build/Cache/sqlite.a: sqlite/sqlite3.c
	clang -c $< -o $@ && echo 'built sqlite for linux'
