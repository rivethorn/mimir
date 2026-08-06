package cli

import "core:fmt"
import "core:thread"
import "core:time"

Spinner_State :: struct {
	message:    string,
	is_running: bool,
}

spinner_proc :: proc(t: ^thread.Thread) {
	state := (^Spinner_State)(t.data)
	frames := []string{"|", "/", "-", "\\"}
	i := 0

	for state.is_running {
		frame := frames[i % len(frames)]
		fmt.printf("\r%s %s", frame, state.message)

		i += 1
		time.sleep(100 * time.Millisecond)
	}
}
