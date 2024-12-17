package ATom

import "core:strings"

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
}

createCity :: proc(f: ^Faction, t: ^Tile) -> ^City {
    append(&cities, City{
        name = getNextCityName(), 
        owner = f, 
        destroyed = false, 
        population = {new_pop(t)}, 
        buildings = {},
        growth = 0.0, 
        project = {}, 
        location = t, 
        tiles = {},
    })
    city := &cities[len(cities) - 1]
    // println("len(cities)-1 =", len(cities)-1)
    // println(city.population)
    append(&f.cities, city)
    for tile in getTilesInRadius(t.coordinate, 1) {
        claimTile(city, tile)
    }
    return city
}

inspectCities :: proc() {
    if (len(cities)-1) == 8 {
        for city in factions[0].cities {
            println(city.name)
            println(city.population[0])
            for tile in city.tiles {
                println(tile)
                assert(tile != nil,"tile was nil!")
            }
        }
    }
}

getNextCityName :: proc() -> cstring {
    @(static) count  := 1
    builder := strings.Builder{}
    strings.write_int(&builder, count)
    count += 1
    println("asfh", count)
    return strings.to_cstring(&builder)
}

drawCities :: proc() {
    for city in cities {
        drawCity(city)
    }
    drawCity :: proc(using city: City) {
        rl.DrawTextureEx(textures.city, Vector2{f32(i32(location.coordinate.x)*tileSize), f32(i32(location.coordinate.y)*tileSize)}, 0.0, 0.5, rl.WHITE)
    }
}

updateCity :: proc(c: ^City) {
    yields: [YieldType]f32
    multipliers: [YieldType]f32 = {.FOOD=1, .PRODUCTION=1, .SCIENCE=1, .GOLD=1}
    yields += c.location.terrain.yields
    for pop in c.population {
        if pop.state == .WORKING {
            yields += pop.tile.terrain.yields
        }
        yields[.FOOD] -= POP_DIET 
    }
    for building in c.buildings {
        yields += building.type.yields
        multipliers += building.type.multipliers
    }
    yields *= multipliers
    c.growth += f32(yields[.FOOD])
    c.hammers += f32(yields[.PRODUCTION])
    c.owner.gold += f32(yields[.GOLD])
    pop_cost := getCityPopCost(c^)
    for c.growth >= pop_cost {
        append(&c.population, new_pop(c.location))
        c.growth -= pop_cost
        pop_cost = getCityPopCost(c^)
    }
    if c.project != nil {
        project_cost := f32(getProjectCost(c.project))
        if c.hammers >= project_cost {
            switch type in c.project {
                case UnitType: createUnit(type,  c.owner, c.location)
                case BuildingType: createBuilding(type, c)
            }
            c.hammers -= project_cost
            c.project = nil
        }
    }
    println("Population:", len(c.population), "growth", c.growth, "growth required", getCityPopCost(c^))
}

destroyCity :: proc(c: ^City) {
    assert(!c.destroyed)
    delete(c.population)
    delete(c.tiles)
    delete(c.buildings)
    c.destroyed = true
}
