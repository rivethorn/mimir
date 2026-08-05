package run

import "core:fmt"
import "core:os"
import "core:strings"
import "core:terminal/ansi"
import "pkgs:build"
import "pkgs:cli"
import "pkgs:state"

handle_run :: proc(app_state: ^state.State) {
	rebuild := build.handle_build(app_state)

	project_dir, err := os.get_working_directory(context.temp_allocator)
	if err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			"Failed to determine project directory",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	exe_extension := ""
	when ODIN_OS == .Windows {
		exe_extension = ".exe"
	}

	tmp := strings.split(project_dir, "/")
	when ODIN_OS == .Windows {
		tmp = strings.split(project_dir, "\\")
	}
	project_name := tmp[len(tmp) - 1]
	bin_path := fmt.tprintf(
		"%s/bin/%s/%s%s",
		project_dir,
		app_state.config.release ? "release" : "debug",
		project_name,
		exe_extension,
	)

	command := make([dynamic]string)
	append(&command, bin_path)
	append(&command, ..app_state.config.run_args)

	run_command := os.Process_Desc {
		command     = command[:],
		working_dir = project_dir,
		stdout      = os.stdout,
		stderr      = os.stderr,
	}

	if !app_state.config.silent {
		if app_state.config.release {
			fmt.println(
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_GREEN),
				"     Running ",
				cli.color_ansi(ansi.RESET),
				"`",
				project_name,
				"`",
				cli.color_ansi(ansi.FAINT),
				rebuild ? "" : " in release mode",
				cli.color_ansi(ansi.RESET),
				"...",
				sep = "",
			)
		} else {
			fmt.println(
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_GREEN),
				"     Running ",
				cli.color_ansi(ansi.RESET),
				"`",
				project_name,
				"`",
				cli.color_ansi(ansi.FAINT),
				rebuild ? "" : " in debug mode",
				cli.color_ansi(ansi.RESET),
				"...",
				sep = "",
			)
		}
	}

	run_process, exec_err := os.process_start(run_command)
	if exec_err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			"Failed to run project ",
			cli.color_ansi(ansi.RESET),
			exec_err,
			sep = "",
		)
		delete(command)
		os.exit(1)
	}

	state, _ := os.process_wait(run_process)
	delete(command)
	os.exit(state.exit_code)
}
