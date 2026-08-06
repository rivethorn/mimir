/*
 Mimir - Odin's toolchain
*/

package main

import "core:fmt"
import "core:os"
import "pkgs:add"
import "pkgs:build"
import "pkgs:clean"
import "pkgs:cli"
import "pkgs:new"
import "pkgs:run"
import "pkgs:state"

VERSION := #config(VERSION, "0.6.0")

main :: proc() {
	if len(os.args) < 2 {
		cli.print_general_usage(os.stderr)
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
	case .Clean:
		clean.handle_clean()
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
