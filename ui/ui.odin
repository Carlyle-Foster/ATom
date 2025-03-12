package ui

import "core:fmt"
import "core:strings"
import "core:math"
import "core:math/linalg"

import rl "vendor:raylib"

import shared "../shared"
import tile "../tiles"
import city "../cities"
// import tech "../technologies"

Color :: rl.Color
Vector2 :: rl.Vector2
Rect :: rl.Rectangle

City :: shared.City

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

    font_size := i32(rect.height)
    text_width := rl.MeasureText(text, font_size)
    for text_width > i32(rect.width) && font_size >= 0 {
        font_size -= 1
        text_width = rl.MeasureText(text, font_size)
    }
    x: i32
    switch align {
        case ALIGN_LEFT: x = i32(rect.x)
        case ALIGN_CENTER: x = i32(rect.x) + (i32(rect.width) - text_width)/2
        case ALIGN_RIGHT: x = i32(rect.x) + (i32(rect.width) - text_width)
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

showBanners :: proc() {
    using shared

    for &c, index in game.cities {
        if city.isVisibleToPlayer(&c) {
            showBanner(&c, index)
        }
    }
    @(static) ps :[128]bool = {}
    showBanner :: proc(using city : ^City, index: int) {
        scale := 1.0 / cam.zoom
        lift := 20.0*scale
        x := f32(location.coordinate.x)*tileSize + tileSize/2
        y := f32(location.coordinate.y)*tileSize - lift 
        width := 128.0*scale
        height := 32.0*scale
        rect := Rect{x - width/2, y, width, height}
        if showButton(rect, rl.GetColor(0xaa2299bb), &ps[index], .MAP) {
            if rl.IsMouseButtonPressed(.LEFT) {
                selectedCity = city
            }
        }
        pop_rect := chopRectangle(&rect, rect.width/4, .LEFT)
        showText(rect, rl.GetColor(0x5299ccbb), name, ALIGN_LEFT)
        builder := strings.builder_make()
        strings.write_int(&builder, len(population))
        pop_text := strings.to_cstring(&builder)
        showText(pop_rect, rl.GOLD, pop_text, ALIGN_CENTER)
    }
}

showCityUI :: proc() {
    using shared
    showSidebar2(subRectangle(windowRect, 0.2, 0.8, ALIGN_RIGHT, ALIGN_CENTER))
    if selectedCity.owner == game.playerFaction {
        showSidebar(subRectangle(windowRect, 0.2, 0.8, ALIGN_LEFT, ALIGN_CENTER))
    }
}

showSidebar :: proc(r: Rect) {
    using shared

    r := r
    padding :: 1.45
    assert(selectedCity != nil)
    
    showRect(r, rl.PURPLE)
    text: cstring = selectedCity != {} ? selectedCity.name : "NULL"
    title_rect := chopRectangle(&r, r.height/5.0, .TOP)
    entry_size := r.height/5
    showRect(title_rect, rl.GetColor(0x992465ff))
    text_box := Rect{title_rect.x + title_rect.width/10, title_rect.y + title_rect.height/10, title_rect.width*0.8, title_rect.height*0.8}
    showText(text_box, rl.GetColor(0x229f54ff), text, ALIGN_CENTER)
    @(static) ps: [256]bool = {}
    index := 0
    for tech_id in game.playerFaction.techs {
        tech := &TechnologyManifest[tech_id]
        item: for project in tech.projects {
            name: cstring 
            texture: rl.Texture  
            switch type in project {
                case ^UnitType: {
                    name = type.name
                    texture = type.texture
                }
                case ^BuildingType: {
                    for b in selectedCity.buildings {
                        if b.type == type do continue item
                    }
                    name = type.name
                    texture = type.texture
                }
            }
            entry_rect := chopRectangle(&r, entry_size, .TOP)
            if showButton(entry_rect, rl.PURPLE, &ps[index], .UI) {
                if rl.IsMouseButtonPressed(.LEFT) {
                    selectedCity.project = project
                    selectedCity = nil
                }
            }
            sprite_rect := chopRectangle(&entry_rect, entry_rect.width/4, .LEFT)
            showSprite(sprite_rect, texture)
            entry_rect = subRectangle(entry_rect, 1.0, 0.35, ALIGN_LEFT, ALIGN_TOP)
            showRect(entry_rect, rl.GetColor(0x18181899))
            entry_rect = subRectangle(entry_rect, 0.97, 0.77, ALIGN_RIGHT, ALIGN_TOP)
            showText(entry_rect, rl.GetColor(0xaaaaffff), name, ALIGN_LEFT, rl.GOLD)
            index += 1
            assert(index <= len(ps))
        }
    }
}

showSidebar2 :: proc(r: Rect) {
    using shared

    r := r
    padding :: 1.45
    assert(selectedCity != nil)

    // entry_size := r.height/5
    for building in selectedCity.buildings {
        name := building.type.name
        texture := building.type.texture
        entry_rect := chopRectangle(&r, r.height/8, .TOP)
        showRect(entry_rect, rl.PURPLE)
        sprite_rect := chopRectangle(&entry_rect, r.width/3, .LEFT)
        showSprite(sprite_rect, texture)
        entry_rect = subRectangle(entry_rect, 1.0, 0.35, ALIGN_LEFT, ALIGN_TOP)
        showRect(entry_rect, rl.GetColor(0x18181899))
        entry_rect = subRectangle(entry_rect, 0.97, 0.77, ALIGN_RIGHT, ALIGN_TOP)
        showText(entry_rect, rl.GetColor(0xaaaaffff), name, ALIGN_LEFT, rl.GOLD)
    }
}

showBorders :: proc() {
    using shared

    for faction in game.factions {
        for city in faction.cities {
            assert(city.tiles != nil)
            for tl in city.tiles {
                if int(game.playerFaction.id) not_in tl.discovery_mask do continue
                assert(tl != nil)
                color := faction.type.primary_color
                color.a = 128
                rect := tile.getRect(tl^)
                showRect(rect, color)
                center := Vector2{rect.x + rect.width/2, rect.y + rect.height/2}
                color = faction.type.secondary_color
                color.a = 192
                for direction in OrthogonalDirections {
                    neighbor := tile.get(tl.coordinate + direction)
                    if neighbor != nil && (neighbor.owner == nil || neighbor.owner.owner == nil || neighbor.owner.owner.id != faction.id) {
                        nrect := tile.getRect(neighbor^)
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

showUnitBox :: proc(r: Rect) {
    using shared
    r := r

    lower := chopRectangle(&r, r.height/4, .BOTTOM)
    lower_left := chopRectangle(&lower, r.width/4, .LEFT)
    showSprite(lower_left, selectedUnit.type.texture)
}

showPlayerStats :: proc() {
    using shared, game

    r := subRectangle(windowRect, 0, 0, windowDimensions.x, windowDimensions.y / 8)
    r2 := subRectangle(r, 0.03, 0.25, windowDimensions.x * 0.97, windowDimensions.y / 16)
    sb := strings.builder_make(context.temp_allocator)

    fmt.sbprintf(&sb, "Science: %v", playerFaction.science)
    showText(chopRectangle(&r2, windowDimensions.x/8, .LEFT), rl.SKYBLUE, strings.to_cstring(&sb), .HALFWAY)
    strings.builder_reset(&sb)

    fmt.sbprintf(&sb, "Gold: %v", playerFaction.gold)
    showText(chopRectangle(&r2, windowDimensions.x/8, .LEFT), rl.GOLD, strings.to_cstring(&sb), .HALFWAY)
    strings.builder_reset(&sb)
}

showCurrentTurn :: proc() {
    using shared, game

    r := subRectangle(windowRect, 0, 0, windowDimensions.x, windowDimensions.y / 8)
    r2 := subRectangle(r, 0.03, 0.25, windowDimensions.x * 0.97, windowDimensions.y / 16)
    sb := strings.builder_make(context.temp_allocator)

    fmt.sbprintf(&sb, "Turn: %v", turn)
    showText(chopRectangle(&r2, windowDimensions.x/8, .RIGHT), rl.PURPLE, strings.to_cstring(&sb), .HALFWAY)
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