package first

import "core:log"

import "./game"

main ::proc() {
    context.logger = log.create_console_logger()
    
    game.start()
}