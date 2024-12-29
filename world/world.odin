package world

import "core:math"
import "core:math/rand"

import rl "vendor:raylib"

import shared "../shared"
import tile "../tiles"

World :: shared.World
Tile :: shared.Tile
Terrain :: shared.Terrain
Vector2 :: shared.Vector2

initialize :: proc(width, height: i32, starting_terrain: Terrain, seed: i64 = 0) -> World {
    assert(width > 0)
    assert(height > 0)
    seed := seed
    if seed == 0 {
        seed = i64(rand.uint64())
    }
    tiles := make([dynamic]Tile, width*height)
    return World {
        dimensions = Vector2{f32(width), f32(height)},
        tiles = tiles,
        seed = seed,
    }
}

generate :: proc() {
    using shared
    using math

    off_center, radius: f32

    for y in 0..<i16(floor(game.world.dimensions.y)) {
        for x in 0..<i16(floor(game.world.dimensions.x)) {
            off_center   =   abs(f32(x) / game.world.dimensions.x - 0.5)*2.0
            radius      =   sin(f32(y) / game.world.dimensions.y * PI)
            c := Coordinate{x,y}
            if radius > off_center {
                r := rl.GetRandomValue(0, 24)
                if r == 0 {
                    tile.get(c)^  = tile.create(c, TerrainManifest[0], .PEARLS)
                }
                else {
                    tile.get(c)^  = tile.create(c, TerrainManifest[1], .PLATINUM)
                }
            }
            else {
                tile.get(c)^ = tile.create(c, TerrainManifest[2], .PLATINUM)
            }
        }
    }
}