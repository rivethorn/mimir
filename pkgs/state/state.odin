package state

Command :: enum {
	Build,
	Run,
	New,
	// Add,
	// Remove,
	// Install,
	// Uninstall,
	// Toolchain,
	Version,
	Help,
	Error,
}

Command_Config :: struct {
	name, src_path, output:           string,
	run_args:                         []string,
	release, silent, force_recompile: bool,
}

State :: struct {
	command: Command,
	config:  Command_Config,
}

