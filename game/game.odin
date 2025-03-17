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
import tech "../technologies"

Faction :: shared.Faction
GameState :: shared.GameState
Rect :: shared.Rect
Tile :: shared.Tile

initializeState :: proc(map_width, map_height: i32, number_of_factions: int) -> GameState {
    using shared

    factions := faction.generateFactions(number_of_factions)
    return GameState {
        world = world.initialize(map_width, map_height, TerrainManifest[0]),
        factions = factions,
        cities = make([dynamic]City, 0, 1024*2),
        units = makeHandledArray(Unit, 1024*8),
        playerFaction = &factions[0],
    }
}

start :: proc() {
    using shared

    rl.SetRandomSeed(u32(time.now()._nsec))
    // rl.SetRandomSeed(2)

    rl.SetTargetFPS(60)
    rl.SetConfigFlags(rl.ConfigFlags{ .WINDOW_RESIZABLE })
    rl.InitWindow(i32(windowDimensions.x), i32(windowDimensions.y), "ATom")
    windowRect = Rect{0, 0, windowDimensions.x, windowDimensions.y}
    defer rl.CloseWindow()

    db := database.initialize("sqlite/SQL")
    defer database.close(db)
    database.regenerateManifests(db, "sqlite/SQL")
    defer unloadAssets()

    game = initializeState(
        number_of_factions = 3,
        map_width = 64, //96, 
        map_height = 52,//64, 
    )
    world.generate(tiles_per_island = i16(rl.GetRandomValue(480, 1024)))
    for &t in game.world.tiles {
        t.discovery_mask += {int(game.playerFaction.id)}
    }

    for &f in game.factions {
        count := 0
        for len(f.cities) == 0 {
            tile := tile.getRandom()
            if tile.owner == nil && tile.terrain.movement_type == .LAND {
                city.create(&f, tile)
            }
            count += 1
            assert(count < 1024)
        }
    }

    cam = {
        offset = windowDimensions/2.0, 
        target = Vector2{f32(game.world.dimensions.x)*tileSize/2, f32(game.world.dimensions.y)*tileSize/2}, 
        rotation = 0.0, 
        zoom = 1.0,
    }
    camNoZoom = cam
    centerCamera(game.playerFaction.cities[0].location^)

    log.debug(TechnologyManifest)

    initAudio()

    textures.city = rl.LoadTexture("Assets/Sprites/townsend.png")
    defer rl.UnloadTexture(textures.city)
    textures.pop = rl.LoadTexture("Assets/Sprites/pop.png")
    defer rl.UnloadTexture(textures.pop)
    textures.technology = rl.LoadTexture("Assets/Sprites/technology.jpg")
    defer rl.UnloadTexture(textures.technology)
    textures.tile_set = rl.LoadTexture("Assets/tileset-2.png")
    defer rl.UnloadTexture(textures.tile_set)

    shader := rl.LoadShader(nil, "Shaders/default.frag")
    
    for !rl.WindowShouldClose() {

        rl.BeginDrawing()
        rl.BeginShaderMode(shader)

        rl.ClearBackground(rl.RAYWHITE)

        lastMousePostion := mousePosition
        mousePosition = rl.GetMousePosition()
        mouseMovement = rl.GetScreenToWorld2D(mousePosition, cam) - rl.GetScreenToWorld2D(lastMousePostion, cam)
        
        ui.findFocus(mousePosition, cam)
        if rl.IsKeyPressed(.T) {
            currentUIState = .TECH
        }
        if rl.IsKeyPressed(.M) {
            currentUIState = .MAP
        }
        if rl.IsKeyPressed(.R) {
            database.regenerateManifests(db, "sqlite/SQL")
        }
        updateWindowSize()
        handleScreenSpaceInput()
        handleWorldSpaceInput()
        rl.EndShaderMode()
        rl.EndDrawing()

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

    // defaultTileSize := window_height/8
    // tileSize = defaultTileSize
    // map_space := game.world.dimensions.x*tileSize
    // //too thorny
    // speculative_x := cam.target.x*(tileSize/old_tile_size)
    // cam_offset := abs(speculative_x - map_space/2)
    // pixels_to_cover := map_space - cam_offset*2 
    // pixels_covered := windowDimensions.x / cam.zoom
    // tiles_to_cover := pixels_to_cover / tileSize
    // if pixels_covered > pixels_to_cover {
    //     tileSize = pixels_covered / tiles_to_cover
    // }
    cam.offset = windowDimensions/2
    cam.target = cam.target*(tileSize/old_tile_size)
}

handleScreenSpaceInput :: proc() {
    using shared

    switch currentUIState {
        case .MAP: 
            rl.BeginMode2D(cam)
            render.gameMap()
            rl.EndMode2D()
            handleInput_MAP()
        case .TECH: 
            handleInput_TECH()
            //TODO: this should be worldspace when we get tech scrolling 8)
            drawTechScreen(windowRect)
    }
}

handleWorldSpaceInput :: proc() {
    using shared
    
    rl.BeginMode2D(cam)
    switch currentUIState {
        case .MAP: 
            ui.showBorders()
            ui.showBanners()
            ui.showUnitIcons()
            render.pops()
        case .TECH: {}
    }
    rl.EndMode2D()
}

handleInput_MAP :: proc() {
    using shared

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
        ui.showUnitBoxIfNecessary(windowRect)
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
        else if .CONTAINS_CITY in tileUnderMouse.flags {
            selectedCity = tileUnderMouse.owner
            click_consumed = true
        }
        if !click_consumed {
            selectedCity = nil
            selectedUnit = invalidHandle(Unit)
        }
    }
    else if rl.IsMouseButtonPressed(.RIGHT) && tileUnderMouse != nil {
        if selected, ok := handleRetrieve(&game.units, selectedUnit).?; ok {
            if selected.tile != tileUnderMouse {
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
    if rl.IsKeyPressed(.A) {
        nextTurn(automate_player_turn = true)
    }
    ui.showPlayerStats()
    ui.showCurrentTurn()
    p2 = false
}

handleInput_TECH :: proc() {
    using shared

    if rl.IsKeyPressed(.M) {
        currentUIState = .MAP
    }
}

nextTurn :: proc(automate_player_turn := false) {
    using shared

    if !automate_player_turn {
        if game.playerFaction.research_project.id == -1 {
            for tech in TechnologyManifest {
                if tech.id not_in game.playerFaction.techs {
                    currentUIState = .TECH
                    return
                }
            }
        }
        for &city in game.playerFaction.cities {
            if city.project == nil {
                selectedCity = city
                centerCamera(city.location^)
                return
            }
        }
        faction.update(game.playerFaction)
    }

    for &f in game.factions {
        if f.id != game.playerFaction.id || automate_player_turn {
            faction.doAiTurn(&f)
            faction.update(&f)
        }
    }
    
    log.info("turn", turn, "ended")
    turn += 1
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
        if false // cameraLookingOutside() 
        {
            cam.target = old_target
        }
        camNoZoom.target = cam.target
    }
    old_zoom := cam.zoom
    cam.zoom += rl.GetMouseWheelMoveV().y / 12.0
    if false // cameraLookingOutside() 
    {
        cam.zoom = old_zoom
    }
}

cameraLookingOutside :: proc() -> bool {
    using shared

    world_dimension := Vector2{f32(game.world.dimensions.x)*tileSize, f32(game.world.dimensions.y)*tileSize}
    x_edge := min(cam.target.x, world_dimension.x - cam.target.x)
    y_edge := min(cam.target.y, world_dimension.y - cam.target.y)

    return x_edge < 0 || y_edge < 0
}

drawTechScreen :: proc(r: Rect) {
    using shared

    length := f32(textures.technology.height)*r.width/r.height
    source_rect := Rect{0, 0, length, f32(textures.technology.height)}
    rl.DrawTexturePro(textures.technology, source_rect, windowRect, Vector2{0, 0}, 0, rl.GRAY)
    tech.drawTree(windowRect)
}

centerCamera :: proc(t: Tile) {
    using shared

    r := tile.getRect(t)
    cam.target = {r.x + r.width/2, r.y + r.height/2}
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