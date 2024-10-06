$(shell mkdir -p Build Build/Cache Build/Debug Build/Release)

PATH_TO_RAYLIB_DOT_LIB="" #FILL THIS IN if ur building on windows!

all: Build/Debug/ATom
	./Build/Debug/ATom

Build/Debug/ATom: Build/Cache/ATom.o Build/Cache/sqlite.a
	clang -Wno-unused-command-line-argument Build/Cache/ATom.o  -o $@  -lm -lc \
-L/ -l:$(HOME)/.local/share/odin/vendor/raylib/linux/libraylib.a  -ldl  -lpthread \
-L./Build/Cache -l:sqlite.a -no-pie

Build/Cache/ATom.o: main.odin
	$(HOME)/.local/share/odin/odin build . -out:$@ -build-mode:obj

Build/Cache/sqlite.a: sqlite/sqlite3.c
	clang -c $^ -o $@ && echo 'built sqlite for linux'

#WINDOWS
Build/Debug/ATom.exe: Build/Cache/ATom.obj Build/Cache/sqlite.lib
	cl -Wno-unused-command-line-argument Build/Cache/ATom.obj  -o $@ -lmsvcrt \
-L/ -l:$PATH_TO_RAYLIB_DOT_LIB \
-L./Build/Cache -l:sqlite.lib -no-pie

Build/Cache/ATom.obj: main.odin
	odin build . -out:$@ -build-mode:obj -target:windows_amd64

Build/Cache/sqlite.lib: sqlite/sqlite3.c
	cl -c $^ -o $@ && echo 'built sqlite for windows'




