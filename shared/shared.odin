package ATom

import "core:log"

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

UnitType :: struct {
    name: cstring,
    texture: rl.Texture,
    strength: i32,
    defense: i32,
    habitat: bit_set[MovementType],
    cost: i32,
}

Unit :: struct {
    type: UnitType,
    owner: ^Faction,
    tile: ^Tile,
    path: [dynamic]^Tile,
}

Terrain :: struct {
    name: cstring,
    yields: [YieldType]f32,
    movement_type: MovementType,
    hue: f32,
}

Tile :: struct {
    coordinate: Coordinate,
    terrain: Terrain,
    resource: ResourceType,
    owner: ^City,
    units: [dynamic]^Unit,
    discovery_mask: u64,
    visibility_mask: u64,
    flags: bit_set[TileFlags],
}

TileFlags :: enum {
    CONTAINS_CITY,
}

MovementType :: enum {
    OCEAN,
    COAST,
    LAND,
    MOUNTAIN,
    CITY,
}

playerFaction: ^Faction = {}

cities := [dynamic]City{}
units := [dynamic]Unit{}
factions := [dynamic]Faction{}

mapDimensions: [2]i32
gameMap: [dynamic]Tile

windowDimensions :: Vector2{1280, 720}

windowRect: Rect = {}

tileSize: i32 = 64

POP_DIET: f32 = 2.0

cam: rl.Camera2D = {}
camNoZoom: rl.Camera2D = {}
mousePosition := Vector2{}
mouseMovement := Vector2{}
leftMouseDown := false

selectedCity: ^City = {}
selectedUnit: ^Unit = {}

Color :: rl.Color
Vector2 :: rl.Vector2
Rect :: rl.Rectangle
Coordinate :: [2]i16

OrthogonalDirections :: [4]Coordinate{
    {1 , 0},
    {-1, 0},
    {0 , 1},
    {0 ,-1},
}

textures: TextureManifest = {}
TextureManifest :: struct {
    city: rl.Texture,
    valet: rl.Texture,
    pop: rl.Texture,
}

YieldType :: enum i8 {
    FOOD,
    PRODUCTION,
    GOLD,
    SCIENCE,
}

Pop :: struct {
    state: enum {
        WORKING,
        UNEMPLOYED,
    },
    tile: ^Tile,
}

new_pop :: proc(c: ^City) -> Pop {
    return Pop{.UNEMPLOYED, c.location}
}

employPop :: proc(p: ^Pop, t: ^Tile) {
    p.tile = t
    p.state = .WORKING
}

TerrainManifest : [dynamic]Terrain = {}
UnitTypeManifest : [dynamic]UnitType = {}
BuildingTypeManifest: [dynamic]BuildingType = {}
projectManifest: [dynamic]ProjectType = {}
factionTypeManifest: [dynamic]FactionType = {}

ResourceType :: enum i16 {
    NO_RESOURCE = -1,
    PLATINUM,
    SILVER,
    JEWELS,
    BANANAS,
    CARPETS,
    PEARLS,
    IVORY,
    COCOA,
    FISHES,
    SHARKS,
    COFFEE,
    RESOURCE_TYPE_COUNT,
}

BuildingType :: struct {
    name: cstring,
    texture: rl.Texture,
    yields: [YieldType]f32,
    multipliers: [YieldType]f32,
    cost: i32,
}

Building :: struct {
    type: BuildingType,
}

ProjectType :: union {
    UnitType,
    BuildingType,
}

getProjectCost :: proc(p: ProjectType) -> i32 {
    switch type in p {
        case UnitType: {
            return type.cost
        }
        case BuildingType: {
            return type.cost
        }
        case: {
            log.panic()
        }
    }
}

Faction :: struct {
    type: FactionType,
    id: u32,
    cities: [dynamic]^City,
    units:  [dynamic]^Unit,
    gold: f32,
}

FactionType :: struct {
    name: cstring,
    primary_color: rl.Color,
    secondary_color: rl.Color,
}