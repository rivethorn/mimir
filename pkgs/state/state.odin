package state

Command :: enum {
	Error,
	Build,
	Run,
	New,
	Clean,
	Add,
	Remove,
	// Install,
	// Uninstall,
	// Toolchain,
	Version,
	Help,
}

Command_Config :: struct {
	name, src_path, output, pkg_name, pkg_url: string,
	run_args:                                  []string,
	release, silent, dry_run:                  bool,
}

State :: struct {
	command: Command,
	config:  Command_Config,
}
