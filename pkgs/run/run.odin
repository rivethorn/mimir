package run

import "core:fmt"
import "core:os"
import "core:strings"
import "core:terminal/ansi"
import "pkgs:build"
import "pkgs:cli"
import "pkgs:state"

handle_run :: proc(app_state: ^state.State) {
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
		"%s/bin/%s%s",
		project_dir,
		project_name,
		exe_extension,
	)

	source_path := fmt.tprintf("%s/src/", project_dir)

	if build.needs_rebuild(source_path, bin_path) {
		if !app_state.config.silent {
			fmt.println(
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_YELLOW),
				"Changes detected. ",
				cli.color_ansi(ansi.RESET),
				cli.color_ansi(ansi.FG_CYAN),
				"Rebuilding project...",
				cli.color_ansi(ansi.RESET),
				sep = "",
			)
		}

		build.handle_build(app_state)
	} else if app_state.config.force_recompile {
		if !app_state.config.silent {
			fmt.println(
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_BLUE),
				"  Rebuilding project...",
				cli.color_ansi(ansi.RESET),
				sep = "",
			)
		}

		build.handle_build(app_state)
	} else {
		fmt.println(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_GREEN),
			"     No need ",
			cli.color_ansi(ansi.FG_YELLOW),
			"Already at latest change",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
	}


	run_command := os.Process_Desc {
		command     = []string{bin_path},
		working_dir = project_dir,
		stdout      = os.stdout,
		stderr      = os.stderr,
	}

	if !app_state.config.silent {
		fmt.println(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_GREEN),
			"     Running ",
			cli.color_ansi(ansi.RESET),
			"`",
			project_name,
			"`",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_GREEN),
			"...",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
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
		os.exit(1)
	}

	state, _ := os.process_wait(run_process)
	os.exit(state.exit_code)
}

