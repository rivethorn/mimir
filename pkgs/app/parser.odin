/*
package args - Mimir's command-line interface.

Defines Mimir's commands and options with reflags, parses `os.args`, and
invokes the matched command's handler. Handlers read parsed values directly
from `reflags.Parsed_Args` using the `get_*` accessors.

Parsing uses reflags' Odin style (like core:flags): options are introduced
with a single dash (`-release`, `-r`), value options take an attached value
(`-name:foo` or `-name=foo`), and underscores in flag names are treated as
dashes (`-no_git` matches `no-git`). A `--` ends option parsing; everything
after it is positional (used by `run` to pass arguments to the project).

Help requests (`-h`/`-help`/`--help`), version requests, usage errors, and
the "not an Odin project" guard are all handled here (printing and exiting).
*/

package app

import "core:fmt"
import "core:os"
import "pkgs:reflags"
import "pkgs:util"

// parse_and_run parses os.args, validates, runs the "not an Odin project"
// guard, and invokes the matched command's handler. Returns the process
// exit code: 0 on success (including help/version requests), 1 on usage
// errors, guard failures, or handler errors.
parse_and_run :: proc() -> (code: int) {
	app_cli := build_cli()
	app_cli.style = .Odin
	defer reflags.destroy_cli(&app_cli)

	parsed, parse_err := reflags.parse(&app_cli, os.args[1:])
	defer reflags.destroy(parsed)
	defer free(parse_err)
	if parse_err != nil {
		reflags.print_error(&app_cli, parse_err)
		return parse_err.reason == .Help_Requested ||
		parse_err.reason == .Version_Requested ? 0 : 1
	}

	if parsed.command.name == "mimir" {
		// No subcommand given.
		reflags.print_help(&app_cli, os.stdout)
		return 1
	}

	if parsed.command.name == "version" {
		fmt.println("Mimir version", VERSION)
		return 0
	}

	if parsed.command.name == "help" {
		reflags.print_help(&app_cli, os.stdout)
		return 0
	}

	cmd_name := parsed.command.name
	if is_project_command(cmd_name) && !util.is_odin_project() {
		// An explicit build target stands on its own: the handler resolves
		// it (or errors) without needing a project around it.
		explicit_target :=
			(cmd_name == "build" || cmd_name == "run") &&
			reflags.get_string(parsed, "pkg") != ""
		if !explicit_target {
			reflags.command_error(
				fmt.tprintf("mimir %s", cmd_name),
				"Current directory does not contain a valid Odin project for Mimir to work with.",
			)
			reflags.error_hint(cmd_name)
			return 1
		}
	}

	if parsed.command.name == "install" {
		repo := reflags.get_string(parsed, "repo")
		if repo != "" && !validate_url(&app_cli, repo) {
			return 1
		}
	}

	// Execute the command handler if present
	if parsed.command.handler != nil {
		handler_err := parsed.command.handler(parsed)
		if handler_err != nil {
			// Handlers print their own errors on the spot; the returned
			// Error only decides the process exit code (Re_Error with
			// reason .None carries a success-style exit code, e.g. the
			// exit code of a program mimir ran).
			e := handler_err.(reflags.Re_Error)
			free(handler_err)
			return e.reason == .None ? e.exit_code :
				e.exit_code != 0 ? e.exit_code : 1
		}
	}

	return 0
}
