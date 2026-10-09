#+private
package command

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "pkgs:reflags"

Build_Target :: struct {
	// src_path is handed to `odin build`, relative to cwd when possible.
	src_path: string,
	// exe_base names the binary: the package directory's name, the file
	// stem for a single file, or the project directory's name for the
	// default src/ build.
	exe_base: string,
	// is_file marks a single-file target, which odin builds with -file.
	is_file: bool,
	// is_default reports the default src/ build with no package argument
	// given or (for run) an unresolvable one. Naming src/ outright still
	// consumes the argument, so it comes back false.
	is_default: bool,
}

// resolve_build_target turns the optional `pkg` argument into a Build_Target.
// Empty means the default src/ build. Otherwise the argument names buildable
// source: a package directory or a single Odin file, resolved as-given
// relative to cwd, then under src/. Naming src/ itself is the default build.
// A directory must hold .odin files; either form must declare a main
// procedure. When fallback_default is set (mimir run), an argument that
// resolves to nothing — or to a file odin can't build — instead yields the
// default target so the caller can pass it to the program.
resolve_build_target :: proc(
	pkg_arg, cwd, cmd_label, hint_name: string,
	fallback_default: bool,
) -> Build_Target {
	if pkg_arg == "" {
		return Build_Target {
			src_path = "src",
			exe_base = filepath.base(cwd),
			is_default = true,
		}
	}

	rel := strings.trim_right(pkg_arg, "/\\")

	pkg_path := ""
	src_form := ""
	is_file := false
	if rel != "" {
		abs := rel
		if !filepath.is_abs(rel) {
			abs, _ = filepath.join({cwd, rel}, context.temp_allocator)
		}
		kind := classify_build_source(abs)
		if kind == .Missing {
			rel2 := fmt.tprintf("src/%s", rel)
			abs2, _ := filepath.join({cwd, rel2}, context.temp_allocator)
			kind = classify_build_source(abs2)
			if kind != .Missing {
				pkg_path = abs2
				src_form = rel2
			}
		} else {
			pkg_path = abs
			src_form = rel
		}
		if pkg_path != "" {
			is_file = kind == .Odin_File
			if kind == .Other_File {
				if fallback_default {
					return Build_Target {
						src_path = "src",
						exe_base = filepath.base(cwd),
						is_default = true,
					}
				}
				reflags.command_error(
					cmd_label,
					fmt.tprintf("'%s' is not an Odin file", pkg_arg),
				)
				reflags.error_hint(hint_name)
				os.exit(1)
			}
		}
	}

	if pkg_path == "" {
		if fallback_default {
			return Build_Target {
				src_path = "src",
				exe_base = filepath.base(cwd),
				is_default = true,
			}
		}
		reflags.command_error(
			cmd_label,
			fmt.tprintf("Unknown package '%s'", pkg_arg),
		)
		reflags.error_hint(hint_name)
		os.exit(1)
	}

	if is_file {
		data, data_err := os.read_entire_file(pkg_path, context.temp_allocator)
		if data_err != nil || !odin_src_has_main(string(data)) {
			reflags.command_error(
				cmd_label,
				fmt.tprintf("File '%s' has no main procedure", rel),
			)
			reflags.error_hint(hint_name)
			os.exit(1)
		}
		return Build_Target {
			src_path = strings.clone(src_form, context.allocator),
			exe_base = strings.clone(
				filepath.stem(pkg_path),
				context.allocator,
			),
			is_file = true,
			is_default = false,
		}
	}

	has_odin, has_main := scan_pkg_dir(pkg_path)
	if !has_odin {
		reflags.command_error(
			cmd_label,
			fmt.tprintf("Package '%s' contains no Odin files", rel),
		)
		reflags.error_hint(hint_name)
		os.exit(1)
	}
	if !has_main {
		reflags.command_error(
			cmd_label,
			fmt.tprintf("Package '%s' has no main procedure", rel),
		)
		reflags.error_hint(hint_name)
		os.exit(1)
	}

	// Naming src/ outright is just the default build: same sources, same
	// binary name. The argument still counts as consumed (is_default stays
	// false) so `run src` doesn't pass "src" to the program.
	default_src, _ := filepath.join({cwd, "src"}, context.temp_allocator)
	clean_pkg, _ := filepath.clean(pkg_path, context.temp_allocator)
	clean_default, _ := filepath.clean(default_src, context.temp_allocator)
	if clean_pkg == clean_default {
		return Build_Target {
			src_path = "src",
			exe_base = filepath.base(cwd),
			is_default = false,
		}
	}

	return Build_Target {
		src_path = strings.clone(src_form, context.allocator),
		exe_base = strings.clone(filepath.base(pkg_path), context.allocator),
		is_default = false,
	}
}

// Target_Kind classifies a candidate build source: a package directory, a
// single Odin file, an existing file odin can't build, or nothing at all.
Target_Kind :: enum {
	Missing,
	Dir,
	Odin_File,
	Other_File,
}

classify_build_source :: proc(path: string) -> Target_Kind {
	if !os.exists(path) {
		return .Missing
	}
	if os.is_dir(path) {
		return .Dir
	}
	if filepath.ext(path) == ".odin" {
		return .Odin_File
	}
	return .Other_File
}

// scan_pkg_dir reports whether dir holds .odin files and whether any of
// them declares a main procedure.
scan_pkg_dir :: proc(dir: string) -> (has_odin, has_main: bool) {
	fd, dir_err := os.open(dir)
	if dir_err != nil {
		return false, false
	}
	defer os.close(fd)

	infos, read_err := os.read_dir(fd, -1, context.temp_allocator)
	if read_err != nil {
		return false, false
	}

	for info in infos {
		if info.type == .Directory {
			continue
		}
		if filepath.ext(info.name) != ".odin" {
			continue
		}
		has_odin = true
		if has_main {
			continue
		}
		full, _ := filepath.join({dir, info.name}, context.temp_allocator)
		data, data_err := os.read_entire_file(full, context.temp_allocator)
		if data_err != nil {
			continue
		}
		if odin_src_has_main(string(data)) {
			has_main = true
		}
	}

	return has_odin, has_main
}

// odin_src_has_main reports whether comment-stripped Odin source declares
// `main :: proc`, allowing any whitespace (even newlines) around the `::`.
odin_src_has_main :: proc(src: string) -> bool {
	code := strip_odin_comments(src)
	i := 0
	for i < len(code) {
		end, ok := match_ident_at(code, i, "main")
		if !ok {
			i += 1
			continue
		}
		j := skip_ws(code, end)
		if j + 2 > len(code) || code[j:j + 2] != "::" {
			i = end
			continue
		}
		k := skip_ws(code, j + 2)
		if _, pok := match_ident_at(code, k, "proc"); pok {
			return true
		}
		i = end
	}
	return false
}

is_ident_byte :: proc(c: byte) -> bool {
	return (c >= 'a' && c <= 'z') ||
		(c >= 'A' && c <= 'Z') ||
		(c >= '0' && c <= '9') ||
		c == '_'
}

is_space_byte :: proc(c: byte) -> bool {
	return c == ' ' ||
		c == '\t' ||
		c == '\n' ||
		c == '\r' ||
		c == '\v' ||
		c == '\f'
}

// match_ident_at matches word at byte offset i with identifier boundaries.
match_ident_at :: proc(s: string, i: int, word: string) -> (end: int, ok: bool) {
	if i < 0 || i + len(word) > len(s) {
		return 0, false
	}
	if s[i:i + len(word)] != word {
		return 0, false
	}
	if i > 0 && is_ident_byte(s[i - 1]) {
		return 0, false
	}
	end = i + len(word)
	if end < len(s) && is_ident_byte(s[end]) {
		return 0, false
	}
	return end, true
}

skip_ws :: proc(s: string, i: int) -> int {
	j := i
	for j < len(s) && is_space_byte(s[j]) {
		j += 1
	}
	return j
}

// write_blank emits a space for c, preserving newlines so tokens can't
// merge across blanked text.
write_blank :: proc(b: ^strings.Builder, c: byte) {
	if c == '\n' {
		strings.write_byte(b, '\n')
	} else {
		strings.write_byte(b, ' ')
	}
}

// strip_odin_comments removes // line comments and (nestable) /* */
// block comments, and blanks out string, rune, and raw-string literals so
// comment markers inside them are left alone and their contents can't pose
// as code. Newlines are preserved so tokens can't merge across removed text.
strip_odin_comments :: proc(
	src: string,
	allocator := context.temp_allocator,
) -> string {
	b := strings.builder_make(allocator)
	i := 0
	for i < len(src) {
		c := src[i]
		if c == '/' && i + 1 < len(src) && src[i + 1] == '/' {
			for i < len(src) && src[i] != '\n' {
				i += 1
			}
		} else if c == '/' && i + 1 < len(src) && src[i + 1] == '*' {
			depth := 1
			i += 2
			for i < len(src) && depth > 0 {
				if src[i] == '\n' {
					strings.write_byte(&b, '\n')
				}
				if src[i] == '/' && i + 1 < len(src) && src[i + 1] == '*' {
					depth += 1
					i += 1
				} else if src[i] == '*' &&
					i + 1 < len(src) &&
					src[i + 1] == '/' {
					depth -= 1
					i += 1
				}
				i += 1
			}
		} else if c == '"' || c == '\'' {
			quote := c
			write_blank(&b, c)
			i += 1
			for i < len(src) {
				write_blank(&b, src[i])
				if src[i] == '\\' && i + 1 < len(src) {
					write_blank(&b, src[i + 1])
					i += 2
					continue
				}
				i += 1
				if src[i - 1] == quote {
					break
				}
			}
		} else if c == '`' {
			write_blank(&b, c)
			i += 1
			for i < len(src) {
				write_blank(&b, src[i])
				i += 1
				if src[i - 1] == '`' {
					break
				}
			}
		} else {
			strings.write_byte(&b, c)
			i += 1
		}
	}
	return strings.to_string(b)
}
