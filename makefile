$(shell mkdir -p Build Build/Cache Build/Debug Build/Release)

all: Build/Debug/ATom
	./Build/Debug/ATom

Build/Debug/ATom: Build/Cache/ATom.o Build/Cache/sqlite.a
	clang -Wno-unused-command-line-argument Build/Cache/ATom.o  -o Build/Debug/ATom  -lm -lc \
-L/ -l:$(HOME)/.local/share/odin/vendor/raylib/linux/libraylib.a  -ldl  -lpthread \
-L./sqlite -l:sqlite.a -no-pie

Build/Cache/ATom.o: main.odin
	$(HOME)/.local/share/odin/odin build . -out:$@ -build-mode:obj

Build/Cache/sqlite.a: sqlite/sqlite3.c
	clang -c $^ -o $@ && echo 'built sqlite'




