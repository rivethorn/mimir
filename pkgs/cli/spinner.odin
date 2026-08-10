package cli

import "core:fmt"
import "core:sync"
import "core:thread"
import "core:time"

Spinner_State :: struct {
	message:    string,
	is_running: bool,
	mtx:        sync.Mutex,
}

spinner_proc :: proc(t: ^thread.Thread) {
	state := (^Spinner_State)(t.data)
	frames := []string{"|", "/", "-", "\\"}
	msg := state.message
	i := 0

	for {
		sync.mutex_lock(&state.mtx)
		running := state.is_running
		sync.mutex_unlock(&state.mtx)

		if !running {
			return
		}

		frame := frames[i % len(frames)]
		fmt.printf("\r%s %s", frame, msg)

		i += 1
		time.sleep(100 * time.Millisecond)
	}
}
