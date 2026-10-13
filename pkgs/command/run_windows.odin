#+build windows
package command

import "core:sys/windows"

setup_console_ctrl_handler :: proc() {
	windows.SetConsoleCtrlHandler(nil, true)
}
