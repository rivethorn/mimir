/*
 Mimir - Odin's toolchain
*/

package main

import "core:fmt"
import "core:os"
import "pkgs:build"
import "pkgs:cli"
import "pkgs:new"
import "pkgs:run"

VERSION := #config(VERSION, "0.3.3")

main :: proc() {
	if len(os.args) < 2 {
		cli.print_general_usage(os.stderr)
		os.exit(1)
	}

	state: State

	get_command(&state)

	switch state.command {
	case .Build:
		build.handle_build()
	case .Run:
		run.handle_run()
	case .New:
		new.create()
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

