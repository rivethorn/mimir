package cli

import "core:os"
import "pkgs:state"

state_init :: proc(app_state: ^state.State) {
	set_main_command(app_state)
	set_config(app_state)
}

@(private = "file")
set_main_command :: proc(app_state: ^state.State) {
	switch os.args[1] {
	case "help", "h":
		app_state.command = .Help
	case "version":
		app_state.command = .Version
	case "new":
		app_state.command = .New
	case "build", "b":
		app_state.command = .Build
	case "run", "r":
		app_state.command = .Run
	case:
		app_state.command = .Error
	}
}

@(private = "file")
set_config :: proc(app_state: ^state.State) {
	#partial switch app_state.command {
	case .Build:
		for i := 2; i < len(os.args); i += 1 {
			switch os.args[i] {
			case "--help", "-h":
				print_build_usage()
				os.exit(0)
			case "--release", "-r":
				app_state.config.release = true
			case "--silent", "-s":
				app_state.config.silent = true
			case:
				print_build_unexpected_arg(os.args[i])
				os.exit(1)
			}
		}
	case .Run:
		for i := 2; i < len(os.args); i += 1 {
			switch os.args[i] {
			case "--help", "-h":
				print_run_usage()
				os.exit(0)
			case "--release", "-r":
				app_state.config.release = true
			case "--silent", "-s":
				app_state.config.silent = true
			case "--force", "-f":
				app_state.config.force_recompile = true
			case:
				print_run_unexpected_arg(os.args[i])
				os.exit(1)
			}
		}
	}
}

