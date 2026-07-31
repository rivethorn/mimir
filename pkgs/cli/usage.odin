package cli

import "core:fmt"
import an "core:terminal/ansi"

print_usage :: proc() {
	fmt.println("Mimir - Odin's toolchain\n")
	fmt.print(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Usage: ",
		sep = "",
	)
	fmt.println(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		"[COMMAND]",
		"\n",
		sep = "",
	)
	fmt.println(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Commands:",
		sep = "",
	)
	fmt.println(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		"    new\t\t",
		color_ansi(an.RESET),
		"Create a new Odin project.",
		sep = "",
	)
	fmt.println(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		"    version\t",
		color_ansi(an.RESET),
		"Show Mimir's version.",
		sep = "",
	)
}

