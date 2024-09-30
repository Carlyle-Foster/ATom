package ATom

import "core:fmt"
import "core:os"
import "core:time"
import "core:math"
import "core:math/rand"
import "core:container/small_array"

import rl "vendor:raylib"

import sqlite "sqlite"

playerID: factionID = 0

cities := [dynamic]City{}
units := [dynamic]Unit{}
factions := [dynamic]Faction{}

buttons := make([dynamic]Button, 0, 128)

mapDimensions: [2]i32
gameMap: [dynamic]Tile

windowDimensions :: Vector2{1280, 720}

tileSize: i32 = 64

cam: rl.Camera2D = {}
mousePosition := Vector2{}
mouseMovement := Vector2{}
leftMouseDown := false

factionID   :: u16
cityID      :: u16
unitID      :: u16

color :: rl.Color
Vector2 :: rl.Vector2
Rect :: rl.Rectangle
coordinate :: [2]i16

println :: fmt.println
FileInfo :: os.File_Info


textures: TextureManifest = {}
TextureManifest :: struct {
    city: rl.Texture,
    valet: rl.Texture,
}

YieldType :: enum i8 {
    FOOD,
    PRODUCTION,
    GOLD,
    SCIENCE,
}

TerrainType :: enum i16 {
    NO_TERRAIN = -1,
    DESERT,
    SEMIDESERT,
    BOREAL,
    MEADOW,
    HIGHLANDS,
    BOG,
    SHALLOWS,
    SEA,
    OCEAN,
    RAINFOREST,
    OLDGROWTH,
    TERRAIN_TYPE_COUNT,
}

Terrain :: struct {
    yields: [YieldType]i32,
}

TerrainManifest := #partial [TerrainType]Terrain{
    .DESERT = {{.FOOD = 0, .PRODUCTION = 1, .GOLD = 0, .SCIENCE = 1}},
    .RAINFOREST = {{.FOOD = 2, .PRODUCTION = 0, .GOLD = 1, .SCIENCE = 1}},
    .SHALLOWS = {{.FOOD = 1, .PRODUCTION = 0, .GOLD = 1, .SCIENCE = 1}},
}

ResourceType :: enum i16 {
    NO_RESOURCE = -1,
    PLATINUM,
    SILVER,
    JEWELS,
    BANANAS,
    CARPETS,
    PEARLS,
    IVORY,
    COCOA,
    FISHES,
    SHARKS,
    COFFEE,
    RESOURCE_TYPE_COUNT,
}

unitType :: enum i16 {
    NO_UNIT = -1,
    VALET,
    SETTLER,
    UNIT_TYPE_COUNT,
}

Tile :: struct {
    terrain: TerrainType,
    resource: ResourceType,
    owner: ^City,
    discovery_mask: u64,
    visibility_mask: u64,
}

City :: struct {
    owner: factionID,
    population: f32,
    location: coordinate,
    tiles: [dynamic]coordinate,
}

Unit :: struct {
    type: unitType,
    owner: factionID,
    position: coordinate,
}

Faction :: struct {
    cities: [dynamic]cityID,
    units:  [dynamic]unitID,
};

Button :: struct {
    rect: Rect,
    color: color,
    text: cstring,
}

getTileYields :: proc(tile: ^Tile) -> [YieldType]i32 {
    return TerrainManifest[tile.terrain].yields
}

getTileDestructured ::proc(x, y: i32) -> []Tile {
    if (x < 0 || x >= mapDimensions.x) || (y < 0 || y >= mapDimensions.y) {
        return {}
    }
    else {
        location := x + y*mapDimensions.x
        return gameMap[location:location+1]
    }
}

getTileByCoordinates ::proc(c: coordinate) -> []Tile {
    if (c.x < 0 || c.x >= i16(mapDimensions.x)) || (c.y < 0 || c.y >= i16(mapDimensions.y)) {
        return {}
    }
    else {
        location := i32(c.x) + i32(c.y)*mapDimensions.x
        return gameMap[location:location+1]
    }
}

getTile :: proc{getTileByCoordinates, getTileDestructured}

forTileInRadius :: proc(center: coordinate, range: i16, callback: proc([]Tile)) {
    for y in -range..=range {
        for x in -range..=range {
            t := getTile(coordinate{center.x + x, center.y + y})
            if t != nil {
                callback(t)
            }
        }
    }
}

generateMap :: proc() {
    offCenter := 0.0
    radius := 0.0
    archetype := Tile{.DESERT, .NO_RESOURCE, nil, 0, 0}
    prototype := Tile{.RAINFOREST, .COCOA, nil, 0, 0}
    for y in 0..<mapDimensions.y {
        for x in 0..<mapDimensions.x {
            offCenter   =   math.abs(f64(x)/f64(mapDimensions.x) - 0.5)*2.0;
            radius      =   math.sin(f64(y) / f64(mapDimensions.y) * math.PI);
            //fmt.println("offCentre: ", offCenter, "radius: ", radius)
            if radius > offCenter {
                r := rl.GetRandomValue(0, 24)
                if r == 0 {
                    getTile(x,y)[0]  = (Tile){.SHALLOWS, .PEARLS, nil, 0, 0};
                }
                else {
                    getTile(x,y)[0]  = prototype;
                }
            }
            else {
                getTile(x,y)[0] = archetype;
            }
        }
    }
}

drawMap :: proc() {
    tile := Tile{}
    color := color{}
    size := i32(tileSize)
    for y in 0..<mapDimensions.y {
        for x in 0..<mapDimensions.x {
            tile = gameMap[x + y*mapDimensions.x]
            #partial switch tile.terrain {
                case .NO_TERRAIN:   fmt.println("wtf")
                case .DESERT:       color = rl.YELLOW;
                case .SEMIDESERT:   color = rl.BROWN
                case .BOREAL:       color = rl.GetColor(0x181818ff)
                case .MEADOW:       color = rl.GREEN
                case .HIGHLANDS:    color = rl.GetColor(0x468f0fff)
                case .BOG:          color = rl.LIGHTGRAY
                case .SHALLOWS:     color = rl.SKYBLUE
                case .SEA:          color = rl.BLUE
                case .OCEAN:        color = rl.DARKBLUE
                case .RAINFOREST:   color = rl.DARKGREEN
                case .OLDGROWTH:    color = rl.GetColor(0x64442eff)
            }
            if tile.discovery_mask & (1 << playerID) > 0 {
                rl.DrawRectangle(x*size, y*size, size, size, color);
            }
        }
    }
    drawCities();
    drawUnits();
}

drawCities :: proc() {
    for city in cities {
        drawCity(city)
    }
    drawCity :: proc(city: City) {
        rl.DrawTextureEx(textures.city, Vector2{f32(i32(city.location.x)*tileSize), f32(i32(city.location.y)*tileSize)}, 0.0, 0.5, rl.WHITE);
    }
}

drawBanners :: proc() {
    for city in cities {
        drawBanner(city)
    }
    drawBanner :: proc(city : City) {
        width : i32 = 82
        height : i32 = 28
        lift : i32 = 20
        rl.DrawRectangle(i32(city.location.x)*tileSize + (tileSize - width)/2, i32(city.location.y)*tileSize - lift, width, height, rl.GetColor(0x992299bb))
    }
}

drawUnits :: proc() {
    for unit in units {
        drawUnit(unit)
    }
    drawUnit :: proc(unit: Unit) {
        rl.DrawTextureEx(textures.valet, Vector2{f32(i32(unit.position.x)*tileSize), f32(i32(unit.position.y)*tileSize)}, 0.0, 0.5, rl.WHITE);
    }
}

updateCamera :: proc() {
    if rl.IsMouseButtonDown(.LEFT) {
        if rl.IsMouseButtonPressed(.LEFT) {
            mouseMovement = Vector2{}
        }
        cam.target -= mouseMovement
    }
    cam.zoom += rl.GetMouseWheelMoveV().y / 10.0
}

updateCity :: proc(c: ^City) {
    c.population *= 1.1
    println("Population: ", c.population)
}

nextTurn :: proc() {
    println("turn")
    for &city in cities {
        updateCity(&city)
    }
}

showButton :: proc(rect: Rect, color: color, text: cstring) -> bool {
    append(&buttons, Button{rect, color, text})
    return rl.CheckCollisionPointRec(mousePosition, rect)
}

updateState :: proc() {
    lastMousePostion := mousePosition
    mousePosition = rl.GetMousePosition()
    mouseMovement = rl.GetScreenToWorld2D(mousePosition, cam) - rl.GetScreenToWorld2D(lastMousePostion, cam)

    updateCamera()
    
    if showButton({1280 - 164, 720 - 48, 164, 48},rl.GetColor(0x161616ff), "NEXT TURN") {
        if rl.IsMouseButtonPressed(.LEFT) {
            nextTurn()
        }
    }

    worldMouse := rl.GetScreenToWorld2D(mousePosition, cam) / f32(tileSize)
    tileUnderMouse := getTile(i32(worldMouse.x), i32(worldMouse.y))
    if rl.IsMouseButtonPressed(.LEFT) && tileUnderMouse != nil {
        createUnit(.VALET, 0, coordinate{i16(worldMouse.x), i16(worldMouse.y)})
    }
    else if rl.IsMouseButtonPressed(.RIGHT) && tileUnderMouse != nil {
        createCity(0, coordinate{i16(worldMouse.x), i16(worldMouse.y)})
    }
    //println(tileUnderMouse)
}

createUnit :: proc(t: unitType, f: factionID, c: coordinate) {
    newUnit := Unit{t, f, c}
    unitEntered(newUnit, c)
    append(&units, newUnit)
    println("new unit: ", newUnit)
}

createCity :: proc(f: factionID, c: coordinate) {
    newCity := City{f, 1.0, c, {c}}
    append(&cities, newCity)
    println("new city: ", newCity)
}

unitEntered :: proc(u: Unit, c: coordinate) {
    visibility: i16 = 5
    forTileInRadius(c, visibility, discover)
    discover :: proc(t: []Tile) {
        t[0].discovery_mask = 1
    }
}

drawButtons :: proc() {
    for button in buttons {
        rl.DrawRectangleRec(button.rect, button.color)
        textColor := rl.GetColor(0xaaaaffff)
        fontSize: i32 = 24
        textWidth := rl.MeasureText(button.text, fontSize)
        textX := i32(button.rect.x) + (i32(button.rect.width) - textWidth)/2
        textY := i32(button.rect.y) + (i32(button.rect.height) - fontSize)/2
        rl.DrawText(button.text, textX, textY, fontSize, textColor)
    }
    clear(&buttons)
}

renderState :: proc() {
    rl.BeginDrawing()
    rl.BeginMode2D(cam)
    rl.ClearBackground(rl.GetColor(0x181818ff))
    drawMap()
    drawBanners()
    rl.EndMode2D()
    drawButtons()
    rl.EndDrawing()
}

rebuildCache :: proc(db: ^sqlite.DataBase) {
    //println("WARNING: cache invalidation not yet implemented")
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

main :: proc() {
    //rl.SetRandomSeed(u32(time.now()._nsec))
    rl.SetRandomSeed(2)

    db: ^sqlite.DataBase = nil
    if !os.exists("sqlite/game.db") {
        sqlite.open("sqlite/game.db", &db)
        rebuildCache(db)
    }
    else {
        sqlite.open("sqlite/game.db", &db)
    }
    defer sqlite.close(db)

    {
        dir, err := os.open("sqlite/SQL")
        defer os.close(dir)
        if err != {} {
            println("f3")
        }

        fi: FileInfo
        fi, err = os.stat("sqlite/game.db")
        if err != {} {
            println("f4")
        }
        cache_mod_time := fi.modification_time
        os.file_info_delete(fi)
        
        instructions: []FileInfo
        instructions, err = os.read_dir(dir, 128)
        defer os.file_info_slice_delete(instructions)
        if err != {} {
            println("f5")
        }
        
        for inst in instructions {
            if time.diff(inst.modification_time, cache_mod_time) <= 0 {
                sqlite.db_config(db, .RESET_DATABASE, 1, 0)
                sqlite.exec(db, "VACUUM", nil, nil, nil)
                sqlite.db_config(db, .RESET_DATABASE, 0, 0)
                rebuildCache(db)
                break;
            }
        }
    }

    mapDimensions = {36, 36}
    cam = {windowDimensions/2.0, Vector2{f32(mapDimensions.x*tileSize/2), f32(mapDimensions.y*tileSize/2)}, 0.0, 1.0}
    println(cam.target)
    gameMap = make([dynamic]Tile, mapDimensions.x * mapDimensions.y)
    generateMap()
    
    append(&factions, Faction{cities = {}, units = {}})
    
    rl.SetConfigFlags(rl.ConfigFlags{.VSYNC_HINT})
    rl.InitWindow(i32(windowDimensions.x), i32(windowDimensions.y), "ATom")
    defer rl.CloseWindow()

    textures.city = rl.LoadTexture("Assets/Sprites/townsend.png")
    defer rl.UnloadTexture(textures.city)
    textures.valet = rl.LoadTexture("Assets/Sprites/adude.png")
    defer rl.UnloadTexture(textures.valet)
    
    for !rl.WindowShouldClose() {
        updateState()
        renderState()
    }
}