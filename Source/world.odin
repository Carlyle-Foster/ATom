package ATom

import "core:fmt"

import "core:math"
import "core:math/rand"
import "core:math/linalg"

import rl "vendor:raylib"

initializeWorld :: proc(width, height: i32, starting_terrain: Terrain, seed: i64 = 0) -> World {
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

generateWorld :: proc(tiles_per_island: i16 = 512) {
    using math

    default: ^Terrain
    shares: i32 = 0
    total_tiles := i16(floor(game.world.dimensions.y) * floor(game.world.dimensions.x))
    total_islands := total_tiles / tiles_per_island
    
    for &t in TerrainManifest {
        if t.name == "shallows" do default = &t
        shares += t.spawn_rate
    }
    assert(default != {})

    islands := make([]Coordinate, total_islands)
    fmt.println("total islands =", total_islands)
    for i in 0..<len(islands) {
        islands[i] = getRandomCoordinate()
        fmt.println(islands[i])
    }

    for y in 0..<i16(floor(game.world.dimensions.y)) {
        for x in 0..<i16(floor(game.world.dimensions.x)) {
            c := Coordinate{x,y}
            far_out := max(i32)
            for il in islands {
                distance_squared := i32(linalg.length2(il - c))
                if distance_squared < far_out do far_out = distance_squared
            }
            ring := i64(far_out / 2)

            bias := i32(ring*ring*ring / 128)
            assert(bias >= 0)
            r := rl.GetRandomValue(1, shares + bias)
            chosen: ^Terrain
            for &t in TerrainManifest {
                r -= t.spawn_rate
                if r <= 0 {
                    chosen = &t
                    break
                }
            }
            if chosen == {} do chosen = default

            getTile(c)^  = createTile(c, chosen, .PEARLS)
        }
    }
}

getRandomCoordinate :: proc() -> Coordinate {
    x := rand.int_max(int(game.world.dimensions.x))
    y := rand.int_max(int(game.world.dimensions.y))
    return Coordinate{i16(x), i16(y)}
}