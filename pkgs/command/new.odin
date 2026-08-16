package command

import "core:fmt"
import "core:os"
import "core:strings"
import "core:terminal/ansi"
import "pkgs:cli"

handle_new :: proc() {
	project_name := os.args[2]

	if strings.contains_any(project_name, `\/:*?"<>|`) ||
	   strings.starts_with(project_name, "-") ||
	   strings.starts_with(project_name, "--") ||
	   project_name == "." ||
	   project_name == ".." {
		fmt.eprintf(
			"%s%sERROR%s: Invalid project name '%s%s%s'\n",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_RED),
			cli.color_ansi(ansi.RESET),
			cli.color_ansi(ansi.FG_YELLOW),
			project_name,
			cli.color_ansi(ansi.RESET),
		)
		os.exit(1)
	}

	if strings.contains(project_name, " ") {
		name_arr, err := strings.split(project_name, " ", context.allocator)
		if err != nil {
			fmt.eprintf(
				"%s%sERROR%s: failed to parse project name\n",
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_RED),
				cli.color_ansi(ansi.RESET),
			)
			os.exit(1)
		}

		clean_name, cn_err := strings.join(name_arr, "-", context.allocator)
		if cn_err != nil {
			fmt.eprintf(
				"%s%sERROR%s: failed to parse project name\n",
				cli.color_ansi(ansi.BOLD),
				cli.color_ansi(ansi.FG_BRIGHT_RED),
				cli.color_ansi(ansi.RESET),
			)
			os.exit(1)
		}

		project_name = clean_name
	}

	project_dir := project_name

	if os.exists(project_dir) {
		fmt.eprintf(
			"%s%sWARNING%s: A project named %q aleadey exists in the current directory\n",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_YELLOW),
			cli.color_ansi(ansi.RESET),
			project_name,
		)
		os.exit(1)
	}

	if err := os.make_directory(project_dir); err != nil {
		if !os.exists(project_dir) {
			fmt.eprintf(
				"%sFailed%s to create directory %q: %v\n",
				cli.color_ansi(ansi.FG_RED),
				cli.color_ansi(ansi.RESET),
				project_dir,
				err,
			)
			os.exit(1)
		}
	}

	pkgs_dir := fmt.aprintf("%s/pkgs", project_dir)
	if err := os.make_directory(pkgs_dir); err != nil {
		if !os.exists(pkgs_dir) {
			fmt.eprintf(
				"%sFailed%s to create directory %q: %v\n",
				cli.color_ansi(ansi.FG_RED),
				cli.color_ansi(ansi.RESET),
				pkgs_dir,
				err,
			)
			os.exit(1)
		}
	}

	src_dir := fmt.aprintf("%s/src", project_dir)
	if err := os.make_directory(src_dir); err != nil {
		if !os.exists(src_dir) {
			fmt.eprintf(
				"%sFailed%s to create directory %q: %v\n",
				cli.color_ansi(ansi.FG_RED),
				cli.color_ansi(ansi.RESET),
				src_dir,
				err,
			)
			os.exit(1)
		}
	}
	main_path := fmt.aprintf("%s/src/main.odin", project_dir)
	if err := os.write_entire_file(
		main_path,
		transmute([]byte)(MAIN_FILE_CONTENT),
	); err != nil {
		fmt.eprintf(
			"%sFailed%s to write main.odin: %v\n",
			cli.color_ansi(ansi.FG_RED),
			cli.color_ansi(ansi.RESET),
			err,
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
		fmt.eprintf(
			"%sFailed%s to write README.md: %v\n",
			cli.color_ansi(ansi.FG_RED),
			cli.color_ansi(ansi.RESET),
			err,
		)
		os.exit(1)
	}

	ols_path := fmt.aprintf("%s/ols.json", project_dir)
	if err := os.write_entire_file(ols_path, transmute([]u8)OLS_FILE_CONTENT);
	   err != nil {
		fmt.eprintf(
			"%sFailed%s to write ols.json: %v\n",
			cli.color_ansi(ansi.FG_RED),
			cli.color_ansi(ansi.RESET),
			err,
		)
		os.exit(1)
	}

	odinfmt_path := fmt.aprintf("%s/odinfmt.json", project_dir)
	if err := os.write_entire_file(
		odinfmt_path,
		transmute([]u8)FMT_FILE_CONTENT,
	); err != nil {
		fmt.eprintf(
			"%sFailed%s to write odinfmt.json: %v\n",
			cli.color_ansi(ansi.FG_RED),
			cli.color_ansi(ansi.RESET),
			err,
		)
		os.exit(1)
	}

	gitignore_path := fmt.aprintf("%s/.gitignore", project_dir)
	gitignore_content := fmt.aprintf("%s\n", GITIG_FILE_CONTENT, project_name)
	if err := os.write_entire_file(
		gitignore_path,
		transmute([]u8)gitignore_content,
	); err != nil {
		fmt.eprintf(
			"%sFailed%s to write .gitignore: %v\n",
			cli.color_ansi(ansi.FG_RED),
			cli.color_ansi(ansi.RESET),
			err,
		)
		os.exit(1)
	}

	if _, err := os.process_start({command = {"git", "init"}}); err != nil {
		fmt.eprintf(
			"%sFailed%s to initialize git repo: %v\n",
			cli.color_ansi(ansi.FG_RED),
			cli.color_ansi(ansi.RESET),
			err,
		)
		os.exit(1)
	}

	fmt.printf(
		"%s%sCreating%s binary `%s` package...\n",
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_CYAN),
		cli.color_ansi(ansi.RESET),
		project_name,
	)
	fmt.printf(
		"%s%sSuccessfully%s created `%s` project\n",
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_GREEN),
		cli.color_ansi(ansi.RESET),
		project_name,
	)
}
