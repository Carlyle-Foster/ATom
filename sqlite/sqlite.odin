package sqlite

when ODIN_OS == .Windows {
    foreign import sqlite "../Build/Cache/sqlite.lib"
}
else {
    foreign import sqlite "../Build/Cache/sqlite.a"
}

@(link_prefix="sqlite3_")
foreign sqlite {
    open            :: proc(path: cstring, db: ^^DataBase) -> int ---
    close           :: proc(db: ^DataBase) -> int ---
    exec            :: proc(db: ^DataBase, query: cstring, callback: (proc "c" (rawptr, int, [^]cstring, [^]cstring) -> int), start_value: rawptr, error_msg: ^cstring) -> int ---
    errmsg          :: proc(db: ^DataBase) -> cstring ---
    free            :: proc(memory: rawptr) ---
    //TODO: properly bind C-style varidic args
    db_config       :: proc(db: ^DataBase, verb: ConfigVerb, arg1: int, arg2: int) -> int ---
}
DataBase :: struct {}

ConfigVerb :: enum {
    RESET_DATABASE = 1009,
}
