package ATom

import "core:encoding/json"

import rl "vendor:raylib"

uiState :: enum {
    MAP,
    TECH,
}
currentUIState := uiState.MAP

GameState :: struct {
    world: World,
    factions: [dynamic]Faction,
    cities: [dynamic]City,
    units: [dynamic]Unit,
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

CityRenderer :: struct {
    city: ^City,
    was_clicked: bool, 
}
CityRendererList: [dynamic]CityRenderer

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
    renderer_id: int,
}

UnitRenderer :: struct {
    unit: ^Unit,
}
UnitRendererList: [dynamic]UnitRenderer

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

windowDimensions := Vector2{1280, 720}

windowRect: Rect = {}

tileSize: f32 = 64

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
    type: BuildingType,
}

ProjectType :: union {
    UnitType,
    BuildingType,
}

Technology :: struct {
    id: int,
    name: cstring,
    projects: [dynamic]ProjectType,
    cost: int,
}
MAX_TECHS :: 128

Faction :: struct {
    type: FactionType,
    id: u32,
    cities: [dynamic]^City,
    units:  [dynamic]^Unit,
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