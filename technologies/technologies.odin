package technologies

import "core:log"

import rl "vendor:raylib"

import shared "../shared"
import project "../projects"
import ui "../ui"

Technology :: shared.Technology

Rect :: shared.Rect
Vector2 :: shared.Vector2
Color :: shared.Color

drawTechnology :: proc(r: Rect, t: Technology) {
    using shared

    @(static) ps: [MAX_TECHS]bool = {}
    researched := t.id in game.playerFaction.techs
    color1, color2: Color
    if researched {
        color1, color2 = rl.DARKBROWN, rl.GOLD
    }
    else if t.id == game.playerFaction.research_project.id {
        color1, color2 = rl.BLUE, rl.DARKBLUE
    }
    else if ps[t.id] { //this is really stupid
        color1, color2 = rl.DARKGREEN, rl.LIME
    }
    else {
        color1, color2 = rl.DARKGREEN, rl.GREEN
    }
    if ui.showButton(r, color1, &ps[t.id], .UI) {
        if rl.IsMouseButtonPressed(.LEFT) && !researched {
            game.playerFaction.research_project = t
            currentUIState = .MAP
            log.info("selected technology:", t.name)
        } 
    }
    text_box := Rect{r.x, r.y, r.width, r.height/2} 
    rl.DrawRectangleRec(text_box, color2)
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