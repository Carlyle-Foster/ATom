package ui

import "core:strings"
import "core:math"
import "core:math/linalg"

import rl "vendor:raylib"

import shared "../shared"
import tile "../tiles"

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

UI_Rect :: struct {
    rect: Rect,
    color: Color,
    mode: DrawMode,
}

UI_Line :: struct {
    start: Vector2,
    end: Vector2,
    thickness: f32,
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

Buttons: [dynamic]UI_Button = {}

UI_Button :: struct {
    rect: Rect,
    was_pressed: ^bool,
    mode: DrawMode,
}

rectsToDraw := make([dynamic]UI_Rect, 0, 64)
linesToDraw := make([dynamic]UI_Line, 0, 64)
textToDraw := make([dynamic]UI_Text, 0, 64)
spritesToDraw := make([dynamic]UI_Sprite, 0, 64)

showRect :: proc(rect: Rect, color: Color, mode: DrawMode) {
    append(&rectsToDraw, UI_Rect{rect, color, mode})
}

showLine :: proc(start, end: Vector2, thickness: f32, color: Color, mode: DrawMode) {
    append(&linesToDraw, UI_Line{start, end, thickness, color, mode})
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

showButton :: proc(rect: Rect, color: Color, was_pressed: ^bool, mode: DrawMode, text: cstring = "") -> bool {
    v := was_pressed^
    was_pressed^ = false
    showText(rect, rl.GetColor(0xaaaaffff), text, ALIGN_LEFT, mode, color)
    append(&Buttons, UI_Button{rect, was_pressed, mode})
    return v
}

showBanners :: proc() {
    using shared

    for &city, index in cities {
        showBanner(&city, index)
    }
    @(static) ps :[128]bool = {}
    showBanner :: proc(using city : ^City, index: int) {
        scale := 1.0 / cam.zoom
        lift := i32(20.0*scale)
        x: i32 = i32(location.coordinate.x)*tileSize + tileSize/2
        y: i32 = i32(location.coordinate.y)*tileSize - lift 
        width := i32(128.0*scale)
        height := i32(32.0*scale)
        rect := Rect{f32(x - width/2), f32(y), f32(width), f32(height)}
        if showButton(rect, rl.GetColor(0xaa2299bb), &ps[index], .MAP) {
            if rl.IsMouseButtonPressed(.LEFT) {
                selectedCity = city
            }
        }
        pop_rect := chopRectangle(&rect, rect.width/4, .LEFT)
        showText(rect, rl.GetColor(0x5299ccbb), name, ALIGN_LEFT, .MAP)
        builder := strings.builder_make()
        strings.write_int(&builder, len(population))
        pop_text := strings.to_cstring(&builder)
        showText(pop_rect, rl.GOLD, pop_text, ALIGN_CENTER, .MAP)
    }
}

showCityUI :: proc() {
    using shared

    showSidebar2(subRectangle(windowRect, 0.2, 0.6, ALIGN_RIGHT, ALIGN_CENTER))
    showSidebar(subRectangle(windowRect, 0.2, 0.8, ALIGN_LEFT, ALIGN_CENTER))
}

showSidebar :: proc(r: Rect) {
    using shared

    r := r
    padding :: 1.45
    assert(selectedCity != nil)
    
    showRect(r, rl.PURPLE, .UI)
    text: cstring = selectedCity != {} ? selectedCity.name : "NULL"
    title_rect := chopRectangle(&r, r.height/5.0, .TOP)
    entry_size := r.height/5
    showRect(title_rect, rl.GetColor(0x992465ff), .UI)
    showText(title_rect, rl.GetColor(0x229f54ff), text, ALIGN_CENTER, .UI)
    @(static) ps: [64]bool = {}
    assert(len(ps) >= len(projectManifest))
    for project, index in projectManifest {
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
        if showButton(entry_rect, rl.PURPLE, &ps[index], .UI) {
            if rl.IsMouseButtonPressed(.LEFT) {
                selectedCity.project = project
                selectedCity = nil
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

showSidebar2 :: proc(r: Rect) {
    using shared

    r := r
    padding :: 1.45
    assert(selectedCity != nil)

    // entry_size := r.height/5
    for building in selectedCity.buildings {
        name := building.type.name
        texture := building.type.texture
        entry_rect := chopRectangle(&r, f32(texture.height/2), .TOP)
        showRect(entry_rect, rl.PURPLE,  .UI)
        sprite_rect := chopRectangle(&entry_rect, f32(texture.width/2), .LEFT)
        showSprite(sprite_rect, texture, .UI)
        entry_rect = subRectangle(entry_rect, 1.0, 0.35, ALIGN_LEFT, ALIGN_TOP)
        showRect(entry_rect, rl.GetColor(0x18181899), .UI)
        entry_rect = subRectangle(entry_rect, 0.97, 0.77, ALIGN_RIGHT, ALIGN_TOP)
        showText(entry_rect, rl.GetColor(0xaaaaffff), name, ALIGN_LEFT, .UI, rl.GOLD)
    }
}

showBorders :: proc() {
    using shared

    for faction in factions {
        for city in faction.cities {
            assert(city.tiles != nil, "city tiles pointer was nil")
            for tl in city.tiles {
                assert(tl != nil, "tile pointer was nil")
                color := faction.type.primary_color
                color.a = 72
                rect := tile.getRect(tl)
                showRect(rect, color, .MAP)
                center := Vector2{rect.x + rect.width/2, rect.y + rect.height/2}
                color = faction.type.secondary_color
                color.a = 255
                for direction in OrthogonalDirections {
                    neighbor := tile.get(tl.coordinate + direction)
                    if neighbor != nil && (neighbor.owner == nil || neighbor.owner.owner == nil || neighbor.owner.owner.id != faction.id) {
                        nrect := tile.getRect(neighbor)
                        target := Vector2{nrect.x + nrect.width/2, nrect.y + nrect.height/2}
                        edge := (target - center) / 2
                        offset := edge * linalg.matrix2_rotate_f32(math.PI/2)
                        start := center + edge - offset
                        end := center + edge + offset
                        showLine(start, end, 6, color, .MAP)
                    }
                }
            }
        }
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

drawMapStuff :: proc() {
    for rect in rectsToDraw {
        if rect.mode == .MAP {
            rl.DrawRectangleRec(rect.rect, rect.color)
        }
    }
    for line in linesToDraw {
        if line.mode == .MAP {
            rl.DrawLineEx(line.start, line.end, line.thickness, line.color)
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
    for line in linesToDraw {
        if line.mode == .UI {
            rl.DrawLineEx(line.start, line.end, line.thickness, line.color)
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
    clear(&linesToDraw)
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

findFocus :: proc(mouse_position: Vector2, cam: rl.Camera2D) {
    lucky_contestant: ^bool = nil
    for button in Buttons {
        switch button.mode {
            case .MAP: {
                if rl.CheckCollisionPointRec(rl.GetScreenToWorld2D(mouse_position, cam), button.rect) {
                    lucky_contestant = button.was_pressed
                }
            }
            case .UI: {
                if rl.CheckCollisionPointRec(mouse_position, button.rect) {
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