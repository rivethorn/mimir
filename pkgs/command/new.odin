package command

import "core:fmt"
import "core:os"
import "core:strings"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:reflags"
import "pkgs:state"

handle_new :: proc(app_state: ^state.State) {
	project_name := app_state.config.name

	if strings.contains_any(project_name, `\/:*?"<>|`) ||
	   strings.starts_with(project_name, "-") ||
	   strings.starts_with(project_name, "--") ||
	   project_name == "." ||
	   project_name == ".." {
		reflags.command_error(
			"mimir new",
			fmt.tprintf("Invalid project name '%s'", project_name),
		)
		reflags.error_hint("new")
		os.exit(1)
	}

	if strings.contains(project_name, " ") {
		name_arr, err := strings.split(project_name, " ", context.allocator)
		if err != nil {
			reflags.command_error("mimir new", "Failed to parse project name")
			os.exit(1)
		}

		clean_name, cn_err := strings.join(name_arr, "-", context.allocator)
		if cn_err != nil {
			reflags.command_error("mimir new", "Failed to parse project name")
			os.exit(1)
		}

		project_name = clean_name
	}

	project_dir := project_name

	if os.exists(project_dir) {
		reflags.command_error(
			"mimir new",
			fmt.tprintf(
				"A project named '%s' already exists in the current directory",
				project_name,
			),
		)
		reflags.error_hint("new")
		os.exit(1)
	}

	if err := os.make_directory(project_dir); err != nil {
		if !os.exists(project_dir) {
			reflags.command_error(
				"mimir new",
				fmt.tprintf(
					"Failed to create directory '%s': %v",
					project_dir,
					err,
				),
			)
			os.exit(1)
		}
	}

	pkgs_dir := fmt.aprintf("%s/pkgs", project_dir)
	if err := os.make_directory(pkgs_dir); err != nil {
		if !os.exists(pkgs_dir) {
			reflags.command_error(
				"mimir new",
				fmt.tprintf(
					"Failed to create directory '%s': %v",
					pkgs_dir,
					err,
				),
			)
			os.exit(1)
		}
	}

	src_dir := fmt.aprintf("%s/src", project_dir)
	if err := os.make_directory(src_dir); err != nil {
		if !os.exists(src_dir) {
			reflags.command_error(
				"mimir new",
				fmt.tprintf(
					"Failed to create directory '%s': %v",
					src_dir,
					err,
				),
			)
			os.exit(1)
		}
	}
	main_path := fmt.aprintf("%s/src/main.odin", project_dir)
	if err := os.write_entire_file(
		main_path,
		transmute([]byte)(MAIN_FILE_CONTENT),
	); err != nil {
		reflags.command_error(
			"mimir new",
			fmt.tprintf("Failed to write main.odin: %v", err),
		)
		os.exit(1)
	}

	readme_path := fmt.aprintf("%s/README.md", project_dir)
	readme_content := fmt.aprintf(
		"# %s\n\nAn [Odin](https://odin-lang.org) project managed via **Mimir**.\n\n## Quick Start\n\n```bash\nmimir run    # Build and run\nmimir build  # Compile to binary\nmimir clean  # Clear build files and artifacts\n```",
		project_name,
	)
	if err := os.write_entire_file(readme_path, transmute([]u8)readme_content);
	   err != nil {
		reflags.command_error(
			"mimir new",
			fmt.tprintf("Failed to write README.md: %v", err),
		)
		os.exit(1)
	}

	ols_path := fmt.aprintf("%s/ols.json", project_dir)
	if err := os.write_entire_file(ols_path, transmute([]u8)OLS_FILE_CONTENT);
	   err != nil {
		reflags.command_error(
			"mimir new",
			fmt.tprintf("Failed to write ols.json: %v", err),
		)
		os.exit(1)
	}

	odinfmt_path := fmt.aprintf("%s/odinfmt.json", project_dir)
	if err := os.write_entire_file(
		odinfmt_path,
		transmute([]u8)FMT_FILE_CONTENT,
	); err != nil {
		reflags.command_error(
			"mimir new",
			fmt.tprintf("Failed to write odinfmt.json: %v", err),
		)
		os.exit(1)
	}

	gitignore_path := fmt.aprintf("%s/.gitignore", project_dir)
	gitignore_content := fmt.aprintf(
		"%s\n%s",
		GITIG_FILE_CONTENT,
		project_name,
	)
	if err := os.write_entire_file(
		gitignore_path,
		transmute([]u8)gitignore_content,
	); err != nil {
		reflags.command_error(
			"mimir new",
			fmt.tprintf("Failed to write .gitignore: %v", err),
		)
		os.exit(1)
	}

	if !app_state.config.no_git {
		if _, err := os.process_start({command = {"git", "init"}});
		   err != nil {
			reflags.command_error(
				"mimir new",
				fmt.tprintf("Failed to initialize git repo: %v", err),
			)
			os.exit(1)
		}
	}

	fmt.printfln(
		"%s%sCreating%s binary `%s` package...",
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_CYAN),
		cli.color_ansi(ansi.RESET),
		project_name,
	)
	fmt.printfln(
		"%s%sSuccessfully%s created `%s` project",
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		cli.color_ansi(ansi.RESET),
		project_name,
	)
}
