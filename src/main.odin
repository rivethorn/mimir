/*
 Mimir - Odin's toolchain
*/

package main

import "core:fmt"
import "core:os"

import "pkgs:cli"
import "pkgs:new"

VERSION := #config(VERSION, "0.1.0")

main :: proc() {
	if len(os.args) < 2 {
		cli.print_usage()
		os.exit(1)
	}

	if len(os.args) > 1 && os.args[1] == "help" {
		cli.print_usage()
		os.exit(0)
	}

	if len(os.args) > 1 && os.args[1] == "version" {
		fmt.println("Mimir version", VERSION)
		os.exit(0)
	}

	if len(os.args) > 2 && os.args[1] == "new" {
		new.create()
		os.exit(0)
	}
}

