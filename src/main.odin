/*
Mimir - Odin's toolchain

The command line is defined and parsed in pkgs:args (with reflags). Each
command has its handler attached via reflags' Command_Handler system, so
main just invokes `args.parse` which dispatches to the correct handler.
*/

package main

import "pkgs:app"

main :: proc() {
	app.parse_and_run()
}
