package command

import "core:bufio"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "pkgs:reflags"

load_ols_config :: proc(
	command_name: string,
) -> (
	config: json.Value,
	fail: ^reflags.Error,
) {
	config_file, err := os.read_entire_file("ols.json", context.temp_allocator)
	if err != nil {
		return {}, reflags.command_fail(fmt.tprintf("mimir %s", command_name), fmt.tprintf("Failed to read ols.json: %v", err))
	}

	parsed, json_err := json.parse_bytes(
		config_file,
		json.DEFAULT_SPECIFICATION,
		false,
		context.temp_allocator,
	)
	if json_err != nil {
		return {}, reflags.command_fail(fmt.tprintf("mimir %s", command_name), fmt.tprintf("Failed to parse ols.json: %v", json_err))
	}
	return parsed, nil
}

get_collections :: proc(
	config: json.Value,
	command_name: string,
) -> (
	collections: json.Array,
	fail: ^reflags.Error,
) {
	#partial switch root in config {
	case json.Object:
		value, ok := root["collections"]
		if !ok {
			empty := make([dynamic]json.Value, 0, 1, context.temp_allocator)
			return json.Array(empty), nil
		}
		#partial switch array in value {
		case json.Array:
			return array, nil
		}
	}
	return {}, reflags.command_fail(fmt.tprintf("mimir %s", command_name), "Invalid ols.json: 'collections' must be an array")
}

collection_name :: proc(value: json.Value) -> (name: string, ok: bool) {
	#partial switch collection in value {
	case json.Object:
		name_value, found := collection["name"]
		if !found {
			return "", false
		}
		#partial switch string_value in name_value {
		case json.String:
			return string(string_value), true
		}
	}
	return "", false
}

collection_path :: proc(
	value: json.Value,
	fallback: string,
) -> (
	path: string,
	ok: bool,
) {
	#partial switch collection in value {
	case json.Object:
		path_value, found := collection["path"]
		if !found {
			return fallback, true
		}
		#partial switch string_value in path_value {
		case json.String:
			return string(string_value), true
		}
	}
	return "", false
}

resolve_collection_path :: proc(
	path: string,
	command_name: string,
) -> (
	result: string,
	fail: ^reflags.Error,
) {
	cwd, cwd_err := os.get_working_directory(context.temp_allocator)
	if cwd_err != nil {
		return "", reflags.command_fail(
			fmt.tprintf("mimir %s", command_name),
			fmt.tprintf("Failed to determine project directory: %v", cwd_err),
		)
	}

	full_path := path
	if !filepath.is_abs(full_path) {
		full_path, _ = filepath.join({cwd, path}, context.temp_allocator)
	}
	result, _ = filepath.clean(full_path, context.temp_allocator)

	clean_cwd, _ := filepath.clean(cwd, context.temp_allocator)
	relative_to_target, rel_err := filepath.rel(
		result,
		clean_cwd,
		context.temp_allocator,
	)
	if result == clean_cwd ||
	   (rel_err == nil &&
			   relative_to_target != ".." &&
			   !strings.starts_with(relative_to_target, "../") &&
			   !strings.starts_with(relative_to_target, `..\`)) {
		return "", reflags.command_fail(
			fmt.tprintf("mimir %s", command_name),
			"Collection path cannot be the project directory or one of its parents",
		)
	}
	return result, nil
}

directory_contains_files :: proc(
	path: string,
) -> (
	contains_files: bool,
	fail: ^reflags.Error,
) {
	walker := os.walker_create(path)
	defer os.walker_destroy(&walker)

	for info in os.walker_walk(&walker) {
		if info.type != .Directory {
			return true, nil
		}
	}
	if err_path, walk_err := os.walker_error(&walker); walk_err != nil {
		return false, reflags.command_fail(
			"mimir remove-col",
			fmt.tprintf(
				"Failed to inspect collection directory '%s': %v",
				err_path,
				walk_err,
			),
		)
	}
	return false, nil
}

confirm_collection_delete :: proc(
	path: string,
) -> (
	confirmed: bool,
	fail: ^reflags.Error,
) {
	fmt.printf(
		"Collection directory '%s' contains files. Delete it and its contents? [y/N]: ",
		path,
	)

	reader: bufio.Reader
	stdin := os.to_stream(os.stdin)
	bufio.reader_init(&reader, stdin, allocator = context.temp_allocator)
	defer bufio.reader_destroy(&reader)
	response, read_err := bufio.reader_read_string(
		&reader,
		'\n',
		context.temp_allocator,
	)
	if read_err != nil && read_err != .EOF {
		return false, reflags.command_fail(
			"mimir remove-col",
			fmt.tprintf("Failed to read confirmation: %v", read_err),
		)
	}

	response = strings.trim(response, " \t\r\n")
	return response == "y" || response == "Y", nil
}

save_ols_config :: proc(
	config: json.Value,
	collections: json.Array,
	command_name: string,
) -> ^reflags.Error {
	#partial switch root in config {
	case json.Object:
		root_map := root
		root_map["collections"] = json.Value(collections)
	case:
		return reflags.command_fail(
			fmt.tprintf("mimir %s", command_name),
			"Invalid ols.json: expected a JSON object",
		)
	}

	data, marshal_err := json.unparse(
		config,
		{
			pretty = true,
			use_spaces = true,
			spaces = 4,
			sort_maps_by_key = true,
		},
		context.temp_allocator,
	)
	if marshal_err != nil {
		return reflags.command_fail(
			fmt.tprintf("mimir %s", command_name),
			fmt.tprintf("Failed to serialize ols.json: %v", marshal_err),
		)
	}

	if err := os.write_entire_file("ols.json", data); err != nil {
		return reflags.command_fail(
			fmt.tprintf("mimir %s", command_name),
			fmt.tprintf("Failed to write ols.json: %v", err),
		)
	}
	return nil
}

handle_add_col :: proc(args: reflags.Parsed_Args) -> ^reflags.Error {
	command_name := "add-col"
	name := reflags.get_string(args, "name")
	config, fail := load_ols_config(command_name)
	if fail != nil {
		return fail
	}
	collections, collection_fail := get_collections(config, command_name)
	if collection_fail != nil {
		return collection_fail
	}

	for col in collections {
		col_name, ok := collection_name(col)
		if !ok {
			return reflags.command_fail(
				"mimir add-col",
				"Invalid ols.json: every collection must have a name",
			)
		}
		if col_name == name {
			return reflags.command_fail(
				"mimir add-col",
				fmt.tprintf("Collection '%s' already exists", name),
			)
		}
	}

	collection_dir, path_fail := resolve_collection_path(name, command_name)
	if path_fail != nil {
		return path_fail
	}
	if os.exists(collection_dir) {
		info, stat_err := os.stat_do_not_follow_links(
			collection_dir,
			context.temp_allocator,
		)
		if stat_err != nil {
			return reflags.command_fail(
				"mimir add-col",
				fmt.tprintf(
					"Failed to inspect collection path '%s': %v",
					name,
					stat_err,
				),
			)
		}
		defer os.file_info_delete(info, context.temp_allocator)
		if info.type == .Symlink {
			return reflags.command_fail(
				"mimir add-col",
				fmt.tprintf("Collection path '%s' is a symbolic link", name),
			)
		}
		if info.type != .Directory {
			return reflags.command_fail(
				"mimir add-col",
				fmt.tprintf(
					"Collection path '%s' exists and is not a directory",
					name,
				),
			)
		}
	} else if err := os.make_directory_all(collection_dir); err != nil {
		return reflags.command_fail(
			"mimir add-col",
			fmt.tprintf(
				"Failed to create collection directory '%s': %v",
				name,
				err,
			),
		)
	}

	new_col := make(map[string]json.Value, context.temp_allocator)
	new_col["name"] = json.Value(json.String(name))
	new_col["path"] = json.Value(json.String(name))
	append(&collections, json.Value(json.Object(new_col)))

	if fail = save_ols_config(config, collections, command_name); fail != nil {
		return fail
	}
	fmt.printfln("Added collection '%s' at '%s'", name, name)
	return nil
}

handle_remove_col :: proc(args: reflags.Parsed_Args) -> ^reflags.Error {
	command_name := "remove-col"
	name := reflags.get_string(args, "name")
	config, fail := load_ols_config(command_name)
	if fail != nil {
		return fail
	}
	old_collections, collection_fail := get_collections(config, command_name)
	if collection_fail != nil {
		return collection_fail
	}

	found := false
	collection_dir: string
	filtered := make(
		[dynamic]json.Value,
		0,
		len(old_collections),
		context.temp_allocator,
	)
	for col in old_collections {
		col_name, ok := collection_name(col)
		if !ok {
			return reflags.command_fail(
				"mimir remove-col",
				"Invalid ols.json: every collection must have a name",
			)
		}
		if col_name == name {
			found = true
			col_path, path_ok := collection_path(col, col_name)
			if !path_ok {
				return reflags.command_fail(
					"mimir remove-col",
					"Invalid ols.json: collection path must be a string",
				)
			}
			collection_dir = col_path
			continue
		}
		append(&filtered, col)
	}
	if !found {
		return reflags.command_fail(
			"mimir remove-col",
			fmt.tprintf("Collection '%s' does not exist", name),
		)
	}

	full_collection_dir, path_fail := resolve_collection_path(
		collection_dir,
		command_name,
	)
	if path_fail != nil {
		return path_fail
	}
	if os.exists(full_collection_dir) {
		info, stat_err := os.stat_do_not_follow_links(
			full_collection_dir,
			context.temp_allocator,
		)
		if stat_err != nil {
			return reflags.command_fail(
				"mimir remove-col",
				fmt.tprintf(
					"Failed to inspect collection path '%s': %v",
					collection_dir,
					stat_err,
				),
			)
		}
		defer os.file_info_delete(info, context.temp_allocator)
		if info.type == .Symlink {
			return reflags.command_fail(
				"mimir remove-col",
				fmt.tprintf(
					"Collection path '%s' is a symbolic link",
					collection_dir,
				),
			)
		}
		if info.type != .Directory {
			return reflags.command_fail(
				"mimir remove-col",
				fmt.tprintf(
					"Collection path '%s' is not a directory",
					collection_dir,
				),
			)
		}

		contains_files, inspect_fail := directory_contains_files(
			full_collection_dir,
		)
		if inspect_fail != nil {
			return inspect_fail
		}
		if contains_files {
			confirmed, confirm_fail := confirm_collection_delete(
				full_collection_dir,
			)
			if confirm_fail != nil {
				return confirm_fail
			}
			if !confirmed {
				fmt.println("Collection removal cancelled")
				return nil
			}
		}
		if err := os.remove_all(full_collection_dir); err != nil {
			return reflags.command_fail(
				"mimir remove-col",
				fmt.tprintf(
					"Failed to remove collection directory '%s': %v",
					full_collection_dir,
					err,
				),
			)
		}
	}

	if fail = save_ols_config(config, json.Array(filtered), command_name);
	   fail != nil {
		return fail
	}
	fmt.printfln("Removed collection '%s'", name)
	return nil
}
