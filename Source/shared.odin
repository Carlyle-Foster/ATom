package ATom

import "core:container/priority_queue"

import rl "vendor:raylib"

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

YieldType :: enum i8 {
    FOOD,
    PRODUCTION,
    GOLD,
    SCIENCE,
}

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

ProjectType :: union {
    ^UnitType,
    ^BuildingType,
}

MovementType :: enum {
    OCEAN,
    COAST,
    LAND,
    MOUNTAIN,
    CITY,
}

game: GameState

uiElements_SCREEN: priority_queue.Priority_Queue(uiElement)

uiElements_WORLD: priority_queue.Priority_Queue(uiElement)

init_ui_system :: proc() {
    uiElements_SCREEN = priority_queue.Priority_Queue(uiElement){
        queue = make([dynamic]uiElement, len = 0, cap = 128),
        less = proc(a, b: uiElement) -> bool { return a.z_index < b.z_index },
        swap = priority_queue.default_swap_proc(uiElement),
    }

    uiElements_WORLD = priority_queue.Priority_Queue(uiElement){
        queue = make([dynamic]uiElement, len = 0, cap = 128),
        less = proc(a, b: uiElement) -> bool { return a.z_index < b.z_index },
        swap = priority_queue.default_swap_proc(uiElement),
    }
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

textures: TextureManifest = {}

TerrainManifest : [dynamic]Terrain = {}
UnitTypeManifest : [dynamic]UnitType = {}
BuildingTypeManifest: [dynamic]BuildingType = {}
projectManifest: [dynamic]ProjectType = {}
factionTypeManifest: [dynamic]FactionType = {}
TechnologyManifest: [dynamic]Technology = {}

// JsonDecree :: json.Marshal_Options {
//     spec = .MJSON,
//     pretty = true,
//     mjson_keys_use_equal_sign = true,
//     use_enum_names = true,
//     write_uint_as_hex = false,
// }