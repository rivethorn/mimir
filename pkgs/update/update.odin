package update

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:terminal/ansi"
import "core:thread"
import "pkgs:cli"
import "pkgs:state"

@(private)
update_repo :: proc(pkg_name, pkg_dir: string) {
	command := []string{"git", "pull"}

	null_path := "NUL" when ODIN_OS == .Windows else "/dev/null"

	null_fd, err := os.open(null_path, os.O_WRONLY)
	if err != nil {
		fmt.printfln("Failed to open null device: %v", err)
		return
	}
	defer os.close(null_fd)

	spin_state := cli.Spinner_State {
		message    = fmt.tprintf(
			"%sUpdating the package...%s",
			cli.color_ansi(ansi.FG_BRIGHT_CYAN),
			cli.color_ansi(ansi.RESET),
		),
		is_running = true,
	}

	clone_command := os.Process_Desc {
		command     = command,
		working_dir = pkg_dir,
		stderr      = null_fd,
		stdout      = null_fd,
	}

	spinner_thread := thread.create(cli.spinner_proc)
	spinner_thread.data = &spin_state
	thread.start(spinner_thread)

	update_process, exec_err := os.process_start(clone_command)
	if exec_err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			"Update Failed\n",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	state, _ := os.process_wait(update_process)

	spin_state.is_running = false
	thread.join(spinner_thread)
	thread.destroy(spinner_thread)

	if state.exit_code != 0 {
		fmt.printfln(
			"\r%s%sFailed to update the package%s",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			cli.color_ansi(ansi.RESET),
		)
		os.exit(state.exit_code)
	}

	fmt.printf(
		"\r%sUpdating the package... %s%sDone!%s",
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		cli.color_ansi(ansi.RESET),
	)
}

handle_update :: proc(app_state: ^state.State) {
	pkg_name := app_state.config.name
	cwd, _ := os.get_working_directory(context.temp_allocator)
	pkg_path, _ := filepath.join(
		{cwd, "pkgs", pkg_name},
		context.temp_allocator,
	)

	if !os.exists(pkg_path) {
		fmt.eprintfln(
			"%s%sError:%s Package '%s%s%s' does not exist in this project",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			cli.color_ansi(ansi.RESET),
			cli.color_ansi(ansi.FG_BRIGHT_YELLOW),
			pkg_name,
			cli.color_ansi(ansi.RESET),
		)
		os.exit(1)
	}

	if app_state.config.dry_run {
		if pkg_name == "" {
			fmt.printfln(
				"%s%sNothing to do!%s",
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_CYAN),
				cli.color_ansi(ansi.RESET),
			)

			os.exit(0)
		}

		fmt.printfln(
			"%s%sWould%s run `%sgit pull%s` in '%s%s%s' directory",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_CYAN),
			cli.color_ansi(ansi.RESET),
			cli.color_ansi(ansi.FG_BRIGHT_BLUE),
			cli.color_ansi(ansi.RESET),
			cli.color_ansi(ansi.FG_BRIGHT_YELLOW),
			pkg_path,
			cli.color_ansi(ansi.RESET),
		)

		os.exit(0)
	}

	update_repo(pkg_name, pkg_path)

	fmt.println(
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		"\nSuccessfully ",
		cli.color_ansi(ansi.RESET),
		"updated '",
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		pkg_name,
		cli.color_ansi(ansi.RESET),
		"'",
		sep = "",
	)
}
