package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:reflags"
import "pkgs:util"

@(private = "file")
pkg_name_from_url :: proc(url: string) -> string {
	return filepath.base(url)
}

handle_install :: proc(args: reflags.Parsed_Args) -> ^reflags.Error {
	repo := reflags.get_string(args, "repo")

	if repo == "" {
		return reflags.command_fail(
			"mimir install",
			"Missing REPO argument — provide a URL, or use '.' to install the current project.",
		)
	}

	// The Mimir bin directory must outlive temp resets, so it is heap
	// memory this handler owns and frees everywhere below.
	bin_dir := util.get_mimir_bin_dir_path()
	defer delete_string(bin_dir)

	name: string
	defer {
		if name != "" {
			delete_string(name)
		}
	}

	if repo == "." /* local project */ {
		project_dir, err := os.get_working_directory(context.allocator)
		if err != nil {
			return reflags.command_fail(
				"mimir install",
				"Failed to determine project directory",
			)
		}
		defer delete_string(project_dir)

		exe_extension := ""
		when ODIN_OS == .Windows {
			exe_extension = ".exe"
		}

		project_name := filepath.base(project_dir)
		pkg_path, _ := filepath.join({bin_dir, project_name}, context.allocator)
		defer delete_string(pkg_path)

		if os.exists(pkg_path) {
			return reflags.command_fail(
				"mimir install",
				fmt.tprintf(
					"Package '%s' is already installed on your system",
					project_name,
				),
			)
		}

		exe_name := fmt.tprintf("%s%s", project_name, exe_extension)

		output_bin, _ := filepath.join(
			{project_dir, "bin", "release", exe_name},
			context.allocator,
		)
		defer delete_string(output_bin)

		if _, build_fail := handle_build_cwd(args, project_dir); build_fail != nil {
			return build_fail
		}

		// Install = place the built release binary in Mimir's bin dir.
		if copy_err := os.copy_file(pkg_path, output_bin); copy_err != nil {
			return reflags.command_fail(
				"mimir install",
				fmt.tprintf("Failed to install binary: %v", copy_err),
			)
		}

		// Keep a private copy for the message: file paths freed above are
		// slices of other allocations.
		name = strings.clone(project_name, context.allocator)
	} else /* remote project */ {
		tmp := util.get_tmp_dir()
		defer delete_string(tmp)

		os.remove_all(tmp)
		defer os.remove_all(tmp)

		os.make_directory(tmp)

		pkg_name := pkg_name_from_url(repo)

		project_dir, _ := filepath.join({tmp, pkg_name}, context.allocator)
		defer delete_string(project_dir)

		pkg_path, _ := filepath.join({bin_dir, pkg_name}, context.allocator)
		defer delete_string(pkg_path)

		if os.exists(pkg_path) {
			return reflags.command_fail(
				"mimir install",
				fmt.tprintf(
					"Package '%s' is already installed on your system",
					pkg_name,
				),
			)
		}

		fail := util.clone_repo(repo, pkg_name, tmp)
		if fail != nil {
			return fail
		}

		project_name := filepath.base(project_dir)

		exe_extension := ""
		when ODIN_OS == .Windows {
			exe_extension = ".exe"
		}

		exe_name := fmt.tprintf("%s%s", project_name, exe_extension)

		output_bin, _ := filepath.join(
			{project_dir, "bin", "release", exe_name},
			context.allocator,
		)
		defer delete_string(output_bin)

		if _, build_fail := handle_build_cwd(args, project_dir); build_fail != nil {
			return build_fail
		}

		// Install = place the built release binary in Mimir's bin dir.
		if copy_err := os.copy_file(pkg_path, output_bin); copy_err != nil {
			return reflags.command_fail(
				"mimir install",
				fmt.tprintf("Failed to install binary: %v", copy_err),
			)
		}

		name = strings.clone(project_name, context.allocator)
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

	return nil
}
