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

// parse parses os.args, validates, runs the "not an Odin project" guard, and
// invokes the matched command's handler. Exits the process on usage errors,
// help/version requests, or project-command guard failures.
parse_and_run :: proc() {
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

	if parsed.command.name == "version" {
		fmt.println("Mimir version", VERSION)
		os.exit(0)
	}

	if parsed.command.name == "help" {
		reflags.print_help(&app_cli, os.stdout)
		os.exit(0)
	}

	if is_project_command(parsed.command.name) && !util.is_odin_project() {
		cmd_name := parsed.command.name
		reflags.command_error(
			fmt.tprintf("mimir %s", cmd_name),
			"Current directory does not contain a valid Odin project for Mimir to work with.",
		)
		reflags.error_hint(cmd_name)
		os.exit(1)
	}

	if parsed.command.name == "install" {
		repo := reflags.get_string(parsed, "repo")
		if repo != "" {
			validate_url(&app_cli, repo)
		}
	}

	// Execute the command handler if present
	if parsed.command.handler != nil {
		handler_err := parsed.command.handler(parsed)
		if handler_err != nil {
			reflags.print_error(&app_cli, &handler_err.(reflags.Re_Error))
			os.exit(1)
		}
	}
}
