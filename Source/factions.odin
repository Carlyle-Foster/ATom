package ATom

import "core:log"
import "core:math/rand"
import "core:math/linalg"
import "core:container/small_array"

import rl "vendor:raylib"

Faction :: struct {
    type: ^FactionType,
    id: u32,
    cities: [dynamic]^City,
    units:  [dynamic]Handle(Unit),
    gold: f32,
    science: f32,
    techs: bit_set[0..<MAX_TECHS],
    research_project: Technology,
}

FactionType :: struct {
    name: cstring,
    primary_color: rl.Color,
    secondary_color: rl.Color,
}

generateFactions :: proc(faction_count: int) -> [dynamic]Faction {
    factions: [dynamic]Faction = {}
    contenders: small_array.Small_Array(256, int)
    for i in 0..<len(factionTypeManifest) {
        small_array.append(&contenders, i)
    }
    for id in 0..<faction_count {
        winner := rand.int_max(small_array.len(contenders))
        faction_type := &factionTypeManifest[small_array.get(contenders, winner)]
        faction := Faction {
            type = faction_type,
            id = u32(id),
            cities = make([dynamic]^City, 0, 1024*1),
            units = make([dynamic]Handle(Unit), 0, 1024*4),
            gold = 0.0,
            techs = { 0 }, //this is the always the first tech listed in TechnologyManifest.sql
            research_project = {id = -1},
        }
        append(&factions, faction)
        small_array.unordered_remove(&contenders, winner)
        if small_array.len(contenders) == 0 {
            for i in 0..<len(factionTypeManifest) {
                small_array.append(&contenders, i)
            }
        }
    }
    return factions
}

updateFaction :: proc(f: ^Faction) {
    for c in f.cities {
        updateCity(c)
    }

    for i := 0; i < len(f.units); {
        uh := f.units[i]
        if _, ok := handleRetrieve(&game.units, uh).?; ok {
            updateUnit(uh)
            i += 1
        }
        else {
            unordered_remove(&f.units, i)
        }
    }
    tech_cost := f32(f.research_project.cost)
    if f.research_project.id != -1 && f.science >= tech_cost {
        f.techs += { f.research_project.id }
        f.science -= tech_cost
        f.research_project.id = -1
    }
}

doAiTurn :: proc(f: ^Faction) {
    for uh in f.units {
        u := handleRetrieve(&game.units, uh).? or_continue
        i16_max :: 1 << 14
        closest: i16 = i16_max
        target: ^Tile
        for tl in getTilesInRadius(u.tile, 4, include_center = false) {
            for uh2 in tl.units {
                possible_enemy := handleRetrieve(&game.units, uh2).? or_continue
                if possible_enemy.owner != u.owner {
                    distance := linalg.vector_length2(tl.coordinate - u.tile.coordinate)
                    if distance < closest {
                        log.debug("LOCKED ON")
                        closest = distance
                        target = tl
                        break
                    }
                }
            }
        }
        if closest != i16_max {
            sendUnitToTile(uh, target)
        }
    }
    for city in f.cities {
        for &p, i in city.population {
            if p.state == .UNEMPLOYED && i < len(city.tiles) {
                chosen, ok := chooseTileToWork(f, city).?
                if ok {
                    employCitizen(&p, chosen)
                }
            }
        }
        needed_protection := len(city.population)
        if city.project == nil {
            surroundings: bit_set[MovementType]
            for tile in city.tiles {
                surroundings += {tile.terrain.movement_type}
            }
            projects: for project in projectManifest {
                switch type in project {
                case ^UnitType:
                    if len(city.location.units) >= needed_protection { continue }
                    if type.habitat & surroundings != {} {
                        city.project = project
                        break
                    }
                case ^BuildingType: 
                    if len(city.location.units) < needed_protection { continue }
                    for b in city.buildings {
                        if b.type.name == project.(^BuildingType).name { continue projects }
                    }
                    city.project = project
                    break
            }
            }
        }
    }
    if f.research_project.id == -1 {
        for tech in TechnologyManifest {
            if tech.id not_in f.techs {
                f.research_project = tech
                break
            }
        }
    }
}

chooseTileToWork :: proc(f: ^Faction, c: ^City) -> Maybe(^Tile) {
    chosen: ^Tile
    high_score := 0
    
    for t in c.tiles {
        if t.flags & {.WORKED, .CONTAINS_CITY} != nil do continue
        
        score := 0
        for y in YieldType {
            score += int(t.terrain.yields[y])
            if score > high_score {
                chosen, high_score = t, score
            }
        }
    }
    return chosen
}