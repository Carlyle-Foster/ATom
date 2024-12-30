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
    for y in 0..<i32(game.world.dimensions.y) {
        for x in 0..<i32(game.world.dimensions.x) {
            t := tile.get(x, y)
            c := rl.ColorFromHSV(t.terrain.hue, 0.65, 1)
            if t.discovery_mask & (1 << game.playerFaction.id) > 0 {
                rl.DrawRectangle(x*size, y*size, size, size, c)
            }
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
    if !city.destroyed {
        rlx.drawAtopTile(textures.city, city.location)
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
    rlx.drawAtopTile(unit.type.texture, unit.tile)
}

pops :: proc() {
    using shared

    for faction in game.factions {
        for city in faction.cities {
            for pop in city.population {
                transparent :: Color{255,255,255,128}
                tint := pop.state == .WORKING ? rl.WHITE : transparent
                rlx.drawAtopTile(textures.pop, pop.tile,  tint)
            }
        }
    }
}