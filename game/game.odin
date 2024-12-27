package game

import "core:log"
import "core:time"
import "core:math"

import rl "vendor:raylib"

import shared "../shared"
import ui "../ui"
import city "../cities"
import unit "../units"
import tile "../tiles"
import faction "../factions"
import render "../rendering" 
import database "../database"

Faction :: shared.Faction

start :: proc() {
    using shared

    context.logger = log.create_console_logger()

    rl.SetRandomSeed(u32(time.now()._nsec))
    // rl.SetRandomSeed(2)

    db := database.initialize("sqlite/SQL")

    mapDimensions = {36, 36}
    cam = {windowDimensions/2.0, Vector2{f32(mapDimensions.x*tileSize/2), f32(mapDimensions.y*tileSize/2)}, 0.0, 1.0}
    camNoZoom = cam
    
    cities = make([dynamic]City, 0, 1024*2)
    units = make([dynamic]Unit, 0, 1024*8)
    factions = make([dynamic]Faction, 0, 128)

    
    gameMap = make([dynamic]Tile, mapDimensions.x * mapDimensions.y)

    rl.SetConfigFlags(rl.ConfigFlags{.VSYNC_HINT})
    rl.InitWindow(i32(windowDimensions.x), i32(windowDimensions.y), "ATom")
    windowRect = Rect{0, 0, windowDimensions.x, windowDimensions.y}
    defer rl.CloseWindow()

    database.generateManifests(db)
    syncProjectManifest()
    defer unloadAssets()

    faction.generateFactions(3)
    playerFaction = &factions[0]

    generateMap()

    initAudio()

    textures.city = rl.LoadTexture("Assets/Sprites/townsend.png")
    defer rl.UnloadTexture(textures.city)
    textures.pop = rl.LoadTexture("Assets/Sprites/pop.png")
    defer rl.UnloadTexture(textures.pop)
    
    
    for !rl.WindowShouldClose() {
        doFrame()
    }
}

doFrame :: proc() {
    updateState()
    renderState()
    free_all(context.temp_allocator)
}

updateState :: proc() {
    using shared

    lastMousePostion := mousePosition
    mousePosition = rl.GetMousePosition()
    mouseMovement = rl.GetScreenToWorld2D(mousePosition, cam) - rl.GetScreenToWorld2D(lastMousePostion, cam)

    ui.findFocus(mousePosition, cam)

    updateCamera()
    
    @(static) p2 := false
    { using ui

        append(&Buttons, UI_Button{windowRect, &p2, .UI})

        @(static) p1 := false
        if showButton( 
            subRectangle(windowRect, 0.36, 0.09, ALIGN_RIGHT, ALIGN_BOTTOM), 
            rl.GetColor(0x161616ff), 
            &p1,
            .UI,
            "NEXT TURN",
        ) {
            if rl.IsMouseButtonPressed(.LEFT) {
                nextTurn()
            }
        }
        if selectedCity != nil {
            showCityUI()
        }
    }
    worldMouse := rl.GetScreenToWorld2D(mousePosition, cam) / f32(tileSize)
    tileUnderMouse := tile.get(i32(worldMouse.x), i32(worldMouse.y))
    if p2 && rl.IsMouseButtonPressed(.LEFT) && tileUnderMouse != nil {
        click_consumed := false
        if selectedCity != nil && tileUnderMouse.owner == selectedCity {
            candidate : ^Pop = nil
            last_index := len(selectedCity.population) - 1
            for &pop, index in selectedCity.population {
                if pop.tile == tileUnderMouse && pop.state == .WORKING {
                    pop.state = .UNEMPLOYED
                    candidate = nil
                    click_consumed = true
                    break
                }
                if candidate == nil && (pop.state == .UNEMPLOYED || index ==  last_index) {
                    candidate = &pop
                }
            }
            if candidate != nil {
                employPop(candidate, tileUnderMouse)
                click_consumed = true
            }
        }
        if len(tileUnderMouse.units) > 0 {
            selectedUnit = tileUnderMouse.units[0]
            selectedCity = nil
            click_consumed = true
            log.info("selected unit:", tileUnderMouse.units[0])
        }
        if .CONTAINS_CITY in tileUnderMouse.flags {
            selectedCity = tileUnderMouse.owner
            click_consumed = true
        }
        if !click_consumed {
            selectedCity = nil
            selectedUnit = nil
        }
    }
    else if rl.IsMouseButtonPressed(.RIGHT) && tileUnderMouse != nil {
        if selectedUnit != nil {
            if selectedUnit.tile != tileUnderMouse {
                unit.sendToTile(selectedUnit, tileUnderMouse)
            }
        }
        else {
            city.create(playerFaction, tileUnderMouse)
        }
    }
    ui.showBorders()
    ui.showBanners()
    p2 = false
}

renderState :: proc() {
    using shared

    rl.BeginDrawing()
    rl.BeginMode2D(cam)
    rl.ClearBackground(rl.GetColor(0x181818ff))
    render.gameMap()
    ui.drawMapStuff()
    render.pops()
    // rl.EndMode2D()
    // rl.BeginMode2D(camNoZoom)
    rl.EndMode2D()
    ui.drawUI()
    rl.EndDrawing()
}

nextTurn :: proc() {
    using shared

    for &city in playerFaction.cities {
        if city.project == nil {
            selectedCity = city
            return
        }
    }
    log.info("turn")

    for &f in factions {
        for c in f.cities {
            city.update(c)
        }
        for u in f.units {
            unit.update(u)
        }
        if f.id != playerFaction.id {
            faction.doAiTurn(&f)
        }
    }
}

initAudio :: proc() {
    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()
    if rl.IsAudioDeviceReady() {
        rl.SetMasterVolume(0.5)
        music := rl.LoadMusicStream("Assets/Audio/Make Haste! 180 BPM E phrygian.mp3")
        defer rl.UnloadMusicStream(music)
        if rl.IsMusicValid(music) {
            rl.SetMusicVolume(music, 0.4)
            rl.PlayMusicStream(music)
        }
    }
}

updateCamera :: proc() {
    using shared

    if rl.IsMouseButtonDown(.LEFT) {
        if rl.IsMouseButtonPressed(.LEFT) {
            mouseMovement = Vector2{}
        }
        cam.target -= mouseMovement
        camNoZoom.target = cam.target
    }
    cam.zoom += rl.GetMouseWheelMoveV().y / 10.0
}

unloadAssets :: proc() {
    using shared
    for unit_type in UnitTypeManifest {
        rl.UnloadTexture(unit_type.texture)
    }
    for building_type in BuildingTypeManifest {
        rl.UnloadTexture(building_type.texture)
    }
}

syncProjectManifest :: proc() {
    using shared

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

generateMap :: proc() {
    using shared

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
                    tile.get(c)^  = tile.create(c, TerrainManifest[0], .PEARLS)
                }
                else {
                    tile.get(c)^  = tile.create(c, TerrainManifest[1], .PLATINUM)
                }
            }
            else {
                tile.get(c)^ = tile.create(c, TerrainManifest[2], .PLATINUM)
            }
        }
    }
}