package cli

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

@(private = "file")
Flag :: struct {
	command:           Command,
	name, short, desc: string,
}

Flags :: [?]Flag {
	{
		command = .Build,
		name = "build",
		short = "b",
		desc = "Compile the current project",
	},
	{
		command = .Run,
		name = "run",
		short = "r",
		desc = "Compile and run the current project",
	},
	{command = .New, name = "new", desc = "Create a new Odin project"},
	{command = .Version, name = "version", desc = "Show Mimir's version"},
	{command = .Help, name = "help", short = "h", desc = "Show help message"},
}

Build_Options :: [?]Flag {
	{name = "--release", desc = "Compile the project in release mode"},
	{name = "--silent", short = "-s", desc = "Silent the terminal output"},
	{name = "help", short = "h", desc = "Show help message"},
}

