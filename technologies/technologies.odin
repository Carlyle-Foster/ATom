package technologies

import rl "vendor:raylib"

import shared "../shared"
import project "../projects"

Technology :: shared.Technology

Rect :: shared.Rect
Vector2 :: shared.Vector2

drawTechnology :: proc(r: Rect, t: Technology) {
    rl.DrawRectangleRec(r, rl.PURPLE)
    text_box := Rect{r.x, r.y, r.width, r.height/2} 
    rl.DrawRectangleRec(text_box, rl.DARKPURPLE)
    rl.DrawText(t.name, i32(r.x), i32(r.y), i32(30), rl.RAYWHITE)
    offset: f32 = 0
    for p in t.projects {
        texture := project.getTexture(p)
        icon_rect := Rect{r.x + offset, r.y + r.height/2, r.width/4, r.height/2}
        shape := Rect{0, 0, f32(texture.width), f32(texture.height)}
        rl.DrawTexturePro(texture, shape, icon_rect, Vector2{0, 0}, 0, rl.WHITE)
        offset += r.width/4
    }
}

drawTree :: proc(r: Rect) {
    using shared

    entry_size := int(r.height) / (len(TechnologyManifest)+1)
    height: f32 = 120
    for tech, index in TechnologyManifest {
        rect := Rect{0, f32(entry_size*(index+1)) - height/2, 200, height}
        drawTechnology(rect, tech)
    }
}