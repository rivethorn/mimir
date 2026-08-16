package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:sys/posix"
import "core:sys/windows"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:state"

handle_run :: proc(app_state: ^state.State) {
	rebuild := handle_build(app_state)

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

	project_name := filepath.base(project_dir)
	bin_path, _ := filepath.join(
		{
			project_dir,
			"bin",
			app_state.config.release ? "release" : "debug",
			project_name,
			exe_extension,
		},
		context.temp_allocator,
	)

	command := make([dynamic]string)
	append(&command, bin_path)
	append(&command, ..app_state.config.run_args)

	run_command := os.Process_Desc {
		command     = command[:],
		working_dir = project_dir,
		stdout      = os.stdout,
		stderr      = os.stderr,
		stdin       = os.stdin,
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

	when ODIN_OS == .Windows {
		windows.SetConsoleCtrlHandler(nil, true)
	} else {
		posix.signal(.SIGINT, nil)
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

	free_all(context.temp_allocator)

	state, _ := os.process_wait(run_process)

	os.exit(state.exit_code)
}
