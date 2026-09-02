package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:reflags"
import "pkgs:state"
import "pkgs:util"

handle_install :: proc(app_state: ^state.State) {
	if app_state.config.url == "" {
		reflags.command_error(
			"mimir install",
			"Missing REPO argument — provide a URL, or use '.' to install the current project.",
		)
		reflags.error_hint("install")
		os.exit(1)
	}

	app_state.config.release = true

	bin_dir := util.get_mimir_bin_dir_path()

	name: string

	if app_state.config.url == "."  /* local project */{
		project_dir, err := os.get_working_directory(context.allocator)
		if err != nil {
			reflags.command_error(
				"mimir install",
				"Failed to determine project directory",
			)
			os.exit(1)
		}

		project_name := filepath.base(project_dir)
		pkg_path, _ := filepath.join({bin_dir, project_name})

		if os.exists(pkg_path) {
			reflags.command_error(
				"mimir install",
				fmt.tprintf(
					"Package '%s' is already installed on your system",
					project_name,
				),
			)
			os.exit(1)
		}

		exe_extension := ""
		when ODIN_OS == .Windows {
			exe_extension = ".exe"
		}

		exe_name := fmt.tprintf("%s%s", project_name, exe_extension)

		output_bin, _ := filepath.join(
			{project_dir, "bin", "release", exe_name},
		)

		handle_build(app_state)

		if err := os.copy_directory_all(bin_dir, output_bin); err != nil {
			reflags.command_error("mimir install", "Failed to install binary")
			os.exit(1)
		}

		name = project_name
	} else  /* remote project */{
		tmp := util.get_tmp_dir()
		os.remove_all(tmp)
		defer os.remove_all(tmp)

		os.make_directory(tmp)

		pkg_name := app_state.config.name

		project_dir, _ := filepath.join({tmp, pkg_name})
		pkg_path, _ := filepath.join({bin_dir, pkg_name})

		if os.exists(pkg_path) {
			reflags.command_error(
				"mimir install",
				fmt.tprintf(
					"Package '%s' is already installed on your system",
					pkg_name,
				),
			)
			reflags.error_hint("install")
			os.exit(1)
		}

		util.clone_repo(app_state.config.url, pkg_name, tmp)

		project_name := filepath.base(project_dir)

		exe_extension := ""
		when ODIN_OS == .Windows {
			exe_extension = ".exe"
		}

		exe_name := fmt.tprintf("%s%s", project_name, exe_extension)

		output_bin, _ := filepath.join(
			{project_dir, "bin", "release", exe_name},
		)

		handle_build(app_state, project_dir)

		if err := os.copy_directory_all(bin_dir, output_bin); err != nil {
			reflags.command_error("mimir install", "Failed to install binary")
			os.exit(1)
		}

		name = project_name
	}

	fmt.println(
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		"\nSuccessfully ",
		cli.color_ansi(ansi.RESET),
		"installed '",
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		name,
		cli.color_ansi(ansi.RESET),
		"'",
		sep = "",
	)
}
