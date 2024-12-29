package units

import "core:log"

import rl "vendor:raylib"

import shared "../shared"
import pathing "../pathing"
import tile "../tiles"


Unit :: shared.Unit
UnitType :: shared.UnitType

MovementType :: shared.MovementType
Faction :: shared.Faction
Tile :: shared.Tile

create :: proc(ut: UnitType, f: ^Faction, t: ^Tile) {
    using shared

    append(&game.units, Unit{ut, f, t, {}})
    new_unit := &game.units[len(game.units) - 1] 
    append(&f.units, new_unit)
    entered(new_unit, t)
    log.info("new unit: ", new_unit)
}

draw :: proc(using unit: Unit) {
    using shared
    rl.DrawTextureEx(unit.type.texture, Vector2{f32(tile.coordinate.x)*tileSize, f32(tile.coordinate.y)*tileSize}, 0.0, 0.5, rl.WHITE)
}

update :: proc(u: ^Unit) {
    if len(u.path) > 0 {
        for unit, index in u.tile.units {
            if unit == u {
                unordered_remove(&u.tile.units, index)
            }
        }
        u.tile = pop(&u.path, )
        append(&u.tile.units, u)
    }
}

sendToTile :: proc(u: ^Unit, t: ^Tile) {
    u.path = pathing.find(u.tile, t, u)
    for tile in u.path {
        log.debug(tile.coordinate.x, tile.coordinate.y)
    }
}

entered :: proc(u: ^Unit, t: ^Tile) {
    append(&t.units, u)
    visibility: i16 = 5
    for tl in tile.getInRadius(t, visibility) {
        tl.discovery_mask = 1
    }
}