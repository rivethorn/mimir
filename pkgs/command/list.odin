package command

import "core:fmt"
import "core:os"
import "core:strings"
import "core:terminal/ansi"
import "pkgs:cli"
import "pkgs:reflags"
import "pkgs:util"

@(private = "file")
get_apps_names :: proc(dir_path: string) -> ([dynamic]string, os.Error) {
	f, err := os.open(dir_path)
	if err != nil {
		return nil, err
	}
	defer os.close(f)

	it := os.read_directory_iterator_create(f)
	defer os.read_directory_iterator_destroy(&it)

	names := make([dynamic]string)

	for info in os.read_directory_iterator(&it) {
		if info.type == .Regular {
			if info.name == "." || info.name == ".." {
				continue
			}

			name_clone := strings.clone(info.name)
			append(&names, name_clone)
		}
	}

	return names, nil
}

handle_list :: proc(args: reflags.Parsed_Args) -> ^reflags.Error {
	bin_dir := util.get_mimir_bin_dir_path()

	binaries, err := get_apps_names(bin_dir)
	if err != nil {
		reflags.command_error("mimir list", "Failed to read binaries path")
		os.exit(1)
	}
	defer delete(binaries)

	if len(binaries) == 0 {
		fmt.printfln(
			"%s%sNo packages are installed by Mimir%s",
			cli.color_ansi(ansi.BOLD),
			cli.color_ansi(ansi.FG_BRIGHT_CYAN),
			cli.color_ansi(ansi.RESET),
		)
		os.exit(0)
	}

	fmt.printfln(
		"%s%s~/.mimir/bin/%s",
		cli.color_ansi(ansi.BOLD),
		cli.color_ansi(ansi.FG_BRIGHT_CYAN),
		cli.color_ansi(ansi.RESET),
	)
	for bin, i in binaries {
		if i != len(binaries) - 1 {
			fmt.printfln(
				"%s├── %s%s",
				cli.color_ansi(ansi.FG_BRIGHT_WHITE),
				bin,
				cli.color_ansi(ansi.RESET),
			)
		} else {
			fmt.printfln(
				"%s└── %s%s",
				cli.color_ansi(ansi.FG_BRIGHT_WHITE),
				bin,
				cli.color_ansi(ansi.RESET),
			)
		}
	}

	free_all(context.temp_allocator)

	return nil
}
