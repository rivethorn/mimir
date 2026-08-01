package build

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:terminal/ansi"
import "core:time"
import "pkgs:cli"
import "pkgs:util"

@(private)
Build_Error :: enum {
	None,
	Command_Not_Found,
	No_Working_Dir,
	Compilation_Failure,
	Spawn_Failure,
}

needs_rebuild :: proc(source_path, binary_path: string) -> bool {
	bin_info, bin_err := os.stat(binary_path, context.temp_allocator)
	if bin_err != nil {
		return true
	}

	src_info, src_err := os.stat(source_path, context.temp_allocator)
	if src_err != nil {
		fmt.eprintf("Source path error: %v\n", src_err)
		return true
	}

	if !(src_info.type == .Directory) {
		return(
			src_info.modification_time._nsec >
			bin_info.modification_time._nsec \
		)
	}

	latest_src_mod := src_info.modification_time

	fd, dir_err := os.open(source_path)
	if dir_err != nil {
		return true
	}
	defer os.close(fd)

	infos, read_err := os.read_dir(fd, -1, context.temp_allocator)
	if read_err != nil {
		return true
	}

	for info in infos {
		if filepath.ext(info.name) == ".odin" {
			if info.modification_time._nsec > latest_src_mod._nsec {
				latest_src_mod = info.modification_time
			}
		}
	}

	return latest_src_mod._nsec > bin_info.modification_time._nsec
}

@(private)
start_build :: proc(config: ^Build_Config) -> Build_Error {
	if !util.command_exists("odin") {
		return .Command_Not_Found
	}

	output := fmt.tprintf("-out:%s", config.output)
	release_mode := config.release ? "-o:speed" : "-o:none"
	debug_mode := config.release ? "" : "-debug"
	working_dir, err := os.get_working_directory(context.temp_allocator)
	if err != nil {
		return .No_Working_Dir
	}

	if !config.silent {
		if config.release {
			fmt.println(
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_GREEN),
				"   Compiling ",
				cli.color_ansi(ansi.RESET),
				"`",
				config.name,
				"`",
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
				"   Compiling ",
				cli.color_ansi(ansi.RESET),
				"`",
				config.name,
				"`",
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
			debug_mode,
		},
		working_dir = working_dir,
		stderr      = os.stderr,
		stdout      = os.stdout,
	}

	build_process, exec_err := os.process_start(build_command)
	if exec_err != nil {
		return .Spawn_Failure
	}

	state, _ := os.process_wait(build_process)

	if !config.silent && state.exit_code != 0 {
		fmt.eprintln(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			"Compilation Failed\n",
			cli.color_ansi(ansi.RESET),
			"exit code: ",
			state.exit_code,
			"\n",
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
			"    Finished ",
			cli.color_ansi(ansi.RESET),
			"successfully in ",
			cli.color_ansi(ansi.BOLD),
			state.user_time,
			"\n\n",
			cli.color_ansi(ansi.FG_BRIGHT_CYAN),
			"Output: ",
			cli.color_ansi(ansi.RESET),
			config.output,
			sep = "",
		)
	}

	return .None
}

@(private)
check_build_flags :: proc() -> (release: bool, silent: bool) {
	for i := 2; i < len(os.args); i += 1 {
		if os.args[i] == "--release" {
			release = true
		} else if os.args[i] == "--silent" || os.args[i] == "-s" {
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

	return release, silent
}

handle_build :: proc(silent := false) {
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

	source_dir := fmt.tprintf("%s/src/", project_dir)

	if !os.exists(source_dir) {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			"This directory does not contain a src/ directory, where are we?",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	tmp := strings.split(project_dir, "/")
	when ODIN_OS == .Windows {
		tmp = strings.split(project_dir, "\\")
	}
	project_name := tmp[len(tmp) - 1]

	exe_extension := ""
	when ODIN_OS == .Windows {
		exe_extension = ".exe"
	}

	output := fmt.tprintf("%s/%s%s", "bin", project_name, exe_extension)

	if !release && !needs_rebuild(source_dir, output) {
		fmt.println(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_YELLOW),
			"Already at latest change",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		return
	}

	walker := os.walker_create(source_dir)
	files: [dynamic]string

	for info in os.walker_walk(&walker) {
		if strings.has_suffix(info.fullpath, ".odin") {
			append(&files, info.name)
			continue
		}
	}

	delete(files)
	os.walker_destroy(&walker)

	if len(files) == 0 {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			"This directory does not contain a valid Odin project",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	config := Build_Config {
		name    = project_name,
		path    = "src",
		output  = output,
		release = release,
		silent  = silent,
	}

	build_err := start_build(&config)
	if build_err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			"Build Error: ",
			cli.color_ansi(ansi.RESET),
			build_err,
			sep = "",
		)
		os.exit(1)
	}
}

