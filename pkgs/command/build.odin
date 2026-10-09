#+feature dynamic-literals
package command

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:reflags"
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
Build_Config :: struct {
	name:            string,
	src_path:        string,
	output:          string,
	release, silent: bool,
}


@(private = "file")
get_collections :: proc(cwd: string) -> [dynamic]string {
	config: Ols

	config_file, err := os.read_entire_file("ols.json", context.temp_allocator)
	if err != nil {
		reflags.command_error(
			"mimir build",
			fmt.tprintf("Failed to read ols.json file: %v", err),
		)
		os.exit(1)
	}

	json_err := json.unmarshal(config_file, &config)
	if json_err != nil {
		reflags.command_error(
			"mimir build",
			fmt.tprintf("Failed to parse ols.json: %v", err),
		)
		os.exit(1)
	}

	collections := make([dynamic]string, 0, 8, context.temp_allocator)

	for col in config.collections {
		current := fmt.tprintf("-collection:%s=%s", col.name, col.path)
		append(&collections, current)
	}

	return collections
}

@(private = "file")
start_build :: proc(config: ^Build_Config, cwd: string) -> Build_Error {
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
			reflags.command_error(
				"mimir build",
				fmt.tprintf(
					"Failed to create directory '%s': %v",
					bin_dir,
					err,
				),
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

	proc_state, _ := os.process_wait(build_process)

	if !config.silent && proc_state.exit_code != 0 {
		reflags.command_error(
			"mimir build",
			fmt.tprintf(
				"Compilation failed (exit code: %d)",
				proc_state.exit_code,
			),
		)
		os.exit(proc_state.exit_code)
	}

	if config.silent && proc_state.exit_code != 0 {
		reflags.command_error(
			"mimir build",
			fmt.tprintf(
				"Compilation failed (exit code: %d)",
				proc_state.exit_code,
			),
		)
		os.exit(proc_state.exit_code)
	}

	if !config.silent {
		fmt.println(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_GREEN),
			"    Finished ",
			cli.color_ansi(ansi.RESET),
			"successfully in ",
			cli.color_ansi(ansi.BOLD),
			proc_state.user_time,
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
		reflags.command_error(
			"mimir build",
			fmt.tprintf("Source path error: %v", src_err),
		)
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

handle_build :: proc(args: reflags.Parsed_Args) -> ^reflags.Error {
	release := reflags.get_bool(args, "release")
	silent := reflags.get_bool(args, "silent")
	pkg := reflags.get_string(args, "pkg")

	project_dir, err := os.get_working_directory(context.allocator)
	if err != nil {
		reflags.command_error(
			"mimir build",
			"Failed to determine project directory",
		)
		os.exit(1)
	}

	target := resolve_build_target(pkg, project_dir, "mimir build", "build", false)

	source_abs := target.src_path
	if !filepath.is_abs(source_abs) {
		source_abs, _ = filepath.join(
			{project_dir, target.src_path},
			context.temp_allocator,
		)
	}

	exe_extension := ""
	when ODIN_OS == .Windows {
		exe_extension = ".exe"
	}

	exe_name := fmt.tprintf("%s%s", target.exe_base, exe_extension)

	output: string
	if release {
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
	if !silent && !needs_rebuild(source_abs, output) {
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
		return nil
	}

	bin_dir, _ := filepath.join({project_dir, "bin"}, context.temp_allocator)
	if err := os.make_directory(bin_dir); err != nil {
		if !os.exists(bin_dir) {
			reflags.command_error(
				"mimir build",
				fmt.tprintf(
					"Failed to create directory '%s': %v",
					bin_dir,
					err,
				),
			)
			os.exit(1)
		}
	}

	config := Build_Config {
		name     = target.exe_base,
		src_path = target.src_path,
		output   = output,
		release  = release,
		silent   = silent,
	}
	build_err := start_build(&config, project_dir)
	if build_err != nil {
		reflags.command_error("mimir build", fmt.tprintf("%v", build_err))
		os.exit(1)
	}

	free_all(context.temp_allocator)
	return nil
}

handle_build_cwd :: proc(
	args: reflags.Parsed_Args,
	cwd: string,
) -> (
	rebuild: bool,
) {
	project_dir := cwd

	release :=
		args.command.name == "install" ? true : reflags.get_bool(args, "release")
	silent :=
		args.command.name == "install" ? false : reflags.get_bool(args, "silent")
	pkg := reflags.get_string(args, "pkg")

	cmd_label := fmt.tprintf("mimir %s", args.command.name)
	target := resolve_build_target(
		pkg,
		project_dir,
		cmd_label,
		args.command.name,
		args.command.name == "run",
	)

	source_abs := target.src_path
	if !filepath.is_abs(source_abs) {
		source_abs, _ = filepath.join(
			{project_dir, target.src_path},
			context.temp_allocator,
		)
	}

	exe_extension := ""
	when ODIN_OS == .Windows {
		exe_extension = ".exe"
	}

	exe_name := fmt.tprintf("%s%s", target.exe_base, exe_extension)

	output: string
	if release {
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

	if !needs_rebuild(source_abs, output) {
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
			reflags.command_error(
				"mimir build",
				fmt.tprintf(
					"Failed to create directory '%s': %v",
					bin_dir,
					err,
				),
			)
			os.exit(1)
		}
	}

	config := Build_Config {
		name     = target.exe_base,
		src_path = target.src_path,
		output   = output,
		release  = release,
		silent   = silent,
	}

	build_err := start_build(&config, cwd)
	if build_err != nil {
		reflags.command_error("mimir build", fmt.tprintf("%v", build_err))
		os.exit(1)
	}

	free_all(context.temp_allocator)
	return true
}
