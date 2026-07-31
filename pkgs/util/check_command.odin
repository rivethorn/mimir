package util

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

command_exists :: proc(command_name: string) -> bool {
	path_env, found := os.lookup_env("PATH", context.temp_allocator)
	if !found do return false

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
		if dir == "" do continue

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
try_execute :: proc(command: []string) -> bool {
	handle, err := os.process_start(os.Process_Desc{command = command})

	if err != nil {
		return false
	}

	_e := os.process_kill(handle)
	return true
}

