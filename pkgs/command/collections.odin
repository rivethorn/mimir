package command

import "core:encoding/json"
import "core:fmt"
import "core:os"
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

	if fail = save_ols_config(config, json.Array(filtered), command_name);
	   fail != nil {
		return fail
	}
	fmt.printfln("Removed collection '%s'", name)
	return nil
}
