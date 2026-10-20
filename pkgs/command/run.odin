package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:sys/posix"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:reflags"

handle_run :: proc(args: reflags.Parsed_Args) -> ^reflags.Error {
	release := reflags.get_bool(args, "release")
	silent := reflags.get_bool(args, "silent")
	pkg := reflags.get_string(args, "pkg")
	run_args := reflags.get_strings(args, "args")

	project_dir, err := os.get_working_directory(context.allocator)
	if err != nil {
		return reflags.command_fail(
			"mimir run",
			"Failed to determine project directory",
		)
	}
	defer delete_string(project_dir)

	target, target_fail := resolve_build_target(
		pkg,
		project_dir,
		"mimir run",
		"run",
		true,
	)
	if target_fail != nil {
		return target_fail
	}
	// resolve_build_target allocates its paths on the heap so the target
	// can outlive temp resets; free it once this handler is done. Default
	// targets hold literals/sub-slices, so only owned copies are freed.
	defer {
		if !target.is_default {
			delete_string(target.src_path)
			delete_string(target.exe_base)
		}
	}
	if pkg != "" && target.is_default {
		// Not a package directory: the argument belongs to the program.
		extra := make([dynamic]string, 0, len(run_args) + 1, context.allocator)
		append(&extra, pkg)
		append(&extra, ..run_args)
		delete(run_args)
		run_args = extra[:]
	}
	defer delete(run_args)
	defer free_all(context.temp_allocator)

	rebuild, build_fail := handle_build_cwd(args, project_dir)
	if build_fail != nil {
		return build_fail
	}

	exe_extension := ""
	when ODIN_OS == .Windows {
		exe_extension = ".exe"
	}

	exe_name := fmt.tprintf("%s%s", target.exe_base, exe_extension)

	bin_path, _ := filepath.join(
		{project_dir, "bin", release ? "release" : "debug", exe_name},
		context.temp_allocator,
	)

	command := make([dynamic]string)
	defer delete(command)
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
				target.exe_base,
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
				target.exe_base,
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
		setup_console_ctrl_handler()
	} else {
		posix.signal(.SIGINT, nil)
	}

	run_process, exec_err := os.process_start(run_command)
	if exec_err != nil {
		return reflags.command_fail(
			"mimir run",
			fmt.tprintf("Failed to run project: %v", exec_err),
		)
	}

	proc_state, _ := os.process_wait(run_process)

	// The child's exit code becomes mimir's exit code.
	if proc_state.exit_code != 0 {
		return reflags.command_fail(
			"mimir run",
			fmt.tprintf("Project exited with code: %d", proc_state.exit_code),
			proc_state.exit_code,
		)
	}

	return nil
}
