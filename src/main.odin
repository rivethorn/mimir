/*
 Mimir - Odin's toolchain

 The command line is defined and parsed in pkgs:args (with reflags); this
 file only switches on the parsed state.Command and dispatches to the
 handlers in pkgs:command.
*/

package main

import "core:fmt"
import "pkgs:args"
import "pkgs:command"
import "pkgs:state"

main :: proc() {
	app_state: state.State
	cmd := args.parse(&app_state)

	#partial switch cmd {
	case .Build:
		command.handle_build(&app_state)
	case .Run:
		command.handle_run(&app_state)
	case .New:
		command.handle_new(&app_state)
	case .Install:
		command.handle_install(&app_state)
	case .Uninstall:
		command.handle_uninstall(&app_state)
	case .Clean:
		command.handle_clean(&app_state)
	case .Version:
		fmt.println("Mimir version", args.VERSION)
	case:
		// .Help and .Error are handled (and exit) inside args.parse.
	}
}
