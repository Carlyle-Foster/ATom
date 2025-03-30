package ATom

import "core:math/rand"

Tile :: struct {
    coordinate: Coordinate,
    terrain: ^Terrain,
    resource: ResourceType,
    owner: ^City,
    units: [dynamic]Handle(Unit),
    discovery_mask: bit_set[0..<32],
    visibility_mask: [32]u8,
    flags: bit_set[TileFlags],
}

TileFlags :: enum {
    CONTAINS_CITY,
    WORKED,
}

Terrain :: struct {
    name: cstring,
    id: i32,
    yields: [YieldType]f32,
    movement_type: MovementType,
    spawn_rate: i32,
}

createTile :: proc(coordinate: Coordinate, terrain: ^Terrain, resource: ResourceType) -> Tile {
    return Tile {
        coordinate = coordinate, 
        terrain = terrain, 
        resource = resource, 
        owner = nil, 
        units = nil, 
        discovery_mask = {}, 
        visibility_mask = 0,
        flags = {},
    }
}

getTile :: proc{getTileByCoordinates, getTileDestructured}

getTileDestructured ::proc(x, y: i32) -> ^Tile {
    if (x < 0 || x >= i32(game.world.dimensions.x)) || (y < 0 || y >= i32(game.world.dimensions.y)) {
        return nil
    }
    else {
        location := x + y*i32(game.world.dimensions.x)
        return &game.world.tiles[location]
    }
}

getTileByCoordinates ::proc(c: Coordinate) -> ^Tile {
    if (c.x < 0 || c.x >= i16(game.world.dimensions.x)) || (c.y < 0 || c.y >= i16(game.world.dimensions.y)) {
        return {}
    }
    else {
        location := i32(c.x) + i32(c.y)*i32(game.world.dimensions.x)
        return &game.world.tiles[location]
    }
}

claimTile :: proc(c: ^City, t: ^Tile) {
    assert(t != nil)
    assert(c != nil)
    if t.owner == nil {
        t.owner = c
        append(&c.tiles, t)
    }
}

getRandomTile :: proc() -> ^Tile {
    using game

    x := rand.int_max(int(game.world.dimensions.x))
    y := rand.int_max(int(game.world.dimensions.y))
    return getTile(i32(x), i32(y))
}

getTileRect :: proc(t: Tile) -> Rect {
    r := Rect {
        x = f32(t.coordinate.x) * tileSize,
        y = f32(t.coordinate.y) * tileSize,
        width = tileSize,
        height = tileSize,
    }
    return r
}

getTilesInRadius :: proc(center: ^Tile, range: i16, include_center := true) -> [dynamic]^Tile {
    tiles := make([dynamic]^Tile, 0, (range*2+1) << 2, context.temp_allocator)
    for y in -range..=range {
        for x in -range..=range {
            t := getTile(Coordinate{center.coordinate.x + x, center.coordinate.y + y})
            if t != nil && (include_center || t != center) {
                append(&tiles, t)
            }
        }
    }
    return tiles
}

getTileMovementType :: proc(t: ^Tile) -> MovementType {
    if .CONTAINS_CITY in t.flags do return .CITY
    else do return t.terrain.movement_type
}

