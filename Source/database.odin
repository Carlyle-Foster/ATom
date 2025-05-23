package ATom

import "core:log"
import "core:fmt"
import "base:runtime"
import "core:strconv"
import "core:strings"
import "core:os"
import "core:time"

import rl "vendor:raylib"

import sqlite "../sqlite"

initializeDatabase :: proc(sql_path: string) -> ^sqlite.DataBase {
    db: ^sqlite.DataBase = nil

    if !os.exists("sqlite/game.db") {
        sqlite.open("sqlite/game.db", &db)
        buildCache(db, sql_path)
    }
    else {
        sqlite.open("sqlite/game.db", &db)
        if cacheOutOfDate(sql_path) {
            rebuildCache(db, sql_path)
        }
    }
    return db
}

cacheOutOfDate :: proc(sql_path: string) -> bool {
    dir, err := os.open(sql_path)
    if err != {} {
        log.panic("failed to open directory", sql_path, os.error_string(err))
    }
    defer os.close(dir)

    fi: os.File_Info
    fi, err = os.stat("sqlite/game.db")
    if err != {} {
        log.panic("")
    }
    cache_mod_time := fi.modification_time
    os.file_info_delete(fi)
    
    instructions: []os.File_Info
    instructions, err = os.read_dir(dir, 128)
    if err != {} {
        log.panic("failed to read directory", sql_path, os.error_string(err))
    }
    defer os.file_info_slice_delete(instructions)
    
    for inst in instructions {
        if time.diff(inst.modification_time, cache_mod_time) <= 0 {
            return true
        }
    }
    return false
}

closeDatabase :: proc(db: ^sqlite.DataBase) { sqlite.close(db) }

buildCache :: proc(db: ^sqlite.DataBase, sql_path: string) {
    dir, err := os.open(sql_path)
    defer os.close(dir)
    if err != {} {
        log.panic("failed to open directory", sql_path, os.error_string(err))
    }
    instructions: []os.File_Info
    instructions, err = os.read_dir(dir, 128)
    defer os.file_info_slice_delete(instructions)
    if err != {} {
        log.panic("failed to read directory", sql_path, os.error_string(err))
    }
    for inst in instructions {
        sql, success := os.read_entire_file(inst.fullpath)
        if !success {
            log.panic("failed to read sql file ", inst.fullpath)
        }
        error_message: cstring
        if sqlite.exec(db, cstring(raw_data(sql)), nil, nil, &error_message) != 0 {
            log.panic("failed to execute sql file on account of:", error_message)
        }
    }
}

rebuildCache :: proc(db: ^sqlite.DataBase, sql_path: string) {
    sqlite.db_config(db, .RESET_DATABASE, 1, 0)
    sqlite.exec(db, "VACUUM", nil, nil, nil)
    sqlite.db_config(db, .RESET_DATABASE, 0, 0)

    buildCache(db, sql_path)
    log.info("rebuilt cache")
}

regenerateManifests :: proc(db: ^sqlite.DataBase, sql_path: string) {
    if cacheOutOfDate(sql_path) {
        rebuildCache(db, sql_path)
    }
    clear(&projectManifest)
    generateTerrainManifest(db)
    generateFactionManifest(db)
    generateUnitTypeManifest(db)
    generateBuildingManifest(db)
    generateTechManifest(db)
}

parser :: proc "c" (_: rawptr, rows: int, values: [^]cstring, _: [^]cstring) -> int

generateManifestGeneric :: proc(db: ^sqlite.DataBase, table: cstring, p: parser) {
    query := strings.clone_to_cstring(fmt.tprint("SELECT * FROM", table))
    defer delete(query)
    error_message: cstring
    if sqlite.exec(db, query, p, nil, &error_message) != 0 {
        log.panic(error_message)
    }
}

generateTerrainManifest :: proc(db: ^sqlite.DataBase) {
    clear(&TerrainManifest)
    generateManifestGeneric(db, "Terrain", defineTerrain)
    
    defineTerrain :: proc "c" (_: rawptr, rows: int, values: [^]cstring, _: [^]cstring) -> int {
        using strconv
        context = runtime.default_context()

        assert(rows == 8)
        name := strings.clone_to_cstring(string(values[0]))
        food, ok1 := parse_f32(string(values[1]))
        production, ok2 := parse_f32(string(values[2]))
        science, ok3 := parse_f32(string(values[3]))
        gold, ok4 := parse_f32(string(values[4]))
        movement_type, ok5 := parseMovementType(string(values[5]))
        _ID, ok6 := parse_int(string(values[6]))
        ID := i32(_ID)
        _spawn_rate, ok7 := parse_int(string(values[7]))
        spawn_rate := i32(_spawn_rate)
        assert(ok1 && ok2 && ok3 && ok4 && ok5 && ok6 && ok7)
        yields : [YieldType]f32 = {
            .FOOD = food, 
            .PRODUCTION = production, 
            .SCIENCE = science, 
            .GOLD = gold,
        }
        log.debug(name)
        append(&TerrainManifest, (Terrain){
                name, 
                ID, 
                yields,
                movement_type, 
                spawn_rate, 
            },
        )
        return 0
    }
}

generateUnitTypeManifest :: proc(db: ^sqlite.DataBase) {
    clear(&UnitTypeManifest)
    generateManifestGeneric(db, "Units", defineUnitType)

    defineUnitType :: proc "c" (_: rawptr, rows: int, values: [^]cstring, _: [^]cstring) -> int {
        using strconv
        context = runtime.default_context()

        assert(rows == 7)
        name := strings.clone_to_cstring(string(values[0]))
        texture := rl.LoadTexture(values[1])
        strength, ok1 := parse_int(string(values[2]))
        defense, ok2 := parse_int(string(values[3]))
        stamina, ok3 := parse_int(string(values[4]))
        habitat, ok4 := parseHabitat(string(values[5]))
        cost, ok5 := parse_int(string(values[6]))
        assert(ok1 && ok2 && ok3 && ok4 && ok5)
        ut := UnitType{
            name, 
            texture,
            i32(strength),
            i32(defense),
            i32(stamina), 
            habitat,
            i32(cost),
        }
        append(&UnitTypeManifest, ut)
        pt := &UnitTypeManifest[len(UnitTypeManifest)-1]
        append(&projectManifest, ProjectType(pt))
        return 0
    }
}

generateBuildingManifest :: proc(db: ^sqlite.DataBase) {
    clear(&BuildingTypeManifest)
    generateManifestGeneric(db, "Buildings", defineBuilding)

    defineBuilding :: proc "c" (_: rawptr, rows: int, values: [^]cstring, _: [^]cstring) -> int {
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
        log.debug(name)
        bt := BuildingType {
            name, 
            texture, 
            yields,
            yield_mults, 
            i32(cost),
        }
        append(&BuildingTypeManifest, bt)
        pt := &BuildingTypeManifest[len(BuildingTypeManifest)-1]
        append(&projectManifest, ProjectType(pt))
        return 0
    }
}

generateFactionManifest :: proc(db: ^sqlite.DataBase) {
    clear(&factionTypeManifest)
    generateManifestGeneric(db, "Factions", defineFaction)
    
    defineFaction :: proc "c" (_: rawptr, rows: int, values: [^]cstring, _: [^]cstring) -> int {
        using strconv
        context = runtime.default_context()

        assert(rows == 3)
        name := strings.clone_to_cstring(string(values[0]))
        primary_color, ok1 := parse_int(string(values[1]))
        secondary_color, ok2 := parse_int(string(values[2]))

        assert(ok1 && ok2)
        log.debug(name)
        append(&factionTypeManifest, FactionType {
                name, 
                rl.GetColor(u32(primary_color)),
                rl.GetColor(u32(secondary_color)),
            },
        )
        return 0
    }
}

generateTechManifest :: proc(db: ^sqlite.DataBase) {
    clear(&TechnologyManifest)
    generateManifestGeneric(db, "Technology", defineTech)
    assert(len(TechnologyManifest) <= MAX_TECHS)
    
    defineTech :: proc "c" (_: rawptr, rows: int, values: [^]cstring, _: [^]cstring) -> int {
        using strconv
        context = runtime.default_context()

        assert(rows == 3)
        @(static) id := 0
        name := strings.clone_to_cstring(string(values[0]))
        unlocks_string := strings.to_lower(string(values[1]))
        unlocks := make([dynamic]ProjectType)
        for raw in strings.split(unlocks_string, ",") {
            target_name := strings.to_lower(strings.trim(raw, " \r\n"))
            for p in projectManifest {
                project_name := strings.to_lower(string(getProjectName(p)))
                if project_name == target_name {
                    append(&unlocks, p)
                    break
                }
            }
        }
        cost, ok := parse_int(string(values[2]))

        assert(ok)
        log.debug(name)
        append(&TechnologyManifest, Technology {
                id,
                name,
                unlocks,
                cost,
            },
        )
        id += 1
        return 0
    }
}

parseMovementType :: proc(s: string) -> (MovementType, bool) {
    mt: MovementType
    switch strings.to_lower(s) {
        case "ocean": mt = .OCEAN
        case "coast": mt = .COAST
        case "land": mt = .LAND
        case "mountain": mt = .MOUNTAIN
        case "city": mt = .CITY
        case: return {}, false
    }
    return mt, true
}

parseHabitat :: proc(s: string) -> (bit_set[MovementType], bool) {
    h: bit_set[MovementType]
    switch strings.to_lower(s) {
        case "land": h = {.LAND, .CITY}
        case "shoreline": h = {.COAST, .CITY}
        case "sea": h = {.COAST, .OCEAN, .CITY}
        case "land+": h = {.LAND, .MOUNTAIN, .CITY}
        case: return {}, false
    }
    return h, true
}