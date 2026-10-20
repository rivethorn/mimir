package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:reflags"

handle_new :: proc(args: reflags.Parsed_Args) -> ^reflags.Error {
	project_name := reflags.get_string(args, "name")
	no_git := reflags.get_bool(args, "no-git")
	is_lib := reflags.get_bool(args, "lib")

	if strings.contains_any(project_name, `\/:*?"<>|`) ||
	   strings.starts_with(project_name, "-") ||
	   strings.starts_with(project_name, "--") ||
	   project_name == "." ||
	   project_name == ".." {
		return reflags.command_fail(
			"mimir new",
			fmt.tprintf("Invalid project name '%s'", project_name),
		)
	}

	if strings.contains(project_name, " ") {
		name_arr := strings.split(project_name, " ", context.temp_allocator)
		clean_name, cn_err := strings.join(
			name_arr,
			"-",
			context.temp_allocator,
		)
		if cn_err != nil {
			return reflags.command_fail(
				"mimir new",
				"Failed to parse project name",
			)
		}

		project_name = clean_name
	}

	project_dir := project_name

	if os.exists(project_dir) {
		return reflags.command_fail(
			"mimir new",
			fmt.tprintf(
				"A project named '%s' already exists in the current directory",
				project_name,
			),
		)
	}

	if err := os.make_directory(project_dir); err != nil {
		if !os.exists(project_dir) {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf(
					"Failed to create directory '%s': %v",
					project_dir,
					err,
				),
			)
		}
	}

	// Everything below writes files whose paths and templates are only
	// needed for the immediate os call, so they ride on the temp
	// allocator and are never reclaimed one by one.
	pkg_name := sanitize_package_name(project_name)

	if is_lib {
		lib_path := fmt.tprintf("%s/%s.odin", project_dir, project_name)
		lib_content := fmt.tprintf(LIB_FILE_FMT, pkg_name)
		if err := os.write_entire_file(lib_path, transmute([]u8)lib_content);
		   err != nil {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf("Failed to write %s.odin: %v", project_name, err),
			)
		}

		readme_path := fmt.tprintf("%s/README.md", project_dir)
		readme_content := fmt.tprintf(
			"# %s\n\nAn [Odin](https://odin-lang.org) library managed via **Mimir**.\n\n## Quick Start\n\nClone it into your project's `pkgs/` directory and import it by folder name.",
			project_name,
		)
		if err := os.write_entire_file(
			readme_path,
			transmute([]u8)readme_content,
		); err != nil {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf("Failed to write README.md: %v", err),
			)
		}

		ols_path := fmt.tprintf("%s/ols.json", project_dir)
		if err := os.write_entire_file(
			ols_path,
			transmute([]u8)OLS_LIB_CONTENT,
		); err != nil {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf("Failed to write ols.json: %v", err),
			)
		}

		odinfmt_path := fmt.tprintf("%s/odinfmt.json", project_dir)
		if err := os.write_entire_file(
			odinfmt_path,
			transmute([]u8)FMT_FILE_CONTENT,
		); err != nil {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf("Failed to write odinfmt.json: %v", err),
			)
		}

		gitignore_path := fmt.tprintf("%s/.gitignore", project_dir)
		if err := os.write_entire_file(
			gitignore_path,
			transmute([]u8)GITIG_FILE_CONTENT,
		); err != nil {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf("Failed to write .gitignore: %v", err),
			)
		}
	} else {
		pkgs_dir := fmt.tprintf("%s/pkgs", project_dir)
		if err := os.make_directory(pkgs_dir); err != nil {
			if !os.exists(pkgs_dir) {
				return reflags.command_fail(
					"mimir new",
					fmt.tprintf(
						"Failed to create directory '%s': %v",
						pkgs_dir,
						err,
					),
				)
			}
		}

		src_dir := fmt.tprintf("%s/src", project_dir)
		if err := os.make_directory(src_dir); err != nil {
			if !os.exists(src_dir) {
				return reflags.command_fail(
					"mimir new",
					fmt.tprintf(
						"Failed to create directory '%s': %v",
						src_dir,
						err,
					),
				)
			}
		}
		main_path := fmt.tprintf("%s/src/main.odin", project_dir)
		if err := os.write_entire_file(
			main_path,
			transmute([]byte)(MAIN_FILE_CONTENT),
		); err != nil {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf("Failed to write main.odin: %v", err),
			)
		}

		readme_path := fmt.tprintf("%s/README.md", project_dir)
		readme_content := fmt.tprintf(
			"# %s\n\nAn [Odin](https://odin-lang.org) project managed via **Mimir**.\n\n## Quick Start\n\n```bash\nmimir run    # Build and run\nmimir build  # Compile to binary\nmimir clean  # Clear build files and artifacts\n```",
			project_name,
		)
		if err := os.write_entire_file(
			readme_path,
			transmute([]u8)readme_content,
		); err != nil {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf("Failed to write README.md: %v", err),
			)
		}

		ols_path := fmt.tprintf("%s/ols.json", project_dir)
		if err := os.write_entire_file(
			ols_path,
			transmute([]u8)OLS_FILE_CONTENT,
		); err != nil {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf("Failed to write ols.json: %v", err),
			)
		}

		odinfmt_path := fmt.tprintf("%s/odinfmt.json", project_dir)
		if err := os.write_entire_file(
			odinfmt_path,
			transmute([]u8)FMT_FILE_CONTENT,
		); err != nil {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf("Failed to write odinfmt.json: %v", err),
			)
		}

		gitignore_path := fmt.tprintf("%s/.gitignore", project_dir)
		gitignore_content := fmt.tprintf(
			"%s\n%s",
			GITIG_FILE_CONTENT,
			project_name,
		)
		if err := os.write_entire_file(
			gitignore_path,
			transmute([]u8)gitignore_content,
		); err != nil {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf("Failed to write .gitignore: %v", err),
			)
		}
	}

	if !no_git {
		cwd, get_err := os.get_working_directory(context.allocator)
		if get_err != nil {
			return reflags.command_fail(
				"mimir new",
				"Failed to get working directory",
			)
		}
		defer delete_string(cwd)

		proj, _ := filepath.join({cwd, project_dir}, context.allocator)
		defer delete_string(proj)

		git_process, start_err := os.process_start(
			{command = {"git", "init"}, working_dir = proj},
		)
		if start_err != nil {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf("Failed to initialize git repo: %v", start_err),
			)
		}

		// Wait so the process doesn't linger as a zombie after mimir ends.
		git_state, _ := os.process_wait(git_process)
		if git_state.exit_code != 0 {
			return reflags.command_fail(
				"mimir new",
				fmt.tprintf(
					"`git init` failed with exit code: %d",
					git_state.exit_code,
				),
				git_state.exit_code,
			)
		}
	}

	fmt.printfln(
		"%s%sCreating%s %s `%s` package...",
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_CYAN),
		cli.color_ansi(ansi.RESET),
		is_lib ? "library" : "binary",
		project_name,
	)
	fmt.printfln(
		"%s%sSuccessfully%s created `%s` project",
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		cli.color_ansi(ansi.RESET),
		project_name,
	)

	free_all(context.temp_allocator)

	return nil
}

// sanitize_package_name converts a project directory name into a valid Odin
// package name: dashes, dots, and spaces become underscores, anything else
// outside [A-Za-z0-9_] becomes an underscore, and a leading digit gets a
// leading underscore prefix.
sanitize_package_name :: proc(name: string) -> string {
	b := strings.builder_make(context.temp_allocator)
	if len(name) > 0 && name[0] >= '0' && name[0] <= '9' {
		strings.write_byte(&b, '_')
	}
	for c in name {
		switch {
		case c == '-' || c == '.' || c == ' ':
			strings.write_byte(&b, '_')
		case (c >= 'a' && c <= 'z') ||
		     (c >= 'A' && c <= 'Z') ||
		     c == '_' ||
		     (c >= '0' && c <= '9'):
			strings.write_byte(&b, byte(c))
		case:
			strings.write_byte(&b, '_')
		}
	}
	return strings.to_string(b)
}
