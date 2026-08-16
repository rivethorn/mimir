package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:util"

@(private = "file")
get_directory_names :: proc(dir_path: string) -> ([dynamic]string, os.Error) {
	f, err := os.open(dir_path)
	if err != nil {
		return nil, err
	}
	defer os.close(f)

	it := os.read_directory_iterator_create(f)
	defer os.read_directory_iterator_destroy(&it)

	names := make([dynamic]string)

	for info in os.read_directory_iterator(&it) {
		if info.type == .Directory {
			if info.name == "." || info.name == ".." {
				continue
			}

			name_clone := strings.clone(info.name)
			append(&names, name_clone)
		}
	}

	return names, nil
}

handle_list :: proc() {
	cwd, err := os.get_working_directory(context.temp_allocator)
	if err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_RED),
			"\nFailed to determine project path",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}
	pkg_path, _ := filepath.join({cwd, "pkgs"}, context.temp_allocator)

	dirs, d_err := get_directory_names(pkg_path)
	defer util.delete_dynamic_strings(dirs)
	if d_err != nil {
		fmt.eprintln(
			cli.color_ansi(ansi.FG_RED),
			"\nFailed to get pkgs directories",
			cli.color_ansi(ansi.RESET),
			sep = "",
		)
		os.exit(1)
	}

	if len(dirs) == 0 {
		fmt.printfln(
			"%s%sThis project has no packages%s",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_CYAN),
			cli.color_ansi(ansi.RESET),
		)
		os.exit(0)
	}

	fmt.printfln(
		"%s%spkgs%s",
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		cli.color_ansi(ansi.RESET),
	)
	for dir, i in dirs {
		if i != len(dirs) - 1 {
			fmt.printfln(
				"%s├── %s%s",
				cli.color_ansi(ansi.FG_BRIGHT_WHITE),
				dir,
				cli.color_ansi(ansi.RESET),
			)
		} else {
			fmt.printfln(
				"%s└── %s%s",
				cli.color_ansi(ansi.FG_BRIGHT_WHITE),
				dir,
				cli.color_ansi(ansi.RESET),
			)
		}
	}

	free_all(context.temp_allocator)
}
