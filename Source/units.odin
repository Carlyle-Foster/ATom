package ATom

import "core:log"
import "core:math/rand"

import rl "vendor:raylib"

Unit :: struct {
    type: ^UnitType,
    owner: ^Faction,
    tile: ^Tile,
    path: [dynamic]^Tile,
    stamina: i32,
    renderer: UnitRenderer,
}

UnitType :: struct {
    name: cstring,
    texture: rl.Texture,
    strength: i32,
    defense: i32,
    stamina: i32,
    habitat: bit_set[MovementType],
    cost: i32,
}

createUnit :: proc(ut: ^UnitType, f: ^Faction, t: ^Tile) {
    log.debug("unit created at coordinates:", t.coordinate, "at tile:", t)

    new_unit := handlePush(&game.units, Unit{ut, f, t, {}, ut.stamina, {}})
    append(&f.units, new_unit)
    unit := handleRetrieve(&game.units, new_unit).? or_else unreachable()
    unitEnteredTile(new_unit, t)
    createUnitRenderer(unit)
    log.info("new unit: ", new_unit)
}

updateUnit :: proc(uh: Handle(Unit)) {
    u := handleRetrieve(&game.units, uh).? or_else unreachable()

    u.stamina = u.type.stamina
    advanceUnit(uh)
}

advanceUnit :: proc(uh: Handle(Unit)) {
    u := handleRetrieve(&game.units, uh).? or_else unreachable()
    for ; u.stamina > 0 && len(u.path) > 0; u.stamina -= 1 {
        for handle, index in u.tile.units {
            if handle == uh {
                unordered_remove(&u.tile.units, index)
            }
        }
        u.tile = pop(&u.path, )
        unitEnteredTile(uh, u.tile)
    }
}

sendUnitToTile :: proc(uh: Handle(Unit), t: ^Tile) {
    u := handleRetrieve(&game.units, uh).? or_else unreachable()

    u.path = findPath(u.tile, t, u)
    for tile in u.path {
        log.debug(tile.coordinate.x, tile.coordinate.y)
    }
    advanceUnit(uh)
}

unitEnteredTile :: proc(uh: Handle(Unit), t: ^Tile) {
    u := handleRetrieve(&game.units, uh).? or_else unreachable()
    for h in t.units {
        mb_enemy := handleRetrieve(&game.units, h).? or_else unreachable()
        if mb_enemy.owner == u.owner do continue
        odds := calculateBattleOdds(u^, mb_enemy^)
        roll := rand.float32()
        if roll <= odds { // we win
            destroyUnit(h)
            log.debug("ATTACKERS WON")
        } else { // we lose
            destroyUnit(uh)
            log.debug("DEFENDERS WON")
        }
    }
    append(&t.units, uh)
    visibility: i16 = 2
    for tl in getTilesInRadius(t, visibility) {
        tl.discovery_mask += {int(u.owner.id)}
    }
}

destroyUnit :: proc(uh: Handle(Unit)) {
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