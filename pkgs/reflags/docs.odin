/*
package reflags - a builder-style command-line argument parser for Odin.

reflags lets you define commands, options, and positional arguments
declaratively, then parse `os.args` against them. It supports nested
subcommands, typed option values (string, int, bool, float, path, enum,
custom), default values, required flags, variadic arguments, aliases,
and colored, auto-generated help/version output.

Basic usage:

```odin
package main

import "core:fmt"
import "core:os"
import "pkgs:reflags"

build_handler :: proc(args: reflags.Parsed_Args) -> ^reflags.Error {
	release := reflags.get_bool(args, "release")
	jobs    := reflags.get_int(args, "jobs")
	fmt.printfln("Building (release=%v, jobs=%d)", release, jobs)
	return nil
}

main :: proc() {
	root := reflags.command("myapp", "Does a thing")
	// convenience: --release/-r boolean flag, --jobs/-j int option
	cmd_add_option := proc(b: ^reflags.Command, o: reflags.Option) { append(&b.options, o) }
	cmd_add_option(&root, reflags.opt_flag("release", "r", "Build in release mode"))
	cmd_add_option(&root, reflags.opt_int("jobs", "j", "Number of parallel jobs"))
	root.handler = build_handler

	cli := reflags.make_cli("myapp", "1.0.0", "Does a thing", &root)

	parsed, err := reflags.parse(&cli, os.args[1:])
	defer reflags.destroy(parsed)
	if err != nil {
		reflags.print_error(&cli, err)
		os.exit(1)
	}

	if parsed.command.handler != nil {
		if herr := parsed.command.handler(parsed); herr != nil {
			reflags.print_error(&cli, herr)
			os.exit(1)
		}
	}
}
```

Or use `parse_or_exit` to let the package handle errors (and `--help` /
`--version`) for you:

```odin
parsed := reflags.parse_or_exit(&cli, os.args[1:])
defer reflags.destroy(parsed)
```

Options can also be built step by step with `option` + `opt_*` procedures,
commands with `command_builder` + `cmd_*` procedures. Value types are
described with `Arg_Type_Info` presets (`string_type`, `int_type`, ...)
or constructed with `enum_type` / `custom_type`.

Command handlers receive a `Parsed_Args` and read values back with the
`get_*` accessors. Handlers may return an `^Error` (see `make_error`);
`Help_Requested` / `Version_Requested` reasons print help/version and exit 0.

See `examples/cargo_like/` for a full Cargo-style CLI.
*/

package reflags
