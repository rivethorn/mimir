package util

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:sync"
import "core:terminal/ansi"
import "core:thread"
import "pkgs:cli"
import "pkgs:reflags"

command_exists :: proc(command_name: string) -> bool {
	// NOTE: no free_all here on purpose. Callers may hold temp memory
	// across this call; each command frees temp when it is done.
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

		full_path, _ := filepath.join(
			[]string{dir, target_file},
			context.temp_allocator,
		)

		if os.exists(full_path) {
			return true
		}
	}

	return false
}

/*
get_mimir_path returns the path of Mimir's home directory (~/.mimir).
The result is a fresh heap allocation: free it with delete_string when
the caller is done with it.
*/
get_mimir_path :: proc() -> string {
	home_env: string
	when ODIN_OS == .Windows {
		home_env = "LOCALAPPDATA"
	} else {
		home_env = "HOME"
	}
	home := os.get_env(home_env, context.temp_allocator)

	path, err := filepath.join({home, ".mimir"}, context.allocator)
	if err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_RED),
			"Failed to determine Mimir directory",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	return path
}

/*
get_mimir_bin_dir_path returns the directory where Mimir installs binaries
(creating it first). The result is a fresh heap allocation: free it with
delete_string when the caller is done with it. Do not hold it across
temp-allocator resets.
*/
get_mimir_bin_dir_path :: proc() -> string {
	base := get_mimir_path()
	defer delete_string(base)

	path, err := filepath.join({base, "bin"}, context.allocator)
	if err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_RED),
			"Failed to determine Mimir directory",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}
	os.make_directory_all(path)

	return path
}

/*
get_tmp_dir returns Mimir's directory for temporary work (repository
clones during install). The result is a fresh heap allocation: free it
with delete_string when the caller is done with it.
*/
get_tmp_dir :: #force_inline proc() -> string {
	if sys_tmp, tmp_err := os.temp_dir(context.temp_allocator);
	   tmp_err == nil {
		path, _ := filepath.join({sys_tmp, "mimir"}, context.allocator)
		return path
	}

	// No system temp dir available: fall back inside Mimir's own directory.
	base := get_mimir_path()
	defer delete_string(base)

	tmp_path, _ := filepath.join({base, "tmp"}, context.allocator)
	defer delete_string(tmp_path)

	if err := os.make_directory_all(tmp_path); err == nil {
		return strings.clone(tmp_path, context.allocator)
	}

	return strings.clone(base, context.allocator)
}

is_odin_project :: proc() -> bool {
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

	return is_odin_project_in(project_dir)
}

// is_odin_project_in reports whether dir holds a Mimir project: a src/
// with Odin files plus an ols.json.
is_odin_project_in :: proc(dir: string) -> bool {
	source_dir, _ := filepath.join({dir, "src"}, context.temp_allocator)

	if !os.exists(source_dir) {
		return false
	}

	// The walker keeps internal buffers, so make sure it is destroyed
	// however this procedure exits; breaking out of walker_walk early
	// would otherwise leak them.
	walker := os.walker_create(source_dir)
	defer os.walker_destroy(&walker)

	for info in os.walker_walk(&walker) {
		if strings.has_suffix(info.fullpath, ".odin") {
			return true
		}
	}

	ols_path, _ := filepath.join({dir, "ols.json"}, context.temp_allocator)

	if !os.exists(ols_path) {
		return false
	}

	return true
}

/*
stop_cli_spinner stops the install spinner: flags it done under lock,
then joins and destroys its thread.
*/
@(private = "file")
stop_cli_spinner :: proc(state: ^cli.Spinner_State, t: ^thread.Thread) {
	sync.mutex_lock(&state.mtx)
	state.is_running = false
	sync.mutex_unlock(&state.mtx)
	thread.join(t)
	thread.destroy(t)
}

/*
clone_repo clones `url` (site/owner/repo) into tmp_dir/pkg_name, showing a
spinner while git runs. Prints its own errors and returns a reflags.Error
(nil on success) so callers can fail cleanly with the exit code git used.
*/
clone_repo :: proc(url, pkg_name, tmp_dir: string) -> ^reflags.Error {
	full_url := fmt.tprintf("https://%s.git", url)
	command := []string{"git", "clone", full_url, pkg_name}

	null_path := "NUL" when ODIN_OS == .Windows else "/dev/null"

	null_fd, err := os.open(null_path, os.O_WRONLY)
	if err != nil {
		return reflags.command_fail(
			"mimir install",
			fmt.tprintf("Failed to open null device: %v", err),
		)
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
	// Wherever clone_repo returns from below, the spinner must stop and be
	// joined first, or mimir dies with still-running threads.

	clone_process, exec_err := os.process_start(clone_command)
	if exec_err != nil {
		stop_cli_spinner(&spin_state, spinner_thread)
		fmt.printf("\r\x1b[2K")
		return reflags.command_fail(
			"mimir install",
			fmt.tprintf("Failed to start `git clone`: %v", exec_err),
		)
	}

	state, _ := os.process_wait(clone_process)

	stop_cli_spinner(&spin_state, spinner_thread)
	fmt.printf("\r\x1b[2K")

	if state.exit_code != 0 {
		return reflags.command_fail(
			"mimir install",
			fmt.tprintf("Failed to clone %s", pkg_name),
			state.exit_code,
		)
	}

	fmt.printfln(
		"\r%sCloning %s... %s%sDone!%s",
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		pkg_name,
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		cli.color_ansi(ansi.RESET),
	)

	return nil
}
