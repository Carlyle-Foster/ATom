RAYLIB_DOT_LIB="$(odin root)vendor\raylib\windows\raylib.lib"

.PHONY: all linux windows build_dir_lin Build_dir_win

all: linux

linux: Build/Debug/ATom
	./$@

build_dir_posix:
	$(shell mkdir -p Build Build/Cache Build/Debug Build/Release)

Build/Debug/ATom: Build/Cache/ATom.o Build/Cache/sqlite.a build_dir_lin
	clang -Wno-unused-command-line-argument $<  -o $@  -lm -lc \
-L/ -l:$(HOME)/.local/share/odin/vendor/raylib/linux/libraylib.a  -ldl  -lpthread \
-L./Build/Cache -l:sqlite.a -no-pie

Build/Cache/ATom.o: main.odin build_dir_lin
	$(HOME)/.local/share/odin/odin build . -out:$@ -build-mode:obj

Build/Cache/sqlite.a: sqlite/sqlite3.c build_dir_lin
	clang -c $^ -o $@ && echo 'built sqlite for linux'

#WINDOWS

#IMPORTANT: here we assume make executes $() using cmd and not powershell

#windows aliases mkdir to md, but it doesn't support -p
define make_directory
	if not exist $(1) (md $(1))
endef

windows: Build\Debug\ATom.exe
	$@

build_dir_win:
	$(call make_directory, "Build")
	$(call make_directory, "Build\Cache")
	$(call make_directory, "Build\Debug")
	$(call make_directory, "Build\Release")

Build\Debug\ATom.exe: Build\Cache\ATom.obj Build\Cache\sqlite.lib build_dir_win
	cl $<  /Fe:$@ /link msvcrt.lib $(RAYLIB_DOT_LIB) Build\Cache\sqlite.lib

Build\Cache\ATom.obj: main.odin build_dir_win
	odin build . -out:$@ -build-mode:obj -target:windows_amd64

Build\Cache\sqlite.lib: Build\Cache\sqlite.obj build_dir_win
	lib $< /OUT:$@ && echo 'built sqlite for windows' && del $<

Build\Cache\sqlite.obj: sqlite\sqlite3.c build_dir_win
	cl /c $< && move /Y sqlite3.obj $@




