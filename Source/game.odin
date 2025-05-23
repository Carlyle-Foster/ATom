package ATom

import "core:log"
import "core:time"
import "core:strings"
import "core:container/priority_queue"

import rl "vendor:raylib"

GameState :: struct {
    world: World,
    factions: [dynamic]Faction,
    cities: [dynamic]City,
    units: HandledArray(Unit),
    playerFaction: ^Faction,
}

initializeGameState :: proc(map_width, map_height: i32, number_of_factions: int) -> GameState {
    factions := generateFactions(number_of_factions)
    return GameState {
        world = initializeWorld(map_width, map_height, TerrainManifest[0]),
        factions = factions,
        cities = make([dynamic]City, 0, 1024*2),
        units = makeHandledArray(Unit, 1024*8),
        playerFaction = &factions[0],
    }
}

startGame :: proc() {
    rl.SetRandomSeed(u32(time.now()._nsec))

    // rl.SetRandomSeed(2)

    rl.SetTargetFPS(60)
    rl.SetConfigFlags(rl.ConfigFlags{ .WINDOW_RESIZABLE })
    rl.InitWindow(i32(windowDimensions.x), i32(windowDimensions.y), "ATom")
    windowRect = Rect{0, 0, windowDimensions.x, windowDimensions.y}
    defer rl.CloseWindow()

    db := initializeDatabase("sqlite/SQL")
    defer closeDatabase(db)
    regenerateManifests(db, "sqlite/SQL")
    defer unloadAssets()

    game = initializeGameState(
        number_of_factions = 3,
        map_width = 64, //96, 
        map_height = 52,//64, 
    )
    generateWorld(tiles_per_island = i16(rl.GetRandomValue(480, 1024)))
    // for &t in game.world.tiles {
    //     t.discovery_mask += {int(game.playerFaction.id)}
    // }

    for &f in game.factions {
        count := 0
        for len(f.cities) == 0 {
            tile := getRandomTile()
            if tile.owner == nil && tile.terrain.movement_type == .LAND {
                createCity(&f, tile)
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

    textures.city = loadTexture("Sprites/townsend.png")
    textures.pop = loadTexture("Sprites/pop.png")
    textures.technology = loadTexture("Sprites/technology.jpg")
    textures.tile_set = loadTexture("tileset-2.png")

    shader := rl.LoadShader(nil, "Shaders/default.frag")

    priority_queue.push(
        &uiElements_SCREEN, 
        uiElement {
            is_vacant = false, 
            z_index = 1,
            variant = cityProductionMenu{},
        },
    )
    
    for !rl.WindowShouldClose() {

        rl.BeginDrawing()
        rl.BeginShaderMode(shader)

        rl.ClearBackground(rl.RAYWHITE)

        lastMousePostion := mousePosition
        mousePosition = rl.GetMousePosition()
        mouseMovement = rl.GetScreenToWorld2D(mousePosition, cam) - rl.GetScreenToWorld2D(lastMousePostion, cam)
        
        findFocus(mousePosition, cam)
        if rl.IsKeyPressed(.R) {
            regenerateManifests(db, "sqlite/SQL")
        }
        updateWindowSize()
        switch currentUIState {
            case .MAP: 
                rl.BeginMode2D(cam)
                renderGameMap()
                showBorders()
                renderPops()
                showUnitIcons()
                renderUiElements_WORLD()
                rl.EndMode2D()
                renderUiElements_SCREEN()
                catchInputsWithUiElements()
                handleInput_MAP()
            case .TECH: 
                handleInput_TECH()
                //TODO: this should be worldspace when we get tech scrolling 8)
                drawTechScreen(windowRect)
        }
        rl.EndShaderMode()
        rl.EndDrawing()

        free_all(context.temp_allocator)
    }
}

updateWindowSize :: proc() {
    old_tile_size := tileSize
    window_width := f32(rl.GetScreenWidth())
    window_height := f32(rl.GetScreenHeight())
    windowRect.width = window_width
    windowRect.height = window_height
    windowDimensions = Vector2{window_width, window_height}

    cam.offset = windowDimensions/2
    cam.target = cam.target*(tileSize/old_tile_size)
}

handleInput_MAP :: proc() {
    updateCamera()
    
    @(static) p2 := false
    {
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
        showUnitBoxIfNecessary(windowRect)
    }
    worldMouse := rl.GetScreenToWorld2D(mousePosition, cam) / tileSize
    tileUnderMouse := getTile(i32(worldMouse.x), i32(worldMouse.y))
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
                employCitizen(candidate, tileUnderMouse)
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
                sendUnitToTile(selectedUnit, tileUnderMouse)
            }
        }
    }
    if rl.IsKeyPressed(.T) {
        currentUIState = .TECH
    }
    if rl.IsKeyPressed(.A) {
        nextTurn(automate_player_turn = true)
    }
    if rl.IsKeyDown(.A) && rl.IsKeyDown(.LEFT_SHIFT) {
        nextTurn(automate_player_turn = true)
    }
    showPlayerStats()
    showCurrentTurn()
    p2 = false
}

handleInput_TECH :: proc() {
    if rl.IsKeyPressed(.T) {
        currentUIState = .MAP
    }
}

nextTurn :: proc(automate_player_turn := false) {
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
        updateFaction(game.playerFaction)
    }

    for &f in game.factions {
        if f.id != game.playerFaction.id || automate_player_turn {
            doAiTurn(&f)
            updateFaction(&f)
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
    if rl.IsMouseButtonDown(.LEFT) {
        if rl.IsMouseButtonPressed(.LEFT) {
            mouseMovement = Vector2{0,0}
        }
        cam.target -= mouseMovement
        camNoZoom.target = cam.target
    }
    cam.zoom += rl.GetMouseWheelMoveV().y / 12.0
}

cameraLookingOutside :: proc() -> bool {
    world_dimension := Vector2{f32(game.world.dimensions.x)*tileSize, f32(game.world.dimensions.y)*tileSize}
    x_edge := min(cam.target.x, world_dimension.x - cam.target.x)
    y_edge := min(cam.target.y, world_dimension.y - cam.target.y)

    return x_edge < 0 || y_edge < 0
}

drawTechScreen :: proc(r: Rect) {
    length := f32(textures.technology.height)*r.width/r.height
    source_rect := Rect{0, 0, length, f32(textures.technology.height)}
    rl.DrawTexturePro(textures.technology, source_rect, windowRect, Vector2{0, 0}, 0, rl.GRAY)
    drawTechTree(windowRect)
}

centerCamera :: proc(t: Tile) {
    r := getTileRect(t)
    cam.target = {r.x + r.width/2, r.y + r.height/2}
}

unloadAssets :: proc() {    
    for unit_type in UnitTypeManifest {
        rl.UnloadTexture(unit_type.texture)
    }
    for building_type in BuildingTypeManifest {
        rl.UnloadTexture(building_type.texture)
    }
}

@(deferred_out=rl.UnloadTexture)
loadTexture :: proc(path: string) -> Texture {
    sb := strings.builder_make()
    strings.write_string(&sb,"Assets/")
    strings.write_string(&sb,path)

    //TODO: this probably leaks a little memory

    return rl.LoadTexture(strings.to_cstring(&sb))
}