package remove

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:state"

handle_remove :: proc(app_state: ^state.State) {
	pkg_name := app_state.config.pkg_name
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
			"%s%sWould%s remove '%s%s%s' directory",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_CYAN),
			cli.color_ansi(ansi.RESET),
			cli.color_ansi(ansi.FG_BRIGHT_YELLOW),
			pkg_path,
			cli.color_ansi(ansi.RESET),
		)

		os.exit(0)
	}

	os.remove_all(pkg_path)

	fmt.printfln(
		"%s%sSuccessfully%s removed '%s%s%s' from project",
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		cli.color_ansi(ansi.RESET),
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		pkg_name,
		cli.color_ansi(ansi.RESET),
	)
}
