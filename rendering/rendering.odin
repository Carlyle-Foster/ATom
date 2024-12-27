package rendering

import rl "vendor:raylib"

import shared "../shared"
import city "../cities"
import unit "../units"
import tile "../tiles"

gameMap :: proc() {
    using shared

    tile := Tile{}
    color := Color{}
    size := i32(tileSize)
    for y in 0..<mapDimensions.y {
        for x in 0..<mapDimensions.x {
            tile = gameMap[x + y*mapDimensions.x]
            color = rl.ColorFromHSV(tile.terrain.hue, 0.65, 1)
            if tile.discovery_mask & (1 << playerFaction.id) > 0 {
                rl.DrawRectangle(x*size, y*size, size, size, color)
            }
        }
    }
    for c in cities {
        city.draw(c)
    }
    for u in units {
        unit.draw(u)
    }
}

pops :: proc() {
    using shared

    for faction in factions {
        for city in faction.cities {
            for pop in city.population {
                rect := tile.getRect(pop.tile)
                transparent :: Color{255,255,255,128}
                tint := pop.state == .WORKING ? rl.WHITE : transparent
                rl.DrawTextureEx(textures.pop, Vector2{rect.x, rect.y}, 0.0, 0.5,  tint)
            }
        }
    }
}