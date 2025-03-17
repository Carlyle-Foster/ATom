package ATom

CITIZEN_DIET: f32 = 2.0

createCitizen :: proc(c: ^City) -> Pop {
    return Pop{.UNEMPLOYED, c.location}
}

employCitizen :: proc(p: ^Pop, t: ^Tile) {
    if t.flags & {.WORKED, .CONTAINS_CITY} != nil do return

    if p.tile != nil {
        p.tile.flags -= {.WORKED}
    }
    p.tile = t
    p.state = .WORKING
    t.flags += {.WORKED}
}

