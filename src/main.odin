/*
Mimir - Odin's toolchain

The command line is defined and parsed in pkgs:args (with reflags). Each
command has its handler attached via reflags' Command_Handler system, so
main just invokes `args.parse` which dispatches to the correct handler.
*/

package main

import "core:mem"
import "pkgs:app"

main :: proc() {
	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena)
	context.allocator = mem.dynamic_arena_allocator(&arena)
	defer mem.dynamic_arena_destroy(&arena)

	app.parse_and_run()
}
