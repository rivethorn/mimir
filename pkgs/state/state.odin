package state

Command :: enum {
	Error,
	Build,
	Run,
	New,
	Clean,
	// Add,
	// Remove,
	// Install,
	// Uninstall,
	// Toolchain,
	Version,
	Help,
}

Command_Config :: struct {
	name, src_path, output: string,
	run_args:               []string,
	release, silent:        bool,
}

State :: struct {
	command: Command,
	config:  Command_Config,
}
