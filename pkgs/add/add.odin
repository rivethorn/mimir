package add

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:sync"
import "core:terminal/ansi"
import "core:thread"
import "pkgs:cli"
import "pkgs:state"

@(private)
get_tmp_dir :: #force_inline proc() -> string {
	tmp, tmp_err := os.temp_dir(context.allocator)
	if tmp_err != nil {
		cwd, _ := os.get_working_directory(context.allocator)
		tmp_path, _ := filepath.join({cwd, "pkgs", "tmp"}, context.allocator)
		if err := os.make_directory_all(tmp_path); err == nil {
			tmp = tmp_path
		}
	} else {
		tmp = fmt.tprintf("%s%s", tmp, "mimir")
	}

	return tmp
}

@(private)
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
			"%sCloning the package...%s",
			cli.color_ansi(ansi.FG_BRIGHT_CYAN),
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
			"\r%s%sFailed to clone the package%s",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			cli.color_ansi(ansi.RESET),
		)
		os.exit(state.exit_code)
	}

	fmt.printf(
		"\r%sCloning the package... %s%sDone!%s",
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		cli.color_ansi(ansi.RESET),
	)
}

handle_add :: proc(app_state: ^state.State) {
	tmp := get_tmp_dir()
	os.remove_all(tmp)
	defer os.remove_all(tmp)

	os.make_directory(tmp)

	pkg_name := app_state.config.name

	clone_repo(app_state.config.url, pkg_name, tmp)

	tmp_path, _ := filepath.join({tmp, pkg_name}, context.temp_allocator)
	cwd, err := os.get_working_directory(context.temp_allocator)
	if err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_RED),
			"\nFailed to determine project path",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}
	pkg_path, _ := filepath.join({cwd, "pkgs"}, context.temp_allocator)

	cpy_err := os.copy_directory_all(pkg_path, tmp_path)
	if cpy_err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_RED),
			"\nFailed to move package ",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	fmt.println(
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		"\nSuccessfully ",
		cli.color_ansi(ansi.RESET),
		"added '",
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		pkg_name,
		cli.color_ansi(ansi.RESET),
		"' to the project",
		sep = "",
	)
}
