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
	for opt in Main_Commands {
		if os.args[1] == opt.name || os.args[1] == opt.short {
			app_state.command = opt.command
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
	case .New:
		if len(os.args) < 3 {
			print_new_arg_err()
			os.exit(1)
		}

		for i := 2; i < len(os.args); i += 1 {
			switch os.args[i] {
			case "--help", "-h":
				print_new_usage()
				os.exit(0)
			}
		}

		if len(os.args) > 3 {
			print_new_name_help()
			os.exit(1)
		}
	case .Add:
		if len(os.args) < 3 {
			print_add_arg_err()
			os.exit(1)
		}

		for i := 2; i < len(os.args); i += 1 {
			switch os.args[i] {
			case "--help", "-h":
				print_add_usage()
				os.exit(0)
			case "--name":
				if len(os.args) == i + 2 {
					app_state.config.name = os.args[i + 1]
				} else {
					print_add_name_err()
					os.exit(1)
				}
			case:
				if os.args[i - 1] == "--name" {
					return
				}
				arr, _ := strings.split(
					os.args[i],
					"/",
					context.temp_allocator,
				)
				if !strings.contains_rune(os.args[i], '/') ||
				   arr[len(arr) - 1] == ".git" ||
				   strings.contains_rune(os.args[i], '@') {
					print_add_url_err()
					os.exit(1)
				}
				app_state.config.name = arr[len(arr) - 1]
				app_state.config.url = os.args[i]
			}
		}
	case .Remove:
		if len(os.args) < 3 {
			print_remove_arg_err()
			os.exit(1)
		}

		for i := 2; i < len(os.args); i += 1 {
			switch os.args[i] {
			case "--help", "-h":
				print_remove_usage()
				os.exit(0)
			case "--dry-run", "-d":
				app_state.config.dry_run = true
			case:
				app_state.config.name = os.args[i]
			}
		}
	case .Update:
		if len(os.args) < 3 {
			print_update_arg_err()
			os.exit(1)
		}

		for i := 2; i < len(os.args); i += 1 {
			switch os.args[i] {
			case "--help", "-h":
				print_update_usage()
				os.exit(0)
			case "--dry-run", "-d":
				app_state.config.dry_run = true
			case:
				app_state.config.name = os.args[i]
			}
		}
	case .List:
		for i := 2; i < len(os.args); i += 1 {
			switch os.args[i] {
			case "--help", "-h":
				print_list_usage()
				os.exit(0)
			case:
				print_list_usage(os.stderr)
				os.exit(1)
			}
		}
	case .Clean:
		for i := 2; i < len(os.args); i += 1 {
			switch os.args[i] {
			case "--help", "-h":
				print_clean_usage()
				os.exit(0)
			case "--dry-run", "-d":
				app_state.config.dry_run = true
			case:
				print_clean_unexpected_arg(os.args[i])
				os.exit(1)
			}
		}
	}
}
