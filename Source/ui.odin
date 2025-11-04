package ATom

import "core:fmt"
import "core:strings"
import "core:math"
import "core:math/linalg"
import "core:container/priority_queue"
// import "core:log"

import rl "vendor:raylib"

// import tech "../technologies"

uiElement :: struct {
    variant: union{cityBanner, cityProductionMenu, cityBuiltBuildingsMenu, unitIcon},
    z_index: int,
    is_vacant: bool,
}

renderUiElements_WORLD :: proc() {
    for &element in uiElements_WORLD.queue {
        #partial switch &v in element.variant {
        case cityBanner: cityBannerRender(v)
        case unitIcon: unitIconRender(&v)
        }
    } 
}

renderUiElements_SCREEN :: proc() {
    for &element in uiElements_SCREEN.queue {
        #partial switch &v in element.variant {
        case cityProductionMenu: cityProductionMenuRender(&v)
        case cityBuiltBuildingsMenu: cityBuiltBuildingsMenuRender(&v)
        }
    } 
}

catchInputsWithUiElements :: proc() {
    #reverse for &element in uiElements_SCREEN.queue {
        #partial switch v in element.variant {
        case cityProductionMenu: cityProductionMenuHandleInput(v)
        }
    } 
    #reverse for &element in uiElements_WORLD.queue {
        #partial switch v in element.variant {
        case cityBanner: cityBannerHandleInput(v)
        case unitIcon: unitIconHandleInput(v)
        }
    } 
}

cityBanner :: struct {
    source: ^City,
}

CityBannerCreate :: proc(source: ^City) {
    priority_queue.push(
        &uiElements_WORLD, 
        uiElement {
            is_vacant = false, 
            z_index = 0,
            variant = cityBanner{source},
        },
    )
}

cityBannerGetRect :: proc(using cb: cityBanner) -> Rect {
    scale := 1.0 / cam.zoom
    lift := 20.0 * scale
    
    coords := source.location.coordinate
    x := f32(coords.x)*tileSize + tileSize/2
    y := f32(coords.y)*tileSize - lift
    
    width := 128. * scale
    height := 32. * scale

    return {
        x = x - width/2,
        y = y,
        width = width,
        height = height,
    }
}

cityBannerRender :: proc(cb: cityBanner) {
    using city := cb.source
    
    rect := cityBannerGetRect(cb)
    rl.DrawRectangleRec(rect, rl.GetColor(0xaa2299bb))
    pop_rect := chopRectangle(&rect, rect.width/4, .LEFT)
    showText(rect, rl.GetColor(0x5299ccbb), name, ALIGN_LEFT)
    builder := strings.builder_make()
    strings.write_int(&builder, len(population))
    pop_text, _ := strings.to_cstring(&builder)
    showText(pop_rect, rl.GOLD, pop_text, ALIGN_CENTER)
}

cityBannerHandleInput :: proc(cb: cityBanner) {
    rect := cityBannerGetRect(cb)
    if isMouseInRect(rect, .MAP) && rl.IsMouseButtonPressed(.LEFT) {
        selectedCity = cb.source
    }
}

cityProductionMenu :: struct {
    body: Rect,
    title: Rect,
    hovered_item: Maybe(ProjectType),
    buildables: [dynamic]ProjectType,
    entry_size: f32,
    is_active: bool,
}

cityProductionMenuUpdate :: proc(pm: ^cityProductionMenu) {
    pm.hovered_item = nil
    pm.is_active = selectedCity != nil && selectedCity.owner == game.playerFaction

    if pm.is_active {
        pm.body = subRectangle(windowRect, 0.2, 0.8, ALIGN_LEFT, ALIGN_CENTER)
        pm.title = chopRectangle(&pm.body, pm.body.height/5.0, .TOP)
        pm.entry_size = pm.body.height/5

        r := pm.body
        clear(&pm.buildables)
        for tech_id in game.playerFaction.techs {
            tech := &TechnologyManifest[tech_id]
            
            item: for project in tech.projects {
                switch type in project {
                case ^BuildingType: for b in selectedCity.buildings {
                    if b.type == type { continue item }
                }
                case ^UnitType: {}
                }
                if isMouseInRect(chopRectangle(&r, pm.entry_size, .TOP), .UI) {
                    pm.hovered_item = project
                }
                append(&pm.buildables, project)
            }
        }
    }
}

cityProductionMenuRender :: proc(using pm: ^cityProductionMenu) {
    cityProductionMenuUpdate(pm)
    if is_active {
        showRect(body, rl.PURPLE)
        showRect(title, rl.GetColor(0x992465ff))
        
        text := selectedCity.name
        text_box := Rect{title.x + title.width/10, title.y + title.height/10, title.width*0.8, title.height*0.8}
        showText(text_box, rl.GetColor(0x229f54ff), text, ALIGN_CENTER)

        r := body
        for project in pm.buildables {
            name := getProjectName(project)
            texture := getProjectTexture(project)

            entry_rect := chopRectangle(&r, entry_size, .TOP)
            showRect(entry_rect, rl.PURPLE) // the actual button

            sprite_rect := chopRectangle(&entry_rect, entry_rect.width/4, .LEFT)
            showSprite(sprite_rect, texture)
            
            color := rl.GetColor(0x18181899)
            if item, ok := pm.hovered_item.?; ok && item == project {
                color = rl.VIOLET
            }
            entry_rect = subRectangle(entry_rect, 1.0, 0.35, ALIGN_LEFT, ALIGN_TOP)
            showRect(entry_rect, color)

            entry_rect = subRectangle(entry_rect, 0.97, 0.77, ALIGN_RIGHT, ALIGN_TOP)
            showText(entry_rect, rl.GetColor(0xaaaaffff), name, ALIGN_LEFT, rl.GOLD)
        }
    }
}

cityProductionMenuHandleInput :: proc(pm: cityProductionMenu) {
    if item, ok := pm.hovered_item.?; ok {
        if rl.IsMouseButtonPressed(.LEFT) { 
            selectedCity.project = item
            selectedCity = nil
        }
    }
}

cityBuiltBuildingsMenu :: struct {}

cityBuiltBuildingsMenuRender :: proc(bb: ^cityBuiltBuildingsMenu) {
    if selectedCity != nil {
        r := subRectangle(windowRect, 0.2, 0.75, ALIGN_RIGHT, ALIGN_CENTER)
        entry_size := r.height/5
        for building in selectedCity.buildings {
            name := building.type.name
            texture := building.type.texture
            entry_rect := chopRectangle(&r, entry_size, .TOP)
            showRect(entry_rect, rl.PURPLE)
            sprite_rect := chopRectangle(&entry_rect, r.width/3, .LEFT)
            showSprite(sprite_rect, texture)
            entry_rect = subRectangle(entry_rect, 1.0, 0.35, ALIGN_LEFT, ALIGN_TOP)
            showRect(entry_rect, rl.GetColor(0x18181899))
            entry_rect = subRectangle(entry_rect, 0.97, 0.77, ALIGN_RIGHT, ALIGN_TOP)
            showText(entry_rect, rl.GetColor(0xaaaaffff), name, ALIGN_LEFT, rl.GOLD)
        }
    }
}

unitIcon :: struct {
    handle: Handle(Unit),
    source: Maybe(^Unit),
    box: Rect,
}

unitIconCreate :: proc(uh: Handle(Unit)) {
    ic := unitIcon {
        handle = uh,
    }
    priority_queue.push(
        &uiElements_WORLD,
        uiElement {
            is_vacant = false,
            z_index = 2,
            variant = ic,
        },
    )
}

unitIconUpdate :: proc(ic: ^unitIcon) {
    ic.source = handleRetrieve(&game.units, ic.handle)
    u, ok := ic.source.?
    if !ok { return }

    scale := 1.0 / cam.zoom
    lift := 16.0*scale
    x := f32(u.tile.coordinate.x)*tileSize + tileSize/2
    y := f32(u.tile.coordinate.y)*tileSize - lift 
    width := 96.0*scale
    height := 24.0*scale
    rect := Rect{x - width/2, y, width, height}

    // wherein we take a stupid approach to showing multiple stacked unit icons
    for uh in u.tile.units {
        unit := handleRetrieve(&game.units, uh).? or_continue
        if unit == u {
            break
        }
        rect.y -= rect.height * 1.1
    }
    ic.box = rect
}

unitIconRender :: proc(ic: ^unitIcon) {
    unitIconUpdate(ic)

    u, ok := ic.source.?
    if !ok { return }

    faction := u.owner.type
    showRect(ic.box, faction.primary_color)
    showText(ic.box, faction.secondary_color, faction.name, ALIGN_CENTER)
}

unitIconHandleInput :: proc(ic: unitIcon) {
    _, ok := ic.source.?
    if !ok { return }

    if isMouseInRect(ic.box, .MAP) && rl.IsMouseButtonPressed(.LEFT) {
        selectedUnit = ic.handle
    }
}

uiState :: enum {
    MAP,
    TECH,
}
currentUIState := uiState.MAP

DrawMode :: enum {
    MAP,
    UI,
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

Buttons: [dynamic]UI_Button = {}

UI_Button :: struct {
    rect: Rect,
    was_pressed: ^bool,
    mode: DrawMode,
}

showRect :: proc(rect: Rect, color: Color) {
    rl.DrawRectangleRec(rect, color)
}

showLine :: proc(start, end: Vector2, thickness: f32, color: Color) {
    rl.DrawLineEx(start, end, thickness, color)
}

showSprite :: proc(rect: Rect, sprite: rl.Texture, background: Color = rl.BLANK) {
    if background != rl.BLANK {
        showRect(rect, background)
    }

    scale := min(rect.width/f32(sprite.width), rect.height/f32(sprite.height))
    rl.DrawTextureEx(sprite, Vector2{rect.x, rect.y}, 1.0, scale, rl.WHITE)
}

showText :: proc(rect: Rect, color: Color, text: cstring, align: Alignment, background: Color = rl.BLANK) {
    rect := rect
    if background != rl.BLANK {
        showRect(rect, background)
    }
    rect = subRectangle(rect, 1.0, 0.8, ALIGN_CENTER, ALIGN_CENTER)

    if rect.width == 0 || rect.height == 0 { return }
    font_size := i32(rect.height)
    text_width := rl.MeasureText(text, font_size)
    if text_width == 0  { return }
    scale_factor := rect.width / f32(text_width)
    if scale_factor < 1. {
        font_size = i32(f32(font_size) * scale_factor)
        text_width = rl.MeasureText(text, font_size)
    }
    x := i32(rect.x)
    side_margin := i32(rect.width) - text_width
    switch align {
        case ALIGN_LEFT: {}
        case ALIGN_CENTER: x += side_margin/2
        case ALIGN_RIGHT: x += side_margin
    }
    y := i32(rect.y) + (i32(rect.height) - font_size)/2
    rl.DrawText(text, x, y, font_size, color)
}

showButton :: proc(rect: Rect, color: Color, was_pressed: ^bool, mode: DrawMode, text: cstring = "") -> bool {
    v := was_pressed^
    was_pressed^ = false
    showRect(rect, color)
    text_box := Rect{rect.x + rect.width/10, rect.y + rect.height/10, rect.width*0.8, rect.height*0.8}
    showText(text_box, rl.GetColor(0xaaaaffff), text, ALIGN_LEFT)
    append(&Buttons, UI_Button{rect, was_pressed, mode})
    return v
}

isMouseInRect :: proc(rect: Rect, mode: DrawMode) -> bool {
    world_mouse := rl.GetScreenToWorld2D(mousePosition, cam)    
    switch mode {
    case .MAP: return rl.CheckCollisionPointRec(world_mouse, rect)
    case .UI: return rl.CheckCollisionPointRec(mousePosition, rect)
    }
    unreachable()
}

showBorders :: proc() {
    for faction in game.factions {
        for city in faction.cities {
            if city.destroyed { return }
            assert(city.tiles != nil)
            for tl in city.tiles {
                if int(game.playerFaction.id) not_in tl.discovery_mask do continue
                assert(tl != nil)
                color := faction.type.primary_color
                color.a = 128
                rect := getTileRect(tl^)
                showRect(rect, color)
                center := Vector2{rect.x + rect.width/2, rect.y + rect.height/2}
                color = faction.type.secondary_color
                color.a = 192
                for direction in OrthogonalDirections {
                    neighbor := getTile(tl.coordinate + direction)
                    if neighbor != nil && (neighbor.owner == nil || neighbor.owner.owner == nil || neighbor.owner.owner.id != faction.id) {
                        nrect := getTileRect(neighbor^)
                        target := Vector2{nrect.x + nrect.width/2, nrect.y + nrect.height/2}
                        edge := (target - center) / 2
                        offset := edge * linalg.matrix2_rotate_f32(math.PI/2)
                        start := center + edge - offset
                        end := center + edge + offset
                        showLine(start, end, 6, color)
                    }
                }
            }
        }
    }
}

showUnitBoxIfNecessary :: proc(r: Rect) {
    r := r

    if selected, ok := handleRetrieve(&game.units, selectedUnit).?; ok {
        lower := chopRectangle(&r, r.height/4, .BOTTOM)
        lower_left := chopRectangle(&lower, r.width/4, .LEFT)
        showSprite(lower_left, selected.type.texture)
    } 
}

showPlayerStats :: proc() {
    using game

    r := subRectangle(windowRect, 0, 0, windowDimensions.x, windowDimensions.y / 8)
    rl.DrawRectangleRec(r, rl.DARKPURPLE)
    r2 := subRectangle(r, 0.03, 0.25, windowDimensions.x * 0.97, windowDimensions.y / 16)
    sb := strings.builder_make(context.temp_allocator)

    fmt.sbprintf(&sb, "Science: %v", playerFaction.science)
    cs , _ := strings.to_cstring(&sb)
    showText(chopRectangle(&r2, windowDimensions.x/8, .LEFT), rl.SKYBLUE, cs, .HALFWAY)
    strings.builder_reset(&sb)

    fmt.sbprintf(&sb, "Gold: %v", playerFaction.gold)
    cs, _ = strings.to_cstring(&sb)
    showText(chopRectangle(&r2, windowDimensions.x/8, .LEFT), rl.GOLD, cs, .HALFWAY)
    strings.builder_reset(&sb)
}

showCurrentTurn :: proc() {
    using game

    r := subRectangle(windowRect, 0, 0, windowDimensions.x, windowDimensions.y / 8)
    r2 := subRectangle(r, 0.03, 0.25, windowDimensions.x * 0.97, windowDimensions.y / 16)
    sb := strings.builder_make(context.temp_allocator)

    fmt.sbprintf(&sb, "Turn: %v", turn)
    cs, _ := strings.to_cstring(&sb)
    showText(chopRectangle(&r2, windowDimensions.x/8, .RIGHT), rl.PINK, cs, .HALFWAY)
    strings.builder_reset(&sb)
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

findFocus :: proc(screen_mouse: Vector2, cam: rl.Camera2D) {
    lucky_contestant: ^bool = nil
    world_mouse := rl.GetScreenToWorld2D(screen_mouse, cam)
    for button in Buttons {
        switch button.mode {
            case .MAP: {
                if rl.CheckCollisionPointRec(world_mouse, button.rect) {
                    lucky_contestant = button.was_pressed
                }
            }
            case .UI: {
                if rl.CheckCollisionPointRec(screen_mouse, button.rect) {
                    lucky_contestant = button.was_pressed
                }
            }
        }
    }
    if lucky_contestant != nil {
        lucky_contestant^ = true
    }
    clear(&Buttons)
}