package ATom

// import "core:math/rand"
// import "core:container/small_array"

import rl "vendor:raylib"

UnitType :: struct {
    name: cstring,
    texture: rl.Texture,
    strength: i32,
    defense: i32,
    cost: i32,
}

Unit :: struct {
    type: UnitType,
    owner: ^Faction,
    tile: ^Tile,
}

createUnit :: proc(ut: UnitType, f: ^Faction, t: ^Tile) {
    append(&units, Unit{ut, f, t})
    new_unit := &units[len(units) - 1] 
    unitEntered(new_unit, t)
    println("new unit: ", new_unit)
}

drawUnits :: proc() {
    for unit in units {
        drawUnit(unit)
    }
    drawUnit :: proc(using unit: Unit) {
        rl.DrawTextureEx(unit.type.texture, Vector2{f32(i32(tile.coordinate.x)*tileSize), f32(i32(tile.coordinate.y)*tileSize)}, 0.0, 0.5, rl.WHITE)
    }
}