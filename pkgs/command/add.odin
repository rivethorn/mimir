package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:state"
import "pkgs:util"

@(private = "file")
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

handle_add :: proc(app_state: ^state.State) {
	tmp := get_tmp_dir()
	os.remove_all(tmp)
	defer os.remove_all(tmp)

	os.make_directory(tmp)

	pkg_name := app_state.config.name

	util.clone_repo(app_state.config.url, pkg_name, tmp)

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

	free_all(context.temp_allocator)
}
