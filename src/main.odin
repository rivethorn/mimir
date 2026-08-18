/*
 Mimir - Odin's toolchain
*/

package main

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "pkgs:args"
import "pkgs:cli"
import "pkgs:command"
import "pkgs:state"
import "pkgs:util"

VERSION :: "0.12.2"

main :: proc() {
	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena)
	context.allocator = mem.dynamic_arena_allocator(&arena)
	defer mem.dynamic_arena_destroy(&arena)

	if len(os.args) < 2 {
		cli.print_general_usage(os.stderr)
		os.exit(1)
	}

	state: state.State

	args.set_main_command(&state)

	if !util.is_general_command(state.command) && !util.is_odin_project() {
		cli.print_no_proj()
		os.exit(1)
	}

	args.set_config(&state)

	switch state.command {
	case .Build:
		command.handle_build(&state)
	case .Run:
		command.handle_run(&state)
	case .New:
		command.handle_new(&state)
	case .Add:
		command.handle_add(&state)
	case .Remove:
		command.handle_remove(&state)
	case .Update:
		command.handle_update(&state)
	case .List:
		command.handle_list()
	case .Install:
		command.handle_install(&state)
	case .Uninstall:
		command.handle_uninstall(&state)
	case .Clean:
		command.handle_clean(&state)
	case .Version:
		fmt.println("Mimir version", VERSION)
	case .Help:
		cli.print_general_usage()
	case .Error:
		cli.unknown_command()
		cli.print_general_usage(os.stderr)
		os.exit(1)
	}
}
