#IMPORTANT: here we assume make executes $() using cmd and not powershell

#windows aliases mkdir to md, but it doesn't support -p
define make_directory
	if not exist $(1) (md $(1))
endef
$(call, make_directory, Build)
$(call, make_directory, Build\Cache)
$(call, make_directory, Build\Debug)
$(call, make_directory, Build\Release)

RAYLIB=$(shell odin root)vendor\raylib\windows\raylib.lib

.PHONY: all


all: Build\Debug\ATom.exe
	$<

Build\Debug\ATom.exe: main.odin sqlite\sqlite.odin Build\Cache\sqlite.lib $(RAYLIB)
	odin build . -out:$@ -target:windows_amd64

Build\Cache\sqlite.lib: Build\Cache\sqlite.obj
	lib $< /OUT:$@ && del $< && echo 'built sqlite for windows'

Build\Cache\sqlite.obj: sqlite\sqlite3.c
	cl /c $< && move /Y sqlite3.obj $@