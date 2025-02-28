package tiles

import "core:math/rand"
import "core:log"

import shared "../shared"

Tile :: shared.Tile
YieldType :: shared.YieldType
ResourceType :: shared.ResourceType
Coordinate :: shared.Coordinate
Terrain :: shared.Terrain
MovementType :: shared.MovementType

City :: shared.City
Unit :: shared.Unit
Rect :: shared.Rect

Flags :: shared.TileFlags

create :: proc(coordinate: Coordinate, terrain: ^Terrain, resource: ResourceType) -> Tile {
    using shared

    return Tile {
        coordinate = coordinate, 
        terrain = terrain, 
        resource = resource, 
        owner = nil, 
        units = nil, 
        discovery_mask = 0, 
        visibility_mask = 0,
        flags = {},
    }
}

getDestructured ::proc(x, y: i32) -> ^Tile {
    using shared

    if (x < 0 || x >= i32(game.world.dimensions.x)) || (y < 0 || y >= i32(game.world.dimensions.y)) {
        return nil
    }
    else {
        location := x + y*i32(game.world.dimensions.x)
        return &game.world.tiles[location]
    }
}

getByCoordinates ::proc(c: Coordinate) -> ^Tile {
    using shared

    if (c.x < 0 || c.x >= i16(game.world.dimensions.x)) || (c.y < 0 || c.y >= i16(game.world.dimensions.y)) {
        return {}
    }
    else {
        location := i32(c.x) + i32(c.y)*i32(game.world.dimensions.x)
        return &game.world.tiles[location]
    }
}

claim :: proc(c: ^City, t: ^Tile) {
    assert(t != nil)
    assert(c != nil)
    if t.owner == nil {
        t.owner = c
        append(&c.tiles, t)
    }
}

get :: proc{getByCoordinates, getDestructured}

getRandom :: proc() -> ^Tile {
    using shared
    using game

    x := rand.int_max(int(game.world.dimensions.x))
    y := rand.int_max(int(game.world.dimensions.y))
    log.debug(x, y)
    return get(i32(x), i32(y))
}

getRect :: proc(t: ^Tile) -> Rect {
    using shared

    r := Rect {
        x = f32(t.coordinate.x) * tileSize,
        y = f32(t.coordinate.y) * tileSize,
        width = tileSize,
        height = tileSize,
    }
    return r
}

getInRadius :: proc(center: ^Tile, range: i16, include_center := true) -> [dynamic]^Tile {
    tiles := make([dynamic]^Tile, 0, (range*2+1) << 2, context.temp_allocator)
    for y in -range..=range {
        for x in -range..=range {
            t := get(Coordinate{center.coordinate.x + x, center.coordinate.y + y})
            if t != nil && (include_center || t != center) {
                append(&tiles, t)
            }
        }
    }
    return tiles
}

getMovementType :: proc(t: ^Tile) -> MovementType {
    if .CONTAINS_CITY in t.flags do return .CITY
    else do return t.terrain.movement_type
}

