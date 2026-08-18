package cli

import "core:fmt"
import "core:os"
import "core:strings"
import an "core:terminal/ansi"

print_run_unexpected_arg :: proc(arg: string, arg_tip: bool) {
	fmt.fprintfln(
		os.stderr,
		"%s%sUnexpected argument%s %s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		color_ansi(an.RESET),
		arg,
	)
	if arg_tip {
		fmt.fprintfln(
			os.stderr,
			" %s%snote%s: to pass '%s%s%s' as an argument to your binary, use '%s-- %s%s'\n",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			color_ansi(an.RESET),
			color_ansi(an.FG_YELLOW),
			arg,
			color_ansi(an.RESET),
			color_ansi(an.FG_BRIGHT_BLUE),
			arg,
			color_ansi(an.RESET),
		)
	}
	fmt.fprintfln(
		os.stderr,
		"%s%sUsage:%s mimir run%s %s[OPTIONS]%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_run_usage :: proc(output := os.stdout) {
	fmt.fprintfln(
		output,
		"%s%smimir %srun%s %s[OPTIONS]%s",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FG_BRIGHT_BLUE),
		color_ansi(an.RESET),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintln(
		output,
		"Compiles (if there are changes) and runs the project\n",
	)
	fmt.fprintfln(
		output,
		"%s%sOptions:",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
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

		fmt.fprintfln(
			output,
			"    %s%s%s%s%s%s",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}

	free_all(context.temp_allocator)
}

print_build_unexpected_arg :: proc(arg: string) {
	fmt.fprintfln(
		os.stderr,
		"%s%sUnexpected argument%s %s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		color_ansi(an.RESET),
		arg,
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sUsage: %smimir build%s %s[OPTIONS]%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_build_usage :: proc(output := os.stdout) {
	fmt.fprintfln(
		output,
		"%s%smimir %sbuild%s %s[OPTIONS]%s",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FG_BRIGHT_BLUE),
		color_ansi(an.RESET),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintln(output, "Compiles the project if there are any changes\n")
	fmt.fprintfln(
		output,
		"%s%sOptions:",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
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

		fmt.fprintfln(
			output,
			"    %s%s%s%s%s%s",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}

	free_all(context.temp_allocator)
}

print_new_arg_err :: proc() {
	fmt.fprintfln(
		os.stderr,
		"%s%sExpected project name%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sUsage: %smimir new%s %s<project-name>%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_new_name_help :: proc() {
	fmt.fprintfln(
		os.stderr,
		"%s%sToo many arguments%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_YELLOW),
		color_ansi(an.RESET),
	)
	args_arr := os.args[2:len(os.args)]
	args_str, _ := strings.join(args_arr, " ", context.temp_allocator)
	fmt.fprintfln(
		os.stderr,
		"%s%s note:%s did you mean \"%s%s\"%s?\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_BRIGHT_BLUE),
		args_str,
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_new_usage :: proc(output := os.stdout) {
	fmt.fprintfln(
		output,
		"%s%smimir %snew%s %s<project-name>%s",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FG_BRIGHT_BLUE),
		color_ansi(an.RESET),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintln(output, "Creates a new Odin project\n")
	fmt.fprintfln(
		output,
		"%s%sOptions:",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
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

		fmt.fprintfln(
			output,
			"    %s%s%s%s%s%s",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}

	free_all(context.temp_allocator)
}

print_add_arg_err :: proc() {
	fmt.fprintfln(
		os.stderr,
		"%s%sExpected package URL%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sUsage: %smimir add%s %s<package-url> %s[OPTIONS]%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_add_url_err :: proc() {
	fmt.fprintfln(
		os.stderr,
		"%s%sIncorrect package URL%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sUsage: %smimir add%s %s<package-url> %s[OPTIONS]%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sExpected format:%s example.com/owner/repo\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_add_name_err :: proc() {
	fmt.fprintfln(
		os.stderr,
		"%s%sExpected package name%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sUsage: %smimir add%s %s<package-url> %s%s%s--name%s %s<package-name>%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FAINT),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_add_usage :: proc(output := os.stdout) {
	fmt.fprintfln(
		output,
		"%s%smimir %sadd%s %s<package-url> %s[OPTIONS]%s",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FG_BRIGHT_BLUE),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintln(output, "Adds a package to your project from URL\n")
	fmt.fprintfln(
		output,
		"%s%sExpected URL format:%s example.com/owner/repo\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		output,
		"%s%sOptions:",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
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

		fmt.fprintfln(
			output,
			"    %s%s%s%s%s%s",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}

	free_all(context.temp_allocator)
}

print_remove_arg_err :: proc() {
	fmt.fprintfln(
		os.stderr,
		"%s%sExpected package name%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sUsage: %smimir remove%s %s<package-name>%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_remove_usage :: proc(output := os.stdout) {
	fmt.fprintfln(
		output,
		"%s%smimir %sremove%s %s<package-name> %s[OPTIONS]%s",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FG_BRIGHT_BLUE),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintln(
		output,
		"Removes a package from your project with the given package name\n",
	)
	fmt.fprintfln(
		output,
		"%s%sOptions:",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
	)
	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in Remove_Options {
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
	for flag in Remove_Options {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.fprintfln(
			output,
			"    %s%s%s%s%s%s",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}

	free_all(context.temp_allocator)
}

print_update_arg_err :: proc() {
	fmt.fprintfln(
		os.stderr,
		"%s%sExpected package name%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sUsage: %smimir update%s %s<package-name>%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_update_usage :: proc(output := os.stdout) {
	fmt.fprintfln(
		output,
		"%s%smimir %supdate%s %s<package-name> %s[OPTIONS]%s",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FG_BRIGHT_BLUE),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintln(output, "Updates a package using the upstream URL\n")
	fmt.fprintfln(
		output,
		"%s%sOptions:",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
	)
	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in Update_Options {
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
	for flag in Update_Options {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.fprintfln(
			output,
			"    %s%s%s%s%s%s",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}

	free_all(context.temp_allocator)
}

print_clean_unexpected_arg :: proc(arg: string) {
	fmt.fprintfln(
		os.stderr,
		"%s%sUnexpected argument%s %s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		color_ansi(an.RESET),
		arg,
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sUsage: %smimir clean%s %s[OPTIONS]%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_clean_usage :: proc(output := os.stdout) {
	fmt.fprintfln(
		output,
		"%s%smimir %sclean%s %s[OPTIONS]%s",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FG_BRIGHT_BLUE),
		color_ansi(an.RESET),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintln(output, "Removes all built binaries and build artifacts\n")
	fmt.fprintfln(
		output,
		"%s%sOptions:",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
	)
	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in Clean_Options {
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
	for flag in Clean_Options {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.fprintfln(
			output,
			"    %s%s%s%s%s%s",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}

	free_all(context.temp_allocator)
}

print_list_usage :: proc(output := os.stdout) {
	fmt.fprintfln(
		output,
		"%s%smimir %slist%s %s[OPTIONS]%s",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FG_BRIGHT_BLUE),
		color_ansi(an.RESET),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintln(
		output,
		"Lists all packages added by Mimir to the current project\n",
	)
	fmt.fprintfln(
		output,
		"%s%sOptions:",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
	)
	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in List_Options {
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
	for flag in List_Options {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.fprintfln(
			output,
			"    %s%s%s%s%s%s",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}

	free_all(context.temp_allocator)
}

print_install_url_err :: proc() {
	fmt.fprintfln(
		os.stderr,
		"%s%sIncorrect package URL%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sUsage: %smimir install%s %s<package-url> %s[OPTIONS]%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sExpected format:%s example.com/owner/repo\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_install_usage :: proc(output := os.stdout) {
	fmt.fprintfln(
		output,
		"%s%smimir %sinstall%s %s<package-url> %s[OPTIONS]%s",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FG_BRIGHT_BLUE),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintln(output, "Installs an Odin binary\n")
	fmt.fprintfln(
		output,
		"%s%snote:%s to install a local project, simply run '%smimir install%s' with no arguments\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		output,
		"%s%sExpected URL format:%s example.com/owner/repo\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		output,
		"%s%sOptions:",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
	)
	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in Install_Options {
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
	for flag in Install_Options {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.fprintfln(
			output,
			"    %s%s%s%s%s%s",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}

	free_all(context.temp_allocator)
}

print_uninstall_arg_err :: proc() {
	fmt.fprintfln(
		os.stderr,
		"%s%sExpected package name%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_RED),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"%s%sUsage: %smimir uninstall%s %s<package-name>%s\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.RESET),
	)
	fmt.fprintfln(
		os.stderr,
		"For more information, try '%s%s--help%s'.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
		color_ansi(an.RESET),
	)
}

print_uninstall_usage :: proc(output := os.stdout) {
	fmt.fprintfln(
		output,
		"%s%smimir %suninstall%s %s<package-name> %s[OPTIONS]%s",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.FG_BRIGHT_BLUE),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
		color_ansi(an.FG_BLUE),
		color_ansi(an.RESET),
	)
	fmt.fprintln(output, "Uninstalls an Odin binary from your system\n")
	fmt.fprintfln(
		output,
		"%s%sOptions:",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
	)
	// First pass: find the widest command name (including the short
	// flag suffix) so the descriptions all line up in the output.
	max_width := 0
	for flag in Uninstall_Options {
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
	for flag in Uninstall_Options {
		name := flag.name
		if flag.short != "" {
			name = fmt.tprintf("%s, %s", flag.name, flag.short)
		}

		padding := strings.repeat(" ", max_width - len(name) + 2)

		fmt.fprintfln(
			output,
			"    %s%s%s%s%s%s",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}

	free_all(context.temp_allocator)
}

print_general_usage :: proc(output := os.stdout) {
	fmt.fprintln(output, "Mimir - Odin's toolchain\n")
	fmt.fprintf(
		output,
		"%s%sUsage: ",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
	)
	fmt.fprintfln(
		output,
		"%s%smimir%s %s[COMMAND]\n",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_CYAN),
		color_ansi(an.RESET),
		color_ansi(an.FG_CYAN),
	)
	fmt.fprintfln(
		output,
		"%s%sCommands:",
		color_ansi(an.BOLD),
		color_ansi(an.FG_BRIGHT_GREEN),
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

		fmt.fprintfln(
			output,
			"    %s%s%s%s%s%s",
			color_ansi(an.BOLD),
			color_ansi(an.FG_BRIGHT_CYAN),
			name,
			color_ansi(an.RESET),
			padding,
			flag.desc,
		)
	}

	free_all(context.temp_allocator)
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

print_no_proj :: proc() {
	fmt.fprintfln(
		os.stderr,
		"%s%sError%s: Current directory does not contain a valid Odin project for Mimir to work with.",
		color_ansi(an.BOLD),
		color_ansi(an.FG_RED),
		color_ansi(an.RESET),
	)
}
