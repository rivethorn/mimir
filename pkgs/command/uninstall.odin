package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:state"
import "pkgs:util"

handle_uninstall :: proc(app_state: ^state.State) {
	pkg_name := app_state.config.name
	bin_dir := util.get_mimir_bin_dir_path()
	pkg_path, _ := filepath.join({bin_dir, pkg_name}, context.temp_allocator)

	if !os.exists(pkg_path) {
		fmt.eprintfln(
			"%s%sError:%s Package '%s%s%s' is not installed on your system",
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
		fmt.printfln(
			"%s%sWould%s remove '%s%s%s'",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_CYAN),
			cli.color_ansi(ansi.RESET),
			cli.color_ansi(ansi.FG_BRIGHT_YELLOW),
			pkg_path,
			cli.color_ansi(ansi.RESET),
		)
		os.exit(0)
	}

	os.remove(pkg_path)

	fmt.printfln(
		"%s%sSuccessfully%s uninstalled '%s%s%s' from your system",
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		cli.color_ansi(ansi.RESET),
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		pkg_name,
		cli.color_ansi(ansi.RESET),
	)

	free_all(context.temp_allocator)
}
