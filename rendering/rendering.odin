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
    for y in 0..<i32(game.world.dimensions.y) {
        for x in 0..<i32(game.world.dimensions.x) {
            tile = game.world.tiles[x + y*i32(game.world.dimensions.x)]
            color = rl.ColorFromHSV(tile.terrain.hue, 0.65, 1)
            if tile.discovery_mask & (1 << game.playerFaction.id) > 0 {
                rl.DrawRectangle(x*size, y*size, size, size, color)
            }
        }
    }
    for c in game.cities {
        if !c.destroyed {
            city.draw(c)
        }
    }
    for u in game.units {
        unit.draw(u)
    }
}

pops :: proc() {
    using shared

    for faction in game.factions {
        for city in faction.cities {
            for pop in city.population {
                transparent :: Color{255,255,255,128}
                tint := pop.state == .WORKING ? rl.WHITE : transparent
                source := Rect{0, 0, f32(textures.pop.width), f32(textures.pop.height)}
                destination := tile.getRect(pop.tile)
                rl.DrawTexturePro(textures.pop, source, destination, Vector2{0,0}, 0.0,  tint)
            }
        }
    }
}