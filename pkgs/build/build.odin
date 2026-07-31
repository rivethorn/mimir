package build

import "core:fmt"
import "core:os"
import "core:strings"
import "core:terminal/ansi"
import "core:time"
import "pkgs:cli"
import "pkgs:util"

Build_Error :: enum {
	None,
	Command_Not_Found,
	No_Working_Dir,
	Compilation_Failure,
}

start_build :: proc(config: ^Build_Config) -> Build_Error {
	if !util.command_exists("odin") {
		return .Command_Not_Found
	}

	output := fmt.tprintf("-out:%s", config.output)
	release_mode := config.release ? "-o:speed" : "-o:none"
	working_dir, err := os.get_working_directory(context.temp_allocator)
	if err != nil {
		return .No_Working_Dir
	}

	if !config.silent {
		if config.release {
			fmt.println(
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_GREEN),
				"Compiling ",
				cli.color_ansi(ansi.RESET),
				config.name,
				cli.color_ansi(ansi.FAINT),
				" in release mode",
				cli.color_ansi(ansi.RESET),
				"...",
				sep = "",
			)
		} else {
			fmt.println(
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_GREEN),
				"Compiling ",
				cli.color_ansi(ansi.RESET),
				config.name,
				cli.color_ansi(ansi.FAINT),
				" in debug mode",
				cli.color_ansi(ansi.RESET),
				"...",
				sep = "",
			)

		}
	}

	build_command := os.Process_Desc {
		command     = []string {
			"odin",
			"build",
			config.path,
			output,
			release_mode,
		},
		working_dir = working_dir,
	}

	state, stdout, stderr, exec_err := os.process_exec(
		build_command,
		context.temp_allocator,
	)
	if exec_err != nil {
		return .Compilation_Failure
	}
	defer delete(stdout)
	defer delete(stderr)

	if !config.silent && state.exit_code != 0 {
		fmt.eprintln(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			"Comlilation Failed\n",
			cli.color_ansi(ansi.RESET),
			"exit code: ",
			state.exit_code,
			"\n",
			string(stderr),
			sep = "",
		)

		os.exit(state.exit_code)
	}

	if config.silent && state.exit_code != 0 {
		fmt.eprintln("exit code", state.exit_code)
		os.exit(state.exit_code)
	}

	if !config.silent {
		fmt.println(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_GREEN),
			"Finished ",
			cli.color_ansi(ansi.RESET),
			"successfully in ",
			cli.color_ansi(ansi.BOLD),
			state.user_time,
			"\n",
			cli.color_ansi(ansi.FG_BRIGHT_CYAN),
			"Output: ",
			cli.color_ansi(ansi.RESET),
			config.output,
			sep = "",
		)
	}

	defer os.exit(state.exit_code)
	return .None
}

check_build_flags :: proc() -> (release: bool, silent: bool) {
	for i := 2; i < len(os.args); i += 1 {
		if os.args[i] == "--release" {
			release = true
		} else if os.args[i] == "--silent" {
			silent = true
		} else if os.args[i] == "help" || os.args[i] == "h" {
			cli.print_build_usage()
			os.exit(0)
		} else {
			fmt.eprintln(
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_RED),
				"Unsupported option ",
				cli.color_ansi(ansi.RESET),
				os.args[i],
				sep = "",
			)
			cli.print_build_usage(os.stderr)
			os.exit(1)
		}
	}

	return
}

handle_build :: proc() {
	release, silent := check_build_flags()

	project_dir, err := os.get_working_directory(context.temp_allocator)
	if err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_RED),
			"Failed to determine project name",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	tmp := strings.split(project_dir, "/")
	project_name := tmp[len(tmp) - 1]

	exe_extension := ""
	when ODIN_OS == .Windows {
		exe_extension = ".exe"
	}

	output := fmt.tprintf("%s/%s%s", "bin", project_name, exe_extension)

	config := Build_Config {
		name    = project_name,
		path    = "src",
		output  = output,
		release = release,
		silent  = silent,
	}

	start_build(&config)
}

