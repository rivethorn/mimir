package util

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:sync"
import "core:terminal/ansi"
import "core:thread"
import "pkgs:cli"
import "pkgs:state"

delete_strings :: proc(ss: []string) {
	for s in ss {
		delete(s)
	}
}

delete_dynamic_strings :: proc(ss: [dynamic]string) {
	delete_strings(ss[:])
	delete(ss)
}

command_exists :: proc(command_name: string) -> bool {
	path_env, found := os.lookup_env("PATH", context.temp_allocator)
	if !found {return false}

	delimiter := ":"
	exe_extension := ""

	when ODIN_OS == .Windows {
		delimiter = ";"
		exe_extension = ".exe"
	}

	target_file := command_name
	if exe_extension != "" &&
	   !strings.has_suffix(command_name, exe_extension) {
		target_file = fmt.tprintf("%s%s", command_name, exe_extension)
	}

	path_list := strings.split(path_env, delimiter, context.temp_allocator)

	for dir in path_list {
		if dir == "" {continue}

		full_path, err := filepath.join(
			[]string{dir, target_file},
			context.temp_allocator,
		)

		if os.exists(full_path) {
			return true
		}
	}

	return false
}

is_odin_project :: proc() -> bool {
	defer free_all(context.temp_allocator)
	project_dir, err := os.get_working_directory(context.temp_allocator)
	if err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_RED),
			"Failed to determine project directory",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	source_dir, _ := filepath.join(
		{project_dir, "src"},
		context.temp_allocator,
	)

	if !os.exists(source_dir) {
		return false
	}

	walker := os.walker_create(source_dir)
	for info in os.walker_walk(&walker) {
		if strings.has_suffix(info.fullpath, ".odin") {
			return true
		}
	}

	os.walker_destroy(&walker)

	ols_path, _ := filepath.join(
		{project_dir, "ols.json"},
		context.temp_allocator,
	)

	if !os.exists(ols_path) {
		return false
	}

	return true
}

is_general_command :: proc(command: state.Command) -> bool {
	switch command {
	case .New, .Version, .Help, .Error:
		return true
	case .Build, .Run, .Clean, .Add, .Remove, .Update, .List:
		return false
	case:
		return false
	}
}

clone_repo :: proc(url, pkg_name, tmp_dir: string) {
	full_url := fmt.tprintf("https://%s.git", url)
	command := []string{"git", "clone", full_url, pkg_name}

	null_path := "NUL" when ODIN_OS == .Windows else "/dev/null"

	null_fd, err := os.open(null_path, os.O_WRONLY)
	if err != nil {
		fmt.printfln("Failed to open null device: %v", err)
		return
	}
	defer os.close(null_fd)

	spin_state := cli.Spinner_State {
		message    = fmt.tprintf(
			"%sCloning %s...%s",
			cli.color_ansi(ansi.FG_BRIGHT_CYAN),
			pkg_name,
			cli.color_ansi(ansi.RESET),
		),
		is_running = true,
	}

	clone_command := os.Process_Desc {
		command     = command,
		working_dir = tmp_dir,
		stderr      = null_fd,
		stdout      = null_fd,
	}

	spinner_thread := thread.create(cli.spinner_proc)
	spinner_thread.data = &spin_state
	thread.start(spinner_thread)

	clone_process, exec_err := os.process_start(clone_command)
	if exec_err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			"Clone Failed\n",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	state, _ := os.process_wait(clone_process)

	sync.mutex_lock(&spin_state.mtx)
	spin_state.is_running = false
	sync.mutex_unlock(&spin_state.mtx)
	thread.join(spinner_thread)
	thread.destroy(spinner_thread)

	if state.exit_code != 0 {
		fmt.printfln(
			"\r%s%sFailed to clone %s%s",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			pkg_name,
			cli.color_ansi(ansi.RESET),
		)
		os.exit(state.exit_code)
	}

	fmt.printf(
		"\r%sCloning %s... %s%sDone!%s",
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		pkg_name,
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		cli.color_ansi(ansi.RESET),
	)
}
