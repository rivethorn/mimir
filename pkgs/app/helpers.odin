package app

import "core:fmt"
import "core:strings"
import "pkgs:reflags"

// is_project_command reports whether a command operates on an Odin project
// and therefore requires one to be present.
is_project_command :: proc(cmd_name: string) -> bool {
	switch cmd_name {
	case "build", "run", "clean":
		return true
	case:
		return false
	}
}

// validate_url enforces the old "site/owner/repo" URL rules: it must contain
// a '/', must not end in ".git", and must not contain '@'. Prints the error
// itself and reports whether the URL passed.
validate_url :: proc(app_cli: ^reflags.CLI, url: string) -> bool {
	if url == "." {
		return true
	}
	arr, _ := strings.split(url, "/", context.temp_allocator)
	if !strings.contains_rune(url, '/') ||
	   arr[len(arr) - 1] == ".git" ||
	   strings.contains_rune(url, '@') {
		err := reflags.make_error(
			.Invalid_Value,
			fmt.tprintf(
				"Invalid repository URL: %s (expected site/owner/repo)",
				url,
			),
		)
		reflags.print_error(app_cli, err)
		free(err)
		return false
	}
	return true
}
