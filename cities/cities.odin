package cities

import "core:log"
import "core:strings"

import shared "../shared"
import unit "../units"
import tile "../tiles"
import citizen "../pops"
import project "../projects"
import rendering "../rendering"

City :: shared.City
BuildingType :: shared.BuildingType
Building :: shared.Building

Faction :: shared.Faction
Tile :: shared.Tile

create :: proc(f: ^Faction, t: ^Tile) -> ^City {
    using shared

    append(&game.cities, City{
        name = getNextName(f), 
        owner = f, 
        destroyed = false, 
        population = {}, 
        buildings = {},
        growth = 0.0, 
        project = {}, 
        location = t, 
        tiles = {},
        renderer_id = -1,
    })
    city := &game.cities[len(game.cities) - 1]
    append(&f.cities, city)
    for tl in tile.getInRadius(t, 1) {
        tile.claim(city, tl)
    }
    for tl in tile.getInRadius(t, 7) {
        tl.discovery_mask += {int(f.id)}
    }
    t.flags += { .CONTAINS_CITY }
    city.population = { citizen.create(city) }
    city.renderer_id = rendering.createCityRenderer(city)
    log.debug(city.location.discovery_mask)
    return city
}

getNextName :: proc(f: ^Faction) -> cstring {
    @(static) count  := 1
    builder := strings.Builder{}
    strings.write_string(&builder, string(f.type.name))
    strings.write_string(&builder, " ")
    strings.write_int(&builder, count)
    count += 1
    return strings.to_cstring(&builder)
}

getPopCost :: proc(c: City) -> f32 {
    base := 10
    mult := 5
    return f32(base + len(c.population)*mult)
}

isVisibleToPlayer :: proc(using c: ^City) -> bool {
    using shared

    return int(game.playerFaction.id) in location.discovery_mask && !destroyed
}

update :: proc(c: ^City) {
    using shared

    yields: [YieldType]f32
    multipliers: [YieldType]f32 = {.FOOD=1, .PRODUCTION=1, .SCIENCE=1, .GOLD=1}
    yields += c.location.terrain.yields
    for p in c.population {
        if p.state == .WORKING {
            yields += p.tile.terrain.yields
        }
        yields[.FOOD] -= citizen.DIET
    }
    for building in c.buildings {
        yields += building.type.yields
        multipliers += building.type.multipliers
    }
    yields[.PRODUCTION] += 2.0
    yields[.SCIENCE] += f32(len(c.population))*1.0
    yields *= multipliers
    c.growth += f32(yields[.FOOD])
    c.hammers += f32(yields[.PRODUCTION])
    c.owner.gold += f32(yields[.GOLD])
    c.owner.science += yields[.SCIENCE]
    c.owner.science += f32(len(c.population))
    pop_cost := getPopCost(c^)
    for c.growth >= pop_cost {
        append(&c.population, citizen.create(c))
        c.growth -= pop_cost
        pop_cost = getPopCost(c^)
    }
    for c.growth < 0 {
        pop(&c.population)
        pop_cost = getPopCost(c^)
        c.growth += pop_cost
        if len(c.population) == 0 {
            destroy(c)
            return
        }
    }
    if c.project != nil {
        project_cost := f32(project.getCost(c.project))
        if c.hammers >= project_cost {
            switch type in c.project {
                case ^UnitType: unit.create(type,  c.owner, c.location)
                case ^BuildingType: createBuilding(type, c)
            }
            c.hammers -= project_cost
            c.project = nil
        }
    }
    log.info("Population:", len(c.population), "growth", c.growth, "growth required", getPopCost(c^))
}

createBuilding :: proc(t: ^BuildingType, c: ^City) -> ^Building {
    building := Building {
        type = t,
    }
    log.info("BUILT:", building)
    append(&c.buildings, building)
    return &c.buildings[len(c.buildings) - 1]
}

destroy :: proc(c: ^City) {
    assert(!c.destroyed)
    c.location.flags -= { .CONTAINS_CITY }
    log.info("city destroyed, name:", c.name, ", owner:", c.owner.type.name)
    delete(c.population)
    delete(c.tiles)
    delete(c.buildings)
    for ct, index in c.owner.cities {
        if ct == c {
            unordered_remove(&c.owner.cities, index)
        }
    } 
    c.destroyed = true
}
