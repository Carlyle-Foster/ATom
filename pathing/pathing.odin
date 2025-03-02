package pathing

//implements the A* pathfinding algorithm

import "core:math"
import "core:log"
import "core:container/priority_queue"

import shared "../shared"
import tile "../tiles"

Tile :: shared.Tile
Unit :: shared.Unit

A_StarNode :: struct {
    start_tile: ^Tile,
    target_tile: ^Tile,
    current_tile: ^Tile,
    parent: ^A_StarNode,
    cost: int,
}

find :: proc(start: ^Tile, end: ^Tile, unit: ^Unit) -> [dynamic]^Tile {
    using shared

    frontier := priority_queue.Priority_Queue(^A_StarNode){}
    priority_queue.init(&frontier, less, swap)
    defer priority_queue.destroy(&frontier)
    
    selected_tile := start 
    selected_node := new(A_StarNode, context.temp_allocator)
    selected_node^ = {start, end, start, nil, 1}
    priority_queue.push(&frontier, selected_node)

    log.debug("START SEARCH {")
    count := 0
    for selected_node.current_tile != end {
        count += 1
        if count > 4096 do return {}
        log.debug("    ", selected_tile.coordinate)
        for tl in tile.getInRadius(selected_tile, 1, include_center = false) {
            if tile.getMovementType(tl) in unit.type.habitat {
                node := new(A_StarNode, context.temp_allocator)
                node^ = {start, end, tl, selected_node, selected_node.cost + 1}
                priority_queue.push(&frontier, node)
            }
        }
        if priority_queue.len(frontier) == 0 do break
        selected_node = priority_queue.pop(&frontier)
        selected_tile = selected_node.current_tile
    }
    log.debug("} END SEARCH")
    path := make([dynamic]^Tile, 0, 128) 
    for {
        if selected_node.parent == nil {
            break
        }
        append(&path, selected_node.current_tile)
        selected_node = selected_node.parent
    }
    return path

    

    less :: proc(a, b: ^A_StarNode) -> bool {
        return getCost(a) < getCost(b)

        getCost :: proc(node: ^A_StarNode) -> int {
            return node.cost + heuristic(node.current_tile.coordinate, node.target_tile.coordinate)

            heuristic :: proc(start, end: Coordinate) -> int {
                using math
                return int(max(abs(end.x - start.x), abs(end.y - start.y)))
            }
        }
    }

    swap :: proc(q: []^A_StarNode, i, j: int) {
        saved := q[i]
        q[i] = q[j]
        q[j] = saved
    }
}