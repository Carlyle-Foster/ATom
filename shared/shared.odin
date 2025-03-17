package ATom

import "core:encoding/json"

import rl "vendor:raylib"

HandledArray :: struct(T: typeid) {
    _inner: [dynamic]HandledData(T),
    vacancies: [dynamic]i16,
}
HandledData :: struct(T: typeid) {
    generation: i16,
    _inner: T,
}
Handle :: struct(T: typeid) {
    generation, index: i16,
}
invalidHandle :: proc($T: typeid) -> Handle(T) { return {-1, -1} }
handleValid :: proc(h: Handle($T)) -> bool { return h.index >= 0 }

makeHandledArray :: proc($T: typeid, capacity: i16 = 16) -> HandledArray(T) {
    return {
        _inner = make([dynamic]HandledData(T), 0, capacity),
        vacancies = make([dynamic]i16, 0, capacity),
    }
}
handleRetrieve :: proc(ha: ^HandledArray($T), h: Handle(T)) -> Maybe(^T) {
    a := &ha._inner

    if (h.index >= i16(len(a))) || (h.index < 0) { return nil }

    result := &a[h.index]
    if h.generation != result.generation { return nil }
    else { return &result._inner }
}
handleFromIndex :: proc(ha: ^HandledArray($T), index: i16) -> Handle(T) {
    return Handle(T) {
        generation = ha._inner[index].generation, 
        index = index, 
    }
}
handlePush :: proc(ha: ^HandledArray($T), item: T) -> Handle(T) {
    a := &ha._inner
    v := &ha.vacancies

    i: i16
    if len(v) > 0 {
        i = pop(v)
        a[i].generation *= -1
        a[i]._inner = item
        return {a[i].generation, i}
    } else {
        i = i16(len(a))
        append(a, HandledData(T){0, item})
        return {0, i}
    }
}
handleRemove :: proc(ha: ^HandledArray($T), h: Handle(T)) -> Maybe(T) {
    a := &ha._inner
    v := &ha.vacancies

    item := &a[h.index]
    if item.generation == h.generation {
        item.generation += 1
        item.generation *= -1
        append(v, h.index)
        return item._inner
    } else {
        return nil
    }
    
}

uiState :: enum {
    MAP,
    TECH,
}
currentUIState := uiState.MAP

GameState :: struct {
    world: World,
    factions: [dynamic]Faction,
    cities: [dynamic]City,
    units: HandledArray(Unit),
    playerFaction: ^Faction,
}
game: GameState

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

UnitType :: struct {
    name: cstring,
    texture: rl.Texture,
    strength: i32,
    defense: i32,
    stamina: i32,
    habitat: bit_set[MovementType],
    cost: i32,
}

Unit :: struct {
    type: ^UnitType,
    owner: ^Faction,
    tile: ^Tile,
    path: [dynamic]^Tile,
    stamina: i32,
    renderer: UnitRenderer,
}

UnitRenderer :: struct {
    unit: ^Unit,
}

Terrain :: struct {
    name: cstring,
    id: i32,
    yields: [YieldType]f32,
    movement_type: MovementType,
    spawn_rate: i32,
}

Tile :: struct {
    coordinate: Coordinate,
    terrain: ^Terrain,
    resource: ResourceType,
    owner: ^City,
    units: [dynamic]Handle(Unit),
    discovery_mask: bit_set[0..<32],
    visibility_mask: [32]u8,
    flags: bit_set[TileFlags],
}

TileFlags :: enum {
    CONTAINS_CITY,
    WORKED,
}

MovementType :: enum {
    OCEAN,
    COAST,
    LAND,
    MOUNTAIN,
    CITY,
}

turn: int = 0

windowDimensions := Vector2{1280, 720}

windowRect: Rect = {}

tileSize: f32 = 64

cam: rl.Camera2D = {}
camNoZoom: rl.Camera2D = {}
mousePosition := Vector2{}
mouseMovement := Vector2{}
leftMouseDown := false

selectedCity: ^City = {}
selectedUnit: Handle(Unit) = {}

Color :: rl.Color
Vector2 :: rl.Vector2
Rect :: rl.Rectangle
Texture :: rl.Texture
Coordinate :: [2]i16

OrthogonalDirections :: [4]Coordinate{
    {1 , 0},
    {-1, 0},
    {0 , 1},
    {0 ,-1},
}

textures: TextureManifest = {}
TextureManifest :: struct {
    city: Texture,
    valet: Texture,
    pop: Texture,
    technology: Texture,
    tile_set: Texture,
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

World :: struct {
    dimensions: Vector2,
    tiles: [dynamic]Tile,
    seed: i64,
}

TerrainManifest : [dynamic]Terrain = {}
UnitTypeManifest : [dynamic]UnitType = {}
BuildingTypeManifest: [dynamic]BuildingType = {}
projectManifest: [dynamic]ProjectType = {}
factionTypeManifest: [dynamic]FactionType = {}
TechnologyManifest: [dynamic]Technology = {}

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
    type: ^BuildingType,
}

ProjectType :: union {
    ^UnitType,
    ^BuildingType,
}

Technology :: struct {
    id: int,
    name: cstring,
    projects: [dynamic]ProjectType,
    cost: int,
}
MAX_TECHS :: 128

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

JsonDecree :: json.Marshal_Options {
    spec = .MJSON,
    pretty = true,
    mjson_keys_use_equal_sign = true,
    use_enum_names = true,
    write_uint_as_hex = false,
}