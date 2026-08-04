package clean

import "core:fmt"
import "core:os"
import "core:strings"
import "core:terminal/ansi"
import "pkgs:cli"

handle_clean :: proc() {
	project_dir, err := os.get_working_directory(context.temp_allocator)
	if err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_RED),
			"Failed to determine project name",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	bin_dir := fmt.tprintf("%s/bin", project_dir)
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

	os.remove_all(bin_dir)

	fmt.println(
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		"        Done ",
		cli.color_ansi(ansi.RESET),
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		"All built binaries and build artifacts are cleaned",
		cli.color_ansi(ansi.RESET),
		sep = "",
	)
}
