package factions

import "core:math/rand"
import "core:container/small_array"

import shared "../shared"
import city "../cities"
import unit "../units"
import tile "../tiles"

Faction :: shared.Faction

generateFactions :: proc(faction_count: int) {
    using shared

    contenders: small_array.Small_Array(256, int)
    for i in 0..<len(factionTypeManifest) {
        small_array.append(&contenders, i)
    }
    for id in 0..<faction_count {
        winner := rand.int_max(small_array.len(contenders))
        faction_type := factionTypeManifest[small_array.get(contenders, winner)]
        faction := Faction {
            type = faction_type,
            id = u32(id),
            cities = make([dynamic]^City, 0, 1024*1),
            units = make([dynamic]^Unit, 0, 1024*4),
            gold = 0.0,
        }
        append(&factions, faction)
        small_array.unordered_remove(&contenders, winner)
        if small_array.len(contenders) == 0 {
            for i in 0..<len(factionTypeManifest) {
                small_array.append(&contenders, i)
            }
        }
    }
}

doAiTurn :: proc(f: ^Faction) {
    using shared

    count := 0
    for len(f.cities) == 0 {
        tile := tile.getRandom()
        if tile.owner == nil && tile.terrain.movement_type == .LAND {
            city.create(f, tile)
        }
        count += 1
        if count > 100 do break
    }
    for city in f.cities {
        i := 0
        for &pop in city.population {
            if pop.state == .UNEMPLOYED && i < len(city.tiles) {
                employPop(&pop, city.tiles[i])
            }
            i += 1
        }
        for u in f.units {
                target := u.tile.coordinate
                target.x  += 1
                tile := tile.get(target)
                if tile != nil {
                    unit.sendToTile(u, tile)
                }
        }
        if len(city.location.units) == 0 && city.project == nil {
            for project in projectManifest {
                switch type in project {
                    case UnitType:
                        if .LAND in type.habitat {
                            city.project = project
                            break
                        }
                    case BuildingType: 
                        continue
                }
            }
        }
    }
}