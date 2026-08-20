#+feature dynamic-literals
package command

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:terminal/ansi"
import "core:time"
import "pkgs:cli"
import "pkgs:state"
import "pkgs:util"

@(private = "file")
Build_Error :: enum {
	None,
	Command_Not_Found,
	No_Working_Dir,
	Compilation_Failure,
	Spawn_Failure,
}

@(private = "file")
get_collections :: proc(cwd: string) -> [dynamic]string {
	config: Ols

	config_file, err := os.read_entire_file("ols.json", context.temp_allocator)
	if err != nil {
		fmt.eprintf(
			"%sFailed%s to read ols.json file: %v\n",
			cli.color_ansi(ansi.FG_RED),
			cli.color_ansi(ansi.RESET),
			err,
		)
		os.exit(1)
	}

	json_err := json.unmarshal(config_file, &config)
	if json_err != nil {
		fmt.eprintf(
			"%sFailed%s to parse ols.json: %v\n",
			cli.color_ansi(ansi.FG_RED),
			cli.color_ansi(ansi.RESET),
			err,
		)
		os.exit(1)
	}

	collections := make([dynamic]string)

	for col in config.collections {
		current := fmt.tprintf("-collection:%s=%s", col.name, col.path)
		append(&collections, current)
	}

	return collections
}

@(private = "file")
start_build :: proc(
	config: ^state.Command_Config,
	cwd: string,
) -> Build_Error {
	if !util.command_exists("odin") {
		return .Command_Not_Found
	}

	output := fmt.tprintf("-out:%s", config.output)
	release_mode := config.release ? "-o:speed" : "-o:none"
	debug_flag := config.release ? "" : "-debug"

	bin_dir, _ := filepath.join(
		{cwd, "bin", config.release ? "release" : "debug"},
		context.temp_allocator,
	)
	if err := os.make_directory(bin_dir); err != nil {
		if !os.exists(bin_dir) {
			fmt.eprintf(
				"%sFailed%s to create directory %q: %v\n",
				cli.color_ansi(ansi.FG_RED),
				cli.color_ansi(ansi.RESET),
				bin_dir,
				err,
			)
			os.exit(1)
		}
	}

	exe_extension := ""
	when ODIN_OS == .Windows {
		exe_extension = ".exe"
	}

	project_name := filepath.base(cwd)

	exe_name := fmt.tprintf("%s%s", project_name, exe_extension)

	bin_path, _ := filepath.join(
		{cwd, "bin", config.release ? "release" : "debug", exe_name},
		context.temp_allocator,
	)

	collections := get_collections(cwd)
	defer util.delete_dynamic_strings(collections)

	first_time := !os.exists(bin_path)

	if !config.silent {
		if config.release {
			if !first_time {
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
			if !first_time {
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

	command := [dynamic]string {
		"odin",
		"build",
		config.src_path,
		output,
		release_mode,
		debug_flag,
	}
	defer delete(command)

	append(&command, ..collections[:])

	build_command := os.Process_Desc {
		command     = command[:],
		working_dir = cwd,
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
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
	}

	return .None
}

@(private = "file")
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

handle_build :: proc(
	app_state: ^state.State,
	cwd: string = "",
) -> (
	rebuild: bool,
) {
	project_dir, err := os.get_working_directory(context.allocator)
	if err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_RED),
			"Failed to determine project name",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	if cwd != "" {
		project_dir = cwd
	}

	source_dir, _ := filepath.join(
		{project_dir, "src"},
		context.temp_allocator,
	)

	project_name := filepath.base(project_dir)

	exe_extension := ""
	when ODIN_OS == .Windows {
		exe_extension = ".exe"
	}

	exe_name := fmt.tprintf("%s%s", project_name, exe_extension)

	output: string
	if app_state.config.release {
		output, _ = filepath.join(
			{"bin", "release", exe_name},
			context.allocator,
		)
	} else {
		output, _ = filepath.join(
			{"bin", "debug", exe_name},
			context.allocator,
		)
	}

	if !app_state.config.silent && !needs_rebuild(source_dir, output) {
		fmt.println(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_GREEN),
			"  No rebuild ",
			cli.color_ansi(ansi.RESET),
			cli.color_ansi(ansi.FG_BRIGHT_CYAN),
			"Already at latest change",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		return false
	}

	bin_dir, _ := filepath.join({project_dir, "bin"}, context.temp_allocator)
	if err := os.make_directory(bin_dir); err != nil {
		if !os.exists(bin_dir) {
			fmt.eprintf(
				"%sFailed%s to create directory %q: %v\n",
				cli.color_ansi(ansi.FG_RED),
				cli.color_ansi(ansi.RESET),
				bin_dir,
				err,
			)
			os.exit(1)
		}
	}

	app_state.config.name = project_name
	app_state.config.src_path = "src"
	app_state.config.output = output

	build_err := start_build(&app_state.config, project_dir)
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

	free_all(context.temp_allocator)
	return true
}
