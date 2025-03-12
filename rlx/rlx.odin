package rlx

import rl "vendor:raylib"

import shared "../shared"
import tile "../tiles"

Texture :: shared.Texture
Rect :: shared.Rect
Tile :: shared.Tile

drawAtopTile :: proc(tx: Texture, tl: Tile, tint := rl.WHITE) {
    using shared

    source := Rect{0, 0, f32(tx.width), f32(tx.height)}
    destination := tile.getRect(tl)
    rl.DrawTexturePro(tx, source, destination, Vector2{0,0}, 0, tint)
}