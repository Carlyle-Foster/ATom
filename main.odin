package ATom

import "core:fmt"
import "core:strings"
import "core:os"
import "core:time"
import "core:math"

import rl "vendor:raylib"

import sqlite "sqlite"

playerFaction: ^Faction = {}

cities := [dynamic]City{}
units := [dynamic]Unit{}
factions := [dynamic]Faction{}

mapDimensions: [2]i32
gameMap: [dynamic]Tile

windowDimensions :: Vector2{1280, 720}

windowRect: Rect = {}

tileSize: i32 = 64

POP_DIET: f32 = 2.0

cam: rl.Camera2D = {}
camNoZoom: rl.Camera2D = {}
mousePosition := Vector2{}
mouseMovement := Vector2{}
leftMouseDown := false

selectedCity: ^City = {}
selectedUnit: ^Unit = {}

Color :: rl.Color
Vector2 :: rl.Vector2
Rect :: rl.Rectangle
Coordinate :: [2]i16

println :: fmt.println

FileInfo :: os.File_Info

textures: TextureManifest = {}
TextureManifest :: struct {
    city: rl.Texture,
    valet: rl.Texture,
    pop: rl.Texture,
}

YieldType :: enum i8 {
    FOOD,
    PRODUCTION,
    GOLD,
    SCIENCE,
}

// TerrainType :: enum i16 {
//     NO_TERRAIN = -1,
//     DESERT,
//     SEMIDESERT,
//     BOREAL,
//     MEADOW,
//     HIGHLANDS,
//     BOG,
//     SHALLOWS,
//     SEA,
//     OCEAN,
//     RAINFOREST,
//     OLDGROWTH,
//     TERRAIN_TYPE_COUNT,
// }

Terrain :: struct {
    name: cstring,
    yields: [YieldType]f32,
    gate: bool,
    hue: f32,
}

Pop :: struct {
    state: enum {
        WORKING,
        UNEMPLOYED,
    },
    tile: ^Tile,
}

new_pop :: proc(t: ^Tile) -> Pop {
    return Pop{.UNEMPLOYED, t}
}

TerrainManifest : [dynamic]Terrain = {}
UnitTypeManifest : [dynamic]UnitType = {}
BuildingTypeManifest: [dynamic]BuildingType = {}
projectManifest: [dynamic]ProjectType = {}

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

BuildingType :: struct {
    name: cstring,
    texture: rl.Texture,
    yields: [YieldType]f32,
    multipliers: [YieldType]f32,
    cost: i32,
}

Building :: struct {
    type: BuildingType,
}

createBuilding :: proc(t: BuildingType, c: ^City) -> ^Building {
    building := Building {
        type = t,
    }
    println("BUILT:", building)
    append(&c.buildings, building)
    return &c.buildings[len(c.buildings) - 1]
}

ProjectType :: union {
    UnitType,
    BuildingType,
}

getProjectCost :: proc(p: ProjectType) -> i32 {
    switch type in p {
        case UnitType: {
            return type.cost
        }
        case BuildingType: {
            return type.cost
        }
        case: {
            panic("")
        }
    }
}

Faction :: struct {
    id: u32,
    cities: [dynamic]^City,
    units:  [dynamic]^Unit,
    gold: f32,
}

nextFactionID :: proc() -> u32 {
    @(static) id :u32 = 0
    value := id
    id += 1
    return value
}

rectsToDraw := make([dynamic]UI_Rect, 0, 64)
textToDraw := make([dynamic]UI_Text, 0, 64)
spritesToDraw := make([dynamic]UI_Sprite, 0, 64)

DrawMode :: enum {
    MAP,
    UI,
}

UI_Rect :: struct {
    rect: Rect,
    color: Color,
    mode: DrawMode,
}

UI_Text :: struct {
    text: cstring,
    rect: Rect,
    color: Color,
    align: Alignment,
    mode: DrawMode,
}

UI_Sprite :: struct {
    texture: rl.Texture,
    rect: Rect,
    mode: DrawMode,
}

generateMap :: proc() {
    offCenter := 0.0
    radius := 0.0
    for y in 0..<mapDimensions.y {
        for x in 0..<mapDimensions.x {
            offCenter   =   math.abs(f64(x)/f64(mapDimensions.x) - 0.5)*2.0
            radius      =   math.sin(f64(y) / f64(mapDimensions.y) * math.PI)
            //fmt.println("offCentre: ", offCenter, "radius: ", radius)
            c := Coordinate{i16(x),i16(y)}
            if radius > offCenter {
                r := rl.GetRandomValue(0, 24)
                if r == 0 {
                    getTile(c)^  = createTile(c, TerrainManifest[0], .PEARLS)
                }
                else {
                    getTile(c)^  = createTile(c, TerrainManifest[1], .PLATINUM)
                }
            }
            else {
                getTile(c)^ = createTile(c, TerrainManifest[2], .PLATINUM)
            }
        }
    }
}

drawMap :: proc() {
    tile := Tile{}
    color := Color{}
    size := i32(tileSize)
    for y in 0..<mapDimensions.y {
        for x in 0..<mapDimensions.x {
            tile = gameMap[x + y*mapDimensions.x]
            color = rl.ColorFromHSV(tile.terrain.hue, 0.65, 1)
            if tile.discovery_mask & (1 << playerFaction.id) > 0 {
                rl.DrawRectangle(x*size, y*size, size, size, color)
            }
        }
    }
    drawCities()
    drawUnits()
}

showBanners :: proc() {
    for city in cities {
        showBanner(city)
    }
    showBanner :: proc(using city : City) {
        scale := 1.0 / cam.zoom
        lift := i32(20.0*scale)
        x: i32 = i32(location.coordinate.x)*tileSize + tileSize/2
        y: i32 = i32(location.coordinate.y)*tileSize - lift 
        width := i32(128.0*scale)
        height := i32(32.0*scale)
        rect := Rect{f32(x - width/2), f32(y), f32(width), f32(height)}
        showRect(rect, rl.GetColor(0xaa2299bb), .MAP)
        pop_rect := chopRectangle(&rect, rect.width/4, .LEFT)
        showText(rect, rl.GetColor(0x5299ccbb), name, ALIGN_LEFT, .MAP)
        builder := strings.builder_make()
        strings.write_int(&builder, len(population))
        pop_text := strings.to_cstring(&builder)
        showText(pop_rect, rl.GOLD, pop_text, ALIGN_CENTER, .MAP)
    }
}

showSidebar :: proc(r: Rect) {
    r := r
    padding :: 1.45
    assert(selectedCity != nil)
    
    showRect(r, rl.PURPLE, .UI)
    text: cstring = selectedCity != {} ? selectedCity.name : "NULL"
    title_rect := chopRectangle(&r, r.height/5.0, .TOP)
    entry_size := r.height/5
    showRect(title_rect, rl.GetColor(0x992465ff), .UI)
    showText(title_rect, rl.GetColor(0x229f54ff), text, ALIGN_CENTER, .UI)
    for project in projectManifest {
        name: cstring 
        texture: rl.Texture  
        switch type in project {
            case UnitType: {
                name = type.name
                texture = type.texture
            }
            case BuildingType: {
                name = type.name
                texture = type.texture
            }
        }
        entry_rect := chopRectangle(&r, entry_size, .TOP)
        if showButton(entry_rect, rl.PURPLE, .UI) {
            if rl.IsMouseButtonPressed(.LEFT) {
                selectedCity.project = project
            }
        }
        sprite_rect := chopRectangle(&entry_rect, f32(texture.width/2), .LEFT)
        showSprite(sprite_rect, texture, .UI)
        entry_rect = subRectangle(entry_rect, 1.0, 0.35, ALIGN_LEFT, ALIGN_TOP)
        showRect(entry_rect, rl.GetColor(0x18181899), .UI)
        entry_rect = subRectangle(entry_rect, 0.97, 0.77, ALIGN_RIGHT, ALIGN_TOP)
        showText(entry_rect, rl.GetColor(0xaaaaffff), name, ALIGN_LEFT, .UI, rl.GOLD)
    }
}



chopRectangle :: proc(r: ^Rect, size: f32, side: enum{TOP, BOTTOM, LEFT, RIGHT}) -> Rect {
    x, y: f32
    width, height: f32
    switch side {
        case .TOP: {
            x = r.x
            y = r.y
            width = r.width
            height = size
            r.y += size
            r.height -= size
        }
        case .BOTTOM: {
            x = r.x
            y = r.y + r.height - size
            width = r.width
            height = size
            r.height -= size
        }
        case .LEFT: {
            x = r.x
            y = r.y
            width = size
            height = r.height
            r.x += size
            r.width -= size
        }
        case .RIGHT: {
            x = r.x + r.width - size
            y = r.y
            width = size
            height = r.height
            r.width -= size
        }
    }
    return Rect{x, y, width, height}
}

subRectangleRaw :: proc(r: Rect, x_percent, y_percent: f32, w, h: f32) -> Rect {
    return Rect {
        x = r.x + r.width * x_percent,
        y = r.y + r.height * y_percent,
        width = w,
        height = h,
    }
}

Alignment :: enum i8 {
    START,
    HALFWAY,
    END,
}

ALIGN_LEFT :: Alignment.START
ALIGN_TOP :: Alignment.START
ALIGN_CENTER :: Alignment.HALFWAY
ALIGN_RIGHT :: Alignment.END
ALIGN_BOTTOM :: Alignment.END

subRectangleCooked :: proc(r: Rect, w_percent, h_percent: f32, x_align, y_align: Alignment) -> Rect {
    x, y: f32
    switch x_align {
        case .START: x = 0
        case .HALFWAY: x = 0.5 - w_percent/2
        case .END: x = 1.0 - w_percent
    }
    switch y_align {
        case .START: y = 0
        case .HALFWAY: y = 0.5 - h_percent/2
        case .END: y = 1.0 - h_percent
    }
    return subRectangleRaw(r, x, y, r.width*w_percent, r.height*h_percent)
}

subRectangle :: proc{subRectangleRaw, subRectangleCooked}



updateCamera :: proc() {
    if rl.IsMouseButtonDown(.LEFT) {
        if rl.IsMouseButtonPressed(.LEFT) {
            mouseMovement = Vector2{}
        }
        cam.target -= mouseMovement
        camNoZoom.target = cam.target
    }
    cam.zoom += rl.GetMouseWheelMoveV().y / 10.0
}

nextTurn :: proc() {
    for &city in playerFaction.cities {
        if city.project == nil {
            selectedCity = city
            return
        }
    }
    println("turn")
    for &city in cities {
        updateCity(&city)
    }
}

showRect :: proc(rect: Rect, color: Color, mode: DrawMode) {
    append(&rectsToDraw, UI_Rect{rect, color, mode})
}

showSprite :: proc(rect: Rect, sprite: rl.Texture, mode: DrawMode, background: Color = rl.BLANK) {
    if background != rl.BLANK {
        showRect(rect, background, mode)
    }
    append(&spritesToDraw, UI_Sprite{sprite, rect, mode})
}

showText :: proc(rect: Rect, color: Color, text: cstring, align: Alignment, mode: DrawMode, background: Color = rl.BLANK) {
    if background != rl.BLANK {
        showRect(rect, background, mode)
    }
    inlay_rect := subRectangle(rect, 1.0, 0.8, ALIGN_CENTER, ALIGN_CENTER)
    append(&textToDraw, UI_Text{text, inlay_rect, color, align, mode})
}

showButton :: proc(rect: Rect, color: Color, mode: DrawMode, text: cstring = "") -> bool {
    showText(rect, rl.GetColor(0xaaaaffff), text, ALIGN_LEFT, mode, color)
    return rl.CheckCollisionPointRec(mousePosition, rect)
}

updateState :: proc() {
    did_something := false
    lastMousePostion := mousePosition
    mousePosition = rl.GetMousePosition()
    mouseMovement = rl.GetScreenToWorld2D(mousePosition, cam) - rl.GetScreenToWorld2D(lastMousePostion, cam)

    updateCamera()
    
    if showButton( 
        subRectangle(windowRect, 0.36, 0.09, ALIGN_RIGHT, ALIGN_BOTTOM), 
        rl.GetColor(0x161616ff), 
        .UI,
        "NEXT TURN",
    ) {
        if rl.IsMouseButtonPressed(.LEFT) {
            did_something = true
            nextTurn()
        }
    }
    if selectedCity != nil {
        showSidebar(subRectangle(windowRect, 0.2, 0.8, ALIGN_LEFT, ALIGN_CENTER))
    }
    worldMouse := rl.GetScreenToWorld2D(mousePosition, cam) / f32(tileSize)
    tileUnderMouse := getTile(i32(worldMouse.x), i32(worldMouse.y))
    if rl.IsMouseButtonPressed(.LEFT) && tileUnderMouse != nil {
        // createUnit(UnitTypeManifest[0], 0,Coordinate{i16(worldMouse.x), i16(worldMouse.y)})
        if selectedCity != nil && tileUnderMouse.owner == selectedCity {
            candidate : ^Pop = nil
            last_index := len(selectedCity.population) - 1
            for &pop, index in selectedCity.population {
                if pop.tile == tileUnderMouse && pop.state == .WORKING {
                    pop.state = .UNEMPLOYED
                    candidate = nil
                    did_something = true
                    break
                }
                if candidate == nil && (pop.state == .UNEMPLOYED || index ==  last_index) {
                    candidate = &pop
                }
            }
            if candidate != nil {
                candidate.state = .WORKING
                candidate.tile = tileUnderMouse
                did_something = true
            }
        }
        println(tileUnderMouse.terrain.name)
        if !did_something { selectedCity = nil }
        for &city in cities {
            if tileUnderMouse == city.location {
                selectedCity = &city
            }
        }
        if len(tileUnderMouse.units) > 0 {
            selectedUnit = tileUnderMouse.units[0]
            println("selected a UNIT")
        }
    }
    else if rl.IsMouseButtonPressed(.RIGHT) && tileUnderMouse != nil {
        createCity(playerFaction, tileUnderMouse)
    }
    showBorders()
    showBanners()
}

getCityPopCost :: proc(c: City) -> f32 {
    base := 10
    mult := 5
    return f32(base + len(c.population)*mult)
}

unitEntered :: proc(u: ^Unit, t: ^Tile) {
    append(&t.units, u)
    visibility: i16 = 5
    for tile in getTilesInRadius(t.coordinate, visibility) {
        tile.discovery_mask = 1
    }
}

drawMapStuff :: proc() {
    for rect in rectsToDraw {
        if rect.mode == .MAP {
            rl.DrawRectangleRec(rect.rect, rect.color)
        }
    }
    for text in textToDraw {
        if text.mode == .MAP {
            drawText(text)
        }
    }
    for sprite in spritesToDraw {
        if sprite.mode == .MAP {
            rl.DrawTextureEx(sprite.texture, Vector2{sprite.rect.x, sprite.rect.y}, 1.0, 0.5, rl.WHITE)
        }
    }

    drawText :: proc(using t: UI_Text) {
        fontSize := i32(t.rect.height)
        textWidth := rl.MeasureText(text, fontSize)
        x: i32
        switch align {
            case ALIGN_LEFT: x = i32(rect.x)
            case ALIGN_CENTER: x = i32(rect.x) + (i32(rect.width) - textWidth)/2
            case ALIGN_RIGHT: x = i32(rect.x) + (i32(rect.width) - textWidth)
        }
        y := i32(rect.y) + (i32(rect.height) - fontSize)/2
        rl.DrawText(text, x, y, fontSize, color)
    }

    drawSprite  :: proc(using s: UI_Sprite) {
        scale := min(rect.width/f32(texture.width), rect.height/f32(texture.height))
        rl.DrawTextureEx(texture, Vector2{rect.x, rect.y}, 1.0, scale, rl.WHITE)
    }
}

drawUI :: proc() {
    for rect in rectsToDraw {
        if rect.mode == .UI {
            rl.DrawRectangleRec(rect.rect, rect.color)
        }
    }
    for text in textToDraw {
        if text.mode == .UI {
            drawText(text)
        }
    }
    for sprite in spritesToDraw {
        if sprite.mode == .UI {
            rl.DrawTextureEx(sprite.texture, Vector2{sprite.rect.x, sprite.rect.y}, 1.0, 0.5, rl.WHITE)
        }
    }
    clear(&rectsToDraw)
    clear(&textToDraw)
    clear(&spritesToDraw)

    drawText :: proc(using t: UI_Text) {
        fontSize := i32(t.rect.height)
        textWidth := rl.MeasureText(text, fontSize)
        textX := i32(rect.x) + (i32(rect.width) - textWidth)/2
        textY := i32(rect.y) + (i32(rect.height) - fontSize)/2
        rl.DrawText(text, textX, textY, fontSize, color)
    }

    drawSprite  :: proc(using s: UI_Sprite) {
        scale := min(rect.width/f32(texture.width), rect.height/f32(texture.height))
        rl.DrawTextureEx(texture, Vector2{rect.x, rect.y}, 1.0, scale, rl.WHITE)
    }
}

showBorders :: proc() {
    for faction in factions {
        for city in faction.cities {
            for tile in city.tiles {
                showRect(getTileRect(tile), rl.Color{0,0,0,80}, .MAP)
            }
        }
    }
}

drawPops :: proc() {
    for faction in factions {
        for city in faction.cities {
            for pop in city.population {
                rect := getTileRect(pop.tile)
                transparent :: Color{255,255,255,128}
                tint := pop.state == .WORKING ? rl.WHITE : transparent
                rl.DrawTextureEx(textures.pop, Vector2{rect.x, rect.y}, 0.0, 0.5,  tint)
            }
        }
    }
}

renderState :: proc() {
    rl.BeginDrawing()
    rl.BeginMode2D(cam)
    rl.ClearBackground(rl.GetColor(0x181818ff))
    drawMap()
    drawMapStuff()
    drawPops()
    // rl.EndMode2D()
    // rl.BeginMode2D(camNoZoom)
    rl.EndMode2D()
    drawUI()
    rl.EndDrawing()
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
        sql_path := "sqlite/SQL"
        dir, err := os.open(sql_path)
        if err != {} {
            panic("")
        }
        defer os.close(dir)

        fi: FileInfo
        fi, err = os.stat("sqlite/game.db")
        if err != {} {
            panic("")
        }
        cache_mod_time := fi.modification_time
        os.file_info_delete(fi)
        
        instructions: []FileInfo
        instructions, err = os.read_dir(dir, 128)
        if err != {} {
            println("error reading directory", sql_path, os.error_string(err))
            panic("")
        }
        defer os.file_info_slice_delete(instructions)
        
        for inst in instructions {
            if time.diff(inst.modification_time, cache_mod_time) <= 0 {
                sqlite.db_config(db, .RESET_DATABASE, 1, 0)
                sqlite.exec(db, "VACUUM", nil, nil, nil)
                sqlite.db_config(db, .RESET_DATABASE, 0, 0)
                rebuildCache(db)
                break
            }
        }
    }
    generateTerrainManifest(db)
    mapDimensions = {36, 36}
    cam = {windowDimensions/2.0, Vector2{f32(mapDimensions.x*tileSize/2), f32(mapDimensions.y*tileSize/2)}, 0.0, 1.0}
    camNoZoom = cam
    println(cam.target)
    
    player := Faction {
        id = 0,
        cities = {},
        units = {},
        gold = 0.0,
    }
    append(&factions, player)
    playerFaction = &factions[0]
    
    gameMap = make([dynamic]Tile, mapDimensions.x * mapDimensions.y)
    generateMap()

    rl.SetConfigFlags(rl.ConfigFlags{.VSYNC_HINT})
    rl.InitWindow(i32(windowDimensions.x), i32(windowDimensions.y), "ATom")
    windowRect = Rect{0, 0, windowDimensions.x, windowDimensions.y}
    defer rl.CloseWindow()

    textures.city = rl.LoadTexture("Assets/Sprites/townsend.png")
    defer rl.UnloadTexture(textures.city)
    textures.pop = rl.LoadTexture("Assets/Sprites/pop.png")
    defer rl.UnloadTexture(textures.pop)
    generateUnitTypeManifest(db)
    generateBuildingManifest(db)
    syncProjectManifest()
    
    for !rl.WindowShouldClose() {
        updateState()
        renderState()
        free_all(context.temp_allocator)
    }
    for unit_type in UnitTypeManifest {
        rl.UnloadTexture(unit_type.texture)
    }
}

syncProjectManifest :: proc() {
    clear(&projectManifest)
    for unit_type in UnitTypeManifest {
        p: ProjectType = unit_type
        append(&projectManifest, p)
    }
    for building_type in BuildingTypeManifest {
        p: ProjectType = building_type
        append(&projectManifest, p)
    }
}