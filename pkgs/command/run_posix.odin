#+build !windows
package command

import "core:sys/posix"

setup_console_ctrl_handler :: proc() {
	posix.signal(.SIGINT, nil)
}
