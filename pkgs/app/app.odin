package app

import "pkgs:command"
import "pkgs:reflags"

VERSION :: "0.16.2"

// build_cli constructs the reflags description of Mimir's command line.
// Each command has its handler attached so reflags can dispatch after parsing.
build_cli :: proc() -> reflags.CLI {
	// the 'root' command
	root := reflags.command("mimir", nil)
	root.long_desc = "Odin's little toolchain"

	// 'build' command with 'release' and 'silent' flags
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
	append(
		&build_cmd.notes,
		"Give a package directory or Odin file to build it instead of src/, e.g. mimir build tools/migrate",
	)
	build_pkg_builder := reflags.argument(
		"pkg",
		"Package directory or Odin file to build (defaults to src/)",
	)
	reflags.arg_optional(&build_pkg_builder)
	append(&build_cmd.arguments, reflags.arg_build(build_pkg_builder))
	build_cmd.handler = command.handle_build

	// 'run' command with 'release' and 'silent' flags, note, and 'args' passing into the app
	run_cmd := reflags.command("run", "Build if needed, then run the project")
	run_cmd.alias = "r"
	append(
		&run_cmd.notes,
		"If the first argument names a package directory or Odin file with a main procedure, it is built and run instead",
	)
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
	run_pkg_builder := reflags.argument(
		"pkg",
		"Package directory or Odin file to build and run instead of src/",
	)
	reflags.arg_optional(&run_pkg_builder)
	append(&run_cmd.arguments, reflags.arg_build(run_pkg_builder))
	run_args_builder := reflags.argument(
		"args",
		"Arguments passed through to the project",
	)
	reflags.arg_optional(&run_args_builder)
	reflags.arg_variadic(&run_args_builder)
	append(&run_cmd.arguments, reflags.arg_build(run_args_builder))
	run_cmd.handler = command.handle_run

	// 'new' command with 'name' argument and 'not-git' flag
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
	append(
		&new_cmd.options,
		reflags.opt_flag("lib", "l", "Scaffold a library instead of a binary"),
	)
	new_cmd.handler = command.handle_new

	// 'install' command with note and 'repo' argument
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
	install_cmd.handler = command.handle_install

	// 'uninstall' command with 'pkg' argument and 'dry-run' flag
	uninstall_cmd := reflags.command(
		"uninstall",
		"Remove an installed binary from your system",
	)
	uninstall_pkg_builder := reflags.argument("pkg", "Package to uninstall")
	append(&uninstall_cmd.arguments, reflags.arg_build(uninstall_pkg_builder))
	append(
		&uninstall_cmd.options,
		reflags.opt_flag(
			"dry-run",
			"d",
			"See what would happen without changing anything",
		),
	)
	uninstall_cmd.handler = command.handle_uninstall

	// 'list' command
	list_cmd := reflags.command("list", "List the apps installed by Mimir")
	list_cmd.handler = command.handle_list

	// 'clean' command with 'dry-run' flag
	clean_cmd := reflags.command("clean", "Nuke bin/ and all build artifacts")
	append(
		&clean_cmd.options,
		reflags.opt_flag(
			"dry-run",
			"d",
			"See what would happen without changing anything",
		),
	)
	clean_cmd.handler = command.handle_clean

	// 'version' and 'help' commands
	version_cmd := reflags.command("version", "Print mimir version")
	help_cmd := reflags.command("help", "Print this help")

	// Add all commands to the 'root' commands
	cmds := []reflags.Command {
		build_cmd,
		run_cmd,
		new_cmd,
		install_cmd,
		uninstall_cmd,
		list_cmd,
		clean_cmd,
		version_cmd,
		help_cmd,
	}
	for cmd in cmds {
		append(&root.subcommands, cmd)
	}

	// The CLI outlives this procedure, so the root command must live on the
	// heap; make_cli stores a pointer to it.
	root_cmd := new(reflags.Command)
	root_cmd^ = root

	return reflags.make_cli("mimir", VERSION, root_cmd)
}
