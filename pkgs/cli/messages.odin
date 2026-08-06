package cli

import "core:fmt"
import "core:os"
import "core:strings"
import an "core:terminal/ansi"

print_run_unexpected_arg :: proc(arg: string, arg_tip: bool) {
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		"Unexpected argument ",
		color_ansi(an.RESET),
		arg,
		"\n",
		sep = "",
	)
	if arg_tip {
		fmt.eprintln(
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			" note: ",
			color_ansi(an.RESET),
			"to pass '",
			color_ansi(an.FG_YELLOW),
			arg,
			color_ansi(an.RESET),
			"' as an argument to your binary, use '",
			color_ansi(an.FG_BRIGHT_BLUE),
			"-- ",
			arg,
			color_ansi(an.RESET),
			"'\n",
			sep = "",
		)
	}
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Usage: ",
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		"run ",
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		"[OPTIONS]",
		color_ansi(an.RESET),
		"\n",
		sep = "",
	)
	fmt.eprintln(
		"For more information, try '",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"--help",
		color_ansi(an.RESET),
		"'.",
		sep = "",
	)
}

print_run_usage :: proc(output := os.stdout) {
	fmt.fprintln(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		color_ansi(an.FG_BRIGHT_BLUE),
		"run ",
		color_ansi(an.RESET),
		color_ansi(an.FG_BLUE),
		"[OPTIONS]",
		color_ansi(an.RESET),
		sep = "",
	)
	fmt.fprintln(
		output,
		"Compiles (if there are changes) and runs the project\n",
	)
	fmt.fprintln(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Options:",
		sep = "",
	)

	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in Run_Options {
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
	for flag in Run_Options {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.fprintf(
			output,
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

print_build_unexpected_arg :: proc(arg: string) {
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		"Unexpected argument ",
		color_ansi(an.RESET),
		arg,
		"\n",
		sep = "",
	)
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Usage: ",
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		"build ",
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		"[OPTIONS]",
		color_ansi(an.RESET),
		"\n",
		sep = "",
	)
	fmt.eprintln(
		"For more information, try '",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"--help",
		color_ansi(an.RESET),
		"'.",
		sep = "",
	)
}

print_build_usage :: proc(output := os.stdout) {
	fmt.fprintln(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		color_ansi(an.FG_BRIGHT_BLUE),
		"build ",
		color_ansi(an.RESET),
		color_ansi(an.FG_BLUE),
		"[OPTIONS]",
		color_ansi(an.RESET),
		sep = "",
	)
	fmt.fprintln(output, "Compiles the project if there are any changes\n")
	fmt.fprintln(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Options:",
		sep = "",
	)
	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in Build_Options {
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
	for flag in Build_Options {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.fprintf(
			output,
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

print_new_arg_err :: proc() {
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		"Expected project name",
		color_ansi(an.RESET),
		"\n",
		sep = "",
	)
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Usage: ",
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		"new ",
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		"<project-name>",
		color_ansi(an.RESET),
		"\n",
		sep = "",
	)
	fmt.eprintln(
		"For more information, try '",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"--help",
		color_ansi(an.RESET),
		"'.",
		sep = "",
	)
}

print_new_name_help :: proc() {
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_YELLOW),
		"Too many arguments ",
		color_ansi(an.RESET),
		"\n",
		sep = "",
	)
	args_arr := os.args[2:len(os.args)]
	args_str, _ := strings.join(args_arr, " ", context.temp_allocator)
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		" note: ",
		color_ansi(an.RESET),
		"did you mean ",
		color_ansi(an.FG_BRIGHT_BLUE),
		"\"",
		args_str,
		"\"",
		color_ansi(an.RESET),
		"?",
		"\n",
		sep = "",
	)
	fmt.eprintln(
		"For more information, try '",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"--help",
		color_ansi(an.RESET),
		"'.",
		sep = "",
	)
}

print_new_usage :: proc(output := os.stdout) {
	fmt.fprintln(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		color_ansi(an.FG_BRIGHT_BLUE),
		"new ",
		color_ansi(an.RESET),
		color_ansi(an.FG_BLUE),
		"<project-name>",
		color_ansi(an.RESET),
		sep = "",
	)
	fmt.fprintln(output, "Creates a new Odin project\n")
	fmt.fprintln(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Options:",
		sep = "",
	)
	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in New_Options {
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
	for flag in New_Options {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.fprintf(
			output,
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

print_add_arg_err :: proc() {
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		"Expected package URL",
		color_ansi(an.RESET),
		"\n",
		sep = "",
	)
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Usage: ",
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		"add ",
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		"<package-url> ",
		color_ansi(an.FG_BLUE),
		"[OPTIONS]",
		color_ansi(an.RESET),
		"\n",
		sep = "",
	)
	fmt.eprintln(
		"For more information, try '",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"--help",
		color_ansi(an.RESET),
		"'.",
		sep = "",
	)
}

print_add_url_err :: proc() {
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		"Incorrect package URL",
		color_ansi(an.RESET),
		"\n",
		sep = "",
	)
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Usage: ",
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		"add ",
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		"<package-url> ",
		color_ansi(an.FG_BLUE),
		"[OPTIONS]",
		color_ansi(an.RESET),
		"\n",
		sep = "",
	)
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		"Expected format: ",
		color_ansi(an.RESET),
		"example.com/owner/repo\n",
		sep = "",
	)
	fmt.eprintln(
		"For more information, try '",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"--help",
		color_ansi(an.RESET),
		"'.",
		sep = "",
	)
}

print_add_name_err :: proc() {
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		"Expected package name",
		color_ansi(an.RESET),
		"\n",
		sep = "",
	)
	fmt.eprintln(
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Usage: ",
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		"add ",
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		"<package-url> ",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FAINT),
		"--name ",
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		"<package-name>",
		color_ansi(an.RESET),
		"\n",
		sep = "",
	)
	fmt.eprintln(
		"For more information, try '",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"--help",
		color_ansi(an.RESET),
		"'.",
		sep = "",
	)
}

print_add_usage :: proc(output := os.stdout) {
	fmt.fprintln(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		color_ansi(an.FG_BRIGHT_BLUE),
		"add ",
		color_ansi(an.RESET),
		color_ansi(an.FG_BLUE),
		"<package-url> ",
		color_ansi(an.FG_BLUE),
		"[OPTIONS]",
		color_ansi(an.RESET),
		sep = "",
	)
	fmt.fprintln(output, "Add a package to your project from URL\n")
	fmt.fprintln(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		"Expected URL format: ",
		color_ansi(an.RESET),
		"example.com/owner/repo\n",
		sep = "",
	)
	fmt.fprintln(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Options:",
		sep = "",
	)
	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in Add_Options {
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
	for flag in Add_Options {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.fprintf(
			output,
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

print_general_usage :: proc(output := os.stdout) {
	fmt.fprintln(output, "Mimir - Odin's toolchain\n")
	fmt.fprint(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Usage: ",
		sep = "",
	)
	fmt.fprintln(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		"mimir ",
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		"[COMMAND]",
		"\n",
		sep = "",
	)
	fmt.fprintln(
		output,
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		"Commands:",
		sep = "",
	)

	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in Main_Commands {
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
	for flag in Main_Commands {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.fprintf(
			output,
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

unknown_command :: proc() {
	fmt.fprintf(
		os.stderr,
		"  %s%sUnknown Command%s: %s\n\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_YELLOW),
		color_ansi(an.RESET),
		os.args[1],
	)
}
