package ATom

import "core:log"
import "core:strings"
import "core:math"

import rl "vendor:raylib"

City :: struct {
    name: cstring,
    owner: ^Faction,
    destroyed: bool,
    population: [dynamic]Pop,
    buildings: [dynamic]Building,
    growth: f32, 
    hammers: f32,
    project: ProjectType,
    location: ^Tile,
    tiles: [dynamic]^Tile,
    renderer_id: int,
}

Building :: struct {
    type: ^BuildingType,
}

BuildingType :: struct {
    name: cstring,
    texture: rl.Texture,
    yields: [YieldType]f32,
    multipliers: [YieldType]f32,
    cost: i32,
}

createCity :: proc(f: ^Faction, t: ^Tile) -> ^City {
    append(&game.cities, City{
        name = getNextCityName(f), 
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
    for tl in getTilesInRadius(t, 1) {
        claimTile(city, tl)
    }
    for tl in getTilesInRadius(t, 7) {
        tl.discovery_mask += {int(f.id)}
    }
    t.flags += { .CONTAINS_CITY }
    city.population = { createCitizen(city) }
    CityBannerCreate(city)
    return city
}

getNextCityName :: proc(f: ^Faction) -> cstring {
    @(static) count  := 1
    builder := strings.Builder{}
    strings.write_string(&builder, string(f.type.name))
    strings.write_string(&builder, " ")
    strings.write_int(&builder, count)
    count += 1
    return strings.to_cstring(&builder)
}

cityGetPopCost :: proc(c: City) -> f32 {
    base := 10
    mult := 5
    return f32(base + len(c.population)*mult)
}

cityIsVisibleToPlayer :: proc(using c: ^City) -> bool {
    return int(game.playerFaction.id) in location.discovery_mask && !destroyed
}

updateCity :: proc(c: ^City) {
    yields: [YieldType]f32
    multipliers: [YieldType]f32 = {.FOOD=1, .PRODUCTION=1, .SCIENCE=1, .GOLD=1}
    yields += c.location.terrain.yields
    yields[.FOOD] = math.max(yields[.FOOD], 2) // the base tile thus always provides at least 2 food
    for p in c.population {
        if p.state == .WORKING {
            yields += p.tile.terrain.yields
        }
        yields[.FOOD] -= CITIZEN_DIET
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
    pop_cost := cityGetPopCost(c^)
    for c.growth >= pop_cost {
        append(&c.population, createCitizen(c))
        c.growth -= pop_cost
        pop_cost = cityGetPopCost(c^)
    }
    for c.growth < 0 {
        pop(&c.population)
        pop_cost = cityGetPopCost(c^)
        c.growth += pop_cost
        if len(c.population) == 0 {
            destroyCity(c)
            return
        }
    }
    if c.project != nil {
        project_cost := f32(getProjectCost(c.project))
        if c.hammers >= project_cost {
            switch type in c.project {
                case ^UnitType: createUnit(type,  c.owner, c.location)
                case ^BuildingType: createBuilding(type, c)
            }
            c.hammers -= project_cost
            c.project = nil
        }
    }
    log.info("Population:", len(c.population), "growth", c.growth, "growth required", cityGetPopCost(c^))
}

createBuilding :: proc(t: ^BuildingType, c: ^City) -> ^Building {
    building := Building {
        type = t,
    }
    log.info("BUILT:", building)
    append(&c.buildings, building)
    return &c.buildings[len(c.buildings) - 1]
}

destroyCity :: proc(c: ^City) {
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
