package ATom

import rl "vendor:raylib"

drawAtopTile :: proc(tx: Texture, tl: Tile, tint := rl.WHITE) {
    source := Rect{0, 0, f32(tx.width), f32(tx.height)}
    destination := getTileRect(tl)
    rl.DrawTexturePro(tx, source, destination, Vector2{0,0}, 0, tint)
}