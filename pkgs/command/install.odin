package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:state"
import "pkgs:util"

handle_install :: proc(app_state: ^state.State) {
	if len(os.args) < 3 && !util.is_odin_project() {
		cli.print_no_proj()
		cli.print_install_usage(os.stderr)
		os.exit(1)
	}

	app_state.config.release = true

	bin_dir := util.get_mimir_bin_dir_path()

	name: string

	if len(os.args) < 3  /* local project */{
		project_dir, err := os.get_working_directory(context.allocator)
		if err != nil {
			fmt.eprintln(
				cli.color_ansi(ansi.FG_RED),
				"Failed to determine project name",
				cli.color_ansi(ansi.RESET),
				sep = "",
			)
			os.exit(1)
		}

		project_name := filepath.base(project_dir)
		pkg_path, _ := filepath.join({bin_dir, project_name})

		if os.exists(pkg_path) {
			fmt.eprintfln(
				"%s%sError:%s Package '%s%s%s' is already installed on your system",
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_RED),
				cli.color_ansi(ansi.RESET),
				cli.color_ansi(ansi.FG_BRIGHT_YELLOW),
				project_name,
				cli.color_ansi(ansi.RESET),
			)
			os.exit(1)
		}

		exe_extension := ""
		when ODIN_OS == .Windows {
			exe_extension = ".exe"
		}

		output_bin, _ := filepath.join(
			{project_dir, "bin", "release", project_name, exe_extension},
		)

		handle_build(app_state)

		if err := os.copy_directory_all(bin_dir, output_bin); err != nil {
			fmt.eprintln(
				cli.color_ansi(ansi.FG_RED),
				"\nFailed to move binary",
				cli.color_ansi(ansi.RESET),
				sep = "",
			)
			os.exit(1)
		}

		name = project_name
	} else  /* remote project */{
		tmp := util.get_tmp_dir()
		os.remove_all(tmp)
		defer os.remove_all(tmp)

		os.make_directory(tmp)

		pkg_name := app_state.config.name

		util.clone_repo(app_state.config.url, pkg_name, tmp)

		project_dir, _ := filepath.join({tmp, pkg_name})
		pkg_path, _ := filepath.join({bin_dir, pkg_name})

		if os.exists(pkg_path) {
			fmt.eprintfln(
				"%s%sError:%s Package '%s%s%s' is already installed on your system",
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_RED),
				cli.color_ansi(ansi.RESET),
				cli.color_ansi(ansi.FG_BRIGHT_YELLOW),
				pkg_name,
				cli.color_ansi(ansi.RESET),
			)
			os.exit(1)
		}

		project_name := filepath.base(project_dir)
		exe_extension := ""
		when ODIN_OS == .Windows {
			exe_extension = ".exe"
		}
		output_bin, _ := filepath.join(
			{project_dir, "bin", "release", project_name, exe_extension},
		)

		handle_build(app_state, project_dir)

		if err := os.copy_directory_all(bin_dir, output_bin); err != nil {
			fmt.eprintln(
				cli.color_ansi(ansi.FG_RED),
				"\nFailed to move binary",
				cli.color_ansi(ansi.RESET),
				sep = "",
			)
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
