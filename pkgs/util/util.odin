package util

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:terminal/ansi"
import "pkgs:cli"

delete_strings :: proc(ss: []string) {
	for s in ss {
		delete(s)
	}
}

delete_dynamic_strings :: proc(ss: [dynamic]string) {
	delete_strings(ss[:])
	delete(ss)
}

command_exists :: proc(command_name: string) -> bool {
	path_env, found := os.lookup_env("PATH", context.temp_allocator)
	if !found {return false}

	delimiter := ":"
	exe_extension := ""

	when ODIN_OS == .Windows {
		delimiter = ";"
		exe_extension = ".exe"
	}

	target_file := command_name
	if exe_extension != "" &&
	   !strings.has_suffix(command_name, exe_extension) {
		target_file = fmt.tprintf("%s%s", command_name, exe_extension)
	}

	path_list := strings.split(path_env, delimiter, context.temp_allocator)

	for dir in path_list {
		if dir == "" {continue}

		full_path, err := filepath.join(
			[]string{dir, target_file},
			context.temp_allocator,
		)

		if os.exists(full_path) {
			return true
		}
	}

	return false
}

is_odin_project :: proc() -> bool {
	project_dir, err := os.get_working_directory(context.temp_allocator)
	if err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_RED),
			"Failed to determine project directory",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	source_dir, _ := filepath.join(
		{project_dir, "src"},
		context.temp_allocator,
	)

	if !os.exists(source_dir) {
		return false
	}

	walker := os.walker_create(source_dir)
	files: [dynamic]string
	defer delete(files)

	for info in os.walker_walk(&walker) {
		if strings.has_suffix(info.fullpath, ".odin") {
			append(&files, info.name)
			continue
		}
	}

	os.walker_destroy(&walker)

	if len(files) == 0 {
		return false
	}

	ols_path, _ := filepath.join(
		{project_dir, "ols.json"},
		context.temp_allocator,
	)

	if !os.exists(ols_path) {
		return false
	}

	return true
}
