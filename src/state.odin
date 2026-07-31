package main

import "core:os"
import "pkgs:cli"

State :: struct {
	command: cli.Command,
}

get_command :: proc(state: ^State) {
	switch os.args[1] {
	case "help", "h":
		state.command = .Help
	case "version":
		state.command = .Version
	case "new":
		state.command = .New
	case "build", "b":
		state.command = .Build
	case:
		state.command = .Error
	}
}

