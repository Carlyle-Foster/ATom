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
    p.tile = t
    p.state = .WORKING
}

