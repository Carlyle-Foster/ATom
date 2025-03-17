package ATom

import "core:log"

getProjectCost :: proc(p: ProjectType) -> i32 {
    switch type in p {
        case ^UnitType: {
            return type.cost
        }
        case ^BuildingType: {
            return type.cost
        }
        case: {
            log.panic()
        }
    }
}

getProjectName :: proc(p: ProjectType) -> cstring {
    switch type in p {
        case ^UnitType: {
            return type.name
        }
        case ^BuildingType: {
            return type.name
        }
        case: {
            log.panic()
        }
    }
}

getProjectTexture :: proc(p: ProjectType) -> Texture {
    switch type in p {
        case ^UnitType: {
            return type.texture
        }
        case ^BuildingType: {
            return type.texture
        }
        case: {
            log.panic()
        }
    }
}

