/*
 Mimir - Odin's toolchain
*/

package main

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "pkgs:add"
import "pkgs:build"
import "pkgs:clean"
import "pkgs:cli"
import "pkgs:list"
import "pkgs:new"
import "pkgs:remove"
import "pkgs:run"
import "pkgs:state"
import "pkgs:update"
import "pkgs:util"

VERSION := #config(VERSION, "0.10.1")

main :: proc() {
	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena)
	context.allocator = mem.dynamic_arena_allocator(&arena)
	defer mem.dynamic_arena_destroy(&arena)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if len(os.args) < 2 {
		cli.print_general_usage(os.stderr)
		os.exit(1)
	}

	if !util.is_odin_project() {
		fmt.eprintln(
			"Current directory does not contain a valid Odin project for Mimir to work with.",
		)

		os.exit(1)
	}

	state: state.State

	cli.state_init(&state)

	switch state.command {
	case .Build:
		build.handle_build(&state)
	case .Run:
		run.handle_run(&state)
	case .New:
		new.create()
	case .Add:
		add.handle_add(&state)
	case .Remove:
		remove.handle_remove(&state)
	case .Update:
		update.handle_update(&state)
	case .List:
		list.handle_list()
	case .Clean:
		clean.handle_clean(&state)
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
