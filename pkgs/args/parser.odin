/*
package args - Mimir's command-line interface.

Defines Mimir's commands and options with reflags, parses `os.args` into a
`state.State`, and returns the invoked command as a `state.Command` enum
for type-safe dispatch in main.

Parsing uses reflags' Odin style (like core:flags): options are introduced
with a single dash (`-release`, `-r`), value options take an attached value
(`-name:foo` or `-name=foo`), and underscores in flag names are treated as
dashes (`-no_git` matches `no-git`). A `--` ends option parsing; everything
after it is positional (used by `run` to pass arguments to the project).

Help requests (`-h`/`-help`/`--help`), version requests, usage errors, and
the "not an Odin project" guard are all handled here (printing and exiting),
so main.odin only switches on the returned command and calls handlers.
*/

package args

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "pkgs:reflags"
import "pkgs:state"
import "pkgs:util"

VERSION :: "0.12.5"

// build_cli constructs the reflags description of Mimir's command line.
build_cli :: proc() -> reflags.CLI {
	root := reflags.command("mimir", nil)
	root.long_desc = "Odin's little toolchain"

	build_cmd := reflags.command(
		"build",
		"Compile the current project into bin/",
	)
	build_cmd.alias = "b"
	append(
		&build_cmd.options,
		reflags.opt_flag(
			"release",
			"r",
			"Compile the project in release mode",
		),
	)
	append(
		&build_cmd.options,
		reflags.opt_flag("silent", "s", "Silent the terminal output"),
	)

	run_cmd := reflags.command("run", "Build if needed, then run the project")
	run_cmd.alias = "r"
	append(
		&run_cmd.notes,
		"Use '--' to pass arguments through to your project, e.g. mimir run -- arg1",
	)
	append(
		&run_cmd.options,
		reflags.opt_flag(
			"release",
			"r",
			"Compile and run the project in release mode",
		),
	)
	append(
		&run_cmd.options,
		reflags.opt_flag("silent", "s", "Silent the terminal output"),
	)
	run_args_builder := reflags.argument(
		"args",
		"Arguments passed through to the project",
	)
	reflags.arg_optional(&run_args_builder)
	reflags.arg_variadic(&run_args_builder)
	append(&run_cmd.arguments, reflags.arg_build(run_args_builder))

	new_cmd := reflags.command("new", "Scaffold a fresh Odin project")
	append(
		&new_cmd.notes,
		"Project names with spaces are converted to kebab-case",
	)
	new_name_builder := reflags.argument("name", "Name of the new project")
	reflags.arg_note(
		&new_name_builder,
		"Avoid path separators and reserved characters (\\/:*?\"<>|)",
	)
	append(&new_cmd.arguments, reflags.arg_build(new_name_builder))
	append(
		&new_cmd.options,
		reflags.opt_flag("no-git", "", "Do not initialize a git repository"),
	)

	install_cmd := reflags.command(
		"install",
		"Build a binary - the current project or a remote one - and install it on your system",
	)
	append(
		&install_cmd.notes,
		"Pass '.' to install the current project; otherwise give a site/owner/repo URL",
	)
	install_repo_builder := reflags.argument(
		"repo",
		"Repository to install from (e.g. site/owner/repo)",
	)
	append(&install_cmd.arguments, reflags.arg_build(install_repo_builder))

	uninstall_cmd := reflags.command(
		"uninstall",
		"Remove an installed binary from your system",
	)
	append(
		&uninstall_cmd.arguments,
		reflags.arg_string("pkg", "Package to uninstall"),
	)
	append(
		&uninstall_cmd.options,
		reflags.opt_flag(
			"dry-run",
			"d",
			"See what would happen without changing anything",
		),
	)

	clean_cmd := reflags.command("clean", "Nuke bin/ and all build artifacts")
	append(
		&clean_cmd.options,
		reflags.opt_flag(
			"dry-run",
			"d",
			"See what would happen without changing anything",
		),
	)

	version_cmd := reflags.command(
		"version",
		"Tell you what version you're running",
	)
	help_cmd := reflags.command("help", "Show help message")

	subs := []reflags.Command {
		build_cmd,
		run_cmd,
		new_cmd,
		install_cmd,
		uninstall_cmd,
		clean_cmd,
		version_cmd,
		help_cmd,
	}
	for sub in subs {
		append(&root.subcommands, sub)
	}

	// The CLI outlives this procedure, so the root command must live on the
	// heap; make_cli stores a pointer to it.
	root_cmd := new(reflags.Command)
	root_cmd^ = root

	return reflags.make_cli("mimir", VERSION, root_cmd)
}

// parse parses os.args into app_state and returns the invoked command.
// Exits the process on usage errors, help/version requests, and when a
// project command is used outside of an Odin project.
parse :: proc(app_state: ^state.State) -> state.Command {
	app_cli := build_cli()
	app_cli.style = .Odin

	parsed, parse_err := reflags.parse(&app_cli, os.args[1:])
	defer reflags.destroy(parsed)
	if parse_err != nil {
		reflags.print_error(&app_cli, parse_err)
		os.exit(
			parse_err.reason == .Help_Requested || parse_err.reason == .Version_Requested ? 0 : 1,
		)
	}

	if parsed.command.name == "mimir" {
		// No subcommand given.
		reflags.print_help(&app_cli, os.stdout)
		os.exit(1)
	}

	cmd := command_from_name(parsed.command.name)

	if cmd == .Help {
		reflags.print_help(&app_cli, os.stdout)
		os.exit(0)
	}

	if is_project_command(cmd) && !util.is_odin_project() {
		cmd_name := parsed.command.name
		reflags.command_error(
			fmt.tprintf("mimir %s", cmd_name),
			"Current directory does not contain a valid Odin project for Mimir to work with.",
		)
		reflags.error_hint(cmd_name)
		os.exit(1)
	}

	fill_config(app_state, parsed, cmd, &app_cli)

	return cmd
}

// command_from_name maps a matched reflags command name to its enum value.
command_from_name :: proc(name: string) -> state.Command {
	switch name {
	case "build":
		return .Build
	case "run":
		return .Run
	case "new":
		return .New
	case "install":
		return .Install
	case "uninstall":
		return .Uninstall
	case "clean":
		return .Clean
	case "version":
		return .Version
	case "help":
		return .Help
	}
	return .Error
}

// is_project_command reports whether a command operates on an Odin project
// and therefore requires one to be present.
is_project_command :: proc(cmd: state.Command) -> bool {
	#partial switch cmd {
	case .Build, .Run, .Clean:
		return true
	}
	return false
}

// fill_config maps the parsed values of `cmd` onto app_state.config.
fill_config :: proc(
	app_state: ^state.State,
	parsed: reflags.Parsed_Args,
	cmd: state.Command,
	app_cli: ^reflags.CLI,
) {
	#partial switch cmd {
	case .Build:
		app_state.config.release = reflags.get_bool(parsed, "release")
		app_state.config.silent = reflags.get_bool(parsed, "silent")
	case .Run:
		app_state.config.release = reflags.get_bool(parsed, "release")
		app_state.config.silent = reflags.get_bool(parsed, "silent")
		app_state.config.run_args = reflags.get_strings(parsed, "args")
	case .New:
		app_state.config.name = reflags.get_string(parsed, "name")
		app_state.config.no_git = reflags.get_bool(parsed, "no-git")
	case .Uninstall:
		app_state.config.name = reflags.get_string(parsed, "pkg")
		app_state.config.dry_run = reflags.get_bool(parsed, "dry-run")
	case .Install:
		app_state.config.url = reflags.get_string(parsed, "repo")
		if app_state.config.url != "" {
			app_state.config.name = pkg_name_from_url(app_state.config.url)
			validate_url(app_cli, app_state.config.url)
		}
	case .Clean:
		app_state.config.dry_run = reflags.get_bool(parsed, "dry-run")
	case:
	}
}

// pkg_name_from_url derives a package name from a repo URL like
// "github.com/owner/repo" -> "repo".
pkg_name_from_url :: proc(url: string) -> string {
	return filepath.base(url)
}

// validate_url enforces the old "site/owner/repo" URL rules: it must contain
// a '/', must not end in ".git", and must not contain '@'.
validate_url :: proc(app_cli: ^reflags.CLI, url: string) {
	arr, _ := strings.split(url, "/", context.temp_allocator)
	if url == "." {
		return
	}
	if !strings.contains_rune(url, '/') ||
	   arr[len(arr) - 1] == ".git" ||
	   strings.contains_rune(url, '@') {
		err := reflags.make_error(
			.Invalid_Value,
			fmt.tprintf(
				"Invalid repository URL: %s (expected site/owner/repo)",
				url,
			),
		)
		reflags.print_error(app_cli, err)
		os.exit(1)
	}
}
