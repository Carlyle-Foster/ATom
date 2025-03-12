package pops

import shared "../shared"

Pop :: shared.Pop
Tile :: shared.Tile
City :: shared.City

DIET: f32 = 2.0

create :: proc(c: ^City) -> Pop {
    return Pop{.UNEMPLOYED, c.location}
}

employ :: proc(p: ^Pop, t: ^Tile) {
    if t.flags & {.WORKED, .CONTAINS_CITY} != nil do return

    if p.tile != nil {
        p.tile.flags -= {.WORKED}
    }
    p.tile = t
    p.state = .WORKING
    t.flags += {.WORKED}
}

