package projects

import "core:log"

import shared "../shared"

ProjectType :: shared.ProjectType
UnitType :: shared.UnitType
BuildingType :: shared.BuildingType

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

syncManifest :: proc() {
    clear(&shared.projectManifest)
    for unit_type in shared.UnitTypeManifest {
        p: ProjectType = unit_type
        append(&shared.projectManifest, p)
    }
    for building_type in shared.BuildingTypeManifest {
        p: ProjectType = building_type
        append(&shared.projectManifest, p)
    }
}

