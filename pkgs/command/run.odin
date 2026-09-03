package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:sys/posix"
import "core:sys/windows"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:reflags"

handle_run :: proc(args: reflags.Parsed_Args) -> ^reflags.Error {
	release := reflags.get_bool(args, "release")
	silent := reflags.get_bool(args, "silent")
	run_args := reflags.get_strings(args, "args")

	project_dir, err := os.get_working_directory(context.allocator)
	if err != nil {
		reflags.command_error(
			"mimir run",
			"Failed to determine project directory",
		)
		os.exit(1)
	}

	rebuild := handle_build_cwd(args, project_dir)

	exe_extension := ""
	when ODIN_OS == .Windows {
		exe_extension = ".exe"
	}

	project_name := filepath.base(project_dir)

	exe_name := fmt.tprintf("%s%s", project_name, exe_extension)

	bin_path, _ := filepath.join(
		{project_dir, "bin", release ? "release" : "debug", exe_name},
		context.temp_allocator,
	)

	command := make([dynamic]string)
	append(&command, bin_path)
	append(&command, ..run_args)

	run_command := os.Process_Desc {
		command     = command[:],
		working_dir = project_dir,
		stdout      = os.stdout,
		stderr      = os.stderr,
		stdin       = os.stdin,
	}

	if !silent {
		if release {
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
		reflags.command_error(
			"mimir run",
			fmt.tprintf("Failed to run project: %v", exec_err),
		)
		os.exit(1)
	}

	free_all(context.temp_allocator)

	proc_state, _ := os.process_wait(run_process)

	os.exit(proc_state.exit_code)
}
