package cli

import "core:fmt"
import "core:strings"
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

	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in Flags {
		width := len(flag.name)
		if flag.short != "" {
			width += len(flag.short) + 2 // ", " + short
		}
		if width > max_width {
			max_width = width
		}
	}

	// Second pass: print each command, padded to max_width plus a
	// small gap before the description.
	for flag in Flags {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.printf(
			"    %s%s%s%s%s%s\n",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}
}
