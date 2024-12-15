package ATom

Tile :: struct {
    coordinate: Coordinate,
    terrain: Terrain,
    resource: ResourceType,
    owner: ^City,
    units: [dynamic]^Unit,
    discovery_mask: u64,
    visibility_mask: u64,
}

createTile :: proc(coordinate: Coordinate, terrain: Terrain, resource: ResourceType) -> Tile {
    assert(playerFaction != nil)
    return Tile {
        coordinate = coordinate, 
        terrain = terrain, 
        resource = resource, 
        owner = nil, 
        units = nil, 
        discovery_mask = 1 << playerFaction.id, 
        visibility_mask = 0,
    }
}

getTileDestructured ::proc(x, y: i32) -> ^Tile {
    if (x < 0 || x >= mapDimensions.x) || (y < 0 || y >= mapDimensions.y) {
        return {}
    }
    else {
        location := x + y*mapDimensions.x
        return &gameMap[location]
    }
}

getTileByCoordinates ::proc(c: Coordinate) -> ^Tile {
    if (c.x < 0 || c.x >= i16(mapDimensions.x)) || (c.y < 0 || c.y >= i16(mapDimensions.y)) {
        return {}
    }
    else {
        location := i32(c.x) + i32(c.y)*mapDimensions.x
        return &gameMap[location]
    }
}

claimTile :: proc(c: ^City, t: ^Tile) {
    assert(t != nil)
    assert(c != nil)
    t.owner = c
    append(&c.tiles, t)
}

getTile :: proc{getTileByCoordinates, getTileDestructured}

getTileRect :: proc(t: ^Tile) -> Rect {
    return Rect {
        x = f32(i32(t.coordinate.x) * tileSize),
        y = f32(i32(t.coordinate.y) * tileSize),
        width = f32(tileSize),
        height = f32(tileSize),
    }
}

getTilesInRadius :: proc(center: Coordinate, range: i16) -> [dynamic]^Tile {
    tiles := make([dynamic]^Tile, 0, (range*2+1) << 2, context.temp_allocator)
    for y in -range..=range {
        for x in -range..=range {
            t := getTile(Coordinate{center.x + x, center.y + y})
            if t != nil {
                append(&tiles, t)
            }
        }
    }
    return tiles
}