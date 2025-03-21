package units

import "core:log"
import "core:math/rand"

import shared "../shared"
import pathing "../pathing"
import tile "../tiles"
import rendering "../rendering"

Handle :: shared.Handle
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
    entered(new_unit, t)
    rendering.createUnitRenderer(unit)
    log.info("new unit: ", new_unit)
}

update :: proc(uh: Handle(Unit)) {
    using shared
    u := handleRetrieve(&game.units, uh).? or_else unreachable()

    u.stamina = u.type.stamina
    advance(uh)
}

advance :: proc(uh: Handle(Unit)) {
    using shared
    u := handleRetrieve(&game.units, uh).? or_else unreachable()
    for ; u.stamina > 0 && len(u.path) > 0; u.stamina -= 1 {
        for handle, index in u.tile.units {
            if handle == uh {
                unordered_remove(&u.tile.units, index)
            }
        }
        u.tile = pop(&u.path, )
        entered(uh, u.tile)
    }
}

sendToTile :: proc(uh: Handle(Unit), t: ^Tile) {
    using shared
    u := handleRetrieve(&game.units, uh).? or_else unreachable()

    u.path = pathing.find(u.tile, t, u)
    for tile in u.path {
        log.debug(tile.coordinate.x, tile.coordinate.y)
    }
    advance(uh)
}

entered :: proc(uh: Handle(Unit), t: ^Tile) {
    using shared

    u := handleRetrieve(&game.units, uh).? or_else unreachable()
    for h in t.units {
        mb_enemy := handleRetrieve(&game.units, h).? or_else unreachable()
        if mb_enemy.owner == u.owner do continue
        odds := calculateBattleOdds(u^, mb_enemy^)
        roll := rand.float32()
        if roll <= odds { // we win
            destroy(h)
            log.debug("ATTACKERS WON")
        } else { // we lose
            destroy(uh)
            log.debug("DEFENDERS WON")
        }
    }
    append(&t.units, uh)
    visibility: i16 = 2
    for tl in tile.getInRadius(t, visibility) {
        tl.discovery_mask += {int(u.owner.id)}
    }
}

destroy :: proc(uh: Handle(Unit)) {
    using shared
    u := handleRetrieve(&game.units, uh).? or_else unreachable()
    for i := 0; i < len(u.tile.units); i += 1 {
        if u.tile.units[i] == uh {
            unordered_remove(&u.tile.units, i)
            break
        }
    }
    handleRemove(&game.units, uh)
}

calculateBattleOdds :: proc(me, u: Unit) -> f32 {
    return 1.
}