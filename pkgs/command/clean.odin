package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:state"

handle_clean :: proc(app_state: ^state.State) {
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

	bin_dir, _ := filepath.join({project_dir, "bin"}, context.temp_allocator)

	if app_state.config.dry_run {
		dbg_path, _ := filepath.join(
			{bin_dir, "debug"},
			context.temp_allocator,
		)
		is_dbg := os.exists(dbg_path)

		rel_path, _ := filepath.join(
			{bin_dir, "release"},
			context.temp_allocator,
		)
		is_rel := os.exists(rel_path)

		if !is_dbg && !is_rel {
			fmt.printfln(
				"%s%sNothing to do!%s",
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_CYAN),
				cli.color_ansi(ansi.RESET),
			)

			os.exit(0)
		}

		if is_dbg {
			fmt.printfln(
				"%s%sWould%s remove '%s%s%s' directory",
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_CYAN),
				cli.color_ansi(ansi.RESET),
				cli.color_ansi(ansi.FG_BRIGHT_YELLOW),
				dbg_path,
				cli.color_ansi(ansi.RESET),
			)
		}

		if is_rel {
			fmt.printfln(
				"%s%sWould%s remove '%s%s%s' directory",
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_CYAN),
				cli.color_ansi(ansi.RESET),
				cli.color_ansi(ansi.FG_BRIGHT_YELLOW),
				rel_path,
				cli.color_ansi(ansi.RESET),
			)
		}

		os.exit(0)
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
