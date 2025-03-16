package units

import "core:log"
import "core:math/rand"

import shared "../shared"
import pathing "../pathing"
import tile "../tiles"
import rendering "../rendering"


Unit :: shared.Unit
UnitType :: shared.UnitType
UnitRenderer :: shared.UnitRenderer

MovementType :: shared.MovementType
Faction :: shared.Faction
Tile :: shared.Tile

create :: proc(ut: ^UnitType, f: ^Faction, t: ^Tile) {
    using shared

    log.debug("unit created at coordinates:", t.coordinate, "at tile:", t)

    new_unit := handlePush(&game.units, Unit{ut, f, t, {}, ut.stamina, {}})
    append(&f.units, new_unit)
    unit := handleRetrieve(&game.units, new_unit).? or_else unreachable()
    entered(unit, t)
    rendering.createUnitRenderer(unit)
    log.info("new unit: ", new_unit)
}

update :: proc(u: ^Unit) {
    u.stamina = u.type.stamina
    advance(u)
}

advance :: proc(u: ^Unit) {
    for ; u.stamina > 0 && len(u.path) > 0; u.stamina -= 1 {
        for unit, index in u.tile.units {
            if unit == u {
                unordered_remove(&u.tile.units, index)
            }
        }
        u.tile = pop(&u.path, )
        entered(u, u.tile)
    }
}

sendToTile :: proc(u: ^Unit, t: ^Tile) {
    u.path = pathing.find(u.tile, t, u)
    for tile in u.path {
        log.debug(tile.coordinate.x, tile.coordinate.y)
    }
    advance(u)
}

entered :: proc(u: ^Unit, t: ^Tile) {
    for mb_enemy in t.units {
        if mb_enemy.owner == u.owner do continue
        odds := calculateBattleOdds(u^, mb_enemy^)
        roll := rand.float32()
        if roll <= odds {
            unimplemented()
        } else {
            unimplemented()
        }
    }
    append(&t.units, u)
    visibility: i16 = 2
    for tl in tile.getInRadius(t, visibility) {
        tl.discovery_mask += {int(u.owner.id)}
    }
}

calculateBattleOdds :: proc(me, u: Unit) -> f32 {
    return 1.
}