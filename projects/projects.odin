package projects

import "core:log"

import shared "../shared"

ProjectType :: shared.ProjectType
UnitType :: shared.UnitType
BuildingType :: shared.BuildingType

Texture :: shared.Texture

getCost :: proc(p: ProjectType) -> i32 {
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

getName :: proc(p: ProjectType) -> cstring {
    switch type in p {
        case UnitType: {
            return type.name
        }
        case BuildingType: {
            return type.name
        }
        case: {
            log.panic()
        }
    }
}

getTexture :: proc(p: ProjectType) -> Texture {
    switch type in p {
        case UnitType: {
            return type.texture
        }
        case BuildingType: {
            return type.texture
        }
        case: {
            log.panic()
        }
    }
}

