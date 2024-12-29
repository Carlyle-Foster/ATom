package game

import "core:log"
import "core:time"

import rl "vendor:raylib"

import shared "../shared"
import world "../world"
import ui "../ui"
import city "../cities"
import unit "../units"
import tile "../tiles"
import pop "../pops"
import faction "../factions"
import render "../rendering" 
import database "../database"

Faction :: shared.Faction
GameState :: shared.GameState

initializeState :: proc(map_width, map_height: i32, number_of_factions: int) -> GameState {
    using shared

    factions := faction.generateFactions(number_of_factions)
    return GameState {
        world = world.initialize(map_width, map_height, TerrainManifest[0]),
        factions = factions,
        cities = make([dynamic]City, 0, 1024*2),
        units = make([dynamic]Unit, 0, 1024*8),
        playerFaction = &factions[0],
    }
}

start :: proc() {
    using shared

    context.logger = log.create_console_logger()

    rl.SetRandomSeed(u32(time.now()._nsec))
    // rl.SetRandomSeed(2)

    db := database.initialize("sqlite/SQL")

    rl.SetTargetFPS(60)
    rl.SetConfigFlags(rl.ConfigFlags{ .WINDOW_RESIZABLE })
    rl.InitWindow(i32(windowDimensions.x), i32(windowDimensions.y), "ATom")
    windowRect = Rect{0, 0, windowDimensions.x, windowDimensions.y}
    defer rl.CloseWindow()

    database.generateManifests(db)
    defer unloadAssets()

    game = initializeState(
        number_of_factions = 3,
        map_width = 96, 
        map_height = 64, 
    )
    world.generate()
    for &t in game.world.tiles {
        t.discovery_mask |= 1 << game.playerFaction.id
    }

    cam = {
        offset = windowDimensions/2.0, 
        target = Vector2{f32(game.world.dimensions.x)*tileSize/2, f32(game.world.dimensions.y)*tileSize/2}, 
        rotation = 0.0, 
        zoom = 1.0,
    }
    camNoZoom = cam

    log.debug(TechnologyManifest)

    initAudio()

    textures.city = rl.LoadTexture("Assets/Sprites/townsend.png")
    defer rl.UnloadTexture(textures.city)
    textures.pop = rl.LoadTexture("Assets/Sprites/pop.png")
    defer rl.UnloadTexture(textures.pop)
    textures.technology = rl.LoadTexture("Assets/Sprites/technology.jpg")
    defer rl.UnloadTexture(textures.technology)
    
    for !rl.WindowShouldClose() {
        if rl.IsKeyPressed(.T) {
            currentUIState = .TECH
        }
        if rl.IsKeyPressed(.M) {
            currentUIState = .MAP
        }
        handleInput()
        renderState()
        free_all(context.temp_allocator)
    }
}

updateWindowSize :: proc() {
    using shared

    old_tile_size := tileSize
    window_width := f32(rl.GetScreenWidth())
    window_height := f32(rl.GetScreenHeight())
    windowRect.width = window_width
    windowRect.height = window_height
    windowDimensions = Vector2{window_width, window_height}

    defaultTileSize := window_height/8
    tileSize = defaultTileSize
    map_space := game.world.dimensions.x*tileSize
    //too thorny
    speculative_x := cam.target.x*(tileSize/old_tile_size)
    cam_offset := abs(speculative_x - map_space/2)
    pixels_to_cover := map_space - cam_offset*2 
    pixels_covered := windowDimensions.x / cam.zoom
    tiles_to_cover := pixels_to_cover / tileSize
    if pixels_covered > pixels_to_cover {
        tileSize = pixels_covered / tiles_to_cover
    }
    cam.offset = windowDimensions/2
    cam.target = cam.target*(tileSize/old_tile_size)
}

handleInput :: proc() {
    using shared

    switch currentUIState {
        case .MAP: handleInput_MAP()
        case .TECH: handleInput_TECH()
    }
}

handleInput_MAP :: proc() {
    using shared

    updateWindowSize()

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
    worldMouse := rl.GetScreenToWorld2D(mousePosition, cam) / tileSize
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
                pop.employ(candidate, tileUnderMouse)
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
            city.create(game.playerFaction, tileUnderMouse)
        }
    }
    if rl.IsKeyPressed(.T) {
        currentUIState = .TECH
    }
    ui.showBorders()
    ui.showBanners()
    p2 = false
}

handleInput_TECH :: proc() {
    using shared

    if rl.IsKeyPressed(.M) {
        currentUIState = .MAP
    }
}

renderState :: proc() {
    using shared

    rl.BeginDrawing()
    if currentUIState == .MAP {
        rl.BeginMode2D(cam)
        rl.ClearBackground(rl.GetColor(0x181818ff))
        render.gameMap()
        ui.drawMapStuff()
        render.pops()
        // rl.EndMode2D()
        // rl.BeginMode2D(camNoZoom)
        rl.EndMode2D()
        ui.drawUI()
    }
    else {
        updateWindowSize()
        ui.drawTechScreen(windowRect)
    }
    rl.EndDrawing()
}

nextTurn :: proc() {
    using shared

    for &city in game.playerFaction.cities {
        if city.project == nil {
            selectedCity = city
            return
        }
    }
    log.info("turn")

    for &f in game.factions {
        faction.update(&f)
        if f.id != game.playerFaction.id {
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
            mouseMovement = Vector2{0,0}
        }
        old_target := cam.target
        cam.target -= mouseMovement
        if  canCameraSeeOutside() {
            cam.target = old_target
        }
        camNoZoom.target = cam.target
    }
    old_zoom := cam.zoom
    cam.zoom += rl.GetMouseWheelMoveV().y / 12.0
    if canCameraSeeOutside() {
        cam.zoom = old_zoom
    }
}

canCameraSeeOutside :: proc() -> bool {
    using shared

    world_dimension := Vector2{f32(game.world.dimensions.x)*tileSize, f32(game.world.dimensions.y)*tileSize}
    real_window := windowDimensions / cam.zoom
    x_edge := min(cam.target.x, world_dimension.x - cam.target.x)
    y_edge := min(cam.target.y, world_dimension.y - cam.target.y)
    return x_edge < real_window.x/2 || y_edge < real_window.y/2
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