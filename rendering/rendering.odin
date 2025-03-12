package rendering
import rl "vendor:raylib"
import rlx "../rlx"

import shared "../shared"
import tile "../tiles"

City :: shared.City
Unit :: shared.Unit
CityRenderer :: shared.CityRenderer
UnitRenderer :: shared.UnitRenderer

gameMap :: proc() {
    using shared

    size := i32(tileSize)
    offset_unit: f32 = 128
    for y in 0..<i32(game.world.dimensions.y) {
        for x in 0..<i32(game.world.dimensions.x) {
            t := tile.get(x, y)
            sizef := f32(size)
            xf, yf := f32(x), f32(y)
            offset := offset_unit*f32(t.terrain.id)
            if int(game.playerFaction.id) not_in t.discovery_mask {
                offset = 0
                // sizef *= 3
            }
            source := Rect{
                offset, 0,
                offset_unit, offset_unit, 
            }
            dest := Rect{
                xf*sizef, yf*sizef,
                sizef, sizef,
            }
            rl.DrawTexturePro(textures.tile_set, source, dest, Vector2{0,0}, 0, rl.WHITE)
        }
    }
    for cr in CityRendererList {
        renderCity(cr)
    }
    for ur in UnitRendererList {
        renderUnit(ur)
    }
}

createCityRenderer :: proc(c: ^City) -> (renderer_id: int) {
    using shared
    append(&CityRendererList, CityRenderer{c, false})
    renderer_id = len(CityRendererList) - 1
    return
}

renderCity :: proc(using cr: CityRenderer) {
    using shared
    if int(game.playerFaction.id) in city.location.discovery_mask && !city.destroyed {
        rlx.drawAtopTile(textures.city, city.location^)
    }
}

createUnitRenderer :: proc(u: ^Unit) -> (renderer_id: int) {
    using shared
    append(&UnitRendererList, UnitRenderer{u})
    renderer_id = len(UnitRendererList) - 1
    return
}

renderUnit :: proc(using ur: UnitRenderer) {
    using shared
    if int(game.playerFaction.id) in unit.tile.discovery_mask {
        rlx.drawAtopTile(unit.type.texture, unit.tile^)
    }
}

pops :: proc() {
    using shared
    if selectedCity != nil {
        for pop in selectedCity.population {
            transparent :: Color{255,255,255,128}
            tint := pop.state == .WORKING ? rl.WHITE : transparent
            rlx.drawAtopTile(textures.pop, pop.tile^,  tint)
        }
    }
}