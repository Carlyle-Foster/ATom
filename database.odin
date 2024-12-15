package ATom

import "base:runtime"
import "core:strconv"
import "core:strings"
import "core:os"

import rl "vendor:raylib"

import sqlite "sqlite"

rebuildCache :: proc(db: ^sqlite.DataBase) {
    dir, err := os.open("sqlite/SQL")
    defer os.close(dir)
    if err != {} {
        println("f1")
    }
    instructions: []FileInfo
    instructions, err = os.read_dir(dir, 128)
    defer os.file_info_slice_delete(instructions)
    if err != {} {
        println("f2")
    }
    
    for inst in instructions {
        sql, success := os.read_entire_file(inst.fullpath)
        if !success {
            println("failed to read sql file ", inst.fullpath)
        }
        error_message: cstring
        if sqlite.exec(db, cstring(raw_data(sql)), nil, nil, &error_message) != 0 {
            println(error_message)
        }
    }
}

generateTerrainManifest :: proc(db: ^sqlite.DataBase) {
    query : cstring = "SELECT * FROM  Terrain"
    error_message: cstring
    if sqlite.exec(db, query, defineTerrain, nil, &error_message) != 0 {
        println(error_message)
    }
    println(TerrainManifest)

    defineTerrain :: proc "c" (test: rawptr, rows: int, values: [^]cstring, _: [^]cstring) -> int {
        using strconv
        context = runtime.default_context()

        assert(rows == 7)
        name := strings.clone_to_cstring(string(values[0]))
        food, ok1 := parse_f32(string(values[1]))
        production, ok2 := parse_f32(string(values[2]))
        science, ok3 := parse_f32(string(values[3]))
        gold, ok4 := parse_f32(string(values[4]))
        gate, ok5 := parse_int(string(values[5]))
        hue, ok6 := parse_f32(string(values[6]))
        assert(ok1 && ok2 && ok3 && ok4 && ok5 && ok6)
        yields : [YieldType]f32 = {
            .FOOD = food, 
            .PRODUCTION = production, 
            .SCIENCE = science, 
            .GOLD = gold,
        }
        println(name)
        append(&TerrainManifest, (Terrain){
                name, 
                yields,
                bool(gate), 
                hue,
            },
        )
        return 0
    }
}

generateUnitTypeManifest :: proc(db: ^sqlite.DataBase) {
    query : cstring = "SELECT * FROM  Units"
    error_message: cstring
    if sqlite.exec(db, query, defineUnitType, nil, &error_message) != 0 {
        println(error_message)
    }
    println(UnitTypeManifest)

    defineUnitType :: proc "c" (test: rawptr, rows: int, values: [^]cstring, _: [^]cstring) -> int {
        using strconv
        context = runtime.default_context()

        assert(rows == 5)
        name := strings.clone_to_cstring(string(values[0]))
        texture := rl.LoadTexture(values[1])
        println("texture =", texture)
        strength, ok1 := parse_int(string(values[2]))
        defense, ok2 := parse_int(string(values[3]))
        cost, ok3 := parse_int(string(values[4]))
        assert(ok1 && ok2 && ok3)
        println(name)
        append(&UnitTypeManifest, UnitType{
                name, 
                texture,
                i32(strength),
                i32(defense), 
                i32(cost),
            },
        )
        return 0
    }
}

generateBuildingManifest :: proc(db: ^sqlite.DataBase) {
    query : cstring = "SELECT * FROM  Buildings"
    error_message: cstring
    if sqlite.exec(db, query, defineBuilding, nil, &error_message) != 0 {
        println(error_message)
    }
    println(BuildingTypeManifest)

    defineBuilding :: proc "c" (test: rawptr, rows: int, values: [^]cstring, _: [^]cstring) -> int {
        using strconv
        context = runtime.default_context()

        assert(rows == 11)
        name := strings.clone_to_cstring(string(values[0]))
        texture := rl.LoadTexture(values[1])
        food, ok1 := parse_f32(string(values[2]))
        production, ok2 := parse_f32(string(values[3]))
        science, ok3 := parse_f32(string(values[4]))
        gold, ok4 := parse_f32(string(values[5]))
        food_mult, ok5 := parse_f32(string(values[6]))
        production_mult, ok6 := parse_f32(string(values[7]))
        science_mult, ok7 := parse_f32(string(values[8]))
        gold_mult, ok8 := parse_f32(string(values[9]))
        cost, ok9 := parse_int(string(values[10]))
        assert(ok1 && ok2 && ok3 && ok4 && ok5 && ok6 && ok7 && ok8 && ok9)
        yields : [YieldType]f32 = {
            .FOOD = food, 
            .PRODUCTION = production, 
            .SCIENCE = science, 
            .GOLD = gold,
        }
        yield_mults : [YieldType]f32 = {
            .FOOD = food_mult, 
            .PRODUCTION = production_mult, 
            .SCIENCE = science_mult, 
            .GOLD = gold_mult,
        }
        println(name)
        append(&BuildingTypeManifest, BuildingType {
                name, 
                texture, 
                yields,
                yield_mults, 
                i32(cost),
            },
        )
        return 0
    }
}