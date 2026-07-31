package cli

import "core:fmt"

color_ansi :: #force_inline proc(seq: string) -> string {
	return fmt.tprintf("\x1b[%sm", seq)
}

