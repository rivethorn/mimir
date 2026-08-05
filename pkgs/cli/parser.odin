package cli

import "core:os"
import "core:strings"
import "pkgs:state"

state_init :: proc(app_state: ^state.State) {
	set_main_command(app_state)
	set_config(app_state)
}

@(private = "file")
set_main_command :: proc(app_state: ^state.State) {
	for elem in Main_Commands {
		if os.args[1] == elem.name || os.args[1] == elem.short {
			app_state.command = elem.command
		}
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
		outer_for: for i := 2; i < len(os.args); i += 1 {
			switch os.args[i] {
			case "--help", "-h":
				print_run_usage()
				os.exit(0)
			case "--release", "-r":
				app_state.config.release = true
			case "--silent", "-s":
				app_state.config.silent = true
			case "--":
				if len(os.args) > 3 {
					app_state.config.run_args = os.args[i + 1:len(os.args)]
				}
				break outer_for
			case:
				if strings.starts_with(os.args[i], "-") {
					print_run_unexpected_arg(os.args[i], false)
					os.exit(1)
				}
				if strings.starts_with(os.args[i], "--") {
					print_run_unexpected_arg(os.args[i], true)
					os.exit(1)
				}
				app_state.config.run_args = os.args[i:len(os.args)]
			}
		}
	}
}
