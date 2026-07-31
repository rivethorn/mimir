/*
 Mimir - Odin's toolchain
*/

package main

import "core:fmt"
import "core:os"
import "pkgs:cli"
import "pkgs:new"

VERSION := #config(VERSION, "0.1.4")

main :: proc() {
	if len(os.args) < 2 {
		cli.print_usage(os.stderr)
		os.exit(1)
	}

	state: State

	get_command(&state)

	switch state.command {
	case .Build:
		fmt.println("build")
	case .New:
		new.create()
	case .Version:
		fmt.println("Mimir version", VERSION)
	case .Help:
		cli.print_usage()
	case .Error:
		cli.unknown_command()
		cli.print_usage(os.stderr)
		os.exit(1)
	}
}

