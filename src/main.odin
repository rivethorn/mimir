/*
Mimir - Odin's toolchain

The command line is defined and parsed in pkgs:args (with reflags). Each
command has its handler attached via reflags' Command_Handler system, so
main just invokes `args.parse` which dispatches to the correct handler.

In debug builds (-debug) the heap is wrapped in a mem.Tracking_Allocator;
if anything is still allocated when the command finishes, a leak report
(name, size, and where in the code it came from) is printed to stderr.
*/

package main

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "pkgs:app"

main :: proc() {
	code: int
	when ODIN_DEBUG {
		code = run_debug()
	} else {
		code = app.parse_and_run()
	}
	os.exit(code)
}

/*
run_debug runs Mimir with a tracking allocator over the heap. Every
context.allocator allocation is counted, so the leak report at the end
covers the whole command. Returns the command's exit code.
*/
@(private = "file")
run_debug :: proc() -> (code: int) {
	// Bad frees (double frees, invalid frees) are collected instead of
	// crashing, so one bug doesn't hide the rest of the report.
	track: mem.Tracking_Allocator
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	code = app.parse_and_run()

	report_leaks(&track)
	mem.tracking_allocator_destroy(&track)
	return
}

/*
report_leaks prints the allocations that are still live at exit, grouped
by call site, plus any bad frees the tracker recorded.
*/
@(private = "file")
report_leaks :: proc(track: ^mem.Tracking_Allocator) {
	if len(track.bad_free_array) > 0 {
		fmt.eprintfln(
			"mimir [debug]: %d bad free(s):",
			len(track.bad_free_array),
		)
		for free in track.bad_free_array {
			print_location(free.location)
			fmt.eprintf("\n")
		}
	}

	if len(track.allocation_map) == 0 {
		return
	}

	// Aggregate by "procedure at file:line" so one leaky call site inside
	// a loop shows up as a single entry. The report's own bookkeeping rides
	// on the temp allocator so it never shows up in the tracker.
	leaked_bytes: int
	Site_Stats :: struct {
		count: int,
		bytes: int,
	}
	sites := make(map[string]Site_Stats, context.temp_allocator)
	for _, entry in track.allocation_map {
		leaked_bytes += entry.size
		loc := entry.location
		key := fmt.tprintf("%s, %s:%d", loc.procedure, loc.file_path, loc.line)
		sites[key] = Site_Stats{sites[key].count + 1, sites[key].bytes + entry.size}
	}

	fmt.eprintfln(
		"mimir [debug]: %d leaked allocation(s), %d bytes:",
		len(track.allocation_map),
		leaked_bytes,
	)
	for key, stat in sites {
		fmt.eprintfln(
			"  %s: %d allocation(s), %d bytes",
			key,
			stat.count,
			stat.bytes,
		)
	}
}

@(private = "file")
print_location :: proc(loc: runtime.Source_Code_Location) {
	file := loc.file_path
	if loc.line > 0 {
		fmt.eprintf("%s:%d", file, loc.line)
	} else {
		fmt.eprintf("%s", file)
	}
}
